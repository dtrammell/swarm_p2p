# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Swarm Storage Hive base class
#
# Most methods here are place holders and MUST be overridden by the
# specific Hive plugin.  Default plugin is File, which is non-optimal for
# searches etc.
#
# Plugins are modules that are included and must implement caller methods.
# @todo Document the plugin methods
#
module SwarmP2P

	class Hive
		include SimplePlugin

		CURRENT_VERSION = '1.0.0'

		DELIMITER = ';;'.freeze

		# Expected data for a peer, per version, and description.
		PEER_FIELDS = {
			'1.0.0' => {
				hive_version: 'The storage format version',
				uuid: 'Unique ID',
				name: 'Optionally provided name of the node',
				host: 'Last known IP/Hostname address',
				port: 'Service port',
				ssl: 'SSL enabled or not',
				handler: 'Message handler type.',
				protocol: 'Primary protocol served.',
				created_at: 'When this entry was first created',
				updated_at: 'When this entry was updated',
				latency: 'Number of hops to this peer. TBD',
				peers: 'comma delimited list of the last set of connected peers. TBD',
				paths: 'Ancestry tree of path to this peer from this node.  TBD',
			}
		}.freeze

		# Ordered (if relevant) data field keys to convert to and from other structures
		DATA_FIELDS = {
			'1.0.0' => [
					:hive_version, :uuid, :name, :created_at, :updated_at,
					:host, :port, :handler, :protocol, :ssl, :latency, :peers, :paths
			]
		}.freeze

		# Unusual field maps between field name and node methods
		# version: field: method
		FIELD_METHODS = {
			'1.0.0' => {
				protocol: :protocol_type,
				handler: :handler_type,
				peers: :known_peers,
				ssl: :ssl_binary
			}
		}.freeze

		attr_reader :data_dir, :hive_name

		#@todo document after finalize
		#
		# dir | data_dir [String] Where the data will be stored
		# name [String] Name for the hive storage (used as needed in specific implementations
		# hive_dir [String] Where plugins shall be found
		# type [String] Name of plugin to be used
		# hive_config [Hash] Specific parameters to be passed on to the plugin used
		#
		def initialize(opts={})
      opts[:dir] ||= opts[:data_dir]
			@data_dir = SwarmP2P.dyno_dir(opts[:dir] || File.join(Dir.home,'swarm_data'))
			@hive_name = opts[:name] || nil # Just being explicit we don't set this here...

			# Plugin options and init
			@plugin_config = opts[:plugin_config] || {}
			@plugin_dir = opts[:plugin_dir] || File.join(__dir__,"hives")
			@plugin_type = opts[:type] || :HiveSqlite

			load_plugin(@plugin_type,@plugin_dir)
			plugin_init({
				dir: data_dir,
				name: hive_name,
				config: plugin_config
			})
		end

		# Below here are methods that must be overriden in specific Hive plugin
		#
		# @param [Hash] data @todo document!
		# 	Specific Hive type init, override in your  module. Options are:
		#  		dir: The data directory for the hive
		#  		name: The name for the hive, used for file basenames or DB names
		# 		config: A hash containing any Hive type specifics that must be passed by caller,
		# 		and need to be documented in on the override method in your module.
		#
		def hive_store_init(opts)
			warn "Hive plugin must override this!"
			return nil
		end

		# Store a peer list for this network
		#
		# @param [Array[Hash]] data @todo document!
		# @return [Hash] Hive specific information fields.  No standard set.
		# @todo expand and define the peer list format (extendible)
		#
		def peers_store(data)
			warn "Hive plugin must override this!"
			return nil
		end

		# Load a peer list for this network
		#
		# @param [Integer] cnt (Optional) Defaults to 50.  Number of peers to return.
		# @param [Integer] offset (Optional) Defaults to 0.  Where to start peer read index.
		# @return [Array] List of peers, host, and routing information.
		# @todo expand and define the peer list format (extendible)
		#
		def peers_load(cnt=50,offs=0)
			warn "Hive plugin must override this!"
			return nil
		end

		# @todo document
		def peers_with_relation(uuid)
			warn "Hive plugin must override this!"
			return nil
		end

		# Random matching peers retrieval.
    #
		# @param [Hash] query Hash of column->value criteria
    # @param [Integer] count Limit to count #
		def peers_random(query={},count=20)
			warn "Hive plugin must override this!"
			return nil
		end

		# Retrieve record for peer by UUID
		#
		# @param [String] uuid The Unique, Universal ID of a peer
		# @return [Object|Nil] Returns record or nil
		#
		def peer_load(uuid)
			warn "Hive plugin must override this!"
			return nil
		end

		# Store (create) or update a peer with provided data.
		#
		# @param [Hash] data Peer data hash
		# @todo define this hash
		# @return [Boolean] Success
		#
		def peer_store(data)
			warn "Hive plugin must override this!"
			return nil
		end

		# Find any peers with the specified peer relation
		#
		# @param [String] uuid
		# @return [Array[Hash]] Peer data hash
		#
		def peers_with_relation(uuid)
			warn "Hive plugin must override this!"
			return nil
		end

		# Get a hash of some useful data of this Hive.  Each HiveType is left up to it's
		# own devices and decisions about what to include here.
		#
		def describe
			return {}
		end

		# Destroy all saved data!  Danger!
		def scorched_earth
			warn "Hive plugin should override this!"
			return true
		end

		# Below here are methods that are either optional or not recommended to override

		# Validatations on peer data.  Minimal implmenetation atm. DB with also throw errors.
		# Throws error on fatal issue, warning on non-fatal.
		#
		def validate_peer_data!(data)
			[:uuid,:host,:port].each{|k|
				data[k] || fail("Peer data does not meet requirements.  #{k} is a required field.  See Hive documentation.")
			}
			keys = peer_fields.keys
			data.keys.each{|k|
				keys.include?(k) || warn("Provided key #{k} will not be stored with peer data")
			}
			true
		end

		# Get last line loaded in call to load, defaulted to 0 if nil.
		# @return [Integer] Last line end position of load
		#
		def last_peer_pos
			@last_peer_pos ||= 0
		end

		# Get last set count for load
		# @return [Integer] Last line end position of load
		#
		def last_peer_count
			@last_peer_count ||= 50
		end

		# Get last line loaded in call to load, defaulted to 0 if nil.
		# @return [Integer] Last line end position of load
		#
		def reset_peer_counters
			@last_peer_pos = 0
			@last_peer_count |= 50
		end

		# Peer fields and descriptions.
		# @todo change to constant for now?  Probably.
		#
		def peer_fields(version=Hive::CURRENT_VERSION)
			PEER_FIELDS[version]
		end

		def peer_keys(version=CURRENT_VERSION)
			DATA_FIELDS[version]
		end

		def peer_key_index(key,version=CURRENT_VERSION)
			DATA_FIELDS[version].index(key)
		end

		def peer_method_map(version=CURRENT_VERSION)
			FIELD_METHODS[version]
		end

		def hive_version
			CURRENT_VERSION				
		end

		def handler_type
			'P2pMainV1'
		end

		def protocol_type
			'ThreadTcp'	
		end

		#------------------------------------------------------------------
		# Peer conversions below between hash,array,string (record)
		#------------------------------------------------------------------

		# Fill out some hash defaults as needed
		#
		# @param [Hash] data Peer record hash
		# @return [Hash]
		#
		def peer_hash_defaults(phash)
			data = phash.dup
			data[:port] ||= 3333 # @todo Network;:DEFAULT_PORT
			data[:name] ||= "SwarmNode_#{data[:uuid]}"
			data[:hive_version] ||= hive_version
			data[:handler] ||= handler_type
			data[:protocol] ||= protocol_type
			data[:ssl] ||= 1
			data[:peers] ||= []
			if data[:peers].is_a?(Array)
				data[:peers] = data[:peers].join(',')
			end
#			data[:created_at] ||= DateTime.now.to_s
#			data[:updated_at] ||= DateTime.now.to_s
			data
		end
		
		# Hash peer to record line
		#
		# @param [Hash] data Peer record hash
		# @return [String]
		#
    # @todo deal with protocol_version somehow...
		#
		def peer_record_from_hash(data)
			fields = []
			local_data = peer_hash_defaults(data)
			peer_keys.each{|k|
				fields << local_data[k] || ''
			}
			"#{fields.join(DELIMITER)}"
		end

		def peer_record_from_peer(peer)
			peer_record_from_hash(peer_to_hash(peer))
		end

		# Array peer record to hash
		#
		# @param [Array] data Peer record array
		# @return [Hash]
		#
		def peer_array_to_hash(data)
			phash = {}
			peer_keys.each_with_index{|k,i|
				phash[k] = data[i] || ''
			}
			phash[:peers] = phash[:peers].split(',')
			peer_hash_defaults(phash)
		end
	
		# Peer object to hash
		#
		# @param [Node] peer Node object to hash
		# @return [Hash]
		#
		def peer_to_hash(peer)
			peer_hash = {}
			peer_keys.each{|k|
				peer_hash[k] = if peer_method_map[k] && peer.respond_to?(peer_method_map[k])
					peer.send(peer_method_map[k])	
				elsif peer.respond_to?(k)
					peer.send(k)
				# else nil
				end
			}
			peer_hash_defaults(peer_hash)
		end

		# Peer object to hash
		#
		# @param [Node] peer Node object to hash
		# @return [Hash]
		#
		def peer_from_hash(hash)
			test_peer = Peer.new({})
			peer_opts = {}
			peer_keys.each{|k|
				 if peer_method_map[k] && test_peer.respond_to?(peer_method_map[k])
					peer_opts[peer_method_map[k]] = hash[k]
				elsif test_peer.respond_to?(k)
					peer_opts[k] = hash[k]
				# else nil
				end
			}
			Peer.new(peer_opts)
		end

		# Peer record line to hash
		#
		# @param [String] line Peer record string
		# @return [Hash]
		#
		def peer_record_to_hash(line)
			peer_array_to_hash(line.split(DELIMITER))
		end

	end # End Hive

end
