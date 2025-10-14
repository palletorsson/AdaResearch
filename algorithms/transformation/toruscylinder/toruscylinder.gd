# TorusCylinder.gd
extends Node3D

@onready var torus_mesh_instance: MeshInstance3D = $TorusMesh
@onready var cylinder_mesh_instance: MeshInstance3D = $CylinderMesh
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var time_elapsed: float = 0.0

func _process(delta):
	time_elapsed += delta
	
	# Rotate the torus around Y axis
	torus_mesh_instance.rotation.y += delta * 0.5
	
	# Animate cylinder moving up and down
	var cylinder_speed = 1.5
	var cylinder_range = 3.0
	cylinder_mesh_instance.position.y = sin(time_elapsed * cylinder_speed) * cylinder_range
