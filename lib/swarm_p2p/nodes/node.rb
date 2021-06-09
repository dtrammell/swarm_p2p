# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A., Dustin T.
#
# Node base class.
#
require 'base64'
require 'openssl'
require 'securerandom'

module SwarmP2P
	class Node
		attr_reader   :name, :host, :port, :status, :ping, :socket, :stats, :ssl_on
		attr_accessor :uuid, :networks, :description, :ssl, :hive, :logger,
									:hive_version, 
									:created_at, :updated_at, :latency, :known_peers

		# Initialization from configuration hash
		def initialize( config={} )
			# Node Metadata
			@uuid = config[:uuid] || nil
			# Network Variables
			@host = config[:host] || '127.0.0.1'
			@port = config[:port] || '3333'
			@name = config[:name] || config[:host]
			@description = config[:description] || @name

			@socket   = config[:socket] || nil
			@status   = :disconnected
			@ssl_on = config[:ssl_on] || false

			# Storage values
			@hive_version	= config[:hive_version]
			@created_at	= config[:created_at]
			@updated_at	= config[:updated_at]
			@latency	= config[:latency]
			@known_peers	= config[:known_peers]

			# Lists
			@networks = []

			# Runtime stats
			@stats = {
				:connect_attempt => nil,
				:connect_success => nil,
				:lastread        => nil,
				:lastwrite       => nil
			}

			# Log Iniitalization
			#	swdebug "Swarm node:#{uuid} initialized."

			return self
		end

		# Add suuid interface over uuid
		def suuid; uuid; end
		def suuid=(v); @uuid = v ; end

		# Check if node has SSL for communication on.
		#
		def ssl_enabled?
			ssl && ssl_on
		end

		# Check if node has SSL for communication on.
		#
		def ssl_binary
			ssl && ssl_on ? 1 : 0
		end

		# Method to just return a string rep of host:port for logging etc.
		def host_id
			"#{host}:#{port}"
		end

		# Add a Network(s) to the Node, if it is unique
		# @param [String|Array[String]] networks One or more network uuids or array(s) of network uuids.
		# @return [Array] Network list.
		#
		def networks_add( *networks )
			@networks = @networks.union(networks.flatten)
		end
		alias_method :network_add, :networks_add

		# Remove a configured Network from the Node
		# @param [String|Array[String]] networks One or more network uuids or array(s) of network uuids.
		# @return [Array] Network list.
		#
		def networks_del( *networks )
			@networks = @networks.difference( networks.flatten )
		end
		alias_method :networks_delete, :networks_del
		alias_method :network_delete, :networks_delete
		alias_method :network_del, :networks_delete

		# Generate a suuid with current method using data.
		#
		# @param [String] data Source data, probably a public key, to turn into uuid.
    # @return [String] RMD160 hash "uuid" returned based on data.
		#
		def self.generate_suuid(data="")
			data.empty? &&
				swfail("Node requires data field to be non-empty to generate a UUID.  generate_uuid() may be useful for you.")
			SwarmP2P::gen_suuid(data)
		end

		# Instance generate_nodeid with data
		# @see Node.generate_suuid
		#
		def generate_suuid(data)
			self.class.generate_suuid(data)
		end

		# Instance generate_uuid
		# @see Node.generate_uuid
		#
		def generate_uuid
			self.class.generate_uuid
		end

	end # Class Node
end # Module Swarm
