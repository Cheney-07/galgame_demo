const fs = require('fs');
let content = fs.readFileSync('E:/gamedemo1/resources/dialogic/layers/quick_menu_layer.gd', 'utf8');

const oldStr = [
    '\tif Dialogic.Save.has_slot(slot_name):',
    '\t\tvar info: Dictionary = Dialogic.Save.get_slot_info(slot_name)',
    '\t\tvar extra: Dictionary = info.get("extra", {})',
    '\t\tvar timestamp: String = str(extra.get("date", info.get("timestamp", "")))',
    '\t\tvar chapter: int = extra.get("chapter", 0)',
    '\t\tvar day: int = extra.get("day", 1)',
    '\t\tbtn.text = "栏位 " + slot_name.right(1) + "\\n" + str(timestamp) + "\\n第" + str(chapter + 1) + "章 第" + str(day) + "天"',
    '\t\tbtn.add_theme_color_override("font_color", Color(1, 1, 1))',
    '\t\tbtn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.15, 0.15, 0.25, 0.85)))',
].join('\n');

const newStr = [
    '\tvar slot_num := _slot_name_to_num(slot_name)',
    '\tif slot_num >= 0 and SaveManager.has_slot(slot_num):',
    '\t\tvar info: Dictionary = SaveManager.get_slot_info(slot_num)',
    '\t\tbtn.text = "栏位 " + slot_name.right(1) + "\\n" + str(info.get("timestamp", "")) + "\\n第" + str(info.get("chapter", 0) + 1) + "章 第" + str(info.get("day", 1)) + "天"',
    '\t\tbtn.add_theme_color_override("font_color", Color(1, 1, 1))',
    '\t\tbtn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.15, 0.15, 0.25, 0.85)))',
    '\telif Dialogic.Save.has_slot(slot_name):',
    '\t\tvar info: Dictionary = Dialogic.Save.get_slot_info(slot_name)',
    '\t\tvar extra: Dictionary = info.get("extra", {})',
    '\t\tvar timestamp: String = str(extra.get("date", info.get("timestamp", "")))',
    '\t\tvar chapter: int = extra.get("chapter", 0)',
    '\t\tvar day: int = extra.get("day", 1)',
    '\t\tbtn.text = "栏位 " + slot_name.right(1) + "\\n" + str(timestamp) + "\\n第" + str(chapter + 1) + "章 第" + str(day) + "天"',
    '\t\tbtn.add_theme_color_override("font_color", Color(1, 1, 1))',
    '\t\tbtn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.15, 0.15, 0.25, 0.85)))',
].join('\n');

if (content.includes(oldStr)) {
    content = content.replace(oldStr, newStr);
    fs.writeFileSync('E:/gamedemo1/resources/dialogic/layers/quick_menu_layer.gd', content, 'utf8');
    console.log('OK: quick_menu_layer.gd updated');
} else {
    console.log('ERROR: pattern not found (checking exact match)');
    console.log(JSON.stringify(oldStr));
}
