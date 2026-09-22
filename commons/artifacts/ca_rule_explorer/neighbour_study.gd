extends Node3D
## Local teaching furniture for CA_Introduction. The existing explorer owns all state.
var work: Node3D
var reading: Label3D
var markers: Array[MeshInstance3D] = []
var elapsed: float = 0.0

func _ready() -> void:
	work = get_parent()
	box("Desk", Vector3(1.78, 0.10, 2.20), Vector3(0, -0.09, 0.18), Color("c9c5bd"), true)
	for x in [-0.68, 0.68]:
		box("Leg", Vector3(0.12, 0.90, 1.25), Vector3(x, -0.59, 0.10), Color("aaa89f"), true)
	var plate := Node3D.new()
	plate.name = "Witness"
	plate.position = Vector3(1.21, 0.25, 0.02)
	plate.rotation_degrees.x = -35
	add_child(plate)
	var case_mesh: MeshInstance3D = box("WitnessCase", Vector3(0.72, 0.88, 0.06), Vector3.ZERO, Color("243238"))
	case_mesh.reparent(plate, false)
	reading = Label3D.new()
	reading.name = "Readout"
	reading.font_size = 25
	reading.pixel_size = 0.00105
	reading.modulate = Color("ffd2df")
	reading.outline_size = 0
	reading.position.z = 0.036
	plate.add_child(reading)
	box("WitnessStalk", Vector3(0.07, 0.55, 0.07), Vector3(1.21, -0.20, 0.02), Color("aaa89f"))
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls: Node3D = rack.create_panel("NEXT GENERATION", [[
		{"type":"button", "label":"STEP"}, {"type":"button", "label":"RUN"},
		{"type":"button", "label":"SEED"}, {"type":"button", "label":"CELL"}]], false)
	controls.name = "StudyControls"
	controls.position = Vector3(0, 0.02, 1.22)
	controls.rotation_degrees.x = -30
	controls.scale = Vector3.ONE * 1.8
	add_child(controls)
	var callbacks: Array[Callable] = [work.step, work.toggle_pause, work.toggle_seed, next_cell]
	for i in range(callbacks.size()):
		var callback: Callable = callbacks[i]
		controls.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton").button_pressed.connect(func(_button): callback.call(); refresh())
	# Thin borders leave the cell's own on/off colour visible.
	for j in range(3):
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(work._cell_size.x * 0.95, 0.004, 0.006)
		marker.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("ff80b4") if j == 1 else Color("ffd77d")
		marker.material_override = mat
		add_child(marker)
		markers.append(marker)
	refresh()

func next_cell() -> void:
	work.sample_cell = (work.sample_cell + 1) % work.cells_x

func refresh() -> void:
	var d: Dictionary = work.neighbourhood_readback()
	reading.text = "THREE CELLS\n\nGEN %d / %s\nCELL %d OF %d\n\nLEFT  SELF  RIGHT\n%d       %d       %d\n\nNEXT: %d\nRULE %d\n\nSEED: %s\nEDGES WRAP" % [d.generation, "RUN" if d.running else "HELD", d.cell, d.width, d.inputs[0], d.inputs[1], d.inputs[2], d.next, d.rule, d.seed.to_upper()]
	for j in range(3):
		var col: int = posmod(int(d.cell) + j - 1, work.cells_x)
		markers[j].position = Vector3((col - work.cells_x / 2.0 + 0.5) * work._cell_size.x, 0.023, -work.board_size / 2.0 + work._cell_size.y * 0.08)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.1:
		elapsed = 0.0
		refresh()

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
