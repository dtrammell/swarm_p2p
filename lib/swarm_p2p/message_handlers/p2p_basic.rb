# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A., Dustin T.
#
# Swarm simple text protocol implementation.  Just for dev and testing,
# not a real handler.  Will be removed from project at some point.
#
module SwarmP2P
  module P2pBasic
		def me
			method(__callee__).owner
		end

		# @see SwarmP2P::MessageHandler
		#
		#@todo see notes on defaults in code.
		#
		def plugin_init(opts) 
		end

		# @see SwarmP2P::MessageHandler
		def message_process(peer,data)
			(ncmd, message, discard) = data.split('::')			
			if !message || message.empty?
				message = "Bad command #{ncmd}"
				ncmd = 'skip'
			end
			return ncmd,message
		end

		#------------------------------------------------------------------------------------
		# RPC handlers.  
		#------------------------------------------------------------------------------------
		# @see SwarmP2P::MessageHandler
		def echo(peer,message)
			outbound_enqueue('puts',peer,"echo_response::#{message}")
		end

		# @see SwarmP2P::MessageHandler
		def echo_response(peer,message)
			puts "Remote echoed back: #{message}"
		end

		# @see SwarmP2P::MessageHandler
		# @todo Offset is off for now
		def peer_list(peer,data)
			(count,offset) = data.split(';;')
			count = count.to_i
			offset = offset.to_i
			all = count == 0 ? true : false
			count = 10 if all || (count < 1)
			loop do
				peers = hive.peers_load(count) #,offset)
				break if !peers || peers.empty?
				peer_recs = peers.map {|p|
					hive.peer_record_from_hash(p)
				}
				inbound_enqueue('peer_list',peer,"#{count};;#{offset+count}") if all
				outbound_enqueue('puts',peer,"peer_list_response::" + peer_recs.join("/REC/"))	
			end
		end

		# @see SwarmP2P::MessageHandler
		def peer_list_response(peer,data)
			data.split('/REC/').each {|p|
puts "Store peer: #{p}"
next
#return true
				(uuid,name,host,port) = p.split(';;')
				hive.peer_store({
					uuid: uuid,
					name: name,
					host: host,
					port: port,
					created_at: Time.now,
				})
			}
		end

		# @see SwarmP2P::MessageHandler
		def peer_announce(peer,data)
			(uuid,name,host,port,peers) = data.split(';;')
			hive.peer_store({
				uuid: uuid,
				name: name,
				host: host,
				port: port,
				peers: peers || [],
				created_at: Time.now,
			})
			send_announce(peer,node)
		end

		# @see SwarmP2P::MessageHandler
		def data_package(peer,message)
			(dst,data) = message.split(';;',2)
			# if subscribes_to?(dst)
			#		hive.store_message(uuid,message)
					send(@message_callback,peer,message)
			# end
			# if node.uuid != uuid
			#   peers = node.peers - peer.uuid
			#   peers.each {|p|
			#			
			# 	}		
			# end
		end

		#----------------------------------------------------------------------------------------------
    # Commands to send to remote node.
		#----------------------------------------------------------------------------------------------

		# @see SwarmP2P::MessageHandler
		def send_echo(peer,data)
			outbound_enqueue('puts',peer,"echo::#{data}")
		end

		# @see SwarmP2P::MessageHandler
		def request_peer_list(peer,count=0,offset=0)
			outbound_enqueue('puts',peer,"peer_list::#{count};;#{offset}")
		end

		# @see SwarmP2P::MessageHandler
		def send_announce(peer,node)
			data = [node.uuid,node.name,node.host,node.port,node.peers.join(',')].join(';;')
			outbound_enqueue('puts',peer,"peer_announce::#{data}")
		end

		# @see SwarmP2P::MessageHandler
		def send_package(peer,data)
			outbound_enqueue('puts',peer,"data_package::#{data}")
		end

		def message_uuid(data)
			uuid == SwarmP2P::generate_dataid(data)
		end

	end # End P2PBasic
end # End SwarmP2P
