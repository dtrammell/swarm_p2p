require 'openssl'
require 'pathname'
require 'socket'

###
# Module Swarm
#

module SwarmP2P
	###
	# Class Network
	#

	class Network

		CURRENT_VERSION = '1.0.0'
		
		# Attribute Accessors
		attr_reader :name, :uuid, :desc
		attr_reader :peer_list

		# Initialization
		def initialize( config )
			# Network Metadata
			@name = config[:name] || 'Default Swarm Network'
			@uuid = config[:id]   || '00000000-0000-0000-0000-000000000000'
			@desc = config[:desc] || @name

			# System Configuration
			$datadir ||= '/tmp/swarm'
			@mydir     = $datadir + '/networks/' + @uuid

			# Check for data directory and create it if missing
			pathname = Pathname.new( @mydir )
			if ! pathname.exist?
				# Create any missing path
				puts ( "Working directory '%s' does not exist... creating." % @mydir )
				pathname.mkpath
			end

			# Lists
			@peer_list = []

			# Bootstrap Peer List
			@bootstrap_peer = config[:bootstrap_peer]

			# Load cached Peer List from File
#			self.peer_list_load
		end

		# Add a Peer to Peer List
		def peer_list_add( host, port, name = 'Unidentified', uuid = nil )
			peer = {
				:name => name,
				:uuid => uuid,
				:host => host,
				:port => port
			}

			# Check Peer List for duplicate
			@peer_list.each do | peerentry |
				# If we have a UUID, match on that
				if peer[:uuid]
					return true if peer[:uuid] == peerentry[:uuid] # Definitely a match, already added, return true
				else
					return true if peer[:name] == peerentry[:name] && peer[:host] == peerentry[:host] # No UUID, if host and name match it's already added, return true
				end
			end

			# Not found in list, add Peer to the Peer List
			@peer_list << peer

			return true
		end

	end # Class Network
end # Module Swarm
