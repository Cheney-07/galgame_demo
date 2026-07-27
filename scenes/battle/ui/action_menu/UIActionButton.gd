# scenes/battle/ui/action_menu/UIActionButton.gd
class_name UIActionButton extends Button

var action_ref:
	set(value):
		action_ref = value
		if action_ref:
			text = action_ref.action_name
			tooltip_text = action_ref.description
