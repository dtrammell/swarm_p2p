# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A., Dustin T.
#
# Peer class.  Generally not for app creation.  Created typically via
# message handler / protocols.
#
module SwarmP2P
	class Peer < Node
		attr_accessor :thread, :protocol, :announced, :socket, :handler

		# Initialization
		def initialize( config )
			super(config)

			# Multithreaded Variables
			@thread = config[:thread]
			@protocol = config[:protocol]
			return true
		end

		# Get the message handler for this peer.
		#
		def handler
			protocol ? protocol.parent : nil
		end

		# Get the message handler for this peer.
		#
		def handler
			@handler ||= protocol ? protocol.parent : nil
		end

		# Get the message handler type for this peer.
		#
		def handler_type
			@handler.type if handler
		end

		# Get the protocol type for this peer.
		#
		def protocol_type
			@protocol.type if @protocol
		end

					# There is a cached SSL certificate, compare it to connection's certificate
#					cached_cert = OpenSSL::X509::Certificate.new( File.read( @ssl_x509_certificate ) )
#					if cached_cert != @ssl_socket.peer_cert
#						puts "WARNING: Cached Peer SSL certificate does NOT match connection's certificate!"
#	 			  else
					# If there is no certificate cached, store the one from the connection
#					puts "No cached SSL certificate for Peer %s, saving connection's certificate..." % @uuid
#					File.write( @ssl_x509_certificate, socket.peer_cert.to_pem )
# TODO: Validate Peer

		# Disconnect
		# @todo - need?
		def disconnect
			socket.close
		end

		# Send Data
		# @todo - need?
		def sends( data )
			socket.puts( data )
		end

	end # End Peer class
end # End SwarmP2P mod