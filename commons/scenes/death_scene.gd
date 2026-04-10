# death_scene.gd — "You Died" scene with cross on hill and biome
#
# Shows after health reaches 0. Atmospheric hilltop with a cross,
# full biome surroundings, "You Died" text, and a Continue button
# that returns to the lab/menu.

extends Node3D

var _continue_pressed := false

func _ready() -> void:
	_build_environment()
	_build_hill()
	_build_cross()
	_build_biome()
	_build_ui()
	_build_camera()
	_build_light()


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	env.name = "DeathEnv"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.15, 0.1, 0.2)
	environment.ambient_light_color = Color(0.3, 0.25, 0.35)
	environment.ambient_light_energy = 0.4
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.2, 0.15, 0.25)
	environment.fog_density = 0.03
	env.environment = environment
	add_child(env)


func _build_hill() -> void:
	# Flat green hill
	var hill := MeshInstance3D.new()
	hill.name = "Hill"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	plane.subdivide_depth = 16
	plane.subdivide_width = 16
	hill.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.3, 0.1)
	mat.roughness = 0.9
	hill.material_override = mat
	add_child(hill)


func _build_cross() -> void:
	# Vertical beam
	var vertical := MeshInstance3D.new()
	vertical.name = "CrossVertical"
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(0.15, 2.5, 0.15)
	vertical.mesh = v_mesh
	vertical.position = Vector3(0, 1.25, -5)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)
	mat.roughness = 0.8
	vertical.material_override = mat
	add_child(vertical)

	# Horizontal beam
	var horizontal := MeshInstance3D.new()
	horizontal.name = "CrossHorizontal"
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(1.2, 0.12, 0.12)
	horizontal.mesh = h_mesh
	horizontal.position = Vector3(0, 1.8, -5)
	horizontal.material_override = mat
	add_child(horizontal)


func _build_biome() -> void:
	# Scatter some simple trees and grass around the hill
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in 20:
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(6.0, 18.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist - 5)

		# Trees
		var tree := MeshInstance3D.new()
		tree.name = "Tree%d" % i
		var trunk := CylinderMesh.new()
		trunk.height = rng.randf_range(1.5, 3.5)
		trunk.top_radius = 0.05
		trunk.bottom_radius = 0.12
		trunk.radial_segments = 5
		tree.mesh = trunk
		tree.position = pos + Vector3(0, trunk.height * 0.5, 0)

		var t_mat := StandardMaterial3D.new()
		t_mat.albedo_color = Color(0.2 + rng.randf() * 0.1, 0.35 + rng.randf() * 0.15, 0.1)
		tree.material_override = t_mat
		add_child(tree)

		# Canopy
		var canopy := MeshInstance3D.new()
		canopy.name = "Canopy%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.4, 1.0)
		sphere.height = sphere.radius * 1.5
		canopy.mesh = sphere
		canopy.position = pos + Vector3(0, trunk.height + sphere.radius * 0.3, 0)

		var c_mat := StandardMaterial3D.new()
		c_mat.albedo_color = Color(0.1 + rng.randf() * 0.15, 0.3 + rng.randf() * 0.2, 0.05)
		canopy.material_override = c_mat
		add_child(canopy)

	# Grass patches
	for i in 40:
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(2.0, 15.0)
		var pos := Vector3(cos(angle) * dist, 0.01, sin(angle) * dist - 5)

		var grass := MeshInstance3D.new()
		grass.name = "Grass%d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(0.15, rng.randf_range(0.2, 0.4))
		grass.mesh = quad
		grass.position = pos + Vector3(0, quad.size.y * 0.5, 0)

		var g_mat := StandardMaterial3D.new()
		g_mat.albedo_color = Color(0.2, 0.5 + rng.randf() * 0.2, 0.1, 0.8)
		g_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		g_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		grass.material_override = g_mat
		add_child(grass)


func _build_ui() -> void:
	# "YOU DIED" text floating above the cross
	var title := Label3D.new()
	title.name = "YouDied"
	title.text = "YOU DIED"
	title.font_size = 96
	title.pixel_size = 0.005
	title.position = Vector3(0, 3.5, -5)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(0.8, 0.15, 0.1)
	title.outline_size = 8
	add_child(title)

	# "Continue" button (3D label — trigger click or gaze to activate)
	var btn := Label3D.new()
	btn.name = "ContinueButton"
	btn.text = "[ Continue ]"
	btn.font_size = 48
	btn.pixel_size = 0.004
	btn.position = Vector3(0, 1.5, -3)
	btn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	btn.modulate = Color(0.7, 0.7, 0.8)
	btn.outline_size = 4
	add_child(btn)

	# Make the continue button clickable via Area3D
	var area := Area3D.new()
	area.name = "ContinueArea"
	area.position = Vector3(0, 1.5, -3)
	area.collision_layer = 0
	area.collision_mask = 0xFFFFF
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 0.5, 0.3)
	col.shape = box
	area.add_child(col)
	add_child(area)

	# Auto-continue after 5 seconds (fallback if VR pointer doesn't work)
	get_tree().create_timer(5.0).timeout.connect(_on_continue)


func _build_camera() -> void:
	# Desktop camera looking at the cross
	var cam := Camera3D.new()
	cam.name = "DeathCamera"
	cam.position = Vector3(2, 2, -1)
	cam.look_at(Vector3(0, 1.5, -5), Vector3.UP)
	cam.current = true
	cam.fov = 60
	add_child(cam)


func _build_light() -> void:
	var light := DirectionalLight3D.new()
	light.name = "MoonLight"
	light.light_color = Color(0.5, 0.45, 0.6)
	light.light_energy = 0.6
	light.rotation_degrees = Vector3(-40, -30, 0)
	light.shadow_enabled = true
	add_child(light)


func _on_continue() -> void:
	if _continue_pressed:
		return
	_continue_pressed = true
	# Return to lab/main menu
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if scene_mgr and scene_mgr.has_method("go_to_lab"):
		scene_mgr.go_to_lab()
	else:
		get_tree().change_scene_to_file("res://commons/scenes/lab.tscn")
