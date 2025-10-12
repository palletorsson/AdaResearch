extends Node3D

@export var num_lines: int = 20
@export var area_size: Vector3 = Vector3(2.0, 2.0, 2.0)

var line_scene: PackedScene = preload("res://commons/primitives/line/line.tscn")

func _ready():
	randomize()
	spawn_lines()

func spawn_lines():
	var half := area_size * 0.5
	for i in range(num_lines):
		var line_instance: Node3D = line_scene.instantiate()
		line_instance.name = "Line_%d" % i
		add_child(line_instance)
		var container: Node3D = line_instance.get_node("lineContainer")
		var p1: Node3D = container.get_node("GrabSphere")
		var p2: Node3D = container.get_node("GrabSphere2")
		p1.position = Vector3(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y),
			randf_range(-half.z, half.z)
		)
		p2.position = Vector3(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y),
			randf_range(-half.z, half.z)
		)
		if container.has_method("refresh_connections"):
			container.call_deferred("refresh_connections")

