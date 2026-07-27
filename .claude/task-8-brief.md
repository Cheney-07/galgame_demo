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

