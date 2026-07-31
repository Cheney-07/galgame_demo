extends Node

## VersionData — 版本号与更新日志（autoload 单例）
##
## 1. version: 默认 "dev"。CI 在导出前通过 sed 把 `"dev"` 替换成 git tag
##    名称（见 .github/workflows/export.yml 的 "Inject version tag" 步骤）。
## 2. changelog: 在 _ready 时从 res://CHANGELOG.md 读取，缺失或为空时保持 ""，
##    由「关于」界面显示占位文案。

var version: String = "dev"
var changelog: String = ""


func _ready() -> void:
	changelog = _read_changelog()


func _read_changelog() -> String:
	const path := "res://CHANGELOG.md"

	# 首选：直接按文本读取。export_filter = all_resources 会把 .md 打进 pck，
	# 导出包中同样可用。
	if FileAccess.file_exists(path):
		var text: String = FileAccess.get_file_as_string(path)
		if not text.strip_edges().is_empty():
			return text

	# 回退：通过 ResourceLoader 读取（某些导入设置下 .md 会被识别为文本资源）
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res != null and "text" in res:
			var text: Variant = res.get("text")
			if text is String and not (text as String).strip_edges().is_empty():
				return text

	return ""
