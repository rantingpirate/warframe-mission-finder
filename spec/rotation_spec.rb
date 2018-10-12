require 'reward'
require 'json'
require 'set'
require "match_fhasheq"

RSpec.describe Rotation, "" do
	before(:all) do
		$relics_by_id = Hash.new
		$relics_by_name = Hash.new
	end
	#tests
	context "" do
		before(:all) do
			json = JSON.parse(File.read('spec/fixtures/rotation.json'))

			#T1 Interception A - Lith + non
			@reward1 = Rotation.new(json["T1InterceptionA"])

			#T2 Interception C - Neo
			@reward2 = Rotation.new(json["T2InterceptionC"])

			#DS Defence C - Meso + Neo + non
			@reward3 = Rotation.new(json["DSDefenseC"]) #defenSe because 'MURICA!!!

		end #before(:all)

		describe '@num_by_tier' do
			it "knows the number of rewards" do
				expect(@reward1.num_by_tier).to eql({
					Lith: 6,
					non: 4,
					relic: 6,
					all: 10
				})
				expect(@reward2.num_by_tier).to eql({
					Neo: 9,
					relic: 9,
					all: 9
				})
				expect(@reward3.num_by_tier).to eql({
					non: 13,
					Meso: 7,
					Neo: 9,
					relic: 16,
					all: 29,
				})
			end #it knows num of rewards
		end #describe @num_by_tier

		describe '@chance_tier' do
			it "knows the chances of each tier" do
				expect(@reward1.chance_tier).to be_equal_hash_within(1e-7, {
					Lith: 6 * 0.1,
					non: 4 * 0.1,
					relic: 0.6
				})
				expect(@reward2.chance_tier).to be_equal_hash_within(1e-9, {
					Neo: 1.0,
					relic: 1.0
				})
				expect(@reward3.chance_tier).to be_equal_hash_within(1e-7, {
					Neo: 0.0158 * 9,
					Meso: 0.0759 * 7,
					relic: 0.0158 * 9 + 0.0759 * 7,
					non: 0.0759 * 3 + 0.0158 * 5 + 0.004 * 5
				})
			end #it knows chance of tier
		end #describe '@chance_tier'

		describe '@chance_each' do
			it "knows the avg chance of a single reward" do
				expect(@reward1.chance_each).to be_equal_hash_within(1e-7, {
					Lith: 0.1,
					non: 0.1
				})
				expect(@reward2.chance_each).to be_equal_hash_within(1e-7, {
					Neo: 1.0 / 9
				})
				expect(@reward3.chance_each).to be_equal_hash_within(1e-7, {
					Neo: 0.0158,
					Meso: 0.0759,
					non: (0.0759 * 3 + 0.0158 * 5 + 0.004 * 5)/13
				})
			end #it knows chance of each
		end #describe @chance_each

		describe '@tiers' do
			it "knows which tiers of rewards it has" do
				expect(@reward1.tiers).to eql(Set[:Lith, :non])
			end #it knows which tiers it has
		end #describe @tiers
	end #context 6 lith relics 4 non
end #describe Rotation
