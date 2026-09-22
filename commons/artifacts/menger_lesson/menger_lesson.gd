extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Read the existing nine-metre sponge at two finite cuts. The flight fixture
## retains its own collision and movement rules across every rebuild.
var source: Node3D
var frame: Node3D
var show_frame := false
var show_removed := false
var show_rule := false
var notice := ""
var kind := "menger"
var last_build_ms := 0.0

func _ready() -> void:
	source = get_parent()
	# The desk stands to the right of the entrance, outside the flight volume.
	position = Vector3(3.2, 0, -4.8)
	rotation.y = PI
	_build_compact_console(["NEXT", "BACK", "GHOST", "FRAME", "RESET", "RULE"], "WHICH HOLE CAN BECOME A PLACE?")
	_build_frame()
	set_stage(0)

func _build_frame() -> void:
	frame = Node3D.new()
	frame.name = "OuterBoundary"
	add_child(frame)
	# Frame coordinates follow the source cube, not the rotated desk.
	frame.transform = transform.affine_inverse()
	var ink := material("ffc777", true)
	for a in [-4.5, 4.5]:
		for b in [-4.5, 4.5]:
			box(Vector3(a, 4.5, b), Vector3(0.045, 9, 0.045), ink, false, frame)
			box(Vector3(0, a+4.5, b), Vector3(9, 0.045, 0.045), ink, false, frame)
			box(Vector3(a, b+4.5, 0), Vector3(0.045, 0.045, 9), ink, false, frame)
	frame.hide()

func people_inside() -> bool:
	var zone: Node3D = source.get_node_or_null("FlightBox")
	if zone == null: return false
	for group in ["em_walker", "player_body", "player"]:
		for person in get_tree().get_nodes_in_group(group):
			if person is Node3D and zone.contains_point(person.global_position): return true
	return false

func act(id: String) -> void:
	notice = ""
	match id:
		"NEXT", "BACK", "RESET":
			if people_inside():
				notice = "A visitor is inside. Leave by a ground door,\nthen press again to change the solid shape."
				refresh()
				return
			if id == "RESET":
				show_frame=false;show_removed=false;show_rule=false
			var target: int=0 if id=="RESET" else clampi(source.current_iteration + (1 if id=="NEXT" else -1),0,2)
			if id=="RESET" or target!=source.current_iteration: set_stage(target)
		"GHOST":
			show_removed = not show_removed
			_apply_views()
		"FRAME":
			show_frame = not show_frame
			_apply_views()
		"RULE":
			show_rule = not show_rule
	refresh()

func set_stage(n: int) -> void:
	n = clampi(n, 0, 2)
	var started := Time.get_ticks_usec()
	source.auto_start = false
	source.tick = "coarse"
	source.build_mode = "grow"
	# Compute the complement at each stage once. View changes never rebuild
	# the solid cubes or alter collision while someone is flying inside.
	source.removal = "ghost"
	source.reset()
	for i in range(n): source.perform_iteration()
	source.is_subdividing = false
	last_build_ms = (Time.get_ticks_usec()-started)/1000.0
	_apply_views()
	refresh()

func _apply_views() -> void:
	frame.visible = show_frame
	for child in source.get_children():
		if child is MeshInstance3D and child.get_meta("menger_removed", false):
			child.visible = show_removed

func kept_volume() -> float:
	var volume := 0.0
	for cube in source.find_all_cube_scenes():
		volume += absf(cube.global_transform.basis.determinant())
	return volume

func refresh() -> void:
	if not notice.is_empty():
		readout.text = notice
	elif show_rule:
		readout.text = "3 x 3 x 3 cells; remove the seven-cell cross\nkeep 20; repeat inside each kept cube\nTwo cuts here. Flying still meets solid cubes."
	else:
		var n: int = source.current_iteration
		readout.text = "cut %d / 2 | %d solid cubes | %.0f m3 retained\nsmallest cube %.1f m | %s\nGHOST marks removals; FRAME holds the outer size" % [n,source.find_all_cube_scenes().size(),kept_volume(),9.0/pow(3,n),"no through-hole yet" if n==0 else "smallest axial opening %.1f m"%(9.0/pow(3,n))]

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)
