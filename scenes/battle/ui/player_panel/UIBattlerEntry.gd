# scenes/battle/ui/player_panel/UIBattlerEntry.gd
class_name UIBattlerEntry extends Control

@onready var name_label := $NameLabel as Label
@onready var hp_bar_bg := $HPBarBg as ColorRect
@onready var hp_bar_fg := $HPBarBg/HPBarFg as ColorRect
@onready var hp_label := $HPLabel as Label
@onready var icon := $Icon as TextureRect

func setup(battler) -> void:
	name_label.text = battler.display_name
	icon.texture = battler.icon_texture

	battler.stats.health_changed.connect(func():
		_update_hp(battler)
	)
	_update_hp(battler)

func _update_hp(battler) -> void:
	var pct = clamp(float(battler.stats.health) / float(battler.stats.max_health), 0.0, 1.0)
	hp_bar_fg.custom_minimum_size.x = hp_bar_bg.size.x * pct
	hp_label.text = str(battler.stats.health) + "/" + str(battler.stats.max_health)

	if pct < 0.25:
		hp_bar_fg.color = Color(0.9, 0.2, 0.2)
	elif pct < 0.5:
		hp_bar_fg.color = Color(0.9, 0.7, 0.2)
	else:
		hp_bar_fg.color = Color(0.2, 0.9, 0.2)
