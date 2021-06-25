#!/usr/bin/ruby
#
# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
#
# BeeCli - A client for testing against bee nodes.  Runs an IRB interface after it starts.
# 
#
#require 'irb'
require 'irbtools'
load "./lib/swarm_p2p.rb"
include SwarmP2P
SwarmP2P::swarm_debug_log = false #true
@data_dir = File.join(Dir.home,"test_hive_3333")

count = (ARGV[0] || 10).to_i
start = (ARGV[1] || 0).to_i

@bees = []
@bee = nil
@msg = nil
@queen = nil

# Spin up some bees!!!
def spinup(cnt=10,start=0)
  if @bees.count > 0
		@bees.each{|b| b[:bee].disconnect }
  end

	@bees = []
	cnt.times {|i|
		bee = {}
		cport = "353#{i + start + 1}"
		bee[:bee] = Bee.new(
			host: "127.0.0.1",
			port: cport,
			queen: '127.0.0.1:3333',
			ssl_on: true,
			data_dir: File.join(@data_dir,"test_hive_clients_#{cport}"),
			hive_type: 'HiveSqlite',
			handler_protocols: { 'P2pMainV1' => { 
				options: {
					callback: lambda {|s,p,d| i_got_mail(s,p,d) }
				},
				protocols: [{ plugin_config:{ port: cport }}],
			}}
		)
		bee[:bee].hive.scorched_earth

    # This is not really needed except the start line, it is just cruft
    # to set up vars for the IRB console
		bee[:mh] = bee[:bee].handlers.first

		@bees[i] = bee
	}
	@bees.each{|b|
		b[:bee].start
	}
	sleep(1)
	beeit(0)
	true
end

# None of this is really needed except the start line, it is just cruft
# to set up vars for the IRB console
def beeit(pos)
	pos = 0 if pos > @bees.count - 1
	@bee = @bees[pos][:bee]
	@msg = @bees[pos][:mh]
	# This is just to provide testing ... we already did the work we needed with queen...
	p = @msg.protocols.first
	@queen = p.connect('127.0.0.1',3333)
	puts "Sending echo test ... "
	@msg.send_echo(@queen,"Echo test...")
	@bee.uuid
end

def i_got_mail(s,p,d)
	d.content ||= "[Data empty from peer?!?!?]"
  STDOUT.puts "------ Bee Node Custom handler! -------"
	puts "From: #{p.host_id}, #{p.uuid}"
	puts "Type: #{d.content_type}"
	puts "Message (length:#{d.content.length}):"
	puts "#{d.content[0..256]}\n\n"
end

spinup(count,start)

def irbdocs
	puts %[
------------------------------------------------------------------------------
Bee Nodes Cluster
------------------------------------------------------------------------------
  Default Variables:
  ==================
  @bees = (ArrayOfHashes) Contain however many bees where spun up.
    @bees[0] = { bee: node, mh: handler, queen: queen_peer }
  @bee = A single bee.  Default = @bees[0]
  @msg = @bee's message handler.
  @queen = @bee's connected queen "Peer" node 

  Examples:
  ==================
	@bee.broadcast("Some Message",[content type])
	@msg.request_peer_list(@queen)

  Utility Methods:
  ==================
  spinup(cnt,[start]) = Restart cnt# of bees and set to @bees. Optional start starts from that
                        position (starting at 0).
  beeit(position) = Sets @bee, @msg, @queen to the @bees[pos] data.
                    If pos > @bees count(-1), use 0.

  Console: (Ruby IRB for more)
  ====================================
  quit - duh
  up_arrow,down_arror - traverse past console input
------------------------------------------------------------------------------
]	
end
sleep(3)
irbdocs
binding.irb
