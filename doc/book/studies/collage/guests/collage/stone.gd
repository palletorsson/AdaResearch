extends Node3D
## The truncated solid, as a guest of the room: the stone of Melencolia I, by hand.
## The class is solid.gd, beside this file. It is the lesson's solid.gd without
## its first line, because a guest declares no class_name: a room holds many
## guests, and two that declare one name do not load together. So the class is
## taken by its file, with load(), as the lesson took the drafted answer.
## Three things are added for the room. The solid stands on the ground: its box
## says how far it reaches below its own middle, and it is lifted by that much.
## It wears BODY, a colour of the course look, written out here as hex because
## a guest names nothing outside its folder. And it has a body, so that a walker
## and a marble meet it.
## A found body can stand beside it on the same place. That is yours to add.

const BODY := Color("c6ff3d")   # the look's lime

func _ready() -> void:
	var solid: MeshInstance3D = load("res://guests/collage/solid.gd").new()
	add_child(solid)
	solid.position = Vector3(0, -solid.get_aabb().position.y, 0)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	solid.material_override = paint
	solid.create_trimesh_collision()
	print("by hand: ", solid.triangles(), " triangles, ", solid.get_aabb().size, " m")
