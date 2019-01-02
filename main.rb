#!/bin/ruby

require_relative "lib/data"
require_relative "lib/reward"
require_relative "lib/globals"
require_relative "lib/mission"

require 'optparse'

$display_each = nil
$force_reparse = nil
$show_void = nil
$num_best = 3
$num_void = 1

EACH_DEFAULT = false

def jround(num, sf, pre = "", is_percent: false, show_percent: true, min_places: nil)
	num = num || 0
	num *= 100 if is_percent
	after = (is_percent and show_percent) ? "%%" : ""
	places = (0 == num) ? 1 : (Math.log10 num).floor + 1
	if places > sf
		return ("%#{pre}.#{sf}g#{after}" % num)
	else
		fto = min_places ? [min_places, sf - places].min : sf - places
		return ("%#{pre}.#{fto}f#{after}" % num)
	end #if places > sf
end #def jround

def simple_display(pool, reward_tier, is_each = false)
	header = ""
	header.concat("#{pool.tier} ") if pool.tier
	header.concat(pool.mode.to_s)
	if pool.tier_rot.has_key? reward_tier and pool.tier_rot[reward_tier]
		rot = pool.tier_rot[reward_tier].sort
		if :Endless == pool.mission_type && :A == rot[0]
			#Endless missions rotate AABC, not ABC
			rot.unshift(:A)
		end #if pool.mission_type == Endless
		if :Excavation == pool.mode
			rot *= EXCAV_MUL
		end
		header.concat(" [#{rot.map{|r| r.to_s}.join("")}]")
	end #if pool.tier_rot[reward_tier]
	if is_each then
		mean = pool.mean_each[reward_tier]
		chance = pool.chance_each[reward_tier]
	else
		mean = pool.mean_tier[reward_tier]
		chance = pool.chance_tier[reward_tier]
	end

	numsOne = jround(mean, 3)
	numsTwo = ""
	numsTwo = "[#{chance.map{|ch| jround(ch, 3, is_percent: true)}.join(", ")}]" if chance

	if not is_each and RELIC_TIERS.include? reward_tier
		numsOne.concat("/#{jround(pool.mean_tier[:relic], 3)}")
	end

	puts "#{header}: #{numsOne} #{numsTwo}"
	pool.fetch_nodes
		.select{|n| not n[:isEvent]}
		.sort{|a,b|
			planet_sort(a,b)
		}
		.each{|n| puts "  #{n[:fullName]}#{n[:isEvent] ? " [Event]" : ""}"}
end

parser = OptionParser.new do |parser|
	parser.on("-e", "--each", "Print the chance and mean for a specific relic") do
		$display_each = :each
	end
	parser.on("-a", "--all", "Print the chance and mean for some relic") do
		$display_each = :all
	end
	parser.on("-f", "--force-reparse", "Re-parse the drop data, even if up-to-date") do
		$force_reparse = true
	end
	parser.on("-n", "--number", "=[NUMBER]", Integer, "Print this many nodes per tier") do |n|
		$num_best = n
	end
	parser.on("-N", "--num-vault", "--num-void", "=[NUMBER]", Integer, "Print this many void missions per tier") do |n|
		$num_void = n
	end
	parser.on("--vault", "Parse the drop data for the vault being open.") do
		$vault_open = true
	end
	parser.on("--no-vault", "Parse the drop data for the vault being closed.") do
		$vault_open = false
	end
	parser.on("-v", "--void-only", "Only show void missions.") do
		$show_void = :only
	end
	parser.on("-V", "--no-void", "Don't show void missions.") do
		$show_void = :none
	end
end

parser.parse!(ARGV)
tiers = ARGV.length > 0 ? ARGV.map{|t| t.downcase().intern} : RELIC_TIERS.to_a + [:relic]

load_data($force_reparse)
puts "each is #{$display_each}" #DEBUG #EACH
(RELIC_TIERS.to_a + [:relic]).each{|tier|
	puts "#{tier}:"
	eachopt = (nil == $display_each) ? EACH_DEFAULT : ($display_each == :each)
	puts "eachopt for #{$display_each}, #{EACH_DEFAULT} is #{eachopt}"
	puts "true and false is #{true and false}"
	iseach = (RELIC_TIERS.include?(tier) and eachopt)
	puts "iseach for #{tier}, #{$display_each}, #{EACH_DEFAULT} is #{iseach}" #DEBUG #EACH
	nodes = best_nodes(tier, $num_best, poolType: :Endless, each: iseach, voidnodes: $show_void)
	if $num_best then
		nodes.each{|p|
			simple_display(p, tier, is_each: iseach)
			puts ""
		}
	else
		simple_display(nodes, tier, is_each: iseach)
		puts ""
	end
	if $num_void and $num_void > 0 and nil == $show_void then
		best_nodes(tier, $num_void, poolType: :Endless, each: iseach, voidnodes: :only).each{|p|
			simple_display(p, tier, is_each: iseach)
			puts ""
		}
	end
	puts ""
}
