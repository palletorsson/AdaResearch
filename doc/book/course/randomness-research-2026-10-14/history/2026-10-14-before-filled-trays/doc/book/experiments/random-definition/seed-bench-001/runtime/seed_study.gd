extends Node3D
## Side-by-side reference and interpretation with one physical control board.
const Record = preload("seed_record.gd")
const Board = preload("seed_board.gd")
var model = Record.new()
var cubes: Array = []
var board: Node3D
var export_path := "user://seed-bench-001.json"

func label_at(words: String, pos: Vector3, size: int = 30) -> Label3D:
	var label := Label3D.new()
	label.text = words; label.position = pos; label.font_size = size
	label.pixel_size = 0.001; label.no_depth_test = false
	add_child(label)
	return label

func _ready() -> void:
	model.acquire()
	label_at("48 VALUES / TWO ASSIGNMENTS", Vector3(0, 1.67, -0.24), 40)
	label_at("REFERENCE: RGB, FIXED HEIGHT", Vector3(-0.32, 1.12, 0.31), 20)
	label_at("SAME RGB / SELECT A OR B", Vector3(0.32, 1.12, 0.31), 20)
	for panel in range(2):
		var tray := Node3D.new(); tray.position = Vector3(-0.32 if panel == 0 else 0.32, 1.0, 0)
		add_child(tray)
		var panel_cubes: Array = []
		for i in range(16):
			var cube := MeshInstance3D.new()
			var mesh := BoxMesh.new(); mesh.size = Vector3.ONE * 0.04
			cube.mesh = mesh
			var material := StandardMaterial3D.new()
			# Unshaded shared mapping prevents lighting differences masquerading as data changes.
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cube.material_override = material; tray.add_child(cube); panel_cubes.append(cube)
		cubes.append(panel_cubes)
		var plate := MeshInstance3D.new(); var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(0.45, 0.015, 0.45); plate.mesh = plate_mesh
		var plate_mat := StandardMaterial3D.new(); plate_mat.albedo_color = Color(0.035, 0.045, 0.055)
		plate.material_override = plate_mat; tray.add_child(plate)
	board = Board.new(); board.name = "SeedControlBoard"
	board.position = Vector3(0,1.0,0.68); board.rotation_degrees.x = -25
	add_child(board); board.action_requested.connect(activate)
	refresh("Press FLAT or BARS, then KEEP. Hand press or ray + trigger.")

func refresh(message: String = "") -> void:
	for panel in range(2):
		var data: Array = model.cells(model.current, panel == 0)
		for i in range(16):
			cubes[panel][i].position = data[i].position
			cubes[panel][i].mesh.size = data[i].size
			cubes[panel][i].material_override.albedo_color = data[i].colour
	var mapping: String = "FLAT" if model.current.mapping_version == "rgb-fixed.v2" else "BARS"
	if model.current.schema == "ada.seed-bench.v1": mapping = "LEGACY FLAT" if model.current.mapping_version == "rgb-fixed.v1" else "LEGACY FLOATING"
	board.set_reading(model.current.seed, mapping, not model.kept.is_empty(), message)

func activate(index: int) -> void:
	var message := ""
	match index:
		0, 1:
			var was_legacy: bool = model.current.schema != model.SCHEMA
			model.select_mapping(index)
			message = "Same 48 values. Fixed bottoms; bars grow upward."
			if was_legacy: message = "Forked old result into the bar recipe. Kept copy unchanged."
		2: model.keep_result(); message = "Independent copy kept. Export to keep it after closing."
		3: message = "Replayed stored values and mapping." if model.replay() else "No kept result. Use KEEP first."
		4: message = "Exported seed-bench-001.json to user data." if model.export_record(export_path) else model.error
		5: message = "Imported stored result." if model.import_record(export_path) else model.error
		6: model.clear_kept(); message = "Memory copy cleared; exported file remains."
		7: model.acquire(model.current.seed.to_int() + 1); message = "NEW DRAWS: next seed. Kept copy unchanged."
	refresh(message)

func _input(event: InputEvent) -> void:
	# Children receive _input before the museum: consume pilot keys before its F6/F7.
	if event is InputEventKey and event.pressed and not event.echo:
		var index := [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8].find(event.keycode)
		if index >= 0:
			board.set_open(true); activate(index); get_viewport().set_input_as_handled()
