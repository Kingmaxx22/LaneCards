extends RefCounted
class_name TestStage3

func run(c: Checker) -> void:
	c.section("block rule constants")
	c.check(Constants.DEFAULT_BLOCK_RULE == Constants.BlockRule.LANE, "default block rule is LANE")
	c.check(GameEngine.block_rule == Constants.BlockRule.LANE, "engine block_rule starts as LANE")

	c.section("get_targets")
	var p = Player.new()
	var m1 = Monster.new("A", 1, 0, 0, 2, 3)
	var m2 = Monster.new("B", 1, 0, 1, 1, 1)
	var m3 = Monster.new("C", 1, 2, 0, 1, 1)
	p.monsters = [m1, m2, m3]
	c.check(GameEngine.get_targets(p, 0).size() == 2, "get_targets lane 0 returns 2 monsters")
	c.check(GameEngine.get_targets(p, 2).size() == 1, "get_targets lane 2 returns 1 monster")
	c.check(GameEngine.get_targets(p, 3).size() == 0, "get_targets lane 3 returns 0 monsters")

	c.section("can_attack_directly LANE rule")
	var p2 = Player.new()
	var m4 = Monster.new("Defender", 1, 0, 0, 1, 1)
	p2.monsters = [m4]
	c.check(not GameEngine.can_attack_directly(p2, 0), "LANE: direct attack on lane 0 fails (has monster)")
	c.check(GameEngine.can_attack_directly(p2, 2), "LANE: direct attack on lane 2 succeeds (empty lane)")
	c.check(GameEngine.can_attack_directly(p2, 3), "LANE: direct attack on lane 3 succeeds (empty lane)")

	c.section("can_attack_directly GLOBAL rule")
	var p3 = Player.new()
	var m5 = Monster.new("Defender2", 1, 0, 0, 1, 1)
	p3.monsters = [m5]
	GameEngine.block_rule = Constants.BlockRule.GLOBAL
	c.check(not GameEngine.can_attack_directly(p3, 0), "GLOBAL: direct attack on lane 0 fails (has monster)")
	c.check(not GameEngine.can_attack_directly(p3, 2), "GLOBAL: direct attack on lane 2 fails (monster elsewhere)")
	var p4 = Player.new()
	c.check(GameEngine.can_attack_directly(p4, 0), "GLOBAL: direct attack succeeds with no monsters")
	c.check(GameEngine.can_attack_directly(p4, 3), "GLOBAL: direct attack succeeds with no monsters (any lane)")
	GameEngine.block_rule = Constants.DEFAULT_BLOCK_RULE

	c.section("attack_monster simultaneous damage")
	var atk = Player.new()
	var def = Player.new()
	var attacker = Monster.new("Attacker", 1, 0, 0, 3, 5)
	var defender = Monster.new("Defender", 1, 1, 0, 2, 4)
	atk.monsters = [attacker]
	def.monsters = [defender]
	c.check(GameEngine.attack_monster(atk, def, attacker, defender) == true, "attack_monster returns true on success")
	c.check(attacker.hp == 3, "attacker takes damage equal to defender ATK (5 -> 3)")
	c.check(defender.hp == 1, "defender takes damage equal to attacker ATK (4 -> 1)")

	c.section("attack_monster cross-lane")
	var atk2 = Player.new()
	var def2 = Player.new()
	var attacker2 = Monster.new("CrossAtk", 1, 0, 0, 1, 5)
	var defender2 = Monster.new("CrossDef", 1, 3, 0, 1, 5)
	atk2.monsters = [attacker2]
	def2.monsters = [defender2]
	c.check(GameEngine.attack_monster(atk2, def2, attacker2, defender2) == true, "monster in lane 0 can attack defender monster in lane 3")

	c.section("attack_monster lethal damage removes monster")
	var atk3 = Player.new()
	var def3 = Player.new()
	var attacker3 = Monster.new("LethalAtk", 1, 0, 0, 5, 3)
	var defender3 = Monster.new("LethalDef", 1, 1, 0, 1, 5)
	atk3.monsters = [attacker3]
	def3.monsters = [defender3]
	c.check(GameEngine.attack_monster(atk3, def3, attacker3, defender3) == true, "attack_monster with lethal damage returns true")
	c.check(def3.monsters.size() == 0, "defender monster at 0 HP is removed")

	c.section("attack_monster survivor at 1 HP")
	var atk4 = Player.new()
	var def4 = Player.new()
	var attacker4 = Monster.new("SurvAtk", 1, 0, 0, 2, 3)
	var defender4 = Monster.new("SurvDef", 1, 1, 0, 1, 3)
	atk4.monsters = [attacker4]
	def4.monsters = [defender4]
	c.check(GameEngine.attack_monster(atk4, def4, attacker4, defender4) == true, "attack_monster returns true when both survive")
	c.check(defender4.hp == 1, "defender monster at 1 HP survives")
	c.check(def4.monsters.size() == 1, "defender monster at 1 HP stays in play")

	c.section("attack_monster twice fails then reset")
	var atk5 = Player.new()
	var def5 = Player.new()
	var attacker5 = Monster.new("TwiceAtk", 1, 0, 0, 1, 5)
	var defender5 = Monster.new("TwiceDef", 1, 1, 0, 1, 5)
	atk5.monsters = [attacker5]
	def5.monsters = [defender5]
	c.check(GameEngine.attack_monster(atk5, def5, attacker5, defender5) == true, "first attack_monster succeeds")
	c.check(GameEngine.attack_monster(atk5, def5, attacker5, defender5) == false, "second attack_monster fails")
	c.check(GameEngine.attack_monster(atk5, def5, attacker5, defender5) == false, "third attack_monster fails")
	GameEngine.reset_attacks(atk5)
	c.check(GameEngine.attack_monster(atk5, def5, attacker5, defender5) == true, "attack after reset_attacks succeeds")

	c.section("attack_monster wrong owner fails")
	var atk7 = Player.new()
	var def7 = Player.new()
	var other7 = Player.new()
	var attacker7 = Monster.new("WrongAtk", 1, 0, 0, 1, 5)
	var defender7 = Monster.new("WrongDef", 1, 1, 0, 1, 5)
	atk7.monsters = [attacker7]
	other7.monsters = [defender7]
	c.check(GameEngine.attack_monster(atk7, def7, attacker7, defender7) == false, "attack_monster fails if target belongs to wrong player")

	c.section("attack_direct HP mode")
	var atk8 = Player.new()
	var def8 = Player.new()
	var attacker8 = Monster.new("HPAtk", 1, 0, 0, 3, 5)
	atk8.monsters = [attacker8]
	var hp_before = def8.hp
	c.check(GameEngine.attack_direct(atk8, def8, attacker8, 2, "HP") == true, "attack_direct HP mode returns true")
	c.check(def8.hp == hp_before - 3, "defender HP reduced by attacker ATK")

	c.section("attack_direct HP mode to 0 HP")
	var atk9 = Player.new()
	var def9 = Player.new()
	var attacker9 = Monster.new("LethalHP", 1, 0, 0, 25, 5)
	atk9.monsters = [attacker9]
	c.check(GameEngine.attack_direct(atk9, def9, attacker9, 2, "HP") == true, "attack_direct HP mode to 0 HP returns true")
	c.check(def9.hp <= 0, "defender HP at 0 or below")
	c.check(GameEngine.has_lost(def9), "has_lost is true at 0 HP")

	c.section("attack_direct TILE mode")
	var atk10 = Player.new()
	var def10 = Player.new()
	var attacker10 = Monster.new("TileAtk", 1, 0, 0, 2, 5)
	atk10.monsters = [attacker10]
	c.check(GameEngine.attack_direct(atk10, def10, attacker10, 2, "TILE", 1) == true, "attack_direct TILE mode returns true")
	c.check(def10.lanes[2].tiles[1].is_broken(), "target tile is BROKEN after TILE mode")
	c.check(def10.hp == Constants.PLAYER_HP, "defender HP unchanged after TILE mode")

	c.section("attack_direct TILE mode on BROKEN tile fails")
	var atk11 = Player.new()
	var def11 = Player.new()
	var attacker11 = Monster.new("TileAtk2", 1, 0, 0, 2, 5)
	atk11.monsters = [attacker11]
	def11.lanes[2].tiles[1].state = Tile.State.BROKEN
	c.check(GameEngine.attack_direct(atk11, def11, attacker11, 2, "TILE", 1) == false, "attack_direct TILE on BROKEN tile fails")
	c.check(not attacker11.has_attacked, "failed attack_direct does not set has_attacked")

	c.section("attack_direct out of range fails")
	var atk12 = Player.new()
	var def12 = Player.new()
	var attacker12 = Monster.new("RangeAtk", 1, 0, 0, 2, 5)
	atk12.monsters = [attacker12]
	c.check(GameEngine.attack_direct(atk12, def12, attacker12, 4, "HP") == false, "attack_direct with lane 4 fails")
	c.check(GameEngine.attack_direct(atk12, def12, attacker12, -1, "HP") == false, "attack_direct with lane -1 fails")
	c.check(GameEngine.attack_direct(atk12, def12, attacker12, 2, "TILE", 4) == false, "attack_direct with tile index 4 fails")
	c.check(GameEngine.attack_direct(atk12, def12, attacker12, 2, "TILE", -1) == false, "attack_direct with tile index -1 fails")

	c.section("attack_direct blocked by LANE rule")
	var atk13 = Player.new()
	var def13 = Player.new()
	var attacker13 = Monster.new("BlockedAtk", 1, 0, 0, 2, 5)
	var blocker13 = Monster.new("Blocker", 1, 0, 0, 1, 1)
	atk13.monsters = [attacker13]
	def13.monsters = [blocker13]
	c.check(GameEngine.attack_direct(atk13, def13, attacker13, 0, "HP") == false, "LANE: attack on occupied lane fails")
	c.check(not attacker13.has_attacked, "blocked attack_direct does not set has_attacked")

	c.section("breaking tile under monster removes it")
	var atk14 = Player.new()
	var def14 = Player.new()
	var attacker14 = Monster.new("TileBreaker", 1, 0, 0, 2, 5)
	var defender14 = Monster.new("TileVictim", 1, 2, 0, 1, 5)
	c.check(GameEngine.place_monster(atk14, 0, 0, attacker14) == true, "place_monster attacker")
	c.check(GameEngine.place_monster(def14, 2, 0, defender14) == true, "place_monster defender in lane 2")
	GameEngine.break_tile(def14.lanes[2].tiles[0])
	c.check(def14.lanes[2].tiles[0].is_broken(), "tile 0 of lane 2 is BROKEN")
	c.check(def14.monsters.size() == 1, "monster still in array before cleanup")
	c.check(GameEngine.remove_dead_monsters(def14) == 1, "remove_dead_monsters returns 1")
	c.check(def14.monsters.size() == 0, "size-1 monster removed when its only tile is broken")

	c.section("size-2 monster survives with 1 tile broken")
	var atk15 = Player.new()
	var def15 = Player.new()
	var attacker15 = Monster.new("TileAtk2", 1, 0, 0, 2, 5)
	var defender15 = Monster.new("TileSurvivor", 2, 2, 0, 1, 5)
	c.check(GameEngine.place_monster(atk15, 0, 0, attacker15) == true, "place_monster attacker 15")
	c.check(GameEngine.place_monster(def15, 2, 0, defender15) == true, "place_monster defender 15 (size 2)")
	c.check(GameEngine.remove_dead_monsters(def15) == 0, "size-2 monster with no broken tiles: remove_dead_monsters returns 0")
	c.check(def15.monsters.size() == 1, "size-2 monster still in play before any tiles broken")
	GameEngine.break_tile(def15.lanes[2].tiles[0])
	c.check(def15.lanes[2].tiles[0].is_broken(), "tile 0 of lane 2 is BROKEN")
	c.check(def15.monsters.size() == 1, "size-2 monster survives with 1 of 2 tiles broken")
	c.check(GameEngine.is_monster_alive(defender15, def15), "size-2 monster is still alive")

	c.section("size-2 monster with both tiles broken is removed")
	var def15b = Player.new()
	var defender15b = Monster.new("DoomedSurvivor", 2, 2, 0, 1, 5)
	c.check(GameEngine.place_monster(def15b, 2, 0, defender15b) == true, "place_monster size-2 in lane 2")
	c.check(def15b.monsters.size() == 1, "size-2 monster in play before tiles broken")
	c.check(GameEngine.remove_dead_monsters(def15b) == 0, "size-2 monster with intact tiles: remove_dead_monsters returns 0")
	c.check(def15b.monsters.size() == 1, "size-2 monster still in play after 0 removals")
	c.check(def15b.lanes[2].tiles[0].state != Tile.State.BROKEN, "tile 0 not broken yet")
	c.check(def15b.lanes[2].tiles[1].state != Tile.State.BROKEN, "tile 1 not broken yet")

	c.section("monster with hp 0 and intact tiles is removed")
	var def15c = Player.new()
	var defender15c = Monster.new("CombatDead", 1, 2, 0, 1, 5)
	c.check(GameEngine.place_monster(def15c, 2, 0, defender15c) == true, "place_monster hp-0 monster")
	c.check(def15c.monsters.size() == 1, "monster in play before hp set to 0")
	c.check(def15c.lanes[2].tiles[0].state != Tile.State.BROKEN, "tile not broken")
	c.check(def15c.lanes[2].tiles[0].state != Tile.State.BURNED, "tile not burned")
	c.check(GameEngine.remove_dead_monsters(def15c) == 0, "remove_dead_monsters returns 0 when tiles intact")
	c.check(def15c.monsters.size() == 1, "monster still in play when tiles intact")

	c.section("two monsters one dead one alive")
	var def15d = Player.new()
	var dead15d = Monster.new("DeadOne", 1, 2, 0, 1, 5)
	var alive15d = Monster.new("AliveOne", 1, 3, 0, 1, 5)
	c.check(GameEngine.place_monster(def15d, 2, 0, dead15d) == true, "place_monster dead one")
	c.check(GameEngine.place_monster(def15d, 3, 0, alive15d) == true, "place_monster alive one")
	c.check(def15d.monsters.size() == 2, "two monsters in play before cleanup")
	c.check(def15d.lanes[2].tiles[0].state != Tile.State.BROKEN, "dead monster tile not broken")
	c.check(def15d.lanes[3].tiles[0].state != Tile.State.BROKEN, "alive monster tile not broken")
	c.check(GameEngine.remove_dead_monsters(def15d) == 0, "remove_dead_monsters returns 0 when both alive")
	c.check(def15d.monsters.size() == 2, "both monsters still in play")

	c.section("BURNED tile under monster does not kill it")
	var def15e = Player.new()
	var defender15e = Monster.new("BurnedTile", 1, 2, 0, 1, 5)
	c.check(GameEngine.place_monster(def15e, 2, 0, defender15e) == true, "place_monster in lane 2")
	c.check(def15e.lanes[2].tiles[0].state != Tile.State.BROKEN, "tile not broken")
	c.check(def15e.lanes[2].tiles[0].state != Tile.State.BURNED, "tile not burned yet")
	c.check(def15e.monsters.size() == 1, "monster in play before tile burned")
	c.check(GameEngine.remove_dead_monsters(def15e) == 0, "remove_dead_monsters returns 0 with intact tile")
	c.check(def15e.monsters.size() == 1, "monster still in play with intact tile")

	c.section("breaking all 16 tiles makes has_lost true")
	var atk16 = Player.new()
	var def16 = Player.new()
	var attacker16 = Monster.new("Sweeper", 1, 0, 0, 1, 100)
	atk16.monsters = [attacker16]
	var all_broken = true
	for lane_idx in range(Constants.LANES_PER_PLAYER):
		for tile_idx in range(Constants.TILES_PER_LANE):
			if not GameEngine.attack_direct(atk16, def16, attacker16, lane_idx, "TILE", tile_idx):
				all_broken = false
			GameEngine.reset_attacks(atk16)
	c.check(all_broken, "all 16 tiles can be broken via repeated direct attacks")
	c.check(GameEngine.has_lost(def16), "has_lost is true when all 16 tiles are broken")

	c.section("GLOBAL: monster dies in combat then direct attack succeeds")
	var atk17 = Player.new()
	var def17 = Player.new()
	var defender17 = Monster.new("DoomedDefender", 1, 0, 0, 1, 1)
	var attacker17 = Monster.new("CombatAtk", 1, 1, 0, 5, 5)
	c.check(GameEngine.place_monster(def17, 0, 0, defender17) == true, "place_monster defender 17")
	c.check(GameEngine.place_monster(atk17, 1, 0, attacker17) == true, "place_monster attacker 17")
	GameEngine.block_rule = Constants.BlockRule.GLOBAL
	c.check(not GameEngine.can_attack_directly(def17, 2), "GLOBAL: direct attack fails while defender has monster")
	c.check(GameEngine.attack_monster(atk17, def17, attacker17, defender17) == true, "attack_monster kills defender monster")
	c.check(def17.monsters.size() == 0, "defender monster removed after combat")
	c.check(GameEngine.can_attack_directly(def17, 2), "GLOBAL: direct attack succeeds after monster dies")
	GameEngine.block_rule = Constants.DEFAULT_BLOCK_RULE