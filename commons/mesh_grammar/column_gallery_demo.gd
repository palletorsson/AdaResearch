## ColumnGalleryDemo — Renders all ProceduralColumns types side by side.
## Each column gets proper SurfaceTool geometry (no triangle-soup artifacts).
extends Node3D

func _ready() -> void:
	_create_environment()
	_create_floor()
	_create_column_gallery()


func _create_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.13, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.58, 0.55)
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.3

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Warm key light from upper right
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_color = Color(1.0, 0.92, 0.82)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	add_child(sun)

	# Cool fill from left
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, -110, 0)
	fill.light_color = Color(0.5, 0.55, 0.7)
	fill.light_energy = 0.5
	fill.shadow_enabled = false
	add_child(fill)

	# Camera — pulled back to frame all 12 columns
	var cam := Camera3D.new()
	cam.position = Vector3(14, 4, 20)
	cam.rotation_degrees = Vector3(-5, 0, 0)
	cam.fov = 58
	cam.current = true
	add_child(cam)


func _create_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 20)
	floor_mesh.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.20, 0.18)
	mat.roughness = 0.95
	floor_mesh.material_override = mat
	add_child(floor_mesh)


func _create_column_gallery() -> void:
	var col_w := 2.0   # cell width
	var col_h := 6.0   # column height
	var spacing := 2.5
	
	var warm_stone := Color(0.82, 0.74, 0.62)
	var cool_stone := Color(0.72, 0.70, 0.66)
	var marble_white := Color(0.88, 0.86, 0.82)
	var dark_stone := Color(0.55, 0.50, 0.45)

	var columns: Array[Dictionary] = [
		{
			"name": "Straight",
			"type": "straight",
			"params": {"color": cool_stone, "segments": 32}
		},
		{
			"name": "Fluted Doric",
			"type": "fluted_straight",
			"params": {"flute_count": 20, "flute_depth": 0.25, "fillet": 0.0, "taper": 0.88, "color": marble_white}
		},
		{
			"name": "Fluted Ionic",
			"type": "fluted_straight",
			"params": {"flute_count": 24, "flute_depth": 0.2, "fillet": 0.3, "taper": 0.9, "color": warm_stone}
		},
		{
			"name": "Solomonic",
			"type": "solomonic",
			"params": {"twist_count": 5.0, "color": marble_white}
		},
		{
			"name": "Twisted Pair",
			"type": "twisted_pair",
			"params": {"twist_count": 3.0, "color": marble_white, "color2": Color(0.65, 0.60, 0.52)}
		},
		{
			"name": "Double Helix",
			"type": "double_helix",
			"params": {"twist_count": 3.5, "band_count": 4, "color": warm_stone}
		},
		{
			"name": "Spiral",
			"type": "spiral",
			"params": {"twist_count": 7.0, "color": marble_white}
		},
		{
			"name": "Tapered",
			"type": "tapered",
			"params": {"taper": 0.6, "sides": 32, "color": dark_stone}
		},
		{
			"name": "Cluster",
			"type": "cluster",
			"params": {"shaft_count": 6, "color": cool_stone}
		},
		{
			"name": "Baluster",
			"type": "profile",
			"params": {"profile": "baluster", "color": marble_white, "segments": 24}
		},
		{
			"name": "Entasis",
			"type": "profile",
			"params": {"profile": "entasis", "color": warm_stone, "segments": 32}
		},
		{
			"name": "Vase",
			"type": "profile",
			"params": {"profile": "vase", "color": warm_stone, "segments": 24}
		},
	]

	var x := 0.0
	for spec in columns:
		var col_node: Node3D = ProceduralColumns.create_column(
			spec["type"], col_w, col_h, spec["params"])
		col_node.position = Vector3(x, 0, 0)
		add_child(col_node)

		# Label
		var label := Label3D.new()
		label.text = spec["name"]
		label.font_size = 36
		label.pixel_size = 0.002
		label.position = Vector3(x + col_w / 2.0, -0.3, 0.5)
		label.modulate = Color(0.85, 0.8, 0.72)
		add_child(label)

		x += spacing
