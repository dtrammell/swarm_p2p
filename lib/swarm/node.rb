require 'base64'
require 'openssl'
require 'securerandom'
require 'socket'
require 'syslog'
require 'thread'

module Swarm
	class Node
		attr_reader   :name, :uuid, :host, :port
		attr_reader   :min_peers, :max_peers
		attr_accessor :network_list, :peer_list
		attr_accessor :desc
		attr_accessor :socket, :ssl, :ssl_x509_certificate, :ssl_x509_certificate_key

		# Initialization from configuration hash
		def initialize( config )
			# Node Metadata
			@name = config[:name] || 'New Node'
			@uuid = config[:uuid] || SecureRandom.uuid
			@desc = config[:desc] || @name

			# System Configuration
			$datadir ||= '/tmp/swarm'
			@mydir     = $datadir + '/nodes/' + @uuid

			# Open Syslog
			Syslog.open( 'Swarm', Syslog::LOG_CONS|Syslog::LOG_PID, Syslog::LOG_DAEMON )

			# Check for data directory and create it if missing
			pathname = Pathname.new( @mydir )
			if ! pathname.exist?
				# Create any missing path
				puts ( "Node working directory '%s' does not exist... creating." % @mydir )
				pathname.mkpath
			end

			# Network Variables
			@host     = config[:host] || '127.0.0.1'
			@port     = config[:port] || '3333'
			@ssl      = config[:ssl]  || true
			@socket   = nil
			@status   = :disconnected
			@ping     = nil

			# Peering Variables
			@max_peers = config[:max_peers] || 8
			@min_peers = config[:min_peers] || 5

			# SSL Variables
			@ssl_x509_certificate     = @mydir + '/' + config[:ssl_x509_certificate]
			@ssl_x509_certificate_key = @mydir + '/' + config[:ssl_x509_certificate_key]

			# Encryption Options
			@sign_messages = config[:sign_messages] || false
			@encrypt_messages = config[:encrypt_messages] || false

			# Lists
			@network_list = []
			@peer_list    = []

			# Timestamps
			@timestamps = {
				:connect_attempt => nil,
				:connect_success => nil,
				:lastread        => nil,
				:lastwrite       => nil
			}

			# Log Iniitalization
			Syslog.info "Swarm v.%s Node %s Initialized." % [ $VERSION, @uuid ] 

			return true
		end

		# Listen for Incoming Peer Connections
		def listen
			# Create a TCP Server
			# TODO: Add host/IP for multiple interfaces
			@tcp_server = TCPServer.new( @port )

			# Setup SSL context if SSL is enabled
			if @ssl
				@ssl_context = OpenSSL::SSL::SSLContext.new
				@ssl_context.cert = OpenSSL::X509::Certificate.new( File.open( @ssl_x509_certificate ) )
				@ssl_context.key  = OpenSSL::PKey::RSA.new( File.open( @ssl_x509_certificate_key ) )
				@ssl_context.ssl_version = :SSLv23
				@ssl_server = OpenSSL::SSL::SSLServer.new( @tcp_server, @ssl_context )
				@server = @ssl_server
			else
				# Use TCP Server directly if no SSL enabled
				@server = @tcp_server
			end

			puts "Listening for incoming connections on port %d..." % @port

			# Initialize a collector Array for peer threads
			@thread_peers    = []

			# Create a thread for the connection listener
			@thread_listener = Thread.new {
				# Listening Loop
				loop do
					# Receive a Connection from a Peer
					connection = @server.accept
					puts "Received a connection..."

					# Create a Thread for connecting Peer
					t = Thread.new {
						begin
							# TODO: Connection Handshake
							# TODO: Add remote peer to peers list

							# Read and Process Data
							while ( line = connection.gets )
								line = line.chomp
								puts line if $DEBUG

								# TODO: Collect a full JSON message
								# TODO: Send message to message handler for message type
							end
						rescue
							$stderr.puts $!
						end
					}

					# Add Peer Thread to peers thread collector
					@thread_peers << t

				end
			}

			return true
		end

		# Add a Network to the Node
		def network_add( network )
			@network_list << network
		end

		# Remove a configured Network from the Node
		def network_del( network )
			# Delete the network object from the list array
			@network_list.delete( network )
		end

		# Connect to a Network
		def network_connect( network )
			# Add network to node if it hasn't been already
			self.network_add( network )

			# Connect up to @min_peers Peers
			network.connect( self, @min_peers )
		end

		# Disconnect from a Network
		def network_disconnect( network )
			# TODO: Disconnect from all Peers that are associated with Network
			network.disconnect( self )
		end

		# Connect a Peer
		def peer_connect( peer )
			peer.connect
		end

		# Disconnect a Peer
		def peer_disconnect( peer )
			peer.disconnect
		end

		# Broadcast Message 
		def broadcast( message )
			# TODO: Step through Peers list and send data to each one
			@peer_list.each do | peer |
				peer.socket.puts( message.to_json )
			end
		end

		# Send Message to Destination
		def message_send( message )
			# Add Node's UUID as message source
			message.message[:data][:head][:src] << self.uuid

			if @sign_messages
				# Sign only the data part of the message
				sigbin = @ssl_context.key.sign( OpenSSL::Digest::SHA256.new, message.message[:data].to_json )

				# Base64 encode the signature so that it can safely be convertd to JSON later, chomp the trailing \n
				sigb64 = Base64.encode64( sigbin ).chomp

				# Store a hash of the source UUID and its signature in the :sigs array of the message
				message.message[:sigs] << {
					:src => self.uuid,
					:sig => sigb64
				}
			end

			# If there is no destination peer specified, send to broadcast method and return
			if message.message[:data][:head][:dst].count < 1
				return self.broadcast( message )
			end

			# Initialize list of recipient peers to send message to
			recipients = []

			# Add peers to recipients list if we're directly connected to any destination peers
			@peer_list.each do | peer |
				message.message[:data][:head][:dst].each do | dst |
					recipients << peer if peer.uuid == dst 
				end
			end

			# TODO: See if Node knows a route for any destination peers

puts message.message[:data].to_json

			# Send message to each recipient's socket
			recipients.each do | r |
				puts "Sending message to recipient %s" % r.name
				r.socket.puts( message.to_json )
			end

			return true
		end

		# Receive Data
		def message_recv( data )
			while line = @socket.gets
				data << line
				puts line if $DEBUG
			end
		end

	end # Class Node
end # Module Swarm
