# Godot 4.7 项目中文字体修复方案

## 问题描述

项目在 Web 导出时中文显示为方框（tofu）或乱码，桌面平台可能正常（依赖系统字体回退）。

## 根本原因

1. `project.godot` 未设置 `theme/default_font`
2. Web 平台无系统字体回退，`allow_system_fallback=true` 无效
3. 动态创建的 Label/Button 只设了 `font_size`，未设 `font`
4. Dialogic 快捷菜单按钮未设置字体

## 修复方案

### 1. 引入中文字体

将支持简体中文的字体放入 `res://fonts/` 目录：

```
fonts/
└── NotoSansSC-Regular.otf    # 7.9 MB（推荐）
```

推荐字体（按优先级）：
- **Noto Sans SC**（Google，推荐）- 约 7.9MB
- Source Han Sans SC（思源黑体）
- STHeiti（macOS 系统字体）

### 2. 创建全局 Theme 资源

文件：`res://resources/global_theme.tres`

```tres
[gd_resource type="Theme" format=3 uid="uid://uo2kd8rgp1"]

[ext_resource type="FontFile" uid="uid://j06ydcgihhuq" path="res://fonts/NotoSansSC-Regular.otf" id="1_font"]

[resource]

Button/fonts/font = ExtResource("1_font")
Button/font_sizes/font_size = 16
Label/fonts/font = ExtResource("1_font")
Label/font_sizes/font_size = 16
default_font = ExtResource("1_font")
default_font_size = 16
```

### 3. 配置 project.godot

在 `[gui]` 部分添加：

```ini
[gui]
theme/default_font="res://fonts/NotoSansSC-Regular.otf"
theme/default_font_size=16
theme/default_theme="res://resources/global_theme.tres"
```

### 4. 动态创建的控件显式设置字体

**关键原则**：所有通过代码动态创建的 Label/Button 必须显式设置字体，不能只依赖主题继承。

#### 4.1 在文件顶部添加字体预加载

```gdscript
var _cn_font: Font = preload("res://fonts/NotoSansSC-Regular.otf")
```

#### 4.2 创建 Label 时设置字体

```gdscript
# 错误 ❌ - 只设了 font_size
var title := Label.new()
title.text = "标题"
title.add_theme_font_size_override("font_size", 36)

# 正确 ✅ - 同时设置 font
var title := Label.new()
title.add_theme_font_override("font", _cn_font)
title.text = "标题"
title.add_theme_font_size_override("font_size", 36)
```

#### 4.3 创建 Button 时设置字体

```gdscript
# 错误 ❌
var btn := Button.new()
btn.text = "确认"
btn.add_theme_font_size_override("font_size", 16)

# 正确 ✅
var btn := Button.new()
btn.add_theme_font_override("font", _cn_font)
btn.text = "确认"
btn.add_theme_font_size_override("font_size", 16)
```

### 5. 内联创建模式处理

对于单行创建模式：

```gdscript
# 单行创建
var tl: Label = Label.new(); tl.text = title
# 需要在分号后添加字体设置
var tl: Label = Label.new(); tl.add_theme_font_override("font", _cn_font); tl.text = title
```

## 需要修改的文件清单

### 核心配置文件

| 文件 | 修改内容 |
|------|----------|
| `project.godot` | 添加 `theme/default_font` 和 `theme/default_theme` |
| `resources/global_theme.tres` | 新建，设置 Button/Label 默认字体 |

### 动态创建控件的脚本

| 文件 | 控件类型 | 数量 |
|------|----------|------|
| `scenes/menu/MainMenu.gd` | Label + Button | ~19 处 |
| `scenes/schedule/ScheduleHub.gd` | Label + Button | ~31 处 |
| `scenes/schedule/Schedule.gd` | Label + Button | ~15 处 |
| `scenes/battle/arena/CombatArena.gd` | Label | ~2 处 |
| `scenes/MainScene.gd` | Label | ~1 处 |
| `scenes/battle/ui/action_menu/UIActionMenu.gd` | Button | ~3 处 |
| `scenes/battle/ui/targeting/UIBattlerTargetingCursor.gd` | Button | ~2 处 |

### Dialogic 相关文件

| 文件 | 修改内容 |
|------|----------|
| `resources/dialogic/styles/Visual Novel Style.tres` | Base 层和 Textbox 层设置字体 |
| `resources/dialogic/layers/quick_menu_layer.gd` | 所有按钮和标签设置字体 |

## Dialogic 字体配置详解

### Style 层级结构

```
Visual Novel Style
├── Base 层 (Resource_loe7k)
│   └── overrides: global_font = NotoSansSC-Regular.otf
├── Textbox 层 (Resource_3tkde)
│   └── overrides: font = NotoSansSC-Regular.otf
└── QuickMenu 层 (quick_menu_layer.gd)
    └── 代码中显式设置字体
```

### 快捷菜单按钮位置

`resources/dialogic/layers/quick_menu_layer.gd` 包含：

- `_make_button()` - 创建「存档/读档/自动/快进/设置」按钮
- `_make_panel_button()` - 创建「关闭/返回主菜单」按钮
- `_make_slot_button()` - 创建存档栏位按钮
- `_make_overlay()` - 创建存档/读档面板标题

所有按钮创建函数都需要添加 `add_theme_font_override("font", _cn_font)`。

## 字体 Import 设置

在 `.import` 文件中：

```ini
[params]
allow_system_fallback=true    # Web 平台无效，但保留不影响
fallbacks=[]                  # 可选：添加 fallback 字体
compress=true
```

## 验证清单

- [ ] 编辑器内中文正常显示
- [ ] 桌面导出中文正常
- [ ] Web 导出中文正常（最关键）
- [ ] 标题画面中文正常
- [ ] 对话框中文正常
- [ ] 菜单按钮（存档/读档/自动/快进/设置）中文正常
- [ ] 存档栏位文字正常
- [ ] 设置界面（音量标签）中文正常
- [ ] 战斗界面文字正常

## 字体优化建议

如果 Web 导出包体过大，可使用字体子集化：

```bash
# 安装工具
pip install fonttools brotli

# 提取项目用到的字符
pyftsubset fonts/NotoSansSC-Regular.otf \
  --text-file=used_chars.txt \
  --output-file=fonts/NotoSansSC-Subset.otf
```

可将 7.9MB 压缩到 1-2MB。

## 注意事项

1. **`extends` 必须在变量声明之前**（GDScript 语法要求）
2. **Button 不继承 `default_font`**，需要在 Theme 中显式设置 `Button/fonts/font`
3. **动态创建的控件需要手动设置字体**，主题继承不可靠
4. **`allow_system_fallback` 在 Web 上无效**，必须使用内嵌字体
