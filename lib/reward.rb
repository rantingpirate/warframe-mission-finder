require 'set'
require "globals"

class Relic
	attr_reader :chance, :id
	def initialize(id, chance)
		@id = id
		@chance = chance
	end #def Relic.new
	def tier() return $relics_by_id[@id][:tier] end
	def name() return $relics_by_id[@id][:name] end
	def fullname() return $relics_by_id[@id][:fullName] end
end #class Relic

def newReward(jh)
	if jh["itemName"].end_with? "Relic"
		rid = jh["_id"]; return nil unless rid
		unless ((r = $relics_by_id[rid]))
			r = ($relics_by_id[rid] = Hash.new)
			arr = jh["itemName"].split
			r[:tier] = arr[0].intern
			r[:name] = arr[1]
			r[:fullName] = jh["itemName"]
			# if not $relics_by_name[r[:tier]]
			# 	$relics_by_name[r[:tier]] = {r[:name] => {nodes: []}}
			# elsif not $relics_by_name[r[:tier]][r[:name]]
			# 	$relics_by_name[r[:tier]][r[:name]] = {nodes: []}
			# end #if
		end #unless
		# relic = $relics_by_name[r[:tier]][r[:name]]
		# relic[:id] = rid unless relic[:id]
		chance = jh["chance"].to_f / 100.0
		return Relic.new(rid,chance)
	else
		return OtherReward.new(jh)
	end #if jh["itemName"] ends with "Relic"
end #def newRelic

class OtherReward
	attr_reader :chance, :name, :tier, :id
	def initialize(reward)
		@id = reward["_id"]
		@name = reward["itemName"]
		@chance = reward["chance"].to_f / 100.0
		@tier = :non
	end
end

class Rotation
	attr_reader :num_by_tier, :chance_tier, :chance_each, :tiers, :rewards
	def initialize(pool)
		# puts "#{pool}" #DEBUG
		@rewards = Hash.new
		@num_by_tier = {relic: 0, all: 0}
		@chance_tier = {relic: 0}
		@chance_each = Hash.new
		pool.each{|reward|
			# puts "#{reward}" #DEBUG
			item = newReward(reward)
			tier = item.tier
			if not @rewards.has_key? tier
				@rewards[tier] = Set[item]
			else
				@rewards[tier].add(item)
			end #if not @rewards.has_key? tier
		} #pool.each
		@tiers = Set.new(@rewards.keys)
		if 1 == @tiers.length
			k = @tiers.to_a[0]
			num = @num_by_tier[:all] = @num_by_tier[k] = @rewards[k].length
			ch = @chance_tier[k] = 1.0
			if :non != k
				@num_by_tier[:relic] = num
				@chance_tier[:relic] = ch
				@chance_each[k] = ch / num
			end #if k isn't :non
		else
			@rewards.each{|tier, set|
				num = set.length
				chance = 1 == @tiers.length ? 1.0 : set.sum{|reward| reward.chance}
				@num_by_tier[tier] = num
				@num_by_tier[:all] += num
				@chance_tier[tier] = chance
				if :non != tier
					@chance_each[tier] = chance / num
					@num_by_tier[:relic] += num
					@chance_tier[:relic] += chance
				end
			} #rewards.each
			@chance_tier[:relic] = 1.0 if not @tiers.include? :non
		end
		@num_by_tier.delete_if{|k,v| 0 == v}
		@chance_tier.delete_if{|k,v| 0 == v}
	end #Rotation.new
end #class Rotation
