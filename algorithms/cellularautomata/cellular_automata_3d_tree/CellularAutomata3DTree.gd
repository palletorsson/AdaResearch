@tool
extends Node3D

@export_category("Tree Settings")
@export var base_size: int = 4
@export var max_height: int = 20
@export var generation_interval: float = 0.1
@export var auto_play: bool = true
@export var gradient: Gradient

@export_category("Pruning Rules")
@export var edge_pruning_chance: float = 0.4
@export var isolation_pruning_chance: float = 0.5
@export var random_pruning_base: float = 0.1

var current_level = 0
var generation_timer = 0.0
var grid = {}  # Dictionary to store 3D grid: Vector3i -> 1/0
var is_growing = false

@onready var multi_mesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D

func _ready():
	if not multi_mesh_instance:
		_setup_multimesh()
	
	if not gradient:
		_setup_default_gradient()
		
	if auto_play:
		start_growth()

func _process(delta):
	if is_growing:
		generation_timer += delta
		if generation_timer >= generation_interval:
			generation_timer = 0.0
			grow_next_level()

func _setup_multimesh():
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.name = "MultiMeshInstance3D"
	add_child(multi_mesh_instance)
	
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.mesh.size = Vector3(0.5, 0.5, 0.5)
	multimesh.use_colors = true
	multimesh.instance_count = 0
	multi_mesh_instance.multimesh = multimesh

func _setup_default_gradient():
	gradient = Gradient.new()
	gradient.remove_point(0)
	gradient.remove_point(0)
	gradient.add_point(0.0, Color("5d4037")) # Brown (Trunk)
	gradient.add_point(0.4, Color("388e3c")) # Green (Leaves)
	gradient.add_point(1.0, Color("81c784")) # Light Green (Top)

func start_growth():
	current_level = 0
	grid.clear()
	if multi_mesh_instance.multimesh:
		multi_mesh_instance.multimesh.instance_count = 0
	
	# Build base immediately
	for level in range(8):
		create_square_layer(level, base_size)
	current_level = 8
	_update_multimesh()
	is_growing = true

func grow_next_level():
	# Expansion phase: levels 8-10
	if current_level >= 8 and current_level <= 10:
		var size = (base_size + 1) + (current_level - 8)
		create_square_layer(current_level, size)
		apply_ca_pruning(current_level, size)
		current_level += 1
	# Maintain phase: levels 11-14
	elif current_level >= 11 and current_level <= 14:
		var size = base_size + 3
		create_square_layer(current_level, size)
		apply_ca_pruning(current_level, size)
		current_level += 1
	# Shrink phase: levels 15-18
	elif current_level >= 15 and current_level <= 18:
		var shrink_step = current_level - 15
		var size = (base_size + 3) - (shrink_step * 2)
		if size > 0:
			create_square_layer(current_level, size)
			apply_ca_pruning(current_level, size)
		current_level += 1
	else:
		is_growing = false
		print("Tree growth complete at level: ", current_level)
	
	_update_multimesh()

func create_square_layer(level: int, size: int):
	for x in range(size):
		for z in range(size):
			var grid_pos = Vector3i(x, level, z)
			# Center the grid coordinates relative to the tree center
			# This simplifies the pruning logic which assumes a center
			grid[grid_pos] = 1

func apply_ca_pruning(level: int, size: int):
	var cubes_to_remove = []
	var center = float(size) / 2.0 - 0.5

	for x in range(size):
		for z in range(size):
			var grid_pos = Vector3i(x, level, z)
			if not grid.has(grid_pos): continue

			var dist_from_center = Vector2(x - center, z - center).length()
			var max_dist = Vector2(center, center).length()
			var edge_factor = dist_from_center / max_dist if max_dist > 0 else 0

			var neighbor_count = count_neighbors_2d(x, level, z, size)
			var should_remove = false

			# Rule 1: Remove corners/edges
			if edge_factor > 0.7 and randf() < edge_pruning_chance:
				should_remove = true

			# Rule 2: Remove isolated cubes
			if neighbor_count < 3 and randf() < isolation_pruning_chance:
				should_remove = true

			# Rule 3: Random organic variation
			var removal_chance = random_pruning_base + (level / 20.0) * 0.1
			if randf() < removal_chance:
				should_remove = true

			# Protect center
			if abs(x - center) < 1.0 and abs(z - center) < 1.0:
				should_remove = false

			if should_remove:
				cubes_to_remove.append(grid_pos)

	for pos in cubes_to_remove:
		grid.erase(pos)

func count_neighbors_2d(x: int, level: int, z: int, size: int) -> int:
	var count = 0
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0: continue
			var neighbor_pos = Vector3i(x + dx, level, z + dz)
			if grid.has(neighbor_pos):
				count += 1
	return count

func _update_multimesh():
	if not multi_mesh_instance or not multi_mesh_instance.multimesh: return
	
	var mm = multi_mesh_instance.multimesh
	var cells = grid.keys()
	mm.instance_count = cells.size()
	
	var idx = 0
	for pos in cells:
		var level = pos.y
		# We need to reconstruct the visual position based on size at that level
		# This is a bit tricky because we stored local grid coordinates (0..size)
		# We need to know the 'size' of the layer this cell belongs to to center it.
		# A simplification: We can store the visual position in the grid dictionary value instead of just '1'
		# OR re-calculate size based on level logic (which is deterministic).
		
		var size = _get_size_for_level(level)
		var half_size = size / 2.0
		
		var visual_x = (pos.x - half_size + 0.5) * 0.55
		var visual_y = level * 0.55
		var visual_z = (pos.z - half_size + 0.5) * 0.55
		
		var t = Transform3D(Basis(), Vector3(visual_x, visual_y, visual_z))
		mm.set_instance_transform(idx, t)
		
		var color_ratio = float(level) / 18.0 # Approx max height
		var col = gradient.sample(color_ratio)
		mm.set_instance_color(idx, col)
		
		idx += 1

func _get_size_for_level(level: int) -> int:
	if level < 8: return base_size
	if level >= 8 and level <= 10: return (base_size + 1) + (level - 8)
	if level >= 11 and level <= 14: return base_size + 3
	if level >= 15 and level <= 18: return (base_size + 3) - ((level - 15) * 2)
	return 0
