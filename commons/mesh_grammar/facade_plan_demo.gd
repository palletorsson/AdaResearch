## FacadePlanDemo — Demo scene for the CSG-based facade plan importer.
## Loads a test facade_plan.json and displays the resulting 3D facade.
## Run this scene directly to test the CSG facade pipeline.
extends Node3D


func _ready() -> void:
	_create_environment()
	_create_floor()
	_create_facade()


# ─── Environment ───────────────────────────────────────────────────────────
func _create_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.65, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.85)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Sun
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 25, 0)
	light.light_color = Color(1.0, 0.95, 0.88)
	light.light_energy = 1.4
	light.shadow_enabled = true
	add_child(light)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -130, 0)
	fill.light_color = Color(0.6, 0.65, 0.8)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	add_child(fill)

	# Camera — positioned to view the facade
	var cam := Camera3D.new()
	cam.position = Vector3(7.5, 6, 18)
	cam.rotation_degrees = Vector3(-8, 0, 0)
	cam.fov = 50
	add_child(cam)


# ─── Floor ─────────────────────────────────────────────────────────────────
func _create_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 30)
	floor_mesh.mesh = plane

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.32, 0.28)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)


# ─── Facade ────────────────────────────────────────────────────────────────
func _create_facade() -> void:
	# Method 1: Using FacadePlanNode (the @tool node)
	var facade_node := FacadePlanNode.new()
	facade_node.name = "TestFacade"
	facade_node.plan_path = "res://commons/mesh_grammar/test_facade_plan.json"
	add_child(facade_node)

	# Section label
	var label := Label3D.new()
	label.text = "FACADE PLAN IMPORTER — CSG Pipeline"
	label.font_size = 48
	label.pixel_size = 0.003
	label.position = Vector3(7.5, 11.5, 0)
	label.modulate = Color(0.3, 0.25, 0.2)
	add_child(label)

	# Info label
	var info := Label3D.new()
	info.text = "Imported from test_facade_plan.json"
	info.font_size = 32
	info.pixel_size = 0.002
	info.position = Vector3(7.5, -0.5, 0.5)
	info.modulate = Color(0.25, 0.2, 0.15)
	add_child(info)
