extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var vector_a: Node3D
var vector_b: Node3D
var projection_vector: Node3D
var rejection_vector: Node3D
var info_label: Label3D
var angle_label: Label3D

func _ready():
	super._ready()
	create_axes(3.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.4, 1.0, 0.2), Color(1.0, 0.5, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.4, 1.6, 0.7), Color(0.2, 0.7, 1.0, 1.0), "Vector b")
	projection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.8, 1.0, 0.4, 1.0), "proj_b(a)", false)
	rejection_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.7, 0.9, 0.8), "rej_b(a)", false)
	info_label = create_info_panel("Dot Product", Vector3(-2.7, 2.2, 0.0))
	angle_label = create_info_panel("θ", Vector3(0.0, 1.6, 0.0))

func _process(_delta):
	var a = get_vector(vector_a)
	var b = get_vector(vector_b)
	var dot = a.dot(b)
	var mag_a = a.length()
	var mag_b = b.length()
	var cos_theta = 0.0
	if mag_a > 0.0001 and mag_b > 0.0001:
		cos_theta = clamp(dot / (mag_a * mag_b), -1.0, 1.0)
	var theta = acos(cos_theta)
	var proj = Vector3.ZERO
	if mag_b > 0.0001:
		proj = b.normalized() * (dot / mag_b)
	var rej = a - proj
	update_vector(projection_vector, proj)
	rejection_vector.position = proj
	update_vector(rejection_vector, rej)
	angle_label.position = (a + b) * 0.25
	angle_label.text = "θ ≈ %.1f°" % rad_to_deg(theta)
	_update_info(a, b, dot, proj, rej, theta, cos_theta)

func _update_info(a: Vector3, b: Vector3, dot: float, proj: Vector3, rej: Vector3, theta: float, cos_theta: float):
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a · b = %.2f" % dot)
	builder.append("|a||b|cosθ = %.2f" % (a.length() * b.length() * cos_theta))
	builder.append("proj_b(a) = (%.2f, %.2f, %.2f)" % [proj.x, proj.y, proj.z])
	builder.append("rej_b(a) = (%.2f, %.2f, %.2f)" % [rej.x, rej.y, rej.z])
	info_label.text = "\n".join(builder)



