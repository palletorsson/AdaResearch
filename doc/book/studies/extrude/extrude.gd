extends Node3D

const Look := preload("res://supplied/look.gd")
const Segment := preload("res://supplied/segment.gd")
const Grammar := preload("res://borrowed/grammar_extrude.gd")

@export var height := 0.8     # metres: how far the walk is pulled up
@export var taper := 1.0      # the size of the upper outline: 1 a prism, 0 a pyramid
@export var spire := false    # tick to hand the solid to the project's extrude as well

# A walk we recorded with borrowed/walk.tscn: eight corners on the floor,
# clockwise seen from above. Yours goes here.
var walk: Array[Vector3] = [Vector3(-0.4, 0, -0.4), Vector3(0.32, 0, -0.4), Vector3(0.6, 0, -0.12), Vector3(0.6, 0, 0.36), Vector3(0.43, 0, 0.53), Vector3(-0.37, 0, 0.53), Vector3(-0.59, 0, 0.31), Vector3(-0.59, 0, -0.25)]

func _ready() -> void:
	for i in range(walk.size()):
		var segment := Segment.new()
		add_child(segment)
		segment.show_between(walk[i - 1], walk[i])
	var mesh := extrude(walk, height, taper)
	if spire:
		mesh = Grammar.extrude_up(mesh, 0.5, 0.3)
	$Solid.mesh = mesh
	$Solid.material_override = Look.paint(Look.BODY)
	$Solid/Body/Shape.shape = mesh.create_trimesh_shape()
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	print("%d corners walked, %d vertices in the mesh, %.2f m high" % [walk.size(), vertices.size(), mesh.get_aabb().size.y])

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("drop"):
		$Marble.drop(centre_of(walk) + Vector3.UP * (height + 1.0))
	$Readout.text = "height %.2f m    taper %.2f\nmarble at %.2f m" % [height, taper, $Marble.position.y]

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
