require 'mission'
require 'json'
require 'set'
require 'match_fhasheq'

# Put json in fixtures/mission.json
$all_test_sets = JSON.parse(File.read("spec/fixtures/missions.json"))

RSpec.shared_examples :Mission do |testset|
	mission = testset[:mission]
	mtype = testset[:mission].class.name
	i = testset[:i]
	it "knows the number of rewards per rotation (#{i+1})" do
	

RSpec.shared_examples :Missions do |mission_type, mission_class|
	before(:context) do
		@test_sets = $all_test_sets[mission_type]
		@test_sets.each{|ts| ts[:mission] = mission_class.new(ts[:data])}
	end

	describe "#{mission_type}.num_by_tier" do
		@test_sets.each.with_index{|testset,i|
				msn = testset[:mission]
				ans = testset[:num_by_tier]
				expect(msn.num_by_tier).to eql(ans)
			end
		}
	end #describe @num_by_tier

	describe "#{mission_type}.chance_tier" do
		@test_sets.each.with_index{|testset,i|
			it "knows the chance of getting a number of rewards of a tier(#{i+1})" do
				msn = testset[:mission]
				ans = testset[:num_by_tier]
				expect(msn.chance_tier).to be_equal_array_hash_within(1e-7, ans)
			end
		}
	end #describe @chance_tier

	describe "#{mission_type}.chance_each" do
		@test_sets.each.with_index{|testset,i|
			it "knows the average chance of getting a number of a certain reward of a tier(#{i+1})" do
				msn = testset[:mission]
				ans = testset[:num_by_tier]
				expect(msn.chance_each).to be_equal_array_hash_within(1e-7, ans)
			end
		}
	end #describe @chance_each

	describe "#{mission_type}.mean_tier" do
		@test_sets.each.with_index{|testset,i|
			it "knows the average number of rewards of each tier for one rotation/full runthrough(#{i+1})" do
				msn = testset[:mission]
				ans = testset[:num_by_tier]


RSpec.describe "Missions" do
	describe Endless do
		describe "@num_by_tier" do
			$test_sets.each.with_index{|testset,i|
				it "knows the number of rewards for each rotation" do
					msn = testset[:mission]


