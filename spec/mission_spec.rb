require 'mission'
require 'json'
require 'set'
require 'globals'

TOL = 1e-7

RSpec.shared_context :Mission do |mc, testsets|

	testsets.each.with_index{|ts, i|
		ts.transform_keys!{|k| k.intern}
		ts[:i] = i
		ts[:mission] = mc.new(ts[:data])
		ts[:answers].transform_keys!{|k| k.intern}
			.values.each{|v| v.transform_keys!{|k| k.intern}}
		ts[:answers][:tier_rot].transform_values!{|v|
			if ["nil"] == v
				nil
			else
				Set.new(v.map{|r| r.intern})
			end
		}
				it "##{i+1} (#{ts[:name]}) knows the number of rewards per rotation" do
					expect(ts[:mission].num_by_tier).to eql(ts[:answers][:num_by_tier])
				end
				it "##{i+1} (#{ts[:name]}) knows the chance of getting a number of rewards of a tier" do
					ans = ts[:answers][:chance_tier]
					act = ts[:mission].chance_tier
					expect(ts[:mission].chance_tier).to(
						match(ts[:answers][:chance_tier].transform_values{|v| match(v.map{|c| a_value_within(TOL).of(c)})})
					)
				end
				it "##{i+1} (#{ts[:name]}) knows the average chance of getting a number of a certain reward of a tier" do
					expect(ts[:mission].chance_each).to(
						match(ts[:answers][:chance_each].transform_values{|v| match(v.map{|c| a_value_within(TOL).of(c)})})
					)
				end
				it "##{i+1} (#{ts[:name]}) knows the average number of rewards of each tier for one rotation/full runthrough" do
					expect(ts[:mission].mean_tier).to(
						match(ts[:answers][:mean_tier].transform_values{|v| a_value_within(TOL).of(v)})
					)
				end
				it "##{i+1} (#{ts[:name]}) knows the average number of a specific reward of a tier for one rotation or full runthrough" do
					expect(ts[:mission].mean_each).to(
						match(ts[:answers][:mean_each].transform_values{|v| a_value_within(TOL).of(v)})
					)
				end
				it "##{i+1} (#{ts[:name]}) knows which rotations each tier is present in" do
					expect(ts[:mission].tier_rot).to eql ts[:answers][:tier_rot]
				end
	} #testsets.each
end #shared_examples Mission


RSpec.shared_context :MissionClass do |mission_class|
	cname = mission_class.name
	testsets = JSON.parse(File.read("spec/fixtures/#{cname}.json"))[cname]
	describe "#{cname}" do
		testsets.each.with_index{|ts, i|
			include_context :Mission, mission_class, ts
		} #testsets.each
	end #RSpec.define "#{cname}"
end #shared_examples MissionClass

RSpec.describe Endless do
	testsets = JSON.parse(File.read("spec/fixtures/Endless.json"))["Endless"]
	include_context :Mission, Endless, testsets
end #RSpec.describe Endless

RSpec.describe Rotated do
	testsets = JSON.parse(File.read("spec/fixtures/Rotated.json"))["Rotated"]
	include_context :Mission, Rotated, testsets
end #RSpec.describe Rotated

RSpec.describe Single do
	testsets = JSON.parse(File.read("spec/fixtures/Single.json"))["Single"]
	include_context :Mission, Single, testsets
end #RSpec.describe Single
