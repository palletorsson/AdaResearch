extends Node3D
## A filmed 3D reveal of source mesh data. Separation is an illustration only.
const PALETTE := [Color("f0ccd6"), Color("a6cbd0"), Color("e2d5ac"), Color("b9b3d2")]
const STARTS := [0.0, 2.4, 4.8, 8.8, 12.8]
const DURATION := 17.0
var running := true
var playhead := 0.0
var camera_angle := 0.0
var record: Dictionary = {}
var _signature := -1
var camera: Camera3D
var geometry: Node3D
var corners: Array[MeshInstance3D] = []
var corner_labels: Array[Label3D] = []
var boundaries: Array[MeshInstance3D] = []
var faces: Array[Node3D] = []
var face_directions: Array[Vector3] = []
var title: Label
var detail: Label
var provenance: Label
var counter: Label
var _centre := Vector3.ZERO
var _scale := 1.0

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("151b24")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dae3ee")
	env.ambient_light_energy = 0.65
	world.environment = env
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 38
	camera.current = true
	add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, -24, 0)
	light.light_energy = 1.25
	light.shadow_enabled = true
	add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-4, 5, -3)
	fill.light_color = Color("a6cbd0")
	fill.omni_range = 16
	fill.light_energy = 2.0
	add_child(fill)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(60, 0.1, 60)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.position.y = -0.15
	floor_node.material_override = finish(Color("242e3b"))
	add_child(floor_node)
	geometry = Node3D.new()
	geometry.position = Vector3(0, 2.5, 0)
	add_child(geometry)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	for rect in [Rect2(0, 0, 1024, 95), Rect2(0, 484, 1024, 92)]:
		var panel := ColorRect.new()
		panel.position = rect.position
		panel.size = rect.size
		panel.color = Color("151b24")
		overlay.add_child(panel)
	title = label(overlay, Vector2(30, 17), 28, Color("f0ccd6"))
	detail = label(overlay, Vector2(30, 57), 19, Color("e0e4e9"))
	counter = label(overlay, Vector2(30, 495), 21, Color("f0ccd6"))
	provenance = label(overlay, Vector2(30, 538), 16, Color("aab8c8"))
	refresh()

func set_record(value: Dictionary) -> bool:
	var signature := hash(value)
	if signature == _signature: return false
	_signature = signature
	record = value.duplicate(true)
	playhead = 0.0
	rebuild()
	refresh()
	return true

func rebuild() -> void:
	for child in geometry.get_children():
		geometry.remove_child(child)
		child.queue_free()
	corners.clear()
	corner_labels.clear()
	boundaries.clear()
	faces.clear()
	face_directions.clear()
	var points: PackedVector3Array = record.get("points", PackedVector3Array())
	if points.is_empty(): return
	var bounds := AABB(points[0], Vector3.ZERO)
	for point in points: bounds = bounds.expand(point)
	_centre = bounds.get_center()
	_scale = 4.0 / maxf(0.25, bounds.size.length())
	var indices: Array = record.get("indices", [])
	for i in range(points.size()):
		var corner := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.058 if i != 0 else 0.085
		ball.height = ball.radius * 2
		ball.radial_segments = 16
		ball.rings = 8
		corner.mesh = ball
		corner.position = display_position(points[i])
		corner.material_override = finish(Color("f0ccd6") if i == 0 else Color("f3eee3"))
		geometry.add_child(corner)
		corners.append(corner)
		var marker := Label3D.new()
		marker.text = str(indices[i]) + ("  START" if i == 0 else "")
		marker.position = corner.position + Vector3(0, 0.19, 0)
		marker.pixel_size = 0.006
		marker.font_size = 29
		marker.modulate = Color("f0ccd6") if i == 0 else Color("ece9e1")
		marker.outline_size = 5
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		geometry.add_child(marker)
		corner_labels.append(marker)
	var count := points.size() if bool(record.get("closed", false)) else points.size() - 1
	for i in range(count):
		boundaries.append(rod(geometry, display_position(points[i]), display_position(points[(i + 1) % points.size()]), 0.016, Color("a6cbd0")))
	var triangles: Array = record.get("triangles", [])
	for i in range(triangles.size()):
		var data: Dictionary = triangles[i]
		var part := Node3D.new()
		geometry.add_child(part)
		var mesh_node := MeshInstance3D.new()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var vertices: PackedVector3Array = data.vertices
		var normals: PackedVector3Array = data.normals
		for j in range(vertices.size()):
			st.set_normal(normals[j])
			st.add_vertex(display_position(vertices[j]))
		mesh_node.mesh = st.commit()
		var mat := finish(PALETTE[i % PALETTE.size()])
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_node.material_override = mat
		part.add_child(mesh_node)
		for j in range(3):
			rod(part, display_position(vertices[j]), display_position(vertices[(j + 1) % 3]), 0.009, Color("222b34"))
		faces.append(part)
		var direction := (vertices[1] - vertices[0]).cross(vertices[2] - vertices[0]).normalized()
		face_directions.append(direction)

func display_position(point: Vector3) -> Vector3:
	return (point - _centre) * _scale

func advance(delta: float) -> void:
	if running:
		playhead = fmod(playhead + delta, DURATION)
		refresh()

func replay() -> void:
	playhead = 0.0
	refresh()

func toggle_pause() -> void:
	running = not running
	refresh()

func step_sample() -> void:
	running = false
	for time in STARTS:
		if time > playhead + 0.01:
			playhead = time + 0.01
			refresh()
			return
	replay()

func next_route() -> void:
	orbit(PI * 0.5)

func orbit(angle: float) -> void:
	camera_angle += angle
	refresh()

func refresh() -> void:
	if camera == null: return
	var phase := 0
	for i in range(STARTS.size()):
		if playhead >= STARTS[i]: phase = i
	# A real perspective camera travels gently around the copied 3D drawing.
	var angle := camera_angle + 0.25 + 0.28 * sin(playhead / DURATION * TAU)
	camera.position = Vector3(sin(angle) * 10.4, 4.9, cos(angle) * 10.4)
	camera.look_at(Vector3(0, 2.45, 0))
	var closed := bool(record.get("closed", false))
	var fills := bool(record.get("fills_visible", true))
	var points: PackedVector3Array = record.get("points", PackedVector3Array())
	title.text = ["01 / POSITIONS", "02 / A BOUNDARY", "03 / A FAN FROM ONE CORNER", "04 / THE FACES, APART", "05 / ONE DRAWING"][phase]
	detail.text = ["Each number refers to a stored position.", "The order decides which corners meet.", "Keep the first corner; take the next two in order.", "Lift the copied faces to see what the surface contains.", "The same faces return to the same stored positions."][phase]
	if points.is_empty():
		title.text = "A DRAWING / REVEALED"
		detail.text = str(record.get("error", "Draw with the triangle tool to begin."))
		if detail.text.is_empty(): detail.text = "Draw with the triangle tool to begin."
	elif not closed:
		title.text = "AN OPEN BOUNDARY"
		detail.text = "This path has not closed. The drawing tool has made no face for it."
	var corner_progress := clampf(playhead / 1.5, 0.0, 1.0)
	for i in range(corners.size()):
		corners[i].visible = phase > 0 or i < maxi(1, ceili(corners.size() * corner_progress))
		corner_labels[i].visible = corners[i].visible and corners.size() <= 16
	var boundary_progress := clampf((playhead - STARTS[1]) / 1.4, 0.0, 1.0)
	for i in range(boundaries.size()):
		boundaries[i].visible = phase > 1 or (phase == 1 and i < ceili(boundaries.size() * boundary_progress))
	var face_progress := clampf((playhead - STARTS[2]) / 3.0, 0.0, 1.0)
	var shown := 0
	var separation := 0.0
	if phase == 3: separation = smoothstep(STARTS[3], STARTS[3] + 1.6, playhead)
	if phase == 4: separation = 1.0 - smoothstep(STARTS[4], STARTS[4] + 1.5, playhead)
	for i in range(faces.size()):
		faces[i].visible = fills and phase >= 2 and (phase > 2 or i < maxi(1, ceili(faces.size() * face_progress)))
		faces[i].position = face_directions[i] * separation * (0.55 + float(i) * 0.30)
		if faces[i].visible: shown += 1
	counter.text = "%d positions  /  %d of %d fan triangles" % [points.size(), shown, faces.size()]
	if closed and not fills: counter.text += "  /  FILL HIDDEN AT THE TOOL"
	var source_name := str(record.get("source_name", "waiting for the hall's tool"))
	provenance.text = source_name if source_name.begins_with("SUPPLIED EXAMPLE") else "LIVE DRAWING  /  " + source_name
	if phase == 3 and closed: provenance.text = "DISPLAY SEPARATION ONLY  /  original drawing stays in place"
	if phase == 4 and closed: provenance.text = "The tool draws both sides. A visible face has no thickness or collision."

func finish(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.55
	return mat

func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.height = 1.0
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.radial_segments = 8
	node.mesh = mesh
	node.material_override = finish(colour)
	parent.add_child(node)
	var distance := a.distance_to(b)
	if distance > 0.000001:
		node.transform = Transform3D(Basis(Quaternion(Vector3.UP, (b - a) / distance)) * Basis.from_scale(Vector3(1, distance, 1)), (a + b) * 0.5)
	else: node.scale = Vector3.ZERO
	return node

func label(parent: Node, at: Vector2, size: int, colour: Color) -> Label:
	var node := Label.new()
	node.position = at
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", colour)
	parent.add_child(node)
	return node
