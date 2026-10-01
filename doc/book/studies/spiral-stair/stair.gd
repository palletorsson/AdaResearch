extends Node3D

const Look := preload("res://supplied/look.gd")

@export var treads := 9         # how many
@export var radius := 1.2       # metres from the middle of the well to the middle of a tread
@export var turn_deg := 30.0    # degrees of turn from one tread to the next
@export var rise := 0.18        # metres up from one tread to the next
@export var ramp := false       # ticked: one sloping surface in place of the treads

func _ready() -> void:
	build()

func build() -> void:
	for child in get_children():
		child.free()
	if ramp:
		add_child(slope())
	else:
		for i in range(1, treads + 1):
			add_child(tread(i))

## The function. Where the stair is after i treads, r metres from the middle:
## x and z go round a circle, y goes up. i may be a number between two treads.
func place(i: float, r: float) -> Vector3:
	var angle := deg_to_rad(turn_deg) * i
	return Vector3(r * cos(angle), rise * i, r * sin(angle))

## Tread i: a block one rise high with the middle of its top at place(i).
func tread(i: int) -> StaticBody3D:
	var size := Vector3(0.9, rise, 0.7)
	var box := BoxMesh.new()
	box.size = size
	var block := MeshInstance3D.new()
	block.mesh = box
	block.material_override = Look.paint(Look.BODY)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var body := StaticBody3D.new()
	body.add_child(block)
	body.add_child(collider)
	body.position = place(i, radius) - Vector3(0, rise / 2.0, 0)
	body.rotation.y = -deg_to_rad(turn_deg) * i
	return body

## The ramp: the same function with no steps in it, as one surface.
func slope() -> StaticBody3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in treads + 1:    # one piece more than the stair has treads: the last point of the route is not an edge
		var a := place(i, radius - 0.45)
		var b := place(i, radius + 0.45)
		var c := place(i + 1, radius + 0.45)
		var d := place(i + 1, radius - 0.45)
		for corner: Vector3 in [a, b, c, a, c, d]:
			tool.add_vertex(corner)
	tool.generate_normals()
	var paint := Look.paint(Look.BODY)
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED    # a surface has no thickness: draw it from below too
	var surface := MeshInstance3D.new()
	surface.mesh = tool.commit()
	surface.material_override = paint
	var collider := CollisionShape3D.new()
	collider.shape = surface.mesh.create_trimesh_shape()
	var body := StaticBody3D.new()
	body.add_child(surface)
	body.add_child(collider)
	return body

## The walker's way: the foot of the stair on the floor, then the middle of each tread.
func route() -> Array:
	var points := []
	for i in treads + 1:
		points.append(to_global(place(i, radius)))
	return points

## How high the top is, in metres above the stair's own floor.
func top() -> float:
	return rise * treads
