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
