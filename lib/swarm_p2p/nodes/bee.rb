# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A., Dustin T.
#
# Bee class.
#
module SwarmP2P
	class Bee < Node
		MAX_PEERS = 8
		MIN_PEERS  = 3

		attr_reader   :min_peers, :max_peers, :queen, :queen_id
		attr_accessor :handlers, :protocols, :queen_host, :queen_port
		attr_accessor :socket, :ssl # :peers, 

		# Initialization from configuration hash
		# @todo Document
		#
		def initialize( config={} )
			super(config)
			# Node Metadata
			@data_dir = config[:data_dir] || SwarmP2P::SWARM_DEFAULTS[:data_dir]
			@ssl = config[:ssl] || SwarmP2P::swarm_ssl_init(File.join(@data_dir,'.ssl'))
			@uuid = @ssl.suuid || swfail!("Unable to determine UUID from SSL keys.")
			@queen_host = config[:queen].split(':')[0] if config[:queen]
			@queen_port = config[:queen].split(':')[1] if config[:queen]

			# Hive init options.
			# if Pre-instantiated Hive object via :hive
			# else Hive type (:hive_type), and uses data_dir to hive init.
			# OR ... obj.hive = SwarmP2P::Hive.new(dir,config)
			if config[:hive]
				@hive = config[:hive]
				@hive_type = @hive.plugin_type
			elsif config[:hive_type]
				@hive_type = config[:hive_type]
				@hive = SwarmP2P::Hive.new(dir: @data_dir, type: config[:hive_type] )
			end
			
			# Handler / Protocol init options
			# if :handler_type, create a handler of that type
			# else :handler_protocols is a hash of handler_type: [{protocol_hash},{protocol2_hash}]
			# OR ... obj.handler_add(MessageHandler Object)
			# OR ... obj.handler_new(type)
			@handlers	= []
			@protocols = []
			if config[:handler_type]		
				handler_new(config[:handler_type])
			end
			if config[:handler_protocols]
				config[:handler_protocols].each_pair {|type,opts|
					swdebug "Auto init handler and protocols: #{type} #{opts}"
					h = handler_new(type, opts )
				}
			end

			# Peer related vars
#			@peers = []
			@max_peers = config[:max_peers] || MAX_PEERS
			@min_peers = config[:min_peers] || MIN_PEERS

			# Message Encryption Options
			@sign_messages    = config[:sign_messages]    || false
			@encrypt_messages = config[:encrypt_messages] || false

			return true
		end

#							socket.close if message.message[:data][:head][:type] != 'peer_management'
#							socket.close if message.message[:data][:head][:src].count > 1
#							socket.close if message.message[:data][:head][:src][0] != message.message[:data][:body][:uuid],
#
							# TODO: connect-back to advertised port to verify peer is listening
							# Create a new Peer object for the Peer
#							peer = SwarmP2P::Peer.new( {
#								:name     => message.message[:data][:body][:payload][:name],
#								:uuid     => message.message[:data][:body][:payload][:uuid],
#								:version  => message.message[:data][:body][:payload][:version],
#								:desc     => message.message[:data][:body][:payload][:desc],
#								:networks => message.message[:data][:body][:paylaod][:networks],
#							} )
#							peer.networks.each do |net|
# 						Find matching network object in @network_list list
#							@network_list.each do |net|
#							n << net.uuid

			## Craft the Node Announcement
			#announcement = {
			#	:name     => @name,
			#	:uuid     => @uuid,
			#	:version  => $VERSION,
			#	:desc     => @desc,
			#	:port     => @port,
			#	:networks => n
			#}.to_json
			#message = Swarm::Message.new( {
			#	:type         => 'peer_management',
			#	:payload_type => 'json',
			#	:payload      => announcement
			#} )
			#

#		# Connect to a Network
#		def network_connect( network )
#			# Add network to node if it hasn't been already
#			# Connect up to @min_peers Peers
#			if network.peer_list.count == 0
#				puts 'No peers known, aborting connections.'
#				# Pick a random peer from the peers list
#				randpeer = SecureRandom.rand(network.peer_list.count)
#				puts 'Selected Peer #%d at random' % randpeer
## Iterate the Node's peer list and check if the randomly selected peer is already connected
#				@peer_list.each do | peer |
#					# Next loop if this peer is already connected
#					next if peer[:uuid] == network.peer_list[randpeer][:uuid]
#				end
#			# Create a Peer object for the peer
#				peer = Peer.new( network.peer_list[randpeer] )

		# Start service only
		def start_service
			handlers_start
			protocols_start
		end

		# Start all handlers and protocols
		def start
			handlers_start
			protocols_start
			if queen_host
				mh = handlers.first
				p = mh.protocols.first
				@queen = p.connect(queen_host,queen_id)
				@queen_id = @queen.host_id
				mh.request_peer_list(@queen)
				# @todo - issue with knowing when we have enough nodes...
				swlog "Unfortunate delay waiting for queen..."
				sleep(5)
				@queen.disconnect
			end
			handlers.each {|h|
				h.peers_connect
			}
		end

		# Start all protocols for all handlers.
		def protocols_start
			handlers.each {|h|
				h.protocols.each {|p|
					p.start
				}	
			}
		end

		# Start all protocols for all handlers.
		def handlers_start
			handlers.each {|h|
				h.start
			}
			handlers
		end

		# Add a new protocol
		# @param [MessageHandler] handler Message handler to add protocol to.
		# @param [Hash] config Protocol config hash
		#
		def protocol_new( handler, config )	
			handler.protocol_new(config)
		end

		# Add a new message handler
		# @param [String] type Handler plugin type
		# @param [Array[Hash]] config Array of protocol config hashes
		#
		def handler_new( type, opts={} )
			h_opts = opts[:options] || {}
			protocols = opts[:protocols] || []

			handler = SwarmP2P::MessageHandler.new(self,{ type: type }.merge(h_opts))
			protocols.each {|proto|
				p = SwarmP2P::Protocol.new(handler,proto)
				handler.protocol_add(p)
			}
			handlers_add(handler)
			handler
		end

		# Add message handler(s) to handlers
		# @param [MessageHandler|Array] handlers One or more MessageHandlers to add to Bee
		#
		def handlers_add( *handlers )
			@handlers = @handlers.union(handlers.flatten)
		end
		alias_method :handler_add, :handlers_add

		# Remove message handler(s) from handlers list
		# @param [MessageHandler|Array] handlers One or more MessageHandlers to remove from Bee
		def handlers_del( *handlers )
			@phandlers = @handlers.difference( handlers.flatten )
		end
		alias_method :handler_del, :handlers_del
		alias_method :handler_delete, :handlers_del
		alias_method :handlers_delete, :handlers_del

		def peers
		  handlers.map{|h| h.peers }.flatten 
		end

		def peers_uuids
			peers.map{|p| p.uuid }.uniq 
		end

		# Add a Peer to the Peer List
		# @param [Peer|Array] peers One or more Peers to add to Bee
		#
		def peers_add( *peers )
			fail "No longer used"			
			@peers = @peers.union(peers.flatten)
		end
		alias_method :peer_add, :peers_add

		# Remove a Peer from the Peer List
		# @param [Peer|Array] peers One or more Peers to remove from Bee
		#
		def peers_del( *peers )
			fail "No longer used"			
			@peers = @peers.difference( peers.flatten )
		end
		alias_method :peer_del, :peers_del
		alias_method :peer_delete, :peers_del
		alias_method :peers_delete, :peers_del

		# Disconnect a Peer
		# @param [Peer] peer Disconnect peer
		# @todo Need this still?
		#
		def peer_disconnect( peer )
			fail "Not implemented yet"			
			peer.disconnect
		end

		# Disconnect all peers
		# @todo Perform on destruction...
		#
		def disconnect
			handlers.each{|h| h.peers.each{|p| p.socket.close } }
		end

		# Send a broadcast to all peers
		# @param [String|Message] data Prefab message or whatever string to broadcast/forward
		# @param [String] type Optional parameter to specify payload type ...
		# @todo - get a handle on what I am doing with types...
		# @todo - this needs to be moved to handlers
		# @todo - remember why I havent yet...?!?!?
		#
		def broadcast(data,type="MessageBroadcast")
			message = if data.is_a?(Message)
				swdebug "Forward message #{data.uuid}" 
				data
			else
				m = Message.new(
					src: self.uuid,
					command: 'data_broadcast',
					payload_type: type,
					payload: data #Base64.encode64(data),
				)
				swdebug "Broadcast new message #{m.uuid}" 
				m
			end

			handlers.each{|h|
				h.message_store(message.uuid,message)
				h.peers.each{|p|
					next if p.uuid == @queen.uuid
					next if message.head.src == p.uuid
					next if message.last_from == p.uuid
					#puts "should broadcast ... #{p.host_id}"
					h.send_message(p,message)
				}
			}
			true
		end

	end # End Class Bee
end # End Module Swarm
