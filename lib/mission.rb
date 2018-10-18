require 'reward'
require 'set'
require "globals"

RELIC_TIERS = [:Lith, :Meso, :Neo, :Axi]


def addChances(chances)
	n = 1
	chances.each{|ch, inv| n *= inv ? 1 - ch : ch}
	return n
end #def addChances
def runPerms(perms, arry, set = nil, i = 0)
	set = [] if not set
	if arry.length <= i
		perms[set.select{|c| !c[1]}.length] += addChances(set)
	else
		runPerms(perms, arry, set + [[arry[i], true]], i+1)
		runPerms(perms, arry, set + [[arry[i], false]], i+1)
	end
end #def runPerms
def chancePermutations(arry)
	perms = [0] * (arry.length + 1)
	runPerms(perms, arry)
	while 0 < perms.length and 0 == perms.last
		perms.pop
	end
	return perms
end #def chancePermutations
def chMean(chances)
	mean = 0
	chances.each.with_index{|ch,i| mean += ch * i}
	return mean
end

class RewardPool
	attr_reader :id
	def initialize(hash)
		@id = hash
	end #def RewardPool.new

	def planets()
		return $pools[@id][:nodes].map{|n| $nodes[n][:planet]}
	end #def RewardPool.planets

	def nodes()
		return $pools[@id][:nodes].map{|n| $nodes[n]}
	end #def RewardPool.nodes

	def node_ids()
		return $pools[@id][:nodes]
	end #def RewardPool.node_ids

	def pool()
		return $pools[@id]
	end #def RewardPool.pool
end #class RewardPool

module RotatingMission
	attr_reader :num_by_tier, :chance_tier, :chance_each, :mean_tier, :mean_each, :tier_rot
	def __rmInit(pool,keyl)
		@rotations = pool.transform_keys{|k| k.intern}
			.transform_values{|r| Rotation.new(r)}
		rewards_by_tier = Hash.new
		# @num_by_tier = Hash.new
		@chance_tier = Hash.new
		@chance_each = Hash.new
		@mean_tier = Hash.new
		@mean_each = Hash.new
		@tier_rot = Hash.new
		@rotations.each{|k,r| r.tiers.each{|t|
			if @tier_rot.has_key? t
				@tier_rot[t].add(k)
			else
				@tier_rot[t] = Set[k]
			end
			rewards_by_tier[t] = Set.new unless rewards_by_tier.has_key? t
			rewards_by_tier[t].merge(r.rewards[t].to_a.map{|rwd| rwd.id.intern})
		}}
		# rewards_by_tier.each{t,rwds}
		@num_by_tier = rewards_by_tier.transform_values{|v| v.length}
		@num_by_tier[:all] = @num_by_tier.values.sum
		if RELIC_TIERS.any?{|t| @num_by_tier.has_key? t}
			@num_by_tier[:relic] = @num_by_tier[:all]
			@num_by_tier[:relic] -= @num_by_tier[:non] if @num_by_tier.has_key? :non
		end #if there are any relics
		aabc = @rotations.fetch_values(*keyl)
		@num_by_tier.reject{|k,_v| :all == k}.each{|tier,num|
			@chance_tier[tier] = chancePermutations(
				aabc.map{|r| r.chance_tier[tier] || 0.0}
			)
			@mean_tier[tier] = chMean(@chance_tier[tier])
		}.select{|k,v| RELIC_TIERS.include? k}.each{|tier,num|
			@chance_each[tier] = chancePermutations(
				aabc.map{|r| r.chance_each[tier] || 0.0}
			)
			@mean_each[tier] = chMean(@chance_each[tier])
		}
	end #def __rmInit1
end #module RotatingMission

class Endless < RewardPool
	include RotatingMission
	def initialize(pool, hash)
		super(hash)
		__rmInit(pool, [:A, :A, :B, :C])
	end #def Endless.new
end #class Endless

class Rotated < RewardPool
	include RotatingMission
	def initialize(pool, hash)
		super(hash)
		__rmInit(pool, [:A, :B, :C])
	end #def Rotated.new
end #class Rotated

class Single < RewardPool
	attr_reader :chance_tier, :mean_tier, :chance_each, :mean_each, :tier_rot
	def initialize(pool, hash)
		super(hash)
		@rewards = Rotation.new(pool)
		@chance_tier = @rewards.chance_tier.transform_values{|v| [1-v, v]}
		@mean_tier = @rewards.chance_tier
		@chance_each = @rewards.chance_each.transform_values{|v| [1-v, v]}
		@mean_each = @rewards.chance_each
		@tier_rot = Hash.new
		@rewards.tiers.each{|tier| @tier_rot[tier] = nil}
	end #def Single.new
	def num_by_tier() return @rewards.num_by_tier end
end #class Single

