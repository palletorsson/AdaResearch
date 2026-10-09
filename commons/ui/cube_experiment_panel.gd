extends Node3D
## Four physical controls below a flat readout, mounted in front of the builder.
## Keep the console out of specimen seating so a case cannot lift the cube.
const DataSurface = preload("res://commons/ui/data_instrument_surface.gd")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
var subject: Node3D
var text_label: Label
var surface: Node3D
var support: Node3D
var _refresh := 0.0
var _mount: Transform3D
var _last_pose := Transform3D()

func _ready() -> void:
	subject = get_parent()
	_mount = transform
	set_as_top_level(true)
	surface = DataSurface.new()
	surface.name = "ReadoutSurface"
	surface.size_m = Vector2(.76,.32)
	surface.ink = Color(1,.78,.28)
	surface.preferred_font_size = 26
	add_child(surface)
	surface.heading.text = "CORNERS / CONNECTIONS"
	text_label = surface.table
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.17,.20,.23)
	material.roughness = .65
	var strip := MeshInstance3D.new()
	strip.name = "ControlBackplate"
	strip.mesh = BoxMesh.new()
	strip.mesh.size = Vector3(.78,.19,.05)
	strip.position = Vector3(0,-.255,-.028)
	strip.material_override = material
	add_child(strip)
	_add_button("ReplayButton","REPLAY",-.285,subject.restart_animation)
	_add_button("PauseButton","PAUSE",-.095,subject.toggle_discovery_pause)
	_add_button("RestoreButton","RESTORE CUBE",.095,subject.restore_discovery_cube)
	_add_button("DiagonalButton","DIAGONALS",.285,_toggle_diagonals)
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

func _add_button(node_name: String, caption: String, x: float, action: Callable) -> void:
	var button: Node3D = preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name = node_name
	button.position = Vector3(x,-.225,.003)
	button.selected_color = Color(.28,.8,.62)
	button.released_emission_energy = .06
	button.pressed.connect(action)
	button.pressed.connect(update_readout)
	add_child(button)
	_caption(node_name+"Caption",caption,x)

func _caption(node_name: String, wording: String, x: float) -> void:
	var previous := get_node_or_null(node_name)
	if previous and previous.get_meta("text","") == wording: return
	if previous:
		remove_child(previous)
		previous.queue_free()
	var label := BakedText.make_label_mesh(wording,Color(.94,.95,1),Vector2(.175,.029),2400,true)
	label.name = node_name
	label.set_meta("text",wording)
	label.position = Vector3(x,-.31,.001)
	add_child(label)

func _sync_mount() -> void:
	var basis := subject.global_basis.orthonormalized()
	var hall: Node = subject.get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	var floor_y: float = hall.global_position.y if hall is Node3D else subject.global_position.y-1.55
	var pose := Transform3D(basis*_mount.basis, subject.global_position+basis*_mount.origin)
	# Specimen and control heights serve different actions in the museum.
	if hall is Node3D: pose.origin.y = floor_y+1.02
	if pose.is_equal_approx(_last_pose): return
	_last_pose = pose
	global_transform = pose
	var front := global_basis.z
	front.y = 0
	front = front.normalized()
	support.global_transform = Transform3D(Basis(Vector3.UP.cross(front),Vector3.UP,front),Vector3(global_position.x,floor_y,global_position.z)-front*.08)
	var height := maxf(.10,global_position.y-floor_y-.24)
	var foot: MeshInstance3D = support.get_node("Foot")
	foot.mesh.size = Vector3(.42,.035,.34)
	foot.position.y = .0175
	var stem: MeshInstance3D = support.get_node("Stem")
	stem.mesh.size = Vector3(.10,height,.10)
	stem.position.y = height*.5
	var bracket: MeshInstance3D = support.get_node("Bracket")
	bracket.mesh.size = Vector3(.24,.04,.24)
	bracket.position = Vector3(0,height,.05)

func _process(delta: float) -> void:
	_refresh += delta
	if _refresh >= .1:
		_refresh = 0
		_sync_mount()
		update_readout()

func _visible_count(nodes: Array) -> int:
	var count := 0
	for node in nodes:
		if node.visible: count += 1
	return count

func _toggle_diagonals() -> void:
	if subject.get_current_phase() == "complete": subject.toggle_discovery_diagonals()
	else: subject.discovery_message = "Finish assembly to show diagonals."

func _set_ready(button: Node3D, ready: bool) -> void:
	if button.has_meta("action_ready") and button.get_meta("action_ready") == ready: return
	button.set_meta("action_ready",ready)
	var color := Color(.85,.83,.75) if ready else Color(.16,.18,.21)
	button.released_color = color
	button.pressed_color = Color(1,.85,.3) if ready else color
	button.play_press_sound = ready
	button.update_colors()

func update_readout() -> void:
	var max_shift := 0.0
	for i in subject.vertices.size():
		max_shift = maxf(max_shift,subject.vertices[i].distance_to(subject._initial_vertices[i])*subject.cube_size)
	var surface_count: int = _visible_count(subject.triangle_meshes)
	if is_instance_valid(subject.final_cube_mesh) and subject.final_cube_mesh.visible:
		surface_count = subject.triangles.size()
	var complete: bool = subject.get_current_phase() == "complete"
	var held: bool = subject._any_handle_held()
	var message: String = subject.discovery_message
	if held: message = "Release the corner to replay or restore."
	elif message.is_empty(): message = "Move v6. Compare the other cube." if complete else "Pause when you recognise the cube."
	text_label.text = "%s%s\n%d points | %d edges\n%d / 12 triangle patches\nCorner shift: %.3f local m\n%s" % [subject.get_current_phase().to_upper()," / PAUSED" if subject.discovery_paused else "",_visible_count(subject.vertex_spheres),_visible_count(subject.edge_lines),surface_count,max_shift,message]
	_set_ready(get_node("ReplayButton"),not held)
	_set_ready(get_node("RestoreButton"),not held)
	_set_ready(get_node("PauseButton"),not complete)
	_set_ready(get_node("DiagonalButton"),complete)
	get_node("PauseButton").set_selected(subject.discovery_paused)
	get_node("DiagonalButton").set_selected(complete and subject.discovery_diagonals)
	_caption("PauseButtonCaption","RESUME" if subject.discovery_paused else "PAUSE",-.095)
	surface.refresh()
