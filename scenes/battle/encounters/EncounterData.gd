# scenes/battle/encounters/EncounterData.gd
class_name EncounterData extends Resource

@export var encounter_id: String = ""
@export var battle_type: String = "explore"
@export var background_path: String = "res://images/battle_bg.png"
@export var music_path: String = ""
@export var player_bg_path: String = ""
@export var enemy_ids: Array[String] = []        # enemy_id list
@export var enemy_counts: Array[int] = []         # corresponding counts
@export var is_boss: bool = false
