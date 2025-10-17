extends Node3D

@export_group("Model Synthesis Parameters")
@export var exemplar_size: Vector3i = Vector3i(8, 8, 8)  # Size of input exemplar
@export var output_size: Vector3i = Vector3i(32, 16, 32)  # Size of output synthesis
@export var overlap_size: int = 3  # Overlap constraint size (N in paper)
@export var search_neighborhood: int = 2  # Search radius for candidate selection

@export_group("Synthesis Control")
@export var generation_speed: float = 0.001  # Very fast for real-time
@export var auto_generate: bool = true
@export var use_coherence_search: bool = true  # Use coherence for speedup
@export var debug_mode: bool = false

@export_group("Cave Exemplar")
@export var create_exemplar: bool = true
@export var exemplar_cave_density: float = 0.3
@export var exemplar_tunnel_probability: float = 0.4

# Voxel types for cave generation
enum VoxelType {
	ROCK = 0,
	AIR = 1,
	WATER = 2,
	ENTRANCE = 3
}

# Core Model Synthesis classes
class ModelVoxel:
	var type: VoxelType
	var position: Vector3i
	var synthesized: bool = false
	
	func _init(voxel_type: VoxelType, pos: Vector3i = Vector3i.ZERO):
		type = voxel_type
		position = pos

class Neighborhood:
	var voxels: Array[Voxel] = []
	var center_position: Vector3i
	var size: int
	
	func _init(center: Vector3i, neighborhood_size: int):
		center_position = center
		size = neighborhood_size
	
	func add_voxel(voxel: Voxel):
		voxels.append(voxel)
	
	func get_pattern_hash() -> String:
		# Create unique hash for this neighborhood pattern
		var pattern = []
		for voxel in voxels:
			pattern.append(str(voxel.type))
		return "".join(pattern)
	
	func matches(other: Neighborhood, overlap_constraint: int) -> bool:
		# Check if neighborhoods match within overlap constraint
		if voxels.size() != other.voxels.size():
			return false
		
		var mismatch_count = 0
		for i in range(voxels.size()):
			if voxels[i].type != other.voxels[i].type:
				mismatch_count += 1
				if mismatch_count > overlap_constraint:
					return false
		return true

class ModelSynthesis:
	var exemplar: Array  # 3D array of VoxelType
	var output: Array    # 3D array of Voxel
	var exemplar_size: Vector3i
	var output_size: Vector3i
	var overlap_size: int
	var search_radius: int
	var use_coherence: bool  # Store coherence search setting
	
	# Coherence optimization (from paper)
	var coherence_map: Dictionary = {}  # Maps output positions to exemplar positions
	var neighborhood_cache: Dictionary = {}  # Cache for neighborhood patterns
	
	func _init(ex_size: Vector3i, out_size: Vector3i, overlap: int, search: int, coherence: bool = true):
		exemplar_size = ex_size
		output_size = out_size
		overlap_size = overlap
		search_radius = search
		use_coherence = coherence
		_initialize_arrays()
	
	func _initialize_arrays():
		# Initialize 3D arrays
		exemplar = []
		output = []
		
		for x in range(exemplar_size.x):
			exemplar.append([])
			for y in range(exemplar_size.y):
				exemplar[x].append([])
				for z in range(exemplar_size.z):
					exemplar[x][y].append(VoxelType.ROCK)
		
		for x in range(output_size.x):
			output.append([])
			for y in range(output_size.y):
				output[x].append([])
				for z in range(output_size.z):
					output[x][y].append(ModelVoxel.new(VoxelType.ROCK, Vector3i(x, y, z)))
	
	func set_exemplar_voxel(pos: Vector3i, type: VoxelType):
		if _is_valid_exemplar_pos(pos):
			exemplar[pos.x][pos.y][pos.z] = type
	
	func get_exemplar_voxel(pos: Vector3i) -> VoxelType:
		if _is_valid_exemplar_pos(pos):
			return exemplar[pos.x][pos.y][pos.z]
		return VoxelType.ROCK
	
	func set_output_voxel(pos: Vector3i, type: VoxelType):
		if _is_valid_output_pos(pos):
			output[pos.x][pos.y][pos.z].type = type
			output[pos.x][pos.y][pos.z].synthesized = true
	
	func get_output_voxel(pos: Vector3i) -> Voxel:
		if _is_valid_output_pos(pos):
			return output[pos.x][pos.y][pos.z]
		return null
	
	func get_neighborhood(grid: Array, pos: Vector3i, size: int, is_exemplar: bool = true) -> Neighborhood:
		var neighborhood = Neighborhood.new(pos, size)
		var bounds = exemplar_size if is_exemplar else output_size
		
		var half_size = size / 2
		for dx in range(-half_size, half_size + 1):
			for dy in range(-half_size, half_size + 1):
				for dz in range(-half_size, half_size + 1):
					var sample_pos = pos + Vector3i(dx, dy, dz)
					
					if is_exemplar:
						if _is_valid_exemplar_pos(sample_pos):
							var voxel = ModelVoxel.new(get_exemplar_voxel(sample_pos), sample_pos)
							neighborhood.add_voxel(voxel)
						else:
							# Handle boundary with wrap-around or default
							var wrapped_pos = Vector3i(
								sample_pos.x % exemplar_size.x,
								sample_pos.y % exemplar_size.y,
								sample_pos.z % exemplar_size.z
							)
							if wrapped_pos.x < 0: wrapped_pos.x += exemplar_size.x
							if wrapped_pos.y < 0: wrapped_pos.y += exemplar_size.y
							if wrapped_pos.z < 0: wrapped_pos.z += exemplar_size.z
							
							var voxel = ModelVoxel.new(get_exemplar_voxel(wrapped_pos), wrapped_pos)
							neighborhood.add_voxel(voxel)
					else:
						if _is_valid_output_pos(sample_pos):
							neighborhood.add_voxel(get_output_voxel(sample_pos))
						else:
							# Default voxel for out-of-bounds
							var default_voxel = ModelVoxel.new(VoxelType.ROCK, sample_pos)
							neighborhood.add_voxel(default_voxel)
		
		return neighborhood
	
	func find_best_matches(target_neighborhood: Neighborhood, use_coherence: bool = true) -> Array[Vector3i]:
		var candidates: Array[Vector3i] = []
		var best_error = INF
		
		# Coherence search - check last successful position first
		if use_coherence and coherence_map.has(target_neighborhood.center_position):
			var coherent_pos = coherence_map[target_neighborhood.center_position]
			var coherent_neighborhood = get_neighborhood(exemplar, coherent_pos, overlap_size, true)
			
			var error = _calculate_neighborhood_error(target_neighborhood, coherent_neighborhood)
			if error <= best_error:
				best_error = error
				candidates = [coherent_pos]
		
		# Search exemplar for matching neighborhoods
		var search_positions = _get_search_positions(use_coherence)
		
		for exemplar_pos in search_positions:
			var exemplar_neighborhood = get_neighborhood(exemplar, exemplar_pos, overlap_size, true)
			var error = _calculate_neighborhood_error(target_neighborhood, exemplar_neighborhood)
			
			if error < best_error:
				best_error = error
				candidates = [exemplar_pos]
			elif error == best_error:
				candidates.append(exemplar_pos)
		
		return candidates
	
	func _get_search_positions(limited_search: bool = false) -> Array[Vector3i]:
		var positions: Array[Vector3i] = []
		
		if limited_search and search_radius > 0:
			# Limited search around coherence position
			var center = coherence_map.get(Vector3i.ZERO, Vector3i(exemplar_size.x/2, exemplar_size.y/2, exemplar_size.z/2))
			for x in range(max(0, center.x - search_radius), min(exemplar_size.x, center.x + search_radius + 1)):
				for y in range(max(0, center.y - search_radius), min(exemplar_size.y, center.y + search_radius + 1)):
					for z in range(max(0, center.z - search_radius), min(exemplar_size.z, center.z + search_radius + 1)):
						positions.append(Vector3i(x, y, z))
		else:
			# Full exemplar search
			for x in range(exemplar_size.x):
				for y in range(exemplar_size.y):
					for z in range(exemplar_size.z):
						positions.append(Vector3i(x, y, z))
		
		return positions
	
	func _calculate_neighborhood_error(target: Neighborhood, candidate: Neighborhood) -> float:
		if target.voxels.size() != candidate.voxels.size():
			return INF
		
		var error = 0.0
		var valid_comparisons = 0
		
		for i in range(target.voxels.size()):
			var target_voxel = target.voxels[i]
			var candidate_voxel = candidate.voxels[i]
			
			# Only compare synthesized voxels in target
			if target_voxel.synthesized:
				if target_voxel.type != candidate_voxel.type:
					error += 1.0
				valid_comparisons += 1
		
		return error / max(1, valid_comparisons) if valid_comparisons > 0 else 0.0
	
	func synthesize_voxel(pos: Vector3i) -> VoxelType:
		# Get neighborhood around position (including already synthesized voxels)
		var target_neighborhood = get_neighborhood(output, pos, overlap_size, false)
		
		# Find best matching neighborhoods in exemplar
		var candidates = find_best_matches(target_neighborhood, use_coherence)
		
		if candidates.is_empty():
			return VoxelType.ROCK  # Default fallback
		
		# Randomly select from best candidates
		var selected_pos = candidates[randi() % candidates.size()]
		
		# Update coherence map for future speedup
		coherence_map[pos] = selected_pos
		
		# Return the voxel type at the selected position
		return get_exemplar_voxel(selected_pos)
	
	func _is_valid_exemplar_pos(pos: Vector3i) -> bool:
		return pos.x >= 0 and pos.x < exemplar_size.x and \
			   pos.y >= 0 and pos.y < exemplar_size.y and \
			   pos.z >= 0 and pos.z < exemplar_size.z
	
	func _is_valid_output_pos(pos: Vector3i) -> bool:
		return pos.x >= 0 and pos.x < output_size.x and \
			   pos.y >= 0 and pos.y < output_size.y and \
			   pos.z >= 0 and pos.z < output_size.z

# Main synthesis controller
var model_synthesis: ModelSynthesis
var mesh_instances: Array[MeshInstance3D] = []
var materials: Dictionary = {}
var generation_timer: float = 0.0
var is_generating: bool = false
var current_synthesis_pos: Vector3i = Vector3i.ZERO
var synthesis_order: Array[Vector3i] = []

func _ready():
	setup_materials()
	initialize_model_synthesis()
	if auto_generate:
		start_synthesis()

func setup_materials():
	# Rock material
	var rock_material = StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.4, 0.3, 0.2)
	rock_material.roughness = 0.9
	materials[VoxelType.ROCK] = rock_material
	
	# Air material (invisible)
	materials[VoxelType.AIR] = null
	
	# Water material
	var water_material = StandardMaterial3D.new()
	water_material.albedo_color = Color(0.2, 0.4, 0.8, 0.6)
	water_material.roughness = 0.1
	water_material.flags_transparent = true
	materials[VoxelType.WATER] = water_material
	
	# Entrance material
	var entrance_material = StandardMaterial3D.new()
	entrance_material.albedo_color = Color(0.8, 0.6, 0.3)
	entrance_material.roughness = 0.7
	materials[VoxelType.ENTRANCE] = entrance_material

func initialize_model_synthesis():
	model_synthesis = ModelSynthesis.new(exemplar_size, output_size, overlap_size, search_neighborhood, use_coherence_search)
	
	if create_exemplar:
		create_cave_exemplar()
	
	create_output_visualization()
	setup_synthesis_order()

func create_cave_exemplar():
	# Create a small cave exemplar with interesting patterns
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.3
	
	print("Creating cave exemplar...")
	
	for x in range(exemplar_size.x):
		for y in range(exemplar_size.y):
			for z in range(exemplar_size.z):
				var pos = Vector3i(x, y, z)
				var world_pos = Vector3(x, y, z)
				
				var noise_value = noise.get_noise_3d(world_pos.x, world_pos.y, world_pos.z)
				
				# Create cave structure
				if y == 0:
					# Floor is mostly rock
					model_synthesis.set_exemplar_voxel(pos, VoxelType.ROCK)
				elif y == exemplar_size.y - 1:
					# Ceiling is mostly rock  
					model_synthesis.set_exemplar_voxel(pos, VoxelType.ROCK)
				elif noise_value > exemplar_cave_density:
					# Hollow areas
					if randf() < exemplar_tunnel_probability and y > 1:
						model_synthesis.set_exemplar_voxel(pos, VoxelType.AIR)
					else:
						model_synthesis.set_exemplar_voxel(pos, VoxelType.ROCK)
				else:
					model_synthesis.set_exemplar_voxel(pos, VoxelType.ROCK)
				
				# Add some water features
				if y == 1 and noise_value > 0.6 and randf() < 0.1:
					model_synthesis.set_exemplar_voxel(pos, VoxelType.WATER)
				
				# Add entrance possibilities at edges
				if (x == 0 or x == exemplar_size.x-1 or z == 0 or z == exemplar_size.z-1) and y == 1:
					if randf() < 0.3:
						model_synthesis.set_exemplar_voxel(pos, VoxelType.ENTRANCE)

func create_output_visualization():
	# Clear existing visualization
	for mesh_instance in mesh_instances:
		if mesh_instance:
			mesh_instance.queue_free()
	mesh_instances.clear()
	
	# Create mesh instances for output grid
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3.ONE * 0.9  # Slightly smaller for gaps
	
	for x in range(output_size.x):
		for y in range(output_size.y):
			for z in range(output_size.z):
				var mesh_instance = MeshInstance3D.new()
				mesh_instance.mesh = box_mesh
				mesh_instance.position = Vector3(x, y, z)
				mesh_instance.material_override = materials[VoxelType.ROCK]
				add_child(mesh_instance)
				mesh_instances.append(mesh_instance)

func setup_synthesis_order():
	# Create scanline order for synthesis (could be randomized)
	synthesis_order.clear()
	
	for y in range(output_size.y):
		for z in range(output_size.z):
			for x in range(output_size.x):
				synthesis_order.append(Vector3i(x, y, z))
	
	# Optional: shuffle for more interesting generation
	synthesis_order.shuffle()
	
	current_synthesis_pos = Vector3i.ZERO
	print("Setup synthesis order for ", synthesis_order.size(), " voxels")

func start_synthesis():
	is_generating = true
	generation_timer = 0.0
	current_synthesis_pos = Vector3i.ZERO

func _process(delta):
	if is_generating and synthesis_order.size() > 0:
		generation_timer += delta
		if generation_timer >= generation_speed:
			generation_timer = 0.0
			synthesis_step()

func synthesis_step():
	if current_synthesis_pos.x >= synthesis_order.size():
		is_generating = false
		print("Model synthesis complete!")
		return
	
	# Get next position to synthesize
	var pos = synthesis_order[current_synthesis_pos.x]
	
	# Synthesize voxel using model synthesis
	var synthesized_type = model_synthesis.synthesize_voxel(pos)
	model_synthesis.set_output_voxel(pos, synthesized_type)
	
	# Update visualization
	update_voxel_visual(pos, synthesized_type)
	
	current_synthesis_pos.x += 1
	
	if debug_mode and current_synthesis_pos.x % 100 == 0:
		print("Synthesized ", current_synthesis_pos.x, "/", synthesis_order.size(), " voxels")

func update_voxel_visual(pos: Vector3i, voxel_type: VoxelType):
	var index = pos.x + pos.y * output_size.x + pos.z * output_size.x * output_size.y
	
	if index >= 0 and index < mesh_instances.size():
		var mesh_instance = mesh_instances[index]
		
		if voxel_type == VoxelType.AIR:
			mesh_instance.visible = false
		else:
			mesh_instance.visible = true
			mesh_instance.material_override = materials[voxel_type]

func restart_synthesis():
	current_synthesis_pos = Vector3i.ZERO
	setup_synthesis_order()
	
	# Reset all voxels to unsynthesized
	for x in range(output_size.x):
		for y in range(output_size.y):
			for z in range(output_size.z):
				var voxel = model_synthesis.get_output_voxel(Vector3i(x, y, z))
				if voxel:
					voxel.synthesized = false
					voxel.type = VoxelType.ROCK
	
	# Reset visualization
	create_output_visualization()
	
	if auto_generate:
		start_synthesis()

func toggle_synthesis():
	is_generating = not is_generating

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space
		toggle_synthesis()
	elif event.is_action_pressed("ui_cancel"):  # Escape
		restart_synthesis()
	elif event.is_action_pressed("ui_select"):  # Enter
		if not is_generating:
			synthesis_step()
