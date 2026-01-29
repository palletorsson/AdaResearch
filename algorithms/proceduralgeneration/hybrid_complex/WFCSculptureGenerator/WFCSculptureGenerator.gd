@tool
extends Node3D
class_name WFCSculptureGenerator

# Sculpture generation parameters
@export var sculpture_size: Vector3i = Vector3i(20, 25, 20)
@export var voxel_size: float = 0.5
@export var generate_sculpture: bool = false : set = _generate_sculpture
@export var clear_sculpture: bool = false : set = _clear_sculpture
@export var hollow_intensity: float = 0.4  # How hollow the sculpture should be
@export var surface_complexity: float = 0.6  # Surface detail variation
@export var organic_flow: float = 0.7  # How organic vs geometric
@export var sculpture_seed: int = 0

# Sculpture type selection
enum SculptureType {
	ABSTRACT_ORGANIC,    # Flowing, organic abstract form
	GEOMETRIC_CRYSTAL,   # Sharp, crystalline geometric structure
	ARCHITECTURAL,       # Building-like architectural form
	BIOLOGICAL,          # Organic, life-like structure
	MINERAL_FORMATION,   # Natural mineral/rock formation
	FLUID_DYNAMIC,       # Fluid, water-like flowing form
	FIBROUS_NETWORK,     # Network of connected fibers
	SPIRAL_TORUS,        # Spiral or torus-based form
	FRACTAL_TREE,        # Tree-like branching structure
	SPHERE_CLUSTER       # Cluster of interconnected spheres
}

@export var sculpture_type: SculptureType = SculptureType.ABSTRACT_ORGANIC

# Material zones for differentiation
enum MaterialZone {
	VOID,           # Empty space (hollow areas)
	CORE_SOLID,     # Dense inner material
	SURFACE_SMOOTH, # Smooth outer surface
	SURFACE_ROUGH,  # Textured outer surface
	SURFACE_POROUS, # Porous outer surface
	TRANSITION,     # Gradient between materials
	SUPPORT,        # Structural supports
	DETAIL_FINE,    # Fine surface details
	DETAIL_DEEP     # Deep carved details
}

# Sculpture voxel types with connection rules
class SculptureVoxel:
	var type: MaterialZone
	var density: float  # 0.0 = void, 1.0 = solid
	var surface_normal: Vector3 = Vector3.ZERO
	var neighbors: Array[MaterialZone] = []  # What can be adjacent
	var weight: float = 1.0
	var mesh_variant: String = ""
	var color_zone: Color = Color.WHITE
	
	func _init(t: MaterialZone, d: float, compatible: Array[MaterialZone], w: float = 1.0):
		type = t
		density = d
		neighbors = compatible.duplicate()
		weight = w
		_setup_visual_properties()
	
	func _setup_visual_properties():
		match type:
			MaterialZone.VOID:
				color_zone = Color.TRANSPARENT
				mesh_variant = "void"
			MaterialZone.CORE_SOLID:
				color_zone = Color(0.3, 0.3, 0.4)
				mesh_variant = "solid"
			MaterialZone.SURFACE_SMOOTH:
				color_zone = Color(0.8, 0.7, 0.6)
				mesh_variant = "smooth"
			MaterialZone.SURFACE_ROUGH:
				color_zone = Color(0.7, 0.6, 0.5)
				mesh_variant = "rough"
			MaterialZone.SURFACE_POROUS:
				color_zone = Color(0.6, 0.5, 0.4)
				mesh_variant = "porous"
			MaterialZone.TRANSITION:
				color_zone = Color(0.5, 0.5, 0.6)
				mesh_variant = "transition"
			MaterialZone.SUPPORT:
				color_zone = Color(0.4, 0.4, 0.5)
				mesh_variant = "support"
			MaterialZone.DETAIL_FINE:
				color_zone = Color(0.9, 0.8, 0.7)
				mesh_variant = "detail_fine"
			MaterialZone.DETAIL_DEEP:
				color_zone = Color(0.5, 0.4, 0.3)
				mesh_variant = "detail_deep"

var voxel_types: Array[SculptureVoxel] = []
var sculpture_grid: Array = []  # 3D grid
var generation_complete: bool = false

class SculptureCell:
	var position: Vector3i
	var possible_voxels: Array[SculptureVoxel] = []
	var collapsed: bool = false
	var chosen_voxel: SculptureVoxel = null
	var distance_to_center: float = 0.0
	var distance_to_surface: float = 0.0
	
	func _init(pos: Vector3i, center: Vector3, bounds: Vector3):
		position = pos
		distance_to_center = (Vector3(pos) - center).length() / (bounds.length() * 0.5)
		_calculate_surface_distance(center, bounds)
	
	func _calculate_surface_distance(center: Vector3, bounds: Vector3):
		var normalized_pos = (Vector3(position) - center) / bounds
		var max_component = max(max(abs(normalized_pos.x), abs(normalized_pos.y)), abs(normalized_pos.z))
		distance_to_surface = 1.0 - max_component
	
	func get_entropy() -> int:
		return possible_voxels.size()
	
	func collapse() -> bool:
		if possible_voxels.is_empty():
			return false
		
		# Weight-based selection with spatial bias
		var total_weight = 0.0
		for voxel in possible_voxels:
			var spatial_weight = _calculate_spatial_weight(voxel)
			total_weight += voxel.weight * spatial_weight
		
		var random_val = randf() * total_weight
		var current_weight = 0.0
		
		for voxel in possible_voxels:
			var spatial_weight = _calculate_spatial_weight(voxel)
			current_weight += voxel.weight * spatial_weight
			if random_val <= current_weight:
				chosen_voxel = voxel
				collapsed = true
				return true
		
		return false
	
	func _calculate_spatial_weight(voxel: SculptureVoxel) -> float:
		match voxel.type:
			MaterialZone.VOID:
				return 1.0 + distance_to_center * 2.0  # More likely in center
			MaterialZone.CORE_SOLID:
				return 1.0 + (1.0 - distance_to_center) * 1.5  # More likely away from center
			MaterialZone.SURFACE_SMOOTH, MaterialZone.SURFACE_ROUGH, MaterialZone.SURFACE_POROUS:
				return 1.0 + distance_to_surface * 3.0  # More likely near surface
			MaterialZone.TRANSITION:
				return 1.0 + sin(distance_to_center * PI) * 1.5  # Gradient zones
			_:
				return 1.0

func _ready():
	setup_sculpture_voxels()

func _generate_sculpture(value):
	if value:
		create_hollow_sculpture()

func _clear_sculpture(value):
	if value:
		clear_generated_sculpture()

func setup_sculpture_voxels():
	voxel_types.clear()
	
	# Define voxel types with their adjacency rules
	voxel_types.append(SculptureVoxel.new(MaterialZone.VOID, 0.0, 
		[MaterialZone.VOID, MaterialZone.SURFACE_POROUS, MaterialZone.TRANSITION], hollow_intensity * 3.0))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.CORE_SOLID, 1.0,
		[MaterialZone.CORE_SOLID, MaterialZone.TRANSITION, MaterialZone.SUPPORT], 2.0))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.SURFACE_SMOOTH, 0.9,
		[MaterialZone.SURFACE_SMOOTH, MaterialZone.SURFACE_ROUGH, MaterialZone.TRANSITION, MaterialZone.DETAIL_FINE], 
		2.0 * surface_complexity))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.SURFACE_ROUGH, 0.9,
		[MaterialZone.SURFACE_ROUGH, MaterialZone.SURFACE_SMOOTH, MaterialZone.SURFACE_POROUS, MaterialZone.DETAIL_DEEP],
		1.5 * surface_complexity))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.SURFACE_POROUS, 0.7,
		[MaterialZone.SURFACE_POROUS, MaterialZone.VOID, MaterialZone.SURFACE_ROUGH, MaterialZone.TRANSITION],
		1.0 * surface_complexity))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.TRANSITION, 0.5,
		[MaterialZone.TRANSITION, MaterialZone.CORE_SOLID, MaterialZone.SURFACE_SMOOTH, MaterialZone.SURFACE_ROUGH, MaterialZone.VOID],
		1.5))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.SUPPORT, 0.8,
		[MaterialZone.SUPPORT, MaterialZone.CORE_SOLID, MaterialZone.TRANSITION],
		0.5))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.DETAIL_FINE, 0.95,
		[MaterialZone.DETAIL_FINE, MaterialZone.SURFACE_SMOOTH, MaterialZone.DETAIL_DEEP],
		0.8 * surface_complexity))
	
	voxel_types.append(SculptureVoxel.new(MaterialZone.DETAIL_DEEP, 0.3,
		[MaterialZone.DETAIL_DEEP, MaterialZone.SURFACE_ROUGH, MaterialZone.DETAIL_FINE, MaterialZone.VOID],
		0.6 * surface_complexity))

func create_hollow_sculpture():
	if sculpture_seed > 0:
		seed(sculpture_seed)
	
	clear_generated_sculpture()
	initialize_sculpture_grid()
	apply_sculptural_constraints()
	await run_sculpture_wfc()
	generate_sculpture_mesh()
	apply_post_processing()

func clear_generated_sculpture():
	for child in get_children():
		if child.has_meta("sculpture_generated"):
			child.queue_free()

func initialize_sculpture_grid():
	sculpture_grid.clear()
	sculpture_grid.resize(sculpture_size.x)
	
	var center = Vector3(sculpture_size) * 0.5
	
	for x in sculpture_size.x:
		sculpture_grid[x] = []
		sculpture_grid[x].resize(sculpture_size.y)
		for y in sculpture_size.y:
			sculpture_grid[x][y] = []
			sculpture_grid[x][y].resize(sculpture_size.z)
			for z in sculpture_size.z:
				var cell = SculptureCell.new(Vector3i(x, y, z), center, Vector3(sculpture_size))
				cell.possible_voxels = voxel_types.duplicate()
				sculpture_grid[x][y][z] = cell

func apply_sculptural_constraints():
	var center = Vector3(sculpture_size) * 0.5
	var max_radius = min(sculpture_size.x, min(sculpture_size.y, sculpture_size.z)) * 0.4
	
	# Apply constraints based on selected sculpture type
	match sculpture_type:
		SculptureType.ABSTRACT_ORGANIC:
			_apply_abstract_organic_constraints(center, max_radius)
		SculptureType.GEOMETRIC_CRYSTAL:
			_apply_geometric_crystal_constraints(center, max_radius)
		SculptureType.ARCHITECTURAL:
			_apply_architectural_constraints(center, max_radius)
		SculptureType.BIOLOGICAL:
			_apply_biological_constraints(center, max_radius)
		SculptureType.MINERAL_FORMATION:
			_apply_mineral_constraints(center, max_radius)
		SculptureType.FLUID_DYNAMIC:
			_apply_fluid_constraints(center, max_radius)
		SculptureType.FIBROUS_NETWORK:
			_apply_fibrous_constraints(center, max_radius)
		SculptureType.SPIRAL_TORUS:
			_apply_spiral_constraints(center, max_radius)
		SculptureType.FRACTAL_TREE:
			_apply_tree_constraints(center, max_radius)
		SculptureType.SPHERE_CLUSTER:
			_apply_sphere_cluster_constraints(center, max_radius)
		_:
			_apply_default_constraints(center, max_radius)

func _organic_noise(pos: Vector3) -> float:
	# Simple organic noise function for natural variation
	var n1 = sin(pos.x * 2.3 + pos.y * 1.7) * 0.5
	var n2 = cos(pos.z * 1.9 + pos.x * 2.1) * 0.3
	var n3 = sin(pos.y * 2.5 + pos.z * 1.8) * 0.2
	return (n1 + n2 + n3) * organic_flow

# Sculpture type constraint functions
func _apply_abstract_organic_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create organic boundary using noise
				var noise_offset = _organic_noise(pos * 0.1) * max_radius * 0.3
				var effective_radius = max_radius + noise_offset
				
				# Outside sculpture bounds - force void
				if distance_to_center > effective_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				
				# Near center - encourage hollowing
				elif distance_to_center < effective_radius * hollow_intensity:
					var hollow_types = voxel_types.filter(func(v): return v.type in [MaterialZone.VOID, MaterialZone.SURFACE_POROUS, MaterialZone.TRANSITION])
					if not hollow_types.is_empty():
						cell.possible_voxels = hollow_types
				
				# Surface area - encourage surface materials
				elif distance_to_center > effective_radius * 0.8:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_SMOOTH, MaterialZone.SURFACE_ROUGH, MaterialZone.SURFACE_POROUS])

func _apply_geometric_crystal_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create crystal facets using multiple planes
				var crystal_factor = _crystal_noise(pos * 0.2)
				var effective_radius = max_radius * (0.7 + crystal_factor * 0.3)
				
				if distance_to_center > effective_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				elif distance_to_center < effective_radius * 0.3:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.CORE_SOLID, MaterialZone.SUPPORT])
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_SMOOTH, MaterialZone.DETAIL_FINE])

func _apply_architectural_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create building-like structure with floors and walls
				var floor_height = int(pos.y / 4.0) * 4.0
				var is_floor = abs(pos.y - floor_height) < 0.5
				var is_wall = (int(pos.x) % 3 == 0) or (int(pos.z) % 3 == 0)
				
				if distance_to_center > max_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				elif is_floor:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_SMOOTH, MaterialZone.CORE_SOLID])
				elif is_wall:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SUPPORT, MaterialZone.CORE_SOLID])
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.VOID, MaterialZone.TRANSITION])

func _apply_biological_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create organic, life-like structure
				var organic_factor = _organic_noise(pos * 0.15)
				var effective_radius = max_radius * (0.6 + organic_factor * 0.4)
				
				if distance_to_center > effective_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				elif distance_to_center < effective_radius * 0.4:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.CORE_SOLID, MaterialZone.SUPPORT])
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_ROUGH, MaterialZone.SURFACE_POROUS, MaterialZone.DETAIL_FINE])

func _apply_mineral_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create mineral formation with layered structure
				var mineral_factor = _mineral_noise(pos * 0.1)
				var effective_radius = max_radius * (0.8 + mineral_factor * 0.2)
				
				if distance_to_center > effective_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				elif distance_to_center < effective_radius * 0.5:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.CORE_SOLID, MaterialZone.SUPPORT])
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_ROUGH, MaterialZone.DETAIL_DEEP])

func _apply_fluid_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create fluid, flowing form
				var fluid_factor = _fluid_noise(pos * 0.08)
				var effective_radius = max_radius * (0.5 + fluid_factor * 0.5)
				
				if distance_to_center > effective_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_SMOOTH, MaterialZone.TRANSITION, MaterialZone.DETAIL_FINE])

func _apply_fibrous_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create fibrous network structure
				var fiber_density = _fiber_noise(pos * 0.12)
				
				if distance_to_center > max_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				elif fiber_density > 0.6:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SUPPORT, MaterialZone.CORE_SOLID])
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.VOID, MaterialZone.TRANSITION])

func _apply_spiral_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create spiral/torus structure
				var spiral_factor = _spiral_noise(pos, center)
				var effective_radius = max_radius * (0.6 + spiral_factor * 0.4)
				
				if distance_to_center > effective_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_SMOOTH, MaterialZone.CORE_SOLID, MaterialZone.SUPPORT])

func _apply_tree_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create tree-like branching structure
				var tree_factor = _tree_noise(pos, center)
				
				if distance_to_center > max_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				elif tree_factor > 0.7:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SUPPORT, MaterialZone.CORE_SOLID])
				elif tree_factor > 0.4:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_ROUGH, MaterialZone.DETAIL_FINE])
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.VOID, MaterialZone.TRANSITION])

func _apply_sphere_cluster_constraints(center: Vector3, max_radius: float):
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				var pos = Vector3(x, y, z)
				var distance_to_center = (pos - center).length()
				
				# Create cluster of interconnected spheres
				var sphere_factor = _sphere_cluster_noise(pos, center)
				
				if distance_to_center > max_radius:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type == MaterialZone.VOID)
				elif sphere_factor > 0.6:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.SURFACE_SMOOTH, MaterialZone.CORE_SOLID])
				else:
					cell.possible_voxels = voxel_types.filter(func(v): return v.type in [MaterialZone.VOID, MaterialZone.TRANSITION])

func _apply_default_constraints(center: Vector3, max_radius: float):
	# Default organic constraints (original behavior)
	_apply_abstract_organic_constraints(center, max_radius)

# Noise functions for different sculpture types
func _crystal_noise(pos: Vector3) -> float:
	return abs(sin(pos.x * 3.0) * cos(pos.y * 3.0) * sin(pos.z * 3.0))

func _mineral_noise(pos: Vector3) -> float:
	return sin(pos.x * 1.5 + pos.y * 2.1) * cos(pos.z * 1.8 + pos.x * 1.3)

func _fluid_noise(pos: Vector3) -> float:
	return sin(pos.x * 0.8 + pos.y * 1.2) * cos(pos.z * 1.1 + pos.x * 0.9) * sin(pos.y * 0.7)

func _fiber_noise(pos: Vector3) -> float:
	var dist = pos.length()
	return sin(dist * 2.0 + pos.y * 3.0) * 0.5 + 0.5

func _spiral_noise(pos: Vector3, center: Vector3) -> float:
	var relative_pos = pos - center
	var angle = atan2(relative_pos.x, relative_pos.z)
	var height_factor = relative_pos.y / sculpture_size.y
	return sin(angle * 3.0 + height_factor * 6.0) * 0.5 + 0.5

func _tree_noise(pos: Vector3, center: Vector3) -> float:
	var relative_pos = pos - center
	var distance_from_center = relative_pos.length()
	var height_factor = pos.y / sculpture_size.y
	return sin(distance_from_center * 2.0) * cos(height_factor * 4.0) * 0.5 + 0.5

func _sphere_cluster_noise(pos: Vector3, center: Vector3) -> float:
	var relative_pos = pos - center
	var cluster_centers = [
		Vector3(0, 0, 0),
		Vector3(sculpture_size.x * 0.3, sculpture_size.y * 0.2, sculpture_size.z * 0.3),
		Vector3(-sculpture_size.x * 0.3, sculpture_size.y * 0.4, -sculpture_size.z * 0.3),
		Vector3(sculpture_size.x * 0.2, sculpture_size.y * 0.6, -sculpture_size.z * 0.2)
	]
	
	var max_influence = 0.0
	for cluster_center in cluster_centers:
		var distance = (relative_pos - cluster_center).length()
		var influence = exp(-distance / (sculpture_size.x * 0.2))
		max_influence = max(max_influence, influence)
	
	return max_influence

func run_sculpture_wfc():
	var max_iterations = sculpture_size.x * sculpture_size.y * sculpture_size.z * 1  # Reduced from 2 to 1
	var iterations = 0
	
	while not is_sculpture_collapsed() and iterations < max_iterations:
		var target_cell = find_sculpture_entropy_cell()
		if target_cell == null:
			break
		
		if not target_cell.collapse():
			print("Failed to collapse sculpture cell at: ", target_cell.position)
			break
		
		propagate_sculpture_constraints(target_cell)
		iterations += 1
		
		# Progress feedback
		if iterations % 1000 == 0:
			print("Sculpture generation progress: ", iterations, "/", max_iterations)
			# Yield control back to the main thread every 1000 iterations
			await get_tree().process_frame
	
	print("Sculpture WFC completed in ", iterations, " iterations")

func find_sculpture_entropy_cell() -> SculptureCell:
	var min_entropy = INF
	var candidates: Array[SculptureCell] = []
	
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				if not cell.collapsed:
					var entropy = cell.get_entropy()
					if entropy > 0 and entropy < min_entropy:
						min_entropy = entropy
						candidates = [cell]
					elif entropy == min_entropy:
						candidates.append(cell)
	
	return candidates[randi() % candidates.size()] if not candidates.is_empty() else null

func propagate_sculpture_constraints(collapsed_cell: SculptureCell):
	var propagation_stack: Array[SculptureCell] = [collapsed_cell]
	
	while not propagation_stack.is_empty():
		var current_cell = propagation_stack.pop_back()
		var neighbors = get_sculpture_neighbors(current_cell.position)
		
		for neighbor in neighbors:
			if neighbor == null or neighbor.collapsed or current_cell.chosen_voxel == null:
				continue
			
			var valid_voxels: Array[SculptureVoxel] = []
			
			for voxel in neighbor.possible_voxels:
				if current_cell.chosen_voxel.neighbors.has(voxel.type):
					valid_voxels.append(voxel)
			
			var old_count = neighbor.possible_voxels.size()
			neighbor.possible_voxels = valid_voxels
			
			if neighbor.possible_voxels.size() < old_count and neighbor not in propagation_stack:
				propagation_stack.append(neighbor)

func get_sculpture_neighbors(pos: Vector3i) -> Array[SculptureCell]:
	var directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	
	var neighbors: Array[SculptureCell] = []
	for direction in directions:
		var neighbor_pos = pos + direction
		if is_valid_sculpture_position(neighbor_pos):
			neighbors.append(sculpture_grid[neighbor_pos.x][neighbor_pos.y][neighbor_pos.z])
		else:
			neighbors.append(null)
	
	return neighbors

func is_valid_sculpture_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < sculpture_size.x and \
		   pos.y >= 0 and pos.y < sculpture_size.y and \
		   pos.z >= 0 and pos.z < sculpture_size.z

func is_sculpture_collapsed() -> bool:
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				if not sculpture_grid[x][y][z].collapsed:
					return false
	return true

func generate_sculpture_mesh():
	# Use marching cubes approach for smooth sculpture surface
	create_instanced_voxel_representation()
	create_smooth_surface_mesh()

func create_instanced_voxel_representation():
	# Create visual representation showing material zones
	var material_groups = {}
	
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				if cell.collapsed and cell.chosen_voxel.type != MaterialZone.VOID:
					var material_type = cell.chosen_voxel.type
					
					if not material_groups.has(material_type):
						material_groups[material_type] = []
					
					material_groups[material_type].append(cell)
	
	# Create mesh instances for each material group
	for material_type in material_groups:
		create_material_group_mesh(material_type, material_groups[material_type])

func create_material_group_mesh(material_type: MaterialZone, cells: Array):
	var multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.set_meta("sculpture_generated", true)
	multimesh_instance.name = "SculptureMaterial_" + MaterialZone.keys()[material_type]
	
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = cells.size()
	
	# Create base mesh for this material type
	var base_mesh = create_voxel_mesh_for_material(material_type)
	multimesh.mesh = base_mesh
	
	# Position each instance
	for i in range(cells.size()):
		var cell: SculptureCell = cells[i]
		var transform = Transform3D()
		transform.origin = Vector3(cell.position) * voxel_size
		
		# Add slight variation for organic feel
		var noise_scale = 0.1 * organic_flow
		transform.origin += Vector3(
			randf_range(-noise_scale, noise_scale),
			randf_range(-noise_scale, noise_scale),
			randf_range(-noise_scale, noise_scale)
		)
		
		# Slight scale variation
		var scale_variation = 1.0 + randf_range(-0.1, 0.1) * surface_complexity
		transform = transform.scaled(Vector3.ONE * scale_variation)
		
		multimesh.set_instance_transform(i, transform)
	
	multimesh_instance.multimesh = multimesh
	
	# Create material
	var material = create_material_for_zone(material_type)
	multimesh_instance.material_override = material
	
	add_child(multimesh_instance)
	if Engine.is_editor_hint():
		multimesh_instance.owner = get_tree().edited_scene_root

func create_voxel_mesh_for_material(material_type: MaterialZone) -> Mesh:
	match material_type:
		MaterialZone.CORE_SOLID:
			var box = BoxMesh.new()
			box.size = Vector3.ONE * voxel_size
			return box
		
		MaterialZone.SURFACE_SMOOTH:
			var sphere = SphereMesh.new()
			sphere.radius = voxel_size * 0.4
			sphere.height = voxel_size * 0.8
			return sphere
		
		MaterialZone.SURFACE_ROUGH:
			return create_rough_surface_mesh()
		
		MaterialZone.SURFACE_POROUS:
			return create_porous_mesh()
		
		MaterialZone.TRANSITION:
			var capsule = CapsuleMesh.new()
			capsule.radius = voxel_size * 0.3
			capsule.height = voxel_size * 0.8
			return capsule
		
		MaterialZone.SUPPORT:
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = voxel_size * 0.2
			cylinder.bottom_radius = voxel_size * 0.3
			cylinder.height = voxel_size
			return cylinder
		
		MaterialZone.DETAIL_FINE:
			return create_detail_mesh(true)
		
		MaterialZone.DETAIL_DEEP:
			return create_detail_mesh(false)
		
		_:
			var box = BoxMesh.new()
			box.size = Vector3.ONE * voxel_size * 0.8
			return box

func create_rough_surface_mesh() -> ArrayMesh:
	# Create irregular surface mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Create randomized cube vertices for rough surface
	var base_size = voxel_size * 0.5
	for i in range(8):
		var corner = Vector3(
			(i & 1) * 2 - 1,
			((i >> 1) & 1) * 2 - 1,
			((i >> 2) & 1) * 2 - 1
		) * base_size
		
		# Add random displacement for roughness
		corner += Vector3(
			randf_range(-base_size * 0.3, base_size * 0.3),
			randf_range(-base_size * 0.3, base_size * 0.3),
			randf_range(-base_size * 0.3, base_size * 0.3)
		)
		
		vertices.append(corner)
		normals.append(corner.normalized())
	
	# Simple cube triangulation
	var cube_indices = [
		0,1,2, 1,3,2, 4,6,5, 5,6,7,
		0,2,4, 2,6,4, 1,5,3, 3,5,7,
		0,4,1, 1,4,5, 2,3,6, 3,7,6
	]
	indices.append_array(cube_indices)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func create_porous_mesh() -> Mesh:
	# Create mesh with holes/pores
	var sphere = SphereMesh.new()
	sphere.radius = voxel_size * 0.35
	sphere.height = voxel_size * 0.7
	return sphere

func create_detail_mesh(fine: bool) -> Mesh:
	if fine:
		var sphere = SphereMesh.new()
		sphere.radius = voxel_size * 0.2
		sphere.height = voxel_size * 0.4
		return sphere
	else:
		var box = BoxMesh.new()
		box.size = Vector3.ONE * voxel_size * 0.6
		return box

func create_smooth_surface_mesh():
	# Create a smooth continuous surface using marching cubes concept
	var surface_mesh_instance = MeshInstance3D.new()
	surface_mesh_instance.set_meta("sculpture_generated", true)
	surface_mesh_instance.name = "SculptureSurface"
	
	# Create simplified surface mesh
	var surface_mesh = create_continuous_surface()
	surface_mesh_instance.mesh = surface_mesh
	
	# Surface material
	var surface_material = StandardMaterial3D.new()
	surface_material.albedo_color = Color(0.9, 0.8, 0.7)
	surface_material.roughness = 0.3
	surface_material.metallic = 0.1
	surface_material.flags_unshaded = false
	surface_mesh_instance.material_override = surface_material
	
	add_child(surface_mesh_instance)
	if Engine.is_editor_hint():
		surface_mesh_instance.owner = get_tree().edited_scene_root

func create_continuous_surface() -> Mesh:
	# Simplified surface generation - in production you'd use marching cubes
	var sphere = SphereMesh.new()
	var avg_size = (sculpture_size.x + sculpture_size.y + sculpture_size.z) / 3.0
	sphere.radius = avg_size * voxel_size * 0.3
	sphere.height = avg_size * voxel_size * 0.6
	return sphere

func create_material_for_zone(zone: MaterialZone) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	match zone:
		MaterialZone.CORE_SOLID:
			material.albedo_color = Color(0.3, 0.3, 0.4)
			material.metallic = 0.7
			material.roughness = 0.2
		
		MaterialZone.SURFACE_SMOOTH:
			material.albedo_color = Color(0.9, 0.8, 0.7)
			material.metallic = 0.1
			material.roughness = 0.1
		
		MaterialZone.SURFACE_ROUGH:
			material.albedo_color = Color(0.7, 0.6, 0.5)
			material.metallic = 0.2
			material.roughness = 0.8
		
		MaterialZone.SURFACE_POROUS:
			material.albedo_color = Color(0.6, 0.5, 0.4)
			material.metallic = 0.0
			material.roughness = 0.9
		
		MaterialZone.TRANSITION:
			material.albedo_color = Color(0.5, 0.5, 0.6)
			material.metallic = 0.3
			material.roughness = 0.5
		
		MaterialZone.SUPPORT:
			material.albedo_color = Color(0.4, 0.4, 0.5)
			material.metallic = 0.8
			material.roughness = 0.3
		
		MaterialZone.DETAIL_FINE:
			material.albedo_color = Color(0.95, 0.9, 0.85)
			material.metallic = 0.0
			material.roughness = 0.2
		
		MaterialZone.DETAIL_DEEP:
			material.albedo_color = Color(0.3, 0.2, 0.1)
			material.metallic = 0.1
			material.roughness = 0.9
		
		_:
			material.albedo_color = Color.WHITE
			material.roughness = 0.5
	
	return material

func apply_post_processing():
	# Add final touches to the sculpture
	print("Sculpture generation complete!")
	print("Hollow areas: ", count_material_type(MaterialZone.VOID))
	print("Surface details: ", count_material_type(MaterialZone.DETAIL_FINE) + count_material_type(MaterialZone.DETAIL_DEEP))

func count_material_type(material_type: MaterialZone) -> int:
	var count = 0
	for x in sculpture_size.x:
		for y in sculpture_size.y:
			for z in sculpture_size.z:
				var cell: SculptureCell = sculpture_grid[x][y][z]
				if cell.collapsed and cell.chosen_voxel.type == material_type:
					count += 1
	return count
