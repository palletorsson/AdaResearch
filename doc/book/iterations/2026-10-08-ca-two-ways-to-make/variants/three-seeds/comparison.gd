extends Node3D
const Procedures = preload("procedures.gd")
const PointBody = preload("point_body.gd")
const ROWS := 24
const PITCH := 0.05
const DEPTH := 3
const VIEW_SCALE := 0.18
var methods := Procedures.new()
var seed_sites: Array[int] = [14, 16, 18]
var history: Array[Array] = []
var cells := MultiMesh.new()
var copies := MultiMesh.new()
var positions: Array[Vector3] = []
var point: XRToolsPickable
var reading := Label3D.new()
var selected := 16

func _ready() -> void:
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	reset()
	park()

func reset() -> void:
	var row: Array[bool] = []
	row.resize(Procedures.N)
	row.fill(false)
	for i in seed_sites:
		row[posmod(i, Procedures.N)] = true
	history.clear()
	history.append(row)
	redraw()

func step() -> void:
	if history.size() == ROWS:
		return
	var old: Array[bool] = []
	old.assign(history.back())
	history.append(methods.next_row(old))
	redraw()

func change_seed() -> void:
	seed_sites.assign([16, 17] if seed_sites.size() == 1 else [16])
	reset()

func _physics_process(_delta: float) -> void:
	if point.held():
		var x := to_local(point.global_position).x
		selected = clampi(floori((x + 1.15) / PITCH + 16), 0, 31)
	else:
		park()
	readout()

func park() -> void:
	point.position = Vector3(-1.15 + (selected - 15.5) * PITCH, 1.15, 0.85)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: step()
			KEY_R: reset()
			KEY_C: change_seed()
			_: return
		get_viewport().set_input_as_handled()

func at(col: int, row: int) -> Vector3:
	return Vector3(-1.15 + (col - 15.5) * PITCH, 1.005, (11.5 - row) * PITCH)

func redraw() -> void:
	for row in ROWS:
		for col in Procedures.N:
			var recorded := row < history.size()
			var alive: bool = recorded and history[row][col]
			var basis := Basis.IDENTITY if recorded else Basis.IDENTITY.scaled(Vector3.ZERO)
			cells.set_instance_transform(row * 32 + col, Transform3D(basis, at(col, row)))
			cells.set_instance_color(row * 32 + col, Color("eadcc1") if alive else Color("183f45"))
	readout()

func readout() -> void:
	var row: Array = history.back()
	var left: bool = row[posmod(selected - 1, 32)]
	var right: bool = row[(selected + 1) % 32]
	reading.text = "RULE 90 / GEN %d / CELL %d\nLEFT %d   RIGHT %d   NEXT %d\nENTER / TRIGGER: STEP   R: REPLAY   C: SEED\nHISTORY CHANGES / %d COPY POSITIONS STAY" % [history.size() - 1, selected, int(left), int(right), int(left != right), positions.size()]

func box(size: Vector3, place: Vector3, colour: Color, solid: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = place
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	node.material_override = finish
	add_child(node)
	if solid:
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		boundary.shape = shape
		node.add_child(body)
		body.add_child(boundary)
	return node

func draw_instances(data: MultiMesh, size: Vector3, colour: Color, colours: bool) -> void:
	data.transform_format = MultiMesh.TRANSFORM_3D
	data.use_colors = colours
	var mesh := BoxMesh.new()
	mesh.size = size
	data.mesh = mesh
	var view := MultiMeshInstance3D.new()
	view.multimesh = data
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.vertex_color_use_as_albedo = colours
	view.material_override = material
	add_child(view)

func make_display() -> void:
	box(Vector3(1.72, 0.08, 1.32), Vector3(-1.15, 0.96, 0), Color("c9c5bd"), true)
	box(Vector3(0.6, 0.92, 0.6), Vector3(-1.15, 0.46, 0), Color("aaa89f"))
	draw_instances(cells, Vector3(PITCH * 0.95, 0.006, PITCH * 0.95), Color.WHITE, true)
	cells.instance_count = 32 * ROWS
	box(Vector3(1.25, 1.08, 1.25), Vector3(0.8, 0.54, 0), Color("c9c5bd"), true)
	draw_instances(copies, Vector3.ONE * VIEW_SCALE, Color("dfacc4"), false)
	positions = methods.copy_positions(Vector3.ZERO, pow(2, DEPTH - 1), DEPTH)
	copies.instance_count = positions.size()
	for i in positions.size():
		copies.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(0.8, 1.50, 0) + positions[i] * VIEW_SCALE))
	box(Vector3(1.6, 0.006, 0.008), Vector3(-1.15, 1.04, 0.85), Color("ffd77d"))
	reading.position = Vector3(-0.4, 2.45, -0.5)
	reading.font_size = 34
	reading.pixel_size = 0.0015
	add_child(reading)
