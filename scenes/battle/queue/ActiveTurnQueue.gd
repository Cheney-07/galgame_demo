# scenes/battle/queue/ActiveTurnQueue.gd
class_name ActiveTurnQueue extends Node

const SLOW_TIME_SCALE := 0.05

signal player_needs_input(battler)
signal action_executed(battler, result: Dictionary)
signal boss_summon_requested(template_id: String)
signal boss_eat_minion(minion)
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
			return

	# 追踪所有 hanbao 的存活回合数（boss 机制）
	for b in battler_list.enemies:
		if b.char_id == "hanbao" and b.stats.health > 0:
			if b.readiness >= 100.0:
				var turns = b.get_meta("turns_alive", 0)
				b.set_meta("turns_alive", turns + 1)

func _on_battler_ready(battler) -> void:
	if _is_executing:
		return

	_is_executing = true
	time_scale = 0.0

	if battler.is_player and battler.char_id != "friendly_hanbao":
		_is_player_menu_open = true
		time_scale = SLOW_TIME_SCALE
		player_needs_input.emit(battler)
	else:
		call_deferred("_deferred_enemy_action", battler)

func _deferred_enemy_action(battler) -> void:
	var alive_targets := battler_list.get_alive_players()
	if alive_targets.is_empty():
		_finish_action(battler)
		return

	var is_boss = battler.has_meta("is_boss") and battler.get_meta("is_boss")
	if is_boss and battler.char_id == "diren_laocong":
		await _boss_act(battler, alive_targets)
	else:
		await _default_enemy_act(battler, alive_targets)

	_finish_action(battler)

func submit_player_action(battler, action, targets: Array) -> void:
	_is_player_menu_open = false
	time_scale = 0.0
	await _execute_action(battler, action, targets)
	_finish_action(battler)

func _default_enemy_act(battler, alive_targets: Array) -> void:
	var action
	if battler.actions.size() > 0 and randf() < 0.3:
		action = battler.actions[randi() % battler.actions.size()]
	else:
		action = battler.get_basic_attack()
	battler.last_action_name = action.action_name

	var targets = action.get_possible_targets(battler, battler_list.get_alive_battlers())
	# 优先攻击我方汉堡
	var hanbaos: Array = (targets if not targets.is_empty() else alive_targets).filter(func(b):
		return b.char_id == "friendly_hanbao" and b.stats.health > 0
	)
	if not hanbaos.is_empty():
		targets = [hanbaos[randi() % hanbaos.size()]]
	elif targets.is_empty():
		targets = [alive_targets[randi() % alive_targets.size()]]

	await _execute_action(battler, action, targets)

func _boss_act(battler, alive_targets: Array) -> void:
	var hanbaos: Array = battler_list.enemies.filter(func(b):
		return b.char_id == "hanbao" and b.stats.health > 0
	)

	if hanbaos.size() > 0:
		for h in hanbaos:
			if h.has_meta("turns_alive") and h.get_meta("turns_alive") >= 2:
				battler.last_action_name = "吃掉汉堡"
				var heal_amount = h.stats.max_health * 2
				h.stats.health = 0
				var result := { "damage": 0, "heal": heal_amount, "crit": false, "hit": true,
					"messages": ["邪恶汉堡牢聪吃掉了汉堡，恢复了 %d HP!" % heal_amount], "effects": [] }
				action_executed.emit(battler, result)
				boss_eat_minion.emit(h)
				return

	if hanbaos.size() <= 3 and randf() < 0.5:
		battler.last_action_name = "召唤汉堡"
		boss_summon_requested.emit("hanbao")
		var result := { "damage": 0, "heal": 0, "crit": false, "hit": true,
			"messages": ["邪恶汉堡牢聪召唤了汉堡!"], "effects": [] }
		action_executed.emit(battler, result)
		return

	await _default_enemy_act(battler, alive_targets)

func _execute_action(battler, action, targets: Array) -> void:
	var result = await action.execute(battler, targets)
	if result == null:
		result = { "damage": 0, "heal": 0, "crit": false, "hit": false, "messages": [], "effects": [] }
	action_executed.emit(battler, result)

func _finish_action(battler) -> void:
	if battler.stats.health > 0:
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
	pass

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

## 暂停回合处理（波次切换时使用）
func pause() -> void:
	is_active = false

## 恢复回合处理，新敌人自动加入充能循环
func resume() -> void:
	is_active = true
