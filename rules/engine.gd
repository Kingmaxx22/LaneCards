extends RefCounted
class_name GameEngine

# --- Combat configuration ---

static var block_rule: int = Constants.DEFAULT_BLOCK_RULE

# --- Tile operations ---

static func burn_tile(tile: Tile) -> bool:
	if not tile.is_ready():
		return false
	tile.state = Tile.State.BURNED
	return true

static func break_tile(tile: Tile) -> void:
	if tile.is_broken():
		return
	tile.state = Tile.State.BROKEN

# --- Upkeep ---

static func upkeep(player: Player) -> void:
	var restored := 0
	for lane in player.lanes:
		if restored >= Constants.UPKEEP_RETURN_RATE:
			break
		var t = lane.first_burned()
		if t != null:
			t.state = Tile.State.READY
			restored += 1

# --- Cost checking and payment ---

static func can_pay(player: Player, cost: Cost) -> bool:
	for biome in cost.requirements:
		var needed: int = cost.requirements[biome]
		var available := _count_ready_of_biome(player, biome)
		if available < needed:
			return false
	if cost.any_count > 0:
		var total_ready := _count_all_ready(player)
		var reserved := 0
		for biome in cost.requirements:
			reserved += cost.requirements[biome]
		if total_ready - reserved < cost.any_count:
			return false
	return true

static func pay_cost(player: Player, cost: Cost) -> bool:
	if not can_pay(player, cost):
		return false
	for biome in cost.requirements:
		var to_burn: int = cost.requirements[biome]
		for lane in player.lanes:
			if to_burn <= 0:
				break
			for tile in lane.tiles:
				if to_burn <= 0:
					break
				if tile.biome == biome and tile.is_ready():
					tile.state = Tile.State.BURNED
					to_burn -= 1
	var any_to_burn := cost.any_count
	if any_to_burn > 0:
		for lane in player.lanes:
			if any_to_burn <= 0:
				break
			for tile in lane.tiles:
				if any_to_burn <= 0:
					break
				if tile.is_ready():
					tile.state = Tile.State.BURNED
					any_to_burn -= 1
	return true

# --- Monster placement ---

static func place_monster(player: Player, lane_index: int, start_index: int, monster: Monster) -> bool:
	if start_index < 0 or start_index + monster.size > Constants.TILES_PER_LANE:
		return false
	var lane = player.lanes[lane_index]
	for i in range(monster.size):
		var idx = start_index + i
		var tile = lane.tiles[idx]
		if tile.is_broken():
			return false
		if _is_tile_occupied(player, lane_index, idx):
			return false
	monster.lane_index = lane_index
	monster.start_index = start_index
	player.monsters.append(monster)
	return true

static func is_monster_alive(monster: Monster, player: Player) -> bool:
	return monster.is_alive(player)

# --- Combat: targeting ---

static func get_targets(defender: Player, lane_index: int) -> Array:
	var targets: Array = []
	for m in defender.monsters:
		if m.lane_index == lane_index:
			targets.append(m)
	return targets

static func can_attack_directly(defender: Player, target_lane: int) -> bool:
	if block_rule == Constants.BlockRule.GLOBAL:
		return defender.monsters.size() == 0
	return get_targets(defender, target_lane).size() == 0

# --- Combat: attack_monster ---

static func attack_monster(attacker_player: Player, defender_player: Player, attacker_monster: Monster, target_monster: Monster) -> bool:
	if attacker_monster.has_attacked:
		return false
	if not attacker_monster.is_alive(attacker_player):
		return false
	if not target_monster.is_alive(defender_player):
		return false
	var attacker_owner = _find_owner(attacker_monster, attacker_player)
	if not attacker_owner:
		return false
	var target_owner = _find_owner(target_monster, defender_player)
	if not target_owner:
		return false
	var atk_dmg = attacker_monster.atk
	var def_dmg = target_monster.atk
	target_monster.hp -= atk_dmg
	attacker_monster.hp -= def_dmg
	attacker_monster.has_attacked = true
	remove_dead_monsters(defender_player)
	remove_dead_monsters(attacker_player)
	return true

# --- Combat: attack_direct ---

static func attack_direct(attacker_player: Player, defender_player: Player, attacker_monster: Monster, target_lane: int, mode: String, tile_index: int = -1) -> bool:
	if target_lane < 0 or target_lane >= Constants.LANES_PER_PLAYER:
		return false
	if not can_attack_directly(defender_player, target_lane):
		return false
	if attacker_monster.has_attacked:
		return false
	if not attacker_monster.is_alive(attacker_player):
		return false
	if mode == "HP":
		defender_player.hp -= attacker_monster.atk
	elif mode == "TILE":
		if tile_index < 0 or tile_index >= Constants.TILES_PER_LANE:
			return false
		var tile = defender_player.lanes[target_lane].tiles[tile_index]
		if tile.is_broken():
			return false
		LaneRules.break_tile_and_cleanup(defender_player, target_lane, tile_index)
	else:
		return false
	attacker_monster.has_attacked = true
	return true

# --- Combat: reset_attacks ---

static func reset_attacks(player: Player) -> void:
	for m in player.monsters:
		m.has_attacked = false

# --- Loss check ---

static func has_lost(player: Player) -> bool:
	return player.hp <= 0 or player.lost_by_deck or _all_lanes_flipped_and_broken(player)

static func _all_lanes_flipped_and_broken(player: Player) -> bool:
	for lane in player.lanes:
		if lane.state != Lane.LaneState.FLIPPED:
			return false
		if not lane.all_broken():
			return false
	return true

# --- Helpers ---

static func _find_owner(monster: Monster, player: Player) -> bool:
	for m in player.monsters:
		if m == monster:
			return true
	return false

static func remove_dead_monsters(player: Player) -> int:
	var to_remove: Array = []
	for m in player.monsters:
		if m.hp <= 0 or not m.is_alive(player):
			to_remove.append(m)
	for m in to_remove:
		player.monsters.erase(m)
	return to_remove.size()

static func _count_ready_of_biome(player: Player, biome: int) -> int:
	var count := 0
	for lane in player.lanes:
		for tile in lane.tiles:
			if tile.biome == biome and tile.is_ready():
				count += 1
	return count

static func _count_all_ready(player: Player) -> int:
	var count := 0
	for lane in player.lanes:
		for tile in lane.tiles:
			if tile.is_ready():
				count += 1
	return count

static func _is_tile_occupied(player: Player, lane_index: int, tile_index: int) -> bool:
	for m in player.monsters:
		if m.lane_index == lane_index:
			for idx in m.tile_indices():
				if idx == tile_index:
					return true
	return false

static func _state_name(s: int) -> String:
	match s:
		Tile.State.READY: return "READY"
		Tile.State.BURNED: return "BURNED"
		Tile.State.BROKEN: return "BROKEN"
	return "UNKNOWN"