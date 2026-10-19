# Lane Cards: Game Design Draft

*Working title. First-pass ruleset for a 2-4 player isometric card game, built in Godot 4.*

## 1. Core Concept

Every card has two lives: **a lane** (face-down, flipped to reveal a biome) or **a played card** (monster, spell, or trap). Using a card as a lane means giving up its front face. That tension is the heart of the game.

## 2. Setup and Board

- Each player has **4 lanes**, starting as 4 face-down cards drawn from their deck.
- Flipping a lane reveals its **biome** and its **4 sections (tiles)**.
- Monsters, spells, and traps are played into or alongside lanes. Spells and traps can also be set as lanes; they keep their text and trigger when all 4 of that lane's tiles are gone.
- Each player starts at **20 HP**.

## 3. Tile States

Each tile has three states. This makes burn costs and the loss condition work together.

| State | Meaning |
| --- | --- |
| **Ready** | Can use its section effect, or be burned to pay a cost |
| **Burned** | Spent. Cannot be used until restored (cost payments such as "burn 2 Forest tiles" go here) |
| **Broken** | Destroyed permanently. Only an opponent can do this to you |

Burning is a renewable resource, like mana. Breaking is permanent, like life.

**Loss conditions:** you lose when all your tiles are broken, or when your HP reaches 0.

**Tile return:** at upkeep, 1 burned tile returns to Ready. If you control a Volcano or Ocean lane, this return does not happen (see Assumptions for how each replaces it).

## 4. Section Effects

Each lane's 4 sections can be activated once per turn, for example "burn this tile: draw 1" or "burn this tile: break an enemy tile". Section effects come from the biome plus the specific lane card, so the same biome can vary between cards.

## 5. The Six Biomes

| Biome | Identity | Example section effect |
| --- | --- | --- |
| **Plains** | Balanced, reliable | Draw 1, or ready a monster |
| **Desert** | Hoarding, delayed value | Bury up to 4 cards from your deck here. When a Desert tile breaks, take one buried card |
| **Forest** | Growth, defense | Restore a burned tile, or hide a monster from targeting |
| **Volcano** | Aggression, burn-heavy | Burns 1 random Ready tile you own each upkeep; cheap burn costs, strong damage |
| **Ocean** | Mobility, flooding, self-healing | Move a monster between lanes, or return a card to hand. Ocean monsters are typically weak (low ATK/HP) to compensate for the biome's strong non-monster effects. |
| **Ice World** | Control | Freeze a tile or monster so it cannot act next turn |

## 6. Combat

- A monster attacks an **enemy monster if one can be targeted**. If none can, it attacks directly.
- On a successful direct attack, the attacker **chooses**: deal damage to HP, or break a tile in that lane. This creates two paths to victory.
- Bypass keywords for game mechanics:
  - **Flying:** ignores blockers
  - **Tunnel:** hits a tile directly
  - **Pierce:** excess damage carries through
  - **Taunt:** forces attackers to target this monster

**Monster size:** a monster occupies **1 to 4 sections** of one lane. It survives while at least one section holding it is not Broken (a Burned section still holds it). If every section holding it is Broken, the monster is destroyed too.

**Section effects and monsters:** a section's effect can be activated regardless of whether a monster occupies it. A monster on a section does not block that section's effect.

## 7. Costs

Every card has a cost paid in tiles, for example "burn 2 Forest tiles" or "burn 1 Volcano + 1 any". This ties biome choice directly to what you can play, so a deck's lane mix defines its identity.

## 8. Turn Structure (Proposed)

1. **Draw:** draw 1 card
2. **Upkeep:** return 1 burned tile to Ready, unless you control a Volcano or Ocean lane (a Volcano burns 1 random tile; an Ocean floods 1 Broken tile back as an Ocean tile)
3. **Main 1:** flip a lane or play cards, paying costs; use section effects
4. **Attack:** declare attacks
5. **Main 2:** play more cards and use remaining section effects
6. **End:** end-of-turn effects; traps stay set

## 9. Assumptions I Made (Edit Freely)

- **Multiplayer targeting:** you may attack any opponent, and you may target any lane. The "lane N to lane N" pairing is only the default for simultaneous attacks; players are free to target any lane they choose. This keeps 4-player games from becoming a pile-on.
- **Lane replacement:** when all 4 tiles in a lane are broken, the lane collapses and you flip a new face-down card from your deck as a comeback mechanic. A spell or trap lane resolves before it is replaced.
- **Traps:** set face-down in a lane, triggered by conditions, and can count as lane cards.
- **Deck size and hand:** about 40 cards, hand limit of 7. Neutral cards are shuffled into each deck after the opening hand is drawn.
- **Tile restoring:** 1 burned tile returns per upkeep; effects such as Forest can restore more.

* **Volcano or Ocean upkeep:** "in play" means a lane you control. With either, you skip the 1-tile return. A Volcano instead burns 1 random Ready tile of yours; an Ocean floods 1 of your Broken tiles, turning it into an Ocean tile that comes back Burned. This is self-healing, and it works on a Broken section in any of your lanes. The skipped return applies only to the lane's owner, and card effects can bypass it.
* **Monster placement:** a monster fills 1-4 adjacent sections in a single lane.

## 10. Rulings and Open Questions

**Decided:**

- A flooded Ocean tile returns **Burned**, and can be flooded again if it breaks again.
- A Burned section can still hold a monster, as long as at least one of its sections is not Broken.
- A section's effect can be activated regardless of whether a monster occupies it. A monster on a section does not block that section's effect.
- Spells and traps used as lanes keep their text and trigger when all 4 of the lane's tiles are gone. The effect resolves **before** the lane is replaced by a new face-down card.
- Neutral cards exist in every format, from 2 to 4 players. They are shuffled into each deck after the opening hand is drawn.
- A Volcano or Ocean lane stops the tile return only for its owner, and card effects can bypass it.
- Volcano's upkeep burn (1 random Ready tile) is intentional — it is a high-risk, high-reward biome.
- Ocean monsters are typically weak (low ATK/HP) to compensate for the biome's strong non-monster effects.
- Attacks may target any lane; the "lane N to lane N" pairing is only the default for simultaneous attacks.

**Still open:** nothing right now.

## 11. Build Order for Godot

1. Pure-script rules engine (cards, tile states, costs, combat) with no visuals, testable headlessly
2. A 2-player text/debug prototype of the full turn loop
3. Placeholder rectangles for the board with drag-and-drop
4. Isometric board rendering (grid-to-screen math over the same game state)
5. Expand to 3-4 players and AI opponents
6. Networking last

**Tech notes:** use GDScript, keep rules in plain script classes with no scene dependencies, build most scenes in code, and export from the command line with `godot --headless --export-release`. iOS and macOS builds need a Mac with Xcode; Android needs the SDK, a JDK, and a signing keystore.

## 12. Next Steps

- Lock the tile-state and cost rules, since everything depends on them
- Design a first 30-card set around a single biome to test balance
- Build the headless rules engine and write tests for costs and combat
