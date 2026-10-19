extends RefCounted
class_name Upkeep

static func controls_biome(player: Player, biome: int) -> bool:
	for lane in player.lanes:
		if lane.state == Lane.LaneState.FLIPPED:
			for tile in lane.tiles:
				if tile.biome == biome:
					return true
	return false

static func return_burned_tile(player: Player, count: int = 1) -> int:
	var tiles = player.usable_tiles()
	var returned := 0
	for tile in tiles:
		if returned >= count:
			break
		if tile.is_burned():
			tile.state = Tile.State.READY
			returned += 1
	return returned

static func volcano_burn(player: Player, rng: RandomNumberGenerator) -> bool:
	var tiles = player.usable_tiles()
	var ready_tiles: Array = []
	for tile in tiles:
		if tile.is_ready():
			ready_tiles.append(tile)
	if ready_tiles.size() == 0:
		return false
	var idx = rng.randi_range(0, ready_tiles.size() - 1)
	ready_tiles[idx].state = Tile.State.BURNED
	return true

static func ocean_flood(player: Player) -> bool:
	var tiles = player.usable_tiles()
	for tile in tiles:
		if tile.is_broken():
			tile.biome = Tile.Biome.OCEAN
			tile.state = Tile.State.BURNED
			return true
	return false

static func run_upkeep(player: Player, rng: RandomNumberGenerator = null) -> Dictionary:
	var result = {
		"returned": 0,
		"burned_by_volcano": false,
		"flooded": false,
	}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var has_volcano = controls_biome(player, Tile.Biome.VOLCANO)
	var has_ocean = controls_biome(player, Tile.Biome.OCEAN)
	if has_volcano:
		result.burned_by_volcano = volcano_burn(player, rng)
	if has_ocean:
		result.flooded = ocean_flood(player)
	if not has_volcano and not has_ocean:
		result.returned = return_burned_tile(player, 1)
	return result

static func start_turn(player: Player, rng: RandomNumberGenerator = null) -> Dictionary:
	LaneRules.reset_flips(player)
	GameEngine.reset_attacks(player)
	return run_upkeep(player, rng)