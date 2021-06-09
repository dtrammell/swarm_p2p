# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Swarm Protocol
#
# Most methods here are place holders and MUST be overridden by the
# specific protocol plugin.  Default plugin is File, which is non-optimal for
# searches etc.
#
# Plugins are modules that are included and must implement caller methods.
# @todo Document the plugin methods
#
# Plugins can access the @parent object, for better or worse, and
# all commands are generally forwarded up to this object after low
# level handling.
# Parent must implement the following methods:
#  @parent.inbound_enqueue(cmd,self,message)
#  @parent.add_peer(self,peer_data)
#
module SwarmP2P

	class Protocol
		include SimplePlugin

		CURRENT_VERSION = '1.0.0'

		attr_accessor :parent, :ssl, :type

		#@todo document after finalize
		#
		def initialize(queue,opts={})
			@queue = @parent = queue
			@ssl = @parent.ssl if ssl_check
			@plugin_dir = opts[:plugin_dir] || File.join(__dir__,"protocols")
			@plugin_type = @type = opts[:type] || :ThreadTcp
			@plugin_config = opts[:plugin_config] || {}

			load_plugin(@plugin_type,@plugin_dir)
			plugin_init(plugin_config)
		end

		def server_id
			"#{@ip}:#{@port}"
		end
		
		# Check if the parent can respond to ssl_enabled?, in which case it also
    # needs to respond to ssl, which returns context.
		# @todo more robust checking ... (ssl respond and ssl context structure)
		def ssl_check
			(parent.respond_to?(:ssl_enabled?) && @parent.ssl_enabled?) ? true : false
		end

		# @todo need to make a template for protocols.
		#
		[:connect, :start, :close].each{|m|
			define_method(m) {
				swwarn("#{m} must be implemented in plugin!")
			}
		}
		#[:send, :recv].each{|m|
		#	define_method(m){|msg|
		#			warn("#{m} must be implemented in plugin!")
		#	}
		#}


	end # End Protocol
end # End SwarmP2P
