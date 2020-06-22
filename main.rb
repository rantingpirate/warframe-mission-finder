#!/bin/ruby

require_relative "lib/data"
require_relative "lib/reward"
require_relative "lib/globals"
require_relative "lib/mission"

require 'optparse'

def is_bool?(b)
  return ((b.is_a? TrueClass) or (b.is_a? FalseClass))
end

class RunOpts
  attr_reader :show_void, :force_reparse, :num_best, :display_each, :display_mode
  # attr_accessor :force_reparse, :num_best, :display_each, :display_mode
  attr_writer :num_void, :show_nodes, :force_reparse, :num_best, :display_each, :display_mode
  def initialize()
    @show_void = nil
    @force_reparse = nil
    @num_best = nil
    @num_void = 1
    @display_each = :all
    @show_nodes = nil
    @display_mode = :tier
  end

  def num_best?()
    return 0 < (@num_best or 0)
  end
  def display_each?()
    return :all != (@display_each || :all)
  end
  def show_nodes()
    return (nil === @show_nodes) ? :show : @show_nodes
  end
  def show_nodes?()
    return (nil === @show_nodes) ?
      :tier == @display_mode :
      (:hide != (@show_nodes || :hide))
  end
  def void()
    return (nil === @show_void) ? :show : @show_void
  end
  def show_void?()
    return ((:only == @show_void) or (:show == @show_void and 0 < @num_void))
  end
  def num_void()
    return show_void? ? @num_void : 0
  end
  def show_void=(v)
    if v.is_a? Symbol
      @show_void = v
    else
      @show_void = v ? :show : :hide
    end
  end
end #class RuntimeOptions

$opts = RunOpts.new();

PROGVER = 1.3
INDENT = "  "
# MISSION_DEFAULT = :relics

# def mission_mode?() return :mission == ($mode or (:default == $mode && MISSION_DEFAULT)) end
# def display_each?() return :each == ($display_each or EACH_DEFAULT) end
# # def hide_nodes?() return $show_nodes ? :hide == $show_nodes : mission_mode? end
# def show_nodes?() return $show_nodes ? :show == $show_nodes : (not mission_mode?) end

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
  print_nodes(pool, INDENT) if $opts.show_nodes?
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

  print_nodes(pool, INDENT) if $opts.show_nodes?
end

# Code to have parser auto-generate help taken from
# https://ruby-doc.org/stdlib-2.7.1/libdoc/optparse/rdoc/OptionParser.html
class ArgParser
  def self.parse(args, opts)
    opt_parser = OptionParser.new do |parser|
      parser.banner = "Usage: <script> [options]"

      parser.on("-e", "--each", "Print the chance and mean for a specific relic") do
        opts.display_each = :each
      end
      parser.on("-a", "--all", "Print the chance and mean for some relic") do
        opts.display_each = :all
      end
      parser.on("-f", "--force-reparse", "Re-parse the drop data, even if up-to-date") do
        opts.force_reparse = true
      end
      parser.on("-n", "--number", "=[NUMBER]", Integer, "Print this many nodes per tier") do |n|
        opts.num_best = n
      end
      parser.on("-N", "--num-vault", "--num-void", "=[NUMBER]", Integer, "Print this many void missions per tier") do |n|
        opts.num_void = n
      end
      parser.on("--[no-]nodes", "List the nodes for each reward pool.") do |n|
        opts.show_nodes = n ? :show : :hide
      end
      parser.on("--[no-]vault", "Parse the drop data for the vault being open [closed].") do |n|
        opts.vault_open = n
      end
      parser.on("-V", "--void-only", "Only show void missions.") do
        opts.show_void = :only
      end
      parser.on("-v", "--[no-]novoid", "Don't [not] show void missions alongside regular missions") do |n|
        opts.show_void = n
      end
      parser.on("--list-relics", "List available relics and exit.") do
        opts.display_mode = :relics
      end
      parser.on("--version", "Display version and exit") do
        puts "#{$PROGRAM_NAME} v#{PROGVER}"
        exit
      end
      parser.on("-h", "--help", "Display help and exit") do
        puts parser
        exit
      end
    end #~ opt_parser = OptionParser.new do |parser|

    opt_parser.parse!(args)
    return opts
  end #~ def ArgParser.parse
end #~ class ArgParser

def relicaps(t)
  if RELIC_TIERS.include? t.capitalize().intern 
    return t.capitalize().intern
  else
    return t.downcase().intern
  end
end

ArgParser.parse(ARGV, $opts)
# STDERR.puts "mission_mode?: #{mission_mode?}"
load_data($opts.force_reparse())

if :relics == $opts.display_mode
  # STDERR.puts "Displaying relics:" #DEBUG
  tiers = Set.new(ARGV.map{|t| relicaps t}.select{|t| RELIC_TIERS.include? t})
  if 0 >= tiers.length
    tiers = RELIC_TIERS.to_a
  end
  relics_by_tier = {
    Lith: [],
    Meso: [],
    Neo: [],
    Axi: []
  }
  $relics.each_value{|r| relics_by_tier[r[:tier]].push(r[:name])}
  RELIC_TIERS.each{|t|
    if tiers.include? t
      s = t.to_s
      puts ""
      puts relics_by_tier[t].sort.map{|n| "#{s} #{n}"}.join("\n")
    end
  }
  exit
end

$missions = []
$runmissions = false
$allmissions = false
$mre = /(?:([DTV][1-4]|DS|KF|Lua)\s+)?(\w+)/i
$tre = /^([DTV][1-4]|DS|KF|Lua);?$/i 
$eachopt = $opts.display_each?
$tiers = []
$runtiers = false
def tieradd(t)
  rt = relicaps t
  $tiers.push(rt) if not $tiers.include?(rt)
end

def parse_missions()
  $runmissions = true
  next_tier = nil
  while 0 < ARGV.length
    m = ARGV.shift
    case
    when /^missions?=?$/i =~ m
      next
    when /^tiers?=?$/i =~ m, valid_tier?(m)
      $missions.push [next_tier, nil] if next_tier
      ARGV.unshift(m)
      return parse_tiers
    when '--' == m
      $missions.push [next_tier, nil] if next_tier
      next_tier = nil
    when $tre =~ m
      $missions.push [next_tier, nil] if next_tier
      t = $1
      if m.end_with? ';'
        $missions.push [t, nil]
        next_tier = nil
      else
        next_tier = t
      end
    when $mre =~ m
      # STDERR.puts "$1: #{$1} (#{$1 or next_tier}), $2: #{$2}"
      $missions.push [next_tier, nil] if next_tier and $1
      $missions.push [($1 or next_tier), $2]
      next_tier = nil
    else
      $missions.push [next_tier, m]
      next_tier = nil
    end #~ case m
    # STDERR.puts "$missions: #{$missions}\nnext_tier: #{next_tier}\n\n"
  end #~ while 0 < ARGV.length
  $missions.push [next_tier, nil] if next_tier
end #~ def parse_$missions

VALID_TIERS = Set.new(RELIC_TIERS).add(:relic)
def valid_tier?(t) VALID_TIERS.include?(relicaps t) end

def parse_tiers()
  $runtiers = true
  while 0 < ARGV.length
    t = ARGV.shift
    case
    when /^tiers?=?$/i =~ t
      next
    when valid_tier?(t)
      tieradd(t)
    when /^missions?=?$/i =~ t, $mre =~ t, $tre =~ t
      ARGV.unshift(t)
      return parse_missions
    else
      tieradd(t)
    end #~ case t
  end #~ while 0 < ARGV.length
end #~ def parse_$tiers

if 0 >= ARGV.length or
    /^$tiers?=?$/i =~ ARGV[0] or
    valid_tier?(ARGV[0])
  parse_tiers()
else
  parse_missions()
end

if $runmissions
  $allmissions = true if 0 >= $missions.length
  # STDERR.puts "we have missions" #DEBUG
  $pools.values.select!{|p|
    # STDERR.puts "p: #{p.tier} #{p.mode}" #DEBUG
    :Endless == p.class.name.intern and (
      $allmissions or
      $missions.any?{|m|
        # STDERR.puts "#{INDENT}m: #{m}" #DEBUG
        (
          (m[1] == nil) or
          m[1].downcase == p.mode.to_s.downcase
        ) and (
          (m[0] == nil) or
          m[0].downcase == p.tier.to_s.downcase
        )
      }
    )
  }
    .sort_by{|p| [p.mode, p.tier]}
    .each{|p| display_pool(p, $eachopt); puts ""}
end

if $runtiers
  if 0 >= $tiers.length
    $tiers.concat(RELIC_TIERS.to_a).push(:relic)
  end
  $tiers.each{|tier|
    puts "#{tier}:"
    iseach = (RELIC_TIERS.include?(tier) and $eachopt)
    nodes = best_nodes(tier, $opts.num_best, poolType: :Endless, each: iseach, voidnodes: $opts.show_void)
    if $opts.num_best? then
      nodes.each{|p|
        simple_display(p, tier, iseach)
        puts ""
      }
    else
      simple_display(nodes, tier, iseach)
      puts ""
    end
    if $opts.num_void > 0 and nil == $opts.show_void then
      best_nodes(tier, $opts.num_void, poolType: :Endless, each: iseach, voidnodes: :only).each{|p|
        simple_display(p, tier, iseach)
        puts ""
      }
    end
    puts ""
  }
end
