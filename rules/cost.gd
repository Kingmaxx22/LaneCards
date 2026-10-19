extends RefCounted
class_name Cost

# Cost is {biome: count, ..., "any": count}
# Example: {PLAINS: 2} means "burn 2 READY PLAINS tiles"
# Example: {VOLCANO: 1, "any": 1} means "burn 1 VOLCANO + 1 any"

var requirements: Dictionary = {}
var any_count: int = 0

func _init(req: Dictionary = {}, any: int = 0) -> void:
	requirements = req
	any_count = any

func description() -> String:
	var parts: Array = []
	for biome in requirements:
		parts.append("%s x%d" % [Tile.Biome.keys()[biome], requirements[biome]])
	if any_count > 0:
		parts.append("any x%d" % any_count)
	return " + ".join(parts)