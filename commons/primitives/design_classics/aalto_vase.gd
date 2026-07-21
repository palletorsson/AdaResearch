@tool
extends Node3D
class_name AaltoVase

# @identity
# essence: a procedural model of Alvar Aalto's 1936 Savoy vase — a body of revolution whose cross-section is not a circle but a sum of cosines, so the silhouette ripples instead of closing
# desire: to be the design_classics kingdom's argument that "iconic shape" is not an irreducible thing the artist felt — it is a tiny vector of coefficients, and modernism is what happens when you discover that
# critical_parameter: harmonics — the Array[float] of Fourier coefficients [1.0, 0.25, 0.15, -0.1] that perturbs each radial slice; flatten it to [1.0] and you get a bland cylinder, exaggerate it and you get the vase that lives in MoMA
# triggers: _ready() calls _rebuild(); every @export setter (height, base_radius, rim_radius, harmonics, twist, ...) re-triggers _rebuild() so the editor previews live; @tool annotation enables in-editor preview
# emerges: a glass vessel the player can spin and watch breathe — slide harmonics[1] up and the four-lobe wave bloats outward; add twist and the lobes spiral up the height like a slow helix; the player learns that "organic" is just "circular plus a few cosines"
# needs: SurfaceTool [native, has]; StandardMaterial3D with refraction + rim lighting for the glass [has, _create_default_glass()]; harmonics: Array[float] export [has]; @tool for editor preview [has]; lerp(base_radius, rim_radius) + sin(t*PI) bulge for vertical profile [has]
# relationships: a sibling of alessi_tree, eames_chair, noguchi_table in the design_classics primitive_kingdom — each one a procedural restatement of a 20th-century icon; the harmonic cross-section technique prefigures the wavefunctions sequence (where Fourier becomes the explicit subject) and the polar_function lineage; complements the bipyramid / arch / bigframe primitives by being the first one whose silhouette is *named* rather than mathematical
# truth: an icon is a Fourier series with social capital. What makes the Aalto vase Aalto is four numbers; what makes it valuable is that someone signed them.

## Procedural Aalto-style organic vase using harmonic cross-sections
## Based on Alvar Aalto's Savoy vase (1936)

@export var height: float = 1.0:
	set(v):
		height = v
		_rebuild()

@export var base_radius: float = 0.3:
	set(v):
		base_radius = v
		_rebuild()

@export var rim_radius: float = 0.5:
	set(v):
		rim_radius = v
		_rebuild()

@export_range(3, 64) var radial_segments: int = 32:
	set(v):
		radial_segments = v
		_rebuild()

@export_range(2, 32) var height_segments: int = 12:
	set(v):
		height_segments = v
		_rebuild()

@export var harmonics: Array[float] = [1.0, 0.25, 0.15, -0.1]:
	set(v):
		harmonics = v
		_rebuild()

@export var twist: float = 0.0:
	set(v):
		twist = v
		_rebuild()

@export var glass_material: Material = null:
	set(v):
		glass_material = v
		_apply_material()

var _mesh_instance: MeshInstance3D

func _ready():
	_rebuild()

func _rebuild():
	# Remove old mesh
	if _mesh_instance:
		_mesh_instance.queue_free()
	
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	
	var mesh = _generate_mesh()
	_mesh_instance.mesh = mesh
	_apply_material()

func _apply_material():
	if _mesh_instance and glass_material:
		_mesh_instance.material_override = glass_material
	elif _mesh_instance:
		_mesh_instance.material_override = _create_default_glass()

func _create_default_glass() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.97, 1.0, 0.3)
	mat.metallic = 0.0
	mat.roughness = 0.05
	mat.refraction_enabled = true
	mat.refraction_scale = 0.05
	mat.rim_enabled = true
	mat.rim = 0.4
	mat.rim_tint = 0.3
	return mat

## Calculate organic radius at given angle using Fourier harmonics
func _aalto_radius(theta: float, base: float) -> float:
	var r = base
	for i in range(harmonics.size()):
		r += harmonics[i] * base * 0.3 * cos((i + 1) * theta)
	return max(r, 0.01)

func _generate_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = []
	var uvs = []
	
	# Generate vertices ring by ring
	for h in range(height_segments + 1):
		var t = float(h) / height_segments
		var y = t * height
		
		# Interpolate radius from base to rim with slight bulge
		var bulge = sin(t * PI) * 0.1
		var radius = lerp(base_radius, rim_radius, t) + bulge * base_radius
		
		# Apply twist along height
		var twist_offset = t * twist
		
		for r in range(radial_segments):
			var theta = TAU * r / radial_segments + twist_offset
			var organic_r = _aalto_radius(theta, radius)
			
			var x = cos(theta) * organic_r
			var z = sin(theta) * organic_r
			
			vertices.append(Vector3(x, y, z))
			uvs.append(Vector2(float(r) / radial_segments, t))
	
	# Generate triangles
	for h in range(height_segments):
		for r in range(radial_segments):
			var current = h * radial_segments + r
			var next_r = h * radial_segments + (r + 1) % radial_segments
			var above = (h + 1) * radial_segments + r
			var above_next = (h + 1) * radial_segments + (r + 1) % radial_segments
			
			# Calculate normals for smooth shading
			var v0 = vertices[current]
			var v1 = vertices[next_r]
			var v2 = vertices[above]
			var v3 = vertices[above_next]
			
			# Triangle 1
			var n1 = (v1 - v0).cross(v2 - v0).normalized()
			st.set_uv(uvs[current])
			st.set_normal(_vertex_normal(vertices, current, radial_segments, height_segments))
			st.add_vertex(v0)
			
			st.set_uv(uvs[above])
			st.set_normal(_vertex_normal(vertices, above, radial_segments, height_segments))
			st.add_vertex(v2)
			
			st.set_uv(uvs[next_r])
			st.set_normal(_vertex_normal(vertices, next_r, radial_segments, height_segments))
			st.add_vertex(v1)
			
			# Triangle 2
			st.set_uv(uvs[next_r])
			st.set_normal(_vertex_normal(vertices, next_r, radial_segments, height_segments))
			st.add_vertex(v1)
			
			st.set_uv(uvs[above])
			st.set_normal(_vertex_normal(vertices, above, radial_segments, height_segments))
			st.add_vertex(v2)
			
			st.set_uv(uvs[above_next])
			st.set_normal(_vertex_normal(vertices, above_next, radial_segments, height_segments))
			st.add_vertex(v3)
	
	# Generate bottom cap
	var bottom_center = Vector3(0, 0, 0)
	for r in range(radial_segments):
		var current = r
		var next = (r + 1) % radial_segments
		
		st.set_normal(Vector3.DOWN)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(bottom_center)
		
		st.set_normal(Vector3.DOWN)
		st.set_uv(uvs[next])
		st.add_vertex(vertices[next])
		
		st.set_normal(Vector3.DOWN)
		st.set_uv(uvs[current])
		st.add_vertex(vertices[current])
	
	return st.commit()

func _vertex_normal(verts: Array, idx: int, r_seg: int, h_seg: int) -> Vector3:
	var v = verts[idx]
	# Simple approximation: normal points outward from Y axis
	var n = Vector3(v.x, 0, v.z).normalized()
	# Blend with some vertical component based on height change
	var h = int(idx / r_seg)
	if h > 0 and h < h_seg:
		var below = verts[idx - r_seg]
		var above = verts[idx + r_seg]
		var tangent = (above - below).normalized()
		n = n.lerp(tangent.cross(n).cross(tangent).normalized(), 0.5)
	return n
