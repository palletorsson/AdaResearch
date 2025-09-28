extends VectorSceneBase

var vector_a: Node3D
var vector_b: Node3D
var difference_vector: Node3D
var negative_b: Node3D
var tip_tail_neg_b: Node3D
var info_label: Label3D

func _ready():
	super._ready()
	create_axes(3.5)
	create_floor(9.0)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.6, 0.7, -0.4), Color(0.9, 0.5, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(-0.3, 1.1, 0.8), Color(0.2, 0.6, 1.0, 1.0), "Vector b")
	difference_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 1.0, 1.0, 1.0), "a - b", false)
	negative_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.2, 0.6, 1.0, 0.6), "-b", false)
	tip_tail_neg_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.2, 0.6, 1.0, 0.4), "-b@a", false)
	info_label = create_info_panel("Vector Subtraction", Vector3(-2.5, 2.2, 0.0))

func _process(_delta):
	var a = get_vector(vector_a)
	var b = get_vector(vector_b)
	var minus_b = -b
	var diff = a - b
	update_vector(difference_vector, diff)
	update_vector(negative_b, minus_b)
	var a_tip = get_arrow_end_position(vector_a)
	tip_tail_neg_b.position = a_tip
	update_vector(tip_tail_neg_b, minus_b)
	_update_info(a, b, diff, minus_b)

func _update_info(a: Vector3, b: Vector3, diff: Vector3, minus_b: Vector3):
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a - b = (%.2f, %.2f, %.2f)" % [diff.x, diff.y, diff.z])
	builder.append("|a - b| = %.2f" % diff.length())
	builder.append("Opposite vector -b = (%.2f, %.2f, %.2f)" % [minus_b.x, minus_b.y, minus_b.z])
	info_label.text = "\n".join(builder)
