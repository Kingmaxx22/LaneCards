extends RefCounted
class_name Player

var lanes: Array = []
var monsters: Array = []
var hp: int = Constants.PLAYER_HP
var deck: Array = []
var hand: Array = []
var discard: Array = []
var set_traps: Array = []
var trigger_log: Array = []
var flips_this_turn: int = 0
var lost_by_deck: bool = false

func _init() -> void:
	for i in range(Constants.LANES_PER_PLAYER):
		lanes.append(Lane.new())

func usable_tiles() -> Array:
	var tiles: Array = []
	for lane in lanes:
		if lane.state != Lane.LaneState.FLIPPED:
			continue
		for tile in lane.tiles:
			tiles.append(tile)
	return tiles

func all_tiles_broken() -> bool:
	for lane in lanes:
		if not lane.all_broken():
			return false
	return true

func has_lost() -> bool:
	if hp <= 0:
		return true
	if lost_by_deck:
		return true
	for lane in lanes:
		if lane.state == Lane.LaneState.FACE_DOWN:
			return false
		if not lane.all_broken():
			return false
	return true

func total_tiles() -> int:
	return Constants.LANES_PER_PLAYER * Constants.TILES_PER_LANE