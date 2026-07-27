### Task 6: 战斗容器 — CombatArena + 完整战斗循环

**Files:**
- Create: `scenes/battle/arena/CombatArena.gd`
- Create: `scenes/battle/arena/CombatArena.tscn`
- Create: `scenes/battle/battle_main.tscn`

- [ ] **Step 1: Create CombatArena.gd**

```gdscript
# scenes/battle/arena/CombatArena.gd
class_name CombatArena extends Control

signal combat_finished(result: Dictionary)

var turn_queue: ActiveTurnQueue = null
var battler_list: BattlerList = null
var _player_battlers: Array = []
var _enemy_battlers: Array = []
var _current_input_battler = null

@onready var background := $Background as TextureRect
@onready var battler_container := $BattlerContainer as Node2D
@onready var ui_turn_bar := $UI/TurnBar as UITurnBar
@onready var ui_player_list := $UI/PlayerList as UIPlayerBattlerList
@onready var ui_action_menu_anchor := $UI/ActionMenuAnchor as Control
@onready var ui_cursor_anchor := $UI/CursorAnchor as Control
@onready var ui_damage_container := $UI/DamageContainer as Control

func start(squad: Array[String], encounter: EncounterData) -> void:
    # 设置背景
    var bg_tex := load(encounter.background_path) if ResourceLoader.exists(encounter.background_path) else null
    if bg_tex:
        background.texture = bg_tex

    # 创建玩家 battler
    _player_battlers.clear()
    var char_ids := squad.duplicate()
    if char_ids.is_empty():
        char_ids = PartyData.get_all_character_ids()
        char_ids = char_ids.slice(0, 3)

    for i in char_ids.size():
        var char_data := PartyData.get_character(char_ids[i])
        if char_data == null:
            continue
        var battler := _create_player_battler(char_data)
        battler.position = Vector2(150, 250 + i * 180)
        battler_container.add_child(battler)
        _player_battlers.append(battler)

    # 创建敌人 battler
    _enemy_battlers.clear()
    for j in encounter.enemy_ids.size():
        var eid := encounter.enemy_ids[j]
        var count := encounter.enemy_counts[j] if j < encounter.enemy_counts.size() else 1
        var template := PartyData.get_enemy(eid)
        if template == null:
            continue
        for k in count:
            var battler := _create_enemy_battler(template)
            var cols := min(count, 3)
            var row := int(k / 3)
            var col := k % 3
            battler.position = Vector2(1400 + col * 180, 200 + row * 180 + j * 60)
            battler_container.add_child(battler)
            _enemy_battlers.append(battler)

    # 创建 BattlerList
    battler_list = BattlerList.new(_player_battlers, _enemy_battlers)

    # 设置 TurnQueue
    turn_queue = ActiveTurnQueue.new()
    add_child(turn_queue)
    turn_queue.setup(battler_list)

    # 连接信号
    turn_queue.player_needs_input.connect(_on_player_needs_input)
    turn_queue.action_executed.connect(_on_action_executed)
    turn_queue.battle_ended.connect(_on_battle_ended)

    # 设置 UI
    ui_turn_bar.setup(battler_list)
    ui_player_list.setup(battler_list)

    # 启动战斗
    ui_turn_bar.fade_in()
    turn_queue.is_active = true

func _create_player_battler(char_data) -> Battler:
    var battler := preload("res://scenes/battle/battler/Battler.tscn").instantiate()
    var stats := BattlerStats.new()
    stats.init_from_character(char_data)
    battler.setup_stats(stats)
    battler.is_player = true
    battler.char_id = char_data.char_id
    battler.display_name = char_data.char_name

    # 设置 sprite
    var sprite_path := "res://images/battle/sprites/" + char_data.char_id + ".png"
    if ResourceLoader.exists(sprite_path):
        battler.sprite = Sprite2D.new()
        battler.sprite.texture = load(sprite_path)
        battler.sprite.scale = Vector2(0.5, 0.5)
        battler.add_child(battler.sprite)
    # 设置 icon
    var icon_path := "res://images/battle/icons/" + char_data.char_id + ".png"
    if ResourceLoader.exists(icon_path):
        battler.icon_texture = load(icon_path)

    # 加载技能
    var has_attack := false
    for sid in char_data.skill_pool:
        var skill_res := PartyData.get_skill(sid)
        if skill_res:
            var action := ActionFactory.from_skill_data(skill_res)
            if action:
                battler.actions.append(action)
        if sid == "weapon_attack":
            has_attack = true
    if not has_attack:
        battler.actions.append(ActionFactory.create_basic_attack())

    return battler

func _create_enemy_battler(template: EnemyTemplate) -> Battler:
    var battler := preload("res://scenes/battle/battler/Battler.tscn").instantiate()
    var stats := BattlerStats.new()
    stats.init_from_enemy(template)
    battler.setup_stats(stats)
    battler.is_player = false
    battler.char_id = template.enemy_id
    battler.display_name = template.enemy_name
    battler.set_meta("exp_reward", template.exp_reward)
    battler.set_meta("gold_reward", template.gold_reward)

    var sprite_path := template.sprite_path
    if sprite_path.is_empty():
        sprite_path = "res://images/battle/sprites/" + template.enemy_id + ".png"
    if ResourceLoader.exists(sprite_path) and not sprite_path.is_empty():
        battler.sprite = Sprite2D.new()
        battler.sprite.texture = load(sprite_path)
        battler.sprite.scale = Vector2(0.5, 0.5)
        battler.add_child(battler.sprite)

    var icon_path := template.icon_path
    if icon_path.is_empty():
        icon_path = "res://images/battle/icons/" + template.enemy_id + ".png"
    if ResourceLoader.exists(icon_path):
        battler.icon_texture = load(icon_path)
    else:
        # 无图标时用 sprite 缩小
        if battler.sprite and battler.sprite.texture:
            battler.icon_texture = battler.sprite.texture

    # 敌人技能
    battler.actions.append(ActionFactory.create_basic_attack())
    for sid in template.skills:
        var skill_res := PartyData.get_skill(sid)
        if skill_res:
            var action := ActionFactory.from_skill_data(skill_res)
            if action:
                battler.actions.append(action)

    return battler

func _on_player_needs_input(battler) -> void:
    _current_input_battler = battler
    # 创建行动菜单
    var menu := preload("res://scenes/battle/ui/action_menu/UIActionMenu.tscn").instantiate()
    menu.setup(battler)
    ui_action_menu_anchor.add_child(menu)
    menu.action_selected.connect(func(action: BattlerAction):
        menu.fade_out()
        _on_action_chosen(battler, action)
    )

func _on_action_chosen(battler, action: BattlerAction) -> void:
    if action.target_scope == BattlerAction.TargetScope.SELF:
        # 防御类不需要选目标
        battler.last_action_name = action.action_name
        if action.action_name == "防御":
            battler.stats.guard = true
        turn_queue.submit_player_action(battler, action, [battler])
        return

    # 需要选目标
    var targets := action.get_possible_targets(battler, battler_list.get_alive_battlers())
    var cursor := preload("res://scenes/battle/ui/targeting/UIBattlerTargetingCursor.tscn").instantiate()
    cursor.setup(targets, battler_list.get_alive_battlers(), turn_queue)
    ui_cursor_anchor.add_child(cursor)
    cursor.target_selected.connect(func(target):
        cursor.queue_free()
        battler.last_action_name = action.action_name
        turn_queue.submit_player_action(battler, action, [target])
    )
    cursor.cancelled.connect(func():
        cursor.queue_free()
        _on_player_needs_input(battler)
    )

func _on_action_executed(battler, result: Dictionary) -> void:
    # 显示伤害/治疗文字
    if result["damage"] > 0:
        var label := preload("res://scenes/battle/ui/effects/UIDamageLabel.tscn").instantiate()
        ui_damage_container.add_child(label)
        # 定位到目标位置
        var targets := battler_list.get_alive_enemies()
        if targets.size() > 0:
            var t := targets[randi() % targets.size()]
            label.position = t.position + Vector2(-30, -30)
        label.show_damage(result["damage"], result.get("crit", false))

    if result["heal"] > 0:
        var label := preload("res://scenes/battle/ui/effects/UIDamageLabel.tscn").instantiate()
        ui_damage_container.add_child(label)
        label.position = Vector2(200, 300)
        label.show_heal(result["heal"])

    if not result.get("hit", true):
        var label := preload("res://scenes/battle/ui/effects/UIDamageLabel.tscn").instantiate()
        ui_damage_container.add_child(label)
        label.position = Vector2(800, 400)
        label.show_miss()

func _on_battle_ended(result: Dictionary) -> void:
    ui_turn_bar.fade_out()
    ui_player_list.fade_out()

    if result.get("won", false):
        # 胜利
        _show_result_text("胜利! EXP +" + str(result.get("exp", 0)) + "  Gold +" + str(result.get("gold", 0)))
        # 经验分配
        for p in _player_battlers:
            var char_data := PartyData.get_character(p.char_id)
            if char_data:
                char_data.add_exp(result.get("exp", 0))
        await get_tree().create_timer(2.0).timeout
        _play_battle_aftermath()
    else:
        _show_result_text("战斗失败...")
        GameState.record_death()
        await get_tree().create_timer(2.5).timeout
        GameState.set_game_phase("schedule")

func _show_result_text(text: String) -> void:
    var label := Label.new()
    label.text = text
    label.set_anchors_preset(Control.PRESET_CENTER)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
    label.add_theme_font_size_override("font_size", 28)
    add_child(label)

func _play_battle_aftermath() -> void:
    GameState.set_game_phase("vn")
    var scene_id := "battle_victory_" + GameState.battle_type
    DialogicBridge.start_timeline("res://resources/dialogic/timelines/battle_results.dtl", scene_id)
    # CombatArena 会在 MainScene 切换场景时被清理
```

- [ ] **Step 2: Create CombatArena.tscn**

```ini
[gd_scene load_steps=5 format=3 uid="uid://arena_tscn"]
[ext_resource type="Script" path="res://scenes/battle/arena/CombatArena.gd" id="1"]
[ext_resource type="PackedScene" uid="uid://turnbar_tscn" path="res://scenes/battle/ui/turn_bar/UITurnBar.tscn" id="2"]
[ext_resource type="PackedScene" uid="uid://playerlist_tscn" path="res://scenes/battle/ui/player_panel/UIPlayerBattlerList.tscn" id="3"]

[node name="CombatArena" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="TextureRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
expand_mode = 1
stretch_mode = 5

[node name="BattlerContainer" type="Node2D" parent="."]

[node name="UI" type="CanvasLayer" parent="."]

[node name="TurnBar" parent="UI" instance=ExtResource("2")]

[node name="PlayerList" parent="UI" instance=ExtResource("3")]

[node name="ActionMenuAnchor" type="Control" parent="UI"]
offset_left = 200
offset_top = 880
offset_right = 1720
offset_bottom = 950

[node name="CursorAnchor" type="Control" parent="UI"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2

[node name="DamageContainer" type="Control" parent="UI"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
```

- [ ] **Step 3: Create battle_main.tscn**

```ini
[gd_scene load_steps=3 format=3 uid="uid://battle_main"]
[ext_resource type="Script" path="res://scenes/battle/arena/CombatArena.gd" id="1"]

[node name="BattleMain" type="CanvasLayer"]
[node name="Arena" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")
```

---

