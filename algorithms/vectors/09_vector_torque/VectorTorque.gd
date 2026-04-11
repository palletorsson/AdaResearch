extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var radius_vector: Node3D
var force_vector: Node3D
var torque_vector: Node3D
var moment_arm_vector: Node3D
var info_label: Label3D

func _ready() -> void:
	super._ready()
	# Match the compact exhibition presentation used by other advanced vector scenes.
	scale = Vector3(0.5, 0.5, 0.5)
	create_axes(1.5)
	radius_vector = spawn_vector(Vector3.ZERO, Vector3(1.4, 0.8, 0.0), Color(1.0, 0.6, 0.2, 1.0), "r")
	force_vector = spawn_vector(Vector3.ZERO, Vector3(0.0, 1.4, 1.0), Color(0.2, 0.8, 1.0, 1.0), "F")
	torque_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.9, 0.6, 1.0, 1.0), "tau", false)
	moment_arm_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.7, 1.0, 0.4, 1.0), "r_perp", false)
	var force_start = force_vector.get_node_or_null("lineContainer/GrabSphere")
	if force_start:
		_disable_grab_sphere(force_start)
	info_label = create_info_panel(
		"Torque",
		Vector3(0.0, 2.5, -0.8),
		Vector2(2.4, 1.0),
		"tau = r x F\n|tau| = |r||F|sin(theta)",
		"Rotational force from cross product"
	)

func _process(_delta):
	var r = get_vector(radius_vector)
	var f = get_vector(force_vector)
	var r_end = to_local(get_arrow_end_position(radius_vector))
	force_vector.position = r_end
	var torque = r.cross(f)
	update_vector(torque_vector, torque)
	_update_moment_arm(r, f)
	_update_info(r, f, torque)

func _update_moment_arm(r: Vector3, f: Vector3) -> void:
	if f.length() < 0.001:
		update_vector(moment_arm_vector, Vector3.ZERO)
		return
	var f_dir = f.normalized()
	var perpendicular = r - f_dir * r.dot(f_dir)
	moment_arm_vector.position = Vector3.ZERO
	update_vector(moment_arm_vector, perpendicular)

func _update_info(r: Vector3, f: Vector3, torque: Vector3) -> void:
	var builder := []
	builder.append("r = (%.2f, %.2f, %.2f)" % [r.x, r.y, r.z])
	builder.append("F = (%.2f, %.2f, %.2f)" % [f.x, f.y, f.z])
	builder.append("tau = r x F = (%.2f, %.2f, %.2f)" % [torque.x, torque.y, torque.z])
	builder.append("|tau| = %.2f" % torque.length())
	if r.length() > 0.001 and f.length() > 0.001:
		var sin_theta = torque.length() / (r.length() * f.length())
		builder.append("sin(theta) ~= %.2f" % clamp(sin_theta, -1.0, 1.0))
	info_label.text = "\n".join(builder)




func apply_grid_config(config: Dictionary) -> void:
	pass
