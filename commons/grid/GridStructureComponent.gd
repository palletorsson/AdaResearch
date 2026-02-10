# GridStructureComponent.gd
# Handles cube placement and grid structure building
# Creates the physical 3D layout from structure data using MultiMesh for performance

extends Node
class_name GridStructureComponent

# Grid properties
var grid_x: int
var grid_y: int
var grid_z: int
var grid: Array = []
var cube_positions: Array = []  # Store Vector3i positions for each instance

# References
var base_cube: Node3D
var parent_node: Node3D

# MultiMesh components
var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh

# Cached mesh data (persists across reloads)
var _cached_mesh: Mesh = null
var _cached_material: Material = null

# Collision parent for static bodies
var collision_parent: Node3D

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Animation settings
var animation_enabled: bool = false
var animation_type: String = "scale_up"  # "scale_up", "drop_in", "fade_in", "wave"
var animation_duration: float = 0.3
var animation_delay: float = 0.05
var animation_order: String = "sequential"  # "sequential", "spiral", "random", "wave_x", "wave_z"
var animation_easing: String = "ease_out"

# Animation state
var _animation_in_progress: bool = false
var _pending_cube_data: Array = []  # Stores {index, position, world_pos} for animation

# Group name for all generated cubes (kept for compatibility)
const CUBE_GROUP_NAME = "grid_cubes"

# Signals
signal structure_generation_complete(cube_count: int)
signal animation_started()
signal animation_complete()

func _ready():
	print("GridStructureComponent: Initialized")

# Initialize with references and settings
func initialize(grid_parent: Node3D, cube_template: Node3D, settings: Dictionary = {}):
	parent_node = grid_parent
	
	# Only update base_cube if the template is valid
	if is_instance_valid(cube_template):
		base_cube = cube_template

	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	
	# Apply animation settings if provided
	var anim_settings = settings.get("grid_animation", {})
	if not anim_settings.is_empty():
		animation_enabled = anim_settings.get("enabled", false)
		animation_type = anim_settings.get("type", "scale_up")
		animation_duration = anim_settings.get("duration", 0.3)
		animation_delay = anim_settings.get("delay_between", 0.05)
		animation_order = anim_settings.get("order", "sequential")
		animation_easing = anim_settings.get("easing", "ease_out")
		print("GridStructureComponent: Animation enabled - type=%s, order=%s, duration=%.2f" % [animation_type, animation_order, animation_duration])

	# Create collision parent
	collision_parent = Node3D.new()
	collision_parent.name = "GridCollisions"
	parent_node.add_child(collision_parent)

	# Create MultiMeshInstance3D
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "GridMultiMesh"
	parent_node.add_child(multimesh_instance)

	# Try to extract mesh from base cube, or use cached data
	var mesh_to_use: Mesh = _cached_mesh
	var mat_to_use: Material = _cached_material
	
	if is_instance_valid(base_cube):
		print("GridStructureComponent: Inspecting base_cube: %s" % base_cube)
		_print_tree(base_cube)
		var mesh_instance = _find_mesh_instance(base_cube)
		if mesh_instance:
			print("GridStructureComponent: Found mesh instance: %s" % mesh_instance.name)
			if mesh_instance.mesh:
				mesh_to_use = mesh_instance.mesh
				_cached_mesh = mesh_to_use  # Cache for future reloads
				
				# Get material
				if mesh_instance.material_override:
					mat_to_use = mesh_instance.material_override
				elif mesh_instance.get_surface_override_material_count() > 0:
					mat_to_use = mesh_instance.get_surface_override_material(0)
				elif mesh_instance.mesh.get_surface_count() > 0:
					mat_to_use = mesh_instance.mesh.surface_get_material(0)
				
				if mat_to_use:
					_cached_material = mat_to_use  # Cache for future reloads
		else:
			print("GridStructureComponent: Failed to find mesh instance in %s" % base_cube.name)
	elif _cached_mesh:
		print("GridStructureComponent: Using cached mesh data (base_cube unavailable)")
	else:
		push_error("GridStructureComponent: No base_cube and no cached mesh data!")
		return

	if mesh_to_use:
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true  # Enable per-instance colors BEFORE setting instance_count
		multimesh.use_custom_data = true  # Enable custom data for algorithms like DiscoFloor
		multimesh.mesh = mesh_to_use
		multimesh_instance.multimesh = multimesh

		if mat_to_use:
			# Duplicate material to avoid modifying the original
			var duplicated_mat = mat_to_use.duplicate()
			multimesh_instance.material_override = duplicated_mat

			# If it's a shader material, ensure show_interior is enabled
			if duplicated_mat is ShaderMaterial:
				duplicated_mat.set_shader_parameter("show_interior", true)
		else:
			# Create a basic material if none exists
			var basic_mat = StandardMaterial3D.new()
			basic_mat.albedo_color = Color.WHITE
			multimesh_instance.material_override = basic_mat

		# Apply color overrides from map settings
		if settings.has("color_overrides"):
			var overrides = settings["color_overrides"]
			var override_mat = multimesh_instance.material_override
			print("GridStructureComponent: Applying color overrides: %s" % overrides)

			if override_mat is ShaderMaterial:
				# Map JSON keys to Shader Uniforms
				var key_map = {
					"model_color": "modelColor",
					"wireframe_color": "wireframeColor",
					"emission_color": "emissionColor",
					"emission_strength": "emission_strength",
					"model_opacity": "modelOpacity",
					"wireframe_opacity": "wireframeOpacity",
					"width": "width",
					"blur": "blur"
				}
				
				for key in overrides.keys():
					if key_map.has(key):
						var uniform_name = key_map[key]
						var value = overrides[key]
						
						# Convert string colors to Color types
						if key.ends_with("_color") and value is String:
							value = _parse_color_string(value)
						
						override_mat.set_shader_parameter(uniform_name, value)
						print("  -> Set shader param '%s' = %s" % [uniform_name, str(value)])
					else:
						print("  -> Warning: Unknown override key '%s'" % key)
			
			# Fallback for StandardMaterial3D (unlikely but safe)
			elif override_mat is StandardMaterial3D:
				if overrides.has("model_color"):
					override_mat.albedo_color = _parse_color_string(str(overrides["model_color"]))
					override_mat.emission_enabled = true
					if overrides.has("emission_color"):
						override_mat.emission = _parse_color_string(str(overrides["emission_color"]))
					if overrides.has("emission_strength"):
						override_mat.emission_energy_multiplier = float(overrides["emission_strength"])
	else:
		push_error("GridStructureComponent: Could not find mesh to use")

	print("GridStructureComponent: Initialized with MultiMesh, cube_size=%f, gutter=%f" % [cube_size, gutter])

# Helper to find MeshInstance3D in the base cube hierarchy
func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

# Debug helper to print tree
func _print_tree(node: Node, depth: int = 0):
	if not node: return
	var prefix = "  ".repeat(depth)
	print("%s- %s (%s)" % [prefix, node.name, node.get_class()])
	for child in node.get_children():
		_print_tree(child, depth + 1)

# Generate structure from data
func generate_structure(structure_data, dimensions: Vector3i):
	if not structure_data:
		print("GridStructureComponent: No structure data provided")
		return
		
	# Set dimensions
	grid_x = dimensions.x
	grid_y = dimensions.y
	grid_z = dimensions.z
	
	print("GridStructureComponent: Generating structure %dx%dx%d" % [grid_x, grid_y, grid_z])
	
	# Initialize grid
	_initialize_grid()
	
	# Apply structure data
	_apply_structure_data(structure_data)

# Initialize the 3D grid array
func _initialize_grid():
	print("GridStructureComponent: Initializing grid array")
	grid = []
	cube_positions.clear()

	# Pre-allocate grid
	grid.resize(grid_x)
	for x in grid_x:
		var y_array = []
		y_array.resize(grid_y)
		grid[x] = y_array

		for y in grid_y:
			var z_array = []
			z_array.resize(grid_z)
			grid[x][y] = z_array

			for z in grid_z:
				grid[x][y][z] = false

# Apply structure data to create cubes
func _apply_structure_data(structure_data):
	if not structure_data.layout_data:
		print("GridStructureComponent: No layout_data in structure")
		return

	var structure_layout = structure_data.layout_data
	var total_size = cube_size + gutter

	# First pass: collect all cube positions
	var temp_positions: Array = []

	for z in grid_z:
		if z >= structure_layout.size():
			break

		var row = structure_layout[z]
		for x in grid_x:
			if x >= row.size():
				break

			var cell_value = str(row[x]).strip_edges()
			var stack_height = 0

			if cell_value.is_valid_int():
				stack_height = int(cell_value)

			# Collect stacked cube positions
			for y in range(0, min(stack_height, grid_y)):
				temp_positions.append(Vector3i(x, y, z))
				grid[x][y][z] = true

	# Set instance count
	var cube_count = temp_positions.size()
	if cube_count > 0 and multimesh:
		multimesh.instance_count = cube_count
		cube_positions = temp_positions

		# Check if animation is enabled
		if animation_enabled:
			# Prepare for animated generation
			_prepare_animated_generation(temp_positions, total_size)
		else:
			# Immediate generation (no animation)
			_generate_cubes_immediate(temp_positions, total_size)

	print("GridStructureComponent: Added %d cubes using MultiMesh with collisions" % cube_count)
	structure_generation_complete.emit(cube_count)

# Generate cubes immediately without animation
func _generate_cubes_immediate(positions: Array, total_size: float):
	for i in range(positions.size()):
		var pos = positions[i]
		var world_pos = Vector3(pos.x, pos.y, pos.z) * total_size

		# Set visual transform
		var transform = Transform3D()
		transform.origin = world_pos
		multimesh.set_instance_transform(i, transform)

		# Create collision shape
		_create_collision_at(world_pos, cube_size)

# Prepare and start animated cube generation
func _prepare_animated_generation(positions: Array, total_size: float):
	print("GridStructureComponent: Starting animated cube generation (%d cubes)" % positions.size())
	animation_started.emit()
	_animation_in_progress = true
	
	# Build animation data with world positions
	_pending_cube_data.clear()
	for i in range(positions.size()):
		var pos = positions[i]
		var world_pos = Vector3(pos.x, pos.y, pos.z) * total_size
		_pending_cube_data.append({
			"index": i,
			"grid_pos": pos,
			"world_pos": world_pos
		})
	
	# Sort based on animation order
	_sort_cubes_for_animation()
	
	# Initialize all cubes to hidden state based on animation type
	_initialize_cubes_for_animation(total_size)
	
	# Create all collision shapes immediately (physics shouldn't wait for animation)
	for data in _pending_cube_data:
		_create_collision_at(data.world_pos, cube_size)
	
	# Start the animation coroutine
	_animate_cubes()

# Sort cubes based on animation order
func _sort_cubes_for_animation():
	match animation_order:
		"sequential":
			# Already in order (z then x then y)
			pass
		"spiral":
			_sort_spiral()
		"random":
			_pending_cube_data.shuffle()
		"wave_x":
			_pending_cube_data.sort_custom(func(a, b): return a.grid_pos.x < b.grid_pos.x)
		"wave_z":
			_pending_cube_data.sort_custom(func(a, b): return a.grid_pos.z < b.grid_pos.z)
		"wave_y":
			_pending_cube_data.sort_custom(func(a, b): return a.grid_pos.y < b.grid_pos.y)
		"center_out":
			_sort_center_out()
		"corners_first":
			_sort_corners_first()

# Sort cubes in a spiral pattern from center
func _sort_spiral():
	var center_x = grid_x / 2.0
	var center_z = grid_z / 2.0
	
	# Sort by angle and distance from center
	_pending_cube_data.sort_custom(func(a, b):
		var da = Vector2(a.grid_pos.x - center_x, a.grid_pos.z - center_z)
		var db = Vector2(b.grid_pos.x - center_x, b.grid_pos.z - center_z)
		var angle_a = da.angle()
		var angle_b = db.angle()
		var dist_a = da.length()
		var dist_b = db.length()
		# Sort primarily by distance, then by angle
		if abs(dist_a - dist_b) > 0.5:
			return dist_a < dist_b
		return angle_a < angle_b
	)

# Sort cubes from center outward
func _sort_center_out():
	var center = Vector3(grid_x / 2.0, grid_y / 2.0, grid_z / 2.0)
	_pending_cube_data.sort_custom(func(a, b):
		var dist_a = Vector3(a.grid_pos).distance_to(center)
		var dist_b = Vector3(b.grid_pos).distance_to(center)
		return dist_a < dist_b
	)

# Sort cubes starting from corners
func _sort_corners_first():
	var center = Vector3(grid_x / 2.0, grid_y / 2.0, grid_z / 2.0)
	_pending_cube_data.sort_custom(func(a, b):
		var dist_a = Vector3(a.grid_pos).distance_to(center)
		var dist_b = Vector3(b.grid_pos).distance_to(center)
		return dist_a > dist_b  # Reverse - corners (far from center) first
	)

# Initialize cubes to their starting animation state
func _initialize_cubes_for_animation(_total_size: float):
	for data in _pending_cube_data:
		var transform = Transform3D()
		
		match animation_type:
			"scale_up":
				# Start at scale 0
				transform.basis = Basis.IDENTITY.scaled(Vector3.ZERO)
				transform.origin = data.world_pos
			"drop_in":
				# Start above final position
				transform.origin = data.world_pos + Vector3(0, 10.0, 0)
			"fade_in":
				# Start at correct position but will use color alpha
				transform.origin = data.world_pos
			"wave":
				# Start below final position
				transform.origin = data.world_pos + Vector3(0, -2.0, 0)
			"pop":
				# Start at scale 0 like scale_up but with overshoot
				transform.basis = Basis.IDENTITY.scaled(Vector3.ZERO)
				transform.origin = data.world_pos
			_:
				transform.origin = data.world_pos
		
		multimesh.set_instance_transform(data.index, transform)

# Animate cubes one by one (or in groups)
func _animate_cubes():
	var tween_group = create_tween()
	tween_group.set_parallel(false)  # Sequential tweens
	
	for i in range(_pending_cube_data.size()):
		var data = _pending_cube_data[i]
		var index = data.index
		var world_pos = data.world_pos
		
		# Add delay between cubes
		if i > 0:
			tween_group.tween_interval(animation_delay)
		
		# Create animation based on type
		match animation_type:
			"scale_up":
				_tween_scale_up(tween_group, index, world_pos)
			"drop_in":
				_tween_drop_in(tween_group, index, world_pos)
			"wave":
				_tween_wave(tween_group, index, world_pos)
			"pop":
				_tween_pop(tween_group, index, world_pos)
			_:
				_tween_scale_up(tween_group, index, world_pos)
	
	# Connect completion callback
	tween_group.finished.connect(_on_animation_complete)

# Tween: Scale up from 0 to 1
func _tween_scale_up(tween: Tween, index: int, target_pos: Vector3):
	var start_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), target_pos)
	var end_transform = Transform3D(Basis.IDENTITY, target_pos)
	
	tween.tween_method(
		func(t: float): _set_transform_interpolated(index, start_transform, end_transform, t),
		0.0, 1.0, animation_duration
	).set_ease(_get_tween_ease()).set_trans(_get_tween_trans())

# Tween: Drop in from above
func _tween_drop_in(tween: Tween, index: int, target_pos: Vector3):
	var start_pos = target_pos + Vector3(0, 10.0, 0)
	var start_transform = Transform3D(Basis.IDENTITY, start_pos)
	var end_transform = Transform3D(Basis.IDENTITY, target_pos)
	
	tween.tween_method(
		func(t: float): _set_transform_interpolated(index, start_transform, end_transform, t),
		0.0, 1.0, animation_duration
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)

# Tween: Wave up from below
func _tween_wave(tween: Tween, index: int, target_pos: Vector3):
	var start_pos = target_pos + Vector3(0, -2.0, 0)
	var start_transform = Transform3D(Basis.IDENTITY, start_pos)
	var end_transform = Transform3D(Basis.IDENTITY, target_pos)
	
	tween.tween_method(
		func(t: float): _set_transform_interpolated(index, start_transform, end_transform, t),
		0.0, 1.0, animation_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

# Tween: Pop in with overshoot
func _tween_pop(tween: Tween, index: int, target_pos: Vector3):
	var start_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), target_pos)
	var end_transform = Transform3D(Basis.IDENTITY, target_pos)
	
	tween.tween_method(
		func(t: float): _set_transform_interpolated(index, start_transform, end_transform, t),
		0.0, 1.0, animation_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# Helper: Interpolate and set transform
func _set_transform_interpolated(index: int, from: Transform3D, to: Transform3D, t: float):
	if not multimesh:
		return
	# Check if from basis is degenerate (zero scale) - can't use interpolate_with
	# because it requires valid rotation for quaternion conversion
	var from_scale = from.basis.get_scale()
	if from_scale.length_squared() < 0.0001:
		# Scale animation from zero - lerp scale manually
		var to_scale = to.basis.get_scale()
		var lerped_scale = from_scale.lerp(to_scale, t)
		var interpolated = Transform3D(Basis.IDENTITY.scaled(lerped_scale), from.origin.lerp(to.origin, t))
		multimesh.set_instance_transform(index, interpolated)
	else:
		var interpolated = from.interpolate_with(to, t)
		multimesh.set_instance_transform(index, interpolated)

# Get tween ease type from string
func _get_tween_ease() -> Tween.EaseType:
	match animation_easing:
		"ease_in": return Tween.EASE_IN
		"ease_out": return Tween.EASE_OUT
		"ease_in_out": return Tween.EASE_IN_OUT
		_: return Tween.EASE_OUT

# Get tween transition type
func _get_tween_trans() -> Tween.TransitionType:
	match animation_type:
		"pop": return Tween.TRANS_BACK
		"drop_in": return Tween.TRANS_BOUNCE
		"wave": return Tween.TRANS_SINE
		_: return Tween.TRANS_CUBIC

# Animation completion callback
func _on_animation_complete():
	print("GridStructureComponent: Animation complete")
	_animation_in_progress = false
	_pending_cube_data.clear()
	animation_complete.emit()

# Check if animation is in progress
func is_animating() -> bool:
	return _animation_in_progress

# Create a collision shape at the specified position
func _create_collision_at(world_pos: Vector3, size: float):
	if not collision_parent:
		return

	# Create StaticBody3D
	var static_body = StaticBody3D.new()
	static_body.position = world_pos

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(size, size, size)
	collision_shape.shape = box_shape

	# Add to hierarchy
	static_body.add_child(collision_shape)
	collision_parent.add_child(static_body)

	# Add to group for easy access
	static_body.add_to_group(CUBE_GROUP_NAME)

# Note: _add_cube is deprecated - using MultiMesh now
# Individual cube nodes are no longer created

# Find highest Y position at X,Z coordinate
func find_highest_y_at(x: int, z: int) -> int:
	if not _is_valid_xz(x, z):
		return 0
		
	for y in range(grid_y-1, -1, -1):
		if grid[x][y][z]:
			return y + 1
	return 0

# Check if position has a cube
func has_cube_at(x: int, y: int, z: int) -> bool:
	if not _is_valid_xyz(x, y, z):
		return false
	return grid[x][y][z]

# Get cube at position
# Note: Returns null with MultiMesh as there are no individual cube nodes
# Use has_cube_at() to check for cube existence
func get_cube_at(_x: int, y: int, z: int) -> Node3D:
	return null

# Clear all cubes
func clear_structure():
	print("GridStructureComponent: Clearing all cubes")

	# Clear MultiMesh instances
	if multimesh:
		multimesh.instance_count = 0

	cube_positions.clear()
	grid.clear()
	_pending_cube_data.clear()
	_animation_in_progress = false

	# Clean up collision parent and all its children
	if collision_parent and is_instance_valid(collision_parent):
		collision_parent.queue_free()
		collision_parent = null

	# Clean up the MultiMeshInstance3D node if it exists
	if multimesh_instance and is_instance_valid(multimesh_instance):
		multimesh_instance.queue_free()
		multimesh_instance = null
		multimesh = null

# Validation helpers
func _is_valid_xyz(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < grid_x and y >= 0 and y < grid_y and z >= 0 and z < grid_z

func _is_valid_xz(x: int, z: int) -> bool:
	return x >= 0 and x < grid_x and z >= 0 and z < grid_z

# Helper to parse "r,g,b,a" string to Color
func _parse_color_string(color_str: String) -> Color:
	var parts = color_str.split(",")
	if parts.size() >= 3:
		var r = parts[0].strip_edges().to_float()
		var g = parts[1].strip_edges().to_float()
		var b = parts[2].strip_edges().to_float()
		var a = 1.0
		if parts.size() >= 4:
			a = parts[3].strip_edges().to_float()
		return Color(r, g, b, a)
	return Color.WHITE

# Get grid dimensions
func get_grid_dimensions() -> Vector3i:
	return Vector3i(grid_x, grid_y, grid_z)

# Get cube count
func get_cube_count() -> int:
	return cube_positions.size()

# Get all cube positions
func get_all_cube_positions() -> Array:
	return cube_positions.duplicate()

# Get all cubes from the group
# Returns collision bodies (StaticBody3D) that represent each cube
func get_all_cubes() -> Array[Node]:
	"""Returns all cube collision bodies in the grid_cubes group"""
	if not parent_node or not parent_node.get_tree():
		return []
	return parent_node.get_tree().get_nodes_in_group(CUBE_GROUP_NAME)

# Get cubes group name
func get_cubes_group_name() -> String:
	"""Returns the group name used for all grid cubes"""
	return CUBE_GROUP_NAME

# Add a cube dynamically at the specified position
# This method allows algorithms to add cubes after initial generation
func add_cube_at(x: int, y: int, z: int) -> bool:
	"""Add a cube at the specified grid coordinates. Returns true if successful."""
	if not _is_valid_xyz(x, y, z):
		push_warning("GridStructureComponent: Cannot add cube at invalid position (%d, %d, %d)" % [x, y, z])
		return false
	
	# Check if cube already exists
	if grid[x][y][z]:
		return false  # Cube already exists
	
	# Ensure multimesh exists before proceeding
	if not multimesh:
		push_warning("GridStructureComponent: Cannot add cube - MultiMesh not initialized")
		return false
	
	# Mark position as occupied
	grid[x][y][z] = true
	
	# Add to positions array
	var pos = Vector3i(x, y, z)
	var old_count = cube_positions.size()
	cube_positions.append(pos)
	var new_count = cube_positions.size()
	
	# IMPORTANT: Store existing transforms before changing instance count
	# This is necessary because in some Godot versions, changing instance_count
	# can reset transforms
	var existing_transforms: Array[Transform3D] = []
	existing_transforms.resize(old_count)
	for i in range(old_count):
		existing_transforms[i] = multimesh.get_instance_transform(i)
	
	# Increase instance count
	multimesh.instance_count = new_count
	
	# Restore existing transforms
	var total_size = cube_size + gutter
	for i in range(old_count):
		multimesh.set_instance_transform(i, existing_transforms[i])
	
	# Set transform for the new instance
	var world_pos = Vector3(pos.x, pos.y, pos.z) * total_size
	var transform = Transform3D()
	transform.origin = world_pos
	multimesh.set_instance_transform(old_count, transform)
	
	# Create collision shape
	_create_collision_at(world_pos, cube_size)
	
	print("GridStructureComponent: Added cube at (%d, %d, %d) - count: %d->%d" % [x, y, z, old_count, new_count])
	return true

func remove_cube_at(x: int, y: int, z: int) -> bool:
	"""Remove a cube at the specified grid coordinates. Returns true if successful."""
	if not _is_valid_xyz(x, y, z):
		push_warning("GridStructureComponent: Cannot remove cube at invalid position (%d, %d, %d)" % [x, y, z])
		return false
	
	# Check if cube exists
	if not grid[x][y][z]:
		return false  # No cube to remove
	
	# Ensure multimesh exists
	if not multimesh:
		push_warning("GridStructureComponent: Cannot remove cube - MultiMesh not initialized")
		return false
	
	# Find the index of this cube in cube_positions
	var pos_to_remove = Vector3i(x, y, z)
	var index_to_remove = -1
	for i in range(cube_positions.size()):
		if cube_positions[i] == pos_to_remove:
			index_to_remove = i
			break
	
	if index_to_remove == -1:
		push_warning("GridStructureComponent: Cube at (%d, %d, %d) not found in cube_positions" % [x, y, z])
		return false
	
	# Mark position as unoccupied
	grid[x][y][z] = false
	
	var old_count = cube_positions.size()
	var last_index = old_count - 1
	
	# If we're removing from the middle, swap with the last element
	# This avoids having to rebuild all transforms
	if index_to_remove < last_index:
		var last_pos = cube_positions[last_index]
		cube_positions[index_to_remove] = last_pos
		
		# Update the transform at index_to_remove to match the swapped cube
		var total_size = cube_size + gutter
		var world_pos = Vector3(last_pos.x, last_pos.y, last_pos.z) * total_size
		var transform = Transform3D()
		transform.origin = world_pos
		multimesh.set_instance_transform(index_to_remove, transform)
	
	# Remove the last element
	cube_positions.pop_back()
	var new_count = cube_positions.size()
	
	# Update instance count
	multimesh.instance_count = new_count
	
	# TODO: Remove collision shape at this position
	# (would need to track collision shapes to remove them)
	
	print("GridStructureComponent: Removed cube at (%d, %d, %d) - count: %d->%d" % [x, y, z, old_count, new_count])
	return true
