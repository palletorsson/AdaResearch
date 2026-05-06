# leg_demo.gd
# Demo scene: ALL critters 1-6 legs side by side.
# Plus scaled beast_demo reference in the back.
# Run with F5 or F6 to see all IK creatures with stepping gait.
extends Node3D

func _ready() -> void:
	_build_floor()
	_build_lighting()
	_build_camera()
	_spawn_creatures()
	print("[LegDemo] Ready — 1, 2, 3, 4, 5, 6 leg critters + beast_demo reference")
	print("[LegDemo] WASD moves all walking critters. All auto-patrol too.")

func _spawn_creatures() -> void:
	# Layout: spread across X axis, 6 spacing
	#   X=-15: one-leg (stationary)
	#   X=-9:  two-leg (stepping)
	#   X=-3:  three-leg (stepping)
	#   X=+3:  four-leg (stepping)
	#   X=+9:  five-leg (stepping)
	#   X=+15: six-leg (stepping)
	#   Z=-8:  beast_demo reference

	# One-leg test — stands in place
	var one_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/one_leg.tscn")
	if one_leg_scene:
		var one_leg: Node = one_leg_scene.instantiate()
		one_leg.position = Vector3(-15, 0, 0)
		add_child(one_leg)
		print("[LegDemo] Spawned one-leg at X=-15")

	# Two-leg critter — stepping gait
	var two_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/two_leg_critter.tscn")
	if two_leg_scene:
		var two_leg: Node = two_leg_scene.instantiate()
		two_leg.position = Vector3(-9, 0, 0)
		add_child(two_leg)
		print("[LegDemo] Spawned two-leg at X=-9")

	# Three-leg critter — stepping gait
	var three_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/three_leg_critter.tscn")
	if three_leg_scene:
		var three_leg: Node = three_leg_scene.instantiate()
		three_leg.position = Vector3(-3, 0, 0)
		add_child(three_leg)
		print("[LegDemo] Spawned three-leg at X=-3")

	# Four-leg critter — stepping gait
	var four_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/four_leg_critter.tscn")
	if four_leg_scene:
		var four_leg: Node = four_leg_scene.instantiate()
		four_leg.position = Vector3(3, 0, 0)
		add_child(four_leg)
		print("[LegDemo] Spawned four-leg at X=3")

	# Five-leg critter — stepping gait
	var five_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/five_leg_critter.tscn")
	if five_leg_scene:
		var five_leg: Node = five_leg_scene.instantiate()
		five_leg.position = Vector3(9, 0, 0)
		add_child(five_leg)
		print("[LegDemo] Spawned five-leg at X=9")

	# Six-leg critter — stepping gait
	var six_leg_scene: PackedScene = load("res://commons/hazards/octapod_crawler/six_leg_critter.tscn")
	if six_leg_scene:
		var six_leg: Node = six_leg_scene.instantiate()
		six_leg.position = Vector3(15, 0, 0)
		add_child(six_leg)
		print("[LegDemo] Spawned six-leg at X=15")

	# Beast_demo reference (scaled down)
	var beast_scene: PackedScene = load("res://commons/hazards/octapod_crawler/beast_demo.tscn")
	if beast_scene:
		var beast_world: Node = beast_scene.instantiate()
		var beast_node: Node = beast_world.find_child("beast", false)
		if beast_node:
			beast_node.get_parent().remove_child(beast_node)
			beast_node.scale = Vector3(0.3, 0.3, 0.3)
			beast_node.position = Vector3(0, 2.2 * 0.3, -8)
			add_child(beast_node)
			print("[LegDemo] Spawned beast_demo reference at Z=-8")
		beast_world.queue_free()

	# Info labels
	_add_label(Vector3(-15, 4.5, 0), "1 LEG\n(stationary)")
	_add_label(Vector3(-9, 4.5, 0), "2 LEGS\n(stepping)")
	_add_label(Vector3(-3, 4.5, 0), "3 LEGS\n(stepping)")
	_add_label(Vector3(3, 4.5, 0), "4 LEGS\n(stepping)")
	_add_label(Vector3(9, 4.5, 0), "5 LEGS\n(stepping)")
	_add_label(Vector3(15, 4.5, 0), "6 LEGS\n(stepping)")
	_add_label(Vector3(0, 2.5, -8), "BEAST DEMO\n(reference)")

func _build_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1

	var fm := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(60, 0.1, 40)
	fm.mesh = fb
	fm.position.y = -0.05
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.35, 0.35, 0.38)
	fmat.roughness = 0.85
	fm.material_override = fmat
	floor_body.add_child(fm)

	var fc := CollisionShape3D.new()
	var fs := BoxShape3D.new()
	fs.size = Vector3(60, 0.1, 40)
	fc.shape = fs
	fc.position.y = -0.05
	floor_body.add_child(fc)

	add_child(floor_body)

func _build_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.light_energy = 1.2
	sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-20, 150, 0)
	add_child(fill)

func _build_camera() -> void:
	if get_viewport().get_camera_3d() != null:
		return
	var cam := Camera3D.new()
	cam.name = "DemoCamera"
	cam.position = Vector3(0, 10, 25)
	cam.look_at(Vector3(0, 1, 0))
	cam.fov = 70.0
	cam.current = true
	add_child(cam)

func _add_label(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 20
	label.outline_size = 4
	label.modulate = Color(0.9, 0.95, 1.0)
	label.position = pos
	label.text = text
	add_child(label)
