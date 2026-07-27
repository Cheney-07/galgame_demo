# Task 6: 战斗容器 — CombatArena + 完整战斗循环

## Status: Complete

## Files Created

### 1. `E:/gamedemo1/scenes/battle/arena/CombatArena.gd`
- **class_name** `CombatArena extends Control`
- **signal** `combat_finished(result: Dictionary)`
- **Key method** `start(squad: Array[String], encounter: EncounterData)` — main entry point that:
  - Loads background texture from `encounter.background_path`
  - Creates player `Battler` nodes via `_create_player_battler()` (reads from `PartyData`, loads sprite/icon/skills)
  - Creates enemy `Battler` nodes via `_create_enemy_battler()` (reads from `EnemyTemplate`, loads sprite/icon/skills)
  - Sets up `BattlerList` and `ActiveTurnQueue`
  - Connects all signals (`player_needs_input`, `action_executed`, `battle_ended`)
  - Initializes `UITurnBar` and `UIPlayerBattlerList`
  - Starts the battle loop by fading in UI and setting `turn_queue.is_active = true`
- **Player input flow:** Menu action selected → targeting cursor (if needed) → `turn_queue.submit_player_action()`
- **Action execution:** Spawns `UIDamageLabel` at target positions for damage/heal/miss
- **Battle end:** Victory → EXP distribution → Dialogic aftermath timeline; Defeat → `GameState.record_death()` → schedule phase

### 2. `E:/gamedemo1/scenes/battle/arena/CombatArena.tscn`
- `Control` node (CombatArena) with:
  - `Background` (TextureRect, full screen)
  - `BattlerContainer` (Node2D)
  - `UI` (CanvasLayer) containing:
    - `TurnBar` (instance of UITurnBar.tscn)
    - `PlayerList` (instance of UIPlayerBattlerList.tscn)
    - `ActionMenuAnchor` (Control, positioned bottom-center)
    - `CursorAnchor` (Control, full-screen, mouse_filter=2)
    - `DamageContainer` (Control, full-screen, mouse_filter=2)

### 3. `E:/gamedemo1/scenes/battle/battle_main.tscn`
- `CanvasLayer` root with a child `Arena` (Control) that has `CombatArena.gd` script attached.

## Verification
- Godot engine is not installed on this system, so `--check-only` could not be run.
- All three files were created matching the specifications in the task brief.
- A `.uid` file was auto-generated for CombatArena.gd by the Godot file system.
- All dependencies (Battler, BattlerStats, BattlerList, ActiveTurnQueue, ActionFactory, UIActionMenu, UIBattlerTargetingCursor, UIDamageLabel, UITurnBar, UIPlayerBattlerList, PartyData, GameState, DialogicBridge) exist in the project with the expected APIs.

## Dependencies Consumed
- `BattlerStats` — stats initialization from character/enemy data
- `Battler` — battler node creation, setup_stats, position management
- `BattlerList` — battler grouping and alive/dead queries
- `ActiveTurnQueue` — turn management, signal emission
- `ActionFactory` — skill-to-action conversion, basic attack/defend creation
- `UIActionMenu` — player action selection UI
- `UIBattlerTargetingCursor` — target selection UI
- `UIDamageLabel` — damage/heal/miss floating text
- `UITurnBar` — turn order visualization
- `UIPlayerBattlerList` — player party status panel
- `PartyData` — character/skill/enemy/encounter data access
- `GameState` — game phase, death recording, battle type
- `DialogicBridge` — post-battle dialog timeline
