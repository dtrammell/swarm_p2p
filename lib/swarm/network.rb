require 'openssl'
require 'pathname'
require 'socket'

###
# Module Swarm
#

module Swarm
	###
	# Class Network
	#

	class Network
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
			self.peer_list_load
		end

		# Load the Peer List from disk
		def peer_list_load
			filename = Pathname.new( @mydir + '/peer_list.dat' )
			if ! filename.exist?
				# Bootstrap Peer List
				if @bootstrap_peer
					self.peer_list_add( @boostrap_peer[:host], @bootstrap_peer[:port], @bootstrap_peer[:name], @bootstrap_peer[:uuid] )
				end

				# File doesn't exist, initialize it
				message = "Warning: Peer List File '%s' NOT FOUND; Initializing" % filename
				puts( message )

				# Write Peer List hash to file
				self.peer_list_save

				return false
			else
				File.open( filename ) do | f |
					@peer_list = Marshal.load( f )
				end
				message = "Loaded Peer List '%s' (%d records)" % [ filename, @peer_list.count ]
				puts ( message )
				if $VERBOSE
					puts "%s:" % filename
					pp @peer_list.inspect
				end
			end

			return true
		end

		# Save the Peer List to disk
		def peer_list_save
			filename = Pathname.new( @mydir + '/peer_list.dat' )
			File.open( filename, 'w+' ) do | f |
				Marshal.dump( @peer_list, f )
			end

			return true
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

		# Connect to the network as a Peer by connecting to up to @max_peers peers
		def connect( node, num_peers = 5 )
			puts 'Connecting Node to %d peers...' % num_peers

			# Keep track of how many peers have successfully connected
			peercount = 0

			# Loop
			loop do
				# Pick a random peer from the peers list
				randpeer = SecureRandom.rand(@peer_list.count)
				puts 'Selected Peer #%d at random' % randpeer

				# Iterate the Node's peer list and check if the randomly selected peer is already connected
				node.peer_list.each do | peer |
					# Next loop if this peer is already connected
					next if peer[:uuid] == @peer_list[randpeer][:uuid]
				end

				# Create a Peer object for the peer
				peer = Peer.new( @peer_list[randpeer] )

				# Connect to the Peer
				if peer.connect( node )
					# If connected, add the Peer object to Node's peers list
					node.peer_list << peer
					peercount += 1
				end

				# Stop connecting if we've reached the min number of Peers allowed or have exhausted the Peer List
				break if peercount > node.min_peers || peercount == @peer_list.count
			end
		end

	end # Class Network
end # Module Swarm

