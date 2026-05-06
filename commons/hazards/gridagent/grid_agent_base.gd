# grid_agent_base.gd
# Base class for Grid Agents - algorithmic entities that traverse and modify grid structures

# @identity
# essence: CharacterBody3D with a NavigationAgent3D that wanders grids, transitions between WANDERING→FEEDING→WORKING→CAPTURED→DIRECTED states, and applies EvolutionTiers operations to the grid cells it traverses
# desire: to encounter something that has agency inside an array — to watch a grid agent wander through a 2D grid, consume cubes, and evolve tier by tier, making the array feel like a habitat rather than a data structure
# critical_parameter: operation_radius — the number of cells the agent affects when in WORKING state; a small radius makes the agent precise and surgical; a large radius makes it chaotic and territorial
# triggers: the agent tier (TIER_1_COPY through higher tiers) determines which GridOperations the agent applies when working; capturing it with the algo-gun (CAPTURED state) interrupts its autonomous behavior and lets the player direct it
# emerges: multiple agents interacting on the same grid create emergent territorial behavior — they unintentionally avoid each other through the physical grid topology rather than any explicit collision logic
# needs: NavigationAgent3D [has]; mesh sphere visual [has]; thought_label Label3D [has]; show_thoughts flag [has]; algo-gun capture mechanism [has when CAPTURED]; VR interaction for directing [has via DIRECTED state]
# relationships: used in Tutorial_2D_Build alongside grid_2d_4x4 as a hazard that modifies the grid; depends on EvolutionTiers, GridInterface, GridOperations helper classes; connects to gridagent_puzzle maps
# truth: an agent inside an array reveals that data structures are not passive containers — they are environments that agents inhabit, and the grid's indexed structure determines what moves are possible

extends CharacterBody3D
class_name GridAgent

# Export properties for configuration
@export var movement_speed: float = 2.0
@export var detection_radius: float = 10.0
@export var operation_radius: int = 3
@export var operation_interval: float = 2.0
@export var wander_change_interval: float = 3.0
@export var show_thoughts: bool = true

# Agent tier (set via metadata or directly)
var current_tier: EvolutionTiers.Tier = EvolutionTiers.Tier.TIER_1_COPY
var evolution_xp: int = 0
var modifier_stack: Array[Dictionary] = []

# Grid reference
var current_grid: Node = null
var grid_cell_position: Vector3i = Vector3i.ZERO

# AI state machine
enum AgentState {
	WANDERING,   # Random walk through grid
	FEEDING,     # Consuming grid cubes for energy
	WORKING,     # Applying operations to grid
	CAPTURED,    # Held by algo-gun
	DIRECTED     # Following player task
}

var current_state: AgentState = AgentState.WANDERING
var state_timer: float = 0.0

# Timers
var operation_timer: float = 0.0
var wander_timer: float = 0.0
var thought_update_timer: float = 0.0

# Movement
var wander_direction: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var has_target: bool = false

# Components (created in _ready)
var navigation_agent: NavigationAgent3D
var collision_shape: CollisionShape3D
var mesh_instance: MeshInstance3D
var thought_label: Label3D

# Visual appearance
var base_color: Color = Color.CYAN
var glow_intensity: float = 1.0

func _ready():
	# Initialize components
	_setup_components()
	_setup_visuals()
	
	# Find grid in scene
	current_grid = GridInterface.get_grid_at_position(global_position)
	if current_grid:
		grid_cell_position = GridInterface.get_cell_at_position(current_grid, global_position)
		print("GridAgent: Found grid, starting at cell %s" % grid_cell_position)
	else:
		print("GridAgent: Warning - No grid found at spawn position")
	
	# Set tier from metadata if available
	if has_meta("agent_tier"):
		var tier_str = get_meta("agent_tier") as String
		current_tier = EvolutionTiers.parse_tier(tier_str)
		base_color = EvolutionTiers.get_color(current_tier)
		_update_visual_tier()
	
	# Optional stack config injected by GridInteractablesComponent.
	if has_meta("agent_config"):
		var cfg = get_meta("agent_config")
		if cfg is Dictionary:
			configure_modifier_stack(cfg)

	# Start in wandering state
	_change_state(AgentState.WANDERING)

func _setup_components():
	# Create NavigationAgent3D
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.name = "NavigationAgent3D"
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	add_child(navigation_agent)
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	add_child(collision_shape)
	
	# Create mesh (simple sphere for now)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.4
	sphere_mesh.height = 0.8
	mesh_instance.mesh = sphere_mesh
	add_child(mesh_instance)
	
	# Create thought label if enabled
	if show_thoughts:
		thought_label = Label3D.new()
		thought_label.name = "ThoughtLabel"
		thought_label.position = Vector3(0, 1.2, 0)
		thought_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		thought_label.font_size = 24
		thought_label.outline_size = 4
		thought_label.modulate = Color(0.9, 0.9, 1.0, 0.8)
		add_child(thought_label)

func _setup_visuals():
	# Create material for mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color * 0.5
	material.emission_energy_multiplier = glow_intensity
	mesh_instance.material_override = material

func _update_visual_tier():
	# Update appearance based on tier
	base_color = EvolutionTiers.get_color(current_tier)
	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override as StandardMaterial3D
		mat.albedo_color = base_color
		mat.emission = base_color * 0.5

func _physics_process(delta):
	# Update timers
	operation_timer += delta
	wander_timer += delta
	thought_update_timer += delta
	state_timer += delta
	
	# Update thought label
	if show_thoughts and thought_label and thought_update_timer >= 0.5:
		thought_update_timer = 0.0
		_update_thought_label()
	
	# State machine
	match current_state:
		AgentState.WANDERING:
			_process_wandering(delta)
		AgentState.FEEDING:
			_process_feeding(delta)
		AgentState.WORKING:
			_process_working(delta)
		AgentState.CAPTURED:
			_process_captured(delta)
		AgentState.DIRECTED:
			_process_directed(delta)

func _process_wandering(_delta):
	# Random walk behavior
	if wander_timer >= wander_change_interval:
		wander_timer = 0.0
		_choose_new_wander_direction()
	
	# Move in current direction
	if wander_direction.length() > 0.1:
		velocity = wander_direction.normalized() * movement_speed
		move_and_slide()
		
		# Update grid position
		if current_grid:
			grid_cell_position = GridInterface.get_cell_at_position(current_grid, global_position)
	
	# Occasionally try to feed or work
	if operation_timer >= operation_interval:
		operation_timer = 0.0
		# Can feed if grid supports removal (now includes GridStructureComponent!)
		var can_feed = current_grid and (
			current_grid.has_method("remove_cube_at") or 
			current_grid.has_method("set_cell_alive") or
			current_grid.has_method("set_cell")
		)
		
		if can_feed and randf() < 0.3:
			_change_state(AgentState.FEEDING)
		elif current_grid:
			_change_state(AgentState.WORKING)

func _process_feeding(_delta):
	# Consume nearby cubes for energy
	if not current_grid:
		_change_state(AgentState.WANDERING)
		return
	
	# Find nearby occupied cell
	var target_cell = GridInterface.find_nearest_occupied_cell(current_grid, grid_cell_position, 3)
	
	if target_cell != grid_cell_position and GridInterface.is_cell_occupied(current_grid, target_cell):
		# Consume the cube
		GridInterface.remove_cube_at_cell(current_grid, target_cell)
		evolution_xp += 1
		print("GridAgent: Consumed cube at %s (XP: %d)" % [target_cell, evolution_xp])
	
	# Return to wandering after feeding
	if state_timer >= 2.0:
		_change_state(AgentState.WANDERING)

func _process_working(_delta):
	# Apply tier-specific operation
	if not current_grid:
		_change_state(AgentState.WANDERING)
		return
	
	# Execute operation based on tier
	var success = _execute_tier_operation()
	
	if success:
		print("GridAgent: Executed %s operation at %s" % [EvolutionTiers.get_tier_string(current_tier), grid_cell_position])
	
	# Return to wandering after working
	if state_timer >= 1.5:
		_change_state(AgentState.WANDERING)

func _process_captured(_delta):
	# Agent is held by algo-gun, awaiting direction
	# Movement handled by gun
	velocity = Vector3.ZERO

func _process_directed(_delta):
	# Following player-assigned task
	# Similar to working but with specific target
	if not has_target:
		_change_state(AgentState.WANDERING)
		return
	
	# Move toward target
	if global_position.distance_to(target_position) > 1.0:
		var direction = (target_position - global_position).normalized()
		velocity = direction * movement_speed
		move_and_slide()
	else:
		# Reached target, execute operation
		var target_cell = GridInterface.get_cell_at_position(current_grid, target_position)
		grid_cell_position = target_cell
		_execute_tier_operation()
		has_target = false
		_change_state(AgentState.WANDERING)

func _execute_tier_operation() -> bool:
	if not current_grid:
		return false
	
	# If a modifier stack is configured, run it as a pipeline.
	if not modifier_stack.is_empty():
		return _execute_modifier_stack()
	
	# Execute operation based on current tier
	match current_tier:
		EvolutionTiers.Tier.TIER_1_COPY:
			return _operation_copy()
		EvolutionTiers.Tier.TIER_2_TRANSLATE:
			return _operation_translate()
		EvolutionTiers.Tier.TIER_3_ROTATE:
			return _operation_rotate()
		EvolutionTiers.Tier.TIER_4_SCALE:
			return _operation_scale()
		EvolutionTiers.Tier.TIER_5_COLOR:
			return _operation_color()
		EvolutionTiers.Tier.TIER_6_ARRAY:
			return _operation_array()
		EvolutionTiers.Tier.TIER_7_SINE:
			return _operation_sine()
		EvolutionTiers.Tier.TIER_8_RANDOM:
			return _operation_random()
		EvolutionTiers.Tier.TIER_9_CA:
			return _operation_ca()
	
	return false

# ===== Tier Operations =====

func _operation_copy() -> bool:
	# Find a nearby cube and copy it
	var source_cell = GridInterface.find_nearest_occupied_cell(current_grid, grid_cell_position, operation_radius)
	if source_cell == grid_cell_position:
		return false
	
	var direction = GridOperations.get_random_direction()
	return GridOperations.copy_cube_adjacent(current_grid, source_cell, direction)

func _operation_translate() -> bool:
	# Move a nearby cube
	var source_cell = GridInterface.find_nearest_occupied_cell(current_grid, grid_cell_position, operation_radius)
	if source_cell == grid_cell_position:
		return false
	
	var direction = GridOperations.get_random_direction()
	return GridOperations.translate_cube_direction(current_grid, source_cell, direction, 2)

func _operation_rotate() -> bool:
	# Rotate structure around current position
	var axis = Vector3i.UP  # Rotate around Y-axis
	return GridOperations.rotate_structure_90(current_grid, grid_cell_position, axis, operation_radius)

func _operation_scale() -> bool:
	# Scale structure at current position
	var scale_factor = 1.5 if randf() > 0.5 else 0.75  # Random grow or shrink
	return GridOperations.scale_structure(current_grid, grid_cell_position, scale_factor, operation_radius)

func _operation_color() -> bool:
	# Colorize nearby region
	return GridOperations.colorize_region(current_grid, grid_cell_position, base_color, operation_radius)

func _operation_array() -> bool:
	# Create array in random direction
	var direction = GridOperations.get_random_direction()
	var count = 3  # Create 3 copies
	var spacing = 2  # 2 cells apart
	return GridOperations.array_linear(current_grid, grid_cell_position, direction, count, spacing, 2)

func _operation_sine() -> bool:
	# Apply sine wave
	var amplitude = 2.0
	var frequency = 0.5
	var axis = "x" if randf() > 0.5 else "z"
	return GridOperations.apply_sine_wave(current_grid, grid_cell_position, amplitude, frequency, operation_radius, axis)

func _operation_random() -> bool:
	# Add randomness to region
	var probability = 0.3  # 30% chance to toggle each cube
	return GridOperations.randomize_structure(current_grid, grid_cell_position, probability, operation_radius)

func _operation_ca() -> bool:
	# Apply cellular automata
	return GridOperations.apply_ca_step(current_grid, grid_cell_position, "growth", operation_radius)

# ===== Transform Distortion Operations =====
# These manipulate multimesh transforms directly — visual-only glitch art.

func _operation_distort_explode() -> bool:
	# Snapshot first so we can restore later
	GridOperations.snapshot_transforms(current_grid)
	return GridOperations.distort_explode(current_grid, grid_cell_position, operation_radius, 3.0)

func _operation_distort_twist() -> bool:
	GridOperations.snapshot_transforms(current_grid)
	var axis = ["x", "y", "z"][randi() % 3]
	return GridOperations.distort_twist(current_grid, grid_cell_position, operation_radius, 15.0, axis)

func _operation_distort_scatter() -> bool:
	GridOperations.snapshot_transforms(current_grid)
	return GridOperations.distort_scatter(current_grid, grid_cell_position, operation_radius, 2.0, 45.0)

func _operation_distort_wave() -> bool:
	GridOperations.snapshot_transforms(current_grid)
	var axis = ["x", "y", "z"][randi() % 3]
	return GridOperations.distort_wave(current_grid, 1.5, 0.5, randf() * TAU, axis)

func _operation_distort_restore() -> bool:
	return GridOperations.restore_transforms(current_grid)

func _execute_modifier_stack() -> bool:
	var success_any = false
	for step in modifier_stack:
		if not (step is Dictionary):
			continue
		
		var op_name = str(step.get("op", "")).strip_edges().to_lower()
		if op_name.is_empty():
			continue
		
		var params = step.get("params", {})
		if not (params is Dictionary):
			params = {}
		
		var op_success = _execute_named_operation(op_name, params)
		success_any = success_any or op_success
	
	return success_any

func _execute_named_operation(op_name: String, params: Dictionary) -> bool:
	var radius = _coerce_int(params.get("radius", operation_radius), operation_radius)
	
	match op_name:
		"copy":
			var source_cell = GridInterface.find_nearest_occupied_cell(current_grid, grid_cell_position, radius)
			if source_cell == grid_cell_position:
				return false
			var direction = _parse_direction(str(params.get("direction", "")), GridOperations.get_random_direction())
			return GridOperations.copy_cube_adjacent(current_grid, source_cell, direction)
		
		"translate":
			var source_cell = GridInterface.find_nearest_occupied_cell(current_grid, grid_cell_position, radius)
			if source_cell == grid_cell_position:
				return false
			var direction = _parse_direction(str(params.get("direction", "")), GridOperations.get_random_direction())
			var distance = _coerce_int(params.get("distance", 2), 2)
			return GridOperations.translate_cube_direction(current_grid, source_cell, direction, distance)
		
		"rotate":
			var axis = _axis_to_vector(str(params.get("axis", "y")))
			return GridOperations.rotate_structure_90(current_grid, grid_cell_position, axis, radius)
		
		"scale":
			var scale_factor = _coerce_float(params.get("factor", 1.5), 1.5)
			return GridOperations.scale_structure(current_grid, grid_cell_position, scale_factor, radius)
		
		"color":
			return GridOperations.colorize_region(current_grid, grid_cell_position, base_color, radius)
		
		"array":
			var direction = _parse_direction(str(params.get("direction", "x")), Vector3i(1, 0, 0))
			var count = _coerce_int(params.get("count", 3), 3)
			var spacing = _coerce_int(params.get("spacing", 2), 2)
			return GridOperations.array_linear(current_grid, grid_cell_position, direction, count, spacing, radius)
		
		"sine":
			var amplitude = _coerce_float(params.get("amplitude", 2.0), 2.0)
			var frequency = _coerce_float(params.get("frequency", 0.5), 0.5)
			var axis_name = str(params.get("axis", "x"))
			return GridOperations.apply_sine_wave(current_grid, grid_cell_position, amplitude, frequency, radius, axis_name)
		
		"random":
			var probability = _coerce_float(params.get("probability", 0.3), 0.3)
			return GridOperations.randomize_structure(current_grid, grid_cell_position, probability, radius)
		
		"ca":
			var rule_type = str(params.get("rule", "growth"))
			return GridOperations.apply_ca_step(current_grid, grid_cell_position, rule_type, radius)
		
		"mirror":
			var mirror_axis = str(params.get("axis", "x"))
			var keep_original = _coerce_bool(params.get("keep_original", true), true)
			return GridOperations.mirror_structure(current_grid, grid_cell_position, mirror_axis, radius, keep_original)
		
		"twist":
			var twist_axis = str(params.get("axis", "y"))
			var twist_angle = _coerce_float(params.get("angle_degrees", 15.0), 15.0)
			return GridOperations.twist_structure(current_grid, grid_cell_position, twist_angle, radius, twist_axis)
		
		# Transform distortion ops (visual-only, glitch art)
		"distort_explode", "explode":
			var strength = _coerce_float(params.get("strength", 3.0), 3.0)
			GridOperations.snapshot_transforms(current_grid)
			return GridOperations.distort_explode(current_grid, grid_cell_position, radius, strength)
		
		"distort_twist":
			var twist_axis = str(params.get("axis", "y"))
			var angle = _coerce_float(params.get("angle_per_unit", 15.0), 15.0)
			GridOperations.snapshot_transforms(current_grid)
			return GridOperations.distort_twist(current_grid, grid_cell_position, radius, angle, twist_axis)
		
		"distort_scatter", "scatter":
			var scatter_str = _coerce_float(params.get("scatter_strength", 2.0), 2.0)
			var rot_str = _coerce_float(params.get("rotation_strength", 45.0), 45.0)
			GridOperations.snapshot_transforms(current_grid)
			return GridOperations.distort_scatter(current_grid, grid_cell_position, radius, scatter_str, rot_str)
		
		"distort_wave":
			var amplitude = _coerce_float(params.get("amplitude", 1.5), 1.5)
			var frequency = _coerce_float(params.get("frequency", 0.5), 0.5)
			var phase = _coerce_float(params.get("phase", 0.0), 0.0)
			var wave_axis = str(params.get("axis", "y"))
			GridOperations.snapshot_transforms(current_grid)
			return GridOperations.distort_wave(current_grid, amplitude, frequency, phase, wave_axis)
		
		"distort_restore", "restore":
			return GridOperations.restore_transforms(current_grid)
	
	return false

func _build_modifier_stack_from_config(config: Dictionary) -> Array[Dictionary]:
	var stack_steps: Array[Dictionary] = []
	var stack_raw = str(config.get("stack", "")).strip_edges()
	if stack_raw.is_empty():
		stack_raw = str(config.get("stack_ops", "")).strip_edges()
	if stack_raw.is_empty():
		return stack_steps
	
	var default_radius = _coerce_int(config.get("stack_radius", operation_radius), operation_radius)
	var raw_ops = stack_raw.split(",", false)
	for raw_op in raw_ops:
		var op_name = raw_op.strip_edges().to_lower()
		if op_name.is_empty():
			continue
		
		var params: Dictionary = {"radius": default_radius}
		
		match op_name:
			"array":
				params["direction"] = str(config.get("array_direction", "x"))
				params["count"] = _coerce_int(config.get("array_count", 3), 3)
				params["spacing"] = _coerce_int(config.get("array_spacing", 2), 2)
			"sine":
				params["axis"] = str(config.get("sine_axis", "x"))
				params["amplitude"] = _coerce_float(config.get("sine_amplitude", 2.0), 2.0)
				params["frequency"] = _coerce_float(config.get("sine_frequency", 0.5), 0.5)
			"random":
				params["probability"] = _coerce_float(config.get("random_probability", 0.3), 0.3)
			"ca":
				params["rule"] = str(config.get("ca_rule", "growth"))
			"mirror":
				params["axis"] = str(config.get("mirror_axis", "x"))
				params["keep_original"] = _coerce_bool(config.get("mirror_keep_original", true), true)
			"twist":
				params["axis"] = str(config.get("twist_axis", "y"))
				params["angle_degrees"] = _coerce_float(config.get("twist_angle", 15.0), 15.0)
			"translate":
				params["direction"] = str(config.get("translate_direction", "x"))
				params["distance"] = _coerce_int(config.get("translate_distance", 2), 2)
			"rotate":
				params["axis"] = str(config.get("rotate_axis", "y"))
			"scale":
				params["factor"] = _coerce_float(config.get("scale_factor", 1.5), 1.5)
			"distort_explode", "explode":
				params["strength"] = _coerce_float(config.get("explode_strength", 3.0), 3.0)
			"distort_twist":
				params["axis"] = str(config.get("distort_twist_axis", "y"))
				params["angle_per_unit"] = _coerce_float(config.get("distort_twist_angle", 15.0), 15.0)
			"distort_scatter", "scatter":
				params["scatter_strength"] = _coerce_float(config.get("scatter_strength", 2.0), 2.0)
				params["rotation_strength"] = _coerce_float(config.get("scatter_rotation", 45.0), 45.0)
			"distort_wave":
				params["amplitude"] = _coerce_float(config.get("wave_amplitude", 1.5), 1.5)
				params["frequency"] = _coerce_float(config.get("wave_frequency", 0.5), 0.5)
				params["phase"] = _coerce_float(config.get("wave_phase", 0.0), 0.0)
				params["axis"] = str(config.get("wave_axis", "y"))
		
		stack_steps.append({"op": op_name, "params": params})
	
	return stack_steps

func _axis_to_vector(axis_name: String) -> Vector3i:
	match axis_name.strip_edges().to_lower():
		"x":
			return Vector3i(1, 0, 0)
		"z":
			return Vector3i(0, 0, 1)
		_:
			return Vector3i(0, 1, 0)

func _parse_direction(value: String, fallback: Vector3i) -> Vector3i:
	var dir = value.strip_edges().to_lower()
	match dir:
		"x", "+x", "east":
			return Vector3i(1, 0, 0)
		"-x", "west":
			return Vector3i(-1, 0, 0)
		"y", "+y", "up":
			return Vector3i(0, 1, 0)
		"-y", "down":
			return Vector3i(0, -1, 0)
		"z", "+z", "north":
			return Vector3i(0, 0, 1)
		"-z", "south":
			return Vector3i(0, 0, -1)
	return fallback

func _coerce_float(value, fallback: float) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	var text = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback

func _coerce_int(value, fallback: int) -> int:
	if value is int:
		return value
	if value is float:
		return int(round(value))
	var text = str(value).strip_edges()
	if text.is_valid_float():
		return int(round(float(text)))
	return fallback

func _coerce_bool(value, fallback: bool) -> bool:
	if value is bool:
		return value
	var text = str(value).strip_edges().to_lower()
	if text in ["1", "true", "yes", "on"]:
		return true
	if text in ["0", "false", "no", "off"]:
		return false
	return fallback

# ===== State Management =====

func _change_state(new_state: AgentState):
	current_state = new_state
	state_timer = 0.0

func _choose_new_wander_direction():
	# Pick a random direction (grid-aligned)
	var directions = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 1, 0), Vector3(0, -1, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1)
	]
	wander_direction = directions[randi() % directions.size()]

func _update_thought_label():
	if not thought_label:
		return
	
	var thought = ""
	match current_state:
		AgentState.WANDERING:
			thought = "Searching..."
		AgentState.FEEDING:
			thought = "Consuming (XP: %d)" % evolution_xp
		AgentState.WORKING:
			thought = EvolutionTiers.get_description(current_tier)
		AgentState.CAPTURED:
			thought = "Captured - Ready"
		AgentState.DIRECTED:
			thought = "Executing task..."
	
	thought_label.text = thought

# ===== Public API =====

func set_tier(tier_str: String):
	"""Set agent tier from string (called from GridInteractablesComponent)"""
	current_tier = EvolutionTiers.parse_tier(tier_str)
	base_color = EvolutionTiers.get_color(current_tier)
	if is_node_ready():
		_update_visual_tier()

func configure_modifier_stack(config: Dictionary) -> void:
	"""Configure a Blender-like ordered operation stack from map config."""
	var enabled = _coerce_bool(config.get("stack_enabled", true), true)
	if not enabled:
		modifier_stack.clear()
		return
	
	modifier_stack = _build_modifier_stack_from_config(config)
	if not modifier_stack.is_empty():
		print("GridAgent: Configured modifier stack (%d steps)" % modifier_stack.size())

func capture():
	"""Called by algo-gun when capturing agent"""
	_change_state(AgentState.CAPTURED)

func release():
	"""Called by algo-gun when releasing agent"""
	_change_state(AgentState.WANDERING)

func direct_to_position(target: Vector3):
	"""Called by algo-gun to direct agent to specific location"""
	target_position = target
	has_target = true
	_change_state(AgentState.DIRECTED)

func add_xp(amount: int):
	"""Award evolution points"""
	evolution_xp += amount
	var max_tier = EvolutionTiers.get_max_tier_for_xp(evolution_xp)
	if max_tier > current_tier:
		# Tier up!
		current_tier = max_tier
		_update_visual_tier()
		print("GridAgent: Evolved to %s!" % EvolutionTiers.get_display_name(current_tier))
