class_name Found
extends Node3D

@export var file := "res://found.gltf"   # a body somebody else made, as a file
@export var unit: float = 0.01           # metres for one unit of the file: 0.01 for centimetres

var part: MeshInstance3D                 # the mesh inside the file, once build() has brought it in

func _ready() -> void:
	build()

func build() -> void:
	var body: Node3D = load(file).instantiate()
	add_child(body)
	part = body.get_child(0)
	var box := part.get_aabb()
	print(part.name, " arrived as ", box)
	body.scale = Vector3.ONE * unit
	body.position = -(box.position + Vector3(box.size.x, 0.0, box.size.z) / 2.0) * unit

func triangles() -> int:
	var arrays := part.mesh.surface_get_arrays(0)
	return arrays[Mesh.ARRAY_INDEX].size() / 3
