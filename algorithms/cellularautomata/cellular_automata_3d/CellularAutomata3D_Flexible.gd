@tool
extends Node3D

# Configurable 3D Cellular Automata
# Supports "Generations" type rules: Survive/Born/States/Neighborhood
# Notation example: "6-8/6-8/3/M"

@export_group("Grid Settings")
@export var grid_size: Vector3i = Vector3i(30, 30, 30)
@export var cell_size: float = 0.2
@export var generation_interval: float = 0.1
@export var run_duration: float = 0.0 # 0.0 means infinite
@export var max_generations: int = 0 # 0 means infinite
@export var paused: bool = false
@export var randomize_on_start: bool = false
@export var center_seed_on_start: bool = true
@export var reset: bool = false:
	set(value):
		if value:
			_initialize_grid()
			generation = 0
			paused = false
			reset = false

@export_group("Debug")
@export var current_generation: int = 0:
	get:
		return generation
	set(value):
		pass # Read only

@export_group("Rule Settings")
@export var rule_string: String = "4-5/5/5/M": # Default to a builder-like rule
	set(value):
		rule_string = value
		_parse_rule(value)

@export_group("Visuals")
@export var mesh_instance: MultiMeshInstance3D
@export var color_alive: Color = Color.WHITE
@export var color_dying: Color = Color.DARK_GRAY
@export var use_gradient: bool = false
@export var gradient_mode: int = 0 # 0: None, 1: Height (Y), 2: Generation
@export var gradient: Gradient

# Internal state
var current_state: PackedByteArray
var next_state: PackedByteArray
var time_accumulator: float = 0.0
var run_timer: float = 0.0
var generation: int = 0
var total_cells: int = 0
var stride_y: int = 0
var stride_z: int = 0

# Parsed rule
var rule_survive: Array[bool] = [] # Index is neighbor count
var rule_born: Array[bool] = []
var rule_states: int = 2
var rule_neighborhood: String = "M"

# Optimization: Precomputed neighbor offsets
var neighbor_offsets: Array[int] = []

func _ready() -> void:
	# robustly find or create mesh instance
	if not mesh_instance:
		for child in get_children():
			if child is MultiMeshInstance3D:
				mesh_instance = child
				break
		
		if not mesh_instance:
			mesh_instance = MultiMeshInstance3D.new()
			mesh_instance.name = "AutomataMesh"
			add_child(mesh_instance)
			
			if Engine.is_editor_hint():
				var root = get_tree().edited_scene_root
				if root:
					mesh_instance.owner = root
	
	# Setup MultiMesh if needed
	if not mesh_instance.multimesh:
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = BoxMesh.new()
		multimesh.mesh.size = Vector3(cell_size, cell_size, cell_size) * 0.9
		mesh_instance.multimesh = multimesh
	
	# Auto-configure gradient based on node name if not set
	if not gradient:
		var n = name.to_lower()
		if "mold" in n:
			gradient = Gradient.new()
			# Overwrite the 2 default points instead of remove+add
			gradient.set_offset(0, 0.0)
			gradient.set_color(0, Color("2e7d32"))   # Dark Green
			gradient.set_offset(1, 1.0)
			gradient.set_color(1, Color("aed581"))   # Light Green
			gradient.add_point(0.5, Color("4db6ac")) # Teal
			use_gradient = true
			gradient_mode = 1 # Height
		elif "structure" in n:
			gradient = Gradient.new()
			# Overwrite the 2 default points instead of remove+add
			gradient.set_offset(0, 0.0)
			gradient.set_color(0, Color("455a64"))   # Blue Grey Dark
			gradient.set_offset(1, 1.0)
			gradient.set_color(1, Color("eceff1"))   # White-ish
			gradient.add_point(0.5, Color("90a4ae")) # Blue Grey Light
			use_gradient = true
			gradient_mode = 1 # Height

	# Ensure material supports vertex colors
	if mesh_instance.multimesh and mesh_instance.multimesh.mesh:
		var mesh = mesh_instance.multimesh.mesh
		if not mesh.material:
			var mat = StandardMaterial3D.new()
			mat.vertex_color_use_as_albedo = true
			mesh.material = mat
		elif mesh.material is StandardMaterial3D:
			mesh.material.vertex_color_use_as_albedo = true

	_calculate_strides()
	_precompute_neighbor_offsets()
	_parse_rule(rule_string)
	_initialize_grid()
	_update_visuals()

func _calculate_strides() -> void:
	stride_y = grid_size.x
	stride_z = grid_size.x * grid_size.y
	total_cells = grid_size.x * grid_size.y * grid_size.z

func _precompute_neighbor_offsets() -> void:
	neighbor_offsets.clear()
	for z in range(-1, 2):
		for y in range(-1, 2):
			for x in range(-1, 2):
				if x == 0 and y == 0 and z == 0:
					continue
				var offset = x + (y * stride_y) + (z * stride_z)
				neighbor_offsets.append(offset)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if paused:
		return
	
	if run_duration > 0.0:
		run_timer += delta
		if run_timer >= run_duration:
			paused = true
			return
	
	if max_generations > 0 and generation >= max_generations:
		paused = true
		return
		
	time_accumulator += delta
	if time_accumulator >= generation_interval:
		time_accumulator = 0.0
		_step()

func _parse_rule(rule: String) -> void:
	var parts = rule.split("/")
	if parts.size() < 2:
		push_error("Invalid rule format. Expected S/B/C/N or S/B")
		return
	
	rule_survive = []
	rule_born = []
	rule_survive.resize(27)
	rule_born.resize(27)
	rule_survive.fill(false)
	rule_born.fill(false)
	
	_parse_range_string(parts[0], rule_survive)
	_parse_range_string(parts[1], rule_born)
	
	if parts.size() > 2:
		rule_states = int(parts[2])
	else:
		rule_states = 2
		
	if parts.size() > 3:
		rule_neighborhood = parts[3]
	else:
		rule_neighborhood = "M"

func _parse_range_string(s: String, target_array: Array[bool]) -> void:
	var groups = s.split(",")
	for group in groups:
		if "-" in group:
			var range_parts = group.split("-")
			var start = int(range_parts[0])
			var end = int(range_parts[1])
			for i in range(start, end + 1):
				if i < target_array.size():
					target_array[i] = true
		else:
			var val = int(group)
			if val < target_array.size():
				target_array[val] = true

func _initialize_grid() -> void:
	_calculate_strides()
	current_state.resize(total_cells)
	next_state.resize(total_cells)
	current_state.fill(0)
	next_state.fill(0)
	
	if center_seed_on_start:
		var cx = grid_size.x / 2
		var cy = grid_size.y / 2
		var cz = grid_size.z / 2
		var range_ext = 3
		
		for z in range(cz - range_ext, cz + range_ext + 1):
			for y in range(cy - range_ext, cy + range_ext + 1):
				for x in range(cx - range_ext, cx + range_ext + 1):
					if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y and z >= 0 and z < grid_size.z:
						if randf() > 0.5:
							var idx = x + (y * stride_y) + (z * stride_z)
							current_state[idx] = 1
	
	if randomize_on_start:
		for i in range(total_cells):
			if randf() < 0.1:
				current_state[i] = 1

	# Setup MultiMesh capacity
	mesh_instance.multimesh.instance_count = total_cells
	mesh_instance.multimesh.visible_instance_count = 0

func _step() -> void:
	# Optimized step using 1D array and precomputed offsets
	# We avoid boundary checks in the inner loop by iterating only the safe inner volume
	# and handling boundaries separately (or just ignoring them for speed, treating as dead)
	
	var sx = grid_size.x
	var sy = grid_size.y
	var sz = grid_size.z
	
	# Safe bounds to avoid boundary checks in the hot loop
	for z in range(1, sz - 1):
		var z_offset = z * stride_z
		for y in range(1, sy - 1):
			var y_offset = y * stride_y
			for x in range(1, sx - 1):
				var idx = x + y_offset + z_offset
				var state = current_state[idx]
				
				# Count neighbors
				var neighbors = 0
				for offset in neighbor_offsets:
					if current_state[idx + offset] == 1:
						neighbors += 1
				
				# Apply Rules
				if state == 0:
					if rule_born[neighbors]:
						next_state[idx] = 1
					else:
						next_state[idx] = 0
				elif state == 1:
					if rule_survive[neighbors]:
						next_state[idx] = 1
					else:
						if rule_states > 2:
							next_state[idx] = 2
						else:
							next_state[idx] = 0
				else:
					if state < rule_states - 1:
						next_state[idx] = state + 1
					else:
						next_state[idx] = 0
	
	# Swap buffers
	var temp = current_state
	current_state = next_state
	next_state = temp
	
	generation += 1
	_update_visuals()

func _update_visuals() -> void:
	var mm = mesh_instance.multimesh
	var active_count = 0
	
	var sx = grid_size.x
	var sy = grid_size.y
	var sz = grid_size.z
	
	# Optimization: Skip the outer boundary layer (always dead)
	# This matches the logic in _step() and saves iterations
	for z in range(1, sz - 1):
		var z_offset = z * stride_z
		for y in range(1, sy - 1):
			var y_offset = y * stride_y
			for x in range(1, sx - 1):
				var idx = x + y_offset + z_offset
				var state = current_state[idx]
				
				if state > 0:
					# Optimization: Occlusion Culling (Shell Rendering)
					# Only render if at least one neighbor is empty (or transparent)
					# This drastically reduces instance count for dense structures
					var is_visible = false
					
					# Check 6 direct neighbors
					# We can use the precomputed offsets, but we need to be careful about the 26 vs 6 neighbors
					# Let's just check the 6 cardinal neighbors manually for speed and correctness of "shell"
					
					# x+1
					if current_state[idx + 1] == 0: is_visible = true
					# x-1
					elif current_state[idx - 1] == 0: is_visible = true
					# y+1
					elif current_state[idx + stride_y] == 0: is_visible = true
					# y-1
					elif current_state[idx - stride_y] == 0: is_visible = true
					# z+1
					elif current_state[idx + stride_z] == 0: is_visible = true
					# z-1
					elif current_state[idx - stride_z] == 0: is_visible = true
					
					if is_visible:
						var t = Transform3D()
						t.origin = Vector3(x, y, z) * cell_size
						
						var color = color_alive
						
						if use_gradient and gradient:
							var t_grad = 0.0
							if gradient_mode == 1: # Height (Y)
								t_grad = float(y) / float(sy)
							elif gradient_mode == 2: # Generation (approximate or just Z?)
								t_grad = float(y) / float(sy)
							
							color = gradient.sample(t_grad)
						elif state > 1:
							var t_life = float(state - 1) / float(rule_states - 2) if rule_states > 2 else 0.0
							color = color_alive.lerp(color_dying, t_life)
						
						mm.set_instance_transform(active_count, t)
						mm.set_instance_color(active_count, color)
						active_count += 1
	
	mm.visible_instance_count = active_count

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
