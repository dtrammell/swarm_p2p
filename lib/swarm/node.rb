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
			@socket   = nil
			@status   = :disconnected
			@ping     = nil

			# Peering Variables
			@max_peers = config[:max_peers] || 8
			@min_peers = config[:min_peers] || 5

			# SSL Variables
			@ssl                      = config[:ssl] || true
			@ssl_x509_certificate     = @mydir + '/' + config[:ssl_x509_certificate]
			@ssl_x509_certificate_key = @mydir + '/' + config[:ssl_x509_certificate_key]
			# Create SSL Key and Cert if they do not exist
			pathname = Pathname.new( @ssl_x509_certificate_key )
			if ! pathname.exist?
				puts "No SSL key found, creating..."
				key = OpenSSL::PKey::RSA.new( 2048 )
				File.write( @ssl_x509_certificate_key, key.to_pem )
				File.write( @ssl_x509_certificate,     key.public_key.to_pem )
			end
			@ssl_context              = OpenSSL::SSL::SSLContext.new
			@ssl_context.ssl_version  = :SSLv23
			@ssl_context.cert         = OpenSSL::X509::Certificate.new( File.open( @ssl_x509_certificate ) )
			@ssl_context.key          = OpenSSL::PKey::RSA.new( File.open( @ssl_x509_certificate_key ) )

			# Message Encryption Options
			@sign_messages    = config[:sign_messages]    || false
			@encrypt_messages = config[:encrypt_messages] || false

			# Lists
			@network_list      = []
			@peer_list         = []
			@messages_received = []
			@messages_incoming = []

			# Timestamps
			@timestamps = {
				:connect_attempt => nil,
				:connect_success => nil,
				:lastread        => nil,
				:lastwrite       => nil
			}

			# Log Iniitalization
			Syslog.info "Swarm Node v.%s (UUID:%s) Initialized." % [ $VERSION, @uuid ] 

			return true
		end

		# Listen for Messages on a Socket
		def listen( socket )
			begin
				# Read and Process Further Data
				while ( data = socket.gets.chomp )
					puts data.to_s if $DEBUG
				
					# Send message to message handler
					self.message_recv( data, peer )
				end
			rescue => e
				#$stderr.puts $!

				case e
				when EOFError
					# Peer closed, exit the thread
					puts "Peer closed the socket."
					exit
				else
					$stderr.puts e.message
				end
			end
		end

		# Setup TCP Server for Incoming Peer Connections
		def server_start
			# Create a TCP Server
			# TODO: Add host/IP for multiple interfaces
			@tcp_server = TCPServer.new( @port )

			# Setup SSL context if SSL is enabled
			if @ssl
				@ssl_server = OpenSSL::SSL::SSLServer.new( @tcp_server, @ssl_context )
				@server = @ssl_server
			else
				# Use TCP Server directly if no SSL enabled
				@server = @tcp_server
			end

			puts "Listening for incoming sockets on port %d..." % @port

			# Initialize a collector Array for peer threads
			@thread_peers    = []

			# Create a thread for the TCP Server
			@server_thread = Thread.new {
				# Listening Loop
				loop do
					# Receive a Connection from a Peer
					socket = @server.accept
					puts "Received a connection..."

					# Create a Thread for connecting Peer
					t = Thread.new {
						begin
							# Send Node Announcement
							self.announce( socket )

							# Get Peer network information from socket
							sock_domain, peer_port, peer_host, peer_ip = socket.peeraddr

							# Receive the Peer's Node Announcement
							data = socket.gets
							message = Swarm::Message.new
							message.import_json( data )
							puts "Received Peer's Node Announcement:"
							puts message

							# Verify the Peer announcement
#							socket.close if message.message[:data][:head][:type] != 'peer_management'
#							socket.close if message.message[:data][:head][:src].count > 1
#							socket.close if message.message[:data][:head][:src][0] != message.message[:data][:body][:uuid],
							# TODO: connect-back to advertised port to verify peer is listening
							
							# Create a new Peer object for the Peer
							peer = Swarm::Peer.new( {
								:name    => message.message[:data][:body][:name],
								:uuid    => message.message[:data][:body][:uuid],
								:version => message.message[:data][:body][:version],
								:desc    => message.message[:data][:body][:desc],
								:host    => peer_ip,
								:port    => message.message[:data][:body][:port],
								:socket  => socket,
								:thread  => t
							} )

							# Save the Peer's certificate
							pathname = Pathname.new( peer.ssl_x509_certificate )
							if ! pathname.exist?
								# Create any missing path
								pathname.mkpath
								# Write certificate to file
								File.write( peer.ssl_x509_certificate, socket.peer_cert )
							end
							
							# Add remote peer to connected peers list
							@peer_list << peer

							# Listen on this socket for further data
							self.listen( socket )

						rescue => e
							#$stderr.puts $!

							case e
								when EOFError
									# Remote peer closed, exit the thread
									puts "Remote peer closed the socket."
									exit
								else
									$stderr.puts e.message
							end
						end
					}

					# Add Peer Thread to peers thread collector
					@thread_peers << t

				end
			}

			return true
		end

		# Send a Node Announcement to Socket
		def announce( socket )
			# Craft the Node Announcement
			announcement = {
				:name    => @name,
				:uuid    => @uuid,
				:version => $VERSION,
				:desc    => @desc,
				:port    => @port
			}.to_json
			message = Swarm::Message.new( {
				:type         => 'peer_management',
				:payload_type => 'json',
				:payload      => announcement 
			} )

			puts "Sending Peer Announcement:"
			puts message

			# Send the Node Announcement 
			socket.puts( message )
		end

		# Add a Network to the Node
		def network_add( network )
			# TODO: Check for duplicates
			@network_list << network
		end

		# Remove a configured Network from the Node
		def network_del( network )
			# Delete the network object from the list array
			@network_list.delete( network )
		end

		# Connect to a Network
		def network_connect( network )
			# Validate method argument
			raise 'Invalid parameter: Expecting Swarm::Network object' if ! network.is_a?(Swarm::Network)

			# Add network to node if it hasn't been already
			self.network_add( network )

			# Connect up to @min_peers Peers
			puts 'Connecting Node to %d peers...' % @min_peers

			# Keep track of how many peers have successfully connected
			peercount = 0

			# Loop
			loop do
				# Pick a random peer from the peers list
				randpeer = SecureRandom.rand(network.peer_list.count)
				puts 'Selected Peer #%d at random' % randpeer

				# Iterate the Node's peer list and check if the randomly selected peer is already connected
				@peer_list.each do | peer |
					# Next loop if this peer is already connected
					next if peer[:uuid] == network.peer_list[randpeer][:uuid]
				end

				# Create a Peer object for the peer
				peer = Peer.new( network.peer_list[randpeer] )

				# Connect to the Peer
				if peer.connect( self )
					# If connected, add the Peer object to Node's peers list
					@peer_list << peer
					peercount += 1

					# Create thread for listening on the socket
					#TODO
				end

            # Stop connecting if we've reached the min number of Peers allowed or have exhausted the Peer List
            break if peercount > @min_peers || peercount == network.peer_list.count
         end

			return true
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
		def broadcast( message, exclude_peer = nil )
			# Step through Peers list and send data to each one (except exclude_peer, this prevents sending messages back to where they came from)
			@peer_list.each do | peer |
				if exclude_peer
					peer.socket.puts( message.to_json ) if peer.uuid != exclude_peer.uuid
				else
					peer.socket.puts( message.to_json )
				end
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

			# Send message to each recipient's socket
			recipients.each do | r |
				puts "Sending message to recipient %s" % r.name
				# TODO: Send marshalled instead of json
				r.socket.puts( message.to_json )
			end

			return true
		end

		# Receive a Message
		def message_recv( data, peer )
			# Put JSON message data back into a Message object
			message = Swarm::Message.new
			message.import_json( data )

			# Silently drop the message if we've already received it
			@messages_received.each do | uuid |
				return true if uuid == message.message[:data][:body][:uuid]
			end

			# Verify any signatures attached to message and reject bad messages
			message.message[:sigs].each do | sig |
				# TODO: Check to see if Peers list has a stored public key and verify the signature
			end

			# Message is valid, record it's UUID in the @messages_received list
			@messages_received << message.message[:data][:body][:uuid]

			# If the message is for this Node, send message to the message processing queue
			notforme = true
			message.message[:data][:head][:dst].each do | dst |
				if @uuid == dst
					notforme = false
					@messages_incoming << message 
				end
			end

			# If the message is not for this Node or was a broadcast, propigate it
			self.message_forward( message, peer ) if notforme
		end

		# Forward a Message
		def message_forward( message, peer )
			puts "Forwarding message..."

			# If there is no destination peers specified, send to broadcast method and return
			if message.message[:data][:head][:dst].count < 1
				return self.broadcast( message, peer )
			end

			# Initialize list of recipient peers to send message to
			recipients = []

			# Add peers to recipients list if we're directly connected to any destination peers
			@peer_list.each do | p |
				message.message[:data][:head][:dst].each do | dst |
					recipients << p if p.uuid == dst 
				end
			end

			# TODO: See if Node knows a route for any destination peers

			# Send message to each recipient's socket
			recipients.each do | r |
				puts "Sending message to recipient %s" % r.name
				# TODO: Send marshalled instead of json
				r.socket.puts( message.to_json )
			end

			return true
			
		end

	end # Class Node
end # Module Swarm
