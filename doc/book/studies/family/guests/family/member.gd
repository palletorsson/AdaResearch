extends Node3D
## One member of the family, as a guest of the room: Globe, 8, 4.
## A member is carried by writing it down: its class and two numbers. The class
## is globe.gd, beside this file. It is the lesson's globe.gd without its first
## line, because a guest declares no class_name: a room holds many guests, and
## two that declare one name do not load together. So the class is taken by its
## file, with load(), as Point Cube took the drafter's answer.
## Three things are added for the room. The member stands on the ground: a
## SphereMesh is 1 m across, so its middle is at 0.5 m. It wears BODY, a colour
## of the course look, written out here as hex because a guest names nothing
## outside its folder. And it has a body, so that a walker and a marble meet it.
## The class and its two numbers are yours to replace.

const BODY := Color("c6ff3d")   # the look's lime

func _ready() -> void:
	var member: MeshInstance3D = load("res://guests/family/globe.gd").new()
	member.segments = 8
	member.rings = 4
	add_child(member)
	member.position = Vector3(0, 0.5, 0)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	member.material_override = paint
	member.create_trimesh_collision()
	print("Globe, ", member.segments, ", ", member.rings, ": ", member.triangles(), " triangles")
