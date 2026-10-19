extends RefCounted
class_name Tile

enum Biome {
	PLAINS,
	DESERT,
	FOREST,
	VOLCANO,
	OCEAN,
	ICE,
}

enum State {
	READY,
	BURNED,
	BROKEN,
}

var biome: int
var state: int = State.READY

func _init(p_biome: int = Biome.PLAINS) -> void:
	biome = p_biome

func is_ready() -> bool:
	return state == State.READY

func is_burned() -> bool:
	return state == State.BURNED

func is_broken() -> bool:
	return state == State.BROKEN
