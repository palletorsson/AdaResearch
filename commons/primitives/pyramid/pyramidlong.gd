# PyramidLong.gd - Long pyramid with rectangular base (6 faces total)
extends Node3D

# @identity
# essence: tall pyramid(rectangular base, height=2.8) — a stretched variant that teaches aspect ratio
# desire: learner sees that changing one dimension breaks square symmetry and changes the entire character
# critical_parameter: pyramid_height = 2.8 — taller than wide, making it a spire rather than a mound
# triggers: nothing — static object placed for spatial comparison with regular pyramid
# emerges: the architectural reading — this is a steeple, an obelisk, a monument; proportion carries meaning
# needs: [missing VR controls — static display; pink color chosen for visibility]
# relationships: sibling to pyramid.gd; demonstrates non-uniform scaling at the geometry level
# truth: proportion is a dimension of meaning — the same topology at different aspect ratios tells different stories
##
## STAGE-2 DNA PROMOTION (2026-07-29). Before this the script had no exports at
## all: one height, one square base, one apex over its centre, all hard-coded. The
## @identity above already names the constant that matters — "critical_parameter:
## pyramid_height = 2.8 — taller than wide" — but 2.8 was a private var, so the
## thing the artifact says it is about could not be turned. Two axes:
##
##   stature       height read as a RATIO to the base   mound · even · spire · needle
##   apex_stance   where the apex sits over that base   centred · edge · corner · beyond
##
## stature=spire returns the literal 2.8 rather than a computed ratio, and centred
## is the old (0, height, 0), so the mesh is bit-for-bit what it was and the 6
## existing placements are unchanged.
##
## stature is not a size knob: the base never moves, only the proportion above it,
## which is exactly the claim in the truth line — same topology, different story.
## apex_stance is borrowed verbatim from the `pyramid` sibling so the two read as
## one family; base_sides is deliberately NOT taken here, because the sibling
## already owns that axis and this artifact's own constant is the aspect ratio.
##
## Usage in map_data.json:
##   "pyramidlong#stature:mound"                     — the spire flattens to a mound
##   "pyramidlong#apex_stance:corner"                — a leaning tower
##   "pyramidlong#stature:needle#apex_stance:beyond"

## Height as a proportion of the base, not an absolute. spire is the shipped 2.8
## over a 0.8 base; mound is half the base (a low hip), even squares the profile,
## needle doubles the spire again.
@export_enum("mound", "even", "spire", "needle") var stature: String = "spire"
## Where the apex sits over the base — a RIGHT pyramid (centred, the old behaviour)
## or an OBLIQUE one. edge = over the midpoint of the first base edge, corner = over
## the first base vertex, beyond = past the base entirely, leaning out of its footprint.
@export_enum("centred", "edge", "corner", "beyond") var apex_stance: String = "centred"

var base_color: Color = Color(1.0, 0.4, 0.8)  # Pink color
var pyramid_height: float = 2.8  # Keep the height you set
var base_width: float = 0.8      # Width (X axis)
var base_length: float = 0.8     # Length (Z axis) - square base

var _mesh_instance: MeshInstance3D

func _ready():
	create_pyramid()

func create_pyramid():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_pyramid_vertices()
	var faces = create_pyramid_faces()
	
	# Add all triangular faces
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "PyramidLong"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)
	_mesh_instance = mesh_instance

func create_pyramid_vertices() -> Array:
	var vertices = []
	var half_width = base_width * 0.5
	var half_length = base_length * 0.5

	# 5 vertices: 4 base corners + 1 apex
	var ring: Array = [
		# Base vertices (square on XZ plane, Y=0)
		Vector3(-half_width, 0, -half_length),  # 0: back-left
		Vector3(half_width, 0, -half_length),   # 1: back-right
		Vector3(half_width, 0, half_length),    # 2: front-right
		Vector3(-half_width, 0, half_length)    # 3: front-left
	]
	vertices.append_array(ring)
	vertices.append(_apex_position(ring))       # 4: top point

	return vertices

## Height resolved from the stature axis. "spire" returns the literal 2.8 the
## artifact shipped with rather than a computed ratio, so the default is exact.
func _resolved_height() -> float:
	match stature:
		"mound":
			return base_width * 0.5
		"even":
			return base_width * 1.0
		"needle":
			return base_width * 7.0
	return pyramid_height

## Apex placement over the base ring. "centred" is the old (0, height, 0).
func _apex_position(ring: Array) -> Vector3:
	var height: float = _resolved_height()
	if ring.is_empty():
		return Vector3(0, height, 0)
	var first: Vector3 = ring[0]
	match apex_stance:
		"edge":
			var mid: Vector3 = (first + (ring[1] as Vector3)) * 0.5
			return Vector3(mid.x, height, mid.z)
		"corner":
			return Vector3(first.x, height, first.z)
		"beyond":
			return Vector3(first.x * 1.6, height, first.z * 1.6)
	return Vector3(0, height, 0)

func create_pyramid_faces() -> Array:
	# 6 triangular faces (2 for square base + 4 triangular sides)
	var faces = [
		# Base (split square into 2 triangles)
		[0, 2, 1],  # Triangle 1 of base (counter-clockwise from below)
		[0, 3, 2],  # Triangle 2 of base
		
		# Side faces (4 triangular faces)
		[0, 1, 4],  # Back face
		[1, 2, 4],  # Right face  
		[2, 3, 4],  # Front face
		[3, 0, 4]   # Left face
	]
	
	return faces

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
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
		
		# Set shader parameters to match the shader uniforms
		material.set_shader_parameter("fill_color", color)
		material.set_shader_parameter("wireframe_color", Color.HOT_PINK)
		material.set_shader_parameter("wireframe_width", 3.0)
		material.set_shader_parameter("wireframe_brightness", 2.0)
		
		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader not found
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		mesh_instance.material_override = standard_material

## Grid config hook. Only rebuilds when a value actually changed AND _ready has
## already built once — an unguarded rebuild here breaks shipped placements.
func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("stature"):
		var wanted: String = str(config_data["stature"])
		if wanted != stature:
			stature = wanted
			rebuild = true
	if config_data.has("apex_stance"):
		var stance: String = str(config_data["apex_stance"])
		if stance != apex_stance:
			apex_stance = stance
			rebuild = true
	if rebuild and _mesh_instance != null and is_inside_tree():
		_rebuild_pyramid()

func _rebuild_pyramid() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	create_pyramid()

func set_base_color(color: Color):
	base_color = color
	var mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance:
		apply_queer_material(mesh_instance, base_color)

func set_pyramid_size(height: float, width: float, length: float):
	pyramid_height = height
	base_width = width
	base_length = length
	# Remove old pyramid and create new one
	if get_child_count() > 0:
		get_child(0).queue_free()
	call_deferred("create_pyramid")
