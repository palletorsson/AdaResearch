extends Node3D
## The Point Plane guest: a walked plane with its body.
## my_plane.tres, beside this script, is the mesh the Plane study made from a
## walk: a fan of triangles with normals, saved as a file. This script loads it,
## stands it on its place in the room, and gives it a collider, as build_face()
## did in the study. Put your own my_plane.tres in this folder and it is yours.
## A guest names nothing outside its folder, so the colour is written out here.

const BODY := Color("c6ff3d")   # the course look's BODY

var height := 0.12   # metres above the ground: how high the plane lies. Yours to change

func _ready() -> void:
	$Face.mesh = load("res://guests/point-plane/my_plane.tres")
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	$Face.material_override = paint
	# The walk was made somewhere in the study, at 1.12 m. Here its middle goes
	# over the middle of the place, and it lies at `height`.
	var box: AABB = $Face.mesh.get_aabb()
	var middle := box.get_center()
	$Face.position = Vector3(-middle.x, height - middle.y, -middle.z)
	$FaceBody.position = $Face.position
	var shape: ConcavePolygonShape3D = $Face.mesh.create_trimesh_shape()
	shape.backface_collision = true
	$FaceBody/CollisionShape3D.shape = shape
	if box.size.x > 1.6 or box.size.z > 1.6:
		print("Point Plane guest: this walk is %.2f m wide and %.2f m deep, and a place in the room is 1.6 m" % [box.size.x, box.size.z])
