extends RefCounted
class_name TestStage6

func run(c: Checker) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345

	c.section("shuffle_with keeps every card")
	var cards = _make_cards(10)
	var cards_copy = cards.duplicate()
	HandRules.shuffle_with(cards, rng)
	c.check(cards.size() == 10, "shuffle preserves count")
	var all_found = true
	for card in cards_copy:
		if not cards.has(card):
			all_found = false
	c.check(all_found, "shuffle keeps every card (no duplicates)")

	c.section("shuffle_with same seed same order")
	var rng_a = RandomNumberGenerator.new()
	rng_a.seed = 12345
	var rng_b = RandomNumberGenerator.new()
	rng_b.seed = 12345
	var deck_a = _make_cards(10)
	var deck_b = _make_cards(10)
	HandRules.shuffle_with(deck_a, rng_a)
	HandRules.shuffle_with(deck_b, rng_b)
	var same = true
	for i in range(10):
		if deck_a[i].name != deck_b[i].name:
			same = false
	c.check(same, "same seed gives same order")

	c.section("shuffle_with different seed different order")
	var rng_c = RandomNumberGenerator.new()
	rng_c.seed = 99999
	var deck_c = _make_cards(10)
	HandRules.shuffle_with(deck_c, rng_c)
	var different = false
	for i in range(10):
		if deck_c[i] != deck_a[i]:
			different = true
	c.check(different, "different seed gives different order")

	c.section("draw_card moves top card to hand")
	var p = Player.new()
	p.deck = _make_cards(5)
	var top_card = p.deck[0]
	var drawn = HandRules.draw_card(p)
	c.check(drawn == top_card, "draw_card returns top card")
	c.check(p.hand.size() == 1, "draw_card adds to hand")
	c.check(p.hand[0] == top_card, "hand contains drawn card")
	c.check(p.deck.size() == 4, "deck shrinks by 1")

	c.section("draw_card on empty deck returns null")
	var p2 = Player.new()
	p2.deck = []
	var result2 = HandRules.draw_card(p2)
	c.check(result2 == null, "draw_card on empty deck returns null")
	c.check(p2.hand.size() == 0, "hand unchanged after empty draw")

	c.section("draw_cards with fewer cards in deck")
	var p3 = Player.new()
	p3.deck = _make_cards(3)
	var drawn3 = HandRules.draw_cards(p3, 5)
	c.check(drawn3 == 3, "draw_cards returns 3 when only 3 in deck")
	c.check(p3.hand.size() == 3, "hand has 3 cards")
	c.check(p3.deck.size() == 0, "deck is empty")

	c.section("setup_player basic")
	var p4 = Player.new()
	p4.deck = _make_cards(10)
	var rng4 = RandomNumberGenerator.new()
	rng4.seed = 12345
	var ok4 = HandRules.setup_player(p4, rng4)
	c.check(ok4, "setup_player succeeds with 10-card deck")
	c.check(p4.lanes[0].state == Lane.LaneState.FACE_DOWN, "lane 0 is FACE_DOWN")
	c.check(p4.lanes[1].state == Lane.LaneState.FACE_DOWN, "lane 1 is FACE_DOWN")
	c.check(p4.lanes[2].state == Lane.LaneState.FACE_DOWN, "lane 2 is FACE_DOWN")
	c.check(p4.lanes[3].state == Lane.LaneState.FACE_DOWN, "lane 3 is FACE_DOWN")
	c.check(p4.hand.size() == 5, "hand has 5 cards")
	c.check(p4.deck.size() == 1, "deck has 1 card remaining")

	c.section("setup_player card conservation")
	var original_size = 10
	var total = 0
	for lane in p4.lanes:
		if lane.card != null:
			total += 1
	total += p4.hand.size()
	total += p4.deck.size()
	c.check(total == original_size, "cards conserved: lanes + hand + deck = original")

	c.section("setup_player with neutral cards")
	var p5 = Player.new()
	p5.deck = _make_cards(10)
	var neutral = [Card.new("Neutral", Card.CardType.SPELL, Tile.Biome.PLAINS, "neutral_effect")]
	var rng5 = RandomNumberGenerator.new()
	rng5.seed = 12345
	var ok5 = HandRules.setup_player(p5, rng5, neutral)
	c.check(ok5, "setup_player with neutrals succeeds")
	var neutral_in_hand = false
	for card in p5.hand:
		if card.name == "Neutral":
			neutral_in_hand = true
	c.check(not neutral_in_hand, "neutral cards not in hand")
	var neutral_in_lanes = false
	for lane in p5.lanes:
		if lane.card != null and lane.card.name == "Neutral":
			neutral_in_lanes = true
	c.check(not neutral_in_lanes, "neutral cards not in lanes")
	var total5 = 0
	for lane in p5.lanes:
		if lane.card != null:
			total5 += 1
	total5 += p5.hand.size()
	total5 += p5.deck.size()
	c.check(total5 == 11, "cards conserved with neutrals: 10 original + 1 neutral")

	c.section("each player gets own copy of neutral")
	var p6a = Player.new()
	p6a.deck = _make_cards(10)
	var p6b = Player.new()
	p6b.deck = _make_cards(10)
	var neutral6 = [Card.new("Neutral6", Card.CardType.SPELL, Tile.Biome.PLAINS, "n6")]
	var rng6a = RandomNumberGenerator.new()
	rng6a.seed = 12345
	var rng6b = RandomNumberGenerator.new()
	rng6b.seed = 12345
	HandRules.setup_player(p6a, rng6a, neutral6)
	HandRules.setup_player(p6b, rng6b, neutral6)
	var neutral_in_deck_a = false
	var neutral_in_deck_b = false
	for card in p6a.deck:
		if card.name == "Neutral6":
			neutral_in_deck_a = true
	for card in p6b.deck:
		if card.name == "Neutral6":
			neutral_in_deck_b = true
	c.check(neutral_in_deck_a, "player A has neutral in deck")
	c.check(neutral_in_deck_b, "player B has neutral in deck")
	var idx_a = -1
	var idx_b = -1
	for i in range(p6a.deck.size()):
		if p6a.deck[i].name == "Neutral6":
			idx_a = i
	for i in range(p6b.deck.size()):
		if p6b.deck[i].name == "Neutral6":
			idx_b = i
	if idx_a >= 0 and idx_b >= 0:
		p6a.deck[idx_a].effect_id = "modified"
		c.check(p6b.deck[idx_b].effect_id == "n6", "modifying one player's neutral does not change the other's")

	c.section("setup_player with 3-card deck fails")
	var p7 = Player.new()
	p7.deck = _make_cards(3)
	var rng7 = RandomNumberGenerator.new()
	rng7.seed = 12345
	var ok7 = HandRules.setup_player(p7, rng7)
	c.check(not ok7, "setup_player fails with 3-card deck")
	c.check(p7.hand.size() == 0, "hand unchanged after failed setup")
	c.check(p7.deck.size() == 3, "deck unchanged after failed setup")
	c.check(p7.lanes[0].state == Lane.LaneState.FLIPPED, "lane 0 unchanged after failed setup")

	c.section("setup_player with 4-card deck")
	var p8 = Player.new()
	p8.deck = _make_cards(4)
	var rng8 = RandomNumberGenerator.new()
	rng8.seed = 12345
	var ok8 = HandRules.setup_player(p8, rng8)
	c.check(ok8, "setup_player succeeds with 4-card deck")
	c.check(p8.hand.size() == 0, "hand empty with 4-card deck (all used for lanes)")
	c.check(p8.deck.size() == 0, "deck empty with 4-card deck")

	c.section("play_monster success")
	var p9 = Player.new()
	p9.deck = _make_cards(10)
	var rng9 = RandomNumberGenerator.new()
	rng9.seed = 12345
	HandRules.setup_player(p9, rng9)
	p9.lanes[0].state = Lane.LaneState.FLIPPED
	p9.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	var monster_card = Card.new("Goblin", Card.CardType.MONSTER, Tile.Biome.PLAINS, "", Cost.new(), 1, 2, 3)
	p9.hand.append(monster_card)
	var hand_size_before = p9.hand.size()
	var result9 = HandRules.play_monster(p9, p9.hand.size() - 1, 0, 0)
	c.check(result9, "play_monster succeeds")
	c.check(p9.hand.size() == hand_size_before - 1, "card removed from hand")
	c.check(p9.monsters.size() == 1, "monster placed on board")
	c.check(p9.monsters[0].atk == 2, "monster has correct ATK")
	c.check(p9.monsters[0].hp == 3, "monster has correct HP")

	c.section("play_monster size 2 occupies 2 sections")
	var p10 = Player.new()
	p10.deck = _make_cards(10)
	var rng10 = RandomNumberGenerator.new()
	rng10.seed = 12345
	HandRules.setup_player(p10, rng10)
	p10.lanes[0].state = Lane.LaneState.FLIPPED
	p10.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	var big_monster = Card.new("Big", Card.CardType.MONSTER, Tile.Biome.PLAINS, "", Cost.new(), 2, 1, 5)
	p10.hand.append(big_monster)
	var result10 = HandRules.play_monster(p10, p10.hand.size() - 1, 0, 1)
	c.check(result10, "play_monster size 2 succeeds")
	c.check(p10.monsters.size() == 1, "monster placed")
	c.check(p10.monsters[0].size == 2, "monster has size 2")
	c.check(p10.monsters[0].start_index == 1, "monster starts at index 1")

	c.section("play_monster fails on FACE_DOWN lane")
	var p11 = Player.new()
	p11.deck = _make_cards(10)
	var rng11 = RandomNumberGenerator.new()
	rng11.seed = 12345
	HandRules.setup_player(p11, rng11)
	var monster_card11 = Card.new("Goblin", Card.CardType.MONSTER, Tile.Biome.PLAINS, "", Cost.new(), 1, 1, 1)
	p11.hand.append(monster_card11)
	var before11 = p11.hand.size()
	var result11 = HandRules.play_monster(p11, p11.hand.size() - 1, 0, 0)
	c.check(not result11, "play_monster fails on FACE_DOWN lane")
	c.check(p11.hand.size() == before11, "card stays in hand after failed play")
	c.check(p11.monsters.size() == 0, "no monster placed")

	c.section("play_monster fails when overlapping monster")
	var p12 = Player.new()
	p12.deck = _make_cards(10)
	var rng12 = RandomNumberGenerator.new()
	rng12.seed = 12345
	HandRules.setup_player(p12, rng12)
	p12.lanes[0].state = Lane.LaneState.FLIPPED
	p12.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	var existing = Monster.new("Existing", 1, 0, 0, 1, 1)
	p12.monsters = [existing]
	var monster_card12 = Card.new("New", Card.CardType.MONSTER, Tile.Biome.PLAINS, "", Cost.new(), 1, 1, 1)
	p12.hand.append(monster_card12)
	var before12 = p12.hand.size()
	var result12 = HandRules.play_monster(p12, p12.hand.size() - 1, 0, 0)
	c.check(not result12, "play_monster fails when overlapping")
	c.check(p12.hand.size() == before12, "card stays in hand after failed play")
	c.check(p12.monsters.size() == 1, "no new monster placed")

	c.section("play_monster fails when cost cannot be paid")
	var p13 = Player.new()
	p13.deck = _make_cards(10)
	var rng13 = RandomNumberGenerator.new()
	rng13.seed = 12345
	HandRules.setup_player(p13, rng13)
	p13.lanes[0].state = Lane.LaneState.FLIPPED
	p13.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	for tile in p13.lanes[0].tiles:
		tile.state = Tile.State.BROKEN
	var costly_monster = Card.new("Costly", Card.CardType.MONSTER, Tile.Biome.PLAINS, "", Cost.new({Tile.Biome.PLAINS: 1}))
	p13.hand.append(costly_monster)
	var before13 = p13.hand.size()
	var result13 = HandRules.play_monster(p13, p13.hand.size() - 1, 0, 0)
	c.check(not result13, "play_monster fails when cost cannot be paid")
	c.check(p13.hand.size() == before13, "card stays in hand after failed play")
	c.check(p13.monsters.size() == 0, "no monster placed")

	c.section("play_monster fails when card is not MONSTER")
	var p14 = Player.new()
	p14.deck = _make_cards(10)
	var rng14 = RandomNumberGenerator.new()
	rng14.seed = 12345
	HandRules.setup_player(p14, rng14)
	p14.lanes[0].state = Lane.LaneState.FLIPPED
	p14.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	var spell_card = Card.new("Fireball", Card.CardType.SPELL, Tile.Biome.PLAINS, "fireball", Cost.new())
	p14.hand.append(spell_card)
	var before14 = p14.hand.size()
	var result14 = HandRules.play_monster(p14, p14.hand.size() - 1, 0, 0)
	c.check(not result14, "play_monster fails for SPELL card")
	c.check(p14.hand.size() == before14, "card stays in hand after failed play")

	c.section("play_monster fails with bad hand_index")
	var p15 = Player.new()
	p15.deck = _make_cards(10)
	var rng15 = RandomNumberGenerator.new()
	rng15.seed = 12345
	HandRules.setup_player(p15, rng15)
	p15.lanes[0].state = Lane.LaneState.FLIPPED
	p15.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	var monster_card15 = Card.new("Goblin", Card.CardType.MONSTER, Tile.Biome.PLAINS, "", Cost.new())
	p15.hand.append(monster_card15)
	var result15a = HandRules.play_monster(p15, -1, 0, 0)
	c.check(not result15a, "play_monster fails with negative hand_index")
	var result15b = HandRules.play_monster(p15, 99, 0, 0)
	c.check(not result15b, "play_monster fails with too-large hand_index")

	c.section("play_spell success")
	var p16 = Player.new()
	p16.deck = _make_cards(10)
	var rng16 = RandomNumberGenerator.new()
	rng16.seed = 12345
	HandRules.setup_player(p16, rng16)
	p16.lanes[0].state = Lane.LaneState.FLIPPED
	p16.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	var spell16 = Card.new("Fireball", Card.CardType.SPELL, Tile.Biome.PLAINS, "fireball_damage", Cost.new({Tile.Biome.PLAINS: 1}))
	p16.hand.append(spell16)
	var result16 = HandRules.play_spell(p16, p16.hand.size() - 1)
	c.check(result16, "play_spell succeeds")
	c.check(p16.trigger_log.has("fireball_damage"), "effect_id logged")
	c.check(p16.discard.size() == 1, "card moved to discard")
	c.check(p16.discard[0] == spell16, "correct card in discard")
	c.check(p16.hand.size() == 5, "card removed from hand")

	c.section("play_spell fails when cost cannot be paid")
	var p17 = Player.new()
	p17.deck = _make_cards(10)
	var rng17 = RandomNumberGenerator.new()
	rng17.seed = 12345
	HandRules.setup_player(p17, rng17)
	for lane in p17.lanes:
		lane.state = Lane.LaneState.FLIPPED
		lane.reset_tiles(Tile.Biome.PLAINS)
		for tile in lane.tiles:
			tile.state = Tile.State.BROKEN
	var costly_spell = Card.new("Costly", Card.CardType.SPELL, Tile.Biome.PLAINS, "costly", Cost.new({Tile.Biome.PLAINS: 1}))
	p17.hand.append(costly_spell)
	var before17 = p17.hand.size()
	var result17 = HandRules.play_spell(p17, p17.hand.size() - 1)
	c.check(not result17, "play_spell fails when cost cannot be paid")
	c.check(p17.hand.size() == before17, "card stays in hand after failed play")
	c.check(p17.discard.size() == 0, "card not in discard")

	c.section("set_trap success")
	var p18 = Player.new()
	p18.deck = _make_cards(10)
	var rng18 = RandomNumberGenerator.new()
	rng18.seed = 12345
	HandRules.setup_player(p18, rng18)
	p18.lanes[0].state = Lane.LaneState.FLIPPED
	p18.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	var trap18 = Card.new("Spike", Card.CardType.TRAP, Tile.Biome.PLAINS, "spike", Cost.new())
	p18.hand.append(trap18)
	var result18 = HandRules.set_trap(p18, p18.hand.size() - 1)
	c.check(result18, "set_trap succeeds")
	c.check(p18.set_traps.size() == 1, "trap stored in set_traps")
	c.check(p18.set_traps[0] == trap18, "correct trap stored")
	c.check(p18.hand.size() == 5, "card removed from hand")

	c.section("5th set_trap fails")
	var p19 = Player.new()
	p19.deck = _make_cards(10)
	var rng19 = RandomNumberGenerator.new()
	rng19.seed = 12345
	HandRules.setup_player(p19, rng19)
	p19.lanes[0].state = Lane.LaneState.FLIPPED
	p19.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	for i in range(4):
		var t = Card.new("Trap" + str(i), Card.CardType.TRAP, Tile.Biome.PLAINS, "trap" + str(i), Cost.new())
		p19.hand.append(t)
		HandRules.set_trap(p19, p19.hand.size() - 1)
	c.check(p19.set_traps.size() == 4, "4 traps set")
	var t5 = Card.new("Trap5", Card.CardType.TRAP, Tile.Biome.PLAINS, "trap5", Cost.new())
	p19.hand.append(t5)
	var before19 = p19.hand.size()
	var result19 = HandRules.set_trap(p19, p19.hand.size() - 1)
	c.check(not result19, "5th set_trap fails")
	c.check(p19.set_traps.size() == 4, "still 4 traps")
	c.check(p19.hand.size() == before19, "5th trap card stays in hand")

	c.section("discard_from_hand success")
	var p20 = Player.new()
	p20.deck = _make_cards(10)
	var rng20 = RandomNumberGenerator.new()
	rng20.seed = 12345
	HandRules.setup_player(p20, rng20)
	var card_to_discard = p20.hand[0]
	var result20 = HandRules.discard_from_hand(p20, 0)
	c.check(result20, "discard_from_hand succeeds")
	c.check(p20.hand.size() == 4, "card removed from hand")
	c.check(p20.discard.size() == 1, "card in discard")
	c.check(p20.discard[0] == card_to_discard, "correct card discarded")

func _make_cards(n: int) -> Array:
	var cards: Array = []
	for i in range(n):
		cards.append(Card.new("Card" + str(i), Card.CardType.MONSTER, Tile.Biome.PLAINS))
	return cards