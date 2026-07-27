### Task 3: ATB 核心 — ActiveTurnQueue + BattlerList + Battler node

**Files:**
- Create: `scenes/battle/queue/BattlerList.gd`
- Create: `scenes/battle/queue/ActiveTurnQueue.gd`
- Create: `scenes/battle/battler/Battler.gd`
- Create: `scenes/battle/battler/Battler.tscn`

**Interfaces:**
- Consumes: `BattlerStats`, `BattlerAction` subclasses, `EnemyTemplate`
- Produces: `ActiveTurnQueue`(queue mgmt), `Battler`(entity with signals)

- [ ] **Step 1: Create BattlerList.gd**

```gdscript
# scenes/battle/queue/BattlerList.gd
class_name BattlerList extends RefCounted

signal battlers_downed()

var players: Array = []
var enemies: Array = []
var has_player_won := false

func _init(player_battlers: Array, enemy_battlers: Array) -> void:
    players = player_battlers
    enemies = enemy_battlers
    _connect_signals()

func _connect_signals() -> void:
    for p in players:
        p.stats.health_depleted.connect(_check_player_status)
    for e in enemies:
        e.stats.health_depleted.connect(_check_enemy_status)

func _check_player_status() -> void:
    for p in players:
        if p.stats.health > 0:
            return
    # 玩家全灭
    has_player_won = false
    battlers_downed.emit()

func _check_enemy_status() -> void:
    for e in enemies:
        if e.stats.health > 0:
            return
    # 敌人全灭
    has_player_won = true
    battlers_downed.emit()

func get_all_battlers() -> Array:
    return players + enemies

func get_alive_battlers() -> Array:
    return get_all_battlers().filter(func(b): return b.stats.health > 0)

func get_alive_enemies() -> Array:
    return enemies.filter(func(b): return b.stats.health > 0)

func get_alive_players() -> Array:
    return players.filter(func(b): return b.stats.health > 0)
```

- [ ] **Step 2: Create ActiveTurnQueue.gd**

```gdscript
# scenes/battle/queue/ActiveTurnQueue.gd
class_name ActiveTurnQueue extends Node

const SLOW_TIME_SCALE := 0.05

signal player_needs_input(battler)
signal action_executed(battler, result: Dictionary)
signal battle_ended(result: Dictionary)

var battler_list: BattlerList = null
var is_active := true
var time_scale := 1.0
var _is_executing := false
var _is_player_menu_open := false

func setup(bl: BattlerList) -> void:
    battler_list = bl
    for b in battler_list.get_all_battlers():
        b.stats.health_depleted.connect(_on_health_depleted.bind(b))
    battler_list.battlers_downed.connect(_on_combat_end)
    set_process(true)

func _process(delta: float) -> void:
    if not is_active or _is_executing:
        return

    # 充能
    for b in battler_list.get_alive_battlers():
        b.readiness += b.stats.speed * delta * time_scale
        if b.readiness >= 100.0:
            b.readiness = 100.0
            _on_battler_ready(b)

func _on_battler_ready(battler) -> void:
    if _is_executing:
        return

    _is_executing = true
    time_scale = 0.0

    if battler.is_player:
        _is_player_menu_open = true
        time_scale = SLOW_TIME_SCALE
        player_needs_input.emit(battler)
    else:
        await _enemy_act(battler)
        _finish_action(battler)

# 玩家通过这个回调提交行动
func submit_player_action(battler, action, targets: Array) -> void:
    _is_player_menu_open = false
    time_scale = 0.0
    await _execute_action(battler, action, targets)
    _finish_action(battler)

func _enemy_act(battler) -> void:
    var alive_targets := battler_list.get_alive_players()
    if alive_targets.is_empty():
        return

    # 简单 AI
    var action
    if battler.actions.size() > 0 and randf() < 0.3:
        action = battler.actions[randi() % battler.actions.size()]
    else:
        action = battler.get_basic_attack()

    var targets := action.get_possible_targets(battler, battler_list.get_alive_battlers())
    if targets.is_empty():
        targets = [alive_targets[randi() % alive_targets.size()]]

    await _execute_action(battler, action, targets)

func _execute_action(battler, action, targets: Array) -> void:
    var result := await action.execute(battler, targets)
    action_executed.emit(battler, result)

func _finish_action(battler) -> void:
    if battler.stats.health > 0:
        # 查找对应行动确定 readiness_saved
        var saved := 0.0
        for a in battler.actions:
            if a.action_name == battler.last_action_name:
                saved = a.readiness_saved
                break
        if battler.last_action_name == "防御":
            saved = 50.0
        elif battler.last_action_name == "攻击":
            saved = 30.0
        battler.readiness = saved
    else:
        battler.readiness = 0.0

    _is_executing = false
    time_scale = 1.0

func _on_health_depleted(_battler) -> void:
    pass  # BattlerList 会处理胜负检测

func _on_combat_end() -> void:
    is_active = false
    time_scale = 0.0

    var total_exp := 0
    var total_gold := 0
    for e in battler_list.enemies:
        if e.has_meta("exp_reward"):
            total_exp += e.get_meta("exp_reward")
        if e.has_meta("gold_reward"):
            total_gold += e.get_meta("gold_reward")

    battle_ended.emit({
        "won": battler_list.has_player_won,
        "exp": total_exp,
        "gold": total_gold
    })
```

- [ ] **Step 3: Create Battler.gd**

```gdscript
# scenes/battle/battler/Battler.gd
class_name Battler extends Node2D

@export var stats: BattlerStats
@export var is_player := false
@export var char_id: String = ""
@export var display_name: String = ""

var readiness := 0.0:
    set(value):
        readiness = value
        readiness_changed.emit(value)

var actions: Array = []               # BattlerAction 列表
var origin_position: Vector2          # 初始位置（用于攻击后归位）
var last_action_name: String = ""

signal readiness_changed(value: float)
signal action_finished()

# Sprite 引用
var sprite: Sprite2D
var icon_texture: Texture2D

func setup_stats(s: BattlerStats) -> void:
    stats = s
    s.initialize()

func take_damage(amount: int) -> void:
    if amount <= 0:
        return
    stats.health -= amount
    # 受击动画
    if sprite:
        var tween := create_tween()
        tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
        tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

func heal(amount: int) -> void:
    if amount <= 0:
        return
    var old := stats.health
    stats.health += amount
    # 治疗动画
    if sprite:
        var tween := create_tween()
        tween.tween_property(sprite, "modulate", Color(0.3, 1, 0.3), 0.15)
        tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)

func get_basic_attack() -> BattlerAction:
    for a in actions:
        if a is AttackBattlerAction and a.readiness_saved >= 30.0:
            return a
    # fallback
    return ActionFactory.create_basic_attack()
```

- [ ] **Step 4: Create Battler.tscn**

Create a minimal `.tscn` file:

```
[gd_scene load_steps=4 format=3 uid="uid://battler_tscn"]
[ext_resource type="Script" path="res://scenes/battle/battler/Battler.gd" id="1"]
[ext_resource type="Script" path="res://scenes/battle/battler/BattlerStats.gd" id="2"]

[sub_resource type="RectangleShape2D" id="1"]

[node name="Battler" type="Node2D"]
script = ExtResource("1")

[node name="Sprite2D" type="Sprite2D" parent="."]
centered = true
```

---

