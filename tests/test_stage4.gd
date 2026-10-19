extends RefCounted
class_name TestStage4

func run(c: Checker) -> void:
	c.section("flip_lane basic")
	var p = Player.new()
	p.lanes[0].state = Lane.LaneState.FACE_DOWN
	p.lanes[0].card = Card.new("TestCard", Card.CardType.MONSTER, Tile.Biome.FOREST)
	c.check(LaneRules.flip_lane(p, 0) == true, "flip_lane on FACE_DOWN lane succeeds")
	c.check(p.lanes[0].state == Lane.LaneState.FLIPPED, "lane is FLIPPED after flip")
	c.check(p.lanes[0].ready_count() == 4, "flipped lane has 4 READY tiles")
	c.check(p.lanes[0].tiles[0].biome == Tile.Biome.FOREST, "tiles have card biome FOREST")

	c.section("flip_lane on FLIPPED lane fails")
	var p2 = Player.new()
	c.check(LaneRules.flip_lane(p2, 0) == false, "flip_lane on FLIPPED lane returns false")

	c.section("flip_lane once per turn")
	var p3 = Player.new()
	p3.lanes[0].state = Lane.LaneState.FACE_DOWN
	p3.lanes[0].card = Card.new("Card1", Card.CardType.MONSTER, Tile.Biome.PLAINS)
	p3.lanes[1].state = Lane.LaneState.FACE_DOWN
	p3.lanes[1].card = Card.new("Card2", Card.CardType.MONSTER, Tile.Biome.PLAINS)
	c.check(LaneRules.flip_lane(p3, 0) == true, "first flip succeeds")
	c.check(LaneRules.flip_lane(p3, 1) == false, "second flip in same turn fails")
	LaneRules.reset_flips(p3)
	c.check(LaneRules.flip_lane(p3, 1) == true, "flip after reset_flips succeeds")

	c.section("flip_lane burns one READY tile when available")
	var p4 = Player.new()
	p4.lanes[0].state = Lane.LaneState.FACE_DOWN
	p4.lanes[0].card = Card.new("BurnCard", Card.CardType.MONSTER, Tile.Biome.PLAINS)
	var ready_before = _count_all_ready(p4)
	c.check(LaneRules.flip_lane(p4, 0) == true, "flip succeeds with READY tiles present")
	var ready_after = _count_all_ready(p4)
	c.check(ready_after == ready_before + 3, "flip burns 1 and adds 4: net +3")

	c.section("flip_lane free when no READY tiles")
	var p5 = Player.new()
	for lane in p5.lanes:
		if lane.state == Lane.LaneState.FLIPPED:
			for tile in lane.tiles:
				tile.state = Tile.State.BURNED
	p5.lanes[0].state = Lane.LaneState.FACE_DOWN
	p5.lanes[0].card = Card.new("FreeCard", Card.CardType.MONSTER, Tile.Biome.PLAINS)
	var ready_before5 = _count_all_ready(p5)
	c.check(LaneRules.flip_lane(p5, 0) == true, "flip succeeds with no READY tiles")
	var ready_after5 = _count_all_ready(p5)
	c.check(ready_after5 == 4, "flip is free when no READY tiles (4 new READY, 0 burned)")

	c.section("failed flip does not burn tile")
	var p6 = Player.new()
	var ready_before6 = _count_all_ready(p6)
	c.check(LaneRules.flip_lane(p6, 0) == false, "flip on FLIPPED lane fails")
	var ready_after6 = _count_all_ready(p6)
	c.check(ready_after6 == ready_before6, "failed flip does not burn any tile")

	c.section("breaking 3 of 4 tiles does not collapse")
	var p7 = Player.new()
	p7.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	LaneRules.break_tile_and_cleanup(p7, 0, 0)
	LaneRules.break_tile_and_cleanup(p7, 0, 1)
	LaneRules.break_tile_and_cleanup(p7, 0, 2)
	c.check(p7.lanes[0].state == Lane.LaneState.FLIPPED, "lane still FLIPPED after 3 tiles broken")
	c.check(p7.lanes[0].tiles[3].is_ready(), "4th tile still READY")

	c.section("breaking 4th tile collapses lane")
	var p8 = Player.new()
	p8.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	LaneRules.break_tile_and_cleanup(p8, 0, 0)
	LaneRules.break_tile_and_cleanup(p8, 0, 1)
	LaneRules.break_tile_and_cleanup(p8, 0, 2)
	c.check(LaneRules.break_tile_and_cleanup(p8, 0, 3) == true, "breaking 4th tile succeeds")
	c.check(p8.lanes[0].state == Lane.LaneState.FACE_DOWN, "lane is FACE_DOWN after collapse and replacement")

	c.section("monsters in collapsed lane removed, others stay")
	var p9 = Player.new()
	p9.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	var m1 = Monster.new("Doomed", 1, 0, 0, 1, 5)
	var m2 = Monster.new("Survivor", 1, 1, 0, 1, 5)
	GameEngine.place_monster(p9, 0, 0, m1)
	GameEngine.place_monster(p9, 1, 0, m2)
	LaneRules.break_tile_and_cleanup(p9, 0, 0)
	LaneRules.break_tile_and_cleanup(p9, 0, 1)
	LaneRules.break_tile_and_cleanup(p9, 0, 2)
	LaneRules.break_tile_and_cleanup(p9, 0, 3)
	c.check(p9.monsters.size() == 1, "monster in collapsed lane removed")
	c.check(p9.monsters[0] == m2, "monster in other lane survives")

	c.section("collapse with SPELL lane card logs effect_id")
	var p10 = Player.new()
	p10.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	p10.lanes[0].card = Card.new("Fireball", Card.CardType.SPELL, Tile.Biome.VOLCANO, "fireball_damage")
	LaneRules.break_tile_and_cleanup(p10, 0, 0)
	LaneRules.break_tile_and_cleanup(p10, 0, 1)
	LaneRules.break_tile_and_cleanup(p10, 0, 2)
	LaneRules.break_tile_and_cleanup(p10, 0, 3)
	c.check(p10.trigger_log.has("fireball_damage"), "SPELL effect_id logged on collapse")

	c.section("collapse with TRAP lane card logs effect_id")
	var p11 = Player.new()
	p11.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	p11.lanes[0].card = Card.new("SpikeTrap", Card.CardType.TRAP, Tile.Biome.FOREST, "spike_damage")
	LaneRules.break_tile_and_cleanup(p11, 0, 0)
	LaneRules.break_tile_and_cleanup(p11, 0, 1)
	LaneRules.break_tile_and_cleanup(p11, 0, 2)
	LaneRules.break_tile_and_cleanup(p11, 0, 3)
	c.check(p11.trigger_log.has("spike_damage"), "TRAP effect_id logged on collapse")

	c.section("collapse with MONSTER lane card logs nothing")
	var p12 = Player.new()
	p12.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	p12.lanes[0].card = Card.new("Goblin", Card.CardType.MONSTER, Tile.Biome.PLAINS)
	LaneRules.break_tile_and_cleanup(p12, 0, 0)
	LaneRules.break_tile_and_cleanup(p12, 0, 1)
	LaneRules.break_tile_and_cleanup(p12, 0, 2)
	LaneRules.break_tile_and_cleanup(p12, 0, 3)
	c.check(p12.trigger_log.size() == 1, "MONSTER lane card logs nothing (only replacement marker)")

	c.section("effect_id logged BEFORE replacement")
	var p13 = Player.new()
	p13.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	p13.lanes[0].card = Card.new("Fireball", Card.CardType.SPELL, Tile.Biome.VOLCANO, "fireball_effect")
	LaneRules.break_tile_and_cleanup(p13, 0, 0)
	LaneRules.break_tile_and_cleanup(p13, 0, 1)
	LaneRules.break_tile_and_cleanup(p13, 0, 2)
	LaneRules.break_tile_and_cleanup(p13, 0, 3)
	c.check(p13.trigger_log.size() == 2, "two entries in trigger_log")
	c.check(p13.trigger_log[0] == "fireball_effect", "effect_id logged first")
	c.check(p13.trigger_log[1] == "replaced", "replacement marker logged second")

	c.section("replacement is top deck card FACE_DOWN deck shrinks")
	var p14 = Player.new()
	var top_card = Card.new("TopCard", Card.CardType.SPELL, Tile.Biome.OCEAN, "ocean_spell")
	var bottom_card = Card.new("BottomCard", Card.CardType.MONSTER, Tile.Biome.DESERT)
	p14.deck = [top_card, bottom_card]
	c.check(p14.deck.size() == 2, "deck starts with 2 cards")
	LaneRules.break_tile_and_cleanup(p14, 0, 0)
	LaneRules.break_tile_and_cleanup(p14, 0, 1)
	LaneRules.break_tile_and_cleanup(p14, 0, 2)
	LaneRules.break_tile_and_cleanup(p14, 0, 3)
	c.check(p14.deck.size() == 1, "deck shrinks by 1 after replacement")
	c.check(p14.deck[0] == bottom_card, "remaining card is the bottom card")
	c.check(p14.lanes[0].card == top_card, "replacement is the top deck card")
	c.check(p14.lanes[0].state == Lane.LaneState.FACE_DOWN, "replacement is FACE_DOWN")

	c.section("empty deck causes lost_by_deck")
	var p15 = Player.new()
	p15.deck = []
	p15.lanes[0].card = Card.new("Fireball", Card.CardType.SPELL, Tile.Biome.VOLCANO, "last_spell")
	LaneRules.break_tile_and_cleanup(p15, 0, 0)
	LaneRules.break_tile_and_cleanup(p15, 0, 1)
	LaneRules.break_tile_and_cleanup(p15, 0, 2)
	LaneRules.break_tile_and_cleanup(p15, 0, 3)
	c.check(p15.trigger_log.has("last_spell"), "effect still logged before deck check")
	c.check(p15.lost_by_deck == true, "lost_by_deck is true when deck empty")
	c.check(GameEngine.has_lost(p15), "has_lost is true when lost_by_deck")

	c.section("breaking already BROKEN tile fails no double collapse")
	var p16 = Player.new()
	p16.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	LaneRules.break_tile_and_cleanup(p16, 0, 0)
	LaneRules.break_tile_and_cleanup(p16, 0, 1)
	LaneRules.break_tile_and_cleanup(p16, 0, 2)
	LaneRules.break_tile_and_cleanup(p16, 0, 3)
	var deck_size_after_collapse = p16.deck.size()
	c.check(LaneRules.break_tile_and_cleanup(p16, 0, 0) == false, "breaking already BROKEN tile fails")
	c.check(p16.deck.size() == deck_size_after_collapse, "deck unchanged after failed break")

	c.section("break_tile_and_cleanup on FACE_DOWN lane fails")
	var p17 = Player.new()
	p17.lanes[0].state = Lane.LaneState.FACE_DOWN
	c.check(LaneRules.break_tile_and_cleanup(p17, 0, 0) == false, "break_tile_and_cleanup on FACE_DOWN lane fails")

	c.section("has_lost false when one lane FACE_DOWN")
	var p18 = Player.new()
	for i in range(1, Constants.LANES_PER_PLAYER):
		for tile in p18.lanes[i].tiles:
			tile.state = Tile.State.BROKEN
	p18.lanes[0].state = Lane.LaneState.FACE_DOWN
	c.check(not GameEngine.has_lost(p18), "has_lost false when one lane is FACE_DOWN")

	c.section("has_lost true when all lanes FLIPPED and all tiles BROKEN")
	var p19 = Player.new()
	for lane in p19.lanes:
		for tile in lane.tiles:
			tile.state = Tile.State.BROKEN
	c.check(GameEngine.has_lost(p19), "has_lost true when all lanes FLIPPED with all tiles BROKEN")

	c.section("attack_direct TILE triggers collapse and replacement")
	var p20 = Player.new()
	p20.deck = [Card.new("Replacement", Card.CardType.MONSTER, Tile.Biome.PLAINS)]
	var attacker = Monster.new("Atk", 1, 1, 0, 1, 5)
	p20.monsters = [attacker]
	LaneRules.break_tile_and_cleanup(p20, 0, 0)
	LaneRules.break_tile_and_cleanup(p20, 0, 1)
	LaneRules.break_tile_and_cleanup(p20, 0, 2)
	c.check(p20.lanes[0].state == Lane.LaneState.FLIPPED, "lane still FLIPPED after 3 breaks")
	c.check(p20.lanes[0].tiles[3].is_ready(), "4th tile still READY before attack")
	c.check(GameEngine.attack_direct(p20, p20, attacker, 0, "TILE", 3) == true, "attack_direct TILE on 4th tile succeeds")
	c.check(p20.lanes[0].state == Lane.LaneState.FACE_DOWN, "lane collapsed and replaced after attack")

func _count_all_ready(p: Player) -> int:
	var count := 0
	for lane in p.lanes:
		if lane.state != Lane.LaneState.FLIPPED:
			continue
		for tile in lane.tiles:
			if tile.is_ready():
				count += 1
	return count