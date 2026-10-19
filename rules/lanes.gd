extends RefCounted
class_name LaneRules

static func flip_lane(player: Player, lane_index: int) -> bool:
	if lane_index < 0 or lane_index >= Constants.LANES_PER_PLAYER:
		return false
	var lane = player.lanes[lane_index]
	if lane.state != Lane.LaneState.FACE_DOWN:
		return false
	if player.flips_this_turn >= 1:
		return false
	if lane.card == null:
		return false
	var has_ready := false
	for l in player.lanes:
		if l.state == Lane.LaneState.FLIPPED:
			for t in l.tiles:
				if t.is_ready():
					has_ready = true
					break
			if has_ready:
				break
	if has_ready:
		var burned := false
		for l in player.lanes:
			if l.state == Lane.LaneState.FLIPPED:
				for t in l.tiles:
					if t.is_ready():
						t.state = Tile.State.BURNED
						burned = true
						break
				if burned:
					break
	lane.state = Lane.LaneState.FLIPPED
	lane.reset_tiles(lane.card.biome)
	player.flips_this_turn += 1
	return true

static func reset_flips(player: Player) -> void:
	player.flips_this_turn = 0

static func break_tile_and_cleanup(player: Player, lane_index: int, tile_index: int) -> bool:
	if lane_index < 0 or lane_index >= Constants.LANES_PER_PLAYER:
		return false
	if tile_index < 0 or tile_index >= Constants.TILES_PER_LANE:
		return false
	var lane = player.lanes[lane_index]
	if lane.state != Lane.LaneState.FLIPPED:
		return false
	var tile = lane.tiles[tile_index]
	if tile.is_broken():
		return false
	tile.state = Tile.State.BROKEN
	_remove_monsters_in_lane(player, lane_index)
	_check_collapse(player, lane)
	return true

static func _remove_monsters_in_lane(player: Player, lane_index: int) -> void:
	var to_remove: Array = []
	for m in player.monsters:
		if m.lane_index == lane_index:
			to_remove.append(m)
	for m in to_remove:
		player.monsters.erase(m)

static func _check_collapse(player: Player, lane: Lane) -> void:
	if not lane.all_broken():
		return
	_remove_monsters_in_lane(player, player.lanes.find(lane))
	if lane.card != null and lane.card.effect_id != "":
		if lane.card.card_type == Card.CardType.SPELL or lane.card.card_type == Card.CardType.TRAP:
			player.trigger_log.append(lane.card.effect_id)
	if player.deck.size() > 0:
		var top_card = player.deck.pop_front()
		lane.card = top_card
		lane.state = Lane.LaneState.FACE_DOWN
		for t in lane.tiles:
			t.state = Tile.State.BROKEN
		player.trigger_log.append("replaced")
	else:
		player.lost_by_deck = true