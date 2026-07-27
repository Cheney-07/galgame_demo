# scenes/battle/encounters/WaveData.gd
class_name WaveData extends Resource

## 单波敌人数据，由 EncounterData.waves 引用

@export var enemy_ids: Array[String] = []       # 本波敌人 ID 列表
@export var enemy_counts: Array[int] = []        # 对应数量
@export var wave_message: String = ""            # 波次提示（空=不显示）
