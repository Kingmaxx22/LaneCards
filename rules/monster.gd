extends RefCounted
class_name Monster

var name: String
var size: int  # 1 to 4
var lane_index: int
var start_index: int
var atk: int
var hp: int
var has_attacked: bool = false

func _init(p_name: String, p_size: int, p_lane: int, p_start: int, p_atk: int = 1, p_hp: int = 1) -> void:
	name = p_name
	size = p_size
	lane_index = p_lane
	start_index = p_start
	atk = p_atk
	hp = p_hp

func tile_indices() -> Array:
	var indices: Array = []
	for i in range(size):
		indices.append(start_index + i)
	return indices

func is_alive(player: Player) -> bool:
	var lane = player.lanes[lane_index]
	for idx in tile_indices():
		var tile = lane.tiles[idx]
		if not tile.is_broken():
			return true
	return false