extends Node3D
## The guest of Combine: the carved body, baked, with its verbs over the door.
## It is what every guest is:
##   - a folder guests/combine/ with the scene combine.tscn in it and all the
##     scene needs beside it: this script and carved.tres, the baked mesh;
##   - it names nothing outside its folder, so it writes its colours out;
##   - it stands on the ground at its own origin and fits in a box 1.6 m wide
##     and deep;
##   - it declares no class_name.
## carved.tres is a mesh and nothing else: corners, triangles and four paints.
## It holds no operand and no verb, so this body cannot be carved again from
## here. The one line of verbs it carries was written onto it by the kit's
## keep(), as a text, and this script hangs that text over the door.

const INK := Color("ffffff")     # the kit's INK and SHADE, written out
const SHADE := Color("0d0620")

func _ready() -> void:
	var mesh: Mesh = load("res://guests/combine/carved.tres")
	var body := MeshInstance3D.new()
	body.mesh = mesh
	add_child(body)
	# The mesh is what the eye gets. This is what a walker and a marble get:
	# a collider made from the same triangles.
	var solid := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	solid.add_child(collider)
	body.add_child(solid)
	@warning_ignore("integer_division")
	var triangles := mesh.get_faces().size() / 3
	var plate := Label3D.new()
	plate.text = "%s\n%d triangles listed, %d baked" % [mesh.get_meta("verbs", "no verbs were kept"), mesh.get_meta("listed", 0), triangles]
	plate.pixel_size = 0.002
	plate.font_size = 40
	plate.modulate = INK
	plate.outline_modulate = SHADE
	plate.outline_size = 12
	plate.position = Vector3(0.0, 2.62, 0.74)
	add_child(plate)
