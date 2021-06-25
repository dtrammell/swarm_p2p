# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
#
# Swarm Root Module
#
# If you want everything and the kitchen sink:
# Without gem: load "./lib/swarm_p2p.rb" ; include SwarmP2P
# With gem: require "swarm_p2p"; include SwarmP2P
#
# Enable Debug Output: SwarmP2P::swarm_debug_log = true
#
require 'crypto-lite'
require 'yaml'
require 'optparse'
require 'recursive-open-struct'
require 'erb'
require 'logger'
require 'syslog'
require 'syslog/logger'
require 'pathname'

$SWARM_SYSLOG = Syslog::Logger.new 'my_program'

$SWARM_DIR='swarm_p2p'
$SWARM_FILES = {
	'' 					=> ['version','topic','message','message_handler','hive','protocol'],
	'util' 			=> ['*'],
	'nodes'			=> ['node','peer','bee'],
}

$SWARM_DIR_ORDER=['util','','nodes']
$SWARM_DIR_ORDER.each{|d|
	$SWARM_FILES[d].each{|f|
		dir = File.join($SWARM_DIR,d)
		if f == '*'
			glob = File.join('lib',$SWARM_DIR,d,'*.rb')
			Dir[glob].each{|ff| require_relative File.join(dir,File.basename(ff)) }
		else
			require_relative File.join(dir,"#{f}.rb")
		end
	}
}

module SwarmP2P
	# Swarm Constants
	#===========================================================================

	# Default init config setup
	SWARM_DEFAULTS = OpenStruct.new({
		cfg_dir: File.join("#{Dir.home}",".swarm_p2p"),
		cfg_file: 'swarm.yml',
		data_dir: File.join("#{Dir.home}","swarm_hive"),
	})

	# Default file entries if no config file is provided
	SWARM_DEFAULT_CONFIG = {
		data_dir: File.join("<% Dir.home %>",'swarm_hive'),
		bees: [{
			name: 'SwarmBee',
			ssl_enabled: true,
			ssl_dir: File.join("<% Dir.home %>","<% @app.cfg_dir %>",'.ssl'),
			port: 3333,
			bind_address: '127.0.0.1',
			colonies: [{
				name: 'DefaultSwarm',
				id: '00000000-0000-0000-0000-000000000000',
				description: 'Default Swarm Network',
			}]
		}],
	}

	def swamp
		puts "lalalalal"
		puts "hahaha"
Thread.new {
		puts "lalalalalalaasddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
swamp2
		puts "lalalalalalaasddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
}
Thread.new {
		puts "lalalalalalaasddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
		puts "lalalalalalaasddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
}
	end

	def swamp2
swamp3
Thread.new {
		swdebug("#{Time.now}::Debug::asddddddddddddddddddddddddddddddddddd")
swamp3
}
	end

	def swamp3
		swdebug("#{Time.now}::Debug::asddddddddddddddddddddddddddddddddddd")
	end

	# Config Methods
	#===========================================================================

	def self.swarm_full_init(opts)
		app = swarm_init(opts)
#		app.ssl_dir ||= config.swarm.ssl_dir ||= File.join(app.cfg_dir,".ssl")
#   app.ssl = swarm_ssl_init(app)
		swarm_describe(app)
	end

	# Initialize a swam application, settings directories, config files,
	# creating required directories, setting up the config object passed
	# to swarm creation.  Allow parsing of hash or ARGV params passed
	# to calling program.
	#
	# @param opts [Hash|Array] The init options, which can include the following:
	#			cfg_dir: Where the config file is stored.  Default is "~/.swarm_p2p/"
	#			cfg_file: Name of the YAML config file.  Default is "<cfg_dir>/swarm.yml".  If provided, ust be full path.
	#			data_dir: Where the hive storage resides.  Default is "~/swarm_hive/"
	# 		ssl_dir: Where the SSL files reside (or created).  Default is "<cfg_dir>/.ssl/"
	# If opts is an ARRAY, treated as ARGV params, @see swarm_argv_init.
	#
	# @return [Object] Openstruct with the following top level methods:
	#		cfg_dir, cfg_file, ssl_dir, data_dir, ssl (requires later initialization),
	#		config (contains methods defined by YAML config file).
	#
	def self.swarm_init(opts={})
		app = SWARM_DEFAULTS.dup

		# If options are an Array, presume the are ARGV array
		# and get back a compatible Hash.
		#
		if opts.is_a?(Array)
			opts = swarm_parse_argv(opts)
		end

		# Parse the options hash for options not defined in the
		# config file and ignore anything not in the list.
		[:cfg_dir,:cfg_file,:data_dir].each{|mk|
			if opts.key?(mk)
				app.send("#{mk}=",opts[mk])
			end
		}

		if opts[:write_config]
			swarm_write_config(File.join(app.cfg_dir,app.cfg_file))
			exit
		end

		# @todo mkdir data_dir in hive init
		# data_dir
		#	Pathname.new(e).mkpath if !Dir.exist?(e)

		app.config = swarm_config(app.to_h)
		app.data_dir ||= app.config.data_dir
		puts app.to_h
		app
	end # Swarm runtime options init

	# Load or use default config file.
	#
	# @param app [Hash] init hash for config loading. @see SWARM_DEFAULTS
	# @return [Object]
	#
	def self.swarm_config(app=nil)
		@app ||= SWARM_DEFAULTS.dup
		SwarmP2P.dyno_dir(@app[:cfg_dir])
		@cfg_full_file = File.join(@app[:cfg_dir],@app[:cfg_file])

		if !Pathname.new(cfg_full_file).exist?
			swarm_write_config(cfg_full_file)
		end

		yaml = YAML.load( ERB.new( File.open(cfg).read ).result )
		RecursiveOpenStruct.new(yaml)
	end

	# Create a default config file.  Can be used to re-create new default config files as
	# format is updated.
	#
	# @param cfg [String] Config file with full path.
	#
	# @todo maybe allow opts to pass in to write configured file... maybe..?
	#
	def self.swarm_write_config(cfg)
			Pathname.new(cfg).dirname.mkpath if !Dir.exist?(cfg)
			SwarmP2P.dyno_dir(cfg)

			File.open( cfg, 'w' ) { |out|
				YAML::dump(SWARM_DEFAULT_CONFIG,out)
			}
	end

	# Parse ARGV for swarm options.  Convienence method for builders using this gem, but
	# ultimately will likely want to role their own.
	#
	def self.swarm_parse_argv(argv)
		options = {}
		OptionParser.new do |opts|
			opts.banner = "Usage: bee.rb [options]"
			opts.on("-c", "--config [PATH]", String, "Config directory. Defaults to ~/.swarm_p2p") { |dir|
				options[:cfg_dir]=dir
			}
# @todo Restore these options.  Currently, config file is only route to set these due to change to
# allow multiple Bees per program.
#
#			opts.on("-d", "--data [PATH]", String, "Data directory. Defaults to ./hive") { |dir|
#				options[:data_dir]=dir
#			}
#			opts.on("-s", "--ssl [PATH]", String, "SSL files directory. Defaults to ~/.swarm_p2p/ssl") { |dir|
#				options[:ssl_dir]=dir
#			}
			opts.on("-w", "--write-config", "Force write a default config to <cfg_dir>, then stop execution.") {
				options[:write_config]=true
			}

			# No argument, shows at tail.  This will print an options summary.
			opts.on_tail("-h", "--help", "Show this message") {
				puts opts
				exit
			}

			# Another typical switch to print the version.
			opts.on_tail("--version", "Show version") {
				puts ::Version.join('.')
				return nil
			}
		end.parse!(argv)
		options
	end

	# Swarm SSL create/read as needed.  Requires an initialed swarm_app object.  See above.
	#
	# @param ssl_dir [String] Path to SSL directory to get/store keys/certs
	# @return [Object] SSL object containing files and SSL context, etc.
	# @todo More docs
	#
	def self.swarm_ssl_init(ssl_dir)
		SwarmP2P.dyno_dir(ssl_dir)
		swdebug "Using #{ssl_dir} for SSL files"
		ssl = OpenStruct.new({
			context: OpenSSL::SSL::SSLContext.new,
			suuid: nil,
			x509_certificate: File.join(ssl_dir,"cert.pem"),
			x509_private_key: File.join(ssl_dir,"priv.pem"),
		})

		# If Key and Cert do not exist, generate new ones.  Either way,
    # load them from file, thus catching bad file writes as well.
		if !Pathname.new( ssl.x509_private_key ).exist?
			swwarn "No SSL private key found, creating..."
			File.write( ssl.x509_private_key , OpenSSL::PKey::RSA.new( 2048 ).to_pem )
		end
		swdebug "Loading PKey #{ssl.x509_private_key}"
		ssl.context.key = OpenSSL::PKey::RSA.new( File.read( ssl.x509_private_key ) )

		if !Pathname.new( ssl.x509_certificate ).exist?
			swwarn "No SSL certificate found, creating..."
			suuid = Digest::RMD160.hexdigest(ssl.context.key.public_key.to_s)
			cert = OpenSSL::X509::Certificate.new
			subject = "/O=SwarmP2P/OU=Swarm/CN=#{suuid}"
			cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
			cert.not_before = Time.now
			cert.not_after = Time.now + 365 * 24 * 60 * 60
			cert.serial = Time.now.to_i
			cert.version = 2
			cert.public_key = ssl.context.key.public_key
			cert.sign( ssl.context.key, OpenSSL::Digest::SHA256.new )
			File.write( ssl.x509_certificate, cert.to_pem + "\n" )

			# @todo - investigate the below signing extras
			#
			#ef = OpenSSL::X509::ExtensionFactory.new
			#ef.subject_certificate = cert
			#ef.issuer_certificate = cert
			#cert.extensions = [
			#  ef.create_extension("basicConstraints","CA:TRUE", true),
			#  ef.create_extension("subjectKeyIdentifier", "hash"),
			#  # ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
			#]
			#cert.add_extension ef.create_extension("authorityKeyIdentifier",
			#                                       "keyid:always,issuer:always")
			#cert.sign ssl.context.key, OpenSSL::Digest::SHA1.new

		end

		swdebug "Loading PKey #{ssl.x509_certificate}"
		ssl.context.cert = OpenSSL::X509::Certificate.new( File.read( ssl.x509_certificate ) )
		#@todo - Eh?
		#ssl.context.min_version = OpenSSL::SSL::TLS1_1_VERSION
		#ssl.context.max_version = OpenSSL::SSL::TLS1_2_VERSION
		#ssl.context.ssl_version = :SSLv3
		ssl.suuid = generate_suuid(ssl.context.key.public_key)
		ssl
	end # End swarm_ssl_init

	# Convenience method to output init data for user information
	# @param [Object] app Swarm app or compatible object
	#
	def self.swarm_describe(app)
		puts %{
==============================================================================
Swarm Init #{::VERSION}
Config File: #{File.join(app.cfg_dir,app.cfg_dir)}
Data Dir: #{app.swarm.data_dir}
==============================================================================
}
	end # swarm_describe

	# Utility Methods
	#===========================================================================

	# Get the suuid with pubkey provided.  Currently same as uuid generate.
	#
	# @param [String|Object] pubkey A public key string or object that responds to .to_s.
	# @return [String] A 20 character suuid based on the public key.
	#
	def generate_suuid(pubkey)
		generate_uuid(pubkey.to_s)
	end

	# Verify suuid.  FOr now, same as UUID, but abstracted if that changes.
	#
	# @param [String] suuid A suuid to check against.
	# @param [String|Object] pubkey A public key string or object that responds to .to_s.
	# @return [Boolean]
	#
	def verify_suuid(suuid,data)
		generate_suuid(data) == suuid
	end

	# Verify uuid against source data.  Currently same as suuid check.
	#
	# @param [String] uuid A uuid to check against.
	# @param [String|Object] pubkey A public key string or object that responds to .to_s.
	# @return [Boolean]
	#
	def verify_uuid(uuid,data)
		generate_uuid(data) == uuid
	end

	# NOTE: Not best for generating node ids.
	#
	# Generate a uuid with data or secure random.
	# Bees don't use this, but it is here in the event that a different sub-node class
	# might not want to use suuids.
	#
	# @param [String|Object] data Optional data to generate a uuid. Must respond to to_s
	#															if not provided, generate a SecureRandom.hex
	# @return [String] RMD160 hash "uuid" returned based on SecureRandom.
	#
	def generate_uuid(data="")
		data = data.to_s.empty? ? SecureRandom.hex(64) : data.to_s
		Digest::RMD160.hexdigest(data)
	end

	# Generate a uuid with secure random, which is not later verifiable, but easy :-)
	# @return [String] RMD160 hash "uuid" returned based on SecureRandom.
	#
	def generate_rand_uuid
		generate_uuid()
	end

	# Throw fatal logs and fail
	# @params [Array[String]] p Messages to log. Last one is fail error.
	#
	def swfail!(*p)
		swfatal(*p)
		fail("#{Time.now}::Fatal::"+p.last)
	end
	alias_method :swfail, :swfail!

	# @params [Array[String]] p Messages to log.
	#
	def swdebug(*p)
		@swarm_debug_logger ||= STDERR

		return nil if !swarm_debug_log

		p.each {|l|
			@swarm_debug_logger.puts("#{Time.now}::Debug::#{l}")
			$SWARM_SYSLOG.debug l
		}
	end

	# @params [Array[String]] p Messages to log.
	#
	def swlog(*p)
		@swarm_info_logger ||= STDOUT
		p.each {|l|
			@swarm_info_logger.puts("#{Time.now}::Info::#{l}")
			$SWARM_SYSLOG.info l
		}
	end
	alias_method :swinfo, :swlog

	# @params [Array[String]] p Messages to log.
	#
	def swwarn(*p)
		@swarm_warn_logger ||= STDOUT
		p.each {|l|
			@swarm_warn_logger.puts("#{Time.now}::Warning::#{l}")
			$SWARM_SYSLOG.warn l
		}
	end

	# @params [Array[String]] p Messages to log.
	#
	def swerror(*p)
		@swarm_error_logger ||= STDERR
		p.each {|l|
			@swarm_error_logger.puts("#{Time.now}::Error::#{l}")
			$SWARM_SYSLOG.error l
		}

	end

	# @params [Array[String]] p Messages to log.
	#
	def swfatal(*p)
		@swarm_error_logger ||= STDERR
		p.each {|l|
			@swarm_error_logger.puts("#{Time.now}::Fatal::#{l}")
			$SWARM_SYSLOG.fatal l
		}
	end


	[
		# Swarm debug log enables debug log output
		:swarm_debug_log,

		# IO handles for various log types, or any class that responds to puts.
		# @todo Verify this will work with logger in some fashion.
		# @todo document these in a Yarn compatible way
		:swarm_error_logger, :swarm_warn_logger, :swarm_debug_logger, :swarm_info_logger
	].each {|m|
		class_variable_set "@@#{m}",nil
		define_method("#{m}="){|io|
			SwarmP2P.class_variable_set "@@#{m}",io
			SwarmP2P.class_variable_get "@@#{m}"
		}
		define_method(m){
			SwarmP2P.class_variable_get "@@#{m}"			
		}
	}
	@@swarm_debug_log = false

	
	# Maintenance Methods
	#===========================================================================

	# Dynamic dir check and create ... jesus...
	# Returns the dir so you can set variables to a dir with this call and know
	# you have a working directory ... for the love of dog.
	#
	# @param dir [String] Directory to check and create if needed
	# @return [String] The directory name
	#
	def self.dyno_dir(d)
		return nil unless d
		if !Dir.exist?(d)
			warn "Creating missing directory #{d}"
			Pathname.new(d).mkpath
		end
		d
	end

	def self.load_relative(file,safe=nil)
		absolute = File.expand_path(file, __dir__)
		load absolute, safe
	end

  # Experimental required file reloader, mostly for IRB testing etc.
  # Not for general consumption!
  #
	def self.reload
		suppress_warnings {
			$SWARM_DIR_ORDER.each{|d|
				$SWARM_FILES[d].each{|f|
					dir = File.join('lib',$SWARM_DIR,d)
					if f == '*'
						glob = File.join('lib',$SWARM_DIR,d,'*.rb')
						Dir[glob].each{|ff| load File.join(dir,File.basename(ff)) }
					else
						load File.join(dir,"#{f}.rb")
					end
				}
			}
			load './lib/swarm_p2p.rb'
		}
		puts "Reloaded lib files.  Might have worked... good luck!"
		return true
	end

# @todo - still need or delete?
#	# File 'lib/core/facets/kernel/load_relative.rb', line 11
#	def aload_relative(relative_feature, safe=nil)
#		c = caller.first
#		fail "Can't parse #{c}" unless c.rindex(/:\d+(:in `.*')?$/)
#		file = $` # File.dirname(c)
##		if /\A\((.*)\)/ =~ file # eval, etc.
##			raise LoadError, "require_relative is called in #{$1}"
##		end
#		absolute = File.expand_path(relative_feature, File.dirname(file))
#		load absolute, safe
#	end

end
