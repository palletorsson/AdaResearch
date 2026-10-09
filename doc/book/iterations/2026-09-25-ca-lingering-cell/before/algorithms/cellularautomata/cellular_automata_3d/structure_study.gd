extends Node3D
## CA_ElementaryRules only: retain the 50^3 builder, expose its three states.
## The parent still computes every generation. This module owns the study clock.
var work: Node3D
var reading: Label3D
var running: bool = false
var elapsed: float = 0.0
var changed: int = -1
var active: int = 0
var fading: int = 0
var state_colours: bool = true
var budget: int = 20

func _ready() -> void:
	work = get_parent()
	work.paused = true
	work.set_process(false)
	# The old camera and light belong to the standalone preview, not the museum.
	for child in work.get_children():
		if child is Camera3D:
			child.current = false
		elif child is DirectionalLight3D:
			child.visible = false
	# Resource-local copy: a replay must not rewrite another instance's MultiMesh.
	work.mesh_instance.multimesh = work.mesh_instance.multimesh.duplicate(true)
	work.mesh_instance.scale = Vector3.ONE * 0.32
	var centre: Vector3 = Vector3(work.grid_size - Vector3i.ONE) * work.cell_size * 0.16
	work.mesh_instance.position = Vector3(-centre.x, 0.06, -centre.z)
	work.growth_seed = 23090
	# Keep VIEW meaningful even if a placer renames the scene before _ready.
	if work.gradient == null:
		var finish := Gradient.new()
		finish.set_color(0, Color("455a64"))
		finish.set_color(1, Color("eceff1"))
		finish.add_point(0.5, Color("90a4ae"))
		work.gradient = finish
	work.gradient_mode = 1
	work.use_gradient = false
	_build_console()
	replay()

func replay() -> void:
	running = false
	elapsed = 0.0
	work.time_accumulator = 0.0
	work.run_timer = 0.0
	work.generation = 0
	budget = 20
	changed = -1
	work._initialize_grid()
	# The legacy seed includes the outer shell, which _step never updates.
	# Clear BOTH buffers here: otherwise that invisible shell alternates on swap.
	var size: Vector3i = work.grid_size
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				if x == 0 or y == 0 or z == 0 or x == size.x - 1 or y == size.y - 1 or z == size.z - 1:
					var i: int = x + y * work.stride_y + z * work.stride_z
					work.current_state[i] = 0
					work.next_state[i] = 0
	work._update_visuals()
	_count_states()
	refresh()

func step_once() -> void:
	running = false
	elapsed = 0.0
	if work.generation >= budget:
		refresh()
		return
	_advance()

func _advance() -> void:
	work._step()
	# After swapping, next_state is the previous generation, not a prediction.
	changed = 0
	for i in range(work.total_cells):
		if work.current_state[i] != work.next_state[i]:
			changed += 1
	_count_states()
	if work.generation >= budget:
		running = false
	refresh()

func _count_states() -> void:
	active = 0
	fading = 0
	for state in work.current_state:
		if state == 1:
			active += 1
		elif state > 1:
			fading += 1

func toggle_run() -> void:
	if work.generation < budget:
		running = not running
	elapsed = 0.0
	refresh()

func extend_budget() -> void:
	budget += 20
	running = false
	elapsed = 0.0
	refresh()

func toggle_view() -> void:
	state_colours = not state_colours
	work.use_gradient = not state_colours
	work._update_visuals()
	refresh()

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	if elapsed >= 1.0:
		elapsed = 0.0
		_advance()

func readback() -> Dictionary:
	return {"generation": work.generation, "budget": budget, "active": active,
		"fading": fading, "changed": changed, "drawn": work.mesh_instance.multimesh.visible_instance_count,
		"running": running, "state_colours": state_colours, "seed": work.growth_seed}

func refresh() -> void:
	var status: String = "RUN" if running else "HELD"
	if work.generation >= budget:
		status = "LIMIT / +20"
	var change_text: String = "NO STEP YET" if changed < 0 else "CHANGED %d" % changed
	reading.text = "A CELL WITH A PAST\nGEN %d / %d   %s\n\nPINK   %d ACTIVE [1]\nGREEN  %d FADING [2]\nDRAWN %d   %s\n\n%s\n6-8 / 6-8 / 3 / M\nEDGE CELLS STAY EMPTY" % [work.generation, budget, status, active, fading, work.mesh_instance.multimesh.visible_instance_count, change_text, "STATE COLOURS" if state_colours else "HEIGHT COLOURS / SAME CELLS"]

func _build_console() -> void:
	# Metre-sized furniture on the entry rim, independent of the reduced mesh.
	box("ConsoleFoot", Vector3(1.15, 0.12, 0.60), Vector3(-1.65, 0.06, -2.86), Color("3c4c52"), true)
	box("ConsoleStem", Vector3(0.13, 0.83, 0.13), Vector3(-1.65, 0.50, -2.86), Color("a7b0ae"), true)
	var console := Node3D.new()
	console.name = "Console"
	console.position = Vector3(-1.65, 1.05, -2.86)
	console.rotation_degrees = Vector3(-28, 180, 0)
	add_child(console)
	var casing: MeshInstance3D = box("ReadoutCase", Vector3(1.15, 0.78, 0.08), Vector3.ZERO, Color("152d33"))
	casing.reparent(console, false)
	casing.position.y = 0.29
	reading = Label3D.new()
	reading.name = "Readout"
	reading.font_size = 40
	reading.pixel_size = 0.0015
	reading.outline_size = 0
	reading.modulate = Color("ffe8ce")
	reading.position = Vector3(0, 0.29, 0.045)
	console.add_child(reading)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls: Node3D = rack.create_panel("FOLLOW ONE GENERATION", [[
		{"type": "button", "label": "STEP"}, {"type": "button", "label": "RUN"},
		{"type": "button", "label": "REPLAY"}, {"type": "button", "label": "VIEW"},
		{"type": "button", "label": "+20"}]], false)
	controls.name = "StudyControls"
	controls.position = Vector3(0, -0.32, 0.02)
	controls.scale = Vector3.ONE * 1.6
	console.add_child(controls)
	var callbacks: Array[Callable] = [step_once, toggle_run, replay, toggle_view, extend_budget]
	for i in range(callbacks.size()):
		var callback: Callable = callbacks[i]
		controls.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton").button_pressed.connect(func(_button): callback.call())

func box(label: String, size: Vector3, at: Vector3, colour: Color, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.7
	n.material_override = mat
	n.position = at
	add_child(n)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		n.add_child(body)
		body.add_child(shape)
	return n
