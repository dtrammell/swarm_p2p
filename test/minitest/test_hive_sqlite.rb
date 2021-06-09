require "minitest/autorun"
require "swarm_p2p.rb"

class TestHiveSqlite < Minitest::Test

  def setup
		@hive = SwarmP2P::Hive.new(dir: "./test_hive", type: 'HiveSqlite')
		10.times {|i|
			@hive.peers_store([{
										uuid: "testnode_uuid_#{i}",
										name: "TestNode#{i}",
										ip: "127.0.0.#{i}",
										created_at: Time.now,
										peers:["testnode_uuid_b#{i}","testnode_uuid_c#{i}","queennode_01"]
			}])
		}
	end

	def teardown
		@hive.scorched_earth
	end

  def test_that_hive_is_sqlite
    assert_equal "HiveSqlite", @hive.hive_type
		assert @hive.db.is_a?(Sequel::SQLite::Database)
		assert_equal :sqlite, @hive.db.adapter_scheme
  end

	def test_that_peers_store
		assert @hive.peers.all.count == 10
	end

	def test_that_peer_store
		i = 111
		cnt = @hive.peers.all.count
		@hive.peer_store({
										uuid: "testnode_uuid_#{i}",
										name: "TestNode#{i}",
										ip: "127.0.0.#{i}",
										created_at: Time.now,
										peers:["testnode_uuid_b#{i}","testnode_uuid_c#{i}","queennode_01"]
		})
		assert cnt = @hive.peers.all.count + 1
		assert @hive.peer_load("testnode_uuid_111")[:uuid] == "testnode_uuid_111"
	end

	def test_that_peers_load
		assert_equal 10, @hive.peers_load(50).count
	end

	def test_that_a_peer_loads
		node = @hive.peer_load('testnode_uuid_1')
		assert 'testnode_uuid_1',node[:uuid]
		assert '127.0.0.1',node[:ip]
	end

	def test_peer_relation_search
		assert_equal 10, @hive.peers_with_relation("queennode_01").count
		assert_equal 'testnode_uuid_0', @hive.peers_with_relation("queennode_01").first[:uuid]
		assert_equal 1, @hive.peers_with_relation("testnode_uuid_b5").count
	end

end
