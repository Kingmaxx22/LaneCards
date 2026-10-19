extends RefCounted
class_name TestStage2

func run(c: Checker) -> void:
	c.section("can_pay / pay_cost")
	var p = Player.new()
	var cost1 = Cost.new({Tile.Biome.PLAINS: 2})
	c.check(GameEngine.can_pay(p, cost1), "can_pay: 16 PLAINS READY, needs 2 -> true")
	var p2 = Player.new()
	for i in range(15):
		var lane_idx = i / 4
		var tile_idx = i % 4
		p2.lanes[lane_idx].tiles[tile_idx].state = Tile.State.BURNED
	c.check(not GameEngine.can_pay(p2, cost1), "can_pay: 1 PLAINS READY, needs 2 -> false")
	var p3 = Player.new()
	var result3 = GameEngine.pay_cost(p3, cost1)
	c.check(result3 == true, "pay_cost returns true when affordable")
	var ready_after = 0
	for lane in p3.lanes:
		for tile in lane.tiles:
			if tile.is_ready():
				ready_after += 1
	c.check(ready_after == 14, "pay_cost burned 2 tiles (16 -> 14 READY)")
	var p4 = Player.new()
	for i in range(15):
		var lane_idx2 = i / 4
		var tile_idx2 = i % 4
		p4.lanes[lane_idx2].tiles[tile_idx2].state = Tile.State.BURNED
	var result4 = GameEngine.pay_cost(p4, cost1)
	c.check(result4 == false, "pay_cost returns false when not affordable")
	var ready_after4 = 0
	for lane in p4.lanes:
		for tile in lane.tiles:
			if tile.is_ready():
				ready_after4 += 1
	c.check(ready_after4 == 1, "pay_cost with insufficient tiles burns nothing (1 READY left)")
	var p5 = Player.new()
	p5.lanes[0].tiles[0].state = Tile.State.BURNED
	p5.lanes[0].tiles[1].state = Tile.State.BROKEN
	var cost5 = Cost.new({Tile.Biome.PLAINS: 2})
	var result5 = GameEngine.pay_cost(p5, cost5)
	c.check(result5 == true, "pay_cost works with BURNED/BROKEN tiles present")
	var ready_after5 = 0
	for lane in p5.lanes:
		for tile in lane.tiles:
			if tile.is_ready():
				ready_after5 += 1
	c.check(ready_after5 == 12, "pay_cost skips BURNED/BROKEN, burns 2 READY (14 -> 12)")

	c.section("monster placement and survival")
	var p6 = Player.new()
	var m1 = Monster.new("Test4", 4, 0, 0)
	var r1 = GameEngine.place_monster(p6, 0, 0, m1)
	c.check(r1 == true, "size-4 monster at start 0 fits")
	var p7 = Player.new()
	var m2 = Monster.new("Test4b", 4, 0, 1)
	var r2 = GameEngine.place_monster(p7, 0, 1, m2)
	c.check(r2 == false, "size-4 monster at start 1 fails (off the end)")
	var p8 = Player.new()
	var m3 = Monster.new("Test2", 2, 0, 3)
	var r3 = GameEngine.place_monster(p8, 0, 3, m3)
	c.check(r3 == false, "size-2 monster at start 3 fails (off the end)")
	var p9 = Player.new()
	p9.lanes[0].tiles[1].state = Tile.State.BROKEN
	var m4 = Monster.new("Test3", 3, 0, 0)
	var r4 = GameEngine.place_monster(p9, 0, 0, m4)
	c.check(r4 == false, "placing over BROKEN tile fails")
	var p10 = Player.new()
	var m5a = Monster.new("First", 2, 0, 0)
	GameEngine.place_monster(p10, 0, 0, m5a)
	var m5b = Monster.new("Second", 2, 0, 1)
	var r5 = GameEngine.place_monster(p10, 0, 1, m5b)
	c.check(r5 == false, "placing over another monster fails")
	var p11 = Player.new()
	var m6 = Monster.new("Survivor", 2, 0, 0)
	GameEngine.place_monster(p11, 0, 0, m6)
	p11.lanes[0].tiles[0].state = Tile.State.BROKEN
	c.check(GameEngine.is_monster_alive(m6, p11), "monster survives with 1 of 2 tiles BROKEN")
	var p12 = Player.new()
	var m7 = Monster.new("Burned", 2, 0, 0)
	GameEngine.place_monster(p12, 0, 0, m7)
	p12.lanes[0].tiles[0].state = Tile.State.BURNED
	p12.lanes[0].tiles[1].state = Tile.State.BURNED
	c.check(GameEngine.is_monster_alive(m7, p12), "monster survives when tiles are BURNED")
	var p13 = Player.new()
	var m8 = Monster.new("Doomed", 2, 0, 0)
	GameEngine.place_monster(p13, 0, 0, m8)
	p13.lanes[0].tiles[0].state = Tile.State.BROKEN
	p13.lanes[0].tiles[1].state = Tile.State.BROKEN
	c.check(not GameEngine.is_monster_alive(m8, p13), "monster dies when all its tiles are BROKEN")