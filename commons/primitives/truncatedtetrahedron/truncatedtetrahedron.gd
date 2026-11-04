# TruncatedTetrahedron.gd - Tetrahedron with cut corners
extends Node3D

# @identity
# essence: tetrahedron with corners cut — each vertex replaced by a triangular face, adding 4 new faces
# desire: learner sees truncation as a topological operation: vertices become faces, edges become edges
# critical_parameter: truncation — how deep the cut goes; the Archimedean family is a one-parameter family
# triggers: SurfaceTool mesh generated at _ready(); rebuilt when apply_grid_config changes the cut
# emerges: the Archimedean insight that truncation transforms one solid into another with more faces
# needs: [missing VR controls — static display only]
# relationships: sibling to grab_tetrahedron and snap_tetrahedron_puzzle; shows topology via truncation
# truth: truncation is a functor — it transforms the vertex-edge-face structure systematically
#
# STAGE-2 DNA PROMOTION (2026-07-29). The artifact claims truncation is an
# OPERATION, and then showed exactly one frozen output of it. Two axes give it back
# its verb:
#
#   truncation    how far along each edge the corner is cut   0.02 … 0.5
#   origin_solid  whether the un-cut solid is shown around the result  hidden · ghost
#
# REAL SOLID (2026-11-04). Until this date the mesh was a self-described "simplified
# version": the four seed corners plus four inner points (two interleaved tetrahedra)
# closed by crossing faces. Measured with platonic_study.topology() it had 8 vertices,
# 19 edges and 8 triangular faces. It was not a truncated tetrahedron at any setting,
# and the 0.5 default the promotion kept "vertex for vertex" was that mesh.
#
# Now each corner of the seed tetrahedron (corners at ±BODY, the even-sign set) is cut
# by a plane through the three points `truncation` of the way along its three edges.
# That leaves 4 cut-corner triangles and 4 truncated faces (hexagons, which are what is
# left of the seed's triangles):
#
#   truncation 1/3  the Archimedean truncated tetrahedron. All 18 edges are equal and
#                   the vertices are the permutations of (3,1,1)·BODY/3 with an even
#                   number of minus signs. 12 vertices, 18 edges, 4 triangles +
#                   4 hexagons. THE DEFAULT.
#   below 1/3       a shallow cut: small triangles, long-edged hexagons
#   above 1/3       a deep cut: the triangles grow and the hexagons' short edges shrink
#   1/2             the cuts meet at the edge midpoints, the hexagons close down to
#                   triangles, and the solid is the octahedron (rectification)
#
# THE 11 PLACEMENTS CHANGE LOOK. None of them sets truncation, so every placement now
# stands the Archimedean solid where it stood the 8-vertex mesh. The extent is the same
# (±BODY on each axis), so footprints are untouched. The old semantics ("fraction of
# the body", 0.5 = the old mesh) are gone, and so is the old mesh.
#
# Usage in map_data.json:
#   "truncatedtetrahedron"                                   the Archimedean solid
#   "truncatedtetrahedron#truncation:0.5"                    cut to the octahedron
#   "truncatedtetrahedron#truncation:0.2#origin_solid:ghost" shallow cut, seed shown

## Half-extent of the seed tetrahedron: its corners sit at (±BODY, ±BODY, ±BODY) with an
## even number of minus signs.
const BODY: float = 0.2

## How far along each edge the corner is cut, as a fraction of the edge. 1/3 is the
## Archimedean truncated tetrahedron; toward 0 the seed tetrahedron reasserts itself;
## at 1/2 the cuts meet at the edge midpoints and the solid is the octahedron.
@export_range(0.02, 0.5, 0.001) var truncation: float = 1.0 / 3.0
## Whether the solid this was cut from is shown around the result. hidden = the
## result alone; ghost = a translucent shell of the un-cut tetrahedron, so the cut is
## legible as a subtraction.
@export var origin_solid: String = "hidden"

var base_color: Color = Color(1.0, 0.5, 0.0)  # Orange from pride colors

var _mesh_instance: MeshInstance3D
var _ghost_instance: MeshInstance3D
var _built: bool = false

func _ready():
	create_truncated_tetrahedron()

## The seed tetrahedron's corners: the even-sign subset of the cube (±BODY)^3.
static func seed_corners() -> Array[Vector3]:
	var b := BODY
	return [Vector3(b, b, b), Vector3(b, -b, -b), Vector3(-b, b, -b), Vector3(-b, -b, b)]

## Faces of the truncated solid, each a convex polygon in order around its boundary.
## Corner i is replaced by the triangle of points cut on its three edges; the seed face
## opposite corner k keeps a hexagon, two cut points per edge. At t = 1/2 the two cut
## points on an edge coincide, so they are welded and the hexagon closes to a triangle.
static func truncated_faces(t: float) -> Array:
	var corners := seed_corners()
	var cut := func(i: int, j: int) -> Vector3:
		return corners[i] + (corners[j] - corners[i]) * t
	var faces: Array = []
	for i in 4:
		var others: Array[int] = []
		for j in 4:
			if j != i: others.append(j)
		faces.append([cut.call(i, others[0]), cut.call(i, others[1]), cut.call(i, others[2])])
	for k in 4:
		var tri: Array[int] = []
		for j in 4:
			if j != k: tri.append(j)
		var ring: Array[Vector3] = []
		for e in 3:
			var a := tri[e]
			var c := tri[(e + 1) % 3]
			ring.append(cut.call(a, c))
			ring.append(cut.call(c, a))
		var welded: Array[Vector3] = []
		for p in ring:
			if welded.is_empty() or welded[-1].distance_to(p) > 0.00001:
				welded.append(p)
		if welded.size() > 1 and welded[-1].distance_to(welded[0]) <= 0.00001:
			welded.pop_back()
		faces.append(welded)
	return faces

func create_truncated_tetrahedron():
	_teardown()

	var t: float = clampf(truncation, 0.02, 0.5)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in truncated_faces(t):
		_add_polygon(st, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "TruncatedTetrahedron"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)
	_mesh_instance = mesh_instance

	if origin_solid == "ghost":
		_build_origin_ghost(seed_corners())
	_built = true

## One flat convex face. A hexagon is split as its middle triangle plus three corner
## triangles, so the split is symmetric under the face's own 3-fold turn (SimpleGrid
## draws every triangle edge, and a fan from one vertex would draw a lopsided face).
func _add_polygon(st: SurfaceTool, poly: Array) -> void:
	var tris: Array = []
	if poly.size() == 3:
		tris = [[0, 1, 2]]
	elif poly.size() == 6:
		tris = [[0, 2, 4], [0, 1, 2], [2, 3, 4], [4, 5, 0]]
	else:
		for i in range(1, poly.size() - 1):
			tris.append([0, i, i + 1])
	for tri in tris:
		add_triangle_with_normal(st, poly, tri)

## The solid before the cut, standing around the result as a translucent shell.
## Same four seed corners, closed as a full tetrahedron — what got truncated.
func _build_origin_ghost(vertices: Array) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seed_faces = [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]
	for face in seed_faces:
		add_triangle_with_normal(st, vertices, face)

	var ghost := MeshInstance3D.new()
	ghost.name = "OriginSolid"
	ghost.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.material_override = mat
	# a hair larger so its faces never z-fight the result's shared faces
	ghost.scale = Vector3.ONE * 1.02
	add_child(ghost)
	_ghost_instance = ghost

func _teardown() -> void:
	if is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()
	_mesh_instance = null
	if is_instance_valid(_ghost_instance):
		_ghost_instance.queue_free()
	_ghost_instance = null

# Adds one triangle with its true face normal, wound clockwise as seen from outside
# (Godot's front face). The solid is centred on the origin and convex, so "outside" is
# the side the face centre lies on.
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0: Vector3 = vertices[face[0]]
	var v1: Vector3 = vertices[face[1]]
	var v2: Vector3 = vertices[face[2]]

	var normal: Vector3 = (v1 - v0).cross(v2 - v0).normalized()
	if normal.dot((v0 + v1 + v2) / 3.0) > 0.0:
		# counter-clockwise from outside: swap to clockwise
		var tmp := v1
		v1 = v2
		v2 = tmp
	else:
		normal = -normal

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_queer_material(mesh_instance: MeshInstance3D, color: Color):
	# Create shader material using the solid wireframe shader
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader

		# Set shader parameters
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)

		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader not found
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		mesh_instance.material_override = standard_material

func set_base_color(color: Color):
	base_color = color
	if is_instance_valid(_mesh_instance):
		apply_queer_material(_mesh_instance, base_color)

func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("truncation"):
		var cut: float = float(config_data["truncation"])
		if not is_equal_approx(cut, truncation):
			truncation = cut
			rebuild = true
	if config_data.has("origin_solid"):
		var shell: String = str(config_data["origin_solid"])
		if shell != origin_solid:
			origin_solid = shell
			rebuild = true
	if config_data.has("base_color"):
		var col: Color = Color(str(config_data["base_color"]))
		if col != base_color:
			base_color = col
			rebuild = true
	# Guarded: rebuild only when a value actually moved and _ready has already
	# built once, so a placement passing unrelated config keys is left alone.
	if rebuild and _built and is_inside_tree():
		create_truncated_tetrahedron()
