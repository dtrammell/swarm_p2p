require 'securerandom'
require 'socket'
require 'openssl'
require 'thread'

module Swarm
	class Peer
		attr_reader   :name, :uuid, :host, :port
		attr_accessor :desc
		attr_accessor :socket, :ssl, :ssl_x509_certificate

		# Initialization
		def initialize( config )
#		host, port, name, id = nil, desc = '' )
			# Peer Metadata
			@uuid = config[:uuid]
			@name = config[:name]
			@desc = config[:desc]

			# System Configuration
			$datadir ||= '/tmp/swarm'
			@mydir     = $datadir + '/networks/' + @uuid

			# Check for data directory and create it if missing
			pathname = Pathname.new( @mydir )
			if ! pathname.exist?
				# Create any missing path
				puts ( "Peer working directory '%s' does not exist... creating." % @mydir )
				pathname.mkpath
			end

			# Network Variables
			@host   = config[:host] || '34.232.133.253'
			@port   = config[:port] || 3333
			@ssl    = config[:ssl]  || true
			@socket = nil
			@status = :disconnected
			@ping   = nil

			# SSL Variables
			@ssl_x509_certificate = @mydir + '/cert.pem'

			# Timestamps
			@timestamps = {
				:connect_attempt => nil,
				:connect_success => nil,
				:lastread        => nil,
				:lastwrite       => nil
			}

			return true
		end

		# Connect to this Peer
		def connect( node )
			# Open (SSL) TCP Socket to Peer
			@tcp_socket = TCPSocket.open( @host, @port )
			if @ssl
#				@ssl_context = OpenSSL::SSL::SSLContext.new
#				@ssl_context.cert = OpenSSL::X509::Certificate.new( File.open( @ssl_x509_certificate ) )
#				@ssl_context.key  = OpenSSL::PKey::RSA.new( File.open( @ssl_x509_certificate_key ) )
#				@ssl_context.ssl_version = :SSLv23
				@ssl_socket = OpenSSL::SSL::SSLSocket.new( @tcp_socket, @ssl_context )
				@ssl_socket.sync_close = true
				@ssl_socket.connect
				@socket = @ssl_socket
			else
				@tcp_socket.connect
				@socket = @tcp_socket
			end

			# TODO: If we have a certificate cached for this Peer, check it

			# TODO: Handshake & Trade IDs

			# TODO: Validate Peer
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
