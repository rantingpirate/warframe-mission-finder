require 'reward'
require 'json'
require 'set'
require "match_fhasheq"

$relics_by_id = Hash.new
$relics_by_name = Hash.new

$test_sets = JSON.parse(File.read('spec/fixtures/rotation.json'))["testsets"]
$test_sets.each{|ts|
	ts.transform_keys!{|k| k.intern}
		.reject{|k,v| :data == k}
		.transform_values!{|v| v.transform_keys!{|k| k.intern}}
	ts[:rotation] = Rotation.new(ts[:data])
}

RSpec.describe Rotation, "" do
	describe '@num_by_tier' do
		$test_sets.each.with_index{|testset,i|
			it "knows the number of rewards (#{i+1})" do
				rot = testset[:rotation]
				ans = testset[:num_by_tier]
				expect(rot.num_by_tier).to eql(ans)
			end #it knows num of rewards
		}
	end #describe @num_by_tier

	describe '@chance_tier' do
		$test_sets.each.with_index{|testset,i|
			it "knows the chances of each tier (#{i+1})" do
				rot = testset[:rotation]
				ans = testset[:chance_tier]
				expect(rot.chance_tier).to be_equal_hash_within(1e-7, ans)
			end #it knows chance of tier
		}
	end #describe '@chance_tier'

	describe '@chance_each' do
		$test_sets.each.with_index{|testset,i|
			it "knows the avg chance of a single reward (#{i+1})" do
				rot = testset[:rotation]
				ans = testset[:chance_each]
				expect(rot.chance_each).to be_equal_hash_within(1e-7, ans)
			end #it knows chance of each
		}
	end #describe @chance_each

	#I really should test @tiers, but I don't wanna.
end #describe Rotation
