extends RigidBody3D
## Supplied probe body. One contract: drop(at).
## It waits, frozen, on the floor until it is dropped. drop(at) puts it at `at`
## with no speed and lets it fall. Where it comes to rest says what the
## colliders under it are: it meets collision shapes and never meshes. Its
## height is the number in the Record label. A reader of a plane cannot be
## lighter than this: a body, a shape and gravity.

func drop(at: Vector3) -> void:
	freeze = true
	global_position = at
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	sleeping = false
