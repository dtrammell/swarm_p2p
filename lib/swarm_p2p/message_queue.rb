require 'json'
require 'securerandom'
require 'socket'
require 'openssl'
require 'thread'

module SwarmP2P
	class MessageQueue
		attr_accessor :inbound, :outbound

		# Initialization
		def initialize( node )
			# Node reference
			@node = node

			# Initialize message queues
			@inbound  = []
			@outbound = []

			# List of messages seen (pruned to just UUIDs)
			@inbound_seen      = []
			@inbound_processed = []

			# Start processing messages
			self.process
		end

		# Process the MeesageQueue in its own thread
		def process
			# Start a new child Thread
			t = Thread.new {
				puts 'Started new thread for message processing.'

				# Master Loop
				loop do
					# Send a message if there is a message in the @outbound queue
					self.send if @outbound.count > 0

					# Receive a message if there is a message in the @inbound queue
					self.recv if @inbound.count  > 0

					# Prune the seen list to max cache amount
					while @inbound_seen.count > 1000
						@inbound_seen.shift
					end

					# Prune the processed list to max cache amount
					while @inbound_processed.count > 25000
						@inbound_processed.shift
					end
				end
			}

			# Return the parent thread
			return true
		end

		# Broadcast a message to all connected peers
		def broadcast( message )
			# Step through peers list and send message to each one except the relay peer who sent it to this Node
			@node.peer_list.each do | peer |
				puts "Broadcasting message to recipient %s" % peer.name
				peer.socket.puts( message.to_json ) if peer.uuid != message.message[:data][:head][:relay]
			end
		end

		# Send a message from the queue
		def send
			# Get the oldest message in the array
			message = @outbound.shift
			return false if message == nil

			puts "Sending message $s" % message.uuid

			# Broadcast if no recipients specified (broadcast message)
			self.broadcast( message ) if message.dst.count == 0

			###
			# Try to minimize network traffic by identifying exact peers matching recipients
			#

			# Initialize list of recipient peers to send message to
			recipients = []

			# Add peers to recipients list if we're directly connected to any destination peers
			matches = 0
			message.dst.each do | dst |
				@node.peer_list.each do | peer |
					recipients << peer if peer.uuid == dst
					matches += 1
				end
         end
	
         # TODO: See if Node knows a route for any destination peers
			# Increment matches if found

         # Send message only to each destination Peer's socket if all recipients reachable
			if message.dst.count == matches
         	recipients.each do | peer |
            	puts "Sending message to recipient %s" % peer.name
            	peer.socket.puts( message.to_json )
         	end
			else
				# Otherwise, broadcast the message
				self.broadcast( message )
			end

			return true
		end

		# Receive a message from the queue
		def recv
			# Get the oldest message in the array
			message = @inbound.shift
			return false if message == nil

			puts "Receiving message %s" % message.uuid

			# Ignore if we've seen or processed this message before (rebroadcast)
			return true if @inbound_seen.include? message.message[:data][:body][:uuid]
			return true if @inbound_processed.include? message.message[:data][:body][:uuid]

			# Verify any signatures attached to message and reject bad messages
			message.message[:sigs].each do | sig |
				# TODO: Check to see if Peers list has a stored public key and verify the signature
			end

			# Message is valid, record its UUID in the @inbound_seen list
			@inbound_seen << message.message[:data][:body][:uuid]

			# Route message to the appropriate message handler if this Node is in the destinations list or is a broadcast message
			if message.message[:data][:head][:dst].include? @node.uuid || message.message[:data][:head][:dst].count == 0
				
				# Record the UUID in the @inbound_processed list
				@inbound_processed << message.message[:data][:body][:uuid]

				# TODO: Send the message to any registered message handlers (by network or app ID)

				# Return if this Node is the only recipient
				return true if message.message[:data][:head][:dst].count == 1
			end

			# Propagate the message
			self.send( message )

			return true
		end

	end # class MessageQueue
end # module Swarm
