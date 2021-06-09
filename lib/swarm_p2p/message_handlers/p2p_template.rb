# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A., Dustin T.
#
# Swarm message handler template.  Not to be used directly, but copied
# to start a new handler.
#
module SwarmP2P
  module P2pTemplate
		def me
			method(__callee__).owner
		end

		# @see SwarmP2P::MessageHandler
		# @todo see notes on defaults in code.
		#
		def plugin_init(opts) 

		end

		# @see SwarmP2P::MessageHandler
		def message_process(peer,data)
		end

		#------------------------------------------------------------------------------------
		# RPC handlers.  
		#------------------------------------------------------------------------------------
		def echo(peer,message)
		end

		def echo_response(peer,message)
		end

		def peer_list(peer,data)
		end

		# @see SwarmP2P::MessageHandler
		def peer_list_response(peer,data)
		end

		# @see SwarmP2P::MessageHandler
		def peer_announce(peer,data)
		end

		# @see SwarmP2P::MessageHandler
		def data_package(peer,message)
		end

		#----------------------------------------------------------------------------------------------
    # Commands to send to remote node.
		#----------------------------------------------------------------------------------------------

		# @see SwarmP2P::MessageHandler
		def send_echo(peer,data)
		end

		# @see SwarmP2P::MessageHandler
		def request_peer_list(peer,count=0,offset=0)
		end

		# @see SwarmP2P::MessageHandler
		def send_announce(peer,node)
		end

		# @see SwarmP2P::MessageHandler
		def send_package(peer,data)
		end

		def message_uuid(data)
			uuid == SwarmP2P::generate_uuid(data)
		end

	end # End P2PTemplate
end # End SwarmP2P
