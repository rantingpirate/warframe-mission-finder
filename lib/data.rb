require "mission"
require "reward"
require "globals"
require 'set'
require 'pathname'
require 'json'

def mapmulti(map, to, list)
	list.each{|n| map[n] = to}
end
def multimapmulti(list, map = nil)
	map = Hash.new if not map
	list.each{|to,l| l.each{|n|map[n] = to}}
	return map
end

$void_diff = false

ENDLESS_MODES = Set[:Defection, :Defense, :Excavation, :"Infested Salvage", :Interception, :"Sanctuary Onslaught", :Survival, :Survxcavation]
DARK_NODES = multimapmulti([
	[:D1, [:PhobosMemphis, :CeresGabii, :VenusMalva]],
	[:D2, [:JupiterCameria, :SaturnPiscinas, :MarsWahiba, :PhobosZeugma, :SaturnCaracol]],
	[:D3, [:NeptuneYursa, :SednaAmarna, :UranusAssur, :NeptuneKelashin]],
	[:D4, [:ErisZabala]],
	[:DS, [:ErisAkkad, :EarthCoba, :MarsKadesh, :EuropaLarzac, :VenusRomula, :SednaSangeru, :PlutoSechura, :CeresSeimeni, :JupiterSinai, :UranusUr]]
])
PLANET_TIERS = multimapmulti([
	[:T1, [:Earth, :Venus, :Mercury, :Mars, :Phobos]],
	[:T2, [:Ceres, :Jupiter, :Europa, :Saturn]],
	[:T3, [:Uranus, :Lua, :Neptuno, :Pluto, :"Kuva Fortress", :Sedna, :Eris]]
]) #PLANET_TIERS
VOID_NODES = {
	VoidTaranis: :T1,
	VoidAni: :T2,
	VoidBelenus: :T3,
	VoidMithra: :T3,
	VoidMot: :T4
} #VOID_NODES
VOID_TIERS = multimapmulti([
	[:V1, [:VoidTeshub, :VoidHepit, :VoidTaranis]],
	[:V2, [:VoidTiwaz, :VoidStribog, :VoidAni]],
	[:V3, [:VoidUkko, :VoidOxomoco, :VoidBelenus]],
	[:V4, [:VoidAten, :VoidMarduk, :VoidMithra, :VoidMot]]
]) #VOID_TIERS
SABOTAGE_NODES = {
	EarthCervantes: :Earth,
	NaeglarEris: :Hive,
	UranusDesdemona: :Sealab,
	VoidStribog: :V2,
	VoidMarduk: :V4
} #SABOTAGE_NODES
ODD_NODES = {
	EuropaCholistan: :T3,
	CeresCasta: :T1,
	CeresCinxia: :T1,
	UranusUmbriel: :T2,
	"Kuva FortressPago": :KF,
	LuaPlato: :Lua,
	LuaPavlov: :Lua,
	"Kuva FortressDakata": :KF
} #ODD_NODES
ARCHWING_NODES = Set[:EarthErpo, :VenusMontes, :MarsSyrtis, :PhobosKepler, :JupiterGalilea, :SaturnPandora, :UranusCaelus, :NeptuneSalacia, :"ErisJordas_Golem_Assassinate"]

def mission_tier(mode, planet, node_id, void_diff: nil)
	void_diff = $void_diff if nil === void_diff
	if :Derelict == planet
		return :OD
	elsif void_diff and :Void == planet
		return VOID_TIERS[node_id]
	elsif ARCHWING_NODES.include? node_id
		return :AW
	elsif :Sabotage == mode and SABOTAGE_NODES.has_key? node_id
		return SABOTAGE_NODES[node_id]
	elsif :Void == planet and VOID_NODES.has_key? node_id
		return VOID_NODES[node_id]
	elsif ODD_NODES.has_key? node_id
		return ODD_NODES[node_id]
	elsif ONE_TIER_MODES.include? mode
		return nil
	elsif DARK_NODES.has_key? node_id
		return DARK_NODES[node_id]
	else
		return PLANET_TIERS[planet]
	end
end #def mission_tier

def parse_planets(json)
	# json.transform_keys!{|k| k.intern}
	json.each{|pname, pdat|
		# pdat.transform_keys!{|k| k.intern}
		pdat.each{|nname, ndat|
			new_node(pname, nname, ndat)
		}
	}
end #def parse_planets

def new_node(planet, node, data)
	pool_id = data["rewards"].hash #might need to convert to string first. We'll see...
	node_id = planet.dup.concat(node).intern
	if not $pools.has_key? pool_id
		data = data.transform_keys{|k| k.intern}
		pool = $pools[pool_id] = {
			nodes: Set[node_id],
			mode: data[:gameMode].intern,
			# is_event: "true" == data[:isEvent] || data[:isEvent],
			hash: pool_id,
			tier: mission_tier(data[:gameMode], planet.intern, node_id)
			reward: new_reward(data[:rewards], pool_id, data[:gameMode].intern),
		}
		pool[:mode] = :Survxcavation if Set[:Survival, :Excavation].include? pool[:mode] and Set [:T2, :T3].include? pool[:tier]
		pool[:reward].tier_rot.keys.each{|k|
			$pools_by_tier[k].add(pool_id) if $pools_by_tier.has_key? k
		}
	else
		$pools[pool_id][:nodes].add(node_id)
		$nodes[node_id] = Set.new unless $nodes.has_key? node_id
		$nodes[node_id].add(pool_id)
	end
end #def new_node

def new_reward(data, pool_id, gamemode)
	if "Array" == data.class.name
		return Single.new(data, pool_id)
	elsif ENDLESS_MODES.include? gamemode
		return Endless.new(data, pool_id)
	else
		return Rotated.new(rewards, pool_id)
	end
end #def new_reward

def best_nodes(tier = :relic, num = nil)
	pool = :relic == tier ? $pools.values : $pools_by_tier[tier].to_a.map{|p| $pools[p]}
	if num
		return pool.max(num){|a,b|
			a[:reward].mean_tier[tier] <=> b[:reward].mean_tier[tier]
		}
	else
		return pool.max{|a,b|
			a[:reward].mean_tier[tier] <=> b[:reward].mean_tier[tier]
		}
	end #if num
end #def best_nodes

