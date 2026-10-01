extends StaticBody3D
## Supplied with this kit: a plank that is on collision layer 2 and on no other.
## Contract: none to call. It is a board of `size` metres with a collider of the
## same size, painted GHOST, because the walker, the marble and a ray that looks
## at layer 1 all pass through it. For a ray whose mask has layer 2 in it, it is
## ground. The layer is set here, in _ready(), so that it can be read.

const Look := preload("res://supplied/look.gd")

@export var size := Vector3(0.8, 0.05, 2.0)   # metres

func _ready() -> void:
	collision_layer = 2    # the number 2 is layer 2 alone; 1 is layer 1; 3 is both
	collision_mask = 0     # a board looks for nothing
	var box := BoxMesh.new()
	box.size = size
	var skin := MeshInstance3D.new()
	skin.name = "Skin"
	skin.mesh = box
	skin.material_override = Look.ghost()
	add_child(skin)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
