extends Node

## ImageUtils — 图片加载工具
## 统一加载纹理并自动修正规格（缩放/裁剪）

func load_texture(path: String, target_size: Vector2 = Vector2.ZERO, keep_aspect: bool = true) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[ImageUtils] File not found: ", path)
		return null

	# 尝试 Godot 原生加载
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		# 编辑器降级：从 Image 文件加载（导出包中由 load() 直接完成）
		var img: Image = Image.load_from_file(path)
		if img == null or img.is_empty():
			push_warning("[ImageUtils] Failed to load image: ", path)
			return null
		tex = ImageTexture.create_from_image(img)

	if tex == null:
		return null

	var src_size: Vector2 = tex.get_size()
	if src_size.x <= 0 or src_size.y <= 0:
		push_warning("[ImageUtils] Zero-sized image: ", path)
		return tex

	# 如果不需要缩放，直接返回
	if target_size == Vector2.ZERO:
		return tex

	# 根据keep_aspect推算实际目标尺寸
	var real_target: Vector2 = target_size
	if target_size.y <= 0 and target_size.x > 0:
		real_target.y = target_size.x * src_size.y / src_size.x
	elif target_size.x <= 0 and target_size.y > 0:
		real_target.x = target_size.y * src_size.x / src_size.y

	if real_target.x <= 0 or real_target.y <= 0:
		return tex

	# 如果规格足够接近，直接返回
	if abs(src_size.x - real_target.x) < 2.0 and abs(src_size.y - real_target.y) < 2.0:
		return tex

	# 需要缩放
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return tex

	var new_size: Vector2i
	if keep_aspect:
		var scale: float = minf(real_target.x / maxf(src_size.x, 1.0), real_target.y / maxf(src_size.y, 1.0))
		scale = maxf(scale, 0.01)
		new_size = Vector2i(maxi(int(src_size.x * scale), 1), maxi(int(src_size.y * scale), 1))
	else:
		new_size = Vector2i(maxi(int(real_target.x), 1), maxi(int(real_target.y), 1))

	img.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func load_portrait(path: String, width: float = 360.0) -> Texture2D:
	return load_texture(path, Vector2(width, 0), true)


func load_icon(path: String, icon_size: float = 64.0) -> Texture2D:
	return load_texture(path, Vector2(icon_size, icon_size), false)


func get_image_size(path: String) -> Vector2:
	if path.is_empty() or not ResourceLoader.exists(path):
		return Vector2.ZERO
	var tex: Texture2D = load_texture(path)
	if tex:
		return tex.get_size()
	return Vector2.ZERO
