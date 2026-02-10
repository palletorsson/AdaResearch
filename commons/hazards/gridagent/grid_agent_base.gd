# grid_agent_base.gd
# Base class for Grid Agents - algorithmic entities that traverse and modify grid structures
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
