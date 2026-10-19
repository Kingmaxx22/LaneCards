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
var cost: Cost
var size: int
var atk: int
var hp: int

func _init(p_name: String, p_type: int, p_biome: int, p_effect: String = "", p_cost: Cost = null, p_size: int = 1, p_atk: int = 1, p_hp: int = 1) -> void:
	name = p_name
	card_type = p_type
	biome = p_biome
	effect_id = p_effect
	cost = p_cost if p_cost != null else Cost.new()
	size = p_size
	atk = p_atk
	hp = p_hp

func copy() -> Card:
	var c = Card.new(name, card_type, biome, effect_id, cost, size, atk, hp)
	return c