extends Node3D
## The spiral stair as a guest: a way up that stands on one place of the room.
## It is stair.gd of the Spiral stair kit, made narrow enough for a place 1.6 m
## wide, with its foot turned to the aisle, and with one thing added: a plate.
##   - everything it needs is in this folder; it names nothing outside it, so
##     the two colours are written out (BODY and LINE of the kit's look);
##   - it stands on the ground at its own origin and fits in 1.6 m by 1.6 m;
##   - it declares no class_name.
## The plate lies on the floor at the foot. A body that steps on it and has a
## walk_to() is handed the stair's route: the room's walker climbs by itself.
## The keys are not heard until that walk ends, at the top or where it is stopped.

const BODY := Color("c6ff3d")    # acid lime: the made body
const LINE := Color("ffffff")    # white: the plate, a mark on the floor
const WIDE := 0.56               # metres: a tread from its inner end to its outer end
const DEEP := 0.35               # metres: a tread from front to back

@export var treads := 6         # how many
@export var radius := 0.5       # metres from the middle of the well to the middle of a tread
@export var turn_deg := 40.0    # degrees of turn from one tread to the next
@export var rise := 0.30        # metres up from one tread to the next
@export var foot_deg := 90.0    # where on the circle the stair begins: 90 is the side of the aisle
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
	add_child(plate())

## The function. Where the stair is after i treads, r metres from the middle:
## x and z go round a circle, y goes up. i may be a number between two treads.
func place(i: float, r: float) -> Vector3:
	var angle := deg_to_rad(foot_deg + turn_deg * i)
	return Vector3(r * cos(angle), rise * i, r * sin(angle))

## Tread i: a block one rise high with the middle of its top at place(i).
func tread(i: int) -> StaticBody3D:
	var size := Vector3(WIDE, rise, DEEP)
	var box := BoxMesh.new()
	box.size = size
	var block := MeshInstance3D.new()
	block.mesh = box
	block.material_override = paint(BODY)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var body := StaticBody3D.new()
	body.add_child(block)
	body.add_child(collider)
	body.position = place(i, radius) - Vector3(0, rise / 2.0, 0)
	body.rotation.y = -deg_to_rad(foot_deg + turn_deg * i)
	return body

## The ramp: the same function with no steps in it, as one surface.
func slope() -> StaticBody3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in treads + 1:
		var a := place(i, radius - WIDE / 2.0)
		var b := place(i, radius + WIDE / 2.0)
		var c := place(i + 1, radius + WIDE / 2.0)
		var d := place(i + 1, radius - WIDE / 2.0)
		for corner: Vector3 in [a, b, c, a, c, d]:
			tool.add_vertex(corner)
	tool.generate_normals()
	var both_sides := paint(BODY)
	both_sides.cull_mode = BaseMaterial3D.CULL_DISABLED    # a surface has no thickness: draw it from below too
	var surface := MeshInstance3D.new()
	surface.mesh = tool.commit()
	surface.material_override = both_sides
	var collider := CollisionShape3D.new()
	collider.shape = surface.mesh.create_trimesh_shape()
	var body := StaticBody3D.new()
	body.add_child(surface)
	body.add_child(collider)
	return body

## The plate at the foot: a mark for the eye and an Area3D for a body.
func plate() -> Area3D:
	var size := Vector3(WIDE, 0.02, DEEP)
	var box := BoxMesh.new()
	box.size = size
	var mark := MeshInstance3D.new()
	mark.mesh = box
	mark.material_override = paint(LINE)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 0.4, 0.2)
	var feeler := CollisionShape3D.new()
	feeler.shape = shape
	feeler.position.y = 0.2
	var area := Area3D.new()
	area.add_child(mark)
	area.add_child(feeler)
	area.position = place(0, radius) + Vector3(0, 0.01, 0)
	area.rotation.y = -deg_to_rad(foot_deg)
	area.body_entered.connect(_on_plate_entered)
	return area

func _on_plate_entered(body: Node3D) -> void:
	if body.has_method("walk_to"):
		body.walk_to(route())

## A body's way up: the foot of the stair on the floor, then the middle of each tread.
func route() -> Array:
	var points := []
	for i in treads + 1:
		points.append(to_global(place(i, radius)))
	return points

## How high the top is, in metres above the stair's own floor.
func top() -> float:
	return rise * treads

func paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
