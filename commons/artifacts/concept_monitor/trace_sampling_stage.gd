extends Node3D
const Record = preload("res://commons/artifacts/concept_monitor/trace_sampling_record.gd")
var record := Record.new()
var running := true
var mode := 0
var playhead := 0.0
var camera_angle := 0.0
var camera: Camera3D
var lanes: Array[Node3D] = []
var dots: Array[MultiMeshInstance3D] = []
var links: Array[MultiMeshInstance3D] = []
var ghosts: Array[MeshInstance3D] = []
var heads: Array[MeshInstance3D] = []
var counts: Array[Label] = []
var title: Label
var note: Label
var state: Label
var _last_revision := -1
var _last_index := -2
var _last_mode := -1
const COLOURS := [Color("f0cadb"), Color("e1d4b0"), Color("a6cbd3")]

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("121720")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dae0eb")
	env.ambient_light_energy = 0.75
	world.environment = env
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 40
	camera.environment = env
	camera.current = true
	add_child(camera)
	orbit(0)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var floor_node := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(40, 0.1, 40)
	floor_node.mesh = floor_mesh
	floor_node.material_override = finish(Color("202631"))
	floor_node.position.y = -0.1
	add_child(floor_node)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	for rect in [Rect2(0, 0, 1024, 102), Rect2(0, 467, 1024, 109)]:
		var panel := ColorRect.new()
		panel.position = rect.position
		panel.size = rect.size
		panel.color = Color("121720")
		overlay.add_child(panel)
	title = label(overlay, "", Vector2(32, 18), 27, Color("f0cadb"))
	note = label(overlay, "", Vector2(32, 62), 18, Color("d7dce3"))
	state = label(overlay, "", Vector2(32, 537), 17, Color("bbc4ce"))
	for i in range(3):
		var lane := Node3D.new()
		lane.position = Vector3((i - 1) * 3.3, 1.8, 0)
		add_child(lane)
		lanes.append(lane)
		var bead := SphereMesh.new()
		bead.radius = 0.031
		bead.height = 0.062
		bead.radial_segments = 8
		bead.rings = 4
		dots.append(instances(lane, bead, finish(COLOURS[i], true)))
		var rod := CylinderMesh.new()
		rod.top_radius = 0.009
		rod.bottom_radius = 0.009
		rod.height = 1.0
		rod.radial_segments = 6
		links.append(instances(lane, rod, finish(COLOURS[i], true)))
		var ghost := MeshInstance3D.new()
		ghost.material_override = finish(Color("464e5b"), true)
		lane.add_child(ghost)
		ghosts.append(ghost)
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.064
		head_mesh.height = 0.128
		head.mesh = head_mesh
		head.material_override = finish(Color("ffffff"))
		lane.add_child(head)
		heads.append(head)
		# Three-dimensional corner marks make depth legible without framing a picture.
		var axes := ImmediateMesh.new()
		axes.surface_begin(Mesh.PRIMITIVE_LINES)
		for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
			axes.surface_add_vertex(Vector3(-1.35, -1.35, -1.35))
			axes.surface_add_vertex(Vector3(-1.35, -1.35, -1.35) + axis * 2.7)
		axes.surface_end()
		var axis_mesh := MeshInstance3D.new()
		axis_mesh.mesh = axes
		axis_mesh.material_override = finish(Color("525c6c"), true)
		lane.add_child(axis_mesh)
		counts.append(label(overlay, "", Vector2(32 + i * 335, 480), 20, COLOURS[i]))
	refresh()

func advance(delta: float) -> void:
	if not running: return
	if record.capturing:
		playhead = record.elapsed
	elif not record.positions.is_empty():
		playhead += delta
		if playhead > record.elapsed + 1.8: playhead = 0.0
	refresh()

func replay() -> void:
	playhead = 0.0
	refresh()

func toggle_pause() -> void:
	running = not running
	refresh()

func next_route() -> void:
	mode = 1 - mode
	refresh()

func step_sample() -> void:
	running = false
	for time in record.times:
		if time > playhead + 0.000001:
			playhead = time
			refresh()
			return
	replay()

func orbit(angle: float) -> void:
	camera_angle = clampf(camera_angle + angle, -0.38, 0.38)
	camera.position = Vector3(sin(camera_angle) * 10.8, 4.8, cos(camera_angle) * 10.8)
	camera.look_at(Vector3(0, 1.7, 0))

func refresh() -> void:
	title.text = "ONE HAND / THREE RECORDS"
	note.text = "GRAIN: change the distance needed to keep a point. No grid snapping." if mode == 0 else "GRID: keep the same sampling distance; change where points may land."
	var index := -1
	for i in range(record.times.size()):
		if record.times[i] <= playhead: index = i
	var activity := "DRAW WITH A DRAW DOT PEN TO BEGIN"
	if not record.positions.is_empty():
		activity = "LIVE PEN" if record.capturing else ("REPLAY" if running else "PAUSED")
		activity += "  /  %s  /  %.1f s" % [record.source_name, minf(playhead, record.elapsed)]
		if record.positions.size() >= Record.LIMIT: activity += " / RECORD FULL"
	state.text = activity
	if _last_index == index and _last_revision == record.revision and _last_mode == mode: return
	_last_index = index
	_last_revision = record.revision
	_last_mode = mode
	var centre := Vector3.ZERO
	var display_scale := 1.0
	if not record.positions.is_empty():
		var bounds := AABB(record.positions[0], Vector3.ZERO)
		for p in record.positions: bounds = bounds.expand(p)
		centre = bounds.get_center()
		display_scale = 2.25 / maxf(0.20, maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)))
	for lane in range(3):
		var kept := record.samples(playhead, mode, lane)
		var pitch: float = Record.GRAINS[lane] if mode == 0 else Record.GRIDS[lane]
		counts[lane].text = "%d mm %s\n%d kept points" % [int(pitch * 1000), "spacing" if mode == 0 else "grid", kept.size()]
		dots[lane].multimesh.instance_count = kept.size()
		links[lane].multimesh.instance_count = maxi(0, kept.size() - 1)
		for i in range(kept.size()):
			var point := (kept[i] - centre) * display_scale
			dots[lane].multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, point))
			if i == 0: continue
			var previous := (kept[i - 1] - centre) * display_scale
			var direction := point - previous
			var basis := Basis(Quaternion(Vector3.UP, direction.normalized())).scaled_local(Vector3(1, direction.length(), 1))
			links[lane].multimesh.set_instance_transform(i - 1, Transform3D(basis, (point + previous) * 0.5))
		var ghost := ImmediateMesh.new()
		if index > 0:
			ghost.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
			for i in range(index + 1): ghost.surface_add_vertex((record.positions[i] - centre) * display_scale)
			ghost.surface_end()
		ghosts[lane].mesh = ghost
		heads[lane].visible = index >= 0
		if index >= 0: heads[lane].position = (record.positions[index] - centre) * display_scale

func instances(parent: Node3D, mesh: Mesh, material: Material) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	node.multimesh.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	return node

func finish(colour: Color, unshaded := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.45
	if unshaded: mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func label(parent: Node, words: String, at: Vector2, size: int, colour: Color) -> Label:
	var node := Label.new()
	node.position = at
	node.text = words
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", colour)
	parent.add_child(node)
	return node
