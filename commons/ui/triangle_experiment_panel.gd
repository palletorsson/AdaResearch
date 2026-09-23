extends Node3D
## One compact instrument for boundary/fill and first-vertex fan comparisons.
## The case is excluded from specimen seating, but follows the owner's pose.
const DataSurface = preload("res://commons/ui/data_instrument_surface.gd")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
var text_label: Label
var subject: Node3D
var is_puzzle: bool
var _refresh := 0.0
var shift_button: Node3D
var shift_caption: MeshInstance3D
var fill_button: Node3D
var new_outline_button: Node3D
var surface: Node3D
var support: Node3D
var _shift_ready := false
var _mount: Transform3D
var _last_pose := Transform3D()

func _ready() -> void:
	subject = get_parent()
	is_puzzle = subject.has_method("toggle_discovery_face")
	_mount = transform
	set_as_top_level(true)
	surface = DataSurface.new()
	surface.name = "ReadoutSurface"
	surface.size_m = Vector2(.76,.42)
	surface.preferred_font_size = 26
	add_child(surface)
	surface.heading.text = "BOUNDARY / FACE" if is_puzzle else "OUTLINE / TRIANGLE FAN"
	text_label = surface.table
	var strip := MeshInstance3D.new()
	strip.name = "ControlBackplate"
	strip.mesh = BoxMesh.new()
	strip.mesh.size = Vector3(.78,.19,.05)
	strip.position = Vector3(0,-.30,-.028)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.17,.20,.23)
	material.roughness = .65
	strip.material_override = material
	add_child(strip)
	fill_button = _button("FillButton",.25 if not is_puzzle else 0)
	fill_button.pressed.connect(_toggle_fill)
	_caption("FillCaption","SHOW / HIDE FILL",fill_button.position.x)
	if not is_puzzle:
		# Move the existing action and its connection into the same tilted frame.
		new_outline_button = subject.get_node("NewOutlineButton")
		new_outline_button.reparent(self,false)
		new_outline_button.position = Vector3(-.25,-.27,.003)
		_caption("OutlineCaption","NEW OUTLINE",-.25)
		shift_button = _button("ShiftStartButton",0)
		shift_button.pressed.connect(_shift_start)
		shift_caption = _caption("ShiftStartCaption","SHIFT START",0)
		var old_coordinates: Label3D = subject.get_node_or_null("GrabPoint/MeshInstance3D/Label3D")
		if old_coordinates:
			old_coordinates.visible = false
			old_coordinates.set("show_position",false)
	# This support uses the hall's floor, never the specimen's plinth top.
	support = Node3D.new()
	support.name = "UprightSupport"
	support.set_as_top_level(true)
	add_child(support)
	for part in ["Foot","Stem","Bracket"]:
		var mesh := MeshInstance3D.new()
		mesh.name = part
		mesh.mesh = BoxMesh.new()
		mesh.material_override = material
		support.add_child(mesh)
	_sync_mount()
	update_readout()

func _button(node_name: String, x: float) -> Node3D:
	var button: Node3D = load("res://commons/interactables/push_button.tscn").instantiate()
	button.name = node_name
	button.position = Vector3(x,-.27,.003)
	button.selected_color = Color(.28,.8,.62)
	button.released_emission_energy = .06
	add_child(button)
	return button

func _caption(node_name: String, wording: String, x: float) -> MeshInstance3D:
	var label := BakedText.make_label_mesh(wording,Color(.94,.95,1),Vector2(.235,.029),2400,true)
	label.name = node_name
	label.position = Vector3(x,-.353,.001)
	add_child(label)
	return label

func _sync_mount() -> void:
	var basis := subject.global_basis.orthonormalized()
	var pose := Transform3D(basis*_mount.basis, subject.global_position+basis*_mount.origin)
	if pose.is_equal_approx(_last_pose): return
	_last_pose = pose
	global_transform = pose
	var hall: Node = subject.get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	var floor_y: float = hall.global_position.y if hall is Node3D else subject.global_position.y-(1.5 if is_puzzle else 1.4)
	var front := global_basis.z
	front.y = 0
	front = front.normalized()
	var upright := Basis(Vector3.UP.cross(front),Vector3.UP,front)
	support.global_transform = Transform3D(upright,Vector3(global_position.x,floor_y,global_position.z)-front*.07)
	var height := maxf(.10,global_position.y-floor_y-.24)
	var foot: MeshInstance3D = support.get_node("Foot")
	foot.mesh.size = Vector3(.40,.035,.32)
	foot.position.y = .0175
	var stem: MeshInstance3D = support.get_node("Stem")
	stem.mesh.size = Vector3(.10,height,.10)
	stem.position.y = height*.5
	var bracket: MeshInstance3D = support.get_node("Bracket")
	bracket.mesh.size = Vector3(.24,.04,.22)
	bracket.position = Vector3(0,height,.05)

func _process(delta: float) -> void:
	_refresh += delta
	if _refresh >= .1:
		_refresh = 0
		_sync_mount()
		update_readout()

func _toggle_fill() -> void:
	if is_puzzle: subject.toggle_discovery_face()
	elif not subject.completed_triangles.is_empty(): subject.toggle_fill_visibility()
	update_readout()

func _shift_start() -> void:
	# Owner rechecks held pen/corners and partial outlines at the input boundary.
	subject.shift_start()
	update_readout()

func _set_ready(button: Node3D, ready: bool) -> void:
	if button.has_meta("action_ready") and button.get_meta("action_ready") == ready: return
	button.set_meta("action_ready",ready)
	var color := Color(.85,.83,.75) if ready else Color(.16,.18,.21)
	button.released_color = color
	button.pressed_color = Color(1,.85,.3) if ready else color
	button.play_press_sound = ready
	button.update_colors()

func update_readout() -> void:
	if is_puzzle:
		var fitted := 0
		for line in subject.snap_lines:
			if line.is_at_target(): fitted += 1
		var closed: bool = subject.is_completed
		var filled: bool = is_instance_valid(subject.discovery_face) and subject.discovery_face.visible
		text_label.text = "Edges at targets: %d / 3\nBoundary: %s\nFill: %s\n\n%s" % [fitted,"closed" if closed else "open", "visible" if filled else "hidden", "Try the fill. Look from both sides." if closed else "Close the three edges first."]
		_set_ready(fill_button,closed)
		fill_button.set_selected(filled)
	else:
		var state: Dictionary = subject.get_experiment_state()
		var first: int = state.selected_start_index
		var drawing_first: int = state.path_first_index if state.partial_outline else -1
		var selection := "No closed loop selected"
		if state.selected_loop_index >= 0:
			selection = "Selected loop %d | START %d" % [state.selected_loop_number,state.selected_start_number]
		var status: String = "SHIFT START keeps this boundary." if state.shift_start_ready else state.shift_start_reason
		var tip: Vector3 = subject.get("_draw_sphere").global_position
		text_label.text = "Path entries: %d | Drawing first: %s\nLoops: %d | Triangles: %d | Fill: %s\n%s\nGrid: %.2f m | Hold: %.1f s\nTip (m): %.2f, %.2f, %.2f\n%s" % [state.path_entries,str(drawing_first+1) if drawing_first>=0 else "--",state.filled_loops,state.logical_triangles,"on" if state.fills_visible else "off",selection,subject.grid_size,subject.hold_place_seconds,tip.x,tip.y,tip.z,status]
		_shift_ready = state.shift_start_ready
		_set_ready(shift_button,_shift_ready)
		_set_ready(fill_button,state.filled_loops > 0)
		fill_button.set_selected(state.filled_loops > 0 and state.fills_visible)
		shift_caption.material_override.albedo_color = Color.WHITE if _shift_ready else Color(.55,.58,.63)
		for i in subject.point_indicators.size():
			var point: Node3D = subject.point_indicators[i]
			var wording := "START %d" % (i+1) if i == first else str(i+1)
			if i == drawing_first: wording = ("START %d\n" % (i+1) if i == first else "") + "DRAW START %d" % (i+1)
			_set_corner_number(point,wording,Color(1,.8,.2) if i == first else Color.WHITE)
	surface.refresh()

func _set_corner_number(point: Node3D, wording: String, color: Color) -> void:
	var previous: MeshInstance3D = point.get_node_or_null("CornerNumber")
	if previous and previous.get_meta("text","") == wording and previous.get_meta("ink",Color.WHITE) == color: return
	if previous:
		point.remove_child(previous)
		previous.queue_free()
	var size := Vector2(.065,.05) if wording.length()<4 else Vector2(.24,.08 if wording.contains("\n") else .05)
	var number := BakedText.make_panel_mesh(wording,Color(.025,.035,.055),color,size,2400,true)
	number.name = "CornerNumber"
	number.set_meta("text",wording)
	number.set_meta("ink",color)
	number.position.y = .09
	number.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	point.add_child(number)
