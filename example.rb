#!/usr/bin/ruby

require './lib/swarm.rb'
require './lib/swarm/message.rb'
require './lib/swarm/network.rb'
require './lib/swarm/node.rb'
require './lib/swarm/peer.rb'

# Global Configuration
$datadir = Dir.home + '/.swarm'

# Node Configuration
config = {
	:name => 'Example Node',
	:uuid => '11111111-1111-1111-1111-111111111111',
}

# Create the Node
@node = Swarm::Node.new( config )

# Network Configuration
netconfig = {
	:name => "Default Swarm Network",
	:uuid => '00000000-0000-0000-0000-000000000000', # default Swarm network
	:bootstrap_peer => {
		:name => 'Queen',
		:uuid => '00000000-0000-0000-0000-000000000000',
		:host => '34.232.133.253',
		:port => 3333
	}
}
netconfig[:datadir] = $datadir

# Create the Network
@network = Swarm::Network.new( netconfig )

# Connect to Network
@node.network_connect( @network )

# Service Incoming Connections
@node.server_start

# Send a Test Message to the Queen
puts "Sending a test message to the Queen"
msgconfig = {
	:network      => [ '00000000-0000-0000-0000-000000000000' ],
	:dst          => [ '00000000-0000-0000-0000-000000000000' ],
	:payload_type => :ascii,
	:payload      => 'This is a TEST MESSAGE'
}
message = Swarm::Message.new( msgconfig )
puts message
@node.message_send( message )

# Send a Test Broadcast Message
puts "Sending a test broadcast message"
msgconfig = {
	:network      => [ '00000000-0000-0000-0000-000000000000' ],
	:payload_type => :ascii,
	:payload      => 'This is a BROADCAST TEST MESSAGE'
}
message = Swarm::Message.new( msgconfig )
puts message
@node.message_send( message )

