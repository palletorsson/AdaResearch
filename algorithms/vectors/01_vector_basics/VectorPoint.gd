extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const POINT_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_text.tscn")

var point: Node3D
var info_label: Label3D
var x_line: Node3D
var y_line: Node3D
var z_line: Node3D

func _ready() -> void:
	super._ready()
	create_axes(1.0)
	point = POINT_SCENE.instantiate()
	point.name = "ReferencePoint"
	add_child(point)
	point.position = Vector3(0.5, 0.5, 0.5)
	var highlight = point.get_node_or_null("HighlightRing")
	if highlight:
		highlight.visible = false
	if point.has_method("set_freeze_enabled"):
		point.set_freeze_enabled(true)
	else:
		point.set("freeze", true)
	info_label = create_info_panel("Point", Vector3(-1.6, 1.5, 0.0))
	x_line = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color.RED, "X-line", false)
	y_line = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color.GREEN, "Y-line", false)
	z_line = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color.BLUE, "Z-line", false)
	_update_info()

func _process(_delta: float) -> void:
	_update_info()

func _update_info() -> void:
	if point == null:
		return
	var pos: Vector3 = point.position
	update_vector(x_line, pos * Vector3.RIGHT)
	update_vector(y_line, pos * Vector3.UP)
	update_vector(z_line, pos * Vector3.BACK)
	var builder := []
	builder.append("Point Position")
	builder.append("x = %.2f" % pos.x)
	builder.append("y = %.2f" % pos.y)
	builder.append("z = %.2f" % pos.z)
	info_label.text = "
".join(builder)
