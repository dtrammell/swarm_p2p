# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
#
# Base message object. Creation and conversion methods.
#
# Message format is as follows:
#     head:
#       	src: Origin node
#       	dst: Destination(s) addresse(s)
#       	type: Type of message.  Default is :network.  Options are :network, :swarm
#					command: What RPC command to run with the message payload.
#       	uuid: Mesage unique universal ID
#       	sent: Timestamp of message origin.  Informative, not trustable for now
#				last_peers: List of peers this message is being sent to from this node.
#	      signatures: Signature for verification against src and contents
#     body:
#       	payload_type: Payload type, application specified
#       	payload: Message content
#
require 'json'
require 'securerandom'

module SwarmP2P
	class Message
		attr_reader :uuid, :head, :body, :timestamps
		attr_accessor :last_from

		# Initialization
		# @param [Hash] config Message parameters
		#
		def initialize( config = {} )
			self.head = config
		  self.body = config

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
			OpenStruct.new({
				uuid: head.uuid,
				sent: head.sent,
				src: head.src,
				content_type: body.payload_type ,
				content: body.payload #Base64.decode64(body.payload)
			})
		end

		# Shortcut for uuid
		def uuid
			head.uuid
		end

		# Shortcut to obj.body.payload_type
		def payload_type
			body.payload_type
		end

		# Shortcut to obj.body.payload_type
		def payload
			#Base64.decode64(
			body.payload
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
			pjson = JSON.parse( json, {:symbolize_names => true} )
			Message.new(pjson[:head].merge(pjson[:body]))
		end

#private

		# Primitive object for header data.  Working with methods, rather than nested
		# hashes is preferable, but Swarm doesn't yet need dedicated head/body classes.
		def head=(opts={})
			@head = OpenStruct.new({
			  uuid: opts[:uuid] || SwarmP2P.generate_uuid,
			  src: opts[:src] || [],
			  dst: opts[:dst] || [],
			  command: opts[:command] || 'data_package',
				parameters: opts[:parameters] || [],
			  sent: opts[:sent] || Time.now,
			  last_peers: opts[:peers] || [],
			  signatures: [],
			})
		end

		# Primitive object for header data.  Working with methods, rather than nested
		# hashes is preferable, but Swarm doesn't yet need dedicated head/body classes.
		def body=(opts={})
			@body = OpenStruct.new({
			  payload_type: opts[:payload_type] || nil,
			  payload: opts[:payload] || '' #Base64.encode64(opts[:payload] || ''),
			})
		end

		def payload=(v)
			body.payload = v #Base64.encode64(v)
		end

	end # class Message
end # module Swarm
