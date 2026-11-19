extends "res://algorithms/color/colorballs/colorballs.gd"
## Keep the museum case's reset relative to its editable position in the tower.
## The source uses world Y and respawns at world zero; its geometry, palette,
## physics and MultiMesh renderer are otherwise inherited unchanged.
## Also supports `case: "shaft_playground"`, which enlarges the balls and bounds
## them inside an open walkable 6 x 6 m playground_spec_hall basin over a shaft.

var _shaft_playground := false
var _pool_half := 3.15
var _forced_palette := ""

func _ready() -> void:
	_forced_palette = str(get_meta("config_palette", "")).strip_edges()
	if str(get_meta("config_case", "")) == "shaft_playground":
		_configure_shaft_playground()
	super._ready()

func get_random_color() -> Color:
	if not _forced_palette.is_empty():
		var colors := _get_palette_colors(_forced_palette)
		if not colors.is_empty():
			return colors[randi() % colors.size()] * color_intensity
	return super.get_random_color()

func _configure_shaft_playground() -> void:
	_shaft_playground = true
	ball_count = clampi(int(get_meta("config_ball_count", 56)), 12, 96)
	_ball_radius = clampf(float(get_meta("config_ball_radius", 0.24)), 0.12, 0.42)
	ball_mass = 0.06
	ball_bounce = 0.72
	ball_friction = 0.22
	linear_damp = 0.22
	angular_damp = 0.22
	spawn_area_size = Vector3(4.4, 1.0, 4.0)
	spawn_height = 1.45
	initial_velocity_range = 0.75
	fall_threshold = -0.5
	emission_strength = 0.0
	roughness_factor = 0.22
	metallic_factor = 0.06
	set_process_input(false)
	for child in get_children():
		if child is Camera3D:
			remove_child(child)
			child.queue_free()

func check_and_respawn_fallen_balls() -> void:
	for i in range(ball_bodies.size()):
		var body: RigidBody3D = ball_bodies[i]
		if not is_instance_valid(body):
			continue
		var local := to_local(body.global_position)
		var out_of_bounds := local.y < fall_threshold
		if _shaft_playground and not out_of_bounds:
			out_of_bounds = absf(local.x) > _pool_half or absf(local.z) > _pool_half or local.y > 4.6
		if not out_of_bounds:
			continue
		var drop_z := randf_range(-spawn_area_size.z * 0.5, spawn_area_size.z * 0.35) if _shaft_playground else randf_range(-spawn_area_size.z / 2, spawn_area_size.z / 2)
		body.global_position = to_global(Vector3(
			randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
			spawn_height,
			drop_z))
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		PhysicsServer3D.body_set_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, body.global_transform)
		body.reset_physics_interpolation()
		var colour: Color = get_random_color()
		if i < ball_colors.size():
			ball_colors[i] = colour
		if use_multimesh_renderer and multimesh and i < multimesh.instance_count:
			multimesh.set_instance_color(i, colour)
		else:
			set_ball_color(balls[i], colour)
