extends Node3D
## One Rule 30 history, three mappings: desk, support tiles, ornamental screen.
## Opt-in furniture for CA_GameOfLife. The parent owns the actual Wolfram rule.
const WIDTH := 15
const ROWS := 24
const CELL := 0.4
const SEED := 23090
var work: Node3D
var history: Array = []
var seed_mode: int = 0
var flipped: bool = false
var running: bool = false
var elapsed: float = 0.0
var selected: int = 0
var reading: Label3D
var console: Node3D
var deck: MultiMeshInstance3D
var screen: MultiMeshInstance3D
var record: MultiMeshInstance3D
var support: StaticBody3D
var shapes: Array[CollisionShape3D] = []
var deck_cursor: MeshInstance3D
var screen_cursor: MeshInstance3D
var record_cursor: MeshInstance3D
var last_step_usec: int = 0

func _ready() -> void:
	work = get_parent()
	work.width = WIDTH
	work.length = ROWS
	work.rule = 30
	work.cell_size = CELL
	_build_space()
	_build_desk()
	replay()
	# A held twelve-row specimen greets the visitor. REPLAY exposes its beginning.
	for i in range(11):
		_advance()

func _seed_row() -> Array:
	var row: Array = []
	row.resize(WIDTH)
	row.fill(0)
	match seed_mode:
		0: row[7] = 1
		1:
			row[5] = 1
			row[9] = 1
		2:
			var rng := RandomNumberGenerator.new()
			rng.seed = SEED
			for x in range(WIDTH): row[x] = int(rng.randf() < 0.45)
	if flipped: row[9] = 1 - int(row[9])
	return row

func replay() -> void:
	running = false
	elapsed = 0.0
	history = [_seed_row()]
	selected = 0
	_refresh()

func step_once() -> void:
	running = false
	elapsed = 0.0
	_advance()

func _advance() -> void:
	if history.size() >= ROWS:
		running = false
		_refresh_readout()
		return
	var started: int = Time.get_ticks_usec()
	var next_row: Array = work._calculate_next_row(history.back())
	history.append(next_row)
	selected = history.size() - 1
	if history.size() == ROWS: running = false
	_refresh()
	last_step_usec = Time.get_ticks_usec() - started

func toggle_run() -> void:
	if history.size() < ROWS: running = not running
	elapsed = 0.0
	_refresh_readout()

func next_seed() -> void:
	seed_mode = (seed_mode + 1) % 3
	flipped = false
	replay()

func flip_seed() -> void:
	flipped = not flipped
	replay()

func previous_row() -> void:
	running = false
	selected = posmod(selected - 1, history.size())
	_refresh_cursor()
	_refresh_readout()

func _process(delta: float) -> void:
	if not running: return
	elapsed += delta
	if elapsed >= 0.5:
		elapsed = 0.0
		_advance()

func cell_position(x: int, generation: int) -> Vector3:
	return Vector3((x - 7) * CELL, -0.11, generation * CELL)

func _refresh() -> void:
	var drawn: int = 0
	for g in range(ROWS):
		for x in range(WIDTH):
			var i: int = g * WIDTH + x
			var present: bool = g < history.size()
			var occupied: bool = present and int(history[g][x]) == 1
			# Only occupied recorded cells offer support. The basin is lower down.
			shapes[i].set_deferred("disabled", not occupied)
			var colour: Color = Color("78d9bd").lerp(Color("e2a4de"), float(g) / (ROWS - 1))
			if occupied:
				deck.multimesh.set_instance_transform(drawn, Transform3D(Basis.IDENTITY, cell_position(x, g)))
				deck.multimesh.set_instance_color(drawn, colour)
				screen.multimesh.set_instance_transform(drawn, Transform3D(Basis.IDENTITY, Vector3(3.45, 0.5 + x * 0.17, g * CELL)))
				screen.multimesh.set_instance_color(drawn, colour)
				drawn += 1
			var ink: Color = colour if occupied else (Color("30494d") if present else Color("17292e"))
			record.multimesh.set_instance_color(i, ink)
	deck.multimesh.visible_instance_count = drawn
	screen.multimesh.visible_instance_count = drawn
	_refresh_cursor()
	_refresh_readout()

func _refresh_cursor() -> void:
	deck_cursor.position.z = selected * CELL
	screen_cursor.position.z = selected * CELL
	record_cursor.position.y = -0.54 + selected * 0.048

func _refresh_readout() -> void:
	var names: Array[String] = ["SINGLE", "PAIR", "SEEDED 23090"]
	var status: String = "RUN" if running else "HELD"
	if history.size() == ROWS: status = "RECORD FULL"
	reading.text = "RULE 30  /  %s\nGEN 0..%d  /  FOLLOW %d\n%s%s\nX WRAPS / GOLD FOLLOWS ONE ROW" % [status, history.size()-1, selected, names[seed_mode], " + FLIP X9" if flipped else ""]

func readback() -> Dictionary:
	return {"generation":history.size()-1,"selected":selected,"running":running,
		"seed_mode":seed_mode,"flipped":flipped,"rule":work.rule,
		"occupied":deck.multimesh.visible_instance_count,"history":history.duplicate(true),
		"step_usec":last_step_usec}

func _build_space() -> void:
	# A shallow collecting floor under the holes; the museum path runs alongside.
	box("Basin", Vector3(7.0, 0.12, 10.0), Vector3(0,-0.66,4.5), Color("233c40"), true)
	_ramp("EntryRamp", 0.7, -0.5)
	_ramp("ExitRamp", 8.3, 9.5)
	for x: float in [-3.16,3.16]:
		box("BasinEdge", Vector3(0.12,0.10,9.6), Vector3(x,-0.05,4.6), Color("bd9265"))
	deck = _instances("SupportTiles", Vector3(CELL,0.22,CELL), false)
	screen = _instances("HistoryLattice", Vector3(0.07,0.155,0.365), true)
	support = StaticBody3D.new()
	support.name = "HistorySupport"
	add_child(support)
	var shape := BoxShape3D.new()
	shape.size = Vector3(CELL,0.22,CELL)
	for g in range(ROWS):
		for x in range(WIDTH):
			var col := CollisionShape3D.new()
			col.shape = shape
			col.position = cell_position(x,g)
			col.disabled = true
			support.add_child(col)
			shapes.append(col)
	for z: float in [-0.28, 3.0, 6.2, 9.48]:
		box("LatticeUpright", Vector3(0.12,3.25,0.09), Vector3(3.45,1.625,z), Color("b08c66"), true)
	for y: float in [0.22,3.22]:
		box("LatticeRail", Vector3(0.12,0.09,9.85), Vector3(3.45,y,4.6), Color("b08c66"), true)
	deck_cursor = box("FollowDeck", Vector3(6.1,0.018,0.022), Vector3(0,0.02,0), Color("ffcc72"))
	screen_cursor = box("FollowLattice", Vector3(0.09,2.75,0.025), Vector3(3.45,1.69,0), Color("ffcc72"))
	var heading := _label("LatticeHeading", "THE SAME HISTORY / WORN BY A WALL", 32)
	heading.position = Vector3(3.35,3.45,4.6)
	heading.rotation_degrees.y = -90
	add_child(heading)
	for g in [0,6,12,18,23]:
		var label := _label("Generation_%d" % g,"GEN %d" % g,32)
		label.position = Vector3(-3.5,0.035,g*CELL)
		label.rotation_degrees = Vector3(-90,0,0)
		add_child(label)

func _build_desk() -> void:
	box("DeskFoot",Vector3(1.8,0.1,0.7),Vector3(0,0.05,-2.4),Color("906e50"),true)
	box("DeskStem",Vector3(0.18,1.2,0.18),Vector3(0,0.64,-2.4),Color("bda889"),true)
	console = Node3D.new()
	console.name = "HistoryDesk"
	console.position = Vector3(0,1.4,-2.4)
	console.rotation_degrees = Vector3(-60,180,0)
	add_child(console)
	var casing: MeshInstance3D = box("DeskCase",Vector3(2.3,1.9,0.10),Vector3.ZERO,Color("183137"),true)
	casing.reparent(console,false)
	record = _instances("FlatRecord",Vector3(0.092,0.04,0.012),false)
	record.reparent(console,false)
	record.multimesh.visible_instance_count = WIDTH*ROWS
	for g in range(ROWS):
		for x in range(WIDTH):
			record.multimesh.set_instance_transform(g*WIDTH+x,Transform3D(Basis.IDENTITY,Vector3(-(x-7)*0.10,-0.54+g*0.048,0.064)))
	record_cursor = box("FollowRecord",Vector3(1.58,0.007,0.013),Vector3(0,0,0.074),Color("ffcc72"))
	record_cursor.reparent(console,false)
	# An upright instrument beside the tilted record stays legible at eye height.
	box("ReadoutStem",Vector3(0.08,1.25,0.08),Vector3(-1.95,0.625,-2.27),Color("bda889"),true)
	var badge := Node3D.new()
	badge.name = "ReadoutHousing"
	badge.position = Vector3(-1.95,1.55,-2.35)
	badge.rotation_degrees.y = 180
	add_child(badge)
	var housing: MeshInstance3D = box("ReadoutCase",Vector3(1.5,0.60,0.075),Vector3.ZERO,Color("183137"),true)
	housing.reparent(badge,false)
	var ink: StandardMaterial3D = housing.material_override
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	reading = _label("HistoryReadout","",38)
	reading.position = Vector3(0,0,0.04)
	badge.add_child(reading)
	var axis := _label("RecordAxes","x14         GENERATIONS GO AWAY FROM YOU         x0",22)
	axis.position = Vector3(0,-0.65,0.063)
	console.add_child(axis)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls: Node3D = rack.create_panel("ONE BEGINNING / THREE BODIES", [[
		{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},
		{"type":"button","label":"REPLAY"},{"type":"button","label":"SEED"},
		{"type":"button","label":"FLIP X9"},{"type":"button","label":"ROW"}]],false)
	controls.name = "HistoryControls"
	controls.position = Vector3(0,-0.84,0.06)
	controls.scale = Vector3.ONE*1.9
	console.add_child(controls)
	var callbacks: Array[Callable] = [step_once,toggle_run,replay,next_seed,flip_seed,previous_row]
	for i in range(callbacks.size()):
		var callback: Callable = callbacks[i]
		controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_button):callback.call())

func _instances(label: String,size: Vector3,glow: bool) -> MultiMeshInstance3D:
	var n := MultiMeshInstance3D.new()
	n.name = label
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.3 if glow else 0.7
	mat.metallic = 0.25 if glow else 0.05
	if glow:
		mat.emission_enabled = true
		mat.emission = Color("375b55")
		mat.emission_energy_multiplier = 0.55
	mesh.material = mat
	mm.mesh = mesh
	mm.instance_count = WIDTH*ROWS
	mm.visible_instance_count = 0
	n.multimesh = mm
	add_child(n)
	return n

func _label(label: String,words: String,font: int) -> Label3D:
	var n := Label3D.new()
	n.name = label
	n.text = words
	n.font_size = font
	n.pixel_size = 0.0014
	n.outline_size = 0
	n.modulate = Color("ffe9cd")
	return n

func box(label: String,size: Vector3,at: Vector3,colour: Color,solid: bool=false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.65
	n.material_override = mat
	n.position = at
	add_child(n)
	if solid:
		var body := StaticBody3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		var shape := CollisionShape3D.new()
		shape.shape = bounds
		n.add_child(body)
		body.add_child(shape)
	return n

func _ramp(label: String,inner_z: float,outer_z: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-3.5,-0.60,inner_z)
	var b := Vector3(3.5,-0.60,inner_z)
	var c := Vector3(3.5,0,outer_z)
	var d := Vector3(-3.5,0,outer_z)
	var verts: Array = [a,c,b,a,d,c] if outer_z < inner_z else [a,b,c,a,c,d]
	for vertex in verts: st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("52666a")
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,mat)
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	add_child(n)
	# A closed convex wedge offers support from either end; a single triangle
	# sheet can reject a contact from its back face.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = PackedVector3Array([a,b,c,d,Vector3(a.x,-0.74,a.z),Vector3(b.x,-0.74,b.z),Vector3(c.x,-0.74,c.z),Vector3(d.x,-0.74,d.z)])
	shape.shape = hull
	n.add_child(body)
	body.add_child(shape)
