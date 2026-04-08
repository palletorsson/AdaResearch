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
		# Always hide the template cube — it's only used for mesh/material extraction
		base_cube.visible = false

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
	## Returns all cube collision bodies in the grid_cubes group
	if not parent_node or not parent_node.get_tree():
		return []
	return parent_node.get_tree().get_nodes_in_group(CUBE_GROUP_NAME)

# Get cubes group name
func get_cubes_group_name() -> String:
	## Returns the group name used for all grid cubes
	return CUBE_GROUP_NAME

# Add a cube dynamically at the specified position
# This method allows algorithms to add cubes after initial generation
func add_cube_at(x: int, y: int, z: int) -> bool:
	## Add a cube at the specified grid coordinates. Returns true if successful.
	if not _is_valid_xyz(x, y, z):
		push_warning("GridStructureComponent: Cannot add cube at invalid position (%d, %d, %d)" % [x, y, z])
		return false
	if grid[x][y][z]:
		return false
	if not multimesh:
		push_warning("GridStructureComponent: Cannot add cube - MultiMesh not initialized")
		return false

	grid[x][y][z] = true
	cube_positions.append(Vector3i(x, y, z))

	# Rebuild the entire multimesh from cube_positions — avoids all buffer issues
	_rebuild_multimesh_from_positions()

	# Create collision shape
	var total_size = cube_size + gutter
	var world_pos = Vector3(x, y, z) * total_size
	_create_collision_at(world_pos, cube_size)

	return true

func remove_cube_at(x: int, y: int, z: int) -> bool:
	## Remove a cube at the specified grid coordinates. Returns true if successful.
	if not _is_valid_xyz(x, y, z):
		push_warning("GridStructureComponent: Cannot remove cube at invalid position (%d, %d, %d)" % [x, y, z])
		return false
	if not grid[x][y][z]:
		return false
	if not multimesh:
		push_warning("GridStructureComponent: Cannot remove cube - MultiMesh not initialized")
		return false

	grid[x][y][z] = false

	# Remove collision body at this position
	var total_size = cube_size + gutter
	var target_world: Vector3 = Vector3(x, y, z) * total_size
	if collision_parent:
		for body in collision_parent.get_children():
			if body is StaticBody3D and body.position.distance_to(target_world) < 0.1:
				body.queue_free()
				break

	# Remove from positions array
	var pos_to_remove = Vector3i(x, y, z)
	var idx = cube_positions.find(pos_to_remove)
	if idx >= 0:
		cube_positions.remove_at(idx)

	# Rebuild the entire multimesh from cube_positions
	_rebuild_multimesh_from_positions()

	return true

func _rebuild_multimesh_from_positions() -> void:
	## Rebuild the multimesh transforms from the cube_positions array.
	## This is the nuclear option — simple, correct, no buffer corruption possible.
	if not multimesh:
		return
	var count = cube_positions.size()
	multimesh.instance_count = count
	var total_size = cube_size + gutter
	for i in range(count):
		var pos = cube_positions[i]
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(pos.x, pos.y, pos.z) * total_size))
		if multimesh.use_colors:
			multimesh.set_instance_color(i, Color.WHITE)
		if multimesh.use_custom_data:
			multimesh.set_instance_custom_data(i, Color(0, 0, 0, 0))

# ===== TRANSFORM DISTORTION API =====
# These operate on multimesh instance transforms directly — visual-only, no grid state change.
# Used by GridAgent "distort" / "explode" operations to create glitch art effects.

## Snapshot the current transforms so they can be restored later.
var _stored_transforms: Array[Transform3D] = []

func snapshot_transforms() -> void:
	## Store all current multimesh transforms for later restore.
	_stored_transforms.clear()
	if not multimesh:
		return
	_stored_transforms.resize(multimesh.instance_count)
	for i in range(multimesh.instance_count):
		_stored_transforms[i] = multimesh.get_instance_transform(i)
	print("GridStructureComponent: Snapshot %d transforms" % _stored_transforms.size())

func restore_transforms() -> void:
	## Restore transforms from the last snapshot.
	if not multimesh or _stored_transforms.is_empty():
		return
	var count = mini(multimesh.instance_count, _stored_transforms.size())
	for i in range(count):
		multimesh.set_instance_transform(i, _stored_transforms[i])
	print("GridStructureComponent: Restored %d transforms" % count)

func distort_explode(center: Vector3i, radius: int = 5, strength: float = 3.0) -> bool:
	## Explode cubes outward from center — transforms scale + translate away from the origin point.
	## Creates the 'laser wireframe' glitch effect seen in the editor bug.
	if not multimesh or multimesh.instance_count == 0:
		return false

	var total_size = cube_size + gutter
	var center_world = Vector3(center.x, center.y, center.z) * total_size
	var affected := 0

	for i in range(multimesh.instance_count):
		var t = multimesh.get_instance_transform(i)
		var offset = t.origin - center_world
		var dist = offset.length()

		if dist > float(radius) * total_size or dist < 0.001:
			continue

		# Strength falls off with distance (closer cubes fly further)
		var falloff = 1.0 - clampf(dist / (float(radius) * total_size), 0.0, 1.0)
		var push = offset.normalized() * strength * falloff * total_size

		# Stretch the basis along the push direction — this creates the wireframe laser lines
		var stretch_axis = offset.normalized()
		var stretch_amount = 1.0 + strength * falloff * 0.5
		var basis = t.basis
		basis = basis * Basis(
			Vector3(1.0 + stretch_axis.x * (stretch_amount - 1.0), stretch_axis.x * stretch_axis.y * (stretch_amount - 1.0), stretch_axis.x * stretch_axis.z * (stretch_amount - 1.0)),
			Vector3(stretch_axis.y * stretch_axis.x * (stretch_amount - 1.0), 1.0 + stretch_axis.y * (stretch_amount - 1.0), stretch_axis.y * stretch_axis.z * (stretch_amount - 1.0)),
			Vector3(stretch_axis.z * stretch_axis.x * (stretch_amount - 1.0), stretch_axis.z * stretch_axis.y * (stretch_amount - 1.0), 1.0 + stretch_axis.z * (stretch_amount - 1.0))
		)

		t.origin += push
		t.basis = basis
		multimesh.set_instance_transform(i, t)
		affected += 1

	print("GridStructureComponent: Explode distort affected %d instances" % affected)
	return affected > 0

func distort_twist(center: Vector3i, radius: int = 5, angle_per_unit: float = 15.0, axis: String = "y") -> bool:
	## Twist transforms around an axis — rotation increases with distance along that axis.
	## Creates a spiraling deformation effect.
	if not multimesh or multimesh.instance_count == 0:
		return false

	var total_size = cube_size + gutter
	var center_world = Vector3(center.x, center.y, center.z) * total_size
	var affected := 0

	for i in range(multimesh.instance_count):
		var t = multimesh.get_instance_transform(i)
		var offset = t.origin - center_world
		var dist = offset.length()

		if dist > float(radius) * total_size:
			continue

		# How far along the twist axis determines rotation amount
		var axis_dist := 0.0
		match axis.to_lower():
			"x": axis_dist = offset.x / total_size
			"z": axis_dist = offset.z / total_size
			_:   axis_dist = offset.y / total_size

		var angle_rad = deg_to_rad(angle_per_unit * axis_dist)
		var rot_basis: Basis
		match axis.to_lower():
			"x": rot_basis = Basis(Vector3(1, 0, 0), angle_rad)
			"z": rot_basis = Basis(Vector3(0, 0, 1), angle_rad)
			_:   rot_basis = Basis(Vector3(0, 1, 0), angle_rad)

		# Rotate position around center and apply rotation to basis
		var rotated_offset = rot_basis * offset
		t.origin = center_world + rotated_offset
		t.basis = rot_basis * t.basis
		multimesh.set_instance_transform(i, t)
		affected += 1

	print("GridStructureComponent: Twist distort affected %d instances" % affected)
	return affected > 0

func distort_scatter(center: Vector3i, radius: int = 5, scatter_strength: float = 2.0, rotation_strength: float = 45.0) -> bool:
	## Randomly scatter cubes — each gets a random offset and rotation.
	## Creates chaotic dissolution effect.
	if not multimesh or multimesh.instance_count == 0:
		return false

	var total_size = cube_size + gutter
	var center_world = Vector3(center.x, center.y, center.z) * total_size
	var affected := 0

	for i in range(multimesh.instance_count):
		var t = multimesh.get_instance_transform(i)
		var offset = t.origin - center_world
		var dist = offset.length()

		if dist > float(radius) * total_size:
			continue

		var falloff = 1.0 - clampf(dist / (float(radius) * total_size), 0.0, 1.0)

		# Random displacement
		var rand_offset = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * scatter_strength * falloff * total_size
		t.origin += rand_offset

		# Random rotation
		var rand_rot = deg_to_rad(rotation_strength * falloff)
		var rand_axis = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		if rand_axis.length() > 0.01:
			t.basis = Basis(rand_axis, rand_rot * randf()) * t.basis

		multimesh.set_instance_transform(i, t)
		affected += 1

	print("GridStructureComponent: Scatter distort affected %d instances" % affected)
	return affected > 0

func distort_wave(amplitude: float = 1.5, frequency: float = 0.5, phase: float = 0.0, axis: String = "y") -> bool:
	## Apply a sine wave displacement to all transforms.
	## Phase can be animated over time for a flowing wave effect.
	if not multimesh or multimesh.instance_count == 0:
		return false

	var total_size = cube_size + gutter

	for i in range(multimesh.instance_count):
		var t = multimesh.get_instance_transform(i)
		var wave_input := 0.0
		match axis.to_lower():
			"x": wave_input = t.origin.z / total_size
			"z": wave_input = t.origin.x / total_size
			_:   wave_input = t.origin.x / total_size  # y-displacement driven by x

		var displacement = sin(wave_input * frequency * TAU + phase) * amplitude * total_size
		match axis.to_lower():
			"x": t.origin.x += displacement
			"z": t.origin.z += displacement
			_:   t.origin.y += displacement

		multimesh.set_instance_transform(i, t)

	return true


# ═══════════════════════════════════════════════════════════════
# VOXEL EDITING — Runtime cube add/remove for Minecraft-style editors
# ═══════════════════════════════════════════════════════════════

## Reference to the structure data for editing
var _editable_layout: Array = []  # 2D array [z][x] of height strings
var _edit_dimensions: Vector3i = Vector3i.ZERO

## Signal when a cube is added or removed
signal cube_changed(pos: Vector3i, added: bool)


## Enable editing mode — stores a mutable copy of the structure layout.
func enable_editing(structure_data) -> void:
	if structure_data and structure_data.layout_data:
		_editable_layout = []
		for row in structure_data.layout_data:
			var new_row: Array = []
			for cell in row:
				new_row.append(str(cell))
			_editable_layout.append(new_row)
		_edit_dimensions = Vector3i(grid_x, grid_y, grid_z)
		print("GridStructureComponent: Editing enabled (%dx%d)" % [grid_x, grid_z])


## Get height at grid position (x, z).
func get_height_at(x: int, z: int) -> int:
	if _editable_layout.is_empty():
		return 0
	if z < 0 or z >= _editable_layout.size():
		return 0
	if x < 0 or x >= _editable_layout[z].size():
		return 0
	var val: String = str(_editable_layout[z][x]).strip_edges()
	return int(val) if val.is_valid_int() else 0


## Add a cube on top of the stack at column (x, z). Returns true if successful.
func stack_add(x: int, z: int) -> bool:
	if _editable_layout.is_empty():
		return false
	var current: int = get_height_at(x, z)
	if current >= grid_y:
		return false  # Max height reached

	_editable_layout[z][x] = str(current + 1)
	_rebuild_from_layout()
	cube_changed.emit(Vector3i(x, current, z), true)
	return true


## Remove the top cube at column (x, z). Returns true if successful.
func stack_remove(x: int, z: int) -> bool:
	if _editable_layout.is_empty():
		return false
	var current: int = get_height_at(x, z)
	if current <= 0:
		return false  # Nothing to remove

	_editable_layout[z][x] = str(current - 1)
	_rebuild_from_layout()
	cube_changed.emit(Vector3i(x, current - 1, z), false)
	return true


## Set height directly at (x, z).
func set_height_at(x: int, z: int, height: int) -> void:
	if _editable_layout.is_empty():
		return
	if z < 0 or z >= _editable_layout.size():
		return
	if x < 0 or x >= _editable_layout[z].size():
		return
	_editable_layout[z][x] = str(clampi(height, 0, grid_y))
	_rebuild_from_layout()


## Get the current editable layout (for saving).
func get_editable_layout() -> Array:
	return _editable_layout


## Convert a world position to grid coordinates.
func world_to_grid(world_pos: Vector3) -> Vector3i:
	var total_size: float = cube_size + gutter
	return Vector3i(
		int(floor(world_pos.x / total_size)),
		int(floor(world_pos.y / total_size)),
		int(floor(world_pos.z / total_size))
	)


## Convert grid coordinates to world position (center of cube).
func grid_to_world(grid_pos: Vector3i) -> Vector3:
	var total_size: float = cube_size + gutter
	return Vector3(
		float(grid_pos.x) * total_size,
		float(grid_pos.y) * total_size,
		float(grid_pos.z) * total_size
	)


## Rebuild the MultiMesh from the current editable layout.
func _rebuild_from_layout() -> void:
	if _editable_layout.is_empty() or not multimesh:
		return

	# Clear grid state
	for x in grid_x:
		for y in grid_y:
			for z in grid_z:
				grid[x][y][z] = false

	# Clear old collisions
	if collision_parent:
		for child in collision_parent.get_children():
			child.queue_free()

	# Collect new cube positions
	var total_size: float = cube_size + gutter
	var temp_positions: Array = []

	for z in _editable_layout.size():
		var row = _editable_layout[z]
		for x in row.size():
			var height: int = int(str(row[x])) if str(row[x]).is_valid_int() else 0
			for y in range(0, mini(height, grid_y)):
				temp_positions.append(Vector3i(x, y, z))
				if x < grid_x and y < grid_y and z < grid_z:
					grid[x][y][z] = true

	# Update MultiMesh
	cube_positions = temp_positions
	multimesh.instance_count = temp_positions.size()

	for i in temp_positions.size():
		var pos: Vector3i = temp_positions[i]
		var world_pos := Vector3(pos.x, pos.y, pos.z) * total_size
		var transform := Transform3D()
		transform.origin = world_pos
		multimesh.set_instance_transform(i, transform)

		# Set default white color
		multimesh.set_instance_color(i, Color.WHITE)

		# Create collision
		_create_collision_at(world_pos, cube_size)
