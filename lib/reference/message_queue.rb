#@todo Delete this after done translating functionality

module SwarmP2P
	class MessageQueue
		# Broadcast a message to all connected peers
		def broadcast( message )
			# Step through peers list and send message to each one except the relay peer who sent it to this Node
			@node.peer_list.each do | peer |
#				puts "Broadcasting message to recipient %s" % peer.name
#				peer.socket.puts( message.to_json ) if peer.uuid != message.message[:data][:head][:relay]
				peer.send(message.to_json)
			end
		end

			# Add peers to recipients list if we're directly connected to any destination peers
#			message.dst.each do | dst |
#				@node.peer_list.each do | peer |
#					recipients << peer if peer.uuid == dst
#				end
#      end

      # Send message only to each destination Peer's socket if all recipients reachable
#			if (message.dst.count > 0) && (message.dst.count == recipients.count)
#         	recipients.each do | peer |
#            	puts "Sending message to recipient %s" % peer.name
#            	peer.send( message.to_json )
#         	end
#			else
#				# Otherwise, broadcast the message
#				self.broadcast( message )
#			end

#			# Verify any signatures attached to message and reject bad messages
#			message.message[:sigs].each do | sig |
#				# TODO: Check to see if Peers list has a stored public key and verify the signature
#			end

	end # class MessageQueue
end # module Swarm
