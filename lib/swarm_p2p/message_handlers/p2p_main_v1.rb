# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A., Dustin T.
#
# Swarm network full message handler (P2P) communication.
#
require 'json'

module SwarmP2P
  module P2pMainV1
		def me
			method(__callee__).owner
		end

		# @see SwarmP2P::MessageHandler
		# @todo see notes on defaults in code.
		#
		def plugin_init(opts={}) 
		end

		# @see SwarmP2P::MessageHandler
		def message_process(peer,data)
			message = if data.is_a?(Hash)
				data
			else
				Message.from_json(data) 
			end
			
			if !message # || message.empty?
				message = "Bad command #{ncmd}"
				ncmd = 'skip'
			else
				ncmd = message.head.command
			end
			swdebug "Message Process::#{ncmd}::#{message.to_s[0..50]}..."

			return ncmd,message
		end

		#------------------------------------------------------------------------------------
		# RPC handlers.  
		#------------------------------------------------------------------------------------
		# @see SwarmP2P::MessageHandler
		def echo(peer,message)
			resp = Message.new(
				command: 'echo_response',
				payload: message.payload
			)
			outbound_enqueue('puts',peer,resp)			
		end

		# @see SwarmP2P::MessageHandler
		def echo_response(peer,message)
			puts "Remote echoed back: #{message.payload}"
		end

		# @see SwarmP2P::MessageHandler
		# @todo offset not working
		def peer_list(peer,data)
			(count,offset) = data.payload.split(';;')
			
			count = count.to_i
			offset = offset.to_i
			all = count == 0
			count = 10 if all || (count < 1)
			peers = hive.peers_load(count,offset)
			return if !peers || peers.empty?
			peer_recs = peers.map {|p|
				hive.peer_record_from_hash(p)
			}
			outb = Message.new(command: 'peer_list_response',payload: peer_recs).to_json
			outbound_enqueue('puts',peer,outb)

			# Requeue automatically to send the next chunk if count was 0
			if all
				offset = offset + count
				inbound_enqueue('peer_list',peer, Message.new(command: 'peer_list', payload: "#{count};;#{offset}"))
			end
		end

		# @see SwarmP2P::MessageHandler
		def peer_list_response(peer,data)
			swdebug hive.peers_store(data.payload)
		end

		# @see SwarmP2P::MessageHandler
		def peer_announce_response(peer,data)
			ret,newpeer = hive.peer_store(data.payload)
			swdebug "Announcement Store: #{ret} :: #{newpeer}"
			# @todo - What other fields do we need?
			peer.uuid = newpeer[:uuid]
			peer.announced = true
		end

		# @see SwarmP2P::MessageHandler
		def peer_announce(peer,data)
			ret,newpeer = hive.peer_store(data.payload)
			swdebug "Announcement Store: #{newpeer[:uuid]}"
			# @todo - What other fields do we need?
			peer.uuid = newpeer[:uuid]
			if !peer.announced
				swdebug "Send response announcement to #{peer.host_id}"
				send_announce_response(peer,@parent)			
				peer.announced = true
			end
		end

		# @see SwarmP2P::MessageHandler
		def data_package(peer,data)
			if !message_store(data.uuid,data)
				@message_callback.call(self, peer, data.content)
			else
				swdebug "Seen it #{data.uuid}"
			end
		end

		# @see SwarmP2P::MessageHandler
		def data_broadcast(peer,data)
			if !message_store(data.uuid,data)
				@message_callback.call(self, peer, data.content)
				data.last_from = peer.uuid
				@parent.broadcast(data)
			else
				swdebug "Seen it #{data.uuid}"
			end
		end

		#----------------------------------------------------------------------------------------------
    # Commands to send to remote node.
		#----------------------------------------------------------------------------------------------

		# @see SwarmP2P::MessageHandler
		def send_echo(peer,data)
			message = Message.new(
				src: node.uuid,
				command: 'echo',
				payload: data
			)
			outbound_enqueue('puts',peer,message.to_json)			
		end

		# @see SwarmP2P::MessageHandler
		def request_peer_list(peer,count=0,offset=0)
			message = Message.new(
				src: node.uuid,
				command: 'peer_list',
				payload: "#{count};;#{offset}"
			)
			outbound_enqueue('puts',peer,message.to_json)
		end

		# @see SwarmP2P::MessageHandler
		def send_announce(peer,node=@parent)
			message = Message.new(
				src: node.uuid,
				command: 'peer_announce',
				payload: hive.peer_record_from_peer(node)
			)
			outbound_enqueue('puts',peer,message.to_json)
			peer.announced = true
		end

		# @see SwarmP2P::MessageHandler
		def send_announce_response(peer,node=@parent)
			message = Message.new(
				src: node.uuid,
				command: 'peer_announce_response',
				payload: hive.peer_record_from_peer(node)
			)
			outbound_enqueue('puts',peer,message.to_json)
			peer.announced = true
		end

		# @see SwarmP2P::MessageHandler
		def send_package(peer,data,type="Message")
			message = Message.new(
				src: node.uuid,
				command: 'data_package',
				payload_type: type,
				payload: data #Base64.encode64(data),
			)
			message_store(message.uuid,message)
			outbound_enqueue('puts',peer,message.to_json)
		end

		# @see SwarmP2P::MessageHandler
		def send_message(peer,message)
			outbound_enqueue('puts',peer,message.to_json)
		end

		# @todo- eh?  Pretty sure this isn't used
		def message_uuid(data)
			fail "Remove this method"
			uuid == SwarmP2P::generate_uuid(data)
		end

	end # End P2PMainV1
end # End SwarmP2P
