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
