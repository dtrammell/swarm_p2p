# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Event Machine TCP Socket Protocol
#
# Example:
# mh = SwarmP2P::MessageHandler.new(node)
# sw = SwarmP2P::Protocol.new(mh,{ type: 'EmTcp', plugin_config:{ port: 8182} })
#
require 'eventmachine'

module SwarmP2P
	class EMServer < EventMachine::Connection

		# Client IP/Port - Convenience method for logs/debugs
		def client_id
			port, ip = Socket.unpack_sockaddr_in(get_peername)
			"#{ip}:#{port}"
		end

		# Server IP/Port - Convenience method for logs/debugs
		def server_id
			"#{@ip}:#{@port}"
		end

		# Initialize the EM service.
		# @param [Hash] opts The options
		def initialize(opts={})
			super
			# whatever else you want to do here
			@parent = opts[:parent] || fail("A compatible parent object must be provided.")
			@port = opts[:port] || 'unknown'
			@ip = opts[:ip] || 'unknown'
		end

		# After client connects, set up peer object
		def post_init
			@peer = Peer.new({
				socket: self
			})
			swdebug "#{server_id}:> client #{client_id} connected."
		end

		# Receive data from connected client.
		def receive_data data
			@parent.inbound_enqueue('process',@peer,data)
		end

		# Homogenize output ... geesh.
		#
		def puts(data)
			send_data data
		end

		# Handle EM disconnect
		# @todo cleanup
		#
		def unbind
			 swdebug "#{server_id}:> #{client_id} disconnected from server."
		end
	end

	module EmTcp
		def me
			method(__callee__).owner
		end

		# @see SwarmP2P::Protocol
		#
		#@todo see notes on defaults in code.
		#
		def plugin_init(opts)
fail "This plugin is not currently up to date."
			@ip = opts[:ip] || '127.0.0.1' # Maybe 0.0.0.0?
			@port = opts[:port] # || get default?
			@server = nil
			@peer_threads    = []
			@server_thread = nil
		end

		# @see SwarmP2P::Protocol
		#
		def start
			swlog "Listening for incoming sockets on #{server_id}."
			# Create a thread for the Event Machine Server so we can return to caller.
# Setup SSL context if SSL is enabled
#		@server = if @ssl
#			OpenSSL::SSL::SSLServer.new( @tcp_server, @ssl_context )
#		else
#		end

			@server_thread = Thread.new {
				EM.run {
					@server = EventMachine.start_server @ip, @port, SwarmP2P::EMServer, {
									parent: @parent , port: @port, ip: @ip,
									warn_logger: @warn_logger,
									debug_logger: @debug_logger,
									logger: @logger,
					}
				}
			}
		end

		# @see SwarmP2P::Protocol
		def connect(host,port,opts={})
			socket = TCPSocket.open( host, port )
			peer = Peer.new({
					:host     => host,
					:port     => port,
					:socket  	=> socket,
					:protocol => self,
			})
			peer.thread = Thread.new {
				Thread.current[:socket] = peer.socket
				self.listen(peer)
			}
			peer
		end

	end

end
