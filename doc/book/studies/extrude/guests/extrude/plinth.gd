extends Node3D
## The guest of the Extrude kit: a plinth, extruded from a walk.
## Paste your own walk over `walk`, choose a height and a taper, and it is
## yours. Everything it needs is in this folder. Its colours are written out,
## because a guest names nothing outside its folder, not even the look.
## It stands on the ground at its own origin, has a collider made from its
## mesh, and carries a plate that says its height and its taper.

const BODY := Color("c6ff3d")     # the kit's BODY, written out
const INK := Color("ffffff")      # the plate's letters
const SHADE := Color("0d0620")    # their edge

@export var height := 0.8     # metres: how far the walk is pulled up
@export var taper := 0.8      # the size of the upper outline: 1 a prism, 0 a pyramid

# The walk of the kit: eight corners on the floor, clockwise seen from above.
# Yours goes here: the line that borrowed/walk.tscn prints.
var walk: Array[Vector3] = [Vector3(-0.4, 0, -0.4), Vector3(0.32, 0, -0.4), Vector3(0.6, 0, -0.12), Vector3(0.6, 0, 0.36), Vector3(0.43, 0, 0.53), Vector3(-0.37, 0, 0.53), Vector3(-0.59, 0, 0.31), Vector3(-0.59, 0, -0.25)]

func _ready() -> void:
	var mesh := extrude(walk, height, taper)
	var solid := MeshInstance3D.new()
	solid.name = "Solid"
	solid.mesh = mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	solid.material_override = paint
	add_child(solid)
	# The mesh is what the eye gets. This is what a marble and a walker get.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	solid.add_child(body)
	# The plate: in front of the wall that is nearest to the aisle.
	var front := 0.0
	for corner in walk:
		front = maxf(front, corner.z)
	var plate := Label3D.new()
	plate.name = "Plate"
	plate.text = "height %.2f m\ntaper %.2f" % [height, taper]
	plate.pixel_size = 0.003
	plate.font_size = 32
	plate.modulate = INK
	plate.outline_modulate = SHADE
	plate.outline_size = 10
	plate.position = Vector3(centre_of(walk).x, minf(height, 1.2) / 2.0, front + 0.02)
	add_child(plate)

func centre_of(points: Array[Vector3]) -> Vector3:
	var sum := Vector3.ZERO
	for point in points:
		sum += point
	return sum / points.size()

# rise: metres up. top: the size of the upper outline, from 1 to 0.
func extrude(outline: Array[Vector3], rise: float, top: float) -> ArrayMesh:
	var centre := centre_of(outline)
	var upper: Array[Vector3] = []
	for corner in outline:
		upper.append(centre + (corner - centre) * top + Vector3.UP * rise)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in range(outline.size()):               # a wall for every edge
		surface.add_vertex(outline[i - 1])
		surface.add_vertex(outline[i])
		surface.add_vertex(upper[i])
		surface.add_vertex(outline[i - 1])
		surface.add_vertex(upper[i])
		surface.add_vertex(upper[i - 1])
	for i in range(1, outline.size() - 1):        # the top: the fan
		surface.add_vertex(upper[0])
		surface.add_vertex(upper[i])
		surface.add_vertex(upper[i + 1])
	for i in range(1, outline.size() - 1):        # the bottom: the fan, wound the other way
		surface.add_vertex(outline[0])
		surface.add_vertex(outline[i + 1])
		surface.add_vertex(outline[i])
	surface.generate_normals()
	return surface.commit()
