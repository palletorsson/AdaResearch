extends "res://algorithms/machinelearning/gradientdescent/GradientDescentDemo.gd"
## Keep the museum optimiser; put its visual samples in the movable exhibit frame.
var local_samples: Array[Vector3] = []
var walker_tween: Tween

func local_point() -> Vector3:
	return Vector3(_current_position.x, _sample_height(_current_position.x, _current_position.y) + POINT_RADIUS, _current_position.y)

func _update_walker_transform() -> void:
	if walker_tween and walker_tween.is_valid(): walker_tween.kill()
	if _path_points.is_empty(): walker_mesh.position = local_point()
	walker_tween = create_tween()
	walker_tween.tween_property(walker_mesh, "position", local_point(), 0.12).set_ease(Tween.EASE_OUT)
	walker_tween.parallel().tween_property(walker_mesh, "scale", Vector3.ONE * 1.25, 0.06)
	walker_tween.tween_property(walker_mesh, "scale", Vector3.ONE, 0.06)

func _update_path_mesh() -> void:
	# The base appends a world-space walker sample after each numerical update.
	# Record the numerical endpoint locally instead, including the reset sample.
	if _path_points.size() == 1: local_samples.clear()
	if local_samples.size() < _path_points.size(): local_samples.append(local_point())
	var mesh := ImmediateMesh.new()
	path_mesh.mesh = mesh
	if local_samples.size() < 2: return
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	mesh.surface_set_color(COLOR_PATH)
	for point in local_samples: mesh.surface_add_vertex(point)
	mesh.surface_end()

func _update_gradient_mesh(gradient: Vector2) -> void:
	var mesh := ImmediateMesh.new()
	gradient_mesh.mesh = mesh
	if not show_gradient or gradient.length() <= 0.0001: return
	var start := local_point() + Vector3(0, 0.3, 0)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(COLOR_GRADIENT)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(start + Vector3(-gradient.x, 0, -gradient.y) * gradient_visual_scale)
	mesh.surface_end()

func _update_info_label(gradient: Vector2) -> void:
	super._update_info_label(gradient)
	# The base passes a zero gradient on every stop, even on budget exhaustion.
	if _state == RunState.COMPLETE and _step_index >= max_steps:
		info_label.text = info_label.text.replace("converged", "max steps")
