# RhizomeCaveDemoController.gd
# Simplified cave generation controller - no UI, camera, or VR controls
# Only generates caves automatically

extends Node3D

# Cave generator
@onready var cave_generator_node = $CaveGenerator
var cave_generator: RhizomeCaveGenerator

func _ready():
	setup_cave_generator()
	
	# Generate initial cave asynchronously to prevent blocking on startup
	call_deferred("generate_cave_async")

# UI setup removed - no UI needed for cave generation only

func setup_cave_generator():
	"""Initialize the cave generator"""
	cave_generator = RhizomeCaveGenerator.new()
	cave_generator.name = "RhizomeCaveGenerator"
	cave_generator_node.add_child(cave_generator)
	
	# Connect signals
	cave_generator.generation_progress.connect(_on_generation_progress)
	cave_generator.generation_complete.connect(_on_generation_complete)
	
	print("RhizomeCaveDemo: Cave generator initialized")
 
func generate_cave_async():
	"""Generate a new cave system asynchronously with default parameters"""
	if cave_generator == null:
		return
	
	print("RhizomeCaveDemo: Starting cave generation...")
	
	# Configure generation parameters with default values
	var cave_size = 30.0  # Default size
	var cave_params = {
		"size": Vector3(cave_size, cave_size * 0.4, cave_size),
		"chunk_size": Vector3i(12, 12, 12),
		"voxel_scale": 1.0,
		"seed": randi(),
		"initial_chambers": 3,
		"growth_iterations": 15
	}
	
	# Configure rhizomatic parameters with default values
	var rhizome_params = {
		"branch_probability": 0.6,
		"merge_distance": 6.0,
		"vertical_bias": 0.3,
		"chamber_probability": 0.25,
		"max_depth": 4
	}
	
	cave_generator.setup_parameters(cave_params)
	cave_generator.configure_rhizome_parameters(rhizome_params)
	
	# Start async generation
	await cave_generator.generate_cave_async()

# Keep the old function for backwards compatibility but make it call the async version
func generate_cave():
	"""Generate a new cave system with current parameters (legacy function)"""
	generate_cave_async()

func _on_generation_progress(percentage: float):
	"""Log progress during generation"""
	var status = ""
	if percentage <= 20:
		status = "Growing rhizomatic network..."
	elif percentage <= 40:
		status = "Creating voxel grid..."
	elif percentage <= 60:
		status = "Carving cave system..."
	elif percentage <= 80:
		status = "Adding organic variation..."
	elif percentage <= 95:
		status = "Generating meshes..."
	else:
		status = "Creating physics..."
	
	print("Cave Generation Progress: %.0f%% - %s" % [percentage, status])

func _on_generation_complete():
	"""Handle generation completion"""
	print("RhizomeCaveDemo: Generation complete!")
	
	# Log cave statistics
	update_cave_statistics()

func update_cave_statistics():
	"""Log cave statistics"""
	if cave_generator == null:
		return
	
	var info = cave_generator.get_cave_info()
	
	print("=== Cave Statistics ===")
	print("• Mesh Chunks: %d" % info.mesh_instances)
	print("• Collision Bodies: %d" % info.collision_bodies)
	print("• Total Vertices: %s" % format_number(info.total_vertices))
	print("• Total Triangles: %s" % format_number(info.total_triangles))
	print("• Voxel Chunks: %d" % info.voxel_chunks)
	print("• Growth Nodes: %d" % info.growth_nodes)
	print("• Chambers: %d" % info.chambers)
	
	# Calculate approximate memory usage
	var memory_mb = (info.total_vertices * 12 + info.total_triangles * 6) / (1024 * 1024)
	print("• Memory Est: %.1f MB" % memory_mb)

func format_number(num: int) -> String:
	"""Format large numbers with commas"""
	var str_num = str(num)
	var formatted = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_num[i] + formatted
		count += 1
	
	return formatted
 
