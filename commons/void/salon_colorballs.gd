extends "res://algorithms/color/colorballs/colorballs.gd"
## Keep the museum case's reset relative to its editable position in the tower.
## The source uses world Y and respawns at world zero; its geometry, palette,
## physics and MultiMesh renderer are otherwise inherited unchanged.

func check_and_respawn_fallen_balls() -> void:
	for i in range(ball_bodies.size()):
		var body: RigidBody3D = ball_bodies[i]
		if not is_instance_valid(body) or to_local(body.global_position).y >= fall_threshold:
			continue
		body.global_position = to_global(Vector3(
			randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
			spawn_height,
			randf_range(-spawn_area_size.z / 2, spawn_area_size.z / 2)))
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
