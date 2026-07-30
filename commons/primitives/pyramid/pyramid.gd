# Pyramid.gd - Regular pyramid with square base (5 faces total)
extends Node3D

# @identity
# essence: pyramid(apex, base_square) — 5 vertices, 8 edges, 5 faces with grid shader overlay
# desire: learner sees the pyramid as a static reference object — a stable, canonical 3D form
# critical_parameter: grid shader — makes face normals and surface orientation visible through grid lines
# triggers: nothing — static, placed for observation and comparison against pyramid_edit
# emerges: the grid shader as a diagnostic tool — surface orientation becomes readable at a glance
# needs: [missing VR controls — static display only; use pyramid_edit for interaction]
# relationships: static sibling to pyramid_edit; used as reference geometry in scale demonstrations
# truth: a pyramid has 5 vertices but only 1 is special — the apex determines the form
##
## STAGE-2 DNA PROMOTION (2026-07-29). Before this the script had no exports at
## all: one square base, one apex over its centre, hard-coded. The word "pyramid"
## was doing the arguing, and the geometry could not answer back. Two axes lift the
## two constants that the name is actually hiding —
##
##   base_sides    how many sides the base polygon has   3 · 4 · 5 · 6 · 8
##   apex_stance   where the apex sits over that base    centred · edge · corner · beyond
##
## base_sides=4 reproduces the literal corner list bit-for-bit and apex_stance=centred
## is the old (0, h, 0), so all 8 existing placements are untouched. Together they say
## what the truth line only half-says: the apex determines the form, but only against a
## base that could have been otherwise — and a pyramid whose apex has walked off the
## centre is still a pyramid, with the same base, the same height and (Cavalieri) the
## same volume.
##
## Usage in map_data.json:
##   "pyramid#base_sides:3"                        — a tetrahedron
##   "pyramid#apex_stance:corner"                  — oblique, apex over one corner
##   "pyramid#base_sides:6#apex_stance:beyond"
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

## How many sides the base polygon has. 4 is the square base this artifact has
## always had; 3 makes it a tetrahedron, 6 a hexagonal pyramid.
@export var base_sides: int = 4
## Where the apex sits over the base — a RIGHT pyramid (centred, the old behaviour)
## or an OBLIQUE one. edge = over the midpoint of the first base edge, corner = over
## the first base vertex, beyond = past the base entirely, leaning out of its footprint.
@export_enum("centred", "edge", "corner", "beyond") var apex_stance: String = "centred"

var base_color: Color = Color(1.0, 0.8, 0.2)
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
	var geometry := _pyramid_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Pyramid",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _pyramid_geometry() -> Dictionary:
	var vertices := _create_pyramid_vertices()
	var faces := _create_pyramid_faces()
	return {
		"vertices": vertices,
		"faces": faces
	}

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

## Grid config hook. Only rebuilds when a value actually changed AND _ready has
## already built once — an unguarded rebuild here breaks shipped placements.
func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("base_sides"):
		var sides: int = max(3, int(config_data["base_sides"]))
		if sides != base_sides:
			base_sides = sides
			rebuild = true
	if config_data.has("apex_stance"):
		var stance: String = str(config_data["apex_stance"])
		if stance != apex_stance:
			apex_stance = stance
			rebuild = true
	if rebuild and _mesh_instance != null and is_inside_tree():
		_rebuild_pyramid()

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

func set_pyramid_size(height: float, base: float) -> void:
	pyramid_height = height
	base_size = base
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
	_mesh_instance = null
	call_deferred("_rebuild_pyramid")
