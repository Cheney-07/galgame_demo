class_name CharacterTemplate
extends Resource

## CharacterTemplate — 角色数据模板 Resource
## 在编辑器里可以点开 .tres 直接修改属性
@export var char_id: String = ""
@export var char_name: String = ""
@export_multiline var description: String = ""
@export var portrait_path: String = ""
@export var battle_portrait: String = ""
@export var base_stats: Dictionary = {
	"STR": 10, "MAG": 10, "VIT": 10, "AGI": 10, "TEC": 10, "CHA": 10
}
@export var growth_rates: Dictionary = {
	"STR": 1.0, "MAG": 1.0, "VIT": 1.0, "AGI": 1.0, "TEC": 1.0, "CHA": 1.0
}
@export var skill_pool: Array[String] = []
@export var battle_role: String = "attacker"

func calculate_hp(level: int) -> int:
	return 100 + int(base_stats["VIT"] * 15.0 * (1.0 + (level - 1) * 0.1))

func get_init_stat(stat: String) -> int:
	return base_stats.get(stat, 10)
