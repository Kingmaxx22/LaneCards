# AGENTS.md — Lane Cards

A 2-4 player isometric card game built in Godot 4 with GDScript. This file is for AI agents and future maintainers.

## Project Overview

Every card has two lives: a **lane** (face-down, flipped to reveal a biome) or a **played card** (monster, spell, or trap). Using a card as a lane means giving up its front face. That tension is the heart of the game.

## Tech Stack

- **Engine:** Godot 4.7.2
- **Language:** GDScript (pure scripts, no scenes for rules)
- **Testing:** Headless via `Godot_v4.7.2-stable_win64_console.exe --headless --script`
- **Platform:** Windows (MSYS bash terminal)

## Project Structure

```
LaneCards/
├── project.godot              # Minimal config, no main scene
├── .gitattributes             # * text=auto eol=lf
├── run_tests.sh               # Bash test runner (30s timeout)
├── run_tests.ps1              # PowerShell test runner (alternative)
├── rules/
│   ├── constants.gd           # Tunable numbers, BlockRule enum
│   ├── tile.gd                # Tile (READY/BURNED/BROKEN, Biome)
│   ├── lane.gd                # Lane (FACE_DOWN/FLIPPED, 4 tiles, card ref)
│   ├── player.gd              # Player (4 lanes, HP, deck, trigger_log)
│   ├── card.gd                # Card (MONSTER/SPELL/TRAP, biome, effect_id)
│   ├── cost.gd                # Cost ({biome: count, any: count})
│   ├── monster.gd            # Monster (size 1-4, atk, hp, has_attacked)
│   ├── engine.gd              # GameEngine (static combat/cost/tile functions)
│   └── lanes.gd               # LaneRules (flip_lane, break_tile_and_cleanup)
├── tests/
│   ├── checker.gd             # Checker helper (pass/fail counters)
│   ├── test_stage1.gd         # Tile states, upkeep, has_lost
│   ├── test_stage2.gd         # Costs, monster placement/survival
│   ├── test_stage3.gd         # Combat, block rules, direct attacks
│   ├── test_stage4.gd         # Lane flipping, collapse, triggers
│   └── test_runner.gd         # SceneTree entry point, runs all stages
└── LaneCardsGameDesignDraft.md # Design document
```

## Running Tests

```bash
# Re-import (required after adding new class_name files)
./Godot_v4.7.2-stable_win64_console.exe --headless --import --path .

# Syntax check a single file
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --check-only --script res://path/to/file.gd

# Run full test suite (30s timeout)
bash run_tests.sh
```

## Architecture Rules

- **Rules are pure GDScript** — `extends RefCounted`, no Node/scene dependencies
- **All game logic is static** on `GameEngine` or `LaneRules` — call as `ClassName.function()`
- **No global functions** — always use class prefix
- **No `assert`** — reserved keyword; use `Checker.check()` instead
- **No Dictionary method calls** — `t.print()` doesn't work; use a class like `Checker`
- **SceneTree entry point** — use `_initialize()`, NOT `_init()`
- **Backward compatibility** — `Player.new()` gives 4 FLIPPED PLAINS lanes with 16 READY tiles

## Test Conventions

- Each stage has its own test file: `tests/test_stageN.gd`
- Test class pattern: `extends RefCounted`, `class_name TestStageN`, `func run(c: Checker)`
- All tests run through `tests/test_runner.gd` which creates one `Checker` and passes to each stage
- Earlier stages' tests must keep passing as new stages are added

## What Each Stage Built

| Stage | What | Key Files |
|-------|------|-----------|
| 1 | Tile states, upkeep, loss conditions | tile.gd, lane.gd, player.gd, engine.gd |
| 2 | Costs, monster placement/survival | cost.gd, monster.gd |
| 3 | Combat, block rules, direct attacks, remove_dead_monsters | engine.gd (updated) |
| 4 | Lane flipping, collapse, spell/trap triggers, replacement | card.gd, lanes.gd, engine.gd (updated) |

## Key Design Decisions

- **Burn = mana, Break = life.** Burning tiles is renewable (upkeep returns 1/turn). Breaking is permanent.
- **Monster size** — 1 to 4 adjacent sections in one lane. Dies when ALL its sections are BROKEN.
- **Block rules** — LANE (default): direct attack only on empty lanes. GLOBAL: direct attack only if defender has NO monsters.
- **Lane collapse** — all 4 tiles BROKEN → monsters removed → SPELL/TRAP effect logged → replacement from deck (FACE_DOWN) or lost_by_deck if empty.
- **Flip cost** — 1 READY tile burned, unless player has 0 READY tiles (free flip exception).
