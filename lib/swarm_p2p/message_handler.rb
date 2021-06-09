# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A., DUstin T.
#
# Base message handler
#
# Specific message handlers are loaded as plugins and are
# required to override many of the methods defined and documented
# below.
#
module SwarmP2P
	class MessageHandler
		include SimplePlugin

		CURRENT_VERSION = '1.0.0'
		MAX_SEEN = 1000 # Seen queue max size
    MAX_PROCESSED = 25000 # Processed queue maz size

		attr_accessor :parent, :message_callback
		attr_reader :peers, :protocols, :thread, :type

		# Initialization
		def initialize(parent, opts={})
			# Node reference
			@parent = parent
			@peers = [] # Connected remote nodes

			# Initialize message queues
			@inbound  = Queue.new
			@outbound = Queue.new
			@peers_add_queue = Queue.new

			# List of message UUIDs seen & processed
#			@inbound_seen      = []
#			@inbound_processed = []

			# Message callback
			@message_callback = opts[:callback] || lambda {|mh, peer, data|
				puts "No-Op Message Callback for #{data.to_s[0..50]}"
			}

			@plugin_dir = opts[:plugin_dir] || File.join(__dir__,"message_handlers")

			# load template plugin for method placeholders
			load_plugin('P2pTemplate',@plugin_dir)
			plugin_init(plugin_config)

			# Load specified or default plugin
			@plugin_type = @type = opts[:type] || :P2pMainV1			
			load_plugin(@plugin_type,@plugin_dir)
			plugin_init(plugin_config)

			# If provided, we can add protocols at MessageHandler init
			@protocols = opts[:protocols] || []
			protocols.each {|proto|
				p = SwarmP2P::Protocol.new(self,proto)
				protocol_add(p)
			}

		end

		def me
			method(__callee__).owner
		end

		# SSL related methods direct to parent node.
		def ssl
			parent.ssl
		end

		def ssl_enabled?
			parent.ssl_enabled? && !ssl.empty?
		end

		# Get the hive associated with parent
		def node
			parent
		end

		# Get the hive associated with parent
		def hive
			parent.hive
		end

		# Parent message handler version
		# @todo probably don't need ... TBD
		#
		def message_version
			CURRENT_VERSION
		end

		# Add a protocol to this handler
		# @param [Hash] config Protocol init config
    # @return [Protocol] Returns protocol object
		#
		def protocol_new(config)
			p = SwarmP2P::Protocol.new(self, config)
			protocol_add(p)
			p
		end

		# Add message handler(s) to handlers
		def protocols_add( *protos )
			@protocols = @protocols.union(protos.flatten)
		end
		alias_method :protocol_add, :protocols_add

		# Queue convience methods.  Pretty clear...
		#-------------------------------------------------------------------------
		def inbound_enqueue(*c)
			enqueue(@inbound,*c)	
		end
		def inbound_dequeue
			dequeue(@inbound)
		end
		def outbound_enqueue(*c)
			enqueue(@outbound,*c)
		end
		def outbound_dequeue
			dequeue(@outbound)
		end
		def enqueue(queue,cmd,peer,msg)
			queue << [cmd,peer,msg]
		end
		def dequeue(queue)
			cmd,s,m = queue.pop
			[cmd,s,m]
		end

		def peers_add_queue(peer)
			@peers_add_queue << peer
		end

		def message_store(muuid,message)
			hive.message_store(muuid,message)
		end

		# Core Handler Processing methods
		#-------------------------------------------------------------------------

		# Start processing the handler.  This runs a process loop
    # inside a thread.  If you prefer to use a different means
    # of concurrency etc., you can call process in a loop.
    #
		# @return [Thread]
		#
		def start
			swdebug 'Started new thread for message processing.'
			# Start a new child Thread
			@thread = Thread.new {
				loop do
					items = process
					if items == 0
						sleep(0.1)
					else
						swdebug "Processing #{items} items"
					end
				end
			}				
		end

		# Single process pass on the message queues.  If you want a threaded loop, call start.
    # 
    # @return [Integer] Total of outbound and inbound queue elements.
    #
		def process
			if !@peers_add_queue.empty?			  
				peer = @peers_add_queue.pop
				swdebug "Add Peer #{peer.host_id}"
				peers_add(peer)
			end

			# Send a message if there is a message in the @outbound queue
			obcnt = process_outbound

			# Receive a message if there is a message in the @inbound queue
			ibcnt = process_inbound

			#@todo - rectify storage versus just knowing the uuid in hive

			# Prune the seen list to max cache amount
			# @todo hive.prune_seen
			#if @inbound_seen.size > MAX_SEEN
			#	@inbound_seen.shift(@inbound_seen.count - MAX_SEEN)
			#end

			# Prune the processed list to max cache amount
			# @todo hive.prune_processed
			#if @inbound_processed.size > MAX_PROCESSED
			#	@inbound_processed.shift(@inbound_processed.count - MAX_PROCESSED)
			#end

			return (obcnt + ibcnt)
		end

		#-------------------------------------------------------------------------
    # Message handlers that are provided to avoid having to implement, but
    # may need to be overridden in plugin to handle more complex cases.
		#-------------------------------------------------------------------------

# @todo below:
# Record the UUID in the @inbound_processed list
#				@inbound_processed << message.message[:data][:body][:uuid]
# TODO: Send the message to any registered message handlers (by network or app ID)
# Return if this Node is the only recipient
#				return true if message.message[:data][:head][:dst].count == 1
#			end
#
# 		# Verify any signatures attached to message and reject bad messages
#			message.message[:sigs].each do | sig |
#				# TODO: Check to see if Peers list has a stored public key and verify the signature
#			end
				# Ignore if we've seen or processed this message before (rebroadcast)
				# @todo - check if hive stores these
				# return true if @inbound_seen.include? check_uuid
				# return true if @inbound_processed.include? check_uuid

				# Message is valid, record its UUID in the @inbound_seen list
				# @inbound_seen << check_uuid


		# Broadcast a message out to all connected peers
		# @todo - work on this ...
		# @opts should include:
		#   source id
		#		
		def broadcast(dst,message,opts={})
			# Don't allow forward if dst is only = to this node.
			return false if dst.count == 1 && parent.uuid == dst.first

			recipients = []
			dst = [dst] if !dst.is_a?(Array)

			# If dst uuids are all current peers, limit broadcast to those peers only.
      # Otherwise, broadcast to all connected peers.
			peer_uuids = parent.peers.map(&:uuid)
			recipient_ids = peer_uuids & dst

			if recipient_ids.count == dst.count
        recipient_ids.each {|uuid|
					send_peer(parent.peer_by_uuid[puuid],message)
				}
			else
				parent.peers.each {||peer|
					send_peer(peer,message)
				}			
			end

			return true
		end

		# Add a Peer to the Peer List
		# @param [Peer|Array] peers One or more Peers to add to Bee
		#
		def peers_add( *peers )
			@peers = @peers.union(peers.flatten)
		end
		alias_method :peer_add, :peers_add

		# Remove a Peer from the Peer List
		# @param [Peer|Array] peers One or more Peers to remove from Bee
		#
		def peers_del( *peers )
			@peers = @peers.difference( peers.flatten )
		end
		alias_method :peer_del, :peers_del
		alias_method :peer_delete, :peers_del
		alias_method :peers_delete, :peers_del

		# Raw send to peer
		#
		def peer_send(peer,message)
			peer.socket.puts(message)
		end

		# Queued send to peer
		#
		def peer_queued_send(peer,message)
			outbound_enqueue('puts',peer,message)
		end

		# Raw send to peer
		#
		def peers_send(peers,message)
			peers.each{|peer|
				send_peer(peer,message)
			}
		end

		# Connect to adjacent, random peers
		# @todo document, expand, currently locked into ThreadTCP
		#
		def peers_connect
			pr = protocols.first
			h = {
				handler: self.type.to_s,
				protocol: pr.type.to_s,
				ssl: @parent.ssl_enabled?
			}
			ps = hive.peers_random(h,20)
			counter = 0
			ps.each{|ph| 
				peer = hive.peer_from_hash(ph)
				next if peer.host_id == @parent.queen_id
				next if peer.uuid == @parent.uuid
				next if peers.any?{|p| p.uuid == peer.uuid }
				ret = pr.connect_peer(peer.host,peer.port)
				next if !ret
				counter += 1
				break if counter > 20# @parent::MIN_PEERS
			}
			counter
		end

		# Send a message from the outbound queue
		# @todo Try to minimize network traffic by identifying exact peers matching recipients
		# @todo See if Node knows a route for any destination peers
		#
		def process_outbound
			return 0 if @outbound.empty?
			recipients = []
			# Get the oldest message in the array
			(cmd,peer,message) = outbound_dequeue
			return 0 if message == nil
			swdebug "Outbound: (#{@outbound.size}) #{cmd} :: #{peer.host_id} :: #{message.to_s[0..60]}(length:#{message.to_s.length})"
			peer.socket.__send__(cmd,message)

			return @outbound.size
		end
		
		# Receive a message from the inbound queue
    # @todo - document
		#
		def process_inbound
			return 0 if @inbound.empty?

			# Get the oldest message in the array
			(cmd,peer,message) = inbound_dequeue

			
			if cmd == 'process'
				(ncmd,data) = message_process(peer,message)

				# If handler has determined that we should reject or have seen this or shouldn't be processed
				return @inbound.size if ncmd == 'skip'

				# @todo add a command limiter to prevent script attacks
				if self.respond_to?(ncmd)
					swdebug "Inbound Process: #{ncmd} :: #{peer.host_id} :: #{message.to_s[0..60]}(length:#{message.to_s.length})"
					inbound_enqueue(ncmd,peer,data)
				else
					self.send_echo(peer,"Bad command.")
				end
			else
				swdebug "Inbound RPC: #{cmd} :: #{peer.host_id} :: #{message.to_s[0..60]}(length:#{message.to_s.length})"
				self.send(cmd,peer,message)
			end

			return @inbound.size
		end

		# Sig validation to pub key
    # @todo - document
		def validate_sig(pkey,sig)
			
		end

		# Stored Sig validation
    # @todo - document
		def validate_suuid(suuid,pkey)
			SwarmP2P::validate_suuid(suuid,pubkey)
		end

		# Peer sig validation
    # @todo - document
		def validate_peer_sig(peer,sig)
#			validate_sig(peer.)
		end

		# Node UUID validation
    # @todo - document
		def validate_stored_sig(suuid,pubkey)
		end

    #=====================================================================================
		# The following are commands that must be overridden by modules
    # for full implementation of swarm protocol.
    #=====================================================================================
    # General RPC notes:
    #
		# As the SwarmP2P gem is really meant to be simple to integrate, the app
    # on top of the SwarmP2P gem doesn't have to worry about the SwarmP2P protocol,
    # but probably wants to actually use the app messages as they arrive.  This is
    # done with a subscription model and a custom handler for when a message matching
    # the UUID is received.  The message handler will auto subscribe the self node ID,
    # but the default callback should be overridden by the app.
		#
		# @todo document

		# Message process needs to be overwritten by plugin, due to the fact that this is
    # where message format is processed, which is handler specific.  Including another
    # handler and then cherry pick overriding is possible.
    #
		# Message process has a lot of work to do potentially, including any checks required
    # for signatures etc.
    #
		# @param [Object] peer The peer object, see class documentation.
    # @param [String] data The unserialized/unprocessed data from socket.
		#
 		def message_process(peer,data)
			warn("#{m} must be implemented in plugin!")			
		end

		# This is required to put together the message format.
		#
		# @param [Object] peer The peer object, see class documentation.
		# @param [String] data The data component of the socket message.
		#
 		def message_prepare(peer,data)
			warn("#{m} must be implemented in plugin!")			
		end

		#
		# @param [Object] peer The peer object, see class documentation.
		# @param [String] data The data component of the socket message.
		#

	end
end
