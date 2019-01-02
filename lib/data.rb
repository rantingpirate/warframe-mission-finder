require_relative "mission"
require_relative "reward"
require_relative "globals"
require 'set'
require 'pathname'
require 'json'

DATA_VERSION = 2

# encoding: UTF-8

$drop_data_dir = Pathname.new('warframe-drop-data') + 'data'
$data_dir = Pathname.new('data')
$data_filename = 'nodes.dat'
$info_filename = 'info.json'

def mapmulti(map, to, list)
	list.each{|n| map[n] = to}
end
def multimapmulti(list, map = nil)
	map = Hash.new if not map
	list.each{|to,l| l.each{|n|map[n] = to}}
	return map
end

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
	[:T3, [:Uranus, :Lua, :Neptune, :Pluto, :"Kuva Fortress", :Sedna, :Eris]]
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
ONE_TIER_MODES = [:Arena, :Capture, :"Mobile Defense"]
ARCHWING_NODES = Set[:EarthErpo, :VenusMontes, :MarsSyrtis, :PhobosKepler, :JupiterGalilea, :SaturnPandora, :UranusCaelus, :NeptuneSalacia, :"ErisJordas_Golem_Assassinate"]
PLANET_NUMS = {
	Earth: 0,
	Venus: 1,
	Mercury: 2,
	Mars: 3,
	Phobos: 4,
	VoidTeshub: 5.1,
	VoidHepit: 5.2,
	VoidTaranis: 5.3,
	Ceres: 6,
	Jupiter: 7,
	Europa: 8,
	VoidTiwaz: 9,
	VoidStribog: 9,
	VoidAni: 9,
	Saturn: 10,
	Uranus: 11,
	Lua: 12,
	Neptune: 13,
	VoidUkko: 14.1,
	VoidOxomoco: 14.2,
	VoidBelenus: 14.3,
	Pluto: 15,
	"Kuva Fortress": 16,
	Sedna: 17,
	VoidAten: 18.1,
	VoidMarduk: 18.2,
	VoidMithra: 18.3,
	VoidMot: 18.4,
	Eris: 19,
	Derelict: 21,
	Sanctuary: 42
}

def planet_sort(a,b)
	sAby = :Void == a[:planet] ? a[:id] : a[:planet]
	sBby = :Void == b[:planet] ? b[:id] : b[:planet]
	result = PLANET_NUMS[sAby] <=> PLANET_NUMS[sBby]
	if 0 == result
		return a[:name].to_s <=> b[:name].to_s
	else return result
	end #if same planet
end


def mission_tier(mode, planet, node_id)
	if :Derelict == planet
		return :OD
	elsif $vault_open and :Void == planet
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
	data.transform_keys!{|k| k.intern}
	pool_id = data[:rewards].hash #might need to convert to string first. We'll see...
	node_id = planet.dup.concat(node).intern
	if not $pools.has_key? pool_id
		mode = data[:gameMode].intern
		tier = mission_tier(mode, planet.intern, node_id)
		# mode = :Survxcavation if Set[:Survival, :Excavation].include? mode and Set[:T2, :T3].include? tier
		pool = $pools[pool_id] = new_reward(data[:rewards], pool_id, mode, tier)
		pool.tier_rot.keys.each{|k|
			#if not non or relic, add to $pools_by_tier
			$pools_by_tier[k].add(pool_id) unless Set[:all, :non].include? k
		}
	end
	$pools[pool_id].add_node(node_id)
	$nodes[node_id] = {
		pool: pool_id,
		planet: planet.intern,
		name: node.intern,
		isEvent: data[:isEvent],
		id: node_id,
		fullName: "#{node}, #{planet}"
	}
end #def new_node

def new_reward(data, pool_id, gamemode, tier)
	if "Array" == data.class.name
		return Single.new(data, pool_id, gamemode, tier)
	elsif ENDLESS_MODES.include? gamemode
		return Endless.new(data, pool_id, gamemode, tier)
	else
		return Rotated.new(data, pool_id, gamemode, tier)
	end
end #def new_reward

def meansort(a,b,t,rev=false,each: false)
	if each
		as = a.mean_each[t] || 0
		bs = b.mean_each[t] || 0
	else
		as = a.mean_tier[t] || 0
		bs = b.mean_tier[t] || 0
	end
	if rev
		return bs <=> as
	else
		return as <=> bs
	end #if reverse
end #def meansort


def best_nodes(tier = :relic, num = nil, poolType: nil, each: false, voidnodes: nil)
	if :relic == tier
		pool = $pools.values
	else
		pool = $pools_by_tier[tier].to_a.map{|p| $pools[p]}
	end
	pool.select!{|p| poolType == p.class.name.intern} if poolType
	pool.select!{|p| p.tier.to_s.start_with? "V"} if :only == voidnodes
	pool.select!{|p| not p.tier.to_s.start_with? "V"} if :none == voidnodes

	if num
		return pool.max(num){|a,b|
			meansort(a,b,tier,each: each)
		} #.sort!{|a,b| meansort(a,b,tier,true,each: each)}
	else
		return pool.max{|a,b|
			meansort(a,b,tier,each: each)
		}
	end #if num
end #def best_nodes


def datadir()
	if not File.directory?($data_dir)
		dir = Pathname.new("")
		$data_dir.split.each{|d|
			dir += d
			if not Dir.exists? dir
				Dir.mkdir(dir)
			end #if
		}
	end
	return $data_dir
end #def datadir

def datafile()
	return datadir() + $data_filename
end

def infofile()
	return datadir() + $info_filename
end

def ser(nodes)
	File.write(datafile(), Marshal.dump(nodes))
end

def deser()
	#TODO: Make this debug/verbose only
	$stderr.puts "Using data file '#{datafile()}'" #DEBUG
	data = nil

	File.open(datafile()){|f|
		data = Marshal.load(f)
	} #File.open(datafile())
	if nil == $vault_open then
		$vault_open = data[:vault_open]
		$pools, $nodes, $relics, $pools_by_tier, $relics_by_name = data.values_at(:pools, :nodes, :relics, :pools_by_tier, :relics_by_name)
	elsif $vault_open != data[:vault_open] then
		load_data(true)
	else
		$pools, $nodes, $relics, $pools_by_tier, $relics_by_name = data.values_at(:pools, :nodes, :relics, :pools_by_tier, :relics_by_name)
	end
end #def deser

def update_data(manifest)
	puts "Updating data..."
	manifest["data_version"] = DATA_VERSION
	json = File.open($drop_data_dir + 'missionRewards.json', "r:UTF-8", &:read)
	parse_planets(JSON.parse(json)["missionRewards"])
	File.open(infofile(), "w") { |f|
		f.write(JSON.pretty_generate(manifest))
	}
	ser({
		:pools	=> $pools,
		:nodes	=> $nodes,
		:relics	=> $relics,
		:pools_by_tier	=> $pools_by_tier,
		:relics_by_name	=> $relics_by_name,
		:vault_open	=> !!$vault_open
	})
end # def update_data

def valid_data?(info, manifest)
	return false if not info
	return false if info["data_version"] != DATA_VERSION
	return false if info["hash"] != manifest["hash"]
	return true
end

def load_data(force = nil)
	info_file = infofile();
	info = File.file?(info_file) ? JSON.parse(File.open(info_file, "r:UTF-8", &:read)) : nil
	manifest = JSON.parse(File.open($drop_data_dir + 'info.json', "r:UTF-8", &:read))
	if force or (nil === force and not valid_data?(info,manifest)) then
		if info_file and info["modified"] > manifest["modified"] then
			# error
			puts("Drop data is older than saved data! Aborting.")
			exit 1
		else
			if nil == $vault_open and File.file?(datafile()) then
				data = nil
				File.open(datafile()){|f| data = Marshal.load(f)}
				if data.respond_to?(:fetch) and (vo = data.fetch(:vault_open, nil)) != nil then
					$vault_open = vo
				end
			end
			update_data manifest
		end
	else
		deser
	end
end # def load_data

