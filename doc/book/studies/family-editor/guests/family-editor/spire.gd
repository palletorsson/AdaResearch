@tool
extends Node3D
## The spire: a pyramid whose apex can walk off its base. One axis, `lean`:
## at 0 the apex is over the middle, at 1 over a corner, at 1.6 beyond the base.
## This folder goes to your room whole, so the script names nothing outside it
## and writes its colour out.

const BODY := Color("c6ff3d")   # the look's BODY colour, written out
const BASE := 0.6               # metres along one side of the base
const HEIGHT := 0.8             # metres from the ground up to the apex

@export_range(0.0, 1.6, 0.05) var lean: float = 0.0:
	set(value):
		if value == lean:
			return
		lean = value
		if is_node_ready():
			rebuild()

var rebuilds := 0               # how many times the body has been built
var _skin: MeshInstance3D       # what the eye gets
var _shape: CollisionShape3D    # what a walker and a marble meet

func _ready() -> void:
	_skin = MeshInstance3D.new()
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	_skin.material_override = paint
	add_child(_skin)
	var body := StaticBody3D.new()
	_shape = CollisionShape3D.new()
	body.add_child(_shape)
	add_child(body)
	rebuild()

## Where the apex is, in the spire's own frame.
func apex() -> Vector3:
	return Vector3(-BASE / 2 * lean, HEIGHT, -BASE / 2 * lean)

## Whether the apex is still over the base.
func over_base() -> bool:
	return lean <= 1.0

func rebuild() -> void:
	var half := BASE / 2
	var ring := [Vector3(-half, 0, -half), Vector3(half, 0, -half), Vector3(half, 0, half), Vector3(-half, 0, half)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)    # every face lit flat: a pyramid has edges
	for i in 4:
		for corner: Vector3 in [ring[i], ring[(i + 1) % 4], apex()]:
			surface.add_vertex(corner)
	for corner: Vector3 in [ring[0], ring[2], ring[1], ring[0], ring[3], ring[2]]:
		surface.add_vertex(corner)
	surface.generate_normals()
	_skin.mesh = surface.commit()
	_shape.shape = _skin.mesh.create_convex_shape()
	rebuilds += 1
	if Engine.is_editor_hint():
		print("rebuilt in the editor: lean ", lean)
