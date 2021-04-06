# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
# 
# Base message object. Creation and conversion methods.
#
# Message format is as follows: 
#     head: 
#       src: Origin drone
#       dst: Destination(s) addresses,
#       type: Type of message.  Default is :network 
#       uuid: Mesage unique universal ID
#       sent: Timestamp of message origin.  Informative, not trustable for now
#       signatures: Signature for verification against src and contents
#     body:
#       payload_type: Payload type, application specified
#       payload: Message content
#
require 'json'
require 'securerandom'

module SwarmP2P
	class Message
		attr_reader :uuid, :head, :body
		#attr_accessor :

		# Initialization
		# @param [Hash] config Message parameters
		# @option config [String] :type [optional] Type of message, defaults to :network 
		# @option config [String] :dst [optional] The destination address. If not provided, broadcast to Network.
		# @option config [String] :payload_type [optional] Message payload type label. 
		# @option config [String] :payload Message content.
		#
		def initialize( config = {} )
			@head = (config)
		        @body = (config)	

			# Timestamps
			@timestamps = {
				:sent => nil,
				:ack  => nil
			}

			return true
		end

		# Sign a message via mechanism provided by code block
		# @param 
		#
		def sign_content(&block)
			self.head.signatures << [uuid,yield(content)]
		end

		# Minimalized data for application
		# @todo Application message and protocol message should probably be different objects
		#
		def content
			{
				uuid: head.uuid,
				sent: head.sent,
				content_type: body.payload_type,
				content: body.payload
			}
		end

		# Message as a hash
		# @return [Hash] Message object as a hash
		# @see SwarmP2P::Message docuemntation 
		#
		def to_h
			{
			    head: head.to_h,
			    body: body.to_h 
                        }
		end

		# Export to string (json)
		# @return [String] Object as json string
		#
		def to_s
			self.to_json
		end

		# Export to JSON
		# @return [String] Message content as json
		#
		def to_json
			to_h.to_json
		end

		# Create message object from JSON string
		# @param json [String] JSON data format string
		# @return [Message] Reconstitute a message object from JSON data
		#
		def self.from_json( json )
			# TODO: Validate message format before just importing it
			json = JSON.parse( json, {:symbolize_names => true} )
			new(json[:head].merge(json[:body]))
		end

private

		# Primitive object for header data.  Working with methods, rather than nested
		# hashes is preferable, but Swarm doesn't yet need dedicated head/body classes.
		def head=(opts={})
			OpenStruct.new({
			  uuid: SecureRandom.uuid,
			  src: opts[:src] || [],
			  dst: opts[:dst] || [],
			  type: opts[:type] || :network,
			  sent: opts[:sent] || Time.now,
			  signatures: [],
			})
		end

		# Primitive object for header data.  Working with methods, rather than nested
		# hashes is preferable, but Swarm doesn't yet need dedicated head/body classes.
		def body=(opts={})
			OpenStruct.new({
			  payload_type: opts[:payload_type] || nil,
			  payload: opts[:payload] || '',
			})
		end

	end # class Message
end # module Swarm
