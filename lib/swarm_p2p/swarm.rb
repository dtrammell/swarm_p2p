# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Swarm Easy Class - convience layer
#
# Creates Bee w/colonies in one call.
#
module SwarmP2P
	class Swarm
			attribute_accessor :bee, :colonies, :peers
			attribute_reader :opts, errors

			# Swarm setup.  Creates the bee (self) and one or more
			# colonies.
			#
			# @param opts [Hash]
			#       @see SwarmP2P.config
			# @return [Swarm]
			#
			#@todo Allow hash options
			#
			def initialize(opts)
				# self.config = objectify_opts if opts.is_a?(Hash)
				self.config = opts.dup
				self.colony ||= []
				self.bee = SwarmP2P::Bee.new(config)
				config.colonies.each{ |net_opts|
					add_colony(bee,net_opts)
				}
			end

			# Add a new colony for this bee.
			#
			# @param bee [Bee] This node (bee).
			# @param opts [OpenStruct] Colony config object entry
			#
			def add_colony(bee,opts)
				colonies << SwarmP2P::Colony.new(bee,opts)
			end

			# Initiate connections to all registered colonies.
			# @see SwarmP2P::Colony.connect
			#
			# @return [Boolean] Established or failed. Errors
			# registered in errors
			#
			def connect()
				colonies.each {|colony|
					colony.connect
				}
			end

	private

		#def config=(opts)
		#	@config = OpenStruct.new({
		#			node: OpenStrut.new(opts[:node]),
		#				networks: OpenStruct.new(opts[:networks])
		#	})
		#end

	end # End Swarm Class
end
