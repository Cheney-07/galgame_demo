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
	has_player_won = false
	battlers_downed.emit()

func _check_enemy_status() -> void:
	for e in enemies:
		if e.stats.health > 0:
			return
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
