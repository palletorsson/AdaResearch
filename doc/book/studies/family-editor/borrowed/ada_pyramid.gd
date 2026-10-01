extends Node3D
## Borrowed from Ada: commons/primitives/pyramid/pyramid.gd, the pyramid that
## stands in the halls. One contract: set `apex_stance` (or `base_sides`) BEFORE
## add_child(). The body is built once, in _ready(), from the values it holds
## then; changed afterwards, the field changes and the body does not.
## Ada's, line for line: the two exports with their @export_enum, pyramid_height
## and base_size, _create_pyramid_vertices(), _base_ring(), _apex_position() and
## _create_pyramid_faces(). Ours: Ada paints the body with a grid shader in a
## colour of its own, Color(1.0, 0.8, 0.2), and builds the mesh with a helper
## script; here a SurfaceTool builds it and it is painted in the look's BODY, so
## that this file needs nothing of Ada's project. Left out: the hook a hall's
## map uses to set the values (apply_grid_config) and set_pyramid_size().

const Look := preload("res://supplied/look.gd")

## How many sides the base polygon has. 4 is the square base this artifact has
## always had; 3 makes it a tetrahedron, 6 a hexagonal pyramid.
@export var base_sides: int = 4
## Where the apex sits over the base — a RIGHT pyramid (centred, the old behaviour)
## or an OBLIQUE one. edge = over the midpoint of the first base edge, corner = over
## the first base vertex, beyond = past the base entirely, leaning out of its footprint.
@export_enum("centred", "edge", "corner", "beyond") var apex_stance: String = "centred"

var base_color: Color = Look.BODY
var pyramid_height: float = 0.8
var base_size: float = 0.6
var _mesh_instance: MeshInstance3D

func _ready():
	_rebuild_pyramid()

func _rebuild_pyramid() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	var vertices := _create_pyramid_vertices()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)    # every face lit flat: a pyramid has edges
	for face: Array in _create_pyramid_faces():
		for index: int in face:
			surface.add_vertex(vertices[index])
	surface.generate_normals()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Pyramid"
	_mesh_instance.mesh = surface.commit()
	_mesh_instance.material_override = Look.paint(base_color)
	add_child(_mesh_instance)

func _create_pyramid_vertices() -> Array[Vector3]:
	var vertices: Array[Vector3] = []
	var ring: Array[Vector3] = _base_ring()
	vertices.append_array(ring)
	vertices.append(_apex_position(ring))
	return vertices

## The base polygon, laid flat on y = 0. For base_sides == 4 this returns the
## literal corner list the artifact shipped with, so the default is exact.
func _base_ring() -> Array[Vector3]:
	var ring: Array[Vector3] = []
	var half_base: float = base_size * 0.5
	var sides: int = max(3, base_sides)
	if sides == 4:
		ring.append_array([
			Vector3(-half_base, 0, -half_base),
			Vector3(half_base, 0, -half_base),
			Vector3(half_base, 0, half_base),
			Vector3(-half_base, 0, half_base)
		])
		return ring
	# Same circumradius and the same starting corner the square had (225 degrees),
	# so a 3- or 6-sided base sits in the footprint the square described.
	var radius: float = half_base * sqrt(2.0)
	for i in sides:
		var angle: float = deg_to_rad(225.0) + TAU * float(i) / float(sides)
		ring.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
	return ring

func _apex_position(ring: Array[Vector3]) -> Vector3:
	var apex: Vector3 = Vector3(0, pyramid_height, 0)
	if ring.is_empty():
		return apex
	match apex_stance:
		"edge":
			var mid: Vector3 = (ring[0] + ring[1 % ring.size()]) * 0.5
			apex = Vector3(mid.x, pyramid_height, mid.z)
		"corner":
			apex = Vector3(ring[0].x, pyramid_height, ring[0].z)
		"beyond":
			apex = Vector3(ring[0].x * 1.6, pyramid_height, ring[0].z * 1.6)
	return apex

func _create_pyramid_faces() -> Array:
	var sides: int = max(3, base_sides)
	var faces: Array = []
	# Base, fanned from vertex 0 and wound to face down.
	for i in range(1, sides - 1):
		faces.append([0, i + 1, i])
	# One triangle per base edge, up to the apex (the last vertex).
	for j in sides:
		faces.append([j, (j + 1) % sides, sides])
	return faces

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = Look.paint(base_color)
