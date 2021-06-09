# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
#
# Colony - A SwarmP2P network
#
module SwarmP2P
	class Colony

		attr_accessor :swarm
		attr_reader :name, :uuid, :description
		attr_reader :peer_list

		# @param opts [Object]
		def initialize(swarm,opts={})
			self.swarm = swarm
			@name = opts[:name] || 'Default Swarm Network'
			@uuid = opts[:id]   || '00000000-0000-0000-0000-000000000000'
			@description = opts[:desc] || @name

			puts "#{swarm.data_dir}"
			puts "#{swarm}"
		end

		# Connect to the colony, including intializing
		# peer connections.
		#
		# @return [Boolean] Success
		#
		def connect()
			# Check queen(s) for peer list

			# Connect to peers
		end

		# Start the colony server
		#
		# @return [Boolean] Success
		#
		def start()

		end

	end
end
