extends Node3D
const PointBody = preload("point_body.gd")
const SIZE := 24
const CELL := 0.08
const LIMIT := 48
const SITE := Vector2i(10, 10)
var seeds: Array[Vector2i] = [Vector2i(7, 6), Vector2i(8, 7), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
var current: Array[bool] = []
var generation := 0
var linked := true
var point: XRToolsPickable
var cells := MultiMesh.new()
var reading := Label3D.new()
var lamp := OmniLight3D.new()
var lamp_finish := StandardMaterial3D.new()

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	replay()
	park()

func index(x: int, y: int) -> int:
	return posmod(y, SIZE) * SIZE + posmod(x, SIZE)

func replay() -> void:
	current.resize(SIZE * SIZE)
	current.fill(false)
	for site in seeds:
		current[index(site.x, site.y)] = true
	generation = 0
	redraw()

func neighbours(old: Array[bool], x: int, y: int) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if true:
				count += int(old[index(x + dx, y + dy)])
	return count

func next_state(alive: bool, count: int) -> bool:
	if alive:
		return count == 2 or count == 3
	return count == 3

func evolve(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(SIZE * SIZE)
	for y in SIZE:
		for x in SIZE:
			next[index(x, y)] = next_state(old[index(x, y)], neighbours(old, x, y))
	return next

func step() -> void:
	if generation == LIMIT:
		return
	current = evolve(current)
	generation += 1
	redraw()

func toggle_link() -> void:
	linked = not linked
	redraw()

func receive(occupied: bool, connected: bool) -> void:
	var lit := occupied and connected
	lamp.light_energy = 1.2 if lit else 0.0
	lamp_finish.albedo_color = Color("90ebca") if lit else Color("50495b")
	lamp_finish.emission = Color("62c4a4") if lit else Color.BLACK
	lamp_finish.emission_energy_multiplier = 1.3 if lit else 0.0

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(-1.2, 1.12, 0.75)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: step()
			KEY_R: replay()
			KEY_L: toggle_link()
			_: return
		get_viewport().set_input_as_handled()

func cell_position(x: int, y: int) -> Vector3:
	return Vector3((x - 11.5) * CELL, 1.06, (y - 11.5) * CELL)

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	node.material_override = finish
	add_child(node)
	return node

func make_display() -> void:
	var table := box(Vector3(2.04, 0.1, 2.04), Vector3(0, 1, 0), Color("365159"))
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.04, 0.1, 2.04)
	boundary.shape = shape
	table.add_child(body)
	body.add_child(boundary)
	box(Vector3(0.16, 0.95, 0.16), Vector3(0, 0.475, 0), Color("b39470"))
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.use_colors = true
	cells.instance_count = SIZE * SIZE
	var tile := BoxMesh.new()
	tile.size = Vector3(CELL * 0.92, 0.012, CELL * 0.92)
	cells.mesh = tile
	var view := MultiMeshInstance3D.new()
	view.multimesh = cells
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.vertex_color_use_as_albedo = true
	view.material_override = ink
	add_child(view)
	for y in SIZE:
		for x in SIZE:
			cells.set_instance_transform(index(x, y), Transform3D(Basis.IDENTITY, cell_position(x, y)))
	var at := cell_position(SITE.x, SITE.y) + Vector3.UP * 0.015
	for side in [-1, 1]:
		box(Vector3(CELL, 0.008, 0.008), at + Vector3(0, 0, side * CELL / 2), Color("ffcc70"))
		box(Vector3(0.008, 0.008, CELL), at + Vector3(side * CELL / 2, 0, 0), Color("ffcc70"))
	box(Vector3(1.2 - at.x, 0.008, 0.008), Vector3((1.2 + at.x) / 2, at.y, at.z), Color("ffcc70"))
	var globe := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	globe.mesh = sphere
	globe.position = Vector3(1.2, 1.3, at.z)
	lamp_finish.emission_enabled = true
	globe.material_override = lamp_finish
	add_child(globe)
	lamp.position = globe.position
	lamp.light_color = Color("90ebca")
	lamp.omni_range = 1.0
	add_child(lamp)
	reading.position = Vector3(0, 1.85, -0.5)
	reading.font_size = 28
	reading.pixel_size = 0.0015
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	reading.outline_size = 4
	add_child(reading)

func redraw() -> void:
	for i in current.size():
		cells.set_instance_color(i, Color("90ebca") if current[i] else Color("273e49"))
	var occupied := current[index(SITE.x, SITE.y)]
	receive(occupied, linked)
	reading.text = "B3/S23 / GEN %d / LIMIT %d\nA (%d,%d) = %d / LAMP %s\nTRIGGER / ENTER: STEP   R: REPLAY   L: LINK" % [generation, LIMIT, SITE.x, SITE.y, int(occupied), "LINKED" if linked else "UNLINKED"]
