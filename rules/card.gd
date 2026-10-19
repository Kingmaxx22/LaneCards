extends RefCounted
class_name Card

enum CardType {
	MONSTER,
	SPELL,
	TRAP,
}

var name: String
var card_type: int
var biome: int
var effect_id: String

func _init(p_name: String, p_type: int, p_biome: int, p_effect: String = "") -> void:
	name = p_name
	card_type = p_type
	biome = p_biome
	effect_id = p_effect