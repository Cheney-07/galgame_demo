extends Node

## PartyData — 角色队伍数据
## 从 Resource .tres 加载角色模板，管理运行时属性/等级/好感度

enum Stat { STR, MAG, VIT, AGI, TEC, CHA }

# ----------------------------------------------------------------------
# CharacterData — 运行时角色实例
# ----------------------------------------------------------------------
class CharacterData:
	var template: Resource = null
	var char_id: String = ""
	var char_name: String = ""

	var level: int = 1
	var current_exp: int = 0

	var stats: Dictionary = {}
	var growth_rates: Dictionary = {}
	var skill_pool: Array[String] = []
	var equipment: Dictionary = {
		"weapon": null, "armor": null, "accessory": null
	}
	var active_buffs: Array = []
	var battle_portrait: String = ""
	var affection: int = 0
	var portrait_path: String = ""

	func init_from_template(tpl: Resource) -> void:
		template = tpl
		char_id = tpl.get("char_id") if tpl.has_method("get") else ""
		char_name = tpl.get("char_name") if tpl.has_method("get") else ""
		portrait_path = tpl.get("portrait_path") if tpl.has_method("get") else ""
		battle_portrait = tpl.get("battle_portrait") if tpl.has_method("get") else ""
		if tpl.has_method("get"):
			stats = tpl.get("base_stats").duplicate() if tpl.get("base_stats") else {"STR":10,"MAG":10,"VIT":10,"AGI":10,"TEC":10,"CHA":10}
			growth_rates = tpl.get("growth_rates").duplicate() if tpl.get("growth_rates") else {"STR":1.0,"MAG":1.0,"VIT":1.0,"AGI":1.0,"TEC":1.0,"CHA":1.0}
			var sp = tpl.get("skill_pool")
			skill_pool = sp.duplicate() if sp else []

	func get_base_stat(stat: String) -> int:
		return stats.get(stat, 10)

	func get_stat(stat: String) -> int:
		var val: int = stats.get(stat, 10)
		for buff in active_buffs:
			if buff.get("stat", "") == stat:
				val += buff.get("value", 0)
		return max(val, 1)

	func get_max_hp() -> int:
		return 100 + int(get_base_stat("VIT") * 15.0 * (1.0 + (level - 1) * 0.1))

	func add_exp(amount: int) -> bool:
		current_exp += amount
		var leveled: bool = false
		var required: int = level * 100
		while current_exp >= required:
			current_exp -= required
			level += 1
			_level_up()
			leveled = true
			required = level * 100
		return leveled

	func _level_up() -> void:
		for st in growth_rates:
			stats[st] += int(growth_rates[st])
		print("[PartyData] ", char_name, " leveled up to Lv.", level)

	func serialize() -> Dictionary:
		return {
			"char_id": char_id,
			"level": level,
			"current_exp": current_exp,
			"stats": stats,
			"skill_pool": skill_pool,
			"affection": affection,
		}

	func deserialize(data: Dictionary) -> void:
		level = data.get("level", 1)
		current_exp = data.get("current_exp", 0)
		if data.has("stats"):
			for k in data["stats"]:
				stats[k] = data["stats"][k]
		var sp: Array = data.get("skill_pool", [])
		skill_pool.clear()
		for sk in sp:
			skill_pool.append(str(sk))
		affection = data.get("affection", 0)

# ----------------------------------------------------------------------
# 技能注册表
# ----------------------------------------------------------------------
var skill_registry: Dictionary = {}

# 敌人注册表
var enemy_registry: Dictionary = {}     # enemy_id -> EnemyTemplate
var encounter_registry: Dictionary = {}  # battle_type -> EncounterData

# ----------------------------------------------------------------------
# 角色字典
# ----------------------------------------------------------------------
var characters: Dictionary = {}

signal stat_changed(char_id: String, stat: String, new_value: int)
signal char_level_up(char_id: String, new_level: int)
signal affection_changed(char_id: String, new_value: int)

# ----------------------------------------------------------------------
# Init
# ----------------------------------------------------------------------
func _ready() -> void:
	_load_skill_registry()
	_load_character_templates()
	_load_enemy_templates()
	_load_encounter_data()
	print("[PartyData] Initialized with ", characters.size(), " characters, ", skill_registry.size(), " skills, ", enemy_registry.size(), " enemies, ", encounter_registry.size(), " encounters.")

# 重置到模板初始状态
func reset() -> void:
	characters.clear()
	_load_character_templates()
	print("[PartyData] Reset to template defaults.")


func _load_skill_registry() -> void:
	var dir: String = "res://resources/skills/"
	var files: PackedStringArray = _list_files(dir, ".tres")
	for f in files:
		var res: Resource = load(dir + f)
		if res == null or not res.has_method("get") or res.get("skill_id") == "":
			continue
		if res.get("skill_id") != null:
			skill_registry[res.get("skill_id")] = res
			print("[PartyData] Loaded skill: ", res.get("skill_id"))


func _load_character_templates() -> void:
	var dir: String = "res://resources/characters/"
	var files: PackedStringArray = _list_files(dir, ".tres")
	for f in files:
		if f.ends_with("_template.gd"):
			continue
		var res: Resource = load(dir + f)
		if res == null or not res.has_method("get"):
			continue
		if res.get("char_id") != null and res.get("char_id") != "":
			var c: CharacterData = CharacterData.new()
			c.init_from_template(res)
			characters[c.char_id] = c
			print("[PartyData] Loaded character: ", c.char_name, " (", c.char_id, ")")


func _list_files(dir: String, ext: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var da: DirAccess = DirAccess.open(dir)
	if da == null:
		return out
	da.list_dir_begin()
	var fn: String = da.get_next()
	while not fn.is_empty():
		if not da.current_is_dir() and fn.ends_with(ext):
			out.append(fn)
		fn = da.get_next()
	da.list_dir_end()
	return out


# ----------------------------------------------------------------------
# 查询方法
# ----------------------------------------------------------------------
func get_character(char_id: String) -> CharacterData:
	return characters.get(char_id, null)


func get_skill(skill_id: String) -> Resource:
	return skill_registry.get(skill_id, null)


func get_all_character_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in characters:
		ids.append(k)
	return ids


# ----------------------------------------------------------------------
# 养成方法
# ----------------------------------------------------------------------
func modify_stat(char_id: String, stat: String, amount: int) -> void:
	var c: CharacterData = get_character(char_id)
	if c == null:
		return
	c.stats[stat] = max(0, c.stats[stat] + amount)
	stat_changed.emit(char_id, stat, c.stats[stat])


func add_affection(char_id: String, amount: int) -> void:
	var c: CharacterData = get_character(char_id)
	if c == null:
		return
	c.affection = max(0, c.affection + amount)
	affection_changed.emit(char_id, c.affection)


# ----------------------------------------------------------------------
# 序列化
# ----------------------------------------------------------------------
func serialize() -> Dictionary:
	var data: Dictionary = {}
	for id in characters:
		data[id] = characters[id].serialize()
	return data


func deserialize(data: Dictionary) -> void:
	for id in data:
		if characters.has(id):
			characters[id].deserialize(data[id])
	print("[PartyData] State deserialized.")

# ----------------------------------------------------------------------
# 敌人/遭遇注册表
# ----------------------------------------------------------------------
func _load_enemy_templates() -> void:
	var dir := "res://scenes/battle/enemies/"
	var files := _list_files(dir, ".tres")
	for f in files:
		if f.ends_with("EnemyTemplate.gd"):
			continue
		var res: Resource = load(dir + f)
		if res == null or res.get("enemy_id") == null:
			continue
		if res.enemy_id != "":
			enemy_registry[res.enemy_id] = res
			print("[PartyData] Loaded enemy: ", res.enemy_name)

func _load_encounter_data() -> void:
	var dir := "res://scenes/battle/encounters/"
	var files := _list_files(dir, ".tres")
	for f in files:
		var res: Resource = load(dir + f)
		if res == null or res.get("battle_type") == null:
			continue
		encounter_registry[res.battle_type] = res
		# Also register by encounter_id so special_day lookups work
		if res.encounter_id and not res.encounter_id.is_empty():
			encounter_registry[res.encounter_id] = res
		print("[PartyData] Loaded encounter: ", res.encounter_id)

func get_enemy(enemy_id: String):
	return enemy_registry.get(enemy_id, null)

func get_encounter(battle_type: String):
	if battle_type == "special":
		var day_key = "special_day" + str(GameState.current_day)
		return encounter_registry.get(day_key, encounter_registry.get("special_day5", encounter_registry.get("default", null)))
	return encounter_registry.get(battle_type, encounter_registry.get("default", null))
