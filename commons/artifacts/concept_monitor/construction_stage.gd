extends Node3D
## Film the construction of the existing resolution_totem, using its actual mesh data.
## This reveals a computational recipe, not the historical construction of a building.
const Source = preload("res://commons/artifacts/resolution_colonnade/resolution_totem.gd")
const SEGMENTS := 12
const RINGS := 6
const TITLES := ["A PROFILE", "REVOLVE", "CONNECT THE FACES", "NINE SECTIONS", "REPEAT THE ELEMENT", "MAKE A COLONNADE"]
const NOTES := ["A radius at each height. This is the outline we chose.", "Turn that outline around an axis. Twelve angular steps.", "Neighbouring positions become triangles. A skin takes shape.", "The column is a stack of nine generated sections.", "The same mesh occupies six different positions.", "Columns, plinths and beams become an arrangement."]
const DURATIONS := [3.5, 5.5, 6.0, 4.0, 5.5, 6.0]
const PLACES := [Vector3(0, 0.22, 0), Vector3(-3.4, 0.22, 0), Vector3(3.4, 0.22, 0), Vector3(0, 0.22, -4), Vector3(-3.4, 0.22, -4), Vector3(3.4, 0.22, -4)]
var running := true
var phase := 0
var elapsed := 0.0
var profile_kind := 0
var camera_angle := 0.40
var camera: Camera3D
var source: Node3D
var construction: Node3D
var profile: MultiMeshInstance3D
var circles: MultiMeshInstance3D
var axis: MeshInstance3D
var growing: MeshInstance3D
var parts: Array[MeshInstance3D] = []
var copies: Array[MeshInstance3D] = []
var plinths: Array[MeshInstance3D] = []
var beams: Array[MeshInstance3D] = []
var arrays: Array[Array] = []
var materials: Array[Material] = []
var total_triangles := 0
var shown_triangles := -1
var title: Label
var note: Label
var facts: Label
var progress_bar: ColorRect

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("202330")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d9d6e0")
	env.ambient_light_energy = 0.48
	world.environment = env
	add_child(world)
	camera = Camera3D.new()
	camera.name = "ConstructionCamera"
	camera.fov = 48
	camera.environment = env
	camera.current = true
	add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -35, 0)
	light.light_color = Color("ffe5c2")
	light.light_energy = 1.25
	light.shadow_enabled = true
	add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(1, 4, -3)
	fill.light_color = Color("c2cced")
	fill.light_energy = 3.0
	fill.omni_range = 10
	add_child(fill)
	_box(self, Vector3(70, 0.12, 70), Vector3(0, -0.08, 0), material(Color("242831")))
	# A floor grid makes depth and the repetition of positions readable.
	var seams: Array[Vector3] = []
	for i in range(-8, 9):
		seams.append_array([Vector3(float(i) * 2, 0.002, -16), Vector3(float(i) * 2, 0.002, 16)])
		seams.append_array([Vector3(-16, 0.002, float(i) * 2), Vector3(16, 0.002, float(i) * 2)])
	_rods(self, seams, 0.006, material(Color("454955"), true))
	var overlay := CanvasLayer.new()
	add_child(overlay)
	# Opaque header/footer protect the caption from the changing architectural image.
	for rect in [Rect2(0, 0, 1024, 105), Rect2(0, 505, 1024, 71)]:
		var panel := ColorRect.new()
		panel.position = rect.position
		panel.size = rect.size
		panel.color = Color("14171f")
		overlay.add_child(panel)
	title = caption(overlay, "", Vector2(34, 18), 29, Color("f1c6d5"))
	note = caption(overlay, "", Vector2(34, 61), 20, Color("eeece6"))
	facts = caption(overlay, "", Vector2(34, 521), 18, Color("d8dce3"))
	progress_bar = ColorRect.new()
	progress_bar.position = Vector2(34, 561)
	progress_bar.color = Color("d290ab")
	progress_bar.size = Vector2(1, 3)
	overlay.add_child(progress_bar)
	build_profile(0)

func build_profile(kind: int) -> void:
	profile_kind = posmod(kind, Source.PROFILE_NAMES.size())
	if construction != null:
		remove_child(construction)
		construction.queue_free()
	construction = Node3D.new()
	construction.name = "Construction"
	add_child(construction)
	arrays.clear()
	materials.clear()
	parts.clear()
	copies.clear()
	plinths.clear()
	beams.clear()
	total_triangles = 0
	shown_triangles = -1
	source = Source.new()
	source.name = "UnchangedGenerator"
	source.set("radial_segments", SEGMENTS)
	source.set("profile_rings", RINGS)
	source.set("profile_kind", profile_kind)
	source.set("collisions", false)
	source.visible = false
	construction.add_child(source)
	var mesh: ArrayMesh = source.get("column_mesh")
	var profile_pairs: Array[Vector3] = []
	var ring_profiles: Array[Vector3] = []
	for surface_index in range(mesh.get_surface_count()):
		var data: Array = mesh.surface_get_arrays(surface_index)
		arrays.append(data)
		materials.append(mesh.surface_get_material(surface_index))
		var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
		total_triangles += vertices.size() / 3
		# Read one radial outline from the generated surface. No profile equation copied.
		var unique: Dictionary = {}
		for point in vertices:
			if absf(point.z) < 0.0001 and point.x > 0.001:
				unique[Vector2(point.x, point.y).snapped(Vector2.ONE * 0.00001)] = point
		var outline: Array = unique.values()
		outline.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
		for i in range(outline.size()):
			ring_profiles.append(outline[i])
			if i > 0: profile_pairs.append_array([outline[i - 1], outline[i]])
		var section := ArrayMesh.new()
		section.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		section.surface_set_material(0, materials[-1])
		var piece := MeshInstance3D.new()
		piece.mesh = section
		construction.add_child(piece)
		parts.append(piece)
	var rose := material(Color("f3a5c8"), true)
	profile = _rods(construction, profile_pairs, 0.022, rose)
	profile.position = PLACES[0]
	# One angular sector at a time, retaining the generator's sampled rings.
	var ring_pairs: Array[Vector3] = []
	for sector in range(SEGMENTS):
		var a := TAU * float(sector) / SEGMENTS
		var b := TAU * float(sector + 1) / SEGMENTS
		for point in ring_profiles:
			ring_pairs.append_array([Vector3(cos(a) * point.x, point.y, sin(a) * point.x), Vector3(cos(b) * point.x, point.y, sin(b) * point.x)])
	circles = _rods(construction, ring_pairs, 0.009, material(Color("d8b6c6"), true))
	circles.position = PLACES[0]
	axis = _box(construction, Vector3(0.009, 5.1, 0.009), Vector3(0, 2.55, 0), material(Color("a2aaba"), true))
	growing = MeshInstance3D.new()
	growing.position = PLACES[0]
	construction.add_child(growing)
	for at in PLACES:
		var copy := MeshInstance3D.new()
		copy.mesh = mesh
		copy.position = at
		construction.add_child(copy)
		copies.append(copy)
		plinths.append(_box(construction, Vector3(1.86, 0.22, 1.86), Vector3(at.x, 0.11, at.z), material(Color("cdc6b6"))))
	for z in [0.0, -4.0]:
		beams.append(_box(construction, Vector3(8.8, 0.28, 0.32), Vector3(0, 5.03, z), material(Color("d8cbb6"))))
	replay()

func advance(delta: float) -> void:
	if not running: return
	elapsed += delta
	camera_angle += delta * 0.027
	if elapsed >= float(DURATIONS[phase]):
		elapsed = 0.0
		phase = (phase + 1) % TITLES.size()
	show_progress(phase, elapsed / float(DURATIONS[phase]))

func show_progress(operation: int, fraction: float) -> void:
	phase = clampi(operation, 0, TITLES.size() - 1)
	var t := clampf(fraction, 0.0, 1.0)
	elapsed = t * float(DURATIONS[phase])
	profile.visible = phase <= 1
	profile.multimesh.visible_instance_count = int(ceil(profile.multimesh.instance_count * clampf(t * 1.7, 0, 1))) if phase == 0 else -1
	circles.visible = phase in [1, 2]
	circles.multimesh.visible_instance_count = int(ceil(circles.multimesh.instance_count * clampf(t * 1.3, 0, 1))) if phase == 1 else -1
	axis.visible = phase <= 1
	growing.visible = phase == 2
	if phase == 2: reveal_faces(clampf(t * 1.22, 0, 1))
	for i in range(parts.size()):
		parts[i].visible = phase == 3
		parts[i].position = PLACES[0] + Vector3(0, float(i) * 0.105 * sin(PI * t), 0)
	for i in range(copies.size()):
		copies[i].visible = phase >= 4 and (phase > 4 or i <= int(t * 6.99))
		copies[i].position = PLACES[i]
		if phase == 4 and i > 0:
			var travel := smoothstep(0.0, 1.0, clampf(t * 6.0 - float(i) + 1.0, 0, 1))
			copies[i].position = PLACES[0].lerp(PLACES[i], travel)
		plinths[i].visible = phase == 5
	for beam in beams:
		beam.visible = phase == 5
		beam.scale.x = maxf(0.001, smoothstep(0.0, 0.75, t))
	_update_camera(t)
	title.text = "%02d  /  %s" % [phase + 1, TITLES[phase]]
	note.text = NOTES[phase]
	facts.text = "%s   ·   %d sides   ·   %d triangles   ·   %s" % [Source.PROFILE_NAMES[profile_kind], SEGMENTS, total_triangles, "PLAYING" if running else "PAUSED"]
	progress_bar.size.x = 956.0 * (float(phase) + t) / float(TITLES.size())

func reveal_faces(fraction: float) -> void:
	var count := int(total_triangles * fraction)
	if count == shown_triangles: return
	shown_triangles = count
	if count == 0:
		growing.mesh = null
		return
	var mesh := ArrayMesh.new()
	var remaining := count * 3
	for i in range(arrays.size()):
		if remaining <= 0: break
		var vertices: PackedVector3Array = arrays[i][Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[i][Mesh.ARRAY_NORMAL]
		var keep := mini(remaining, vertices.size())
		var data: Array = []
		data.resize(Mesh.ARRAY_MAX)
		data[Mesh.ARRAY_VERTEX] = vertices.slice(0, keep)
		data[Mesh.ARRAY_NORMAL] = normals.slice(0, keep)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		mesh.surface_set_material(mesh.get_surface_count() - 1, materials[i])
		remaining -= keep
	growing.mesh = mesh

func _update_camera(t: float) -> void:
	var widening := smoothstep(0.0, 0.8, t) if phase == 4 else (1.0 if phase == 5 else 0.0)
	var distance := lerpf(10.8, 15.3, widening)
	var target := Vector3(0, 2.6, lerpf(0, -1.8, widening))
	camera.position = target + Vector3(sin(camera_angle) * distance, 3.6 + widening * 1.8, cos(camera_angle) * distance)
	camera.look_at(target)

func orbit(angle: float) -> void:
	camera_angle += angle
	_update_camera(elapsed / float(DURATIONS[phase]))

func toggle_pause() -> void:
	running = not running
	show_progress(phase, elapsed / float(DURATIONS[phase]))

func replay() -> void:
	phase = 0
	elapsed = 0.0
	show_progress(0, 0.0)

func step_sample() -> void:
	running = false
	phase = (phase + 1) % TITLES.size()
	elapsed = float(DURATIONS[phase]) * 0.85
	show_progress(phase, 0.85)

func next_route() -> void:
	build_profile(profile_kind + 1)

func material(colour: Color, unshaded := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.74
	if unshaded: mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _rods(parent: Node, pairs: Array[Vector3], radius: float, finish: Material) -> MultiMeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 1
	cylinder.radial_segments = 6
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cylinder
	mm.instance_count = pairs.size() / 2
	for i in range(mm.instance_count):
		var direction := pairs[i * 2 + 1] - pairs[i * 2]
		var basis := Basis(Quaternion(Vector3.UP, direction.normalized())) * Basis.from_scale(Vector3(1, direction.length(), 1))
		mm.set_instance_transform(i, Transform3D(basis, (pairs[i * 2] + pairs[i * 2 + 1]) * 0.5))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = finish
	parent.add_child(node)
	return node

func _box(parent: Node, size: Vector3, at: Vector3, finish: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = finish
	node.position = at
	parent.add_child(node)
	return node

func caption(parent: Node, words: String, at: Vector2, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label
