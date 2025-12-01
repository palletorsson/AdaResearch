extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const POINT_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_text.tscn")

var point: Node3D
var x_line: Node3D
var y_line: Node3D
var z_line: Node3D

func _ready() -> void:
	super._ready()
	create_axes(1.0)
	point = POINT_SCENE.instantiate()
	point.name = "ReferencePoint"
	add_child(point)
	point.position = Vector3(1.0, 1.0, 1.0)
	var highlight = point.get_node_or_null("HighlightRing")
	if highlight:
		highlight.visible = false
	
	# Lock point in place
	if point.has_method("set_freeze_enabled"):
		point.set_freeze_enabled(true)
	else:
		point.set("freeze", true)
		
	x_line = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color.RED, "X-line", false)
	y_line = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color.GREEN, "Y-line", false)
	z_line = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color.BLUE, "Z-line", false)
	
	# Initial update only - no process loop needed for static scene
	_update_vectors()
	
	# Disable processing as this is a static visualization
	set_process(false)

func _update_vectors() -> void:
	if point == null:
		return
	var pos: Vector3 = point.position
	update_vector(x_line, pos * Vector3.RIGHT)
	update_vector(y_line, pos * Vector3.UP)
	update_vector(z_line, pos * Vector3.BACK)
