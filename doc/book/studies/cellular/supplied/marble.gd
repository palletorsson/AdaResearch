extends RigidBody3D
## Supplied probe body. One contract: drop(at).
## It waits, frozen, until it is dropped. drop(at) puts it at `at`, a position
## in the room (a global position), with no speed, and lets it fall. Where it
## comes to rest says what the colliders under it are: it meets collision shapes
## and never meshes. marble.tscn is the whole marble: a ball of 0.1 m radius,
## so one lying on the ground has its middle at 0.10 m. It is painted BONE.

const Look := preload("res://supplied/look.gd")

func _ready() -> void:
	if has_node("MeshInstance3D"):
		$MeshInstance3D.material_override = Look.paint(Look.BONE)

func drop(at: Vector3) -> void:
	freeze = true
	global_position = at
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	sleeping = false
