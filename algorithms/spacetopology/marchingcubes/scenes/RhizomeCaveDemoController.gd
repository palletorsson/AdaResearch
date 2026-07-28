# RhizomeCaveDemoController.gd
# Simplified cave generation controller - no UI, camera, or VR controls
# Only generates caves automatically
#
# @identity
# essence: a cave system grown live by the rhizome generator — chambers connected without a trunk, any passage reachable from any other, marched into walkable rock at load
# desire: to let the player stand inside Deleuze and Guattari's figure instead of reading it; the network room needs a space whose topology is the argument
# critical_parameter: the connectivity of the generated graph — no chamber is root, no passage is main; delete any tunnel and the rest still connects, which is the rhizome's whole claim
# triggers: _ready() defers generate_cave_async so the marching-cubes pass builds the cave without blocking entry; progress and completion arrive by signal
# emerges: navigation without hierarchy — you cannot ask which way is forward, only which opening is next, and orientation becomes relational rather than rooted
# needs: RhizomeCaveGenerator [algorithms/spacetopology/marchingcubes]; async generation [the cave must not gate the map load]; the surrounding 3t labels stating the principles the space enacts
# relationships: the teaching centre of Rhizome_Network — rhizome_grower beside it shows the same figure growing at hand scale while this one is inhabited at body scale
# truth: a rhizome cannot be toured, only entered somewhere. Any point connects to any other, so the map of this cave and the cave itself never agree — and the disagreement is the lesson.

extends Node3D

# Cave generator
@onready var cave_generator_node = $CaveGenerator
var cave_generator: RhizomeCaveGenerator

func _ready() -> void:
	setup_cave_generator()
	
	# Generate initial cave asynchronously to prevent blocking on startup
	call_deferred("generate_cave_async")

# UI setup removed - no UI needed for cave generation only

func setup_cave_generator() -> void:
	"""Initialize the cave generator"""
	cave_generator = RhizomeCaveGenerator.new()
	cave_generator.name = "RhizomeCaveGenerator"
	cave_generator_node.add_child(cave_generator)
	
	# Connect signals
	cave_generator.generation_progress.connect(_on_generation_progress)
	cave_generator.generation_complete.connect(_on_generation_complete)
	
	print("RhizomeCaveDemo: Cave generator initialized")
 
func generate_cave_async() -> void:
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
func generate_cave() -> void:
	"""Generate a new cave system with current parameters (legacy function)"""
	generate_cave_async()

func _on_generation_progress(percentage: float) -> void:
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

func _on_generation_complete() -> void:
	"""Handle generation completion"""
	print("RhizomeCaveDemo: Generation complete!")
	
	# Log cave statistics
	update_cave_statistics()

func update_cave_statistics() -> void:
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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
