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
$mission_mode = nil
$show_nodes = nil

EACH_DEFAULT = :all
INDENT = "  "
MISSION_DEFAULT = :relics
# NODES_DEFAULT = :show
def mission_mode?() return :mission == ($mission_mode or MISSION_DEFAULT) end
def display_each?() return :each == ($display_each or EACH_DEFAULT) end
# def hide_nodes?() return $show_nodes ? :hide == $show_nodes : mission_mode? end
def show_nodes?() return $show_nodes ? :show == $show_nodes : (not mission_mode?) end

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

def display_pool(pool, is_each = false)
    main_header = ""
    main_header.concat("#{pool.tier} ") if pool.tier
    main_header.concat(pool.mode.to_s)
    main_header.concat(pool_rotations(pool, :relic))
    mainOne, mainTwo = pool_nums(pool, :relic, is_each)

    puts "#{main_header}: #{mainOne} #{mainTwo}"
    RELIC_TIERS.to_a
        .select{|tier| pool.tier_rot.has_key? tier and pool.tier_rot[tier]}
        .each {|tier|
            header = "#{tier}#{pool_rotations(pool, tier)}"
            numOne, numTwo = pool_nums(pool, tier)
            puts "#{INDENT*2}#{header}: #{numOne} #{numTwo}"
        }
    print_nodes(pool, INDENT) if show_nodes?
end

def pool_rotations(pool, reward_tier)
	if pool.tier_rot.has_key? reward_tier and pool.tier_rot[reward_tier]
		rot = pool.tier_rot[reward_tier].sort
		if :Endless == pool.mission_type && :A == rot[0]
			#Endless missions rotate AABC, not ABC
			rot.unshift(:A)
		end #if pool.mission_type == Endless
		if :Excavation == pool.mode
			rot *= EXCAV_MUL
		end
        return " [#{rot.map{|r| r.to_s}.join("")}]"
    else return ""
	end #if pool.tier_rot[reward_tier]
end
def pool_nums(pool, reward_tier, is_each = false)
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
    return [numsOne, numsTwo]
end
def print_nodes(pool, header = "")
    pool.fetch_nodes
        .select{|n| not n[:isEvent]}
        .sort{|a,b|
            planet_sort(a,b)
        }
        .each{|n| puts "#{header}#{n[:fullName]}#{n[:isEvent] ? " [Event]" : ""}"}
end


def simple_display(pool, reward_tier, is_each = false)
	header = ""
	header.concat("#{pool.tier} ") if pool.tier
	header.concat(pool.mode.to_s)
    header.concat(pool_rotations(pool, reward_tier))

    numsOne, numsTwo = pool_nums(pool, reward_tier, is_each)

	puts "#{header}: #{numsOne} #{numsTwo}"

    print_nodes(pool, INDENT) if show_nodes?
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
    parser.on("--nodes", "List the nodes for each reward pool.") do
        $show_nodes = :show
    end
    parser.on("--no-nodes", "Don't list the nodes for each reward pool.") do
        $show_nodes = :hide
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
    parser.on("-m", "--missions", "Show chance for each relic for listed missions.") do |m|
        $mission_mode = :mission
    end
end

def relicaps(t)
	if RELIC_TIERS.include? t.capitalize().intern 
		return t.capitalize().intern
	else
		return t.downcase().intern
	end
end

parser.parse!(ARGV)
# STDERR.puts "mission_mode?: #{mission_mode?}"
load_data($force_reparse)

if mission_mode?
    missions = []
    next_tier = nil
    eachopt = display_each?
    mre = /(?:([DTV][1-4]|DS|KF|Lua)\s+)?(\w+)/i
    tre = /^([DTV][1-4]|DS|KF|Lua);?$/i 
    ARGV.each{|m|
        # STDERR.puts "m: #{m} (#{!!(tre =~ m)},#{!!(mre =~ m)})"
        if '--' == m
            missions.push [next_tier, nil] if next_tier
            next_tier = nil
        elsif tre =~ m
            missions.push [next_tier, nil] if next_tier
            t = $1
            if m.end_with? ';'
                missions.push [t, nil]
                next_tier = nil
            else
                next_tier = t
            end
        elsif mre =~ m
            # STDERR.puts "$1: #{$1} (#{$1 or next_tier}), $2: #{$2}"
            missions.push [next_tier, nil] if next_tier and $1
            missions.push [($1 or next_tier), $2]
            next_tier = nil
        else
            missions.push [next_tier, m]
            next_tier = nil
        end
        # STDERR.puts "missions: #{missions}\nnext_tier: #{next_tier}\n\n"
    }
    missions.push [next_tier, nil] if next_tier

    $pools.values
        .select{|p|
            # STDERR.puts "p: #{p.tier} #{p.mode}"
            :Endless == p.class.name.intern and
            missions.any?{|m|
                # STDERR.puts "#{INDENT}m: #{m}"
                (
                    (m[1] == nil) or
                    m[1].downcase == p.mode.to_s.downcase
                ) and (
                    (m[0] == nil) or
                    m[0].downcase == p.tier.to_s.downcase
                )
            }
        }
        .sort_by{|p| [p.mode, p.tier]}
        .each{|p| display_pool(p, eachopt); puts ""}

else # $mission_mode == false

    tiers = ARGV.length <= 0 ? RELIC_TIERS.to_a + [:relic] : ARGV.map{|t| relicaps t}
    tiers.each{|tier|
        puts "#{tier}:"
        eachopt = display_each?
        iseach = (RELIC_TIERS.include?(tier) and eachopt)
        nodes = best_nodes(tier, $num_best, poolType: :Endless, each: iseach, voidnodes: $show_void)
        if $num_best then
            nodes.each{|p|
                simple_display(p, tier, iseach)
                puts ""
            }
        else
            simple_display(nodes, tier, iseach)
            puts ""
        end
        if $num_void and $num_void > 0 and nil == $show_void then
            best_nodes(tier, $num_void, poolType: :Endless, each: iseach, voidnodes: :only).each{|p|
                simple_display(p, tier, iseach)
                puts ""
            }
        end
        puts ""
    }
end
