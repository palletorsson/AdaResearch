extends Node3D
## A camera films native PrimitiveMesh topology. Parameters are discrete;
## only the display turn is continuous. No existing exhibit is modified.
const Meshes = preload("res://commons/artifacts/concept_monitor/resolution_meshes.gd")
const Inspection = preload("res://commons/primitives/shared/mesh_inspection.gd")
const SEGMENTS := [4, 5, 6, 8, 12, 16, 24, 32, 48, 64]
const RINGS := [0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32]
const PAIRS := [Vector2i(4,0), Vector2i(4,4), Vector2i(8,1), Vector2i(8,8), Vector2i(16,2), Vector2i(16,16), Vector2i(32,4), Vector2i(32,32), Vector2i(64,8), Vector2i(64,32)]
const STEP_TIME := 1.6
const PERIOD := 49.6
const COLOURS := [Color("ecd8c2"), Color("e9bad2"), Color("b7dce0")]
var running := true
var manual := false
var show_edges := true
var segments := 4
var rings := 4
var playhead := 0.0
var turn := 0.0
var camera_angle := 0.0
var camera: Camera3D
var bodies: Array[MeshInstance3D] = []
var edges: Array[MeshInstance3D] = []
var measures: Array[Dictionary] = []
var captions: Array[Label] = []
var title: Label
var note: Label
var state: Label
var _last := Vector2i(-1,-1)

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("10161e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dae0eb")
	env.ambient_light_energy = 0.38
	world.environment = env
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 42
	camera.current = true
	add_child(camera)
	orbit(0)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-28,0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18,150,0)
	fill.light_color = Color("b1c9e9")
	fill.light_energy = 0.3
	add_child(fill)
	box(Vector3(35,.08,30), Vector3(0,-.06,0), Color("202731"))
	var overlay := CanvasLayer.new()
	add_child(overlay)
	for rect in [Rect2(0,0,1024,100), Rect2(0,466,1024,110)]:
		var panel := ColorRect.new()
		panel.position = rect.position
		panel.size = rect.size
		panel.color = Color("10161e")
		overlay.add_child(panel)
	title = label(overlay, Vector2(30,14), 26, Color("eee5db"))
	note = label(overlay, Vector2(30,58), 18, Color("cad1dc"))
	state = label(overlay, Vector2(30,544), 15, Color("9eabbc"))
	for i in range(3):
		var x := (i - 1) * 3.15
		box(Vector3(2.65,.16,2.65), Vector3(x,.08,0), Color("3b4350"))
		var body := MeshInstance3D.new()
		body.position = Vector3(x,1.36,0)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = COLOURS[i]
		finish.roughness = .62
		body.material_override = finish
		add_child(body)
		bodies.append(body)
		captions.append(label(overlay, Vector2(30+i*334,479), 18, COLOURS[i]))
	refresh()

func advance(delta: float) -> void:
	if not running: return
	turn += delta * .17
	if not manual: playhead = fmod(playhead + delta, PERIOD)
	refresh()

func replay() -> void:
	manual = false
	running = true
	playhead = 0.0
	turn = 0.0
	refresh()

func toggle_pause() -> void:
	running = not running
	refresh()

func step_sample() -> void:
	manual = false
	running = false
	playhead = fmod((floorf(playhead / STEP_TIME) + 1.0) * STEP_TIME + .001, PERIOD)
	refresh()

func next_route() -> void:
	show_edges = not show_edges
	refresh()

func set_resolution(s: int, r: int) -> void:
	segments = clampi(s,4,64)
	rings = clampi(r,0,32)
	manual = true
	running = false
	refresh()

func orbit(angle: float) -> void:
	camera_angle = clampf(camera_angle + angle, -.32, .32)
	camera.position = Vector3(sin(camera_angle)*9.7,4.2,cos(camera_angle)*9.7)
	camera.look_at(Vector3(0,1.35,0))

func refresh() -> void:
	if camera == null: return
	var frame := mini(int(playhead / STEP_TIME),30)
	var chapter := "CHOOSE A COMBINATION"
	var detail := "S changes the divisions around. R changes the divisions along the body."
	if not manual:
		if frame < 10:
			segments = SEGMENTS[frame]
			rings = 4
			chapter = "01 / AROUND THE BODY"
			detail = "Change the segments. Keep rings at 4. Watch the silhouette."
		elif frame < 21:
			segments = 12
			rings = RINGS[frame-10]
			chapter = "02 / ALONG THE BODY"
			detail = "Change the rings. Keep 12 segments. The cylinder keeps its straight outline."
		else:
			segments = PAIRS[frame-21].x
			rings = PAIRS[frame-21].y
			chapter = "03 / TWO INDEPENDENT CHOICES"
			detail = "A dense row cannot repair a sparse circle. Change the two directions separately."
	if Vector2i(segments,rings) != _last:
		_last = Vector2i(segments,rings)
		for edge in edges:
			edge.get_parent().remove_child(edge)
			edge.queue_free()
		edges.clear()
		measures.clear()
		for i in range(3):
			var mesh: PrimitiveMesh = Meshes.make(i,segments,rings)
			bodies[i].mesh = mesh
			var data: Dictionary = Meshes.measure(mesh)
			measures.append(data)
			var edge := Inspection.overlay(mesh,data)
			bodies[i].add_child(edge)
			edges.append(edge)
	for i in range(3):
		bodies[i].rotation.y = turn
		edges[i].visible = show_edges
		var mesh: PrimitiveMesh = bodies[i].mesh
		var r: int = mesh.get("rings")
		var name_text: String = ["CYLINDER", "PILL / CAPSULE", "SPHERE"][i]
		captions[i].text = "%s  /  S %d  R %d\n%d surface triangles" % [name_text, segments, r, measures[i].surface_triangles]
		if i == 2 and rings == 0: captions[i].text += "  (R min. 1)"
	title.text = chapter
	note.text = detail
	state.text = "%s  |  %s  |  Explore every S 4-64 / R 0-32; sphere R starts at 1." % ["MANUAL" if manual else "FILM", "TRIANGLE EDGES" if show_edges else "SMOOTH SHADING"]

func label(parent: Node, at: Vector2, size: int, colour: Color) -> Label:
	var result := Label.new()
	result.position = at
	result.add_theme_font_size_override("font_size",size)
	result.add_theme_color_override("font_color",colour)
	parent.add_child(result)
	return result

func box(size: Vector3, at: Vector3, colour: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	finish.roughness = .85
	node.material_override = finish
	add_child(node)
