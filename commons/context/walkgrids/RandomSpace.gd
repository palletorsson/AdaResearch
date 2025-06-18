# RandomSpace.gd - Pure chaos
extends TopologySpace
class_name RandomSpace

@export var chaos_level: float = 1.0
@export var seed_value: int = 12345

func generate_space():
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var heights = []
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			# Pure randomness - mathematical anarchy
			var height = rng.randf_range(-chaos_level, chaos_level)
			heights.append(height * height_scale)
	
	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	
	# Chaotic material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.2, 0.1) # Aggressive red
	material.roughness = 1.0
	material.metallic = 0.0
	mesh_instance.material_override = material
