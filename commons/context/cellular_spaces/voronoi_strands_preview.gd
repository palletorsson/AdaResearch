extends Node3D

const Web = preload("res://commons/context/cellular_spaces/voronoi_strands.tscn")
const Walker = preload("res://commons/context/cellular_spaces/preview_walker.gd")
var web: Node3D
var walker: CharacterBody3D
var caption: Label
var _caption_time: float = 0.0

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("e9e6e2")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.4
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	add_child(light)
	var room_light := OmniLight3D.new()
	room_light.position = Vector3(-3, 8.5, 5)
	room_light.light_energy = 0.65
	room_light.omni_range = 28
	room_light.shadow_enabled = true
	add_child(room_light)
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(30, 0.2, 30)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("cecbc7")
	material.roughness = 0.95
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position.y = -0.1
	floor_body.add_child(visual)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	collider.position.y = -0.1
	floor_body.add_child(collider)
	# Visible room walls and collision use the same boxes. The entrance
	# behind the initial visitor position remains three metres wide.
	_room_box("WestWall", Vector3(-10.15, 4.75, 2.5), Vector3(0.3, 9.5, 23.6))
	_room_box("EastWall", Vector3(10.15, 4.75, 2.5), Vector3(0.3, 9.5, 23.6))
	_room_box("BackWall", Vector3(0, 4.75, -9.15), Vector3(20, 9.5, 0.3))
	_room_box("FrontLeft", Vector3(-5.75, 4.75, 14.15), Vector3(8.5, 9.5, 0.3))
	_room_box("FrontRight", Vector3(5.75, 4.75, 14.15), Vector3(8.5, 9.5, 0.3))
	_room_box("EntranceLintel", Vector3(0, 6.25, 14.15), Vector3(3, 6.5, 0.3))
	_room_box("Ceiling", Vector3(0, 9.65, 2.5), Vector3(20.6, 0.3, 23.6))
	web = Web.instantiate()
	add_child(web)
	walker = CharacterBody3D.new()
	walker.set_script(Walker)
	walker.position = Vector3(0, 0.03, 10)
	add_child(walker)
	walker.home = walker.position
	walker.eyes.rotation_degrees.x = 14
	var hud := CanvasLayer.new()
	add_child(hud)
	caption = Label.new()
	caption.position = Vector2(24, 20)
	caption.add_theme_color_override("font_color", Color("25232c"))
	caption.add_theme_font_size_override("font_size", 20)
	hud.add_child(caption)
	_caption()

func _room_box(label: String, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	add_child(body)
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("e1ddd7")
	if label == "WestWall":
		material.albedo_color = Color("d0d7db")
	elif label == "BackWall":
		material.albedo_color = Color("e8e0d7")
	material.roughness = 0.95
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _caption() -> void:
	if not is_instance_valid(web.weaver):
		return
	var state := "Complete" if web.weaver.finished else ("Paused" if web.weaver.paused else "Weaving")
	if web.weaver.finished and web.weaver.laid_count < web.weaver.segments.size():
		state = "Resting at end of connected strands"
	var forces := "Tension begins when weaving finishes"
	if web.tension_active:
		var metrics: Dictionary = web.dynamics.metrics()
		forces = "Gravity + tension · estimated peak %.1f N · stretch %.1f mm" % [metrics.peak_tension, metrics.max_extension * 1000.0]
		if web.tension_paused:
			forces = "Forces paused"
	caption.text = "VORONOI / SPIDER\n%d cells · %d / %d strands · %s\nShared knots · fixed floor, wall and ceiling anchors\n%s\n\nWASD  Walk    Hold right mouse  Look\nF  Finish & release    G  Tug a knot (finishes weaving)\nB  Replay    P  Pause    T  Weaving speed\nR  New seed    Space  Highlight junctions" % [web.site_count, web.weaver.laid_count, web.weaver.segments.size(), state, forces]

func _process(delta: float) -> void:
	_caption_time += delta
	if _caption_time >= 0.1:
		_caption_time = 0.0
		_caption()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			web.seed_value += 1
			web.regenerate()
			_caption()
		elif event.physical_keycode == KEY_SPACE:
			var knots: MultiMeshInstance3D = web.generated.get_node("Knots")
			var material: StandardMaterial3D = knots.material_override
			material.albedo_color = Color("eb772c") if material.albedo_color == web.line_color else web.line_color
			knots.multimesh.mesh.radius = web.strand_radius * (3.0 if material.albedo_color != web.line_color else 1.6)
			knots.multimesh.mesh.height = knots.multimesh.mesh.radius * 2.0
		elif event.physical_keycode == KEY_B:
			web.weaver.restart()
		elif event.physical_keycode == KEY_P:
			web.weaver.paused = not web.weaver.paused
			web.tension_paused = web.weaver.paused
		elif event.physical_keycode == KEY_F:
			web.weaver.finish()
		elif event.physical_keycode == KEY_T:
			web.weaver.speed = 12.0 if web.weaver.speed < 10 else web.weave_speed
		elif event.physical_keycode == KEY_G:
			if not web.weaver.finished:
				web.weaver.finish()
			web.tug_from_camera(walker.eyes)
