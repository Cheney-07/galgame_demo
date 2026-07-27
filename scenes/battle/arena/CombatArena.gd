# scenes/battle/arena/CombatArena.gd
class_name CombatArena extends Control

const WaveDataRef = preload("res://scenes/battle/encounters/WaveData.gd")

signal combat_finished(result: Dictionary)

var turn_queue: ActiveTurnQueue = null
var battler_list: BattlerList = null
var _player_battlers: Array = []
var _enemy_battlers: Array = []
var _current_input_battler = null

# 波次系统
var _waves: Array[WaveData] = []
var _max_enemies_on_field: int = 4
var _current_wave_index: int = 0
var _all_enemy_battlers: Array = []     # 所有波次的敌人（用于奖励结算）
var _wave_spawning := false             # 波次生成中标记

@onready var background := $Background as TextureRect
@onready var battler_container := $BattlerContainer as Node2D
@onready var ui_turn_bar := $UI/TurnBar
@onready var ui_player_list := $UI/PlayerList
@onready var ui_cursor_anchor := $UI/CursorAnchor as Control
@onready var ui_damage_container := $UI/DamageContainer as Control

func start(squad: Array[String], encounter) -> void:
	if encounter == null:
		push_error("[CombatArena] encounter is null!")
		return

	if ResourceLoader.exists(encounter.background_path):
		background.texture = load(encounter.background_path)

	# 创建玩家 battler
	_player_battlers.clear()
	var char_ids := squad.duplicate()
	if char_ids.is_empty():
		char_ids = PartyData.get_all_character_ids()
		char_ids = char_ids.slice(0, 3)

	for i in char_ids.size():
		var char_data = PartyData.get_character(char_ids[i])
		if char_data == null:
			continue
		var battler := _create_player_battler(char_data)
		battler.position = Vector2(150, 180 + i * 140)
		battler_container.add_child(battler)
		_player_battlers.append(battler)

	# ── 解析波次数据 ──
	_waves.clear()
	_all_enemy_battlers.clear()
	_current_wave_index = 0
	_wave_spawning = false

	if encounter.waves and not encounter.waves.is_empty():
		_waves = encounter.waves
		_max_enemies_on_field = encounter.max_enemies_on_field
	else:
		# 向后兼容：旧格式自动转单波
		var w := WaveData.new()
		w.enemy_ids = encounter.enemy_ids
		w.enemy_counts = encounter.enemy_counts
		_waves = [w]
		_max_enemies_on_field = 4

	# ── 创建 BattlerList（敌人初始为空，通过 _spawn_wave 填充）──
	battler_list = BattlerList.new(_player_battlers, [])
	battler_list.wave_mode = true
	battler_list.wave_cleared.connect(_on_wave_cleared)

	# ── 连接死亡动画 ──
	for b in battler_list.get_all_battlers():
		b.stats.health_depleted.connect(_on_battler_depleted.bind(b))

	# ── 设置 TurnQueue ──
	turn_queue = ActiveTurnQueue.new()
	add_child(turn_queue)
	turn_queue.setup(battler_list)

	# 连接信号
	turn_queue.player_needs_input.connect(_on_player_needs_input)
	turn_queue.action_executed.connect(_on_action_executed)
	turn_queue.battle_ended.connect(_on_battle_ended)

	if encounter.is_boss:
		turn_queue.boss_summon_requested.connect(_on_boss_summon)
		turn_queue.boss_eat_minion.connect(_on_boss_eat)

	if ui_turn_bar and ui_turn_bar.has_method("setup"):
		ui_turn_bar.setup(battler_list)
	if ui_player_list and ui_player_list.has_method("setup"):
		ui_player_list.setup(battler_list)
	if ui_turn_bar and ui_turn_bar.has_method("fade_in"):
		ui_turn_bar.fade_in()

	# 生成第一波敌人
	_spawn_wave(0)

	turn_queue.is_active = true

func _add_hp_bar(battler, y_offset: float) -> void:
	var bg = ColorRect.new()
	bg.name = "HPBg"
	bg.color = Color(0.2, 0.1, 0.1)
	bg.position = Vector2(-50, y_offset)
	bg.size = Vector2(100, 8)
	battler.add_child(bg)

	var fg = ColorRect.new()
	fg.name = "HPFg"
	fg.color = Color(0.2, 0.9, 0.2)
	fg.size = Vector2(100, 8)
	bg.add_child(fg)

	battler.stats.health_changed.connect(func():
		if not is_instance_valid(fg):
			return
		var pct = clamp(float(battler.stats.health) / float(battler.stats.max_health), 0.0, 1.0)
		fg.size.x = 100.0 * pct
		if pct < 0.25:
			fg.color = Color(0.9, 0.2, 0.2)
		elif pct < 0.5:
			fg.color = Color(0.9, 0.7, 0.2)
	)

func _create_player_battler(char_data) -> Battler:
	var battler = load("res://scenes/battle/battler/Battler.tscn").instantiate()
	var stats = BattlerStats.new()
	stats.init_from_character(char_data)
	battler.setup_stats(stats)
	battler.is_player = true
	battler.char_id = char_data.char_id
	battler.display_name = char_data.char_name

	var sprite_path = "res://images/battle/sprites/" + char_data.char_id + ".png"
	if ResourceLoader.exists(sprite_path):
		battler.sprite = Sprite2D.new()
		battler.sprite.texture = load(sprite_path)
		_scale_sprite_to_height(battler.sprite, 120.0)
		battler.add_child(battler.sprite)
		_add_hp_bar(battler, -75.0)

	var icon_path = "res://images/battle/icons/" + char_data.char_id + ".png"
	if ResourceLoader.exists(icon_path):
		battler.icon_texture = load(icon_path)

	var has_attack := false
	for sid in char_data.skill_pool:
		var skill_res = PartyData.get_skill(sid)
		if skill_res:
			var action = ActionFactory.from_skill_data(skill_res)
			if action:
				battler.actions.append(action)
		if sid == "weapon_attack":
			has_attack = true
	if not has_attack:
		battler.actions.append(ActionFactory.create_basic_attack())

	return battler

func _create_enemy_battler(template) -> Battler:
	var battler = load("res://scenes/battle/battler/Battler.tscn").instantiate()
	var stats = BattlerStats.new()
	stats.init_from_enemy(template)
	battler.setup_stats(stats)
	battler.is_player = false
	battler.char_id = template.enemy_id
	battler.display_name = template.enemy_name
	battler.set_meta("exp_reward", template.exp_reward)
	battler.set_meta("gold_reward", template.gold_reward)
	if template.enemy_id == "diren_laocong":
		battler.set_meta("is_boss", true)

	var sprite_path = template.sprite_path
	if sprite_path.is_empty():
		sprite_path = "res://images/battle/sprites/" + template.enemy_id + ".png"
	if ResourceLoader.exists(sprite_path) and not sprite_path.is_empty():
		battler.sprite = Sprite2D.new()
		battler.sprite.texture = load(sprite_path)
		_scale_sprite_to_height(battler.sprite, 120.0)
		battler.add_child(battler.sprite)
		_add_hp_bar(battler, -80.0)

	var icon_path = template.icon_path
	if icon_path.is_empty():
		icon_path = "res://images/battle/icons/" + template.enemy_id + ".png"
	if ResourceLoader.exists(icon_path):
		battler.icon_texture = load(icon_path)
	else:
		if battler.sprite and battler.sprite.texture:
			battler.icon_texture = battler.sprite.texture

	battler.actions.append(ActionFactory.create_basic_attack())
	for sid in template.skills:
		var skill_res = PartyData.get_skill(sid)
		if skill_res:
			var action = ActionFactory.from_skill_data(skill_res)
			if action:
				battler.actions.append(action)

	return battler

func _scale_sprite_to_height(sprite: Sprite2D, target_height: float) -> void:
	var tex_size = sprite.texture.get_size()
	if tex_size.y > 0:
		var scale_factor = target_height / tex_size.y
		sprite.scale = Vector2(scale_factor, scale_factor)

func _spawn_wave(index: int) -> void:
	if index >= _waves.size():
		return

	_wave_spawning = true
	var wave_data: WaveData = _waves[index]

	# 清除旧的敌人列表（准备填充新波次敌人）
	battler_list.enemies.clear()

	var enemy_idx := 0
	for j in wave_data.enemy_ids.size():
		var eid := wave_data.enemy_ids[j]
		var count := wave_data.enemy_counts[j] if j < wave_data.enemy_counts.size() else 1
		var template = PartyData.get_enemy(eid)
		if template == null:
			continue
		for k in count:
			var battler := _create_enemy_battler(template)
			battler.position = _get_enemy_position(enemy_idx)
			battler_container.add_child(battler)
			battler_list.enemies.append(battler)
			_all_enemy_battlers.append(battler)
			battler.stats.health_depleted.connect(_on_battler_depleted.bind(battler))
			battler.stats.health_depleted.connect(func(): battler_list._check_enemy_status())
			enemy_idx += 1

	# 连接 BattlerList 玩家状态检查（新敌人需要重新绑定）
	for p in battler_list.players:
		if not p.stats.health_depleted.is_connected(battler_list._check_player_status):
			p.stats.health_depleted.connect(battler_list._check_player_status)

	# 波次提示文字
	if not wave_data.wave_message.is_empty():
		var msg_label := Label.new()
		msg_label.text = wave_data.wave_message
		msg_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		msg_label.position = Vector2(0, 20)
		msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		msg_label.add_theme_font_size_override("font_size", 32)
		add_child(msg_label)
		# 2秒后淡出
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(msg_label, "modulate:a", 0.0, 1.0)
		tw.tween_callback(msg_label.queue_free)

	print("[CombatArena] Wave ", index + 1, "/", _waves.size(), " spawned with ", enemy_idx, " enemies")
	_wave_spawning = false


func _get_enemy_position(index: int) -> Vector2:
	"""根据 max_enemies_on_field 在右侧固定区域排列"""
	var max_per_row := mini(3, _max_enemies_on_field)
	var col := index % max_per_row
	var row := int(index / max_per_row)
	return Vector2(700 + col * 170, 120 + row * 160)

func _on_battler_depleted(battler) -> void:
	if is_instance_valid(battler):
		battler.set_meta("dead", true)
		var tween = create_tween()
		tween.tween_property(battler, "modulate", Color(1, 1, 1, 0), 0.5)
		await tween.finished
		battler.visible = false

func _on_wave_cleared() -> void:
	if _wave_spawning:
		return

	_current_wave_index += 1

	if _current_wave_index < _waves.size():
		# 还有下一波：暂停回合，延迟刷新
		if turn_queue:
			turn_queue.pause()
		# 更新 turn_bar 显示（新敌人即将出现）
		if ui_turn_bar and ui_turn_bar.has_method("fade_out"):
			ui_turn_bar.fade_out()
		await get_tree().create_timer(0.8).timeout
		_spawn_wave(_current_wave_index)
		# 刷新 turn_bar
		if ui_turn_bar and ui_turn_bar.has_method("setup"):
			ui_turn_bar.setup(battler_list)
		if ui_turn_bar and ui_turn_bar.has_method("fade_in"):
			ui_turn_bar.fade_in()
		if turn_queue:
			turn_queue.resume()
	else:
		# 所有波次完成 → 触发战斗胜利
		battler_list.wave_mode = false
		battler_list.battlers_downed.emit()

func _on_player_needs_input(battler) -> void:
	_current_input_battler = battler
	var menu = UIActionMenu.new()
	menu.setup(battler)
	menu.position = Vector2(100, 620)
	menu.custom_minimum_size = Vector2(1720, 70)
	add_child(menu)
	menu.action_selected.connect(func(action: BattlerAction):
		menu.queue_free()
		_on_action_chosen(battler, action)
	)

func _on_action_chosen(battler, action: BattlerAction) -> void:
	if action.target_scope == BattlerAction.TargetScope.SELF:
		battler.last_action_name = action.action_name
		if action.action_name == "防御":
			battler.stats.guard = true
		turn_queue.submit_player_action(battler, action, [battler])
		return

	var targets = action.get_possible_targets(battler, battler_list.get_alive_battlers())
	if targets.size() == 0:
		targets = battler_list.get_alive_players()  # fallback
	if targets.size() == 0:
		return

	var cursor = load("res://scenes/battle/ui/targeting/UIBattlerTargetingCursor.tscn")
	if cursor == null:
		return
	cursor = cursor.instantiate()
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
	if result["damage"] > 0:
		var label = load("res://scenes/battle/ui/effects/UIDamageLabel.tscn").instantiate()
		ui_damage_container.add_child(label)
		var targets = battler_list.get_alive_enemies()
		if targets.size() > 0:
			var t = targets[randi() % targets.size()]
			label.position = t.position + Vector2(-30, -30)
		label.show_damage(result["damage"], result.get("crit", false))

	if result["heal"] > 0:
		var label = load("res://scenes/battle/ui/effects/UIDamageLabel.tscn").instantiate()
		ui_damage_container.add_child(label)
		label.position = Vector2(200, 300)
		label.show_heal(result["heal"])

	if not result.get("hit", true):
		var label = load("res://scenes/battle/ui/effects/UIDamageLabel.tscn").instantiate()
		ui_damage_container.add_child(label)
		label.position = Vector2(800, 400)
		label.show_miss()

func _on_boss_summon(template_id: String) -> void:
	var template = PartyData.get_enemy(template_id)
	if template == null:
		return
	var battler = _create_enemy_battler(template)
	var pos_idx := battler_list.enemies.size()
	battler.position = _get_enemy_position(pos_idx)
	battler.set_meta("summoned", true)
	battler.set_meta("turns_alive", 0)
	battler_container.add_child(battler)
	battler_list.enemies.append(battler)
	_all_enemy_battlers.append(battler)
	battler.stats.health_depleted.connect(_on_battler_depleted.bind(battler))
	battler.stats.health_depleted.connect(func(): battler_list._check_enemy_status())

func _on_boss_eat(minion) -> void:
	battler_list.enemies.erase(minion)
	if is_instance_valid(minion):
		minion.queue_free()

func _on_battle_ended(result: Dictionary) -> void:
	ui_turn_bar.fade_out()
	ui_player_list.fade_out()

	if result.get("won", false):
		_show_result_text("胜利!")
		for p in _player_battlers:
			var char_data = PartyData.get_character(p.char_id)
			if char_data:
				char_data.add_exp(result.get("exp", 0))
		await get_tree().create_timer(1.5).timeout
		_play_special_aftermath(true)
	else:
		_show_result_text("战斗失败...")
		GameState.record_death()
		await get_tree().create_timer(1.5).timeout
		_play_special_aftermath(false)

func _show_result_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	label.add_theme_font_size_override("font_size", 28)
	add_child(label)

func _play_special_aftermath(won: bool) -> void:
	GameState.set_game_phase("vn")
	var timeline = "res://resources/dialogic/timelines/special_battles.dtl"
	if GameState.battle_type == "special":
		var day = str(GameState.current_day)
		if won:
			GameState.mark_special_battle_won()
			GameState.last_battle_won = true
			var label = "special_post_day" + day + "_win"
			DialogicBridge.start_timeline(timeline, label)
		else:
			GameState.last_battle_won = false
			var label = "special_post_day" + day + "_lose"
			DialogicBridge.start_timeline(timeline, label)
	else:
		GameState.set_game_phase("vn")
		var scene_id := "battle_victory_" + GameState.battle_type
		DialogicBridge.start_timeline("res://resources/dialogic/timelines/battle_results.dtl", scene_id)
