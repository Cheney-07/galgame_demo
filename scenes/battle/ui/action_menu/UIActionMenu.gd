# scenes/battle/ui/action_menu/UIActionMenu.gd
class_name UIActionMenu extends Control

signal action_selected(action: BattlerAction)
signal menu_closed()

func setup(battler, disabled_action_names: Array[String] = []) -> void:
	var btn_scene = load("res://scenes/battle/ui/action_menu/UIActionButton.tscn")
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	var atk_btn
	if btn_scene != null:
		atk_btn = btn_scene.instantiate()
	else:
		atk_btn = Button.new()
	atk_btn.text = "攻击"
	atk_btn.pressed.connect(func():
		_select_action(battler.get_basic_attack())
	)
	hbox.add_child(atk_btn)

	for a in battler.actions:
		if a == battler.get_basic_attack():
			continue
		var btn
		if btn_scene != null:
			btn = btn_scene.instantiate()
		else:
			btn = Button.new()
		btn.text = a.action_name
		var captured = a
		btn.pressed.connect(func():
			_select_action(captured)
		)
		hbox.add_child(btn)

	var def_btn
	if btn_scene != null:
		def_btn = btn_scene.instantiate()
	else:
		def_btn = Button.new()
	def_btn.text = "防御"
	def_btn.pressed.connect(func():
		_select_action(_create_defend_action())
	)
	hbox.add_child(def_btn)

	fade_in()

func _create_defend_action() -> BattlerAction:
	var action := BattlerAction.new()
	action.action_name = "防御"
	action.description = "本回合伤害减半"
	action.readiness_saved = 50.0
	action.target_scope = BattlerAction.TargetScope.SELF
	return action

func fade_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()

func _select_action(action: BattlerAction) -> void:
	action_selected.emit(action)
