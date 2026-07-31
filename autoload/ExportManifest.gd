extends Node

## ExportManifest — 导出依赖清单
## 此文件的唯一目的是通过 preload() 让 Godot 导出系统追踪所有
## 通过字符串路径动态加载的资源（DirAccess扫描、load(string)等）。
## preload() 是编译期指令，不会被实际执行，不占用运行时内存。
##
## 添加新图片/资源后需同步更新此列表。

static func _manifest() -> void:
	# ================================================
	# 版本信息 (VersionData autoload — 防止脚本被裁剪)
	# ================================================
	preload("res://autoload/version_data.gd")

	# ================================================
	# Splash 启动画面
	# ================================================
	preload("res://images/splash_slide_01.png")
	preload("res://images/game_menu.png")

	# ================================================
	# 主菜单 — 按钮图片 (MainMenu.gd BUTTON_DEFS)
	# ================================================
	preload("res://images/icon_start_idle.png")
	preload("res://images/kaishi_gaoliang.png")
	preload("res://images/icon_cg_idle.png.png")
	preload("res://images/cg_gaoliang.png")
	preload("res://images/duqu.png")
	preload("res://images/duqu_gaoliang.png")
	preload("res://images/shezhi.png")
	preload("res://images/shezhi_gaoliang.png")
	preload("res://images/guanyu.png")
	preload("res://images/guanyu_gaoliang.png")
	preload("res://images/bangzhu.png")
	preload("res://images/bangzhu_gaoliang.png")
	preload("res://images/tuichu.png")
	preload("res://images/tuichu_gaoliang.png")

	# ================================================
	# 主菜单 — 角色立绘 (MainMenu.gd CHAR_DEFS)
	# ================================================
	preload("res://images/chenli_attack.png")
	preload("res://images/hajiyou_lihui.png")
	preload("res://images/laoma.png")
	preload("res://images/laocong.png")
	preload("res://images/hajilong.png")
	preload("res://images/laoxiang.png")

	# ================================================
	# 主菜单 — 背景 & 日程背景
	# ================================================
	preload("res://images/main_menu.png")
	preload("res://images/schedule_bg.png")

	# ================================================
	# CG 画廊 (MainMenu.gd DirAccess 扫描 images/cg/)
	# ================================================
	preload("res://images/cg/hajilong_cg1.jpg")
	preload("res://images/cg/hajiyou_cg1.jpg")
	preload("res://images/cg/hajiyou_cg2.jpg")
	preload("res://images/cg/hajiyou_cg3.jpg")
	preload("res://images/cg/laoma_cg1.jpg")
	preload("res://images/cg/laoma_cg2.jpg")
	preload("res://images/cg/laocong_cg1.jpg")
	preload("res://images/cg/bad_end1.png")
	preload("res://images/cg/bad_end2.png")
	preload("res://images/cg/goodend_1.png")
	preload("res://images/cg/未命名.png")

	# ================================================
	# 战斗 — 背景 (EncounterData.background_path)
	# ================================================
	preload("res://images/battle_bg.png")
	preload("res://images/battle/bg_explore.png")
	preload("res://images/battle/bg_quest.png")
	preload("res://images/battle/bg_boss.png")

	# ================================================
	# 战斗 — 角色精灵 (EnemyTemplate.sprite_path)
	# ================================================
	preload("res://images/battle/sprites/slime.png")
	preload("res://images/battle/sprites/bianbian.png")
	preload("res://images/battle/sprites/hanbao.png")
	preload("res://images/battle/sprites/chenli.png")
	preload("res://images/battle/sprites/hajiyou.png")
	preload("res://images/battle/sprites/hajilong.png")
	preload("res://images/battle/sprites/laoma.png")
	preload("res://images/battle/sprites/laocong.png")
	preload("res://images/battle/sprites/laoxiang.png")
	preload("res://images/battle/sprites/protagonist.png")
	preload("res://images/battle/sprites/diren_laocong.png")

	# ================================================
	# 战斗 — 头像图标 (EnemyTemplate.icon_path)
	# ================================================
	preload("res://images/battle/icons/slime.png")
	preload("res://images/battle/icons/bianbian.png")
	preload("res://images/battle/icons/hanbao.png")
	preload("res://images/battle/icons/chenli.png")
	preload("res://images/battle/icons/hajiyou.png")
	preload("res://images/battle/icons/hajilong.png")
	preload("res://images/battle/icons/laoma.png")
	preload("res://images/battle/icons/laocong.png")
	preload("res://images/battle/icons/laoxiang.png")
	preload("res://images/battle/icons/protagonist.png")
	preload("res://images/battle/icons/diren_laocong.png")

	# ================================================
	# 敌人 — 图鉴图片
	# ================================================
	preload("res://images/enemies/slime.png")
	preload("res://images/enemies/bianbian.png")
	preload("res://images/enemies/hanbao.png")
	preload("res://images/enemies/diren_laocong.png")

	# ================================================
	# 技能图标 & 属性图标
	# ================================================
	preload("res://images/icons/skills/laocongskill.png")
	preload("res://images/icons/skills/laoxiangskill.png")
	preload("res://images/icons/skills/hayiyouskill_1.png")
	preload("res://images/icons/skills/hajiyouskill_2.png")
	preload("res://images/icons/skills/chenliskill.png")
	preload("res://images/icons/stats/STR.png")
	preload("res://images/icons/stats/MAG.png")
	preload("res://images/icons/stats/VIT.png")
	preload("res://images/icons/stats/AGI.png")
	preload("res://images/icons/stats/TEC.png")
	preload("res://images/icons/stats/CHA.png")

	# ================================================
	# 其他动态加载的杂项图片
	# ================================================
	preload("res://images/mengjing.png")
	preload("res://images/hei.png")
	preload("res://images/bghei.png")
	preload("res://images/bgliang.png")
	preload("res://images/choice_normal.png")
	preload("res://images/choice_hover.png")
	preload("res://images/choice_focus.png")

	print("[ExportManifest] Export dependency manifest registered.")
