# SpaceColonizationMoldSpore.gd
# Implements 3D mold fungus spore growth using Space Colonization Algorithm
# Creates organic, branching fungal networks in 1x1 unit space

extends Node3D
class_name SpaceColonizationMoldSpore

# Core algorithm components
var auxin_sources: Array[Vector3] = []  # Target points for growth
var growth_nodes: Array[GrowthNode] = []  # Active growing points
var spore_branches: Array[SporeBranch] = []  # Connected branch segments
var mesh_instances: Array[MeshInstance3D] = []

# Algorithm parameters
@export var space_bounds: Vector3 = Vector3(1.0, 1.0, 1.0)  # 1x1x1 unit space
@export var influence_radius: float = 0.15  # How far auxins influence growth
@export var kill_distance: float = 0.05  # Distance to remove consumed auxins
@export var step_size: float = 0.02  # Growth step distance
@export var branch_angle_variance: float = 25.0  # Angular randomness in degrees
@export var num_auxin_sources: int = 200  # Number of target points
@export var max_iterations: int = 500  # Maximum growth iterations
@export var min_branch_length: float = 0.03  # Minimum branch segment length

# Spore-specific parameters
@export var spore_radius: float = 0.008  # Thickness of spore filaments
@export var sporulation_probability: float = 0.02  # Chance to create spore bodies
@export var spore_body_size: float = 0.02  # Size of spore reproductive bodies
@export var branching_probability: float = 0.3  # Chance to create new branches
@export var mycelium_density: float = 0.8  # How dense the fungal network becomes

# Visual parameters
@export var spore_color: Color = Color(0.8, 0.9, 0.7, 0.9)  # Pale fungal color
@export var spore_body_color: Color = Color(0.9, 0.8, 0.6, 1.0)  # Spore body color
@export var enable_glow: bool = true  # Add bioluminescent glow effect

# Generation state
var current_iteration: int = 0
var is_generating: bool = false
var rng: RandomNumberGenerator

# Node classes for the algorithm
class GrowthNode:
	var position: Vector3
	var direction: Vector3  # Growth direction
	var parent: GrowthNode
	var children: Array[GrowthNode] = []
	var age: int = 0
	var is_active: bool = true
	var branch_strength: float = 1.0
	var has_spore_body: bool = false
	
	func _init(pos: Vector3, dir: Vector3 = Vector3.ZERO, p: GrowthNode = null):
		position = pos
		direction = dir.normalized() if dir != Vector3.ZERO else Vector3.UP
		parent = p
		age = 0
		branch_strength = 1.0

class SporeBranch:
	var start_node: GrowthNode
	var end_node: GrowthNode
	var thickness: float
	var has_spores: bool = false
	var spore_positions: Array[Vector3] = []
	
	func _init(start: GrowthNode, end: GrowthNode, thick: float = 0.008):
		start_node = start
		end_node = end
		thickness = thick

signal generation_complete()
signal generation_progress(percentage: float)

func _ready():
	setup_random_generator()
	print("SpaceColonizationMoldSpore: Initialized for 1x1x1 unit space")

func setup_random_generator(seed_value: int = -1):
	# Initialize random number generator
	rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func generate_mold_spore_network(seed_value: int = -1) -> Array[MeshInstance3D]:
	# Generate complete 3D mold spore network using Space Colonization Algorithm
	print("SpaceColonizationMoldSpore: Starting generation...")
	
	setup_random_generator(seed_value)
	clear_previous_generation()
	
	# Initialize the algorithm
	initialize_auxin_sources()
	initialize_growth_nodes()
	
	# Run the space colonization algorithm
	is_generating = true
	current_iteration = 0
	
	while is_generating and current_iteration < max_iterations:
		space_colonization_iteration()
		current_iteration += 1
		
		# Emit progress
		var progress = float(current_iteration) / float(max_iterations)
		generation_progress.emit(progress)
		
		# Check if we should continue
		if auxin_sources.is_empty() or get_active_growth_nodes().is_empty():
			break
	
	# Generate the final 3D mesh
	create_spore_mesh()
	add_spore_bodies()
	
	is_generating = false
	generation_complete.emit()
	
	print("SpaceColonizationMoldSpore: Generation complete after %d iterations" % current_iteration)
	return mesh_instances

func clear_previous_generation():
	# Clear any existing generated content
	for mesh_instance in mesh_instances:
		if mesh_instance and is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
	
	mesh_instances.clear()
	auxin_sources.clear()
	growth_nodes.clear()
	spore_branches.clear()

func initialize_auxin_sources():
	# Create auxin sources distributed throughout the 1x1x1 space
	auxin_sources.clear()
	
	# Create random distribution with some clustering for realistic growth
	for i in range(num_auxin_sources):
		var pos: Vector3
		
		if i < num_auxin_sources * 0.3:
			# 30% clustered sources for realistic nutrient distribution
			var cluster_center = Vector3(
				rng.randf_range(0.2, 0.8),
				rng.randf_range(0.2, 0.8),
				rng.randf_range(0.2, 0.8)
			)
			pos = cluster_center + Vector3(
				rng.randf_range(-0.15, 0.15),
				rng.randf_range(-0.15, 0.15),
				rng.randf_range(-0.15, 0.15)
			)
		else:
			# 70% random distribution
			pos = Vector3(
				rng.randf_range(0.05, 0.95),
				rng.randf_range(0.05, 0.95),
				rng.randf_range(0.05, 0.95)
			)
		
		# Ensure within bounds
		pos = pos.clamp(Vector3.ZERO, space_bounds)
		auxin_sources.append(pos)
	
	print("SpaceColonizationMoldSpore: Created %d auxin sources" % auxin_sources.size())

func initialize_growth_nodes():
	# Create initial growth nodes (spore starting points)
	growth_nodes.clear()
	
	# Start with 2-4 initial spores at the bottom of the space
	var num_initial_spores = rng.randi_range(2, 4)
	
	for i in range(num_initial_spores):
		var start_pos = Vector3(
			rng.randf_range(0.3, 0.7),
			0.05,  # Start near bottom
			rng.randf_range(0.3, 0.7)
		)
		
		var initial_direction = Vector3(
			rng.randf_range(-0.3, 0.3),
			1.0,  # Grow upward initially
			rng.randf_range(-0.3, 0.3)
		).normalized()
		
		var growth_node = GrowthNode.new(start_pos, initial_direction)
		growth_nodes.append(growth_node)
	
	print("SpaceColonizationMoldSpore: Created %d initial growth nodes" % growth_nodes.size())

func space_colonization_iteration():
	# Perform one iteration of the space colonization algorithm
	var active_nodes = get_active_growth_nodes()
	if active_nodes.is_empty():
		is_generating = false
		return
	
	# Step 1: Find auxin sources that influence each growth node
	var node_influences: Dictionary = {}
	
	for node in active_nodes:
		var influenced_auxins: Array[Vector3] = []
		
		for auxin in auxin_sources:
			var distance = node.position.distance_to(auxin)
			if distance <= influence_radius:
				influenced_auxins.append(auxin)
		
		if not influenced_auxins.is_empty():
			node_influences[node] = influenced_auxins
	
	# Step 2: Calculate growth directions and create new nodes
	var new_nodes: Array[GrowthNode] = []
	var auxins_to_remove: Array[Vector3] = []
	
	for node in node_influences.keys():
		var influenced_auxins = node_influences[node] as Array[Vector3]
		
		# Calculate average direction to influenced auxins
		var growth_direction = Vector3.ZERO
		for auxin in influenced_auxins:
			growth_direction += (auxin - node.position).normalized()
		
		if growth_direction != Vector3.ZERO:
			growth_direction = growth_direction.normalized()
			
			# Add some randomness for organic growth
			growth_direction = add_growth_randomness(growth_direction)
			
			# Create new growth node
			var new_position = node.position + growth_direction * step_size
			
			# Ensure within bounds
			if is_within_bounds(new_position):
				var new_node = GrowthNode.new(new_position, growth_direction, node)
				new_node.branch_strength = node.branch_strength * 0.95  # Gradual weakening
				new_nodes.append(new_node)
				
				# Create branch connection
				var branch = SporeBranch.new(node, new_node, spore_radius * node.branch_strength)
				spore_branches.append(branch)
				
				# Add to parent's children
				node.children.append(new_node)
				
				# Check for sporulation
				if rng.randf() < sporulation_probability:
					new_node.has_spore_body = true
					branch.has_spores = true
					add_spore_positions_to_branch(branch)
		
		# Check for auxin consumption
		for auxin in influenced_auxins:
			if node.position.distance_to(auxin) <= kill_distance:
				if auxin not in auxins_to_remove:
					auxins_to_remove.append(auxin)
	
	# Step 3: Add new nodes and remove consumed auxins
	for node in new_nodes:
		growth_nodes.append(node)
	
	for auxin in auxins_to_remove:
		auxin_sources.erase(auxin)
	
	# Step 4: Handle branching
	handle_branching(new_nodes)
	
	# Step 5: Age nodes and deactivate old ones
	age_growth_nodes()

func add_growth_randomness(direction: Vector3) -> Vector3:
	# Add organic randomness to growth direction
	var random_angle = deg_to_rad(rng.randf_range(-branch_angle_variance, branch_angle_variance))
	var random_axis = Vector3(
		rng.randf_range(-1.0, 1.0),
		rng.randf_range(-1.0, 1.0),
		rng.randf_range(-1.0, 1.0)
	).normalized()
	
	# Rotate the direction around the random axis
	var rotated_direction = direction.rotated(random_axis, random_angle)
	return rotated_direction.normalized()

func handle_branching(new_nodes: Array[GrowthNode]):
	# Create additional branches for more complex growth patterns
	var additional_branches: Array[GrowthNode] = []
	
	for node in new_nodes:
		if rng.randf() < branching_probability and node.branch_strength > 0.3:
			# Create a secondary branch at an angle
			var branch_direction = node.direction.rotated(
				Vector3.UP, 
				deg_to_rad(rng.randf_range(30.0, 90.0))
			)
			branch_direction = add_growth_randomness(branch_direction)
			
			var branch_position = node.position + branch_direction * step_size * 0.7
			
			if is_within_bounds(branch_position):
				var branch_node = GrowthNode.new(branch_position, branch_direction, node.parent)
				branch_node.branch_strength = node.branch_strength * 0.7
				additional_branches.append(branch_node)
				
				# Create branch connection
				var branch = SporeBranch.new(node, branch_node, spore_radius * branch_node.branch_strength)
				spore_branches.append(branch)
	
	# Add additional branches to growth nodes
	for branch_node in additional_branches:
		growth_nodes.append(branch_node)

func add_spore_positions_to_branch(branch: SporeBranch):
	# Add spore positions along a fertile branch
	var num_spores = rng.randi_range(2, 6)
	
	for i in range(num_spores):
		var t = rng.randf()  # Random position along branch
		var spore_pos = branch.start_node.position.lerp(branch.end_node.position, t)
		
		# Add slight random offset
		spore_pos += Vector3(
			rng.randf_range(-0.01, 0.01),
			rng.randf_range(-0.01, 0.01),
			rng.randf_range(-0.01, 0.01)
		)
		
		branch.spore_positions.append(spore_pos)

func get_active_growth_nodes() -> Array[GrowthNode]:
	# Get all currently active growth nodes
	var active_nodes: Array[GrowthNode] = []
	
	for node in growth_nodes:
		if node.is_active and node.branch_strength > 0.1:
			active_nodes.append(node)
	
	return active_nodes

func age_growth_nodes():
	# Age all growth nodes and deactivate old ones
	for node in growth_nodes:
		node.age += 1
		
		# Deactivate nodes that are too old or weak
		if node.age > 50 or node.branch_strength < 0.1:
			node.is_active = false

func is_within_bounds(position: Vector3) -> bool:
	# Check if position is within the 1x1x1 space bounds
	return (position.x >= 0.0 and position.x <= space_bounds.x and
			position.y >= 0.0 and position.y <= space_bounds.y and
			position.z >= 0.0 and position.z <= space_bounds.z)

func create_spore_mesh():
	# Generate the final 3D mesh for the spore network
	if spore_branches.is_empty():
		print("SpaceColonizationMoldSpore: No branches to mesh")
		return
	
	# Create main mycelium network mesh
	var mycelium_mesh = create_mycelium_mesh()
	if mycelium_mesh != null:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mycelium_mesh
		mesh_instance.name = "MoldMyceliumNetwork"
		
		# Apply spore material
		var material = create_spore_material()
		mesh_instance.material_override = material
		
		add_child(mesh_instance)
		mesh_instances.append(mesh_instance)
		
		print("SpaceColonizationMoldSpore: Created mycelium mesh with %d branches" % spore_branches.size())

func create_mycelium_mesh() -> ArrayMesh:
	# Create the main mycelium (fungal thread) mesh
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var indices: PackedInt32Array = []
	
	var vertex_count = 0
	
	for branch in spore_branches:
		if branch.start_node == null or branch.end_node == null:
			continue
		
		# Create cylindrical tube for each branch
		var branch_vertices = create_branch_cylinder(
			branch.start_node.position,
			branch.end_node.position,
			branch.thickness
		)
		
		# Add vertices and create triangles
		var start_index = vertex_count
		
		for vertex_data in branch_vertices:
			vertices.append(vertex_data.position)
			normals.append(vertex_data.normal)
			uvs.append(vertex_data.uv)
		
		# Create indices for cylinder (simplified for brevity)
		var segments = 8  # 8-sided cylinder
		for i in range(segments):
			var next_i = (i + 1) % segments
			
			# Two triangles per segment
			# Triangle 1
			indices.append(start_index + i)
			indices.append(start_index + next_i)
			indices.append(start_index + i + segments)
			
			# Triangle 2
			indices.append(start_index + next_i)
			indices.append(start_index + next_i + segments)
			indices.append(start_index + i + segments)
		
		vertex_count += branch_vertices.size()
	
	if vertices.is_empty():
		return null
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func create_branch_cylinder(start_pos: Vector3, end_pos: Vector3, radius: float) -> Array:
	# Create cylindrical geometry for a single branch
	var branch_data = []
	var segments = 8
	var direction = (end_pos - start_pos).normalized()
	var length = start_pos.distance_to(end_pos)
	
	# Create a coordinate system for the cylinder
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.9:
		up = Vector3.RIGHT
	
	var right = direction.cross(up).normalized()
	up = right.cross(direction).normalized()
	
	# Create vertices around the cylinder
	for i in range(segments * 2):  # Start and end rings
		var ring_index = i / segments
		var segment_index = i % segments
		
		var angle = (float(segment_index) / float(segments)) * TAU
		var ring_pos = start_pos if ring_index == 0 else end_pos
		
		var local_pos = Vector3(
			cos(angle) * radius,
			sin(angle) * radius,
			0.0
		)
		
		# Transform to world space
		var world_pos = ring_pos + right * local_pos.x + up * local_pos.y
		var normal = (right * local_pos.x + up * local_pos.y).normalized()
		var uv = Vector2(float(segment_index) / float(segments), float(ring_index))
		
		branch_data.append({
			"position": world_pos,
			"normal": normal,
			"uv": uv
		})
	
	return branch_data

func add_spore_bodies():
	# Add spore reproductive bodies to the network
	for branch in spore_branches:
		if not branch.has_spores:
			continue
		
		for spore_pos in branch.spore_positions:
			var spore_body = MeshInstance3D.new()
			spore_body.mesh = SphereMesh.new()
			spore_body.mesh.radius = spore_body_size
			spore_body.mesh.height = spore_body_size * 2
			spore_body.position = spore_pos
			spore_body.name = "SporeBody"
			
			# Apply spore body material
			var spore_material = create_spore_body_material()
			spore_body.material_override = spore_material
			
			add_child(spore_body)
			mesh_instances.append(spore_body)
	
	print("SpaceColonizationMoldSpore: Added spore bodies to fertile branches")

func create_spore_material() -> StandardMaterial3D:
	# Create material for the main mycelium network
	var material = StandardMaterial3D.new()
	material.albedo_color = spore_color
	material.roughness = 0.8
	material.metallic = 0.1
	
	if enable_glow:
		material.emission_enabled = true
		material.emission = spore_color * 0.3
		material.emission_energy = 0.5
	
	# Add translucency for organic feel
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	return material

func create_spore_body_material() -> StandardMaterial3D:
	# Create material for spore reproductive bodies
	var material = StandardMaterial3D.new()
	material.albedo_color = spore_body_color
	material.roughness = 0.6
	material.metallic = 0.2
	
	if enable_glow:
		material.emission_enabled = true
		material.emission = spore_body_color * 0.4
		material.emission_energy = 0.7
	
	return material

# Public API functions
func set_parameters(params: Dictionary):
	# Configure generation parameters
	if params.has("influence_radius"):
		influence_radius = params.influence_radius
	if params.has("kill_distance"):
		kill_distance = params.kill_distance
	if params.has("step_size"):
		step_size = params.step_size
	if params.has("num_auxin_sources"):
		num_auxin_sources = params.num_auxin_sources
	if params.has("sporulation_probability"):
		sporulation_probability = params.sporulation_probability
	if params.has("branching_probability"):
		branching_probability = params.branching_probability

func get_generation_statistics() -> Dictionary:
	# Get statistics about the generated spore network
	var total_spore_bodies = 0
	for branch in spore_branches:
		total_spore_bodies += branch.spore_positions.size()
	
	return {
		"total_branches": spore_branches.size(),
		"total_growth_nodes": growth_nodes.size(),
		"total_spore_bodies": total_spore_bodies,
		"remaining_auxin_sources": auxin_sources.size(),
		"iterations_completed": current_iteration,
		"active_growth_nodes": get_active_growth_nodes().size()
	}

func reset_generation():
	# Reset the generator for a new generation
	clear_previous_generation()
	current_iteration = 0
	is_generating = false
	print("SpaceColonizationMoldSpore: Generator reset")
