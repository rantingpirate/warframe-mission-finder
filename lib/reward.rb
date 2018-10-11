#!/bin/ruby

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

def newRelic(jh)
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
	relic = $relics_by_name[r[:tier]][r[:name]]
	relic[:id] = rid unless relic[:id]
	chance = jh["chance"].to_f / 100.0
	return Relic.new(rid,chance)
end #def newRelic

class OtherReward
	attr_reader :chance, :name
	def initialize(reward)
		@id = reward["_id"]
		@name = reward["itemName"]
		@chance = reward["chance"].to_f / 100.0
	end
end

class Rotation
	attr_reader :num_by_tier, :chance_tier, :chance_each, :tiers
	def initialize(pool)
	end #Rotation.new
end #class Rotation
