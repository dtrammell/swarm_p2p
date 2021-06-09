# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Local swarm will spin up a test network of multiple drones a queen, setting different ports
# automatically.
#
require "multi_daemons"
require_relative "lib/swarm_p2pi.rb"

log_dir = "log"
pid_dir = "tmp"

help = %{
#{File.basename(__FILE__)} - Summon a SwarmP2P hive

  Command options:
                install: Install new version of software.
                start: Start all drones and queen
                stop: Stop all services
                restart Stop only that daemon
                status: Get running status for all daemons
                list: list all running daemons
                -h/--help: Get this help

}

dcmd = (!ARGV.empty? && ARGV[0]) ? ARGV[0] : ARGV[0] = "-h"

processes = []
daemons = ['drone.rb']

daemons.keys.map {|k|
        if (dcmd == "start")
          puts "Adding daemon: #{k} via command: #{daemons[k][:cmd]}"
        end
        processes << MultiDaemons::Daemon.new(daemons[k][:cmd], name: k, type: :script, options: daemons[k][:options])
}
controller = MultiDaemons::Controller.new(processes)
controller.status

