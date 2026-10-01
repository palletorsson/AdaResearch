extends MeshInstance3D
## A dry marker image: bounded pixel storage, updated only when ink changes.
## Keeps the board independent of the spray canvas's transient feedback passes.
var texture_size := Vector2i(1024, 614)
var viewport: SubViewport
var _image: Image
var _texture: ImageTexture
var _dirty := false

func _ready() -> void:
	_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	_image.fill(Color.WHITE)
	_texture = ImageTexture.create_from_image(_image)
	viewport = SubViewport.new()
	viewport.name = "DryInkCanvas"
	viewport.size = texture_size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var paper := TextureRect.new()
	paper.texture = _texture
	paper.size = Vector2(texture_size)
	viewport.add_child(paper)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	material_override = material

func _process(_delta: float) -> void:
	if not _dirty: return
	_texture.update(_image)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_dirty = false

func reset_canvas() -> void:
	_image.fill(Color.WHITE)
	_dirty = true

func draw_point(uv: Vector2, color: Color, radius: int = 3, _snap_size: int = -1) -> void:
	_stamp(uv * Vector2(texture_size), color, radius)
	_dirty = true

func draw_line(from_uv: Vector2, to_uv: Vector2, color: Color, radius: int = 3, _snap_size: int = -1) -> void:
	var start := from_uv * Vector2(texture_size)
	var end := to_uv * Vector2(texture_size)
	var steps := maxi(1, ceili(start.distance_to(end) / maxf(1.0, radius * .5)))
	for i in range(steps + 1):
		_stamp(start.lerp(end, float(i) / steps), color, radius)
	_dirty = true

func _stamp(at: Vector2, color: Color, radius: int) -> void:
	var cx := roundi(at.x)
	var cy := roundi(at.y)
	for dy in range(-radius, radius + 1):
		var y := cy + dy
		if y < 0 or y >= texture_size.y: continue
		var span := floori(sqrt(float(radius * radius - dy * dy)))
		var left := maxi(0, cx - span)
		var right := mini(texture_size.x - 1, cx + span)
		if right >= left:
			_image.fill_rect(Rect2i(left, y, right - left + 1, 1), color)
