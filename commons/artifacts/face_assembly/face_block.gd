extends Node3D
## One face: the building block of the template tables (template_build.gd).
## It is what the hand holds when a face has been taken from the hanging box, so it is what the wrist clock
## shows as the selected item (commons/data/inventory/items.json: face_triangle, face_square, tool "face").
## Nothing is placed with it by the hand itself: a frame on a building table takes one face for each trigger.
const Kit = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const EDGE := 0.32
const HALF_THICKNESS := 0.009

@export_enum("Triangle:3", "Square:4") var sides := 3


static func outline(count: int) -> PackedVector3Array:
	if count == 4:
		return PackedVector3Array([Vector3(-EDGE / 2, 0, -EDGE / 2), Vector3(EDGE / 2, 0, -EDGE / 2), Vector3(EDGE / 2, 0, EDGE / 2), Vector3(-EDGE / 2, 0, EDGE / 2)])
	var altitude := EDGE * sqrt(3.0) / 2
	return PackedVector3Array([Vector3(-EDGE / 2, 0, -altitude / 3), Vector3(EDGE / 2, 0, -altitude / 3), Vector3(0, 0, altitude * 2 / 3)])


static func panel(count: int) -> ArrayMesh:
	var polygon := outline(count)
	var vertices := PackedVector3Array()
	for y in [-HALF_THICKNESS, HALF_THICKNESS]:
		for v in polygon: vertices.append(v + Vector3.UP * y)
	var faces: Array = []
	var bottom: Array = []
	var top: Array = []
	for i in count:
		bottom.append(count - 1 - i)
		top.append(count + i)
	faces.append(bottom)
	faces.append(top)
	for i in count: faces.append([i, (i + 1) % count, (i + 1) % count + count, i + count])
	return Kit.mesh(vertices, faces)


func _ready() -> void:
	var face := MeshInstance3D.new()
	face.name = "Face"
	face.mesh = panel(sides)
	face.material_override = Kit.material(Color("d78ba7"))
	# standing, so it reads as a shape from the side as well as from above
	face.rotation = Vector3(deg_to_rad(-62), 0, 0)
	add_child(face)
