extends Node3D
## Simultaneous assignments of one retained set; saved earlier layouts still replay.
const Record = preload("seed_record.gd")
const Board = preload("seed_board.gd")
const CAPTIONS := ["FLAT / RGB", "BARS / MEAN", "COMBO / RGB + MEAN", "SCALE / MEAN", "ROTATE / MEAN"]
const OFFSETS := [Vector3(-0.64,1,-0.40), Vector3(0,1,-0.40), Vector3(0.64,1,-0.40), Vector3(-0.32,1,0.38), Vector3(0.32,1,0.38)]
var model = Record.new()
var cubes: Array = []
var board: Node3D
var display_root: Node3D
var display_recipe := ""
var export_path := "user://seed-bench-001.json"

func label_at(words: String, pos: Vector3, size: int = 30, owner_node: Node = null) -> Label3D:
	var label := Label3D.new()
	label.text = words; label.position = pos; label.font_size = size
	label.pixel_size = 0.001; label.no_depth_test = false
	if owner_node == null: owner_node = self
	owner_node.add_child(label)
	return label

func _ready() -> void:
	model.acquire()
	label_at("48 VALUES / FIVE SPATIAL ASSIGNMENTS", Vector3(0,1.78,-0.78), 38)
	label_at("Same triples in every tray.  u = (r + g + b) / 3", Vector3(0,1.69,-0.78), 23)
	board = Board.new(); board.name = "SeedControlBoard"
	board.position = Vector3(0,1.0,1.12); board.rotation_degrees.x = -25
	add_child(board); board.action_requested.connect(activate)
	refresh("Colour uses RGB; height, size and turn use their mean. KEEP a result.")

func box_at(parent: Node3D, size: Vector3, pos: Vector3, colour: Color) -> MeshInstance3D:
	var box := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	box.mesh = mesh; box.position = pos
	var material := StandardMaterial3D.new(); material.albedo_color = colour
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material_override = material; parent.add_child(box)
	return box

func build_views() -> void:
	if display_root != null:
		remove_child(display_root); display_root.queue_free()
	display_root = Node3D.new(); add_child(display_root); cubes.clear()
	display_recipe = model.current.schema
	var current_recipe: bool = display_recipe == model.SCHEMA
	for panel in range(5 if current_recipe else 2):
		var tray := Node3D.new()
		tray.position = OFFSETS[panel] if current_recipe else Vector3(-0.32 if panel == 0 else 0.32,1,0)
		display_root.add_child(tray)
		box_at(tray, Vector3(0.54,0.03,0.54), Vector3.ZERO, Color(0.55,0.38,0.20))
		box_at(tray, Vector3(0.46,0.008,0.46), Vector3(0,0.019,0), Color(0.025,0.035,0.045))
		var caption: String = CAPTIONS[panel] if current_recipe else ("SAVED / REFERENCE" if panel == 0 else "SAVED / ORIGINAL MAPPING")
		label_at(caption, tray.position + Vector3(0,0.02,0.31), 20, display_root)
		var panel_cubes: Array = []
		for i in range(16):
			var cube := box_at(tray, Vector3.ONE * 0.04, Vector3.ZERO, Color.WHITE)
			var marker := box_at(cube, Vector3(0.014,0.002,0.022), Vector3(0.03,0.022,0), Color(0.9,0.3,0.07))
			marker.name = "DirectionMark"; marker.visible = current_recipe and panel == 4
			panel_cubes.append(cube)
		cubes.append(panel_cubes)

func refresh(message: String = "") -> void:
	if display_recipe != model.current.schema: build_views()
	var current_recipe: bool = model.current.schema == model.SCHEMA
	for panel in range(cubes.size()):
		var mode: String = model.ASSIGNMENTS[panel] if current_recipe else "combo"
		var data: Array = model.cells(model.current, not current_recipe and panel == 0, mode)
		for i in range(16):
			cubes[panel][i].position = data[i].position
			cubes[panel][i].mesh.size = data[i].size
			cubes[panel][i].rotation.y = data[i].rotation_y
			cubes[panel][i].material_override.albedo_color = data[i].colour
	board.set_reading(model.current.seed, "FIVE VIEWS" if current_recipe else "SAVED LAYOUT", not model.kept.is_empty(), message)

func activate(index: int) -> void:
	var message := ""
	match index:
		0: model.acquire(42); message = "Seed 42 regenerated. Kept copy unchanged."
		1: model.use_current_recipe(); message = "Same stored values, five views. Earlier kept copy unchanged."
		2: model.keep_result(); message = "Independent copy kept. Export to keep it after closing."
		3: message = "Replayed stored values and recipe." if model.replay() else "No kept result. Use KEEP first."
		4: message = "Exported seed-bench-001.json to user data." if model.export_record(export_path) else model.error
		5: message = "Imported original recipe. CURRENT VIEWS forks it." if model.import_record(export_path) else model.error
		6: model.clear_kept(); message = "Memory copy cleared; exported file remains."
		7: model.acquire(model.current.seed.to_int() + 1); message = "NEW DRAWS: next seed. Kept copy unchanged."
	refresh(message)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index := [KEY_F1,KEY_F2,KEY_F3,KEY_F4,KEY_F5,KEY_F6,KEY_F7,KEY_F8].find(event.keycode)
		if index >= 0:
			board.set_open(true); activate(index); get_viewport().set_input_as_handled()
