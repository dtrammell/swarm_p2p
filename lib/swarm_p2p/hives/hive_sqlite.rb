# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Donovan A.
#
# Swarm SQLite Hive plugin
#
module HiveSqlite
	require "sequel"

	attr_reader :db
	attr_accessor :dir, :name

	def me
		method(__callee__).owner
	end

	# @see SwarmP2P::Hive
	# Initialize the SQLlite DB in addition to normal hive init.
	#
	def plugin_init(opts)
		@dir = opts[:dir] || fail("Hive needs a data directory")
		@name = opts[:name] || "HiveSqliteData"
		@db = Sequel.sqlite(File.join(dir,"#{name.snakecase}.db"))
		db_create
	end

	def db_create
		db_peers_create
		db_messages_create
		db_topics_create
	end

	# @see SwarmP2P::Hive
	def scorched_earth
		db.drop_table(:peers)
		db.drop_table(:messages)
		db.drop_table(:topics)
		db_create
	end

	# @see SwarmP2P::Hive
	[:peers,:messages,:topics].each{|table|
		define_method(table){ db[table.to_sym] }
	}

	# @see SwarmP2P::Hive
	def peers_store(data)
		new_count = 0
		update_count = 0
		data.each{|row|
			ret,peer = peer_store(row)
			ret == 'update' ? update_count += 1 : new_count +=1
		}
		record_count = peers.count
		unchanged_count = record_count - (update_count + new_count)
		{ records: record_count, updated: update_count, new: new_count, unchanged: unchanged_count }
	end

	# @see SwarmP2P::Hive
	def peers_load(cnt=50,offs=0)
		peers.limit(cnt).offset(offs).all
	end

	# @see SwarmP2P::Hive
	def peers_with_relation(uuid)
		list = peers.where(Sequel.ilike(:peers, "%#{uuid}%")).all
		list.reject!{|rec|
			uuids = rec[:peers].split(',')
			!uuids.include?(uuid)
		}
		list
	end

	def peers_random(query={},count)
		peers.where(query).order(Sequel.lit('RANDOM()')).limit(count)
  end

	# @see SwarmP2P::Hive
	def peer_load(uuid)
		peers.where(uuid: uuid).first
	end

	# @see SwarmP2P::Hive
	def peer_store(data)
		data = if data.is_a?(Node)
			peer_to_hash(data)
		elsif data.is_a?(String)
			peer_record_to_hash(data)
		elsif data.is_a?(Array)
			peer_array_to_hash(data)
		end

		data = peer_hash_defaults(data)
		validate_peer_data!(data)
		item = peers.where(uuid: data[:uuid]).first
		data.delete(:id)

		# @todo fix extra DB call on update...
		msg = if item
			data[:updated_at] = DateTime.now.to_s
			peers.where(uuid: data[:uuid]).update(data)
			'update'
		# @todo figure out if :update is a conflict option ... supposed to be, not working
		else
			peers.insert_conflict(:replace).insert(data)
			item = peers.where(uuid: data[:uuid]).first
			'insert'
		end
		[msg,item]
	end
	
	# Stores the message, agnostic of format, if it is a new message
	#
	def message_store(uuid,message)
		item = messages.where(uuid: uuid).first
		if item
			true
		else
			# @todo look up insert conflict options
			messages.insert_conflict(:replace).insert({
				uuid: uuid,
				content_type: message.class.to_s,
				content: message.to_json
			})
			false
		end
	end

	# @see SwarmP2P::Hive
  def describe
		db.tables.map{|table_name|
			table = db[table_name]
			{
				table: table_name,
				fields: table.columns,
				indexes: db.indexes(table_name),
				records: table.count,
#				schema: table.schema
			}
		}
	end

private

  # Database structures etc.  Temporary location for this stuff.

  # Create peer db table
  #@todo Sqlite need :id as primary key?  Unsure
	#	primary_key :id
	#@todo Default name to uuid...
  #
  def db_peers_create
		db.create_table? :peers do
			String :uuid, primary_key: true
			String :name, null: false
			String :host, null: false
			Integer :port, null: false
# @todo change to protocols array or table with handler included
			String :protocol, null: false
			String :handler, null: false
			String :hive_version, null: false
			Integer :ssl, null: false
			Integer :latency
			String :peers
			String :paths
			String :public_key
			String :created_at
			String :updated_at
# Error: `local': ArgumentError: mon out of range (Sequel::InvalidValue)
#			DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, :index=>true
#			DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP, :index=>true
			index [:uuid], unique: true
		end
	end

  # Create peer db table
  def db_messages_create
		db.create_table? :messages do
			String :uuid, primary_key: true
			String :content_type
			String :content
			DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, :index=>true
			index [:uuid], unique: true
		end
	end

	def db_topics_create
		db.create_table? :topics do
			String :uuid, primary_key: true
			Integer :enabled
			DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, :index=>true
			index [:uuid], unique: true
		end
	end

  # Create protocols to peers db table
  def db_protocols_create
		fail("Not implemented yet")
		db.create_table? :protocols do
			index [:uuid]
			String :protocol, default: protocol_type
			String :handler, default: handler_type
		end
	end

end
