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
