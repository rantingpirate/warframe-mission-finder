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
			#T1 Interception A - Lith + non
			@reward1 = Rotation.new(JSON.parse('{ "rewards": [
				{
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
				}
			]}')["rewards"])

			#T2 Interception C - Neo
			@reward2 = Rotation.new(JSON.parse('{ "C": [
				{
					"_id": "edf6e02da7cd769e2ef7e2304588a3cf",
					"itemName": "Neo S7 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "9775655780fe4a7724604a80e9d2e061",
					"itemName": "Neo M1 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "bbb274f2dfe06056f18631b60f4f6904",
					"itemName": "Neo L1 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "dcbb8799d88967ca23949f26afe890cd",
					"itemName": "Neo N8 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "2a24ac7e185bfb16e858ade71072d5b3",
					"itemName": "Neo B5 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "10b3e169367737955b214c868ada8f02",
					"itemName": "Neo K2 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "179ddb606841b8413063bff1cf8649ec",
					"itemName": "Neo G1 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "f58ec2a5bef670da23dd6bdd56fc0d48",
					"itemName": "Neo A2 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}, {
					"_id": "ee0e96031108011e1839b9cffb193aae",
					"itemName": "Neo H2 Relic",
					"rarity": "Uncommon",
					"chance": 11.11
				}
			]}')["C"])

			#DS Defence C - Meso + Neo + non
			@reward3 = Rotation.new(JSON.parse('{ "C": [
				{
					"_id": "2ad0245c6d5a228e1be1b32e8a755de9",
					"itemName": "Hellfire",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "a194c9886416edb9e62292dfb9c5616f",
					"itemName": "Heated Charge",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "5a718a4c673b01e82406be1fc9cef491",
					"itemName": "Molten Impact",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "15289bd8046419b1caef1dd087843eda",
					"itemName": "Barrel Diffusion",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "668c39e0dc06284d37ed849abaa09f31",
					"itemName": "Streamline",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "cc79d6a82a335af95e5727430ef51841",
					"itemName": "Intensify",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "edf6e02da7cd769e2ef7e2304588a3cf",
					"itemName": "Neo S7 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "7f428e9e9c552cb53e9b40bdd57be587",
					"itemName": "Thunderbolt",
					"rarity": "Legendary",
					"chance": 0.4
				}, {
					"_id": "d28ee6279a71bde6bfd02ff4584de946",
					"itemName": "50 Endo",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "84ff01cdfaf6a03db1727013086e63ee",
					"itemName": "80 Endo",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "9775655780fe4a7724604a80e9d2e061",
					"itemName": "Neo M1 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "c626a74bf3c1450bf107abfaa92a4bd3",
					"itemName": "True Punishment",
					"rarity": "Legendary",
					"chance": 0.4
				}, {
					"_id": "012914188142a00d062d093ef61acad4",
					"itemName": "Quickening",
					"rarity": "Legendary",
					"chance": 0.4
				}, {
					"_id": "bcc7c5c3b29424d0f64deed29a58f294",
					"itemName": "Enduring Strike",
					"rarity": "Legendary",
					"chance": 0.4
				}, {
					"_id": "86009854add0e510f8a9b87a5c72d8b4",
					"itemName": "Life Strike",
					"rarity": "Legendary",
					"chance": 0.4
				}, {
					"_id": "66d030ef9602c1a4767e90e84b6f24b3",
					"itemName": "Meso T1 Relic",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "78ba7306d460bd998fe610790133bc74",
					"itemName": "Meso Z1 Relic",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "6b402256e3b353e89108c44e5aaebafc",
					"itemName": "Meso B2 Relic",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "bbb274f2dfe06056f18631b60f4f6904",
					"itemName": "Neo L1 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "dcbb8799d88967ca23949f26afe890cd",
					"itemName": "Neo N8 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "2a24ac7e185bfb16e858ade71072d5b3",
					"itemName": "Neo B5 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "cab467816b762dc0be43158963c04839",
					"itemName": "Meso S8 Relic",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "45cfb8831fca98c960bfa6786b38054d",
					"itemName": "Meso T3 Relic",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "86c7cf31eef89ba012fe2ecc7c64a8e7",
					"itemName": "Meso D3 Relic",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "d6733d1318ee52b3e93324a13912e341",
					"itemName": "Meso R1 Relic",
					"rarity": "Rare",
					"chance": 7.59
				}, {
					"_id": "10b3e169367737955b214c868ada8f02",
					"itemName": "Neo K2 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "179ddb606841b8413063bff1cf8649ec",
					"itemName": "Neo G1 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "f58ec2a5bef670da23dd6bdd56fc0d48",
					"itemName": "Neo A2 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}, {
					"_id": "ee0e96031108011e1839b9cffb193aae",
					"itemName": "Neo H2 Relic",
					"rarity": "Rare",
					"chance": 1.58
				}
			]}')["C"])
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
