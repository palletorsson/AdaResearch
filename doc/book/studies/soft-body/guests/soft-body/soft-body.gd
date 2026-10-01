extends Node3D
## The guest of the Soft body study: a cloth hung between two posts, 1.4 m
## apart. Walk between the posts and the cloth gives way; walk on and it
## comes back. The posts stop a body; the cloth stops nobody.
## The cloth is the node Cloth, with cloth.gd: the soft part. This script
## only stands the two posts beside it. It names nothing outside its folder
## and declares no class_name.

const BONE := Color("f4efe6")   # the kit's BONE colour, written out
const HEIGHT := 2.0             # metres: the posts, and where the cloth hangs from
const APART := 1.4              # metres between the middles of the posts

func _ready() -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BONE
	paint.roughness = 0.8
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.08, HEIGHT, 0.08)
		post.mesh = mesh
		post.material_override = paint
		post.position = Vector3(side * APART / 2.0, HEIGHT / 2.0, 0.0)
		add_child(post)
		# The mesh is what the eye gets. This is what a marble and a walker get.
		var body := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		collider.shape = shape
		body.add_child(collider)
		post.add_child(body)
