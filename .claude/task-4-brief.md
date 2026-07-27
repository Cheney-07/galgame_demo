### Task 4: UI 组件 — 核心三件套（TurnBar + PlayerBattlerList + Entry）

**Files:**
- Create: `scenes/battle/ui/turn_bar/UITurnBar.gd`
- Create: `scenes/battle/ui/turn_bar/UITurnBar.tscn`
- Create: `scenes/battle/ui/turn_bar/UIBattlerIcon.gd`
- Create: `scenes/battle/ui/turn_bar/UIBattlerIcon.tscn`
- Create: `scenes/battle/ui/player_panel/UIPlayerBattlerList.gd`
- Create: `scenes/battle/ui/player_panel/UIPlayerBattlerList.tscn`
- Create: `scenes/battle/ui/player_panel/UIBattlerEntry.gd`
- Create: `scenes/battle/ui/player_panel/UIBattlerEntry.tscn`

- [ ] **Step 1: Create UIBattlerIcon.gd + .tscn**

```gdscript
# scenes/battle/ui/turn_bar/UIBattlerIcon.gd
class_name UIBattlerIcon extends TextureRect

var battler_ref                 # 弱引用对应的 Battler
var position_range := Vector2.ZERO  # x 轴移动范围

var progress := 0.0:
    set(value):
        progress = clampf(value, 0.0, 1.0)
        position.x = lerpf(position_range.x, position_range.y, progress)

func setup(battler, range_val: Vector2) -> void:
    battler_ref = battler
    position_range = range_val
    texture = battler.icon_texture
    modulate = Color(0.5, 0.5, 1.0) if battler.is_player else Color(1.0, 0.5, 0.5)

func fade_out() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.5)
    tween.tween_callback(queue_free)
```

```ini
# scenes/battle/ui/turn_bar/UIBattlerIcon.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/turn_bar/UIBattlerIcon.gd" id="1"]

[node name="UIBattlerIcon" type="TextureRect"]
custom_minimum_size = Vector2(48, 48)
expand_mode = 1
stretch_mode = 5
script = ExtResource("1")
```

- [ ] **Step 2: Create UITurnBar.gd + .tscn**

```gdscript
# scenes/battle/ui/turn_bar/UITurnBar.gd
class_name UITurnBar extends Control

const ICON_SCENE := preload("res://scenes/battle/ui/turn_bar/UIBattlerIcon.tscn")

@onready var background := $Background as TextureRect
@onready var icons_container := $Background/Icons as Control

var _icons := []  # UIBattlerIcon 列表

func setup(battler_list: BattlerList) -> void:
    for b in battler_list.get_all_battlers():
        var icon := ICON_SCENE.instantiate()
        icon.custom_minimum_size = Vector2(48, 48)
        icon.size = Vector2(48, 48)

        var range_x := Vector2(icon.size.x / 2.0, background.size.x - icon.size.x / 2.0)
        icon.setup(b, range_x)
        icon.progress = 0.0

        # 连接 readiness 变化
        b.readiness_changed.connect(func(val: float):
            if is_instance_valid(icon):
                icon.progress = val / 100.0
        )
        b.stats.health_depleted.connect(icon.fade_out)

        icons_container.add_child(icon)
        _icons.append(icon)

func fade_in() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)
    modulate.a = 0.0

func fade_out() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
```

```ini
# scenes/battle/ui/turn_bar/UITurnBar.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/turn_bar/UITurnBar.gd" id="1"]

[node name="UITurnBar" type="Control"]
anchors_preset = 0
offset_left = 100.0
offset_right = 1820.0
offset_top = 10.0
offset_bottom = 70.0
script = ExtResource("1")

[node name="Background" type="TextureRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 0.4)
expand_mode = 1

[node name="Icons" type="Control" parent="Background"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
```

- [ ] **Step 3: Create UIBattlerEntry.gd + .tscn**

```gdscript
# scenes/battle/ui/player_panel/UIBattlerEntry.gd
class_name UIBattlerEntry extends Control

@onready var name_label := $NameLabel as Label
@onready var hp_bar_bg := $HPBarBg as ColorRect
@onready var hp_bar_fg := $HPBarFg as ColorRect
@onready var hp_label := $HPLabel as Label
@onready var icon := $Icon as TextureRect

func setup(battler) -> void:
    name_label.text = battler.display_name
    icon.texture = battler.icon_texture

    # 连接 HP 变化
    battler.stats.health_changed.connect(func():
        _update_hp(battler)
    )
    _update_hp(battler)

func _update_hp(battler) -> void:
    var pct := clampf(float(battler.stats.health) / float(battler.stats.max_health), 0.0, 1.0)
    hp_bar_fg.custom_minimum_size.x = hp_bar_bg.size.x * pct
    hp_label.text = str(battler.stats.health) + "/" + str(battler.stats.max_health)

    if pct < 0.25:
        hp_bar_fg.color = Color(0.9, 0.2, 0.2)
    elif pct < 0.5:
        hp_bar_fg.color = Color(0.9, 0.7, 0.2)
    else:
        hp_bar_fg.color = Color(0.2, 0.9, 0.2)
```

```ini
# scenes/battle/ui/player_panel/UIBattlerEntry.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/player_panel/UIBattlerEntry.gd" id="1"]

[node name="UIBattlerEntry" type="Control"]
custom_minimum_size = Vector2(200, 60)
script = ExtResource("1")

[node name="Icon" type="TextureRect" parent="."]
offset_left = 5
offset_top = 5
offset_right = 50
offset_bottom = 55
expand_mode = 1
stretch_mode = 5

[node name="NameLabel" type="Label" parent="."]
offset_left = 55
offset_top = 5
offset_right = 195
offset_bottom = 25
theme_override_colors/font_color = Color(1, 1, 1)

[node name="HPBarBg" type="ColorRect" parent="."]
offset_left = 55
offset_top = 28
offset_right = 195
offset_bottom = 42
color = Color(0.3, 0.1, 0.1)

[node name="HPBarFg" type="ColorRect" parent="HPBarBg"]
offset_right = 140
offset_bottom = 14
color = Color(0.2, 0.9, 0.2)

[node name="HPLabel" type="Label" parent="."]
offset_left = 55
offset_top = 42
offset_right = 195
offset_bottom = 58
theme_override_colors/font_color = Color(0.8, 0.8, 0.8)
theme_override_font_sizes/font_size = 12
```

- [ ] **Step 4: Create UIPlayerBattlerList.gd + .tscn**

```gdscript
# scenes/battle/ui/player_panel/UIPlayerBattlerList.gd
class_name UIPlayerBattlerList extends Control

const ENTRY_SCENE := preload("res://scenes/battle/ui/player_panel/UIBattlerEntry.tscn")

func setup(battler_list: BattlerList) -> void:
    var idx := 0
    for p in battler_list.players:
        var entry := ENTRY_SCENE.instantiate()
        entry.position = Vector2(0, idx * 70)
        entry.setup(p)
        add_child(entry)
        idx += 1

func fade_out() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
```

```ini
# scenes/battle/ui/player_panel/UIPlayerBattlerList.tscn
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/ui/player_panel/UIPlayerBattlerList.gd" id="1"]

[node name="UIPlayerBattlerList" type="Control"]
offset_left = 10
offset_top = 100
offset_right = 210
offset_bottom = 500
script = ExtResource("1")
```

---

