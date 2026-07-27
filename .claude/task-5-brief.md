### Task 5: UI 组件 — 行动部分（ActionMenu + TargetingCursor + DamageLabel）

**Files:**
- Create: `scenes/battle/ui/action_menu/UIActionButton.gd`
- Create: `scenes/battle/ui/action_menu/UIActionButton.tscn`
- Create: `scenes/battle/ui/action_menu/UIActionMenu.gd`
- Create: `scenes/battle/ui/action_menu/UIActionMenu.tscn`
- Create: `scenes/battle/ui/targeting/UIBattlerTargetingCursor.gd`
- Create: `scenes/battle/ui/targeting/UIBattlerTargetingCursor.tscn`
- Create: `scenes/battle/ui/effects/UIDamageLabel.gd`
- Create: `scenes/battle/ui/effects/UIDamageLabel.tscn`

- [ ] **Step 1: Create UIActionButton**

```gdscript
# scenes/battle/ui/action_menu/UIActionButton.gd
class_name UIActionButton extends Button

var action_ref: BattlerAction:
    set(value):
        action_ref = value
        if action_ref:
            text = action_ref.action_name
            tooltip_text = action_ref.description
```

```ini
# scenes/battle/ui/action_menu/UIActionButton.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/action_menu/UIActionButton.gd" id="1"]

[node name="UIActionButton" type="Button"]
custom_minimum_size = Vector2(120, 50)
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(1, 1, 1)
script = ExtResource("1")
```

- [ ] **Step 2: Create UIActionMenu**

```gdscript
# scenes/battle/ui/action_menu/UIActionMenu.gd
class_name UIActionMenu extends Control

signal action_selected(action: BattlerAction)
signal menu_closed()

const BTN_SCENE := preload("res://scenes/battle/ui/action_menu/UIActionButton.tscn")

func setup(battler) -> void:
    var hbox := HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 10)
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    add_child(hbox)

    # 攻击按钮
    var atk_btn := BTN_SCENE.instantiate()
    atk_btn.action_ref = battler.get_basic_attack()
    atk_btn.pressed.connect(func():
        _select_action(atk_btn.action_ref)
    )
    hbox.add_child(atk_btn)

    # 技能按钮
    for a in battler.actions:
        if a != battler.get_basic_attack():
            var btn := BTN_SCENE.instantiate()
            btn.action_ref = a
            btn.pressed.connect(func():
                _select_action(btn.action_ref)
            )
            hbox.add_child(btn)

    # 防御按钮
    var def_btn := BTN_SCENE.instantiate()
    def_btn.text = "防御"
    def_btn.tooltip_text = "本回合伤害减半"
    def_btn.pressed.connect(func():
        _select_action(ActionFactory.create_defend())
    )
    hbox.add_child(def_btn)

    fade_in()

func fade_in() -> void:
    modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)

func fade_out() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.15)
    await tween.finished
    queue_free()

func _select_action(action: BattlerAction) -> void:
    action_selected.emit(action)
```

```ini
# scenes/battle/ui/action_menu/UIActionMenu.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/action_menu/UIActionMenu.gd" id="1"]

[node name="UIActionMenu" type="Control"]
anchors_preset = 0
offset_left = 200.0
offset_right = 1720.0
offset_top = 880.0
offset_bottom = 950.0
mouse_filter = 2
script = ExtResource("1")
```

- [ ] **Step 3: Create UIBattlerTargetingCursor**

```gdscript
# scenes/battle/ui/targeting/UIBattlerTargetingCursor.gd
class_name UIBattlerTargetingCursor extends Control

signal target_selected(target)
signal cancelled()

var _battler_positions := {}  # Battler → position on screen

func setup(possible_targets: Array, all_battlers: Array, turn_queue: ActiveTurnQueue) -> void:
    for t in possible_targets:
        if t.stats.health <= 0:
            continue

        # 创建可点击区域
        var btn := Button.new()
        btn.text = t.display_name
        btn.custom_minimum_size = Vector2(120, 40)
        # 把按钮放在 battler 位置附近
        if t.is_player:
            btn.position = t.position + Vector2(-60, -80)
        else:
            btn.position = t.position + Vector2(-60, 40)
        btn.add_theme_stylebox_override("normal", _make_highlight_style())
        btn.pressed.connect(func():
            target_selected.emit(t)
        )
        add_child(btn)

    # 取消按钮
    var cancel := Button.new()
    cancel.text = "取消"
    cancel.position = Vector2(800, 920)
    cancel.pressed.connect(func():
        cancelled.emit()
    )
    add_child(cancel)

func _make_highlight_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.2, 0.6, 1.0, 0.4)
    s.set_corner_radius_all(6)
    return s
```

```ini
# scenes/battle/ui/targeting/UIBattlerTargetingCursor.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/targeting/UIBattlerTargetingCursor.gd" id="1"]

[node name="UIBattlerTargetingCursor" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 1
script = ExtResource("1")
```

- [ ] **Step 4: Create UIDamageLabel**

```gdscript
# scenes/battle/ui/effects/UIDamageLabel.gd
class_name UIDamageLabel extends Label

func show_damage(amount: int, is_crit: bool) -> void:
    text = "-" + str(amount)
    if is_crit:
        text += " 暴击!"
        add_theme_color_override("font_color", Color(1, 0.6, 0))
        add_theme_font_size_override("font_size", 20)
    else:
        add_theme_color_override("font_color", Color(1, 0.3, 0.3))
        add_theme_font_size_override("font_size", 16)
    _animate()

func show_heal(amount: int) -> void:
    text = "+" + str(amount)
    add_theme_color_override("font_color", Color(0.3, 1, 0.3))
    add_theme_font_size_override("font_size", 16)
    _animate()

func show_miss() -> void:
    text = "MISS!"
    add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    add_theme_font_size_override("font_size", 14)
    _animate()

func _animate() -> void:
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position", position + Vector2(0, -40), 1.0)
    tween.tween_property(self, "modulate:a", 0.0, 1.0)
    await tween.finished
    queue_free()
```

```ini
# scenes/battle/ui/effects/UIDamageLabel.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/effects/UIDamageLabel.gd" id="1"]

[node name="UIDamageLabel" type="Label"]
horizontal_alignment = 1
vertical_alignment = 1
script = ExtResource("1")
```

---

