extends Node3D
## Shared camera stage. Subclasses film independent copies of existing source data.
var display: Node3D
var camera: Camera3D
var playhead := 0.0
var running := true
var duration := 24.0
var title_text := "A PROCESS REVEALED"
var phases: Array[String] = []
var notes: Array[String] = []
var source_paths: Array[String] = []
var evidence: Dictionary = {}
var _title: Label
var _note: Label
var _footer: Label
var _focus := Vector3(0,1.3,0)
var _distance := 11.0
var _azimuth := 0.2
var _elevation := 0.28
var _view_offset := 0.0

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("121822")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d6dfed")
	env.ambient_light_energy = .42
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-30,0)
	light.light_energy = .9
	light.shadow_enabled = true
	add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18,145,0)
	fill.light_color = Color("b8cce8")
	fill.light_energy = .35
	add_child(fill)
	camera = Camera3D.new()
	camera.fov = 42
	camera.environment = env.duplicate(true)
	camera.current = true
	add_child(camera)
	orbit(0)
	display = Node3D.new()
	display.name = "FilmedGeometry"
	add_child(display)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	for rect in [Rect2(0,0,1024,98),Rect2(0,534,1024,42)]:
		var panel := ColorRect.new()
		panel.position = rect.position
		panel.size = rect.size
		panel.color = Color("121822")
		canvas.add_child(panel)
	_title = _text(canvas,Vector2(26,12),27,Color("f1dfd0"))
	_note = _text(canvas,Vector2(26,51),17,Color("d0d9e4"))
	_note.size = Vector2(974,44)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer = _text(canvas,Vector2(26,544),16,Color("b2becb"))
	_build()
	refresh()

func _build() -> void:
	pass

func _draw(_time: float) -> void:
	pass

func refresh() -> void:
	if display == null: return
	_draw(playhead)
	var i := phase_index(playhead)
	_title.text = title_text
	_note.text = notes[mini(i,notes.size()-1)] if not notes.is_empty() else ""
	_footer.text = "%02d / %s     %.1f s / %.0f s" % [i+1,phases[i] if not phases.is_empty() else "PROCESS",playhead,duration]

func advance(delta: float) -> void:
	if not running: return
	playhead = fposmod(playhead+delta,maxf(duration,.1))
	refresh()

func toggle_pause() -> void:
	running = not running

func replay() -> void:
	playhead = 0.0
	running = true
	refresh()

func step_sample() -> void:
	running = false
	var count := maxi(1,phases.size())
	playhead = fposmod((floorf(playhead/duration*count)+1.0)*duration/count+.001,duration)
	refresh()

func next_route() -> void:
	orbit(.28)

func phase_index(time: float) -> int:
	return clampi(int(time/maxf(duration,.1)*maxi(1,phases.size())),0,maxi(0,phases.size()-1))

func phase_progress(time: float) -> float:
	return fposmod(time/maxf(duration,.1)*maxi(1,phases.size()),1.0)

func orbit(angle: float) -> void:
	_view_offset += angle
	if camera == null: return
	var angle_now := _azimuth + _view_offset
	camera.position = _focus+Vector3(sin(angle_now)*cos(_elevation),sin(_elevation),cos(angle_now)*cos(_elevation))*_distance
	camera.look_at(_focus)

func frame_scene(center: Vector3, distance: float, azimuth := .2, elevation := .28) -> void:
	_focus = center
	_distance = distance
	_azimuth = azimuth
	_elevation = elevation
	orbit(0)

func frame_from_position(center: Vector3, at: Vector3) -> void:
	var offset := at-center
	var distance := offset.length()
	frame_scene(center,distance,atan2(offset.x,offset.z),asin(clampf(offset.y/maxf(distance,.0001),-1,1)))

func material(colour: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = .62
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if colour.a < 1.0: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func add_mesh(mesh: Mesh, colour: Color, at := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(colour)
	node.position = at
	(parent if parent != null else display).add_child(node)
	return node

func add_box(at: Vector3, size: Vector3, colour: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add_mesh(mesh,colour,at,parent)

func add_ball(at: Vector3, radius: float, colour: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 12
	mesh.rings = 6
	return add_mesh(mesh,colour,at,parent)

func add_rod(a: Vector3, b: Vector3, radius: float, colour: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(a.distance_to(b),.00001)
	mesh.radial_segments = 6
	mesh.rings = 0
	var node := add_mesh(mesh,colour,(a+b)*.5,parent)
	var dir := (b-a).normalized()
	if dir.length_squared() > .001:
		node.basis = Basis(Quaternion(Vector3.UP,dir))
	return node

func add_lines(points: PackedVector3Array, colour: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	if points.size() >= 2:
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for point in points: mesh.surface_add_vertex(point)
		mesh.surface_end()
	var node := add_mesh(mesh,colour,Vector3.ZERO,parent)
	node.material_override = material(colour,true)
	return node

func add_label(text: String, at: Vector3, colour := Color.WHITE, parent: Node3D = null) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 30
	label.pixel_size = .006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = colour
	label.outline_size = 5
	(parent if parent != null else display).add_child(label)
	return label

func clear_display() -> void:
	for node in display.get_children():
		display.remove_child(node)
		node.queue_free()

func _text(parent: Node, at: Vector2, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",colour)
	parent.add_child(label)
	return label
