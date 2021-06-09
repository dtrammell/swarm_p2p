# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Minimal plugin system
#
module SimplePlugin
	attr_reader :plugin_dir, :plugin_type, :plugin_config

  # Dynamically load a module to act as a plugin,
  # allowing behavior changes via config at run time.
  #
  # @param name [Symbol] Symbolic name of the module/class to load.
  #
  def load_plugin(name,path)
		file = File.join(path,"#{name.to_s.snakecase}.rb")
		swdebug ">>Loading #{name} from #{file}"
		load file
		self.singleton_class.send(:include, name.to_s.constantize)
  end

	def plugin_init(*p)
		swwarn "This must be overridden in plugin modules!"
	end
	
end
