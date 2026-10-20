extends Node3D
## Side-by-side reference and interpretation. Desktop keys and carried-point activation.
const Record = preload("seed_record.gd")
const Point = preload("point_body.gd")
var model = Record.new()
var cubes: Array = []
var status_label: Label3D
var point: Node3D
var export_path := "user://seed-bench-001.json"
var controls := ["F1: FLAT", "F2: HEIGHT", "F3: KEEP", "F4: REPLAY", "F5: EXPORT", "F6: IMPORT", "F7: CLEAR", "F8: NEXT SEED"]

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
	for i in range(controls.size()):
		label_at(controls[i], Vector3((i % 4 - 1.5) * 0.30, 0.85 - (i / 4) * 0.13, 0.42), 23)
	status_label = label_at("", Vector3(0, 0.51, 0.42), 20)
	point = Point.new(); add_child(point); point.position = Vector3(-0.85, 1.05, 0.65)
	point.action_pressed.connect(point_action)
	refresh("Choose FLAT or HEIGHT, then KEEP.\nDesktop: F1-F8. VR: hold point at a label; press trigger.")

func refresh(message: String = "") -> void:
	for panel in range(2):
		var data: Array = model.cells(model.current, panel == 0)
		for i in range(16):
			cubes[panel][i].position = data[i].position
			cubes[panel][i].material_override.albedo_color = data[i].colour
	status_label.text = "Seed %s | %s | %s\n%s" % [model.current.seed, model.current.mapping_version,
		"KEPT" if not model.kept.is_empty() else "NO KEPT COPY", message]

func activate(index: int) -> void:
	var message := ""
	match index:
		0, 1: model.select_mapping(index); message = "Same 48 values. Only the height rule changes."
		2: model.keep_result(); message = "Independent copy kept. Export to keep it after closing."
		3: message = "Replayed stored values and mapping." if model.replay() else "No kept result. Use KEEP first."
		4: message = "Exported: " + export_path if model.export_record(export_path) else model.error
		5: message = "Imported stored result." if model.import_record(export_path) else model.error
		6: model.clear_kept(); message = "Memory copy cleared; exported file remains."
		7: model.acquire(model.current.seed.to_int() + 1); message = "NEW DRAWS: next seed. Kept copy unchanged."
	refresh(message)

func _input(event: InputEvent) -> void:
	# Children receive _input before the museum: consume pilot keys before its F6/F7.
	if event is InputEventKey and event.pressed and not event.echo:
		var index := [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8].find(event.keycode)
		if index >= 0: activate(index); get_viewport().set_input_as_handled()

func point_action(action: String) -> void:
	if action != "trigger_click": return
	var p := to_local(point.global_position)
	for i in range(controls.size()):
		var target := Vector3((i % 4 - 1.5) * 0.30, 0.85 - (i / 4) * 0.13, 0.42)
		if absf(p.x - target.x) < 0.14 and absf(p.y - target.y) < 0.06 and absf(p.z - target.z) < 0.18:
			activate(i); return
