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

