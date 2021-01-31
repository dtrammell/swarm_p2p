require 'securerandom'
require 'socket'
require 'openssl'
require 'thread'

module Swarm
	class Peer
		attr_reader   :name, :uuid, :version, :host, :port
		attr_accessor :desc
		attr_accessor :socket, :ssl, :ssl_x509_certificate
		attr_accessor :listener_thread

		# Initialization
		def initialize( config )
			# Peer Metadata
			@name     = config[:name]     || 'Queen'
			@uuid     = config[:uuid]     || '00000000-0000-0000-0000-000000000000'
			@version  = nil
			@desc     = config[:desc]     ||= @name
			@networks = config[:networks] ||= [ '00000000-0000-0000-0000-000000000000' ]

			# System Configuration
			$datadir ||= '/tmp/swarm'
			@mydir     = $datadir + '/peers/' + @uuid

			# Multithreaded Variables
			@thread = nil

			# Check for data directory and create it if missing
			pathname = Pathname.new( @mydir )
			if ! pathname.exist?
				# Create any missing path
				puts ( "Peer working directory '%s' does not exist... creating." % @mydir )
				pathname.mkpath
			end

			# Network Variables
			@host   = config[:host]   || '34.232.133.253'
			@port   = config[:port]   || 3333
			@ssl    = config[:ssl]    || true
			@socket = config[:socket] || nil
			@status = :disconnected
			@ping   = nil

			# SSL Variables
			@ssl_x509_certificate    = @mydir + '/cert.pem'
			@ssl_context             = OpenSSL::SSL::SSLContext.new
			@ssl_context.ssl_version = :SSLv23

			# Timestamps
			@timestamps = {
				:connect_attempt => nil,
				:connect_success => nil,
				:lastread        => nil,
				:lastwrite       => nil
			}

			return true
		end

		# Connect Node to this Peer
		def connect( node )
			# Open (SSL) TCP Socket to Peer
			@tcp_socket = TCPSocket.open( @host, @port )
			if @ssl
				# Use Node's SSL certificate for client connection
				@ssl_context.cert      = OpenSSL::X509::Certificate.new( File.open( node.ssl_x509_certificate ) )
				@ssl_socket            = OpenSSL::SSL::SSLSocket.new( @tcp_socket, @ssl_context )
				@ssl_socket.sync_close = true
				@ssl_socket.connect
				@socket = @ssl_socket
			else
				@tcp_socket.connect
				@socket = @tcp_socket
			end

			# Receive Node Announcement from Peer
			data = @socket.gets
			message = Swarm::Message.new
			message.import_json( data )
			puts 'Received Peer\'s Node Announcement:'
			puts message

			# SSL Stuff
			if @ssl
				pathname = Pathname.new( @ssl_x509_certificate )
				if pathname.exist?
					# There is a cached SSL certificate, compare it to connection's certificate
					cached_cert = OpenSSL::X509::Certificate.new( File.read( @ssl_x509_certificate ) )
					if cached_cert != @ssl_socket.peer_cert
						puts "WARNING: Cached Peer SSL certificate does NOT match connection's certificate!"
					end
				else
					# If there is no certificate cached, store the one from the connection
					puts "No cached SSL certificate for Peer %s, saving connection's certificate..." % @uuid
					File.write( @ssl_x509_certificate, @ssl_socket.peer_cert.to_pem )
				end
			end

			# TODO: Validate Peer

			# Send a Node Announcement to Peer
			node.announce( @socket )

			# Set Peer status to connected
			@status = :connected

			# Add Peer to Node's connected peers list
			node.peer_list << self

			# Create a new thread to listen to the Peer's socket
			t = Thread.new {
				node.listen( @socket )
			}

			return true
		end

		# Disconnect
		def disconnect
			# TODO Close SSL TCP Socket to Peer
		end

		# Query the Peer's Peer List
		def query_peer_list
			# TODO Request peer's peerlist
		end

		# Send Data
		def send( data )
			@socket.puts( data )
		end

		# Receive Data
		def recv( data )
			while line = @socket.gets
				data << line
				puts line if $DEBUG
			end
		end

	end

end
