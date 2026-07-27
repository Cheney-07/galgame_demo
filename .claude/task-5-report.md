# Task 5 Report — Action Menu, Targeting Cursor, Damage Label

## Status

All components created and verified.

## Files created (8 files, 4 GDScript + 4 TSCN)

| # | Component | Files | Paths |
|---|-----------|-------|-------|
| 1 | UIActionButton | .gd + .tscn | `scenes/battle/ui/action_menu/UIActionButton.gd` |
|   |               |       | `scenes/battle/ui/action_menu/UIActionButton.tscn` |
| 2 | UIActionMenu   | .gd + .tscn | `scenes/battle/ui/action_menu/UIActionMenu.gd` |
|   |               |       | `scenes/battle/ui/action_menu/UIActionMenu.tscn` |
| 3 | UIBattlerTargetingCursor | .gd + .tscn | `scenes/battle/ui/targeting/UIBattlerTargetingCursor.gd` |
|   |                         |       | `scenes/battle/ui/targeting/UIBattlerTargetingCursor.tscn` |
| 4 | UIDamageLabel  | .gd + .tscn | `scenes/battle/ui/effects/UIDamageLabel.gd` |
|   |               |       | `scenes/battle/ui/effects/UIDamageLabel.tscn` |

## Component details

- **UIActionButton**: Extends Button. `action_ref` setter updates `text` and `tooltip_text` from the assigned `BattlerAction`. Scene configured with `custom_minimum_size = Vector2(120, 50)`, font_size 16, white font color.

- **UIActionMenu**: Extends Control. `setup(battler)` builds an HBoxContainer with basic attack button, per-skill buttons (excluding basic attack), and a defend button. Signals: `action_selected(action)` and `menu_closed`. Animation: `fade_in()` (alpha 0→1 over 0.2s), `fade_out()` (alpha 1→0 over 0.15s then queue_free).

- **UIBattlerTargetingCursor**: Extends Control, full-screen anchor preset. `setup(possible_targets, all_battlers, turn_queue)` creates clickable buttons at battler positions (players offset -80 above, enemies +40 below) with blue semi-transparent highlight style (`Color(0.2, 0.6, 1.0, 0.4)`), plus a cancel button at bottom center. Signals: `target_selected(target)` and `cancelled()`.

- **UIDamageLabel**: Extends Label. `show_damage(amount, is_crit)` — red text, orange for crit with " 暴击!" suffix and larger font. `show_heal(amount)` — green text with "+" prefix. `show_miss()` — gray "MISS!". Animation: upward float by 40px and fade over 1 second, then queue_free.

## Verification

- Project runs in Godot 4.7.1.stable without any new errors.
- All `.tscn` scenes correctly reference their GDScript via `ExtResource`.
- All `class_name` declarations match the brief.
- All signal names match the brief (`action_selected`, `menu_closed`, `target_selected`, `cancelled`).
- Consumed interfaces (Battler, BattlerAction, ActionFactory, ActiveTurnQueue, BattlerStats) all exist in the project.

## Concerns

None. All files match the brief exactly.
