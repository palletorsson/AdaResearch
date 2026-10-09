extends Node3D
const Field = preload("field.gd")
const PointBody = preload("point_body.gd")
const LIMIT := 2400
const W := Vector2i(12, 15)
var left := Field.new()
var right := Field.new()
var point: XRToolsPickable
var reading := Label3D.new()
var textures: Array[ImageTexture] = []
var show_u := false
var injections := 0

func _ready() -> void:
	right.exchange = false
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): plant())
	park()
	reset()

func reset() -> void:
	left.reset()
	right.reset()
	left.seed_at(Vector2i(0, 0))
	right.seed_at(Vector2i(0, 0))
	injections = 0
	paint()

func advance(count: int) -> void:
	for i in mini(count, LIMIT - left.ticks):
		left.step()
		right.step()
	paint()

func change_exchange() -> void:
	right.exchange = not right.exchange
	reset()

func target_site() -> Vector2i:
	if not point.held():
		return Vector2i(-1, -1)
	var at := to_local(point.global_position)
	for cx in [0.85, -0.85]:
		if absf(at.x - cx) < 0.64 and absf(at.z - 0.5) < 0.64 and absf(at.y - 1.01) < 0.35:
			return Vector2i(floori((at.x - cx + 0.64) / 0.04), floori((at.z - 0.5 + 0.64) / 0.04))
	return Vector2i(-1, -1)

func plant() -> void:
	var site := target_site()
	if site.x < 0:
		return
	left.seed_at(site)
	right.seed_at(site)
	injections += 1
	paint()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(0, 1.12, -0.35)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: advance(1)
			KEY_SPACE: advance(100)
			KEY_R: reset()
			KEY_E: change_exchange()
			KEY_V: show_u = not show_u; paint()
			KEY_I: plant()
			_: return
		get_viewport().set_input_as_handled()

func tint(value: float) -> Color:
	if show_u:
		return Color("241e46").lerp(Color("bce8bc"), value)
	return Color("122d3d").lerp(Color("edb1cb"), clampf(value * 2.0, 0.0, 1.0))

func paint() -> void:
	for side in 2:
		var field = left if side == 0 else right
		var data: PackedFloat32Array = field.u if show_u else field.v
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				image.set_pixel(x, y, tint(data[y * 32 + x]))
		textures[side].update(image)
	var i := left.index(W.x, W.y)
	reading.text = "TICK %d / W (12,15)\nA: U %.3f  V %.3f\nB: U %.3f  V %.3f\nB EXCHANGE %s / VIEW %s / SEEDS %d\nENTER: STEP   SPACE: +100   R: REPLAY\nE: EXCHANGE B   V: VIEW   TRIGGER / I: PLANT" % [left.ticks, left.u[i], left.v[i], right.u[i], right.v[i], "ON" if right.exchange else "OFF", "U" if show_u else "V x2", injections]

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("263744")
	node.material_override = material
	add_child(node)
	return node

func make_display() -> void:
	for side in 2:
		var cx := -0.85 if side == 0 else 0.85
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var texture := ImageTexture.create_from_image(image)
		textures.append(texture)
		var title := Label3D.new()
		title.text = "A" if side == 0 else "B"
		title.position = Vector3(cx, 2.42, -0.4)
		title.font_size = 52
		title.pixel_size = 0.0015
		add_child(title)
		var finish := StandardMaterial3D.new()
		finish.albedo_texture = texture
		finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		var table := box(Vector3(1.36, 0.08, 1.36), Vector3(cx, 0.96, 0.5))
		box(Vector3(0.5, 0.92, 0.5), Vector3(cx, 0.46, 0.5))
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.36, 0.08, 1.36)
		boundary.shape = shape
		table.add_child(body)
		body.add_child(boundary)
		for wall in [false, true]:
			var display := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(1.28, 1.28)
			display.mesh = plane
			display.material_override = finish
			display.position = Vector3(cx, 1.7, -0.4) if wall else Vector3(cx, 1.01, 0.5)
			if wall:
				display.rotation.x = PI / 2.0
			add_child(display)
		var mark := box(Vector3(0.038, 0.004, 0.038), Vector3(cx + (W.x + 0.5 - 16) * 0.04, 1.014, 0.5 + (W.y + 0.5 - 16) * 0.04))
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color("ffe49a")
		gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gold.albedo_color.a = 0.3
		mark.material_override = gold
	reading.position = Vector3(0, 2.65, 0.5)
	reading.font_size = 30
	reading.pixel_size = 0.0013
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	add_child(reading)
