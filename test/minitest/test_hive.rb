require "minitest/autorun"
require 'pathname'
require "swarm_p2p.rb"

class TestHive < Minitest::Test

  def setup
		@hive = SwarmP2P::Hive.new(data_dir: "./test_hive", type: 'HiveFile')
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

  def test_that_hive_is_file_type
    assert_equal "HiveFile", @hive.hive_type
  end

	def test_that_peers_setup
		assert @hive.peers.is_a?(String)
	end

	def test_that_peers_store
		assert @hive.line_count(@hive.peers) == 10
	end

	def test_that_peers_load
		assert_equal 10, @hive.peers_load(50).count
	end

	def test_that_a_peer_loads
		node = @hive.peer_load('testnode_uuid_1')
		assert 'testnode_uuid_1',node[:uuid]
		assert '127.0.0.1',node[:ip]
	end

	def test_that_a_peer_stores
		i = 111
		cnt = @hive.line_count(@hive.peers)
		@hive.peer_store({
										uuid: "testnode_uuid_#{i}",
										name: "TestNode#{i}",
										ip: "127.0.0.#{i}",
										created_at: Time.now,
										peers:["testnode_uuid_b#{i}","testnode_uuid_c#{i}","queennode_01"]
		})
		assert cnt = @hive.line_count(@hive.peers) + 1
		assert @hive.peer_load("testnode_uuid_111")[:uuid] == "testnode_uuid_111"
	end

	def test_peer_relation_search
		assert_equal 10, @hive.peers_with_relation("queennode_01").count
		assert_equal 'testnode_uuid_0', @hive.peers_with_relation("queennode_01").first[:uuid]
		assert_equal 1, @hive.peers_with_relation("testnode_uuid_b5").count
	end

end
