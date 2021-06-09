# Project: SwarmP2P
# @see https://github.com/dtrammell/swarm_p2p
# @author Dustin T., Donovan A.
#
# Swarm File Hive plugin
#
require 'search_in_file'

module HiveFile
	DELIMITER = ';;'.freeze

	attr_accessor :dir, :name
	attr_reader :peers, :messages, :hive_version, :protocol_version

	def me
		method(__callee__).owner
	end

	# @see SwarmP2P::Hive
	def plugin_init(opts={ })
fail "This plugin is not currently up to date."

		@name = opts[:name] || "HiveFileData"
		dir = opts[:dir] || fail("Hive needs a data directory")
		@hive_version = opts[:hive_version] || SwarmP2P::Hive::CURRENT_VERSION
		# @todo fix me! Get proper valeus from proper places
		@protocol_version = opts[:protocol_version] || '1.0.0' #SwarmP2P::Network::CURRENT_VERSION

		# Create our own HiveFile subdirectory
		@dir = SwarmP2P.dyno_dir( File.join(dir, name.snakecase) )

		# Setup for specific files, including creating if non-exist
		@peers = File.join(@dir, 'peers.dat' )
	  FileUtils.touch(@peers)

	end

	# @see SwarmP2P::Hive
	def peers_store(dataset)
		# Use a temp file to create new data file while we are in read mode of data file and overwrite
		peers_tmp_file = Pathname.new( @dir + '/peers.tmp' )
		peers_tmp = File.open(peers_tmp_file,'w')

		# Convert to hash of hash with uuid as key for fast lookups
    data_hash = {}
    dataset.each{|data|
			validate_peer_data!(data)
			data_hash[data[:uuid]] = data
		}

		line_count = 0
		update_count = 0
		new_count = 0
		preserved_count = 0

    # Open peer file, parse line by line.  If a uuid is found in data hash, update line, delete
    # data_hash entry, and write new line to temp file.  If uuid not in data hash, keep it and
    # write to temp file.
		File.foreach(peers) { | line |
			uuid = line.split(DELIMITER)[peer_keys.find_index(:uuid)]
			new_line = if data_hash[uuid]
				update_count +=1
				peer_record_from_hash(data_hash.delete(uuid))
			else
				preserved_count+=1
				line
			end
			peers_tmp.write("#{new_line}#{$/}")
			line_count += 1

		}
		# Any remaining entries in data hash are new and get added to temp file.
		data_hash.each_pair{|k,v|
			peers_tmp.write(peer_record_from_hash(v) + $/)
			new_count +=1
		}
		line_count += new_count
		peers_tmp.close

		# Overwrite data file with new temp file
		FileUtils.cp(peers_tmp_file,peers)
		FileUtils.rm_f(peers_tmp_file)

		@last_peer_pos = 0

		return { records: line_count, updated: update_count, new: new_count, unchanged: preserved_count }
	end

	# Destructive save, overwrites data.
	def peers_save!(dataset)
		File.open( peers, 'w' ) do | f |
			dataset.each{|data|
				validate_peer_data!(data)
				f.write "#{peer_record_from_hash(data)}#{$/}"
			}
		end
		line_count(peers)
	end

	# @see SwarmP2P::Hive
	#	# Bootstrap Peer List
	#	if @bootstrap_peer
	#		self.peer_list_add( @bootstrap_peer[:host], @bootstrap_peer[:port], @bootstrap_peer[:name], @bootstrap_peer[:uuid] )
	#
	#		@peer_list = Marshal.load( f )
	def peers_load(cnt=last_peer_count,offs=last_peer_pos)
		file = File.open( peers, 'r' )
		@last_peer_count = cnt if (cnt > 0) && (cnt != @last_peer_count)
		file.pos= offs	|| 0
		peer_hashes = []

		# Iterate line by line cnt times, converting record to hash, updating offset
		# tracking as you go.
		line = file.gets
		inc = 0
		while line
				inc+=1
				peer_hashes << peer_record_to_hash(line)
				break if inc == (cnt - 1)
				line = file.gets
				@last_peer_pos = file.pos
		end

		# @todo possible issue on end of records ... see last if condition...
		@last_peer_pos = 0 if peer_hashes.empty? #file.eof

		peer_hashes
	end
  alias_method :peers_next, :peers_load

	# @see SwarmP2P::Hive
	def peer_load(uuid)
		peer_hash = nil
		File.foreach(peers) { | line |
			r_uuid = line.split(DELIMITER)[peer_key_index(:uuid)]
			next if uuid != r_uuid
			peer_hash = peer_record_to_hash(line)
			break
		}
		peer_hash
	end

	# @see SwarmP2P::Hive
	def peer_store(data)
		validate_peer_data!(data)
		open(peers, 'a') { |f|
			f.write(peer_record_from_hash(data) + $/)
		}
	end

	# @see SwarmP2P::Hive
	def peers_with_relation(uuid)
		peer_hashes = []
		File.foreach(peers) { | line |
			uuid_list = line.split(DELIMITER)[peer_key_index(:peers)].split(',')
			peer_hashes << peer_record_to_hash(line) if uuid_list.include?(uuid)
		}
		peer_hashes
	end

	# @see SwarmP2P::Hive
  def describe
		return {
			type: self.class.name,
			description: 'Basic file storage Hive',
			directory: dir,
			files: {
				peers: peers
			}
		}
	end

	# @see SwarmP2P::Hive
	def scorched_earth
		File.delete(peers)
		FileUtils.remove_dir(dir)
	end

	# Below here, all methods are specific to this Hive module and not universal Hive interface methods.

	# Count lines of file fast (low level ruby C binding call)
	#
	# @param file [String] Filename with full path
	# @return [Integer] LIne count
	def line_count(file)
		f = File.new(file)
		num_newlines = 0
		while (c = f.getc) != nil
			num_newlines += 1 if c == $/
		end
		num_newlines
	end

end
