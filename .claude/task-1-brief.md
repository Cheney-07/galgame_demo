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

