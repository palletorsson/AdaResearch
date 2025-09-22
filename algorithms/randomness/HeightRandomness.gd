class_name HeightRandomnessAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = ""
var algorithm_description: String = ""
var grid_reference = null
var max_steps: int = 1000

# Height properties
@export var raise_amount: float = 0.5
var total_raises: int = 0
@export var max_raises: int = 150
@export var max_height: float = 10.0  # Maximum height cubes can reach
@export var min_height: float = 0.0   # Minimum height for cubes
@export var height_variation: float = 0.2  # Random variation in raise amount

# 8x8 area bounds in the middle of 11x16 map
@export var region_min_x: int = 2
@export var region_max_x: int = 9
@export var region_min_z: int = 4
@export var region_max_z: int = 11
@export var target_y_level: int = 1

# Node3D properties
@export var auto_start: bool = true
@export var step_delay: float = 0.15
@export var auto_loop: bool = true  # Automatically restart when finished
@export var loop_delay: float = 2.0  # Delay before restarting (seconds)
@export var enable_visual_feedback: bool = true  # Show visual effects during raising
@export var enable_sound_feedback: bool = true  # Play sounds during raising

var timer: Timer
var loop_timer: Timer
var is_running: bool = false
var cube_heights: Dictionary = {}  # Track individual cube heights
var audio_player: AudioStreamPlayer3D

# Signals
signal algorithm_step_complete()
signal algorithm_finished()

func _init():
	algorithm_name = "Height Distribution (8x8 Region)"
	algorithm_description = "Random height distribution in middle 8x8 area with auto-loop capability"
	max_steps = max_raises

func _ready():
	# Create timer for stepping
	timer = Timer.new()
	timer.wait_time = step_delay
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Create timer for looping
	loop_timer = Timer.new()
	loop_timer.wait_time = loop_delay
	loop_timer.one_shot = true
	loop_timer.timeout.connect(_on_loop_timer_timeout)
	add_child(loop_timer)
	
	# Setup audio player for feedback
	_setup_audio_player()
	
	# Auto-connect to grid system
	call_deferred("_find_and_connect_grid")
	
	if auto_start:
		call_deferred("start_algorithm")

func _find_and_connect_grid():
	# Look for GridSystem in the scene
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		# Try finding by class name
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		set_grid_reference(grid_system)
		print("HeightRandomnessAlgorithm: Connected to grid system")
	else:
		print("HeightRandomnessAlgorithm: WARNING - Could not find GridSystem!")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

func _setup_audio_player():
	"""Setup audio player for cube raising feedback"""
	if enable_sound_feedback:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.unit_size = 2.0
		audio_player.max_distance = 20.0
		audio_player.volume_db = -10.0
		add_child(audio_player)
		
		# Generate a simple rising tone
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 44100
		var data = PackedByteArray()
		var length = 0.1
		var samples = int(length * 44100)
		data.resize(samples * 2)
		
		for i in range(samples):
			var t = float(i) / 44100.0
			var frequency = 200.0 + (t / length) * 100.0  # Rising frequency
			var envelope = 0.3 * (1.0 - t / length)
			var sample_value = envelope * sin(TAU * frequency * t)
			var sample_int = int(clamp(sample_value, -1.0, 1.0) * 32767.0)
			data.encode_s16(i * 2, sample_int)
		
		stream.data = data
		audio_player.stream = stream

func start_algorithm():
	if not grid_reference:
		print("HeightRandomnessAlgorithm: Cannot start - grid not ready")
		return
	
	setup_initial_state()
	is_running = true
	timer.start()
	print("HeightRandomnessAlgorithm: Algorithm started")

func stop_algorithm():
	is_running = false
	timer.stop()
	loop_timer.stop()  # Also stop the loop timer
	print("HeightRandomnessAlgorithm: Algorithm stopped")

func set_auto_loop(enabled: bool):
	"""Enable or disable automatic looping"""
	auto_loop = enabled
	print("HeightRandomnessAlgorithm: Auto-loop %s" % ("enabled" if enabled else "disabled"))

func step_once():
	if not grid_reference:
		return false
	
	var result = execute_step()
	algorithm_step_complete.emit()
	
	if not result:
		stop_algorithm()
		algorithm_finished.emit()
		
		# Start loop timer if auto_loop is enabled
		if auto_loop:
			print("HeightRandomnessAlgorithm: Algorithm finished, restarting in %.1f seconds..." % loop_delay)
			loop_timer.start()
	
	return result

func _on_timer_timeout():
	if is_running:
		step_once()

func _on_loop_timer_timeout():
	"""Called when it's time to restart the algorithm"""
	if auto_loop:
		reset_algorithm()
		start_algorithm()

func reset_algorithm():
	"""Reset the algorithm to its initial state"""
	if not grid_reference:
		return
	
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	print("HeightRandomnessAlgorithm: Resetting cubes to base level...")
	
	# Reset all cubes in the region back to their base positions
	for x in range(region_min_x, region_max_x + 1):
		for z in range(region_min_z, region_max_z + 1):
			var cube = structure_component.get_cube_at(x, target_y_level, z)
			if cube:
				# Reset to original position using GridCommon utility
				var grid_pos = Vector3i(x, target_y_level, z)
				var world_pos = GridCommon.grid_to_world_position(grid_pos, structure_component.cube_size, structure_component.gutter)
				cube.position = world_pos
	
	# Reset counters and height tracking
	total_raises = 0
	cube_heights.clear()
	
	print("HeightRandomnessAlgorithm: Reset complete - ready to restart")

func setup_initial_state():
	# Ensure there are base cubes in the 8x8 region
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Add base cubes in the region at target Y level if they don't exist
	for x in range(region_min_x, region_max_x + 1):
		for z in range(region_min_z, region_max_z + 1):
			if not structure_component.has_cube_at(x, target_y_level, z):
				_place_cube_at(x, target_y_level, z)
	
	total_raises = 0
	print("HeightRandomness: Initialized 8x8 region with base cubes")

func execute_step() -> bool:
	if total_raises >= max_raises:
		return false
	
	# Choose random position within the 8x8 region
	var rand_x = randi_range(region_min_x, region_max_x)
	var rand_z = randi_range(region_min_z, region_max_z)
	
	# Raise the cube at this position
	_raise_cube(rand_x, rand_z)
	total_raises += 1
	
	return total_raises < max_raises

# Set grid reference for the algorithm to work with
func set_grid_reference(grid_ref):
	grid_reference = grid_ref

func _raise_cube(x: int, z: int):
	if not grid_reference:
		return
	
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Get the cube at target Y level position
	var cube = structure_component.get_cube_at(x, target_y_level, z)
	if not cube:
		return
	
	# Calculate current height for this cube
	var cube_key = str(x) + "," + str(z)
	var current_height = cube_heights.get(cube_key, 0.0)
	
	# Check height limits
	if current_height >= max_height:
		# Try to find a different cube to raise
		_try_raise_different_cube()
		return
	
	# Calculate raise amount with variation
	var actual_raise = raise_amount + randf_range(-height_variation, height_variation)
	actual_raise = max(0.1, actual_raise)  # Ensure minimum raise
	
	# Apply the raise
	cube.position.y += actual_raise
	cube_heights[cube_key] = current_height + actual_raise
	
	# Visual feedback
	if enable_visual_feedback:
		_add_visual_effect(cube.global_position)
	
	# Audio feedback
	if enable_sound_feedback and audio_player:
		audio_player.global_position = cube.global_position
		audio_player.pitch_scale = 0.8 + (current_height / max_height) * 0.4  # Higher pitch for higher cubes
		audio_player.play()
	
	print("HeightRandomness: Raised cube at (%d, %d) to height %.2f" % [x, z, cube_heights[cube_key]])

func _try_raise_different_cube():
	"""Try to find a different cube that hasn't reached max height"""
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		var rand_x = randi_range(region_min_x, region_max_x)
		var rand_z = randi_range(region_min_z, region_max_z)
		var cube_key = str(rand_x) + "," + str(rand_z)
		var current_height = cube_heights.get(cube_key, 0.0)
		
		if current_height < max_height:
			_raise_cube(rand_x, rand_z)
			return
		
		attempts += 1
	
	# If no suitable cube found, reduce max height slightly
	max_height = max(min_height + 1.0, max_height - 0.5)
	print("HeightRandomness: Reduced max height to %.2f" % max_height)

func _add_visual_effect(position: Vector3):
	"""Add a visual effect at the cube position"""
	if not enable_visual_feedback:
		return
	
	# Create a temporary particle effect
	var effect = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	effect.mesh = sphere_mesh
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.2, 0.8, 1.0, 1.0)
	material.emission_energy = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.6
	effect.material_override = material
	
	effect.global_position = position + Vector3(0, 0.5, 0)
	add_child(effect)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector3(2.0, 2.0, 2.0), 0.3)
	tween.parallel().tween_property(effect, "global_position", effect.global_position + Vector3(0, 1.0, 0), 0.3)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

# Place a cube at specific 3D coordinates
func _place_cube_at(x: int, y: int, z: int):
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Check if cube already exists
	if structure_component.has_cube_at(x, y, z):
		return
	
	# Create new cube using the grid system's method
	var total_size = structure_component.cube_size + structure_component.gutter
	structure_component._add_cube(x, y, z, total_size)
	# Don't manipulate grid array directly - let the component handle it

# Get current region bounds for external access
func get_region_bounds() -> Dictionary:
	return {
		"min_x": region_min_x,
		"max_x": region_max_x,
		"min_z": region_min_z,
		"max_z": region_max_z,
		"center_x": (region_min_x + region_max_x) / 2,
		"center_z": (region_min_z + region_max_z) / 2
	}

# Get algorithm info
func get_algorithm_info() -> Dictionary:
	return {
		"name": algorithm_name,
		"description": algorithm_description,
		"max_steps": max_steps,
		"max_raises": max_raises,
		"current_raises": total_raises,
		"raise_amount": raise_amount,
		"max_height": max_height,
		"min_height": min_height,
		"height_variation": height_variation,
		"visual_feedback": enable_visual_feedback,
		"sound_feedback": enable_sound_feedback,
		"auto_loop": auto_loop,
		"loop_delay": loop_delay,
		"is_running": is_running,
		"region_bounds": get_region_bounds(),
		"cube_heights": cube_heights.size()
	}

# Get height statistics for the current state
func get_height_statistics() -> Dictionary:
	var heights = cube_heights.values()
	if heights.is_empty():
		return {"average": 0.0, "max": 0.0, "min": 0.0, "total_cubes": 0}
	
	var total = 0.0
	var max_height_found = 0.0
	var min_height_found = heights[0]
	
	for height in heights:
		total += height
		max_height_found = max(max_height_found, height)
		min_height_found = min(min_height_found, height)
	
	return {
		"average": total / heights.size(),
		"max": max_height_found,
		"min": min_height_found,
		"total_cubes": heights.size(),
		"height_distribution": cube_heights
	}

# Manually continue the rising process (useful for external control)
func continue_rising_process(steps: int = 10):
	"""Continue the rising process for a specific number of steps"""
	if not is_running:
		start_algorithm()
	
	for i in range(steps):
		if total_raises >= max_raises:
			break
		step_once()
		await get_tree().create_timer(step_delay).timeout
