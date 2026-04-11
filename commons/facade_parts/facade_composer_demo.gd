## FacadeComposerDemo — Standalone demo scene for the part-based facade system.
## Loads the classical preset and renders it with environment lighting.
extends Node3D

const _FC := preload("res://commons/facade_parts/facade_composer.gd")


func _ready() -> void:
	_create_environment()
	_create_floor()
	_create_facade()


func _create_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.72, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.88)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Sun — warm afternoon light
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_color = Color(1.0, 0.94, 0.85)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	add_child(sun)

	# Fill from opposite side — cool blue bounce
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -120, 0)
	fill.light_color = Color(0.55, 0.6, 0.75)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	add_child(fill)

	# Camera
	var cam := Camera3D.new()
	cam.position = Vector3(7.5, 7, 18)
	cam.rotation_degrees = Vector3(-8, 0, 0)
	cam.fov = 55
	cam.current = true
	add_child(cam)


func _create_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 20)
	floor_mesh.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.38, 0.34)
	mat.roughness = 0.95
	floor_mesh.material_override = mat
	add_child(floor_mesh)


func _create_facade() -> void:
	var facade := _FC.build_from_file("res://commons/facade_parts/presets/classical.json")
	add_child(facade)

	# Label
	var label := Label3D.new()
	label.text = "Classical Facade (Part-Based)"
	label.font_size = 48
	label.pixel_size = 0.002
	label.position = Vector3(7.5, -0.4, 0.6)
	label.modulate = Color(0.9, 0.85, 0.78)
	add_child(label)
