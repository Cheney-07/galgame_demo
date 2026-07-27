# ATB 半即时战斗系统重构 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 gamedemo1 的纯回合制战斗替换为 ATB（Active Time Battle）半即时系统，保留现有角色/技能/Dialogic 联动

**Architecture:** CombatArena(Controller) → ActiveTurnQueue(ATB Loop) → Battler(Entity) × N → UI 组件(7 个独立 tscn)，数据驱动（Resource），Tween 动画

**Tech Stack:** Godot 4.3+ / GDScript / Dialogic 2 / Resource 系统 / Tween

**Spec:** `docs/superpowers/specs/2026-07-21-atb-combat-system-design.md`

## Global Constraints

- 所有新文件放在 `scenes/battle/` 下
- `class_name` 用于所有新 Resource 和 Node 类型
- 无能量系统 — 技能战斗内免费使用
- readiness_saved 控制技能频率（普攻 30，技能 0，防御 50）
- ATB 三档 time_scale: 1.0(正常) / 0.05(选行动) / 0.0(执行行动)
- 所有路径用 `res://` 前缀
- 保持 ScheduleHub → MainScene → Battle → Dialogic → Schedule 流程不变
- BOSS diren_laocong 特殊机制: 召唤 hanbao → 2 回合未消灭则被吃掉回血

---

## 文件结构

```
scenes/battle/
├── battle_main.tscn                 ← 入口场景（替代旧的 battle.tscn）
├── arena/
│   ├── CombatArena.gd               ← 战斗容器（Control）
│   └── arena_template.tscn          ← 战斗容器模版场景
├── battler/
│   ├── Battler.gd                   ← ATB 战斗实体（Node2D）
│   ├── Battler.tscn                 ← 战斗实体场景
│   └── BattlerStats.gd              ← 属性 Resource
├── queue/
│   ├── ActiveTurnQueue.gd           ← ATB 循环核心（Node）
│   └── BattlerList.gd               ← 参战者列表（RefCounted）
├── actions/
│   ├── BattlerAction.gd             ← 行动基类 Resource
│   ├── AttackBattlerAction.gd       ← 伤害型行动
│   ├── HealBattlerAction.gd         ← 治疗型行动
│   ├── ModifyStatsBattlerAction.gd  ← 增益型行动
│   ├── SpecialBattlerAction.gd      ← 特殊行动
│   └── ActionFactory.gd             ← 从 SkillData 创建 Action
├── ui/
│   ├── turn_bar/
│   │   ├── UITurnBar.gd + .tscn     ← ATB 行动顺序条
│   │   └── UIBattlerIcon.gd + .tscn ← 行动条上的图标
│   ├── player_panel/
│   │   ├── UIPlayerBattlerList.gd + .tscn ← 我方状态
│   │   └── UIBattlerEntry.gd + .tscn     ← 单角色条目
│   ├── action_menu/
│   │   ├── UIActionMenu.gd + .tscn  ← 行动菜单
│   │   └── UIActionButton.gd + .tscn ← 行动按钮
│   ├── targeting/
│   │   └── UIBattlerTargetingCursor.gd + .tscn ← 目标选择
│   └── effects/
│       └── UIDamageLabel.gd + .tscn ← 伤害浮字
├── enemies/
│   ├── EnemyTemplate.gd             ← 敌人模板 Resource
│   ├── slime.tres                   ← 史莱姆
│   ├── diren_laocong.tres           ← 邪恶汉堡牢聪（BOSS）
│   ├── bianbian.tres                ← 便便
│   └── hanbao.tres                  ← 汉堡（新增）
└── encounters/
    ├── EncounterData.gd             ← 遭遇战配置 Resource
    ├── explore_encounter.tres       ← 探索战斗
    ├── quest_encounter.tres         ← 委托战斗
    └── default_encounter.tres       ← 默认
```

---

### Task 1: 准备阶段 — 数据层（BattlerStats / EnemyTemplate / EncounterData）

**Files:**
- Create: `scenes/battle/battler/BattlerStats.gd`
- Create: `scenes/battle/enemies/EnemyTemplate.gd`
- Create: `scenes/battle/encounters/EncounterData.gd`
- Modify: `autoload/PartyData.gd`
- Create: `scenes/battle/enemies/slime.tres`
- Create: `scenes/battle/enemies/diren_laocong.tres`
- Create: `scenes/battle/enemies/bianbian.tres`
- Create: `scenes/battle/enemies/hanbao.tres`
- Create: `scenes/battle/encounters/explore_encounter.tres`
- Create: `scenes/battle/encounters/quest_encounter.tres`
- Create: `scenes/battle/encounters/default_encounter.tres`

**Interfaces:**
- Consumes: `PartyData.CharacterData` (existing)
- Produces: `BattlerStats`(Resource), `EnemyTemplate`(Resource), `EncounterData`(Resource)

- [ ] **Step 1: Create BattlerStats.gd**

```gdscript
# scenes/battle/battler/BattlerStats.gd
class_name BattlerStats extends Resource

enum StatType { MAX_HEALTH, MAX_ENERGY, ATTACK, MAGIC_ATTACK, DEFENSE, SPEED, HIT_CHANCE, EVASION }

@export var base_max_health := 100
@export var base_attack := 10
@export var base_magic_attack := 10
@export var base_defense := 10
@export var base_speed := 70
@export var base_hit_chance := 90
@export var base_evasion := 5

var max_health := base_max_health
var attack := base_attack
var magic_attack := base_magic_attack
var defense := base_defense
var speed := base_speed
var hit_chance := base_hit_chance
var evasion := base_evasion

var health := max_health:
    set(value):
        health = clampi(value, 0, max_health)
        health_changed.emit()
        if health <= 0:
            health_depleted.emit()

var guard := false

signal health_changed()
signal health_depleted()

var _modifiers := {}   # stat_name → { id: value }
var _multipliers := {} # stat_name → { id: value }
var _next_id := 0

func _init() -> void:
    for key in ["attack", "magic_attack", "defense", "speed", "hit_chance", "evasion"]:
        _modifiers[key] = {}
        _multipliers[key] = {}

func initialize() -> void:
    health = max_health

func init_from_character(char_data) -> void:
    var vit = char_data.get_stat("VIT")
    base_max_health = 100 + int(vit * 15.0 * (1.0 + (char_data.level - 1) * 0.1))
    base_attack = char_data.get_stat("STR")
    base_magic_attack = char_data.get_stat("MAG")
    base_defense = vit
    base_speed = char_data.get_stat("AGI")
    base_hit_chance = 80 + char_data.get_stat("TEC") * 2
    base_evasion = char_data.get_stat("AGI") / 2
    _refresh_all()

func init_from_enemy(template) -> void:
    base_max_health = template.get("hp", 100)
    base_attack = template.get("str", 10)
    base_magic_attack = template.get("mag", 10)
    base_defense = template.get("vit", 10)
    base_speed = template.get("agi", 10)
    base_hit_chance = 80 + template.get("tec", 5) * 2
    base_evasion = template.get("agi", 10) / 2
    _refresh_all()

func _refresh_all() -> void:
    for key in ["max_health", "attack", "magic_attack", "defense", "speed", "hit_chance", "evasion"]:
        _recalculate(key)
    health = max_health

func _recalculate(prop_name: String) -> void:
    var base_prop = "base_" + prop_name
    if not (base_prop in self):
        return
    var value := get(base_prop) as float
    var mult := 1.0
    for m in _multipliers.get(prop_name, {}).values():
        mult += m
    if mult < 0.0:
        mult = 0.0
    if not is_equal_approx(mult, 1.0):
        value *= mult
    for mod in _modifiers.get(prop_name, {}).values():
        value += mod
    value = roundf(max(value, 0.0))
    set(prop_name, int(value))

func add_modifier(stat_name: String, value: int) -> int:
    var id := _next_id
    _next_id += 1
    _modifiers[stat_name][id] = value
    _recalculate(stat_name)
    return id

func remove_modifier(stat_name: String, id: int) -> void:
    if _modifiers[stat_name].erase(id):
        _recalculate(stat_name)

func add_multiplier(stat_name: String, value: float) -> int:
    var id := _next_id
    _next_id += 1
    _multipliers[stat_name][id] = value
    _recalculate(stat_name)
    return id

func remove_multiplier(stat_name: String, id: int) -> void:
    if _multipliers[stat_name].erase(id):
        _recalculate(stat_name)
```

- [ ] **Step 2: Create EnemyTemplate.gd**

```gdscript
# scenes/battle/enemies/EnemyTemplate.gd
class_name EnemyTemplate extends Resource

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var hp: int = 80
@export var str: int = 8
@export var mag: int = 6
@export var vit: int = 6
@export var agi: int = 8
@export var tec: int = 5
@export var cha: int = 3
@export var sprite_path: String = ""
@export var icon_path: String = ""
@export var skills: Array[String] = []
@export var exp_reward: int = 30
@export var gold_reward: int = 10
@export var ai_behavior: String = "aggressive"
```

- [ ] **Step 3: Create EncounterData.gd**

```gdscript
# scenes/battle/encounters/EncounterData.gd
class_name EncounterData extends Resource

@export var encounter_id: String = ""
@export var battle_type: String = "explore"
@export var background_path: String = "res://images/battle_bg.png"
@export var music_path: String = ""
@export var player_bg_path: String = ""          # 左侧玩家区域背景
@export var enemy_defs: Array[EnemySlot] = []    # 敌人配置

class EnemySlot:
    var enemy_id: String = ""
    var count: int = 1
```

Wait — Godot Resources don't support custom inner classes that show up in the editor easily. Let me use a simpler approach:

```gdscript
# scenes/battle/encounters/EncounterData.gd
class_name EncounterData extends Resource

@export var encounter_id: String = ""
@export var battle_type: String = "explore"
@export var background_path: String = "res://images/battle_bg.png"
@export var music_path: String = ""
@export var player_bg_path: String = ""
@export var enemy_ids: Array[String] = []        # enemy_id 列表
@export var enemy_counts: Array[int] = []         # 对应数量
@export var is_boss: bool = false
```

- [ ] **Step 4: Create enemy .tres files**

```ini
# scenes/battle/enemies/slime.tres
[gd_resource type="Resource" script_class="EnemyTemplate" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/enemies/EnemyTemplate.gd" id="1"]
[resource]
script = ExtResource("1")
enemy_id = "slime"
enemy_name = "史莱姆"
hp = 40
str = 5
mag = 3
vit = 4
agi = 4
tec = 3
cha = 1
sprite_path = "res://images/battle/sprites/slime.png"
icon_path = "res://images/battle/icons/slime.png"
skills = []
exp_reward = 20
gold_reward = 10
ai_behavior = "aggressive"
```

```ini
# scenes/battle/enemies/diren_laocong.tres
[gd_resource type="Resource" script_class="EnemyTemplate" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/enemies/EnemyTemplate.gd" id="1"]
[resource]
script = ExtResource("1")
enemy_id = "diren_laocong"
enemy_name = "邪恶汉堡牢聪"
hp = 150
str = 12
mag = 8
vit = 8
agi = 9
tec = 6
cha = 3
sprite_path = "res://images/battle/sprites/diren_laocong.png"
icon_path = "res://images/battle/icons/diren_laocong.png"
skills = []
exp_reward = 100
gold_reward = 50
ai_behavior = "boss"
```

```ini
# scenes/battle/enemies/bianbian.tres
[gd_resource type="Resource" script_class="EnemyTemplate" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/enemies/EnemyTemplate.gd" id="1"]
[resource]
script = ExtResource("1")
enemy_id = "bianbian"
enemy_name = "便便"
hp = 60
str = 6
mag = 4
vit = 4
agi = 5
tec = 3
cha = 1
sprite_path = "res://images/battle/sprites/bianbian.png"
icon_path = "res://images/battle/icons/bianbian.png"
skills = []
exp_reward = 40
gold_reward = 20
ai_behavior = "aggressive"
```

```ini
# scenes/battle/enemies/hanbao.tres
[gd_resource type="Resource" script_class="EnemyTemplate" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/enemies/EnemyTemplate.gd" id="1"]
[resource]
script = ExtResource("1")
enemy_id = "hanbao"
enemy_name = "汉堡"
hp = 30
str = 4
mag = 2
vit = 3
agi = 6
tec = 2
cha = 1
sprite_path = "res://images/battle/sprites/hanbao.png"
icon_path = "res://images/battle/icons/hanbao.png"
skills = []
exp_reward = 10
gold_reward = 5
ai_behavior = "aggressive"
```

- [ ] **Step 5: Create encounter .tres files**

```ini
# scenes/battle/encounters/explore_encounter.tres
[gd_resource type="Resource" script_class="EncounterData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/encounters/EncounterData.gd" id="1"]
[resource]
script = ExtResource("1")
encounter_id = "explore_default"
battle_type = "explore"
background_path = "res://images/battle/bg_explore.png"
enemy_ids = ["slime", "slime"]
enemy_counts = [1, 1]
is_boss = false
```

```ini
# scenes/battle/encounters/quest_encounter.tres
[gd_resource type="Resource" script_class="EncounterData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/encounters/EncounterData.gd" id="1"]
[resource]
script = ExtResource("1")
encounter_id = "quest_diren_laocong"
battle_type = "quest"
background_path = "res://images/battle/bg_quest.png"
enemy_ids = ["diren_laocong", "bianbian", "hanbao", "hanbao"]
enemy_counts = [1, 1, 2, 1]
is_boss = true
```

```ini
# scenes/battle/encounters/default_encounter.tres
[gd_resource type="Resource" script_class="EncounterData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/encounters/EncounterData.gd" id="1"]
[resource]
script = ExtResource("1")
encounter_id = "default"
battle_type = "default"
background_path = "res://images/battle/bg_explore.png"
enemy_ids = ["slime", "slime"]
enemy_counts = [2, 1]
is_boss = false
```

- [ ] **Step 6: Add enemy/encounter registry to PartyData.gd**

```gdscript
# Add after skill_registry declaration (around line 97 in PartyData.gd)
var enemy_registry: Dictionary = {}     # enemy_id → EnemyTemplate
var encounter_registry: Dictionary = {}  # battle_type → EncounterData

# Add to _ready() — after _load_character_templates():
_load_enemy_templates()
_load_encounter_data()

# Add new methods:

func _load_enemy_templates() -> void:
    var dir := "res://scenes/battle/enemies/"
    var files := _list_files(dir, ".tres")
    for f in files:
        if f.ends_with("EnemyTemplate.gd"):
            continue
        var res: Resource = load(dir + f)
        if res == null or not res is EnemyTemplate:
            continue
        if res.enemy_id != "":
            enemy_registry[res.enemy_id] = res
            print("[PartyData] Loaded enemy: ", res.enemy_name)

func _load_encounter_data() -> void:
    var dir := "res://scenes/battle/encounters/"
    var files := _list_files(dir, ".tres")
    for f in files:
        var res: Resource = load(dir + f)
        if res == null or not res is EncounterData:
            continue
        encounter_registry[res.battle_type] = res
        print("[PartyData] Loaded encounter: ", res.encounter_id)

func get_enemy(enemy_id: String) -> EnemyTemplate:
    return enemy_registry.get(enemy_id, null)

func get_encounter(battle_type: String) -> EncounterData:
    return encounter_registry.get(battle_type, encounter_registry.get("default", null))
```

- [ ] **Step 7: Verify data layer**

Run the project. If it loads without errors, the registries are initialized. Check console output for `[PartyData] Loaded enemy:` and `[PartyData] Loaded encounter:` lines.

---

### Task 2: 行动系统 — BattlerAction 基类 + 4 子类 + ActionFactory

**Files:**
- Create: `scenes/battle/actions/BattlerAction.gd`
- Create: `scenes/battle/actions/AttackBattlerAction.gd`
- Create: `scenes/battle/actions/HealBattlerAction.gd`
- Create: `scenes/battle/actions/ModifyStatsBattlerAction.gd`
- Create: `scenes/battle/actions/SpecialBattlerAction.gd`
- Create: `scenes/battle/actions/ActionFactory.gd`

**Interfaces:**
- Consumes: `SkillData` (from resources/skills/), `BattlerStats.StatType`
- Produces: `BattlerAction` subclasses with `execute(source, targets) → Dictionary`

- [ ] **Step 1: Create BattlerAction.gd（基类）**

```gdscript
# scenes/battle/actions/BattlerAction.gd
class_name BattlerAction extends Resource

enum TargetScope { SELF, SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES }

@export var action_name: String = "行动"
@export var description: String = ""
@export var target_scope: TargetScope = TargetScope.SINGLE_ENEMY
@export var readiness_saved: float = 0.0
@export var base_power: float = 1.0
@export var stat_scale: String = "STR"
@export var icon_path: String = ""

func can_execute(_source) -> bool:
    return true

func get_possible_targets(source, all_battlers: Array) -> Array:
    var targets: Array = []
    var players := all_battlers.filter(func(b): return b.is_player)
    var enemies := all_battlers.filter(func(b): return not b.is_player and b.stats.health > 0)

    match target_scope:
        TargetScope.SELF:
            targets = [source]
        TargetScope.SINGLE_ENEMY:
            targets = enemies
        TargetScope.ALL_ENEMIES:
            targets = enemies
        TargetScope.SINGLE_ALLY:
            targets = players.filter(func(b): return b.stats.health > 0)
        TargetScope.ALL_ALLIES:
            targets = players.filter(func(b): return b.stats.health > 0)

    return targets

func execute(source, targets: Array) -> Dictionary:
    return { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }

func get_hit_chance(source) -> float:
    return source.stats.hit_chance / 100.0
```

- [ ] **Step 2: Create AttackBattlerAction.gd**

```gdscript
# scenes/battle/actions/AttackBattlerAction.gd
class_name AttackBattlerAction extends BattlerAction

@export var hit_count: int = 1
@export var use_magic: bool = false
@export var crit_chance_bonus: float = 0.0

func execute(source, targets: Array) -> Dictionary:
    var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
    if targets.is_empty():
        result["hit"] = false
        result["messages"].append("没有目标!")
        return result

    # 动画：向目标移动
    await _move_to_target(source, targets[0])

    var actual_hits := hit_count
    if action_name == "弹幕连射":
        actual_hits = 3 + int(source.stats.speed / 5)
        if actual_hits > 1:
            result["messages"].append(str(actual_hits) + " Hits!")

    var total_dmg := 0
    var atk_stat := source.stats.magic_attack if use_magic else source.stats.attack
    var target_def := targets[0].stats.defense

    for h in actual_hits:
        var hit_roll := randf()
        var hit_chance_val := source.stats.hit_chance / 100.0
        if hit_roll > hit_chance_val:
            continue  # miss 该段

        var base_dmg := atk_stat * base_power
        var def_factor := 100.0 / (100.0 + target_def)
        var dmg := max(1, int(base_dmg * def_factor))

        var crit_roll := randf()
        var crit := crit_roll < (0.05 + crit_chance_bonus)
        if crit:
            dmg = int(dmg * 1.5)
            result["crit"] = true

        total_dmg += dmg

    # 防御减半
    if targets[0].stats.guard:
        total_dmg = int(total_dmg * 0.5)
        result["messages"].append("防御!")

    targets[0].stats.guard = false
    result["damage"] = total_dmg

    targets[0].take_damage(total_dmg)
    source.position = source.origin_position

    return result

func _move_to_target(source, target) -> void:
    var origin := source.position
    source.origin_position = origin
    var dir := -1.0 if source.is_player else 1.0
    var dest := target.position + Vector2(dir * 200.0, 0)
    var tween := source.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(source, "position", dest, 0.2)
    await tween.finished
```

- [ ] **Step 3: Create HealBattlerAction.gd**

```gdscript
# scenes/battle/actions/HealBattlerAction.gd
class_name HealBattlerAction extends BattlerAction

func execute(source, targets: Array) -> Dictionary:
    var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
    if targets.is_empty():
        return result

    var stat_val := source.stats.get(stat_scale.to_lower(), 10)
    var cha_val := source.stats.get("cha", 10)  # will be 0 unless we add it

    var heal_amount := int(stat_val * base_power * (1.0 + cha_val / 50.0))
    heal_amount = max(1, heal_amount)

    # 跳跃动画
    var origin := source.position
    var jump := source.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    jump.tween_property(source, "position", origin + Vector2(0, -150), 0.15)
    await jump.finished
    var fall := source.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
    fall.tween_property(source, "position", origin, 0.15)
    await fall.finished

    if target_scope == TargetScope.ALL_ALLIES:
        var count := 0
        for t in targets:
            if t.stats.health > 0:
                t.heal(heal_amount)
                count += 1
        result["heal"] = heal_amount
        if count > 1:
            result["messages"].append("全队回复 " + str(heal_amount))
    else:
        var t := targets[0]
        t.heal(heal_amount)
        result["heal"] = heal_amount

    return result
```

- [ ] **Step 4: Create ModifyStatsBattlerAction.gd**

```gdscript
# scenes/battle/actions/ModifyStatsBattlerAction.gd
class_name ModifyStatsBattlerAction extends BattlerAction

@export var modify_stat: String = "attack"
@export var modify_value: int = 5
@export var duration_turns: int = 3

func execute(source, targets: Array) -> Dictionary:
    var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
    result["effects"] = [{ "stat": modify_stat, "value": modify_value, "turns": duration_turns }]

    for t in targets:
        if t.stats.health > 0:
            var id := t.stats.add_modifier(modify_stat, modify_value)
            # 存储 buff id 以便后续移除
            if not t.has_meta("buff_ids"):
                t.set_meta("buff_ids", [])
            t.get_meta("buff_ids").append({ "id": id, "stat": modify_stat, "turns": duration_turns })

    result["messages"].append(action_name + "!")
    return result
```

- [ ] **Step 5: Create SpecialBattlerAction.gd**

```gdscript
# scenes/battle/actions/SpecialBattlerAction.gd
class_name SpecialBattlerAction extends BattlerAction

func execute(source, targets: Array) -> Dictionary:
    var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
    result["messages"].append("召唤助战!")

    if targets.is_empty():
        return result

    # 额外 MAG 伤害
    var mag := source.stats.magic_attack
    var def_val := targets[0].stats.defense
    var dmg := int(mag * base_power * 100.0 / (100.0 + def_val))
    dmg = max(1, dmg)
    result["damage"] = dmg
    targets[0].take_damage(dmg)

    return result
```

- [ ] **Step 6: Create ActionFactory.gd**

```gdscript
# scenes/battle/actions/ActionFactory.gd
extends RefCounted

static func from_skill_data(skill_data) -> BattlerAction:
    if skill_data == null:
        return null

    match skill_data.skill_type:
        "damage":
            var action := AttackBattlerAction.new()
            action.action_name = skill_data.skill_name
            action.description = skill_data.description
            action.base_power = skill_data.power
            action.stat_scale = skill_data.stat_scale
            action.icon_path = skill_data.icon_path
            action.hit_count = skill_data.hit_count
            action.readiness_saved = 0.0  # 技能归零
            action.target_scope = _map_target_type(skill_data.target_type)
            action.use_magic = (skill_data.stat_scale == "MAG")
            return action

        "heal":
            var action := HealBattlerAction.new()
            action.action_name = skill_data.skill_name
            action.description = skill_data.description
            action.base_power = skill_data.power
            action.stat_scale = skill_data.stat_scale
            action.icon_path = skill_data.icon_path
            action.readiness_saved = 0.0
            action.target_scope = _map_target_type(skill_data.target_type)
            return action

        "buff":
            var action := ModifyStatsBattlerAction.new()
            action.action_name = skill_data.skill_name
            action.description = skill_data.description
            action.base_power = skill_data.power
            action.stat_scale = skill_data.stat_scale
            action.icon_path = skill_data.icon_path
            action.readiness_saved = 0.0
            action.target_scope = _map_target_type(skill_data.target_type)
            if skill_data.effects.size() > 0:
                var ef = skill_data.effects[0]
                action.modify_stat = ef.get("stat", "attack")
                action.modify_value = ef.get("value", 5)
                action.duration_turns = ef.get("turns", 3)
            return action

        "special":
            var action := SpecialBattlerAction.new()
            action.action_name = skill_data.skill_name
            action.description = skill_data.description
            action.base_power = skill_data.power
            action.stat_scale = skill_data.stat_scale
            action.icon_path = skill_data.icon_path
            action.readiness_saved = 0.0
            action.target_scope = TargetScope.SINGLE_ENEMY
            return action

    return null

static func create_basic_attack() -> AttackBattlerAction:
    var action := AttackBattlerAction.new()
    action.action_name = "攻击"
    action.description = "普通攻击"
    action.base_power = 1.0
    action.stat_scale = "STR"
    action.hit_count = 1
    action.readiness_saved = 30.0  # 普攻保留 30%
    action.target_scope = TargetScope.SINGLE_ENEMY
    return action

static func create_defend() -> BattlerAction:
    var action := BattlerAction.new()
    action.action_name = "防御"
    action.description = "本回合伤害减半"
    action.readiness_saved = 50.0
    action.target_scope = TargetScope.SELF
    return action

static func _map_target_type(ttype: String) -> int:
    match ttype:
        "single_enemy": return BattlerAction.TargetScope.SINGLE_ENEMY
        "all_enemies": return BattlerAction.TargetScope.ALL_ENEMIES
        "single_ally": return BattlerAction.TargetScope.SINGLE_ALLY
        "all_allies": return BattlerAction.TargetScope.ALL_ALLIES
        "self": return BattlerAction.TargetScope.SELF
    return BattlerAction.TargetScope.SINGLE_ENEMY
```

---

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

### Task 7: 集成 — MainScene 改造 + 旧文件删除

**Files:**
- Modify: `scenes/MainScene.gd`
- Delete: `scenes/battle/BattleController.gd`
- Delete: `scenes/battle/BattleUI.gd`
- Delete: `scenes/battle/SkillProcessor.gd`
- Delete: `scenes/battle/battle.tscn`

- [ ] **Step 1: Modify MainScene.gd**

Replace `_create_battle_scene()` and `_get_enemies()`:

```gdscript
# Replace _create_battle_scene() body entirely:
func _create_battle_scene() -> void:
    var btl_res: Resource = load("res://scenes/battle/battle_main.tscn")
    if btl_res:
        battle_scene = btl_res.instantiate()
        battle_scene.visible = false
        add_child(battle_scene)

        var squad: Array[String] = GameState.formation_squad
        if squad.is_empty():
            var chars := PartyData.get_all_character_ids()
            for i in min(3, chars.size()):
                squad.append(chars[i])

        var encounter: EncounterData = _get_encounter(GameState.battle_type)

        if battle_scene.has_method("start"):
            battle_scene.start(squad, encounter)
        else:
            _show_error("Battle scene missing start method")
    else:
        _show_error("无法加载战斗场景")


# Replace _get_enemies() entirely:
func _get_encounter(battle_type: String) -> EncounterData:
    return PartyData.get_encounter(battle_type)


# Remove the entire old _get_enemies() method body
```

- [ ] **Step 2: Delete old battle files**

```bash
rm "E:/gamedemo1/scenes/battle/BattleController.gd"
rm "E:/gamedemo1/scenes/battle/BattleUI.gd"
rm "E:/gamedemo1/scenes/battle/SkillProcessor.gd"
rm "E:/gamedemo1/scenes/battle/battle.tscn"
```

- [ ] **Step 3: Full integration test**

Run the project. Create a new game or load save. Verify:
1. Schedule → 编队 → 战斗 → 进入战斗场景
2. ATB 充能、TurnBar 显示、角色行动
3. 选行动 → 选目标 → 执行（动画 + 伤害）
4. 敌人 AI 行动
5. 胜利 → 经验结算 → Dialogic 剧情 → 返回日程
6. 失败 → 返回日程

---

### Task 8: BOSS 特殊机制 — diren_laocong 召唤 + 吃掉 hanbao

**Files:**
- Modify: `scenes/battle/queue/ActiveTurnQueue.gd`（添加 BOSS AI 行为）
- Modify: `scenes/battle/arena/CombatArena.gd`（添加 BOSS 特殊逻辑）

- [ ] **Step 1: Add BOSS AI to ActiveTurnQueue**

```gdscript
# In ActiveTurnQueue.gd, enhance _enemy_act():

func _enemy_act(battler) -> void:
    var is_boss := battler.has_meta("is_boss") and battler.get_meta("is_boss")
    var alive_targets := battler_list.get_alive_players()
    if alive_targets.is_empty():
        return

    if is_boss and battler.char_id == "diren_laocong":
        await _boss_act(battler, alive_targets)
    else:
        await _default_enemy_act(battler, alive_targets)

func _default_enemy_act(battler, alive_targets: Array) -> void:
    var action
    if battler.actions.size() > 0 and randf() < 0.3:
        action = battler.actions[randi() % battler.actions.size()]
    else:
        action = battler.get_basic_attack()

    var targets := action.get_possible_targets(battler, battler_list.get_alive_battlers())
    if targets.is_empty():
        targets = [alive_targets[randi() % alive_targets.size()]]

    await _execute_action(battler, action, targets)

func _boss_act(battler, alive_targets: Array) -> void:
    # 检查是否有存活的 hanbao
    var hanbaos := battler_list.enemies.filter(func(b):
        return b.char_id == "hanbao" and b.stats.health > 0
    )

    if hanbaos.size() > 0:
        # 检查是否有 hanbao 超过 2 回合
        for h in hanbaos:
            if h.has_meta("turns_alive") and h.get_meta("turns_alive") >= 2:
                # 吃掉汉堡，回血
                battler.last_action_name = "吃掉汉堡"
                var heal_amount := h.stats.max_health * 2
                battler.heal(heal_amount)
                # 汉堡死亡
                h.stats.health = 0
                # 显示消息
                var result := { "damage": 0, "heal": heal_amount, "crit": false, "hit": true,
                    "messages": ["邪恶汉堡牢聪吃掉了汉堡，恢复了 " + str(heal_amount) + " HP!"], "effects": [] }
                action_executed.emit(battler, result)
                return

    # 如果没有可吃的汉堡，50% 概率召唤
    if hanbaos.size() < 2 and randf() < 0.5:
        # 召唤一个新汉堡
        var hanbao_template := PartyData.get_enemy("hanbao")
        if hanbao_template:
            battler.last_action_name = "召唤汉堡"
            var new_hanbao := _create_summoned_hanbao(hanbao_template)
            new_hanbao.set_meta("turns_alive", 0)
            battler_container.add_child(new_hanbao)
            battler_list.enemies.append(new_hanbao)
            new_hanbao.stats.health_depleted.connect(battler_list._check_enemy_status)
            var result := { "damage": 0, "heal": 0, "crit": false, "hit": true,
                "messages": ["邪恶汉堡牢聪召唤了汉堡!"], "effects": [] }
            action_executed.emit(battler, result)
            return

    # 默认攻击
    await _default_enemy_act(battler, alive_targets)

func _create_summoned_hanbao(template: EnemyTemplate) -> Battler:
    # 与 _create_enemy_battler 类似，但放在 battler_container 中
    var battler := preload("res://scenes/battle/battler/Battler.tscn").instantiate()
    var stats := BattlerStats.new()
    stats.init_from_enemy(template)
    battler.setup_stats(stats)
    battler.is_player = false
    battler.char_id = template.enemy_id
    battler.display_name = template.enemy_name

    var sprite_path := "res://images/battle/sprites/hanbao.png"
    if ResourceLoader.exists(sprite_path):
        battler.sprite = Sprite2D.new()
        battler.sprite.texture = load(sprite_path)
        battler.sprite.scale = Vector2(0.4, 0.4)
        battler.add_child(battler.sprite)

    var icon_path := "res://images/battle/icons/hanbao.png"
    if ResourceLoader.exists(icon_path):
        battler.icon_texture = load(icon_path)

    battler.actions.append(ActionFactory.create_basic_attack())
    battler.position = Vector2(1300, 400)
    battler.set_meta("summoned", true)
    return battler
```

- [ ] **Step 2: Add boss summon/action signals to ActiveTurnQueue**

The boss needs CombatArena to create new battler nodes (it has the scene references). Use signals:

```gdscript
# Add to ActiveTurnQueue signal declarations (near top):
signal boss_summon_requested(template_id: String)
signal boss_eat_minion(minion)
signal boss_message(text: String)

# In _boss_act, replace direct battler_container access with signals:
func _boss_act(battler, alive_targets: Array) -> void:
    var hanbaos := battler_list.enemies.filter(func(b):
        return b.char_id == "hanbao" and b.stats.health > 0
    )

    if hanbaos.size() > 0:
        for h in hanbaos:
            if h.has_meta("turns_alive") and h.get_meta("turns_alive") >= 2:
                # 吃掉汉堡，回血
                battler.last_action_name = "吃掉汉堡"
                var heal_amount := h.stats.max_health * 2
                h.stats.health = 0  # 杀死汉堡
                var result := { "damage": 0, "heal": heal_amount, "crit": false, "hit": true,
                    "messages": ["邪恶汉堡牢聪吃掉了汉堡，恢复了 %d HP!" % heal_amount], "effects": [] }
                action_executed.emit(battler, result)
                boss_eat_minion.emit(h)
                return

    if hanbaos.size() < 2 and randf() < 0.5:
        battler.last_action_name = "召唤汉堡"
        boss_summon_requested.emit("hanbao")
        var result := { "damage": 0, "heal": 0, "crit": false, "hit": true,
            "messages": ["邪恶汉堡牢聪召唤了汉堡!"], "effects": [] }
        action_executed.emit(battler, result)
        return

    await _default_enemy_act(battler, alive_targets)


# In _process, add after the readiness loop:
# 追踪所有 hanbao 的存活回合数（boss 机制）
for b in battler_list.enemies:
    if b.char_id == "hanbao" and b.stats.health > 0:
        if b.readiness >= 100.0:
            var turns := b.get_meta("turns_alive", 0)
            b.set_meta("turns_alive", turns + 1)
```

- [ ] **Step 3: Connect boss signals in CombatArena**

```gdscript
# In CombatArena.start(), after turn_queue.setup():
if encounter.is_boss:
    turn_queue.boss_summon_requested.connect(_on_boss_summon)
    turn_queue.boss_eat_minion.connect(_on_boss_eat)

# Add new methods:
func _on_boss_summon(template_id: String) -> void:
    var template := PartyData.get_enemy(template_id)
    if template == null:
        return
    var battler := _create_enemy_battler(template)
    battler.position = Vector2(1300 + randi() % 200, 300 + randi() % 200)
    battler.set_meta("summoned", true)
    battler.set_meta("turns_alive", 0)
    battler_container.add_child(battler)
    battler_list.enemies.append(battler)
    battler.stats.health_depleted.connect(battler_list._check_enemy_status)

func _on_boss_eat(minion) -> void:
    # 移除被吃掉的 minion
    battler_list.enemies.erase(minion)
    if is_instance_valid(minion):
        minion.queue_free()

# In _create_enemy_battler, after creating battler:
if template.enemy_id == "diren_laocong":
    battler.set_meta("is_boss", true)
```

---

### Task 9: 收尾 — 旧文件删除 + 最终验证

- [ ] **Step 1: Verify no remaining references to old files**

```bash
grep -r "BattleController" E:/gamedemo1/scenes/ --include="*.gd" || echo "No references to BattleController"
grep -r "BattleUI" E:/gamedemo1/scenes/ --include="*.gd" || echo "No references to BattleUI"
grep -r "SkillProcessor" E:/gamedemo1/scenes/ --include="*.gd" || echo "No references to SkillProcessor"
grep -r "battle.tscn" E:/gamedemo1/ --include="*.gd" --include="*.tscn" || echo "No references to old battle.tscn"
```

- [ ] **Step 2: Full game flow test**

1. 启动游戏 → 序章剧情（Dialogic 正常）
2. 进入日程 → 查看角色状态
3. 编队 3 人 → 战斗
4. ATB 充能 → TurnBar 显示 → 选技能 → 攻击/治疗/增益
5. 敌人行动
6. 胜利 → Dialogic → 返回日程
7. 测试失败场景
8. BOSS 战测试召唤 + 吃汉堡机制
