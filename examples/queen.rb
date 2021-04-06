#!/usr/bin/ruby

require './lib/swarm_p2p'

# Global Configuration
$datadir = Dir.home + '/.swarm'

# Node Configuration
config = {
	:name => 'Queen Node',
	:uuid => '11111111-1111-1111-1111-111111111111',
}

# Create the Node
@node = SwarmP2P::Node.new( config )

# Network Configuration
netconfig = {
	:name => "Default Swarm Network",
	:uuid => '00000000-0000-0000-0000-000000000000', # default Swarm network
	:bootstrap_peer => {
	}
}
netconfig[:datadir] = $datadir

# Create the Network
@network = SwarmP2P::Network.new( netconfig )

# Connect to Network
@node.network_connect( @network )

# Service Incoming Connections
@node.server_start
