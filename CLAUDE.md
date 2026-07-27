# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**黎明之诗·改** — A hybrid JRPG (turn-based combat + character raising) × Visual Novel game built in Godot 4.7. The game was ported from a Ren'Py pure-text galgame. Players manage a daily schedule (10 AP/day), train six party members' stats, build relationships, fight turn-based battles, and unlock multiple endings.

Full design document: `2026-07-17-hybrid-rpg-vn-design.md`

## Engine & Versions

- **Godot 4.7** (GL Compatibility renderer, D3D12 on Windows)
- **Dialogic 2** addon (`addons/dialogic/`) for all visual novel sequences
- **GDScript** (`.gd`) only — no C#, no C++ modules

## Commands

```bash
# Launch Godot editor (must have Godot 4.7+ on PATH)
godot --editor

# Run the game directly (splash screen → main menu → gameplay)
godot --path .

# Run a specific scene for testing
godot --path . "res://scenes/menu/splash.tscn"

# Note: There is no CI, no linting, and no automated tests.
# Game state resets on "New Game" via GameState.reset() / PartyData.reset() / StoryFlags.clear_all()
```

## Architecture: Three-Phase Game Loop

The game runs through three phases, managed by `GameState.game_phase`:

```
vn       → Dialogic timelines play (story, dialogues, social scenes)
schedule → ScheduleHub scene (daily actions: train, social, explore, rest)
battle   → CombatArena scene (turn-based 3vN combat)
```

`scenes/MainScene.gd` listens to `GameState.game_phase_changed` and instantiates/shows the correct scene. The initial entry point is `scenes/menu/splash.tscn` → `MainMenu` → `main.tscn` (MainScene).

### Scene Flow

```
Splash → MainMenu (title screen) → MainScene (phase manager)
                                        ├── loads/plays Dialogic timelines
                                        ├── instantiates ScheduleHub
                                        └── instantiates CombatArena
```

## Autoloads (Global Singletons)

Defined in `project.godot` → `[autoload]`. Available everywhere as globals.

| Autoload | File | Responsibility |
|----------|------|----------------|
| `GameState` | `autoload/GameState.gd` | Chapter, day, AP, time period, game phase, death count, character recruitment, daily talk limits, special battle tracking, serialize/deserialize |
| `PartyData` | `autoload/PartyData.gd` | Loads character templates from `resources/characters/*.tres`, loads skills from `resources/skills/*.tres`, loads enemies from `scenes/battle/enemies/*.tres`, loads encounters from `scenes/battle/encounters/*.tres`. Manages `CharacterData` inner class with XP/leveling. Provides `get_character()`, `get_skill()`, `get_enemy()`, `get_encounter()` |
| `StoryFlags` | `autoload/StoryFlags.gd` | Boolean flags, affection, choice history, ending/CG unlock tracking, serialize/deserialize |
| `SaveManager` | `autoload/SaveManager.gd` | Serializes GameState + PartyData + StoryFlags to JSON at `user://saves/save_N.sav`. 20 slots. Also provides slot info for UI |
| `ImageUtils` | `autoload/ImageUtils.gd` | Texture loading with automatic resize/crop via `load_texture()`, `load_portrait()`, `load_icon()` |
| `DialogicBridge` | `autoload/DialogicBridge.gd` | Bridges game state ↔ Dialogic variables. Registers character aliases. Syncs stats/affection/AP to Dialogic VAR subsystem. Handles save/load/skip hotkeys during VN. Listens to PartyData/GameState signals for real-time variable push |

## Data Architecture

### Characters (`resources/characters/`)
- `character_template.gd` — `CharacterTemplate` Resource class with `char_id`, `char_name`, `base_stats`, `growth_rates`, `skill_pool`, `portrait_path`
- Each character is a `.tres` file (e.g., `hajiyou.tres`, `chenli.tres`)
- `PartyData` scans the directory and instantiates `CharacterData` objects at runtime

### Skills (`resources/skills/`)
- `skill_data.gd` — `SkillData` Resource class with `skill_id`, `skill_name`, `skill_type` (damage/heal/buff/debuff/special), `target_type`, `power`, `stat_scale`, `hit_count`
- Skills are `.tres` files; loaded by PartyData into a registry
- `ActionFactory.from_skill_data()` converts SkillData → BattlerAction for combat

### Enemies & Encounters (`scenes/battle/`)
- `enemies/EnemyTemplate.gd` — enemy stat templates as `.tres`
- `encounters/EncounterData.gd` — defines enemy groups per battle type; `.tres` files in `encounters/`
- `PartyData` loads both and provides `get_enemy()` / `get_encounter()`

### Save System
Dual-save approach:
1. **SaveManager** (game state): JSON files with full GameState + PartyData + StoryFlags serialization
2. **Dialogic.Save** (VN position): Dialogic's built-in save, stores timeline position + dialogic variables; extra metadata (date, chapter, day) passed via `extra` dict

Both must be saved/loaded together for correct restore. The `quick_menu_layer.gd` and `ScheduleHub.gd` both coordinate the dual save.

## Battle System (`scenes/battle/`)

```
CombatArena.gd (arena controller)
├── ActiveTurnQueue.gd (turn ordering by AGI, readiness)
├── BattlerList.gd (player/enemy battler registry)
├── Battler.gd / BattlerStats.gd (unit data + HP/stat modifiers)
├── actions/
│   ├── BattlerAction.gd (base action class, target scoping)
│   ├── AttackBattlerAction.gd, HealBattlerAction.gd,
│   │   ModifyStatsBattlerAction.gd, SpecialBattlerAction.gd
│   └── ActionFactory.gd (creates actions from SkillData)
└── ui/
    ├── action_menu/ (player action selection)
    ├── targeting/ (cursor for enemy selection)
    ├── turn_bar/ (AGI-order display)
    ├── player_panel/ (party HP display)
    └── effects/ (damage/heal/miss labels)
```

- BattlerStats maps the six-dimension stats (STR→ATK, MAG→MAG_ATK, VIT→HP+DEF, AGI→Speed, TEC→Hit, CHA→unused in combat)
- Guard/defend reduces damage; buffs use the modifier system on BattlerStats
- Special battles on days divisible by 5 fire `special_battles.dtl` timelines before/after combat

## Dialogic Integration

- **Dialogic 2** is the visual novel engine. Timelines (`.dtl`) define dialogue, character joins/leaves, backgrounds, choices, and conditional branches
- Timelines live in `resources/dialogic/timelines/`:
  - `prologue.dtl` — game intro (label: `prologue_dream`)
  - `social.dtl` — character social link scenes
  - `special_battles.dtl` — special battle story (pre/post battle)
  - `battle_results.dtl` — post-battle results scenes
- Characters are defined as `.dch` files in `resources/dialogic/characters/` and `resources/characters/`
- Dialogic variables (defined in `project.godot` → `[dialogic] variables`) are synced from GameState/PartyData by DialogicBridge
- `@tool` scripts like `quick_menu_layer.gd` extend `DialogicLayoutLayer` to add custom in-VN UI

## Key Patterns

### UI Construction
Most UI is built procedurally in GDScript (not through `.tscn` scene files). Look for:
- `CanvasLayer` root nodes with `Control` children
- `_create_overlay(title)` → returns a content Control to populate
- `_flat_stylebox(color)` / `_make_button_style(color)` for styled buttons
- `_show_toast(msg)` for temporary status messages
- Tween-based fade transitions (modulate.a 0→1 or 1→0)

### Phase Transitions
`MainScene._fade_transition(action)` wraps phase switches in a black fade: fade to black → execute action → fade back in. The `_transition_lock` flag prevents re-entrant switches.

### Character Recruitment
Characters unlock over time: protagonist + 哈基佑 start unlocked; 陈立 at day 5, 老马 at day 10, 牢翔 at day 15, 牢聪 after day 20 boss. `GameState.recruit_character()` emits `character_recruited` which ScheduleHub listens to for refreshing its character grid.

## Key Files to Know

| File | Why |
|------|-----|
| `project.godot` | Autoloads, Dialogic config, input map, display settings |
| `scenes/MainScene.gd` | Central phase manager — the glue between VN/schedule/battle |
| `autoload/GameState.gd` | All top-level game state; modify carefully |
| `autoload/PartyData.gd` | All character/skill/enemy data loading and queries |
| `autoload/DialogicBridge.gd` | Game↔Dialogic variable sync; read when working on VN integration |
| `scenes/battle/battler/BattlerStats.gd` | Six-stat→combat-stat mapping and modifier system |
| `2026-07-17-hybrid-rpg-vn-design.md` | Complete game design — character kits, ending conditions, skill mechanics |

## Directory Notes

- `old/` contains the original Ren'Py `.rpy` script files (the source material before the Godot port)
- `images/cg/` — CG gallery images; auto-discovered by filename at runtime
- `addons/dialogic/` — the Dialogic 2 plugin; do not modify directly
- `.godot/` — editor cache and import files; in `.gitignore`
- The `scripts/` and `docs/` directories are empty/legacy
