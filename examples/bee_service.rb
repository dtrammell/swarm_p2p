#!/usr/bin/ruby
#
# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
#
# Bee - A SwarmP2P server node partial implementation.
#
require 'irb'

load "./lib/swarm_p2p.rb"
include SwarmP2P
SwarmP2P::swarm_debug_log = true
port = 3333
data_dir = File.join(Dir.home,"test_hive_#{port}")

count = ARGV[0] || 10
bee = Bee.new(
	host: "127.0.0.1",
	port: port,
	data_dir: data_dir,
	ssl_on: true,
  hive_type: 'HiveSqlite',
	handler_protocols: { 'P2pMainV1' => { 
		options: {
			callback: lambda {|s,p,d| i_got_mail(s,p,d) }
		},
		protocols: [{ plugin_config:{ port: port }}],
	}}
#----- OR without init of the protocols...
#	handler_type: 'P2pMainV1',
)
swlog "Queen ID: #{bee.uuid}"

# Test populate a hive with some nodes
# This obviously wouldn't normally be part of a queen node service...
# Start fresh each start
bee.hive.scorched_earth
count.times {|i|
	cport = "353#{i+1}"
	cnode = Bee.new(
		host: "127.0.0.1",
		port: cport,
		ssl_on: true,
		data_dir: File.join(data_dir,"test_hive_clients_#{cport}"),
		hive_type: 'HiveSqlite',
		handler_type: 'P2pMainV1',
	)
	puts cnode.uuid
	bee.hive.peer_store(cnode)
}
swlog "NODES ADDED: #{bee.hive.peers_load().count}"

def i_got_mail(s,p,d)
	d.content ||= "[Data empty from peer?!?!?]"
  puts "Bee Queen Custom handler!"
	puts "From: #{p.host_id}, #{p.uuid}"
	puts "Type: #{d.content_type}"
	puts "Message: #{d.content[0..256]}\n (length:#{d.content.length})\n"
	# Could do something like this ... when appropriate ... but be careful not to
	# loop yourself
	s.send_package(p,"Got yer messages starting with #{d.content[0..25]}")
end

# Start protocols and message queues in one shot.
bee.start_service

#== or the following for more direct control of loops if need be
# bee.protocols_start
# bee.handlers_start
# Example:
# Start message handler processing
# loop {
#	 items = bee.handlers.first.process
#   if items == 0
#		 sleep(0.1)
#	  else
#		 swlog "Processing #{items} items"
#	 end
# }

#== Example Protocol add #2
# node.protocol_new(handlers.first,{ type: 'EmTcp', plugin_config:{ port: 8282} })
# OR
# node.handlers.first.protocol_new({ type: 'EmTcp', plugin_config:{ port: 8282} })
# OR
# p2 = SwarmP2P::Protocol.new(bee.handlers.first,{ type: 'EmTcp', plugin_config:{ port: 3434} })
# p2.start

def irbdocs
	puts %[
------------------------------------------------------------------------------
Bee Proto Queen
------------------------------------------------------------------------------
TODO - Document

	Console: (Ruby IRB for more)
  ====================================
  quit - duh
	up_arrow,down_arror - traverse past console input
------------------------------------------------------------------------------
]
end

irbdocs
binding.irb
