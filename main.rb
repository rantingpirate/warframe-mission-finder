require_relative "lib/data"
require_relative "lib/reward"
require_relative "lib/globals"
require_relative "lib/mission"

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
	if pool.tier_rot.has_key? reward_tier && pool.tier_rot[reward_tier]
		rot = pool.tier_rot[reward_tier].to_a.sort
		if :Endless == pool.mission_type && :A == rot[0]
			#Endless missions rotate AABC, not ABC
			rot.unshift(:A)
		end #if pool.mission_type == Endless
		header.concat(" [#{rot.join("")}]")
	end #if pool.tier_rot[reward_tier]
	if is_each
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
		.sort{|a,b|
			planet_sort(a,b)
		}
		.each{|p| puts "  #{p[:fullName]}#{p[:isEvent] ? " [Event]" : ""}"}
end

load_data()
(RELIC_TIERS.to_a + [:relic]).each{|tier|
	puts "#{tier}:"
	best_nodes(tier, 3, poolType: :Endless).each{|p|
		simple_display(p, tier)
		puts ""
	}
	puts ""
}
