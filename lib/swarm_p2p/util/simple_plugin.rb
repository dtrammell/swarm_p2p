# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Minimal plugin system
# @todo replace hard coded lib path
# 
module SimplePlugin

  # Dynamically load a module to act as a plugin,
  # allowing behavior changes via config at runtime.
  #
  # @param name [Symbol] Symbolic name of the module/class to load.
  #
  def self.plugin(name)
    file = name.downcase.to_s
    self.autoload(name,"./lib/swam_p2p/#{file}")
  end
end
