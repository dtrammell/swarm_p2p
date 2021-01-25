require 'json'
require 'securerandom'
require 'socket'
require 'openssl'
require 'thread'

module Swarm
	class Message
		attr_accessor :src, :dst, :message

		# Initialization
		def initialize( config = {} )

			# Message Data
			@message = {
				:data => {
					# Message Header
 					:head => {
						:src  => [],
						:dst  => config[:dst] || []
					},
					:body => {
						# Message UUID
						:uuid => SecureRandom.uuid,

						# Message Payload Type
						:type => config[:type] || nil,

						# Message Payload
						:payload => config[:payload]
					}
				},
				:sigs => [
				]
			}

			# Timestamps
			@timestamps = {
				:sent => nil,
				:ack  => nil
			}

			return true
		end

		def to_s
			self.to_json
		end

		def to_json
			@message.to_json
		end

		def import_json( json )
			# TODO: Validate message format before just importing it
			@message = JSON.parse( json )
		end

	end # class Message
end # module Swarm
