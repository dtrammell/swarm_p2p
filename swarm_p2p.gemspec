lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'swarm_p2p/version'

Gem::Specification.new do |s|
  s.name        = 'swarm_p2p'
  s.version     = SwarmP2P::VERSION 
  s.summary     = "P2P low level network framework."
  s.description = %(
Provides a distributed, communication framework and Swarm P2P network access, 
for applications to be developed on top of without need to develop their own 
P2P technology solution.
  )%
  s.authors     = ["Dustin Trammel","Donovan Allen"]
  s.email       = ["","roboyeti@gmail.com"]
  s.files       = Dir.glob('./lib/**/*')
  s.require_paths = ["lib"]
  s.homepage   = 'https://github.com/dtrammell/swarm_p2p'
  s.license    = 'MIT'
  s.add_runtime_dependency 'sqlite3','~> 1.4' 
  s.add_runtime_dependency 'crypto-lite','~> 0.0.1'
  s.add_runtime_dependency 'base58-alphabets','~> 0.0.1'
  s.add_development_dependency 'yard','~> 0.9'
end
