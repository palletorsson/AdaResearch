extends Node3D

# Rotation Settings
@export_group("Rotation")
@export var rotation_speed: Vector3 = Vector3(0, 45, 0)  # degrees per second


func _process(delta):
	_update_rotation(delta)
	
func _update_rotation(delta):
	"""Handle rotation animation"""
	self.rotation_degrees += rotation_speed * delta
