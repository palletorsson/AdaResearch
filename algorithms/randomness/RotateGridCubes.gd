extends Node3D

## RotateGridCubes.gd
## Rotates all MultiMesh instances
## Syntax: Z, X, Y rotation in degrees, then Z, X, Y continuous rotation flags

# Initial rotation configuration (Z, X, Y order)
@export_group("Initial Rotation")
@export var rotation_z_degrees: float = 0.0  # Rotation around Z axis (roll)
@export var rotation_x_degrees: float = 45.0  # Rotation around X axis (pitch)
@export var rotation_y_degrees: float = 0.0  # Rotation around Y axis (yaw)

# Continuous rotation configuration
@export_group("Continuous Rotation")
@export var continuous_rotation_z: bool = false  # Spin on Z axis
@export var continuous_rotation_x: bool = false  # Spin on X axis
@export var continuous_rotation_y: bool = false  # Spin on Y axis
@export var rotation_speed_z: float = 30.0  # Degrees per second
@export var rotation_speed_x: float = 30.0  # Degrees per second
@export var rotation_speed_y: float = 30.0  # Degrees per second

# Alternating/offset patterns - creates gaps even with high rotation
@export_group("Rotation Patterns")
@export var alternating_x: bool = false  # Alternate X rotation direction (checkerboard)
@export var alternating_y: bool = false  # Alternate Y rotation direction
@export var alternating_z: bool = false  # Alternate Z rotation direction
@export var phase_offset_enabled: bool = false  # Stagger rotation by position
@export var phase_offset_degrees: float = 45.0  # How much to offset per row/column
@export_enum("Row (X)", "Column (Z)", "Diagonal", "Radial") var phase_offset_mode: int = 0

# Gradient - rotation increases across the grid
@export_group("Gradient")
@export var gradient_enabled: bool = false  # Enable gradient rotation
@export var gradient_start: float = 0.0  # Starting rotation (degrees)
@export var gradient_end: float = 45.0  # Ending rotation (degrees)
@export var gradient_auto_max: bool = false  # Auto-calculate max based on Z rotation
@export var gradient_bell_curve: bool = false  # Bell curve: 0 at edges, max in middle
@export var gradient_flip: bool = false  # Flip rotation direction (negative)
@export var max_walkable_slope: float = 45.0  # Player's max slope (for auto calculation)
@export_enum("Z (forward)", "X (sideways)", "Diagonal", "Radial") var gradient_axis: int = 0

# Burst Pattern - alternating rotated/flat sections
@export_group("Burst Pattern")
@export var burst_mode: bool = true  # Enable burst pattern (overrides gradient)
@export var burst_rotate_count: int = 3  # Rows of rotation before flat section
@export var burst_flat_count: int = 3  # Rows of flat (0°) cubes between bursts
@export_enum("Z (forward)", "X (sideways)") var burst_axis: int = 0  # Which axis to measure rows

# Wave Pattern - repeating gradient (0 → max → 0) with flat gaps
@export_group("Wave Pattern")
@export var wave_mode: bool = false  # Enable wave pattern (overrides burst/gradient)
@export var wave_rows: int = 5  # Rows for one wave cycle (0 → max → 0)
@export var wave_flat_rows: int = 2  # Flat rows between waves
@export var wave_max_rotation: float = 20.0  # Peak rotation at center of wave
@export_enum("Z (forward)", "X (sideways)") var wave_axis: int = 0  # Which axis for wave

# Animation settings
@export_group("Animation")
@export var rotate_on_ready: bool = true
@export var rotation_duration: float = 1.0  # Animation duration in seconds
@export var use_animation: bool = true

@export_group("MultiMesh")
@export var multimesh_path: NodePath = "../GridMultiMesh"

# Internal
var target_rotation_degrees: Vector3 = Vector3.ZERO
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var animation_tween: Tween = null
var initial_transforms: Array[Transform3D] = []

func _ready():
	# Build target rotation from Z, X, Y components
	target_rotation_degrees = Vector3(rotation_x_degrees, rotation_y_degrees, rotation_z_degrees)

	# Find MultiMesh
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)

	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("✅ Found MultiMesh with %d instances" % multimesh.instance_count)

			# Store initial transforms
			for i in range(multimesh.instance_count):
				initial_transforms.append(multimesh.get_instance_transform(i))

			if rotate_on_ready:
				rotate_all_cubes()
		else:
			push_warning("MultiMesh found but has no instances")
	else:
		push_warning("Could not find MultiMeshInstance3D")

func _find_multimesh_instance(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_multimesh_instance(child)
		if result:
			return result
	return null

func rotate_all_cubes():
	"""Rotate all cubes in the MultiMesh"""
	if not multimesh:
		print("RotateGridCubes: No MultiMesh found")
		return

	print("RotateGridCubes: Rotating %d instances (Z=%s°, X=%s°, Y=%s°)" % [
		multimesh.instance_count,
		rotation_z_degrees,
		rotation_x_degrees,
		rotation_y_degrees
	])
	if burst_mode:
		var axis_name = "Z (forward)" if burst_axis == 0 else "X (sideways)"
		print("RotateGridCubes: Burst mode - %d rotated rows, %d flat rows, axis=%s" % [
			burst_rotate_count, burst_flat_count, axis_name
		])
	elif gradient_enabled:
		var end_info = str(gradient_end) + "°"
		if gradient_auto_max:
			var auto_max = get_max_x_rotation(rotation_z_degrees, max_walkable_slope)
			end_info = "auto(%.1f° for Z=%.1f°)" % [auto_max, rotation_z_degrees]
		print("RotateGridCubes: Gradient enabled - start=%s°, end=%s, axis=%s, transforms=%d" % [
			gradient_start, end_info, gradient_axis, initial_transforms.size()
		])

	if use_animation:
		animate_rotation()
	else:
		apply_instant_rotation()

	print("RotateGridCubes: Rotation complete")

func apply_instant_rotation():
	"""Apply rotation instantly to all instances"""
	if not multimesh:
		return

	var min_rot_x = INF
	var max_rot_x = -INF

	for i in range(multimesh.instance_count):
		var transform = initial_transforms[i] if i < initial_transforms.size() else multimesh.get_instance_transform(i)
		var pos = transform.origin

		# Calculate rotation for this specific cube
		var rot = _get_rotation_for_position(pos, i, Vector3(rotation_x_degrees, rotation_y_degrees, rotation_z_degrees))

		# Track rotation range for debug
		min_rot_x = min(min_rot_x, rot.x)
		max_rot_x = max(max_rot_x, rot.x)

		var rot_basis = Basis()
		rot_basis = rot_basis.rotated(Vector3.BACK, deg_to_rad(rot.z))
		rot_basis = rot_basis.rotated(Vector3.RIGHT, deg_to_rad(rot.x))
		rot_basis = rot_basis.rotated(Vector3.UP, deg_to_rad(rot.y))

		transform.basis = rot_basis * Basis()
		multimesh.set_instance_transform(i, transform)

	if gradient_enabled:
		print("RotateGridCubes: Applied gradient - X rotation range: %.1f° to %.1f°" % [min_rot_x, max_rot_x])

func _get_rotation_for_position(pos: Vector3, index: int, base_rot: Vector3) -> Vector3:
	"""Calculate rotation for a specific cube based on position and pattern settings"""
	var rot = base_rot

	# Determine grid position (rough estimate based on position)
	var grid_x = int(round(pos.x))
	var grid_z = int(round(pos.z))
	var is_alternate = (grid_x + grid_z) % 2 == 1  # Checkerboard pattern

	# Apply wave pattern - repeating gradient (0 → max → 0) with flat gaps
	if wave_mode:
		var row_index: int
		if wave_axis == 0:  # Z (forward)
			row_index = grid_z
		else:  # X (sideways)
			row_index = grid_x
		
		# Normalize to positive
		if row_index < 0:
			row_index = -row_index
		
		# Calculate position in wave cycle
		var cycle_length = wave_rows + wave_flat_rows
		var pos_in_cycle = row_index % cycle_length
		
		if pos_in_cycle < wave_rows:
			# In wave section - apply bell curve (0 → max → 0)
			# t goes from 0 to 1 across wave_rows
			var t = float(pos_in_cycle) / float(wave_rows - 1) if wave_rows > 1 else 0.5
			# Bell curve using sin: peaks at t=0.5
			var wave_factor = sin(t * PI)
			rot.x = wave_max_rotation * wave_factor
		else:
			# In flat section
			rot.x = 0.0
		
		# Wave mode overrides burst/gradient, skip to alternating patterns
	# Apply burst pattern - alternating rotated/flat sections
	elif burst_mode:
		# Determine which row we're in based on burst_axis
		var row_index: int
		if burst_axis == 0:  # Z (forward)
			row_index = grid_z
		else:  # X (sideways)
			row_index = grid_x
		
		# Normalize to positive values for modulo
		if row_index < 0:
			row_index = -row_index
		
		# Determine position in the burst cycle
		var cycle_length = burst_rotate_count + burst_flat_count
		var pos_in_cycle = row_index % cycle_length
		var is_rotating = pos_in_cycle < burst_rotate_count
		
		if not is_rotating:
			# Flat section - set rotation to zero
			rot = Vector3.ZERO
		# else: keep the base_rot for rotating sections
		
		# Skip gradient if burst mode is active (burst overrides gradient)
	elif gradient_enabled:
		var t = _get_gradient_factor(grid_x, grid_z)

		# Bell curve: transform t from linear (0→1) to bell (0→1→0)
		# Uses sin(t * PI) which peaks at t=0.5
		if gradient_bell_curve:
			t = sin(t * PI)

		var actual_end = gradient_end
		# Auto-calculate max X rotation based on Z rotation
		if gradient_auto_max:
			actual_end = get_max_x_rotation(rot.z, max_walkable_slope)
		var gradient_rot = lerp(gradient_start, actual_end, t)

		# Flip direction (negative rotation for player coming from -z)
		if gradient_flip:
			gradient_rot = -gradient_rot

		# Apply gradient to X rotation (pitch/slope)
		rot.x = gradient_rot

	# Apply alternating patterns (flip direction for alternate cubes)
	if alternating_x and is_alternate:
		rot.x = -rot.x
	if alternating_y and is_alternate:
		rot.y = -rot.y
	if alternating_z and is_alternate:
		rot.z = -rot.z

	# Apply phase offset
	if phase_offset_enabled:
		var offset = 0.0
		match phase_offset_mode:
			0:  # Row (X)
				offset = grid_x * phase_offset_degrees
			1:  # Column (Z)
				offset = grid_z * phase_offset_degrees
			2:  # Diagonal
				offset = (grid_x + grid_z) * phase_offset_degrees
			3:  # Radial
				offset = sqrt(grid_x * grid_x + grid_z * grid_z) * phase_offset_degrees

		# Apply offset to all active rotation axes
		if rotation_x_degrees != 0:
			rot.x += offset
		if rotation_y_degrees != 0:
			rot.y += offset
		if rotation_z_degrees != 0:
			rot.z += offset

	return rot

func get_max_x_rotation(z_deg: float, max_slope: float = 45.0) -> float:
	"""Calculate maximum X rotation that keeps slope walkable given Z rotation"""
	if abs(z_deg) >= max_slope:
		return 0.0  # Z alone exceeds max slope
	var z_rad = deg_to_rad(z_deg)
	var max_slope_rad = deg_to_rad(max_slope)
	return rad_to_deg(acos(cos(max_slope_rad) / cos(z_rad)))

func _get_gradient_factor(grid_x: float, grid_z: float) -> float:
	"""Calculate gradient interpolation factor (0-1) based on position"""
	# Get grid bounds from initial transforms
	if initial_transforms.is_empty():
		print("RotateGridCubes: WARNING - initial_transforms is empty, gradient will be 0")
		return 0.0

	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF

	for transform in initial_transforms:
		var p = transform.origin
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_z = min(min_z, p.z)
		max_z = max(max_z, p.z)

	var t = 0.0
	match gradient_axis:
		0:  # Z (forward) - gradient along depth
			if max_z > min_z:
				t = (grid_z - min_z) / (max_z - min_z)
		1:  # X (sideways)
			if max_x > min_x:
				t = (grid_x - min_x) / (max_x - min_x)
		2:  # Diagonal
			var max_diag = (max_x - min_x) + (max_z - min_z)
			if max_diag > 0:
				t = ((grid_x - min_x) + (grid_z - min_z)) / max_diag
		3:  # Radial (from center)
			var center_x = (min_x + max_x) / 2.0
			var center_z = (min_z + max_z) / 2.0
			var max_dist = sqrt(pow(max_x - center_x, 2) + pow(max_z - center_z, 2))
			if max_dist > 0:
				var dist = sqrt(pow(grid_x - center_x, 2) + pow(grid_z - center_z, 2))
				t = dist / max_dist

	return clamp(t, 0.0, 1.0)

func animate_rotation():
	"""Animate rotation with interpolation"""
	if not multimesh or animation_tween:
		return

	animation_tween = create_tween()
	var start_rot = Vector3.ZERO
	var target_rot = target_rotation_degrees

	animation_tween.tween_method(func(progress: float):
		var current_base_rot = start_rot.lerp(target_rot, progress)

		for i in range(multimesh.instance_count):
			var transform = initial_transforms[i] if i < initial_transforms.size() else Transform3D()
			var pos = transform.origin

			# Calculate rotation for this specific cube
			var current_rot = _get_rotation_for_position(pos, i, current_base_rot)

			var rot_basis = Basis()
			rot_basis = rot_basis.rotated(Vector3.BACK, deg_to_rad(current_rot.z))
			rot_basis = rot_basis.rotated(Vector3.RIGHT, deg_to_rad(current_rot.x))
			rot_basis = rot_basis.rotated(Vector3.UP, deg_to_rad(current_rot.y))

			transform.basis = rot_basis * Basis()
			multimesh.set_instance_transform(i, transform)
	, 0.0, 1.0, rotation_duration)

	animation_tween.set_ease(Tween.EASE_IN_OUT)
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	animation_tween.finished.connect(func(): animation_tween = null)

func _process(delta: float) -> void:
	if not multimesh:
		return

	# Handle continuous rotation
	if continuous_rotation_z or continuous_rotation_x or continuous_rotation_y:
		for i in range(multimesh.instance_count):
			var transform = multimesh.get_instance_transform(i)
			var pos = initial_transforms[i].origin if i < initial_transforms.size() else transform.origin

			# Determine direction multiplier for alternating patterns
			var grid_x = int(round(pos.x))
			var grid_z = int(round(pos.z))
			var is_alternate = (grid_x + grid_z) % 2 == 1

			var dir_x = -1.0 if (alternating_x and is_alternate) else 1.0
			var dir_y = -1.0 if (alternating_y and is_alternate) else 1.0
			var dir_z = -1.0 if (alternating_z and is_alternate) else 1.0

			if continuous_rotation_z:
				transform.basis = transform.basis.rotated(Vector3.BACK, deg_to_rad(rotation_speed_z * delta * dir_z))
			if continuous_rotation_x:
				transform.basis = transform.basis.rotated(Vector3.RIGHT, deg_to_rad(rotation_speed_x * delta * dir_x))
			if continuous_rotation_y:
				transform.basis = transform.basis.rotated(Vector3.UP, deg_to_rad(rotation_speed_y * delta * dir_y))

			multimesh.set_instance_transform(i, transform)

# Public API for manual control

func rotate_cubes_instant_zxy(z: float, x: float, y: float):
	"""Rotate all cubes instantly to specified degrees (Z, X, Y order)"""
	rotation_z_degrees = z
	rotation_x_degrees = x
	rotation_y_degrees = y
	target_rotation_degrees = Vector3(x, y, z)
	use_animation = false
	rotate_all_cubes()

func rotate_cubes_animated_zxy(z: float, x: float, y: float, duration: float = 1.0):
	"""Rotate all cubes with animation to specified degrees (Z, X, Y order)"""
	rotation_z_degrees = z
	rotation_x_degrees = x
	rotation_y_degrees = y
	target_rotation_degrees = Vector3(x, y, z)
	rotation_duration = duration
	use_animation = true
	rotate_all_cubes()

func set_continuous_rotation(cont_z: bool, cont_x: bool, cont_y: bool):
	"""Enable/disable continuous rotation on specified axes"""
	continuous_rotation_z = cont_z
	continuous_rotation_x = cont_x
	continuous_rotation_y = cont_y

func reset_rotation():
	"""Reset all cubes to zero rotation"""
	rotation_z_degrees = 0.0
	rotation_x_degrees = 0.0
	rotation_y_degrees = 0.0
	target_rotation_degrees = Vector3.ZERO
	rotate_all_cubes()

# Grid artifact configuration API
func apply_grid_config(config: Dictionary) -> void:
	"""Apply configuration from map JSON using # syntax"""
	print("RotateGridCubes: Applying grid config: %s" % str(config))

	# Initial rotation (rot_x, rot_y, rot_z)
	if config.has("rot_x"):
		rotation_x_degrees = float(config["rot_x"])
	if config.has("rot_y"):
		rotation_y_degrees = float(config["rot_y"])
	if config.has("rot_z"):
		rotation_z_degrees = float(config["rot_z"])

	# Alternating patterns (alt_x, alt_y, alt_z)
	if config.has("alt_x"):
		alternating_x = str(config["alt_x"]).to_lower() == "true"
	if config.has("alt_y"):
		alternating_y = str(config["alt_y"]).to_lower() == "true"
	if config.has("alt_z"):
		alternating_z = str(config["alt_z"]).to_lower() == "true"

	# Phase offset (phase, phase_deg, phase_mode)
	if config.has("phase"):
		phase_offset_enabled = str(config["phase"]).to_lower() == "true"
	if config.has("phase_deg"):
		phase_offset_degrees = float(config["phase_deg"])
	if config.has("phase_mode"):
		var mode_str = str(config["phase_mode"]).to_lower()
		match mode_str:
			"row", "x", "0": phase_offset_mode = 0
			"column", "col", "z", "1": phase_offset_mode = 1
			"diagonal", "diag", "2": phase_offset_mode = 2
			"radial", "rad", "3": phase_offset_mode = 3

	# Continuous rotation (spin_x, spin_y, spin_z, speed_x, speed_y, speed_z)
	if config.has("spin_x"):
		continuous_rotation_x = str(config["spin_x"]).to_lower() == "true"
	if config.has("spin_y"):
		continuous_rotation_y = str(config["spin_y"]).to_lower() == "true"
	if config.has("spin_z"):
		continuous_rotation_z = str(config["spin_z"]).to_lower() == "true"
	if config.has("speed_x"):
		rotation_speed_x = float(config["speed_x"])
	if config.has("speed_y"):
		rotation_speed_y = float(config["speed_y"])
	if config.has("speed_z"):
		rotation_speed_z = float(config["speed_z"])

	# Animation settings
	if config.has("animate"):
		use_animation = str(config["animate"]).to_lower() == "true"
	if config.has("duration"):
		rotation_duration = float(config["duration"])

	# Burst pattern settings (burst, burst_rotate, burst_flat, burst_axis)
	if config.has("burst"):
		burst_mode = str(config["burst"]).to_lower() == "true"
	if config.has("burst_rotate"):
		burst_rotate_count = int(config["burst_rotate"])
	if config.has("burst_flat"):
		burst_flat_count = int(config["burst_flat"])
	if config.has("burst_axis"):
		var axis_str = str(config["burst_axis"]).to_lower()
		match axis_str:
			"z", "forward", "0": burst_axis = 0
			"x", "sideways", "1": burst_axis = 1

	# Wave pattern settings (wave, wave_rows, wave_flat, wave_max, wave_axis)
	if config.has("wave"):
		wave_mode = str(config["wave"]).to_lower() == "true"
		# Wave mode overrides burst
		if wave_mode:
			burst_mode = false
	if config.has("wave_rows"):
		wave_rows = int(config["wave_rows"])
	if config.has("wave_flat"):
		wave_flat_rows = int(config["wave_flat"])
	if config.has("wave_max"):
		wave_max_rotation = float(config["wave_max"])
	if config.has("wave_axis"):
		var axis_str = str(config["wave_axis"]).to_lower()
		match axis_str:
			"z", "forward", "0": wave_axis = 0
			"x", "sideways", "1": wave_axis = 1

	# Gradient settings (grad, grad_start, grad_end, grad_axis, grad_auto, max_slope, bell, flip)
	if config.has("grad"):
		gradient_enabled = str(config["grad"]).to_lower() == "true"
	if config.has("grad_start"):
		gradient_start = float(config["grad_start"])
	if config.has("grad_end"):
		gradient_end = float(config["grad_end"])
	if config.has("grad_auto"):
		gradient_auto_max = str(config["grad_auto"]).to_lower() == "true"
	if config.has("bell"):
		gradient_bell_curve = str(config["bell"]).to_lower() == "true"
	if config.has("flip"):
		gradient_flip = str(config["flip"]).to_lower() == "true"
	if config.has("max_slope"):
		max_walkable_slope = float(config["max_slope"])
	if config.has("grad_axis"):
		var axis_str = str(config["grad_axis"]).to_lower()
		match axis_str:
			"z", "forward", "0": gradient_axis = 0
			"x", "sideways", "1": gradient_axis = 1
			"diagonal", "diag", "2": gradient_axis = 2
			"radial", "rad", "3": gradient_axis = 3

	# Update target and re-apply rotation
	target_rotation_degrees = Vector3(rotation_x_degrees, rotation_y_degrees, rotation_z_degrees)

	# Collision handling
	if config.has("no_collision") and str(config["no_collision"]).to_lower() == "true":
		_disable_grid_collisions()
	elif config.has("rotate_collision") and str(config["rotate_collision"]).to_lower() == "true":
		# Will rotate collisions after applying visual rotation
		pass

	# Re-apply if already initialized
	if multimesh and multimesh.instance_count > 0:
		rotate_all_cubes()

	# Rotate collisions to match visuals (after rotate_all_cubes sets up transforms)
	if config.has("rotate_collision") and str(config["rotate_collision"]).to_lower() == "true":
		call_deferred("_rotate_grid_collisions")

func _disable_grid_collisions() -> void:
	"""Disable collision shapes in the grid so players can walk through rotated cubes"""
	var collision_parent = get_parent().get_node_or_null("GridCollisions")
	if collision_parent:
		for child in collision_parent.get_children():
			if child is StaticBody3D:
				child.collision_layer = 0
				child.collision_mask = 0
		print("RotateGridCubes: Disabled grid collisions")

func _rotate_grid_collisions() -> void:
	"""Rotate collision shapes to match the visual cube rotations"""
	var collision_parent = get_parent().get_node_or_null("GridCollisions")
	if not collision_parent:
		print("RotateGridCubes: No GridCollisions found")
		return

	var rotated_count = 0
	for child in collision_parent.get_children():
		if child is StaticBody3D:
			var pos = child.position
			var grid_x = int(round(pos.x))
			var grid_z = int(round(pos.z))

			# Calculate the same rotation as the visual cube
			var rot = _get_rotation_for_position(pos, rotated_count, Vector3(rotation_x_degrees, rotation_y_degrees, rotation_z_degrees))

			# Apply rotation to collision body
			child.rotation_degrees = Vector3(rot.x, rot.y, rot.z)
			rotated_count += 1

	print("RotateGridCubes: Rotated %d collision shapes" % rotated_count)
