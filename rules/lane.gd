extends RefCounted
class_name Lane

enum LaneState {
	FACE_DOWN,
	FLIPPED,
}

var tiles: Array = []
var state: int = LaneState.FLIPPED
var card: Card = null

func _init() -> void:
	for i in range(Constants.TILES_PER_LANE):
		tiles.append(Tile.new())

func all_broken() -> bool:
	for t in tiles:
		if not t.is_broken():
			return false
	return true

func burned_count() -> int:
	var c := 0
	for t in tiles:
		if t.is_burned():
			c += 1
	return c

func first_burned() -> Tile:
	for t in tiles:
		if t.is_burned():
			return t
	return null

func ready_count() -> int:
	var count := 0
	for t in tiles:
		if t.is_ready():
			count += 1
	return count

func all_ready() -> bool:
	for t in tiles:
		if not t.is_ready():
			return false
	return true

func set_biome(biome: int) -> void:
	for t in tiles:
		t.biome = biome

func reset_tiles(biome: int) -> void:
	for t in tiles:
		t.state = Tile.State.READY
		t.biome = biome