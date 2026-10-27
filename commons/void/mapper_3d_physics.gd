extends "res://commons/interfaces/value_mapper_3d.gd"
## Keep the original FM mapper, including its grabbable point. Presets and
## boundary clamps must update the frozen rigid body's physics pose as well.

func set_values(x_value: float, y_value: float, z_value: float) -> void:
	super.set_values(x_value, y_value, z_value)
	_sync_point()

func _constrain_point() -> void:
	var bounded: Vector3 = point.position.clamp(Vector3.ZERO, space_size)
	# Reassigning an unchanged frozen pose every render frame feeds an old
	# physics snapshot back into Jolt and alternates it with a newly set preset.
	if not point.position.is_equal_approx(bounded):
		point.position = bounded
		_sync_point()

func _sync_point() -> void:
	if point is RigidBody3D and point.is_inside_tree():
		point.force_update_transform()
		PhysicsServer3D.body_set_state(point.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, point.global_transform)
