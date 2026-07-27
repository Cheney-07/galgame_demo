extends CanvasLayer

## Splash — 启动画面，3张图片依次淡入淡出

var slides = [
	"res://images/splash_slide_01.png",
]
# splash_slide_02/03 图片格式问题无法加载，只保留第1张
var current_index: int = 0
var display: TextureRect
var tween: Tween
var fading: bool = false
var skipped: bool = false

const FADE_DURATION: float = 0.5
const SLIDE_DURATION: float = 3.0

func _ready() -> void:
	# 创建全屏显示
	display = TextureRect.new()
	display.name = "SplashDisplay"
	display.anchor_left = 0.0
	display.anchor_top = 0.0
	display.anchor_right = 1.0
	display.anchor_bottom = 1.0
	display.offset_left = 0.0
	display.offset_top = 0.0
	display.offset_right = 0.0
	display.offset_bottom = 0.0
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)

	# 加载第一张
	show_current_slide()


func load_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var tex = load(path)
	if tex != null:
		return tex
	var img = Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func show_current_slide() -> void:
	if current_index >= slides.size():
		finish()
		return

	var path = slides[current_index]
	var texture = load_texture(path)
	if texture == null:
		print("[Splash] Failed to load: ", path)
		current_index += 1
		show_current_slide()
		return

	display.texture = texture
	display.modulate.a = 0.0
	_fade_in()


func _fade_in() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(display, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_interval(SLIDE_DURATION)
	tween.tween_callback(_fade_out)


func _fade_out() -> void:
	if skipped:
		finish()
		return
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(display, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(_next_slide)


func _next_slide() -> void:
	current_index += 1
	show_current_slide()


func finish() -> void:
	# 切换到主菜单
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _input(event: InputEvent) -> void:
	if skipped:
		return
	if event is InputEventMouseButton and event.pressed:
		skipped = true
		finish()
	elif event is InputEventKey and event.pressed:
		skipped = true
		finish()
