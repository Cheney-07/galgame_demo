# 波次战斗系统 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 引入波次（Wave）系统，每波在场敌人数量受 `max_enemies_on_field` 限制，消灭当前波后自动刷新下一波，解决怪物溢出屏幕问题。

**Architecture:** 新增 `WaveData` Resource 定义每波敌人组合；修改 `CombatArena` 增加波次生成/切换逻辑；`BattlerList` 增加 `wave_cleared` 信号区分波清空与全灭；`ActiveTurnQueue` 增加暂停/恢复；`EncounterData` 增加 `waves` 数组和 `max_enemies_on_field`。

**Tech Stack:** Godot 4.7, GDScript

## Global Constraints

- 所有现有 encounter `.tres` 迁移到 waves 格式
- 每波在场敌人 ≤ `max_enemies_on_field`（encounter 自行配置）
- 波次切换：自动连续，延迟 0.8 秒
- Boss AI（召唤/吃汉堡）机制保持
- 战斗中可动态增删敌人（Boss 召唤机制）
- 向后兼容：无 waves 的旧 encounter 自动视为单波

---

## 文件结构

| 操作 | 文件 | 职责 |
|------|------|------|
| 新建 | `scenes/battle/encounters/WaveData.gd` | 单波敌人数据 Resource |
| 修改 | `scenes/battle/encounters/EncounterData.gd` | 增加 waves 字段，max_enemies_on_field |
| 修改 | `scenes/battle/queue/BattlerList.gd` | 增加 wave_cleared 信号 |
| 修改 | `scenes/battle/queue/ActiveTurnQueue.gd` | 增加 pause/resume 方法 |
| 修改 | `scenes/battle/arena/CombatArena.gd` | 波次生成/切换/位置排列核心逻辑 |
| 新建 | `scenes/battle/encounters/waves/*.tres` | 每波敌人数据文件 |
| 修改 | `scenes/battle/encounters/*.tres` | 迁移到 waves 格式 |

---

### Task 1: 创建 WaveData Resource

**Files:**
- Create: `scenes/battle/encounters/WaveData.gd`

**Produces:** `WaveData` class with `enemy_ids`, `enemy_counts`, `wave_message`

- [ ] **Step 1: 创建 WaveData.gd**

```gdscript
# scenes/battle/encounters/WaveData.gd
class_name WaveData extends Resource

## 单波敌人数据，由 EncounterData.waves 引用

@export var enemy_ids: Array[String] = []       # 本波敌人 ID 列表
@export var enemy_counts: Array[int] = []        # 对应数量
@export var wave_message: String = ""            # 波次提示（空=不显示）
```

- [ ] **Step 2: 验证** — 在 Godot 编辑器中确认 WaveData 可被 Inspector 识别

- [ ] **Step 3: 提交**
```bash
git add scenes/battle/encounters/WaveData.gd
git commit -m "feat: add WaveData resource class for wave-based encounters"
```

---

### Task 2: 修改 EncounterData — 增加 waves 字段

**Files:**
- Modify: `scenes/battle/encounters/EncounterData.gd`

**Consumes:** `WaveData` class from Task 1
**Produces:** `EncounterData.waves: Array[WaveData]`, `EncounterData.max_enemies_on_field: int`

- [ ] **Step 1: 修改 EncounterData.gd**

```gdscript
# scenes/battle/encounters/EncounterData.gd
class_name EncounterData extends Resource

@export var encounter_id: String = ""
@export var battle_type: String = "explore"
@export var background_path: String = "res://images/battle_bg.png"
@export var music_path: String = ""
@export var player_bg_path: String = ""
@export var enemy_ids: Array[String] = []        # [废弃] 使用 waves 替代
@export var enemy_counts: Array[int] = []         # [废弃] 使用 waves 替代
@export var is_boss: bool = false
@export var waves: Array[WaveData] = []           # 波次列表（新）
@export var max_enemies_on_field: int = 4         # 场上同时最多敌人数量
```

- [ ] **Step 2: 验证** — 在 Godot 编辑器中打开任意 EncounterData，确认新字段出现在 Inspector 中

- [ ] **Step 3: 提交**
```bash
git add scenes/battle/encounters/EncounterData.gd
git commit -m "feat: add waves & max_enemies_on_field fields to EncounterData"
```

---

### Task 3: 修改 BattlerList — 增加 wave_cleared 信号

**Files:**
- Modify: `scenes/battle/queue/BattlerList.gd`

**Produces:** `wave_cleared` signal, `_wave_mode` flag

- [ ] **Step 1: 修改 BattlerList.gd，增加 wave_cleared 信号**

将原文件替换为：

```gdscript
# scenes/battle/queue/BattlerList.gd
class_name BattlerList extends RefCounted

signal battlers_downed()
signal wave_cleared()       # 新增：当前波敌人全灭

var players: Array = []
var enemies: Array = []
var has_player_won := false
var wave_mode := false      # 波次模式开启时，_check_enemy_status 发 wave_cleared 而非 battlers_downed

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
	has_player_won = false
	battlers_downed.emit()

func _check_enemy_status() -> void:
	for e in enemies:
		if e.stats.health > 0:
			return
	has_player_won = true
	if wave_mode:
		wave_cleared.emit()
	else:
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

- [ ] **Step 2: 验证** — 逻辑检查，确认 `wave_mode=false` 时行为与原来完全一致

- [ ] **Step 3: 提交**
```bash
git add scenes/battle/queue/BattlerList.gd
git commit -m "feat: add wave_cleared signal to BattlerList for wave mode"
```

---

### Task 4: 修改 ActiveTurnQueue — 增加 pause/resume

**Files:**
- Modify: `scenes/battle/queue/ActiveTurnQueue.gd`

**Produces:** `pause()` / `resume()` 方法

- [ ] **Step 1: 在 ActiveTurnQueue.gd 末尾增加 pause/resume 方法**

在文件末尾（`_on_combat_end` 之后）添加：

```gdscript
## 暂停回合处理（波次切换时使用）
func pause() -> void:
	is_active = false

## 恢复回合处理，新敌人自动加入充能循环
func resume() -> void:
	is_active = true
```

- [ ] **Step 2: 验证** — 确认语法无错误

- [ ] **Step 3: 提交**
```bash
git add scenes/battle/queue/ActiveTurnQueue.gd
git commit -m "feat: add pause/resume to ActiveTurnQueue for wave transitions"
```

---

### Task 5: 修改 CombatArena — 波次生成核心逻辑

**Files:**
- Modify: `scenes/battle/arena/CombatArena.gd`

**Consumes:** WaveData (Task 1), EncounterData.waves (Task 2), BattlerList.wave_mode (Task 3), ActiveTurnQueue.pause/resume (Task 4)

**改动范围最大。** 具体改动如下：

- [ ] **Step 1: 新增成员变量**

在 `var _current_input_battler = null` 之后增加：

```gdscript
# 波次系统
var _waves: Array[WaveData] = []
var _max_enemies_on_field: int = 4
var _current_wave_index: int = 0
var _all_enemy_battlers: Array = []     # 所有波次的敌人（用于奖励结算）
var _wave_spawning := false             # 波次生成中标记
```

- [ ] **Step 2: 重构 start() 中的敌人创建部分**

将 `start()` 中创建敌人的代码（第 44-59 行）替换为波次初始化：

```gdscript
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
	
	# ── 创建玩家 battler ──
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
```

- [ ] **Step 3: 新增 _spawn_wave() 方法**

在 `_scale_sprite_to_height` 之后添加：

```gdscript
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
```

- [ ] **Step 4: 新增 _on_wave_cleared() 方法**

在 `_on_battler_depleted` 之后添加：

```gdscript
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
```

- [ ] **Step 5: 修改 _on_battle_ended() 中的经验计算**

将原来的经验/金币遍历从 `battler_list.enemies` 改为 `_all_enemy_battlers`：

```gdscript
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
```

- [ ] **Step 6: 修改 _on_boss_summon()**

Boss 召唤的敌人添加到 `battler_list.enemies`（当前波）和 `_all_enemy_battlers`（总奖励池），位置在现有敌人之后：

```gdscript
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
```

- [ ] **Step 7: _on_boss_eat() 保持不变** — 只从 enemies 移除，不从 _all_enemy_battlers 移除（奖励仍计入）

- [ ] **Step 8: 验证** — 运行 Godot 检查语法，无报错

- [ ] **Step 9: 提交**
```bash
git add scenes/battle/arena/CombatArena.gd
git commit -m "feat: implement wave-based enemy spawning in CombatArena"
```

---

### Task 6: 迁移 Encounter .tres 文件

创建 `waves/` 子目录，为每个 encounter 创建波次数据文件，然后修改原有 encounter 引用 waves。

- [ ] **Step 1: 创建目录，创建所有 WaveData .tres 文件**

目录：`scenes/battle/encounters/waves/`

**default_wave1.tres** (3只史莱姆):
```tres
[gd_resource type="Resource" script_class="WaveData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/battle/encounters/WaveData.gd" id="1"]

[resource]
script = ExtResource("1")
enemy_ids = Array[String](["slime", "slime"])
enemy_counts = Array[int]([2, 1])
```

**explore_wave1.tres** (4只):
enemy_ids=["slime","slime"], counts=[2,2]

**explore_wave2.tres** (3只):
enemy_ids=["hanbao"], counts=[3]

**quest_wave1.tres** (4只):
enemy_ids=["slime","slime"], counts=[2,2]

**quest_wave2.tres** (4只):
enemy_ids=["hanbao","bianbian"], counts=[2,2]

**special5_wave1.tres** (4只):
enemy_ids=["slime","slime"], counts=[2,2]

**special5_wave2.tres** (3只):
enemy_ids=["bianbian","bianbian"], counts=[1,2]

**special10_wave1.tres** (4只):
enemy_ids=["slime","slime"], counts=[2,2]

**special10_wave2.tres** (3只):
enemy_ids=["bianbian","hanbao"], counts=[2,1]

**special15_wave1.tres** (5只):
enemy_ids=["slime","slime"], counts=[3,2]

**special15_wave2.tres** (5只):
enemy_ids=["bianbian","hanbao"], counts=[3,2]

**special20_wave1.tres:**
根据现有 special_day20.tres 内容拆分

**special25_wave1.tres** (4只):
enemy_ids=["hanbao","hanbao"], counts=[2,2]

**special25_wave2.tres** (4只, Boss):
enemy_ids=["diren_laocong","hanbao"], counts=[1,3], wave_message="邪恶汉堡出现了！"

**special30_wave1.tres** (4只):
enemy_ids=["slime","bianbian"], counts=[2,2], wave_message="敌人出现！"

**special30_wave2.tres** (4只):
enemy_ids=["hanbao","hanbao","bianbian"], counts=[2,1,1], wave_message="增援来了！"

**special30_wave3.tres** (2只):
enemy_ids=["boss","hanbao"], counts=[1,1], wave_message="最终 Boss 出现！"

- [ ] **Step 2: 修改各 Encounter .tres 引用 waves**

`default_encounter.tres`:
```tres
[gd_resource type="Resource" script_class="EncounterData" load_steps=2 format=3]
[ext_resource type="Script" uid="uid://363dylmqt3g2" path="res://scenes/battle/encounters/EncounterData.gd" id="1"]

[resource]
script = ExtResource("1")
encounter_id = "default"
battle_type = "default"
background_path = "res://images/battle/bg_explore.png"
max_enemies_on_field = 4
waves = Array[Resource("res://scenes/battle/encounters/WaveData.gd")]([
    preload("res://scenes/battle/encounters/waves/default_wave1.tres")
])
```

`explore_encounter.tres`:
```tres
[gd_resource type="Resource" script_class="EncounterData" load_steps=2 format=3]
[ext_resource type="Script" uid="uid://363dylmqt3g2" path="res://scenes/battle/encounters/EncounterData.gd" id="1"]

[resource]
script = ExtResource("1")
encounter_id = "explore_default"
battle_type = "explore"
background_path = "res://images/battle/bg_explore.png"
max_enemies_on_field = 4
waves = Array[Resource("res://scenes/battle/encounters/WaveData.gd")]([
    preload("res://scenes/battle/encounters/waves/explore_wave1.tres"),
    preload("res://scenes/battle/encounters/waves/explore_wave2.tres")
])
```

其他 encounter 同理类推。

- [ ] **Step 3: 验证** — 在 Godot 编辑器中逐一打开 encounter 确认 waves 正确加载

- [ ] **Step 4: 提交**
```bash
git add scenes/battle/encounters/waves/ scenes/battle/encounters/*.tres
git commit -m "feat: migrate all encounters to wave-based format"
```

---

### Task 7: 运行游戏验证

- [ ] **Step 1: 启动游戏，测试 day 5 特殊战斗**
  - 确认敌人分波出现（每波 ≤ 4 个）
  - 确认波次提示显示
  - 确认消灭一波后 0.8s 自动刷新下一波
  - 确认全部消灭后正常战后结算

- [ ] **Step 2: 测试 Boss 召唤机制（day 25）**
  - 确认 Boss 能在当前波中动态召唤汉堡
  - 确认召唤的敌人位置正确、在屏幕范围内
  - 确认召唤敌人死亡也计入波次检测

- [ ] **Step 3: 测试向后兼容**
  - 临时修改一个 encounter 清空 waves、填充旧的 enemy_ids

- [ ] **Step 4: 提交（如有修正）**
