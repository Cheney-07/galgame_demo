const fs = require('fs');
let content = fs.readFileSync('E:/gamedemo1/scenes/menu/MainMenu.gd', 'utf8');

// Update _create_load_screen to use SaveManager for slot info
const oldLoadScreen = [
    '\tvar SLOT_COUNT := 9',
    '\tvar grid := GridContainer.new()',
    '\tgrid.columns = 3',
    '\tgrid.add_theme_constant_override("h_separation", 12)',
    '\tgrid.add_theme_constant_override("v_separation", 12)',
    '',
    '\tfor i in SLOT_COUNT:',
    '\t\tvar slot_name := "slot_" + str(i)',
    '\t\tvar btn := Button.new()',
    '\t\tbtn.custom_minimum_size = Vector2(170, 80)',
    '\t\tbtn.add_theme_font_size_override("font_size", 13)',
    '\t\tbtn.focus_mode = Control.FOCUS_NONE',
    '',
    '\t\tif Dialogic.Save.has_slot(slot_name):',
    '\t\t\tvar info: Dictionary = Dialogic.Save.get_slot_info(slot_name)',
    '\t\t\tvar extra: Dictionary = info.get("extra", {})',
    '\t\t\tvar timestamp: String = str(extra.get("date", info.get("timestamp", "")))',
    '\t\t\tvar chapter: int = extra.get("chapter", 0)',
    '\t\t\tvar day: int = extra.get("day", 1)',
    '\t\t\tbtn.text = "栏位 " + str(i + 1) + "\\n" + timestamp + "\\n第" + str(chapter + 1) + "章 第" + str(day) + "天"',
    '\t\t\tbtn.add_theme_color_override("font_color", Color(1, 1, 1))',
    '\t\t\tbtn.add_theme_stylebox_override("normal", _flat_stylebox(Color(0.15, 0.15, 0.25, 0.85)))',
    '\t\t\tbtn.pressed.connect(_do_load_from_menu.bind(slot_name))',
    '\t\telse:',
    '\t\t\tbtn.text = "空栏位 " + str(i + 1)',
    '\t\t\tbtn.disabled = true',
    '\t\t\tbtn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))',
    '\t\t\tbtn.add_theme_stylebox_override("normal", _flat_stylebox(Color(0.1, 0.1, 0.15, 0.7)))',
].join('\n');

const newLoadScreen = [
    '\tvar SLOT_COUNT := 9',
    '\tvar grid := GridContainer.new()',
    '\tgrid.columns = 3',
    '\tgrid.add_theme_constant_override("h_separation", 12)',
    '\tgrid.add_theme_constant_override("v_separation", 12)',
    '',
    '\tfor i in SLOT_COUNT:',
    '\t\tvar slot_name := "slot_" + str(i)',
    '\t\tvar btn := Button.new()',
    '\t\tbtn.custom_minimum_size = Vector2(170, 80)',
    '\t\tbtn.add_theme_font_size_override("font_size", 13)',
    '\t\tbtn.focus_mode = Control.FOCUS_NONE',
    '',
    '\t\tif SaveManager.has_slot(i):',
    '\t\t\tvar info: Dictionary = SaveManager.get_slot_info(i)',
    '\t\t\tbtn.text = "栏位 " + str(i + 1) + "\\n" + str(info.get("timestamp", "")) + "\\n第" + str(info.get("chapter", 0) + 1) + "章 第" + str(info.get("day", 1)) + "天"',
    '\t\t\tbtn.add_theme_color_override("font_color", Color(1, 1, 1))',
    '\t\t\tbtn.add_theme_stylebox_override("normal", _flat_stylebox(Color(0.15, 0.15, 0.25, 0.85)))',
    '\t\t\tbtn.pressed.connect(_do_load_from_menu.bind(slot_name))',
    '\t\telse:',
    '\t\t\tbtn.text = "空栏位 " + str(i + 1)',
    '\t\t\tbtn.disabled = true',
    '\t\t\tbtn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))',
    '\t\t\tbtn.add_theme_stylebox_override("normal", _flat_stylebox(Color(0.1, 0.1, 0.15, 0.7)))',
].join('\n');

if (content.includes(oldLoadScreen)) {
    content = content.replace(oldLoadScreen, newLoadScreen);
    console.log('OK: _create_load_screen updated');
} else {
    console.log('ERROR: _create_load_screen pattern not found');
}

// Update _do_load_from_menu to check SaveManager first
const oldLoadFn = [
    'func _do_load_from_menu(slot_name: String) -> void:',
    '\tif not Dialogic.Save.has_slot(slot_name):',
    '\t\treturn',
    '\tGameState.pending_load_slot = slot_name',
    '\tget_tree().change_scene_to_file("res://scenes/main.tscn")',
].join('\n');

const newLoadFn = [
    'func _do_load_from_menu(slot_name: String) -> void:',
    '\tvar slot_num := _slot_name_to_num(slot_name)',
    '\tif slot_num >= 0 and not SaveManager.has_slot(slot_num):',
    '\t\tif not Dialogic.Save.has_slot(slot_name):',
    '\t\t\treturn',
    '\tGameState.pending_load_slot = slot_name',
    '\tget_tree().change_scene_to_file("res://scenes/main.tscn")',
].join('\n');

if (content.includes(oldLoadFn)) {
    content = content.replace(oldLoadFn, newLoadFn);
    console.log('OK: _do_load_from_menu updated');
} else {
    console.log('ERROR: _do_load_from_menu pattern not found');
}

fs.writeFileSync('E:/gamedemo1/scenes/menu/MainMenu.gd', content, 'utf8');
console.log('File saved');
