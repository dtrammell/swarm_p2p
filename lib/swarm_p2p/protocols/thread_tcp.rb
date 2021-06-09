# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
#
# Threaded TCP Socket Protocol.  Is the default protocol.
#
# Example:
# mh = SwarmP2P::MessageHandler.new(node)
# sw = SwarmP2P::Protocol.new(mh,{ type: 'ThreadTcp', plugin_config:{ port: 8182} })
#
require 'socket'
require 'thread'
require 'openssl'

module ThreadTcp
	def me
		method(__callee__).owner
	end

	# @see SwarmP2P::Protocol
	# Initialize the SQLlite DB in addition to normal hive init.
	#
	#@todo see notes on defaults in code.
  #
	def plugin_init(opts)
#		swdebug "Init Plugin: #{me} #{__callee__}"
		@ip = opts[:ip] || '127.0.0.1' # Maybe 0.0.0.0?
		@port = opts[:port] # || get default?
		@server = nil

		# Setup SSL context if SSL is enabled
		@peer_threads    = []
		@server_thread = nil
	end

	# @see SwarmP2P::Protocol
	# Setup TCP Server for Incoming Peer Connections
	def start
		@server = if @ssl
			swlog "Enabling SSL on #{server_id}."

			ssl_socket = OpenSSL::SSL::SSLServer.new( TCPServer.new( @ip, @port ), @ssl.context )
#      ssl_socket.start_immediately = true
			ssl_socket
		else
			TCPServer.new( @ip, @port )
		end

		swlog "Listening for incoming sockets on #{server_id}."

		## Create a thread for the TCP Server
		@server_thread = Thread.new {
			# Listening Loop
			begin
				loop do
					# Receive a Connection from a Peer
					@peer_threads << init_client(@server.accept)
				end
			rescue EOFError => e
				swwarn "#{server_id}:> #{client_id} disconnected from server."
			rescue => e
				swfail! "In Thread: #{e.message}"
			end
		}
	end

	# @see SwarmP2P::Protocol
	# Listen for Messages on a Socket
	def listen( peer )
		socket = peer.socket
		begin
			# Read and Process Further Data
			while ( data = socket.gets )
				# Queue it up.
				@parent.inbound_enqueue('process',peer,data.chomp)
			end
		rescue EOFError => e
			swwarn "#{server_id}:> #{client_id} disconnected from server."
			exit
		rescue => e
			swwarn "In Listen: #{e.message}"
		end
	end

	# @see SwarmP2P::Protocol
	def init_client(socket)
		@sock_domain, @peer_port, @peer_host, @peer_ip = socket.peeraddr
		peer = Peer.new({
			:host     => @peer_ip,
			:port     => @peer_port,
			:socket  => socket,
			:protocol => self
		})

		# Create a Thread for connecting Peer
		peer.thread = Thread.new {
#			@sock_domain, @peer_port, @peer_host, @peer_ip = socket.peeraddr
			swdebug "#{server_id}:> client #{client_id} connected."
			Thread.current[:socket] = socket
			self.listen( peer )
			swdebug "#{server_id}:> #{client_id} disconnected from server."
			@parent.peers_del(peer)
		} # End Thread
		@parent.peers_add_queue(peer)
		@parent.peers_add(peer)
		peer
	rescue EOFError => e
		swdebug "#{server_id}:> #{client_id} abruptly disconnected from server."
	rescue => e
		swdebug "Accept Init: #{e.message}"
	end

	# @see SwarmP2P::Protocol
	def connect_host(host,port,opts={})
		connect_peer(host,port,opts)
	end

	# @see SwarmP2P::Protocol
	def connect_peer(host,port=nil,opts={})
		peer = if host.is_a?(String)
			Peer.new({
					:host     => peer,
					:port     => port,
					:protocol => self,
			})
		else
			host
		end

		socket = if @ssl
			swdebug "Trying SSL to #{peer.host_id}."

			ssl_context = OpenSSL::SSL::SSLContext.new
			ssl_context.ca_file = ssl.x509_certificate

			ssl_socket = OpenSSL::SSL::SSLSocket.new( TCPSocket.new( peer.host, peer.port ), ssl_context )
			ssl_socket.sync_close = true
			ssl_socket.connect
			ssl_socket
		else
			swdebug "Trying to #{peer.host_id}."
			TCPSocket.open( peer.host, peer.port )
		end

		peer.socket = socket
		swlog "Connected to #{peer.host_id}."
		@parent.peers_add(peer)
		peer.thread = Thread.new {
			@sock_domain, @peer_port, @peer_host, @peer_ip = socket.peeraddr
			Thread.current[:socket] = peer.socket
			@parent.send_announce(peer)
			self.listen(peer)
			swdebug "#{server_id}:> #{client_id} disconnected."
			@parent.peers_del(peer)			
		}
		@parent.peers_add(peer)
		peer

	rescue => e #ECONNREFUSED => e
		swdebug "Unable to talk to #{peer.host_id}"
		return nil
	end
	alias_method :connect, :connect_peer

	# Client IP/Port - Convenience method for logs/debugs
	def client_id
		"#{@peer_host}:#{@peer_port}"
	end

#
#							# Get Peer network information from socket
#
#							# Receive the Peer's Node Announcement
#							data = socket.gets
#							message = Swarm::Message.new
#							message.import_json( data )
#							puts "Received Peer's Node Announcement:"
#							puts message
#
#							# Verify the Peer announcement
##							socket.close if message.message[:data][:head][:type] != 'peer_management'
##							socket.close if message.message[:data][:head][:src].count > 1
##							socket.close if message.message[:data][:head][:src][0] != message.message[:data][:body][:uuid],
#							# TODO: connect-back to advertised port to verify peer is listening
#
#							# Create a new Peer object for the Peer
#							peer = SwarmP2P::Peer.new( {
#								:name     => message.message[:data][:body][:payload][:name],
#								:uuid     => message.message[:data][:body][:payload][:uuid],
#								:version  => message.message[:data][:body][:payload][:version],
#								:desc     => message.message[:data][:body][:payload][:desc],
#								:networks => message.message[:data][:body][:paylaod][:networks],
#								:host     => peer_ip,
#								:port     => message.message[:data][:body][:payload][:port],
#								:socket   => socket,
#								:thread   => t
#							} )
#
# @hive.save_peer_cert(peer.ssl_x509_certificate)
# peer_add
#
#							# Add peer to network peer list(s)
#							peer.networks.each do |net|
#								# Find matching network object in @network_list list
## TODO
#							end
#
#							# Listen on this socket for further data
#
#						end
#					}
#

end
