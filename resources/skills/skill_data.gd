class_name SkillData
extends Resource

## SkillData — 技能数据模板 Resource

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_type: String = "damage"       # damage / heal / buff / debuff / special
@export var target_type: String = "single_enemy" # single_enemy / all_enemies / single_ally / all_allies / self
@export var power: float = 1.0                  # 威力倍率
@export var stat_scale: String = "STR"           # 伤害/治疗关联属性
@export var hit_count: int = 1                   # 多段攻击段数（>1 时为多段）
@export var cooldown: int = 0                    # 冷却回合
@export var effects: Array[Dictionary] = []       # Buff/Debuff 效果
@export var description: String = ""
@export var icon_path: String = ""
