extends Node3D
## The CA introduction retains twenty actual growth stages. The computation runs
## once; arrival plays its recorded geometry at a readable pace. Replay never
## claims to rerun the random process. One fixed final fit keeps old lines still.
const STEP_SECONDS := 0.5
const APPROACH_METRES := 3.0
var work: Node3D
var counts: Array[int] = []
var ready_to_watch := false
var playing := false
var begun := false
var stage := 0
var elapsed := 0.0
var fixed_transform := Transform3D.IDENTITY
var caption: Label3D
var strokes: MultiMeshInstance3D

func setup(source: Node3D) -> void:
	work = source
	name = "GrowthHistory"
	work.mesh_instance_lines.visible = false
	caption = Label3D.new()
	caption.text = "APPROACH TO UNFOLD\nA GROWTH HISTORY"
	caption.font_size = 28
	caption.pixel_size = 0.0017
	caption.modulate = Color(0.84, 0.93, 1.0)
	caption.position = Vector3(0, 0.66, -1.285)
	caption.rotation_degrees.y = 180
	add_child(caption)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var button: Node3D = rack.create_panel("", [[{"type":"button", "label":"REPLAY"}]], true)
	button.name = "Replay"
	button.scale = Vector3.ONE * 2.0
	button.position = Vector3(0, 0.95, -1.12)
	button.rotation_degrees = Vector3(-30, 180, 0)
	add_child(button)
	var plinth := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = Vector3(0.64, 0.88, 0.3)
	plinth.mesh = box; plinth.position = Vector3(0, 0.44, -1.12)
	var material := StandardMaterial3D.new(); material.albedo_color = Color(0.10, 0.13, 0.16)
	plinth.material_override = material; add_child(plinth)
	button.find_child("Btn_0", true, false).get_node("InteractableAreaButton").button_pressed.connect(func(_button): replay())

func capture(finished: bool) -> void:
	if not finished:
		counts.append(work.connections.size())
		return
	fixed_transform = work.mesh_instance_lines.transform
	ready_to_watch = true
	_build_strokes()
	_show_stage(0)

func _build_strokes() -> void:
	if strokes != null:
		strokes.queue_free()
	strokes = MultiMeshInstance3D.new()
	strokes.name = "RecordedLines"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.006; cylinder.bottom_radius = 0.006
	cylinder.height = 1.0; cylinder.radial_segments = 6; cylinder.rings = 1
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	cylinder.material = material
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true; mm.mesh = cylinder; mm.instance_count = work.connections.size()
	for i in range(work.connections.size()):
		var link: Array = work.connections[i]
		var a: Vector3 = fixed_transform * link[0]
		var b: Vector3 = fixed_transform * link[1]
		var direction: Vector3 = b - a
		var length := direction.length()
		if length < 0.00001:
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), a))
			continue
		var y := direction / length
		var guide := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var x := guide.cross(y).normalized()
		var z := x.cross(y).normalized()
		mm.set_instance_transform(i, Transform3D(Basis(x, y * length, z), (a + b) * 0.5))
		mm.set_instance_color(i, link[2])
	strokes.multimesh = mm; add_child(strokes)

func _process(delta: float) -> void:
	if not ready_to_watch:
		return
	if not begun:
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			observe_from(camera.global_position)
	advance(delta)

func observe_from(eye: Vector3) -> void:
	if not ready_to_watch or begun:
		return
	# Distance in world metres, including authored and museum scale.
	var centre: Vector3 = work.to_global(Vector3(0, 1.2, 0))
	if eye.distance_to(centre) <= APPROACH_METRES:
		replay()

func replay() -> void:
	if not ready_to_watch or counts.is_empty():
		return
	begun = true
	playing = true
	elapsed = 0.0
	_show_stage(0)

func advance(delta: float) -> void:
	if not playing:
		return
	elapsed += minf(delta, 0.1)
	if elapsed < STEP_SECONDS:
		return
	elapsed -= STEP_SECONDS
	if stage + 1 < counts.size():
		_show_stage(stage + 1)
	else:
		playing = false
		caption.text = "TWENTY SAVED STAGES\nREPLAY THE SAME GROWTH"

func _show_stage(index: int) -> void:
	stage = clampi(index, 0, maxi(0, counts.size() - 1))
	if strokes != null:
		strokes.multimesh.visible_instance_count = counts[stage]
	var mesh: ImmediateMesh = work.immediate_mesh
	mesh.clear_surfaces()
	if counts.is_empty() or counts[stage] == 0:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(counts[stage]):
		var link: Array = work.connections[i]
		mesh.surface_set_color(link[2]); mesh.surface_add_vertex(link[0])
		mesh.surface_set_color(link[2]); mesh.surface_add_vertex(link[1])
	mesh.surface_end()
	work.mesh_instance_lines.transform = fixed_transform
	if begun:
		caption.text = "GROWTH HISTORY\n%d OF %d" % [stage + 1, counts.size()]
