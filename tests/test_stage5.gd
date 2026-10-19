extends RefCounted
class_name TestStage5

func run(c: Checker) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345

	c.section("controls_biome checks")
	var p = Player.new()
	p.lanes[0].state = Lane.LaneState.FACE_DOWN
	p.lanes[0].card = Card.new("VolcanoCard", Card.CardType.MONSTER, Tile.Biome.VOLCANO)
	c.check(not Upkeep.controls_biome(p, Tile.Biome.VOLCANO), "controls_biome false for FACE_DOWN Volcano lane")
	p.lanes[0].state = Lane.LaneState.FLIPPED
	p.lanes[0].reset_tiles(Tile.Biome.VOLCANO)
	c.check(Upkeep.controls_biome(p, Tile.Biome.VOLCANO), "controls_biome true for FLIPPED Volcano lane")
	p.lanes[0].reset_tiles(Tile.Biome.PLAINS)
	c.check(not Upkeep.controls_biome(p, Tile.Biome.VOLCANO), "controls_biome false for FLIPPED non-Volcano lane")

	c.section("normal upkeep no Volcano no Ocean")
	var p2 = Player.new()
	p2.lanes[0].tiles[0].state = Tile.State.BURNED
	var result2 = Upkeep.run_upkeep(p2, rng)
	c.check(result2.returned == 1, "normal upkeep returns 1 tile")
	c.check(not result2.burned_by_volcano, "no volcano burn without Volcano")
	c.check(not result2.flooded, "no flood without Ocean")

	c.section("FACE_DOWN Volcano lane does not stop normal return")
	var p3 = Player.new()
	p3.lanes[0].state = Lane.LaneState.FACE_DOWN
	p3.lanes[0].card = Card.new("VolcanoCard", Card.CardType.MONSTER, Tile.Biome.VOLCANO)
	p3.lanes[1].tiles[0].state = Tile.State.BURNED
	var result3 = Upkeep.run_upkeep(p3, rng)
	c.check(result3.returned == 1, "FACE_DOWN Volcano lane does not stop normal return")

	c.section("Volcano present no tile returns")
	var p4 = Player.new()
	p4.lanes[0].reset_tiles(Tile.Biome.VOLCANO)
	p4.lanes[1].tiles[0].state = Tile.State.BURNED
	var ready_before = 0
	for tile in p4.usable_tiles():
		if tile.is_ready():
			ready_before += 1
	var result4 = Upkeep.run_upkeep(p4, rng)
	var ready_after = 0
	for tile in p4.usable_tiles():
		if tile.is_ready():
			ready_after += 1
	c.check(result4.returned == 0, "Volcano: no tile returns")
	c.check(result4.burned_by_volcano, "Volcano: burned_by_volcano is true")
	c.check(ready_after == ready_before - 1, "Volcano: exactly 1 READY tile burned")

	c.section("Volcano with existing BURNED tiles")
	var p5 = Player.new()
	p5.lanes[0].reset_tiles(Tile.Biome.VOLCANO)
	p5.lanes[1].tiles[0].state = Tile.State.BURNED
	p5.lanes[1].tiles[1].state = Tile.State.BURNED
	var burned_before5 = 0
	for lane in p5.lanes:
		if lane.state == Lane.LaneState.FLIPPED:
			for tile in lane.tiles:
				if tile.is_burned():
					burned_before5 += 1
	var result5 = Upkeep.run_upkeep(p5, rng)
	c.check(result5.burned_by_volcano, "Volcano with existing BURNED: volcano burns")
	var burned_after5 = 0
	for lane in p5.lanes:
		if lane.state == Lane.LaneState.FLIPPED:
			for tile in lane.tiles:
				if tile.is_burned():
					burned_after5 += 1
	c.check(burned_after5 == burned_before5 + 1, "Volcano: exactly 1 new BURNED tile")

	c.section("Volcano with no READY tiles does nothing")
	var p6 = Player.new()
	p6.lanes[0].reset_tiles(Tile.Biome.VOLCANO)
	for lane in p6.lanes:
		if lane.state == Lane.LaneState.FLIPPED:
			for tile in lane.tiles:
				tile.state = Tile.State.BURNED
	var result6 = Upkeep.run_upkeep(p6, rng)
	c.check(not result6.burned_by_volcano, "Volcano with no READY: burned_by_volcano is false")
	var ready6 = 0
	for lane in p6.lanes:
		if lane.state == Lane.LaneState.FLIPPED:
			for tile in lane.tiles:
				if tile.is_ready():
					ready6 += 1
	c.check(ready6 == 0, "Volcano with no READY: still 0 READY")

	c.section("Volcano only burns tiles in FLIPPED lanes")
	var p7 = Player.new()
	p7.lanes[0].state = Lane.LaneState.FACE_DOWN
	p7.lanes[0].card = Card.new("VolcanoCard", Card.CardType.MONSTER, Tile.Biome.VOLCANO)
	p7.lanes[0].tiles[0].state = Tile.State.READY
	p7.lanes[0].tiles[0].biome = Tile.Biome.VOLCANO
	p7.lanes[1].reset_tiles(Tile.Biome.VOLCANO)
	var result7 = Upkeep.run_upkeep(p7, rng)
	c.check(result7.burned_by_volcano, "Volcano only in FLIPPED lanes: burns")
	c.check(p7.lanes[0].tiles[0].is_ready(), "FACE_DOWN Volcano tile not burned")

	c.section("Ocean present no tile returns")
	var p8 = Player.new()
	p8.lanes[0].reset_tiles(Tile.Biome.OCEAN)
	p8.lanes[1].tiles[0].state = Tile.State.BROKEN
	var result8 = Upkeep.run_upkeep(p8, rng)
	c.check(result8.returned == 0, "Ocean: no tile returns")
	c.check(result8.flooded, "Ocean: flooded is true")
	c.check(p8.lanes[1].tiles[0].biome == Tile.Biome.OCEAN, "Ocean: flooded tile becomes OCEAN biome")
	c.check(p8.lanes[1].tiles[0].is_burned(), "Ocean: flooded tile becomes BURNED")

	c.section("Ocean with no BROKEN tiles does nothing")
	var p9 = Player.new()
	p9.lanes[0].reset_tiles(Tile.Biome.OCEAN)
	p9.lanes[1].tiles[0].state = Tile.State.BURNED
	var result9 = Upkeep.run_upkeep(p9, rng)
	c.check(result9.returned == 0, "Ocean with no BROKEN: no tile returns")
	c.check(not result9.flooded, "Ocean with no BROKEN: flooded is false")
	var broken9 = 0
	for lane in p9.lanes:
		if lane.state == Lane.LaneState.FLIPPED:
			for tile in lane.tiles:
				if tile.is_broken():
					broken9 += 1
	c.check(broken9 == 0, "Ocean with no BROKEN: no broken tiles")

	c.section("flooded tile can break and be flooded again")
	var p10 = Player.new()
	p10.lanes[0].reset_tiles(Tile.Biome.OCEAN)
	p10.lanes[1].tiles[0].state = Tile.State.BROKEN
	var r10a = Upkeep.run_upkeep(p10, rng)
	c.check(r10a.flooded, "first flood succeeds")
	c.check(p10.lanes[1].tiles[0].is_burned(), "tile is BURNED after first flood")
	p10.lanes[1].tiles[0].state = Tile.State.BROKEN
	var r10b = Upkeep.run_upkeep(p10, rng)
	c.check(r10b.flooded, "second flood succeeds after re-break")

	c.section("lane with 3 BROKEN tiles floods one back no collapse")
	var p11 = Player.new()
	p11.lanes[0].reset_tiles(Tile.Biome.OCEAN)
	p11.lanes[1].tiles[0].state = Tile.State.BROKEN
	p11.lanes[1].tiles[1].state = Tile.State.BROKEN
	p11.lanes[1].tiles[2].state = Tile.State.BROKEN
	var r11 = Upkeep.run_upkeep(p11, rng)
	c.check(r11.flooded, "flood one of 3 broken tiles")
	c.check(p11.lanes[1].state == Lane.LaneState.FLIPPED, "lane still FLIPPED after flood")
	var broken11 = 0
	for tile in p11.lanes[1].tiles:
		if tile.is_broken():
			broken11 += 1
	c.check(broken11 == 2, "2 BROKEN tiles remain after flood")

	c.section("flood picks first BROKEN tile in lane then tile order")
	var p12 = Player.new()
	p12.lanes[0].reset_tiles(Tile.Biome.OCEAN)
	p12.lanes[1].tiles[0].state = Tile.State.BROKEN
	p12.lanes[1].tiles[1].state = Tile.State.BROKEN
	var r12 = Upkeep.run_upkeep(p12, rng)
	c.check(r12.flooded, "flood succeeds")
	c.check(p12.lanes[1].tiles[0].biome == Tile.Biome.OCEAN, "first BROKEN tile flooded (tile 0)")
	c.check(p12.lanes[1].tiles[1].biome != Tile.Biome.OCEAN, "second BROKEN tile not flooded yet")

	c.section("Volcano and Ocean both present")
	var p13 = Player.new()
	p13.lanes[0].reset_tiles(Tile.Biome.VOLCANO)
	p13.lanes[1].reset_tiles(Tile.Biome.OCEAN)
	p13.lanes[2].tiles[0].state = Tile.State.BROKEN
	p13.lanes[3].tiles[0].state = Tile.State.BROKEN
	var result13 = Upkeep.run_upkeep(p13, rng)
	c.check(result13.returned == 0, "Both: no tile returns")
	c.check(result13.burned_by_volcano, "Both: volcano burns")
	c.check(result13.flooded, "Both: ocean floods")
	c.check(p13.lanes[2].tiles[0].biome == Tile.Biome.OCEAN, "Both: BROKEN tile flooded")

	c.section("return_burned_tile bypasses Volcano rule")
	var p14 = Player.new()
	p14.lanes[0].reset_tiles(Tile.Biome.VOLCANO)
	p14.lanes[1].tiles[0].state = Tile.State.BURNED
	p14.lanes[1].tiles[1].state = Tile.State.BURNED
	var ret14 = Upkeep.return_burned_tile(p14, 2)
	c.check(ret14 == 2, "return_burned_tile returns 2 tiles even with Volcano")

	c.section("return_burned_tile with only 1 burned tile")
	var p15 = Player.new()
	p15.lanes[0].reset_tiles(Tile.Biome.VOLCANO)
	p15.lanes[1].tiles[0].state = Tile.State.BURNED
	var ret15 = Upkeep.return_burned_tile(p15, 2)
	c.check(ret15 == 1, "return_burned_tile returns 1 when only 1 burned")

	c.section("start_turn resets flips and attacks then runs upkeep")
	var p16 = Player.new()
	p16.flips_this_turn = 1
	var m16 = Monster.new("Test", 1, 0, 0, 1, 5)
	m16.has_attacked = true
	p16.monsters = [m16]
	p16.lanes[1].tiles[0].state = Tile.State.BURNED
	Upkeep.start_turn(p16, rng)
	c.check(p16.flips_this_turn == 0, "start_turn resets flips_this_turn")
	c.check(not m16.has_attacked, "start_turn resets has_attacked")
	c.check(p16.lanes[1].tiles[0].is_ready(), "start_turn runs upkeep and returns burned tile")