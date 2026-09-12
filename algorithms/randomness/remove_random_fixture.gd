extends Node3D
## The recovered 8x8 relationship is an owned model, independent of the walkable floor.
const SIDE := 8
const PITCH := 0.14
var _remover: Node3D
var _status: Label3D
var _last: Label3D
var panel: Node3D

func build(remover: Node3D) -> void:
	_remover = remover
	# the bench replays: RESET re-seeds the run, NEW SEED starts another (R1b, 2026-09-11);
	# its seeds are five digits, so the status can name one a visitor can repeat
	_remover.set("replay_on_reset", true)
	_remover.call("set_random_seed", randi_range(10000, 99999))
	_box("Pedestal", Vector3(0.8, 0.96, 0.8), Vector3(0, 0.48, 0), Color(0.08, 0.11, 0.16), true)
	_box("Board", Vector3(1.4, 0.06, 1.4), Vector3(0, 0.99, 0), Color(0.07, 0.10, 0.14), true)
	var cubes := MultiMeshInstance3D.new()
	cubes.name = "GridMultiMesh"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.82, 0.82, 0.82)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.7
	mesh.material = material
	mm.mesh = mesh
	mm.instance_count = SIDE * SIDE
	for z in range(SIDE):
		for x in range(SIDE):
			mm.set_instance_transform(z * SIDE + x, Transform3D(Basis.IDENTITY, Vector3(x, 0, z)))
			mm.set_instance_color(z * SIDE + x, Color.WHITE)
			# Permanent slot plates survive subtraction and preserve each address.
			_box("Slot_%d_%d" % [x,z], Vector3(0.125, 0.006, 0.125), Vector3((x-3.5)*PITCH, 1.025, (z-3.5)*PITCH), Color(0.45, 0.51, 0.57))
	cubes.multimesh = mm
	cubes.position = Vector3(-3.5 * PITCH, 1.086, -3.5 * PITCH)
	cubes.scale = Vector3.ONE * PITCH
	add_child(cubes)
	for i in range(SIDE):
		var col := _label(str(i), Vector3((i-3.5)*PITCH, 1.032, -0.64), 32, 0.0018)
		col.rotation_degrees.x = -90
		var row := _label(str(i), Vector3(-0.64, 1.032, (i-3.5)*PITCH), 32, 0.0018)
		row.rotation_degrees.x = -90
	# the status and the legend cased on a post at the tray's LEFT, turned to the visitor, at
	# reading height; they had floated on the wall behind and above the tray (Astra's
	# visual review, 12 September: "the state text floats much farther away")
	_status = _label("", Vector3(-1.12, 1.16, 0.40), 24, 0.0016)
	_status.rotation_degrees = Vector3(0, 30, 0)
	_last = _label("", Vector3(-1.12, 1.00, 0.40), 19, 0.0014)
	_last.rotation_degrees = Vector3(0, 30, 0)
	_box("StatusPlate", Vector3(1.0, 0.36, 0.012), Vector3(-1.12, 1.08, 0.40), Color(0.07, 0.10, 0.14))
	get_node("StatusPlate").rotation_degrees = Vector3(0, 30, 0)
	get_node("StatusPlate").position += Vector3(-0.5, 0, -0.87) * 0.008   # behind the text (its normal for yaw +30° is (0.5, 0, 0.87))
	_box("StatusPost", Vector3(0.04, 0.90, 0.04), Vector3(-1.12, 0.45, 0.40), Color(0.07, 0.10, 0.14))
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	panel = rack.create_panel("CHOOSE THE SET, THEN REMOVE", [
		[{"type":"button", "label":"RANGE"}, {"type":"button", "label":"ROW"}, {"type":"button", "label":"COLUMN"}, {"type":"button", "label":"ALL"}],
		[{"type":"button", "label":"REMOVE ONE"}, {"type":"button", "label":"RESET"}, {"type":"button", "label":"NEW SEED"}]
	])
	panel.name = "Controls"
	panel.scale = Vector3.ONE * 3.0
	# off the tray, to its right and turned to the visitor, so the near rows stay in view
	# while a set is chosen (12 September; it had leaned in front of the tray)
	panel.position = Vector3(0.95, 0.82, 0.70)
	panel.rotation_degrees = Vector3(-35, -35, 0)
	add_child(panel)
	for i in range(4):
		var mode: String = ["Range", "Row", "Column", "All"][i]
		var button := panel.find_child("Btn_%d" % i, true, false)
		button.connect("pressed", func(): _remover.call("choose_mode", mode))
	panel.find_child("Btn_4", true, false).connect("pressed", func(): _remover.call("remove_one"))
	panel.find_child("Btn_5", true, false).connect("pressed", func(): _remover.call("reset_and_find_instances"))
	panel.find_child("Btn_6", true, false).connect("pressed", func():
		_remover.call("set_random_seed", randi_range(10000, 99999))
		_remover.call("reset_and_find_instances"))
	_remover.connect("state_changed", _update_status)
	_update_status()

func _update_status() -> void:
	var state: Dictionary = _remover.call("get_state")
	var region := str(state["mode"]).to_upper()
	if region == "RANGE": region = "RANGE: columns %.0f-%.0f, rows %.0f-%.0f" % [_remover.get("x_min"), _remover.get("x_max"), _remover.get("z_min"), _remover.get("z_max")]
	elif region == "ROW": region = "ROW %d" % int(_remover.get("target_row"))
	elif region == "COLUMN": region = "COLUMN %d" % int(_remover.get("target_column"))
	_status.text = "%s · seed %d\nEligible: %d   Remaining: %d   Removed: %d" % [region, int(state.get("seed", 0)), state["eligible_at_start"], state["remaining"], state["removed"]]
	var index: int = int(state["last_selected"] if state["busy"] else state["last_removed"])
	_last.text = "Amber: can be chosen. Grey: outside the set.\nRESET replays this seed's order; NEW SEED starts another."
	if int(state["remaining"]) == 0 and bool(state["bound"]) and not bool(state["busy"]):
		# the set is empty — after a full run, or a mask that admitted nothing
		_last.text = "No eligible cubes remain%s.\nRESET replays this seed; a mode button or NEW SEED starts another." % ((" — last removed: column %d, row %d" % [index % SIDE, index / SIDE]) if index >= 0 else "")
	elif index >= 0:
		_last.text = "%s column %d, row %d\nAmber: can be chosen. Grey: outside the set." % ["Choosing" if state["busy"] else "Last removed:", index % SIDE, index / SIDE]

func _label(text: String, pos: Vector3, font_size: int, pixel_size: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = Color(0.92, 0.95, 1.0)
	label.no_depth_test = false
	add_child(label)
	return label

func _box(title: String, size: Vector3, pos: Vector3, colour: Color, solid: bool = false) -> void:
	var node := MeshInstance3D.new()
	node.name = title
	node.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.8
	mesh.material = material
	node.mesh = mesh
	add_child(node)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		node.add_child(body)
