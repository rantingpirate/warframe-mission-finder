require 'mission'
require 'json'
require 'set'
require 'match_fhasheq'

# Put json in fixtures/mission.json
# json = Hash.new
# JSON.parse(File.read("spec/fixtures/endless.json"))

RSpec.shared_examples :Mission do |testset, i|
	before(:all) do
		@ts = testset[:answers]
		@mission = testset[:mission]
	end #before :all

	context "#{testset[:name]} (##{i+1})" do
		define "@num_by_tier" do
			it "knows the number of rewards per rotation" do
				expect(@mission.num_by_tier).to eql(@ts[:num_by_tier])
			end
		end #define num_by_tier
		define "@chance_tier" do
			it "knows the chance of getting a number of rewards of a tier" do
				expect(@mission.chance_tier).to(
					be_equal_array_hash_within(1e-7, @ts[:chance_tier])
				)
			end
		end #define chance_tier
		define "@chance_each" do
			it "knows the average chance of getting a number of a certain reward of a tier" do
				expect(@mission.chance_each).to(
					be_equal_array_hash_within(1e-7, @ts[:chance_each])
				)
			end
		end #define chance_each
		define "@mean_tier" do
			it "knows the average number of rewards of each tier for one rotation/full runthrough" do
				expect(@mission.mean_tier).to(
					be_equal_hash_within(1e-7, @ts[:mean_tier])
				)
			end
		end #@mean_tier
		define "@mean_each" do
			it "knows the average number of a specific reward of a tier for one rotation or full runthrough" do
				expect(@mission.mean_each).to(
					be_equal_hash_within(1e-7, @ts[:mean_each])
				)
			end
		end #@mean_each
		# define "@tiers" do	# covered by @tier_rot.keys
		# 	it "knows which tiers of rewards it has" do
		# 		expect(@mission.tiers).to eql(Set.new(@ts[:tiers]))
		# 	end
		# end #@tiers
		define "@tier_rot" do
			it "knows which rotations each tier is present in" do
				expect(@mission.tier_rot).to eql @ts[:tier_rot]
			end
		end #@tier_rot"
	end #context #{ts[:name]}
end #shared_examples Mission


RSpec.shared_examples :MissionClass do |mission_class|
	cname = mission_class.name
	testsets = JSON.parse(File.read("spec/fixtures/#{cname}.json"))[cname]
	RSpec.define "#{cname}" do
		testsets.each.with_index{|ts, i|
			ts.transform_keys!{|k| k.intern}
			ts[:mission] = mission_class.new(ts[:data])
			ts[:i] = i
			ts[:answers].transform_keys!{|k| k.intern}
				.values.each{|v| v.transform_keys!{|k| k.intern}}
			# ts[:answers][:tiers] = Set.new(ts[:tiers].map{|tier| tier.intern})
			ts[:answers][:tier_rot].transform_values!{|v|
				Set.new(v.map{|r| "nil" == r ? nil : r.intern})
			}
			include_examples :Mission, ts, i
		} #testsets.each
	end #RSpec.define "#{cname}"
end #shared_examples MissionClass

RSpec.describe "Mission" do
	[Endless, Rotated, Single].each{|mc| include_examples :MissionClass, mc}
end #define Mission
