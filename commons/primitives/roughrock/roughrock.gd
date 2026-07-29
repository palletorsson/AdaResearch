# RoughRock.gd - Irregular polyhedron with rough surface
extends Node3D

# @identity
# essence: cube_vertices + deterministic_noise(seed) → irregular polyhedron — controlled randomness
# desire: learner sees a non-uniform organic shape and understands it as seeded perturbation of regular geometry
# critical_parameter: noise_seed — the same seed always produces the same rock; change it, get a different rock
# triggers: nothing at runtime — generated once at _ready() with a fixed seed for repeatability
# emerges: the concept of procedural generation from seed — infinite variation, deterministic replay
# needs: [rock_seed + roughness exposed as config axes [has], missing VR controls — no live slider yet]
# relationships: sibling to all other static primitives; conceptual bridge to fractal/procgen sequences
# truth: nature's irregularity is not random — it is deterministic noise that we lack the seed to predict

var base_color: Color = Color(0.0, 0.8, 0.0)  # Green from pride colors

# --- DNA (stage 2, promoted 2026-07-29) ---
# roughness: the amplitude of the deterministic perturbation. 0.0 shows the regular
#   polyhedron underneath — the claim "irregularity is seeded noise" turns off and you
#   see what it was noise ON. 0.05 is the shipped rock. Past ~0.2 the fixed face list
#   can no longer keep a convex hull and the rock reads as a shard cluster: the point
#   where "controlled randomness" stops being controlled.
@export var roughness: float = 0.05
# rock_seed: which rock out of the infinite deterministic family. 0 is the shipped one.
@export var rock_seed: int = 0

var _built: bool = false
var _mesh_instance: MeshInstance3D = null

func _ready():
	create_rough_rock()
	_built = true

func create_rough_rock():
	if _mesh_instance and is_instance_valid(_mesh_instance):
		remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create irregular vertices with noise
	var vertices = []
	var base_points = [
		Vector3(0.3, 0.2, 0.1),
		Vector3(-0.2, 0.3, 0.15),
		Vector3(-0.25, -0.1, 0.25),
		Vector3(0.1, -0.3, 0.2),
		Vector3(0.25, -0.1, -0.2),
		Vector3(-0.1, 0.2, -0.3),
		Vector3(0.15, 0.35, -0.1),
		Vector3(-0.3, -0.2, -0.1)
	]
	
	# Add roughness to points using deterministic "randomness" for consistency
	for i in range(base_points.size()):
		var point = base_points[i]
		# Use a simple hash function for deterministic variation
		var seed_val: int = i * 12345 + int(point.x * 1000) + int(point.y * 1000) + int(point.z * 1000)
		var rng = RandomNumberGenerator.new()
		rng.seed = seed_val + rock_seed * 7919

		var rough_point = point + Vector3(
			rng.randf_range(-roughness, roughness),
			rng.randf_range(-roughness, roughness),
			rng.randf_range(-roughness, roughness)
		)
		vertices.append(rough_point)
	
	# Create faces connecting points (simplified convex hull approach)
	var faces = [
		[0, 1, 6], [1, 2, 3], [3, 4, 0], [4, 5, 6],
		[6, 1, 2], [2, 7, 3], [3, 7, 4], [4, 7, 5],
		[5, 7, 2], [2, 1, 5], [5, 1, 6], [6, 0, 4]
	]
	
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "RoughRock"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)
	_mesh_instance = mesh_instance

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
	var mesh_instance: MeshInstance3D = _mesh_instance
	if mesh_instance == null and get_child_count() > 0:
		mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance:
		apply_queer_material(mesh_instance, base_color)

func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("roughness"):
		var new_roughness: float = float(config_data["roughness"])
		if not is_equal_approx(new_roughness, roughness):
			roughness = new_roughness
			rebuild = true
	if config_data.has("rock_seed"):
		var new_seed: int = int(config_data["rock_seed"])
		if new_seed != rock_seed:
			rock_seed = new_seed
			rebuild = true
	# Only rebuild when a value actually changed AND _ready already built once —
	# an unguarded rebuild here would re-generate every shipped placement.
	if rebuild and _built and is_inside_tree():
		create_rough_rock()
