require 'set'
$relics = Hash.new
$relics_by_name = Hash.new
$pools = Hash.new
$nodes = Hash.new
$pools_by_tier = {Lith: Set.new, Meso: Set.new, Neo: Set.new, Axi: Set.new}
$vault_open = nil
