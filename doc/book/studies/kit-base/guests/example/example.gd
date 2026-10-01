extends Node3D
## The example guest: a box of 0.5 m that a body can stand on and walk into.
## It shows what every guest is:
##   - a folder guests/<name>/ with the scene <name>.tscn in it, and everything
##     the scene needs in the same folder: this script is all this one needs;
##   - it names nothing outside its folder, not even the look in supplied/:
##     a guest writes its colours out;
##   - it stands on the ground at its own origin, so its box is lifted by half
##     its height, and it fits in a box 1.6 m wide and deep;
##   - it declares no class_name.

const BODY := Color("c6ff3d")   # the kit's BODY colour, written out
const EDGE := 0.5               # metres

func _ready() -> void:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(EDGE, EDGE, EDGE)
	box.mesh = mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	box.material_override = paint
	box.position.y = EDGE / 2.0
	add_child(box)
	# The mesh is what the eye gets. This is what a marble and a walker get.
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	body.add_child(collider)
	box.add_child(body)
