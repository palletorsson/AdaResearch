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
# OPERATION, and then showed exactly one frozen output of it: the cut depth lived as
# the bare literal 0.1 against a body of 0.2, a ratio of one half, stated nowhere and
# variable never. An operation you can only ever see one result of is indistinguishable
# from a shape. Two axes give it back its verb:
#
#   truncation    how deep the cut goes, as a fraction of the body    0.1 … 1.0
#   origin_solid  whether the un-cut solid is shown around the result  hidden · ghost
#
# truncation is the parameter the Archimedean family is indexed by: slide it and the
# corner faces grow while the original faces shrink, which is the whole content of the
# word "truncated". origin_solid answers the question the static version could not —
# cut from WHAT — by standing the pre-truncation tetrahedron around the result as a
# translucent shell, so the operation is visible and not just its output.
#
# truncation=0.5 + origin_solid=hidden reproduces the previous mesh vertex for vertex,
# and is the default, so the 11 existing placements are unchanged.
#
# Usage in map_data.json:
#   "truncatedtetrahedron"
#   "truncatedtetrahedron#truncation:0.9"
#   "truncatedtetrahedron#truncation:0.25#origin_solid:ghost"

## Half-extent of the seed tetrahedron. The pre-promotion mesh's ±0.2 corners.
const BODY: float = 0.2

## Depth of the cut, as a fraction of the body. 0.5 is the pre-promotion mesh
## (corner vertices at ±0.1 against a body of ±0.2). Toward 0 the cut vanishes and
## the seed tetrahedron reasserts itself; toward 1 the corner faces grow until they
## are the same size as the faces they were cut from.
@export var truncation: float = 0.5
## Whether the solid this was cut from is shown around the result. hidden = the
## legacy display, the result alone; ghost = a translucent shell of the un-cut
## tetrahedron, so the cut is legible as a subtraction.
@export var origin_solid: String = "hidden"

var base_color: Color = Color(1.0, 0.5, 0.0)  # Orange from pride colors

var _mesh_instance: MeshInstance3D
var _ghost_instance: MeshInstance3D
var _built: bool = false

func _ready():
	create_truncated_tetrahedron()

func create_truncated_tetrahedron():
	_teardown()

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Simplified version - create a smaller tetrahedron with cut corners.
	# b = the seed tetrahedron's corners; c = where the cut lands. c/b IS the
	# truncation; at the default 0.5 these are the original 0.2 / 0.1 literals.
	var b: float = BODY
	var c: float = BODY * clampf(truncation, 0.02, 1.0)
	var vertices = [
		Vector3(b, b, b),
		Vector3(-b, -b, b),
		Vector3(-b, b, -b),
		Vector3(b, -b, -b),
		# Cut corners
		Vector3(c, c, -c),
		Vector3(-c, -c, -c),
		Vector3(-c, c, c),
		Vector3(c, -c, c)
	]

	var faces = [
		[0, 4, 6], [1, 5, 7], [2, 6, 4], [3, 7, 5],
		[4, 5, 6, 7], [0, 1, 2, 3]
	]

	for face in faces:
		if face.size() == 3:
			add_triangle_with_normal(st, vertices, face)
		else:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "TruncatedTetrahedron"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)
	_mesh_instance = mesh_instance

	if origin_solid == "ghost":
		_build_origin_ghost(vertices)
	_built = true

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

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	var face_center = (v0 + v1 + v2) / 3.0
	var normal = face_center.normalized()

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
