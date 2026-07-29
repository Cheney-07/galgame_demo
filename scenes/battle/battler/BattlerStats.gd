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
@export var base_cha := 10

var max_health := base_max_health
var attack := base_attack
var magic_attack := base_magic_attack
var defense := base_defense
var speed := base_speed
var hit_chance := base_hit_chance
var evasion := base_evasion
var cha := base_cha

var health := max_health:
	set(value):
		health = clampi(value, 0, max_health)
		health_changed.emit()
		if health <= 0:
			health_depleted.emit()

var guard := false

signal health_changed()
signal health_depleted()

var _modifiers := {}
var _multipliers := {}
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
	base_cha = char_data.get_stat("CHA")
	_refresh_all()

func init_from_enemy(template) -> void:
	base_max_health = template.hp
	base_attack = template.str
	base_magic_attack = template.mag
	base_defense = template.vit
	base_speed = template.agi
	base_hit_chance = 80 + template.tec * 2
	base_evasion = template.agi / 2
	base_cha = template.cha
	_refresh_all()

func _refresh_all() -> void:
	for key in ["max_health", "attack", "magic_attack", "defense", "speed", "hit_chance", "evasion", "cha"]:
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
	if not _modifiers.has(stat_name):
		_modifiers[stat_name] = {}
		_multipliers[stat_name] = {}
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
