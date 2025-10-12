extends Node3D

@export var num_points: int = 30
@export var area_size: Vector3 = Vector3(1.0, 1.0, 1.0)

var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_color_with_text.tscn")

func _ready():
	randomize()
	spawn_points()

func spawn_points():
	var half_extents := area_size * 0.5
	for i in range(num_points):
		var p := point_scene.instantiate()
		p.name = "Point_%d" % i
		add_child(p)
		var pos := Vector3(
			randf_range(-half_extents.x, half_extents.x),
			randf_range(-half_extents.y, half_extents.y),
			randf_range(-half_extents.z, half_extents.z)
		)
		p.position = pos

