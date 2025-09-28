extends VectorSceneBase

var vector_a: Node3D
var vector_b: Node3D
var sum_vector: Node3D
var tip_tail_b: Node3D
var tip_tail_a: Node3D
var info_label: Label3D

func _ready():
	super._ready()
	create_axes(3.5)
	create_floor(9.0)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.8, 0.6, -0.2), Color(0.9, 0.4, 0.3, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(0.4, 1.6, 0.9), Color(0.3, 0.8, 0.9, 1.0), "Vector b")
	sum_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 1.0, 1.0, 1.0), "a + b", false)
	tip_tail_b = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.3, 0.8, 0.9, 0.6), "b@a", false)
	tip_tail_a = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.9, 0.4, 0.3, 0.6), "a@b", false)
	info_label = create_info_panel("Vector Addition", Vector3(-2.5, 2.2, 0.0))

func _process(_delta):
	var a = get_vector(vector_a)
	var b = get_vector(vector_b)
	var result = a + b
	update_vector(sum_vector, result)
	var a_tip = get_arrow_end_position(vector_a)
	var b_tip = get_arrow_end_position(vector_b)
	tip_tail_b.position = a_tip
	update_vector(tip_tail_b, b)
	tip_tail_a.position = b_tip
	update_vector(tip_tail_a, a)
	_update_info(a, b, result)

func _update_info(a: Vector3, b: Vector3, result: Vector3):
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("a + b = (%.2f, %.2f, %.2f)" % [result.x, result.y, result.z])
	builder.append("|a + b| = %.2f" % result.length())
	builder.append("Triangle inequality: %.2f â‰¤ %.2f" % [result.length(), a.length() + b.length()])
	info_label.text = "\n".join(builder)
