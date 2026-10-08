extends Node3D
## A private filmed illustration. It neither reads nor writes the visitor's TraceData.
## Sampled positions are kept in order; straight distance and polyline length differ.
const SAMPLE_COUNT := 33
const SAMPLE_SECONDS := 0.16
const HOLD_SECONDS := 2.8
const A := Vector3(-2, -0.16, 0)
const B := Vector3(2, -0.16, 0)
var running := true
var route := 0
var sample_index := 0
var elapsed := 0.0
var hold_elapsed := 0.0
var points: Array[Vector3] = []
var beads: Array[MeshInstance3D] = []
var links: Array[MeshInstance3D] = []
var head: MeshInstance3D
var status: Label
var measure: Label
var progress: ColorRect

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("11141c")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e7e2ee")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -25, 0)
	light.light_energy = 1.1
	add_child(light)
	var camera := Camera3D.new()
	camera.name = "IllustrationCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 6.4
	camera.position = Vector3(0, 0, 8)
	camera.environment = settings
	camera.current = true
	add_child(camera)
	# A filmed backdrop keeps the drawing ground explicit, including on Compatibility.
	var backdrop := MeshInstance3D.new()
	var panel := QuadMesh.new()
	panel.size = Vector2(7, 4)
	backdrop.mesh = panel
	backdrop.position.z = -0.3
	var paper := material(Color("11141c"))
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop.material_override = paper
	add_child(backdrop)
	var chalk := material(Color("eff0e8"))
	var pink := material(Color("ef8cb9"))
	var faint := material(Color("707987"))
	var baseline := rod(faint, 0.012)
	baseline.name = "StraightSegment"
	fit_rod(baseline, A, B)
	for point in [A, B]:
		var end := ball(chalk, 0.083)
		end.position = point
	for index in range(SAMPLE_COUNT):
		beads.append(ball(chalk, 0.026))
		if index > 0: links.append(rod(pink, 0.014))
	head = ball(pink, 0.078)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	caption(overlay, "01  /  LINE & TRACE", Vector2(46, 28), 22, Color("ecece8"))
	caption(overlay, "Same endpoints. Another journey.", Vector2(46, 65), 28, Color("f1c1d7"))
	caption(overlay, "A", Vector2(183, 337), 24, Color("ecece8"))
	caption(overlay, "B", Vector2(823, 337), 24, Color("ecece8"))
	status = caption(overlay, "", Vector2(46, 424), 22, Color("ecece8"))
	measure = caption(overlay, "", Vector2(46, 462), 20, Color("b5becb"))
	caption(overlay, "STRAIGHT SEGMENT", Vector2(700, 425), 16, Color("9ca5b3"))
	caption(overlay, "TRACE / KEPT POSITIONS", Vector2(700, 458), 16, Color("ef8cb9"))
	progress = ColorRect.new()
	progress.position = Vector2(46, 527)
	progress.size = Vector2(0, 3)
	progress.color = Color("ef8cb9")
	overlay.add_child(progress)
	set_route(0)

func advance(delta: float) -> void:
	if not running: return
	if sample_index == SAMPLE_COUNT - 1:
		hold_elapsed += delta
		if hold_elapsed >= HOLD_SECONDS: set_route((route + 1) % 3)
		return
	elapsed += delta
	while elapsed >= SAMPLE_SECONDS and sample_index < SAMPLE_COUNT - 1:
		elapsed -= SAMPLE_SECONDS
		show_sample(sample_index + 1)

func path_point(t: float, kind: int) -> Vector3:
	var height := sin(PI * t) * 0.90
	if kind == 1: height = sin(TAU * t) * 0.50
	if kind == 2: height = sin(PI * t) * (0.30 + 0.60 * sin(PI * t))
	return A.lerp(B, t) + Vector3(0, height, 0)

func set_route(kind: int) -> void:
	route = posmod(kind, 3)
	points.clear()
	for index in range(SAMPLE_COUNT):
		points.append(path_point(float(index) / float(SAMPLE_COUNT - 1), route))
	for index in range(SAMPLE_COUNT):
		beads[index].position = points[index]
		if index > 0: fit_rod(links[index - 1], points[index - 1], points[index])
	replay()

func replay() -> void:
	elapsed = 0.0
	hold_elapsed = 0.0
	show_sample(0)

func toggle_pause() -> void:
	running = not running
	refresh_text()

func step_sample() -> void:
	running = false
	if sample_index == SAMPLE_COUNT - 1: replay()
	else: show_sample(sample_index + 1)

func next_route() -> void:
	set_route((route + 1) % 3)

func show_sample(index: int) -> void:
	sample_index = clampi(index, 0, SAMPLE_COUNT - 1)
	for i in range(SAMPLE_COUNT):
		beads[i].visible = i <= sample_index
		if i > 0: links[i - 1].visible = i <= sample_index
	head.position = points[sample_index]
	progress.size.x = 932.0 * float(sample_index) / float(SAMPLE_COUNT - 1)
	refresh_text()

func retained_length() -> float:
	var length := 0.0
	for i in range(1, sample_index + 1): length += points[i - 1].distance_to(points[i])
	return length

func refresh_text() -> void:
	var state := "PLAYING" if running else "PAUSED"
	if sample_index == SAMPLE_COUNT - 1 and running: state = "JOURNEY KEPT"
	status.text = "%s   /   %02d positions   /   route %d" % [state, sample_index + 1, route + 1]
	measure.text = "A to B  4.00 m     ·     trace so far  %.2f m" % retained_length()

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.34
	return result

func ball(finish: Material, radius: float) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 16
	mesh.rings = 8
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = finish
	add_child(body)
	return body

func rod(finish: Material, radius: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1
	mesh.radial_segments = 8
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = finish
	add_child(body)
	return body

func fit_rod(body: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var direction := end - start
	body.position = (start + end) * 0.5
	body.quaternion = Quaternion(Vector3.UP, direction.normalized())
	body.scale = Vector3(1, direction.length(), 1)

func caption(parent: Node, words: String, at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label
