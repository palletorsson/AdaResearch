extends Node3D
const PointBody = preload("point_body.gd")
const WIDTH := 15
const ROWS := 24
const CELL := 0.08
const ANSWERS := [false, true, true, true, true, false, false, false]
var seeds: Array[int] = [7]
var current: Array[bool] = []
var history: Array[Array] = []
var selected := 0
var point: XRToolsPickable
var reading := Label3D.new()
var deck := MultiMesh.new()
var screen := MultiMesh.new()
var shapes: Array[CollisionShape3D] = []
var deck_mark: MeshInstance3D
var screen_mark: MeshInstance3D

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	replay()
	park()

func replay() -> void:
	current.resize(WIDTH)
	current.fill(false)
	for x in seeds:
		assert(x >= 0 and x < WIDTH)
		current[x] = true
	history.clear()
	history.append(current.duplicate())
	selected = 0
	redraw()

func next_row(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(WIDTH)
	for x in WIDTH:
		var left := old[posmod(x - 1, WIDTH)]
		var self_cell := old[x]
		var right := old[posmod(x + 1, WIDTH)]
		next[x] = ANSWERS[4 * int(left) + 2 * int(self_cell) + int(right)]
	return next

func step() -> void:
	if history.size() == ROWS:
		return
	current = next_row(current)
	history.append(current.duplicate())
	selected = history.size() - 1
	redraw()

func select_row(g: int) -> void:
	if g < 0 or g >= history.size():
		return
	selected = g
	deck_mark.position.z = g * CELL
	screen_mark.position.z = g * CELL
	reading.text = "RULE 30 / GEN 0..%d / READ %d\nMOVE POINT ALONG Z: READ HISTORY\nTRIGGER OR ENTER: STEP / R: REPLAY" % [history.size() - 1, selected]

func _physics_process(_delta: float) -> void:
	if point.held():
		var p := to_local(point.global_position)
		select_row(floori(p.z / CELL + 0.5))
	else:
		park()

func park() -> void:
	point.position = Vector3(-0.85, 1.05, selected * CELL)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			step()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			replay()
			get_viewport().set_input_as_handled()

func deck_position(x: int, g: int) -> Vector3:
	return Vector3((x - 7) * CELL, 1.0, g * CELL)

func screen_position(x: int, g: int) -> Vector3:
	return Vector3(0.85, 1.05 + (WIDTH - 1 - x) * 0.055, g * CELL)

func make_view(mm: MultiMesh, size: Vector3) -> void:
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = WIDTH * ROWS
	var cube := BoxMesh.new()
	cube.size = size
	mm.mesh = cube
	var view := MultiMeshInstance3D.new()
	view.multimesh = mm
	var finish := StandardMaterial3D.new()
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.vertex_color_use_as_albedo = true
	view.material_override = finish
	add_child(view)

func marker(size: Vector3, at: Vector3) -> MeshInstance3D:
	var mark := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mark.mesh = cube
	mark.position = at
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("ffcc72")
	mark.material_override = gold
	add_child(mark)
	return mark

func make_display() -> void:
	make_view(deck, Vector3(CELL, 0.022, CELL))
	make_view(screen, Vector3(0.014, 0.05, CELL * 0.9))
	var support := StaticBody3D.new()
	add_child(support)
	var tile := BoxShape3D.new()
	tile.size = Vector3(CELL, 0.022, CELL)
	for g in ROWS:
		for x in WIDTH:
			var shape := CollisionShape3D.new()
			shape.shape = tile
			shape.position = deck_position(x, g)
			shape.disabled = true
			support.add_child(shape)
			shapes.append(shape)
	deck_mark = marker(Vector3(1.4, 0.008, 0.012), Vector3(0, 1.018, 0))
	screen_mark = marker(Vector3(0.025, 0.86, 0.012), Vector3(0.85, 1.435, 0))
	reading.position = Vector3(0, 2.1, 0.9)
	reading.font_size = 30
	reading.pixel_size = 0.0015
	reading.outline_size = 4
	add_child(reading)

func redraw() -> void:
	for g in ROWS:
		for x in WIDTH:
			var i := g * WIDTH + x
			var occupied: bool = g < history.size() and history[g][x]
			var basis := Basis.IDENTITY if occupied else Basis.IDENTITY.scaled(Vector3.ZERO)
			var colour := Color("78d9bd").lerp(Color("e2a4de"), float(g) / (ROWS - 1))
			deck.set_instance_transform(i, Transform3D(basis, deck_position(x, g)))
			screen.set_instance_transform(i, Transform3D(basis, screen_position(x, g)))
			deck.set_instance_color(i, colour)
			screen.set_instance_color(i, colour)
			shapes[i].set_deferred("disabled", not occupied)
	select_row(selected)
