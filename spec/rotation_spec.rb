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
	context "Interception T1 [A]" do
		before(:all) do
			@reward = Rotation.new(JSON.parse('{ "rewards": [{
				"_id": "c0400ac7082c2f3d811e47ca9b7a8ae8",
				"itemName": "Vitality",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "0bd85e0ab15774ad9a7ecc9340e4e7ad",
				"itemName": "Magazine Warp",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "3cb0fa05c766f182e58bb10462d2b3a4",
				"itemName": "Trick Mag",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "830b0bc4dbe549d5cb907162e67d7682",
				"itemName": "Synthula",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "49bcc45ccb51d3736b159cb10e3f5594",
				"itemName": "Lith H2 Relic",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "9786fe2fcc5920398e9e3d8f28881d21",
				"itemName": "Lith P1 Relic",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "5d58af8d5e702a2e34accd1c20151a9c",
				"itemName": "Lith O1 Relic",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "5a11cc6ac5f4f5d6ef6af2323cc44baa",
				"itemName": "Lith Z2 Relic",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "10a4f1fc42c313fe75d4ff958b85ee46",
				"itemName": "Lith C3 Relic",
				"rarity": "Uncommon",
				"chance": 10
			}, {
				"_id": "a5e70251bfe3077c21ac012179e76df1",
				"itemName": "Lith B5 Relic",
				"rarity": "Uncommon",
				"chance": 10
			}]}')["rewards"]) # Interception T1 Rotation A as of 2018-10-04
		end #before(:all)

		describe '@num_by_tier' do
			it "knows the number of rewards" do
				expect(@reward.num_by_tier).to eql({
					Lith: 6,
					non: 4,
					relic: 6,
					all: 10
				})
			end #it knows num of rewards
		end #describe @num_by_tier

		def float_eq(a,b,tolerance)
			return Math.abs(a-b) < tolerance
		end
		def float_hash_eq(a,b,tolerance)
			return (keys = Set.new(a.keys)) == Set.new(b.keys) && keys.all{|k|
				float_eq(a[k],b[k],tolerance)
			}
		end

		describe '@chance_tier' do
			it "knows the chances of each tier" do
				expect(@reward.chance_tier).to be_equal_hash_within(1e-7, {
					Lith: 0.6,
					non: 0.4,
					relic: 0.6
				})
			end #it knows chance of tier
		end #describe '@chance_tier'

		describe '@chance_each' do
			it "knows the avg chance of a single reward" do
				expect(@reward.chance_each).to be_equal_hash_within(1e-7, {
					Lith: 0.1,
					non: 0.1
				})
			end #it knows chance of each
		end #describe @chance_each

		describe '@tiers' do
			it "knows which tiers of rewards it has" do
				expect(@reward.tiers).to eql(Set[:Lith, :non])
			end #it knows which tiers it has
		end #describe @tiers
	end #context 6 lith relics 4 non
end #describe Rotation
