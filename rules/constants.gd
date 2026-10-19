extends RefCounted
class_name Constants

# Tunable game numbers — change here, not in engine code.

const PLAYER_HP := 20
const TILES_PER_LANE := 4
const LANES_PER_PLAYER := 4
const UPKEEP_RETURN_RATE := 1

enum BlockRule {
	LANE,
	GLOBAL,
}

const DEFAULT_BLOCK_RULE := BlockRule.LANE