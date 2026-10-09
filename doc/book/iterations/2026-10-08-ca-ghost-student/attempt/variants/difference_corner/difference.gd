extends Node3D
const Pair = preload("paired.gd")
const Point = preload("point_body.gd")
const PITCH := 0.085
var model = Pair.new()
var slice_z := 5
var gain := 1.0
var point: Node3D
var reading: Label3D
var textures: Array[ImageTexture] = []
var volumes: Array[MultiMesh] = []
var frames: Array[Node3D] = []

func _ready() -> void:
	make_display()
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): step())
	park()
	paint()

func step() -> void:
	model.step()
	paint()

func select_slice(value: int) -> void:
	var selected := clampi(value, 0, Pair.N - 1)
	if selected != slice_z:
		slice_z = selected
		paint()

func _physics_process(_delta: float) -> void:
	if point.held():
		select_slice(roundi(to_local(point.global_position).z / PITCH + 5.0))
	else:
		park()

func park() -> void:
	point.position = Vector3(0, 1.24, (slice_z - 5) * PITCH)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER:
			step()
			return
		KEY_R: pass
		KEY_I: model.integer_storage = not model.integer_storage
		KEY_C: model.changed = not model.changed
		KEY_P: model.pull = 0.0 if model.pull > 0.0 else 0.25
		KEY_N: model.drive = 1.0 if model.drive == 0.0 else 0.0
		KEY_B: model.scattered = not model.scattered
		_: return
	model.reset()
	paint()

func tint(value: float) -> Color:
	return Color("182c42").lerp(Color("efc0d6"), value / 9.0)

func paint() -> void:
	var result: Dictionary = model.report()
	gain = 1.0 / maxf(result.maximum, 0.000001)
	for side in 3:
		var img := Image.create(Pair.N, Pair.N, false, Image.FORMAT_RGBA8)
		for y in Pair.N:
			for x in Pair.N:
				var i: int = model.index(Vector3i(x, y, slice_z))
				var colour := tint(model.a[i] if side == 0 else model.b[i])
				if side == 2:
					colour = Color("112c31").lerp(Color("ffd18e"), absf(model.a[i] - model.b[i]) * gain)
				img.set_pixel(x, Pair.N - 1 - y, colour)
		textures[side].update(img)
	for side in 2:
		var values: PackedFloat64Array = model.a if side == 0 else model.b
		for i in Pair.COUNT:
			volumes[side].set_instance_color(i, tint(values[i]))
		frames[side].position.z = (slice_z - 5) * PITCH
	reading.text = "UPDATE %d / Z SLICE %d\n%s / %s / ONE CELL %s\nPULL %.2f / DRIVE %.1f\nDIFFERENT %d (>0.000001)\nMAX %.8f / MEAN %.8f / GAIN x%.1f" % [model.tick, slice_z,
		"INTEGER" if model.integer_storage else "FRACTIONAL", "SCATTERED" if model.scattered else "UNIFORM",
		"ON" if model.changed else "OFF", model.pull, model.drive, result.count, result.maximum, result.mean, gain]

func box(parent: Node3D, size: Vector3, at: Vector3, colour: Color, solid: bool = false) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.mesh = mesh
	surface.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	surface.material_override = material
	parent.add_child(surface)
	if solid:
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		boundary.shape = shape
		surface.add_child(body)
		body.add_child(boundary)

func label(words: String, at: Vector3, pixel: float = 0.0014) -> Label3D:
	var result := Label3D.new()
	result.text = words
	result.position = at
	result.font_size = 32
	result.pixel_size = pixel
	add_child(result)
	return result

func make_display() -> void:
	box(self, Vector3(2.95, 0.08, 1.5), Vector3(0, 1.0, 0), Color("e4dfd4"), true)
	for side in 2:
		var cx := -0.85 if side == 0 else 0.85
		box(self, Vector3(0.6, 0.96, 0.6), Vector3(cx, 0.48, 0), Color("e4dfd4"))
		var cells := MultiMesh.new()
		cells.transform_format = MultiMesh.TRANSFORM_3D
		cells.use_colors = true
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * 0.03
		cells.mesh = cube
		cells.instance_count = Pair.COUNT
		for z in Pair.N:
			for y in Pair.N:
				for x in Pair.N:
					cells.set_instance_transform(model.index(Vector3i(x, y, z)), Transform3D(Basis.IDENTITY, Vector3(cx + (x - 5) * PITCH, 1.12 + y * PITCH, (z - 5) * PITCH)))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = cells
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		instance.material_override = material
		add_child(instance)
		volumes.append(cells)
		var frame := Node3D.new()
		frame.position = Vector3(cx, 1.545, 0)
		add_child(frame)
		frames.append(frame)
		for sign_ in [-1, 1]:
			box(frame, Vector3(0.012, 0.94, 0.012), Vector3(sign_ * 0.47, 0, 0), Color("ffd18e"))
			box(frame, Vector3(0.94, 0.012, 0.012), Vector3(0, sign_ * 0.47, 0), Color("ffd18e"))
	for side in 3:
		var cx := (side - 1) * 0.85
		var img := Image.create(Pair.N, Pair.N, false, Image.FORMAT_RGBA8)
		var texture := ImageTexture.create_from_image(img)
		textures.append(texture)
		box(self, Vector3(0.74, 0.74, 0.035), Vector3(cx, 2.5, -0.8), Color("b59a79"))
		var view := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.7, 0.7)
		view.mesh = quad
		view.position = Vector3(cx, 2.5, -0.777)
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		view.material_override = material
		add_child(view)
		label(["A", "B", "|A-B| x GAIN"][side], Vector3(cx, 2.96, -0.77))
	box(self, Vector3(0.009, 0.009, 0.94), Vector3(0, 1.08, 0), Color("ffd18e"))
	box(self, Vector3(2.6, 0.47, 0.04), Vector3(0, 0.77, 0.78), Color("172937"))
	reading = label("", Vector3(0, 0.77, 0.807), 0.001)
	label("ENTER step / R replay / I storage / C one cell\nP pull / N drive / B seed", Vector3(0, 0.43, 0.81), 0.0009)
