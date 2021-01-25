require 'json'
require 'securerandom'
require 'socket'
require 'openssl'
require 'thread'

module Swarm
	class Message
		attr_reader   :uuid
		attr_accessor :src, :dst, :data

		# Initialization
		def initialize( config )
			# Message Metadata
			@uuid = SecureRandom.uuid
			@src  = [ nil ]
			@dst  = [ config[:dst] ] || [ nil ]

			# Message Data
			@payload = config[:payload]

			# Timestamps
			@timestamps = {
				:sent => nil,
				:ack  => nil
			}

			@data = {
				:uuid    => @uuid,
				:payload => @payload
			}

			return true
		end

		def to_s
			# TODO: Check for binary data, return hex if not string
			return @data.to_s
		end

		def to_json
			@data.to_json
		end

	end # class Message
end # module Swarm
