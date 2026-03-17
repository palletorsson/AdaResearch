extends Node3D

## Demo scene for ProceduralColumns — shows all 6 column types side by side,
## plus all profile presets in a second row.
##
## Row 1: solomonic, double_helix, straight, profile (entasis), fluted_twist, cluster
## Row 2: All profile presets (entasis, baluster, vase, bamboo, bone, solomon_smooth)

const COLUMN_HEIGHT := 4.0
const COLUMN_WIDTH := 2.0
const SPACING := 3.0


func _ready() -> void:
	_setup_environment()
	_create_row_1()
	_create_row_2()


## Set up floor, camera, and lighting for the gallery.
func _setup_environment() -> void:
	# Floor plane
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(60, 20)
	var floor_inst := MeshInstance3D.new()
	floor_inst.name = "Floor"
	floor_inst.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.3, 0.32)
	floor_mat.roughness = 0.9
	floor_inst.set_surface_override_material(0, floor_mat)
	add_child(floor_inst)

	# Camera
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(8.0, 3.5, 12.0)
	camera.look_at(Vector3(8.0, 2.0, 0.0))
	camera.fov = 50.0
	add_child(camera)

	# Warm directional light (sun-like)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

	# Fill light from the other side
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-30.0, 150.0, 0.0)
	fill.light_color = Color(0.7, 0.75, 0.9)
	fill.light_energy = 0.4
	fill.shadow_enabled = false
	add_child(fill)

	# Environment (sky + ambient)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.17, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.38, 0.35)
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)


## Row 1: The 6 main column types.
func _create_row_1() -> void:
	var types := ["solomonic", "double_helix", "straight", "profile", "fluted_twist", "cluster"]
	var row_z := 0.0

	for i in range(types.size()):
		var col_type: String = types[i]
		var x := float(i) * SPACING
		var params := {}

		# Specific tweaks per type for visual appeal
		match col_type:
			"solomonic":
				params["twist_count"] = 6.0
				params["twist_radius"] = 0.08
				params["shaft_radius"] = 0.2
			"double_helix":
				params["twist_count"] = 4.0
				params["helix_radius"] = 0.16
				params["shaft_radius"] = 0.12
				params["band_count"] = 3
			"straight":
				params["radius"] = 0.2
			"profile":
				params["profile"] = "entasis"
				params["radius"] = 0.2
			"fluted_twist":
				params["twist_count"] = 6.0
				params["twist_radius"] = 0.06
				params["shaft_radius"] = 0.2
				params["flute_count"] = 20
				params["flute_depth"] = 0.15
			"cluster":
				params["shaft_count"] = 8
				params["central_radius"] = 0.15
				params["satellite_radius"] = 0.07
				params["orbit_radius"] = 0.22

		var column := ProceduralColumns.create_column(col_type, COLUMN_WIDTH, COLUMN_HEIGHT, params)
		column.position = Vector3(x, 0.0, row_z)
		add_child(column)

		# Label
		_add_label(col_type, Vector3(x + COLUMN_WIDTH * 0.5, -0.15, row_z + 0.5))


## Row 2: All profile column presets.
func _create_row_2() -> void:
	var profile_names := ProceduralColumns.get_profile_names()
	var row_z := -4.0

	for i in range(profile_names.size()):
		var profile_name: String = profile_names[i]
		var x := float(i) * SPACING
		var params := {
			"profile": profile_name,
			"radius": 0.2,
			"color": Color(0.75, 0.7, 0.62),
		}

		var column := ProceduralColumns.profile_column(COLUMN_WIDTH, COLUMN_HEIGHT, params)
		column.position = Vector3(x, 0.0, row_z)
		add_child(column)

		# Label
		_add_label(profile_name, Vector3(x + COLUMN_WIDTH * 0.5, -0.15, row_z + 0.5))


## Add a floating text label (Label3D) at the given position.
func _add_label(text: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.name = "Label_%s" % text
	label.text = text
	label.position = pos
	label.font_size = 48
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	label.outline_size = 8
	add_child(label)
