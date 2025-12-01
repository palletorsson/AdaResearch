class_name ParticleResources
extends Node

## Shared Particle Resources Singleton
## Provides shared meshes and materials for particle system optimization
## Created by: Agent-PerformanceEngineer
## Protocol: IACP v2.2

# Shared meshes (created once, reused by all particles)
var sphere_mesh: SphereMesh
var box_mesh: BoxMesh

# Shared materials
var particle_material: StandardMaterial3D
var confetti_materials: Array[StandardMaterial3D] = []

# MultiMesh instances (managed by emitters)
var multimesh_pool: Dictionary = {}

func _ready():
	create_shared_meshes()
	create_shared_materials()
	print("ParticleResources: Shared resources initialized")

func create_shared_meshes():
	"""Create shared mesh resources"""
	# Sphere for regular particles
	sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1
	sphere_mesh.radial_segments = 8  # Low poly for performance
	sphere_mesh.rings = 4
	
	# Box for confetti particles
	box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.08, 0.02, 0.05)

func create_shared_materials():
	"""Create shared material resources"""
	# Default particle material (pink emission)
	particle_material = StandardMaterial3D.new()
	particle_material.albedo_color = Color(1.0, 0.6, 1.0, 1.0)
	particle_material.emission_enabled = true
	particle_material.emission = Color(1.0, 0.6, 1.0) * 0.5
	particle_material.emission_energy_multiplier = 0.6
	particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_material.vertex_color_use_as_albedo = true  # For per-instance colors
	
	# Confetti materials (variety of colors)
	var confetti_colors = [
		Color(1.0, 0.6, 1.0, 1.0),   # Pink
		Color(0.5, 0.5, 1.0, 1.0),   # Blue
		Color(0.5, 1.0, 0.5, 1.0),   # Green
		Color(1.0, 1.0, 0.5, 1.0),   # Yellow
		Color(1.0, 0.5, 0.5, 1.0),   # Red
		Color(0.5, 1.0, 1.0, 1.0),   # Cyan
	]
	
	for color in confetti_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.6
		mat.emission_energy_multiplier = 0.8
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.metallic = 0.5
		mat.roughness = 0.3
		mat.vertex_color_use_as_albedo = true
		confetti_materials.append(mat)

func get_sphere_mesh() -> SphereMesh:
	"""Get shared sphere mesh for particles"""
	return sphere_mesh

func get_box_mesh() -> BoxMesh:
	"""Get shared box mesh for confetti"""
	return box_mesh

func get_particle_material() -> StandardMaterial3D:
	"""Get shared particle material"""
	return particle_material

func get_random_confetti_material() -> StandardMaterial3D:
	"""Get random confetti material"""
	return confetti_materials[randi() % confetti_materials.size()]

func create_multimesh(max_instances: int, mesh: Mesh) -> MultiMesh:
	"""Create a MultiMesh for particle instancing"""
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 0  # Start with 0, grow as needed
	multimesh.visible_instance_count = 0
	multimesh.mesh = mesh
	
	# Enable custom data for per-instance colors/alpha
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	
	return multimesh
