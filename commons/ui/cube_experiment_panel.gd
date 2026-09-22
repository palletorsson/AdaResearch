extends Node3D
## Side controls read the builder's actual visible layers and vertex data.
const Casing = preload("res://commons/ui/instrument_panel_case.gd")
var subject: Node3D
var text_label: Label3D
var pause_caption: Label3D
var _refresh: float = 0.0

func _ready() -> void:
	subject = get_parent()
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.10,0.96)
	screen.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.025,0.035,0.055)
	screen.material_override = material
	add_child(screen)
	var casing := Casing.new()
	casing.name = "Casing"
	add_child(casing)
	casing.fit_rect(Vector2.ZERO,quad.size,Color(1.0,0.78,0.15))
	text_label = Label3D.new()
	text_label.name = "Readout"
	text_label.font_size = 32
	text_label.pixel_size = 0.0015
	text_label.width = 650
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.position = Vector3(-0.49,0.42,0.006)
	text_label.outline_size = 0
	add_child(text_label)
	_add_button("ReplayButton","REPLAY",Vector2(-0.27,-0.12),subject.restart_animation)
	pause_caption = _add_button("PauseButton","PAUSE",Vector2(0.27,-0.12),subject.toggle_discovery_pause)
	_add_button("RestoreButton","RESTORE CUBE",Vector2(-0.27,-0.35),subject.restore_discovery_cube)
	_add_button("DiagonalButton","DIAGONALS",Vector2(0.27,-0.35),subject.toggle_discovery_diagonals)
	update_readout()

func _add_button(node_name: String, caption: String, at: Vector2, action: Callable) -> Label3D:
	var button: Node3D = preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name = node_name
	button.position = Vector3(at.x,at.y,0.035)
	button.pressed.connect(action)
	button.pressed.connect(update_readout)
	add_child(button)
	var label := Label3D.new()
	label.text = caption
	label.font_size = 28
	label.pixel_size = 0.0015
	label.position = Vector3(at.x,at.y+0.078,0.01)
	label.outline_size = 0
	add_child(label)
	return label

func _process(delta: float) -> void:
	_refresh += delta
	if _refresh >= 0.1:
		_refresh = 0.0
		update_readout()

func _visible_count(nodes: Array) -> int:
	var count := 0
	for node in nodes:
		if node.visible: count += 1
	return count

func update_readout() -> void:
	var max_shift := 0.0
	for i in subject.vertices.size():
		max_shift = maxf(max_shift,subject.vertices[i].distance_to(subject._initial_vertices[i])*subject.cube_size)
	var surface_count: int = _visible_count(subject.triangle_meshes)
	if is_instance_valid(subject.final_cube_mesh) and subject.final_cube_mesh.visible:
		surface_count = subject.triangles.size()
	text_label.text = "CORNERS / CONNECTIONS\n%s%s\nVisible: %d points | %d edges\nTriangle patches: %d / 12\nLargest corner shift: %.3f local m\n%s" % [subject.get_current_phase().to_upper()," / PAUSED" if subject.discovery_paused else "",_visible_count(subject.vertex_spheres),_visible_count(subject.edge_lines),surface_count,max_shift,subject.discovery_message]
	pause_caption.text = "RESUME" if subject.discovery_paused else "PAUSE"
