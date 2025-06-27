# simple_cave.gd
# Simple example of using the rhizomatic cave generation system
# Demonstrates basic usage patterns and parameter configuration

extends Node3D

func _ready():
	generate_simple_cave()

func generate_simple_cave():
	"""Generate a basic cave system"""
	print("🏔️ Simple Cave Example: Starting generation...")
	
	# Create the cave generator
	var cave_generator = RhizomeCaveGenerator.new()
	add_child(cave_generator)
	
	# Configure basic parameters
	cave_generator.setup_parameters({
		"size": Vector3(60, 20, 60),      # 60x20x60 unit cave
		"chunk_size": Vector3i(16, 16, 16), # Smaller chunks for speed
		"voxel_scale": 1.0,               # 1 unit per voxel
		"seed": 12345,                    # Reproducible generation
		"initial_chambers": 2,            # Start with 2 chambers
		"growth_iterations": 30           # Moderate complexity
	})
	
	# Configure rhizomatic growth
	cave_generator.configure_rhizome_parameters({
		"branch_probability": 0.6,        # 60% chance to branch
		"merge_distance": 6.0,           # Merge tunnels within 6 units
		"vertical_bias": 0.2,            # Prefer horizontal growth
		"chamber_probability": 0.25,     # 25% chance for chambers
		"max_depth": 5                   # Limit branching depth
	})
	
	# Generate the cave
	var mesh_instances = cave_generator.generate_cave()
	
	# Print results
	var info = cave_generator.get_cave_info()
	print("✅ Cave generated successfully!")
	print("   • Mesh chunks: %d" % info.mesh_instances)
	print("   • Vertices: %d" % info.total_vertices)
	print("   • Triangles: %d" % info.total_triangles)
	print("   • Growth nodes: %d" % info.growth_nodes)
	print("   • Chambers: %d" % info.chambers)
	
	return mesh_instances

# Alternative: Generate cave from code without scene
static func create_cave_procedurally(parent_node: Node3D, params: Dictionary = {}) -> RhizomeCaveGenerator:
	"""Static function to create a cave system procedurally"""
	
	# Default parameters
	var default_params = {
		"size": Vector3(80, 30, 80),
		"chunk_size": Vector3i(20, 20, 20),
		"voxel_scale": 1.0,
		"seed": randi(),
		"initial_chambers": 3,
		"growth_iterations": 40
	}
	
	# Merge with provided parameters
	for key in params:
		default_params[key] = params[key]
	
	# Create and configure generator
	var generator = RhizomeCaveGenerator.new()
	generator.setup_parameters(default_params)
	
	# Default rhizomatic settings
	generator.configure_rhizome_parameters({
		"branch_probability": 0.7,
		"merge_distance": 8.0,
		"vertical_bias": 0.3,
		"chamber_probability": 0.3,
		"max_depth": 6
	})
	
	# Add to scene and generate
	parent_node.add_child(generator)
	generator.generate_cave()
	
	return generator

# Example usage in other scripts:
# var cave = simple_cave.create_cave_procedurally(self, {"size": Vector3(100, 40, 100)}) 