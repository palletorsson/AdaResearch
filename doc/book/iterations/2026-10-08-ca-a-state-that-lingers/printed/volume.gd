extends Node3D
const PointBody = preload("point_body.gd")
const SIZE := 7
const SPACING := 0.18
const CENTRE := Vector3i(3, 3, 3)
const COLOURS := [Color("53616b"), Color("df76b4"), Color("89d7a3")]
var current: Array[int] = []
var generation := 0
var point: XRToolsPickable
var reading := Label3D.new()
var cells := MultiMesh.new()

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	reset()
	park()

func index(p: Vector3i) -> int:
	return p.x + SIZE * p.y + SIZE * SIZE * p.z

func reset() -> void:
	current.resize(SIZE * SIZE * SIZE)
	current.fill(0)
	# Nine cells in a flat square; three more just above its middle row.
	for z in range(2, 5):
		for x in range(2, 5):
			current[index(Vector3i(x, 3, z))] = 1
	for x in range(2, 5):
		current[index(Vector3i(x, 4, 3))] = 1
	generation = 0
	redraw()

func active_neighbours(old: Array[int], p: Vector3i) -> int:
	var count := 0
	for z in range(-1, 2):
		for y in range(-1, 2):
			for x in range(-1, 2):
				var offset := Vector3i(x, y, z)
				if offset != Vector3i.ZERO and old[index(p + offset)] == 1:
					count += 1
	return count

func next_state(state: int, neighbours: int) -> int:
	if state == 2:
		return 0
	if neighbours >= 6 and neighbours <= 8:
		return 1
	if state == 1:
		return 2
	return 0

func evolve(old: Array[int]) -> Array[int]:
	var next: Array[int] = []
	next.resize(old.size())
	next.fill(0)
	# The outer shell stays empty; only interior addresses receive answers.
	for z in range(1, SIZE - 1):
		for y in range(1, SIZE - 1):
			for x in range(1, SIZE - 1):
				var p := Vector3i(x, y, z)
				next[index(p)] = next_state(old[index(p)], active_neighbours(old, p))
	return next

func step() -> void:
	current = evolve(current)
	generation += 1
	redraw()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(0.8, 1.05, 0.65)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			step()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			reset()
			get_viewport().set_input_as_handled()

func make_display() -> void:
	cells.transform_format = MultiMesh.TRANSFORM_3D
	cells.use_colors = true
	cells.instance_count = SIZE * SIZE * SIZE
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * SPACING * 0.65
	cells.mesh = cube
	var view := MultiMeshInstance3D.new()
	view.multimesh = cells
	var finish := StandardMaterial3D.new()
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.vertex_color_use_as_albedo = true
	view.material_override = finish
	add_child(view)
	reading.position = Vector3(0, 1.9, 0)
	reading.font_size = 30
	reading.pixel_size = 0.0015
	reading.outline_size = 4
	add_child(reading)
	# A gold address stays after the central cell disappears.
	for axis in range(3):
		for a in [-1, 1]:
			for b in [-1, 1]:
				var edge := MeshInstance3D.new()
				var bar := BoxMesh.new()
				bar.size = Vector3.ONE * 0.006
				bar.size[axis] = SPACING
				edge.mesh = bar
				edge.position = Vector3(0, 1.05, 0)
				edge.position[(axis + 1) % 3] += a * SPACING / 2
				edge.position[(axis + 2) % 3] += b * SPACING / 2
				var gold := StandardMaterial3D.new()
				gold.albedo_color = Color("ffd77d")
				edge.material_override = gold
				add_child(edge)

func redraw() -> void:
	for z in SIZE:
		for y in SIZE:
			for x in SIZE:
				var p := Vector3i(x, y, z)
				var i := index(p)
				var basis := Basis.IDENTITY if current[i] > 0 else Basis.IDENTITY.scaled(Vector3.ZERO)
				var at := Vector3(p - CENTRE) * SPACING + Vector3(0, 1.05, 0)
				cells.set_instance_transform(i, Transform3D(basis, at))
				cells.set_instance_color(i, COLOURS[current[i]])
	var words := ["EMPTY", "ACTIVE", "FADING"]
	reading.text = "GEN %d / CENTRE %s\n%d ACTIVE NEIGHBOURS\nHOLD POINT + TRIGGER: STEP\nENTER: STEP / R: REPLAY" % [generation, words[current[index(CENTRE)]], active_neighbours(current, CENTRE)]
