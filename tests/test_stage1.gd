extends RefCounted
class_name TestStage1

func run(c: Checker) -> void:
	c.section("burn_tile")
	var t = Tile.new()
	c.check(t.is_ready(), "new tile is READY")
	var result = GameEngine.burn_tile(t)
	c.check(result == true, "burn_tile returns true on READY tile")
	c.check(t.is_burned(), "READY -> BURNED after burn_tile")
	var t2 = Tile.new()
	t2.state = Tile.State.BURNED
	var result2 = GameEngine.burn_tile(t2)
	c.check(result2 == false, "burn_tile returns false on BURNED tile")
	c.check(t2.is_burned(), "burning already-BURNED tile stays BURNED")

	c.section("break_tile")
	var t3 = Tile.new()
	t3.state = Tile.State.READY
	GameEngine.break_tile(t3)
	c.check(t3.is_broken(), "READY -> BROKEN after break_tile")
	var t4 = Tile.new()
	t4.state = Tile.State.BURNED
	GameEngine.break_tile(t4)
	c.check(t4.is_broken(), "BURNED -> BROKEN after break_tile")
	var t5 = Tile.new()
	t5.state = Tile.State.BROKEN
	GameEngine.break_tile(t5)
	c.check(t5.is_broken(), "BROKEN stays BROKEN (idempotent)")

	c.section("upkeep")
	var p = Player.new()
	p.lanes[0].tiles[0].state = Tile.State.BURNED
	p.lanes[1].tiles[0].state = Tile.State.BURNED
	var burned_before = _count_burned(p)
	c.check(burned_before == 2, "setup: 2 burned tiles before upkeep")
	GameEngine.upkeep(p)
	var burned_after = _count_burned(p)
	c.check(burned_after == 1, "upkeep returns exactly 1 burned tile to READY")

	c.section("has_lost")
	var p2 = Player.new()
	c.check(not GameEngine.has_lost(p2), "new player has not lost")
	p2.hp = 0
	c.check(GameEngine.has_lost(p2), "player loses at 0 HP")
	p2.hp = 5
	c.check(not GameEngine.has_lost(p2), "player with HP > 0 and tiles intact has not lost")
	p2.hp = 20
	for lane in p2.lanes:
		for tile in lane.tiles:
			tile.state = Tile.State.BROKEN
	c.check(GameEngine.has_lost(p2), "player loses when all 16 tiles are BROKEN")

	c.section("edge cases")
	var p3 = Player.new()
	c.check(_count_burned(p3) == 0, "new player has 0 burned tiles")
	var all_broken_before = _count_broken(p3)
	c.check(all_broken_before == 0, "new player has 0 broken tiles")
	c.check(_count_ready(p3) == 16, "new player has 16 ready tiles")
	c.check(_count_burned(p3) == 0, "upkeep with no burned tiles does nothing")
	for lane in p3.lanes:
		for tile in lane.tiles:
			tile.state = Tile.State.BROKEN
	c.check(_count_burned(p3) == 0, "no burned tiles when all are BROKEN")
	p3.lanes[0].tiles[0].state = Tile.State.BURNED
	c.check(not GameEngine.has_lost(p3), "player with 1 BURNED tile has not lost")
	p3.lanes[0].tiles[1].state = Tile.State.BURNED
	p3.lanes[0].tiles[2].state = Tile.State.BURNED
	p3.lanes[0].tiles[3].state = Tile.State.BURNED
	c.check(not GameEngine.has_lost(p3), "player with 4 BURNED tiles has not lost")

func _count_burned(p: Player) -> int:
	var count = 0
	for lane in p.lanes:
		count += lane.burned_count()
	return count

func _count_broken(p: Player) -> int:
	var count = 0
	for lane in p.lanes:
		for tile in lane.tiles:
			if tile.is_broken():
				count += 1
	return count

func _count_ready(p: Player) -> int:
	var count = 0
	for lane in p.lanes:
		for tile in lane.tiles:
			if tile.is_ready():
				count += 1
	return count