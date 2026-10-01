extends MeshInstance3D
## Supplied with this kit: the mark on the floor of launch.tscn. It is a disc
## in GHOST, 0.3 m in radius, lying where the formula says the kit's launch
## comes down: 2 x 4 x 6 / 9.8 = 4.898 m from the Bullet. It has no collider.
## It does not follow the bullet: change `launch` and the mark is wrong until
## you move it in the scene.

const Look := preload("res://supplied/look.gd")

func _ready() -> void:
	material_override = Look.ghost()
