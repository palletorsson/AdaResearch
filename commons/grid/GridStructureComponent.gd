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

# Collision parent for static bodies
var collision_parent: Node3D

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Group name for all generated cubes (kept for compatibility)
const CUBE_GROUP_NAME = "grid_cubes"

# Signals
signal structure_generation_complete(cube_count: int)

func _ready():
	print("GridStructureComponent: Initialized")

# Initialize with references and settings
func initialize(grid_parent: Node3D, cube_template: Node3D, settings: Dictionary = {}):
	parent_node = grid_parent
	base_cube = cube_template

	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)

	# Create collision parent
	collision_parent = Node3D.new()
	collision_parent.name = "GridCollisions"
	parent_node.add_child(collision_parent)

	# Create MultiMeshInstance3D
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "GridMultiMesh"
	parent_node.add_child(multimesh_instance)

	# Extract mesh from base cube
	print("GridStructureComponent: Inspecting base_cube: %s" % base_cube)
	_print_tree(base_cube)
	var mesh_instance = _find_mesh_instance(base_cube)
	if mesh_instance:
		print("GridStructureComponent: Found mesh instance: %s" % mesh_instance.name)
	else:
		print("GridStructureComponent: Failed to find mesh instance in %s" % base_cube.name)

	if mesh_instance and mesh_instance.mesh:
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true  # Enable per-instance colors BEFORE setting instance_count
		multimesh.use_custom_data = true  # Enable custom data for algorithms like DiscoFloor
		multimesh.mesh = mesh_instance.mesh
		multimesh_instance.multimesh = multimesh

		# Copy material if available - handle both material_override and surface materials
		var mat = null
		if mesh_instance.material_override:
			mat = mesh_instance.material_override
		elif mesh_instance.get_surface_override_material_count() > 0:
			mat = mesh_instance.get_surface_override_material(0)
		elif mesh_instance.mesh.get_surface_count() > 0:
			mat = mesh_instance.mesh.surface_get_material(0)

		if mat:
			# Duplicate material to avoid modifying the original
			var duplicated_mat = mat.duplicate()
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
		push_error("GridStructureComponent: Could not find MeshInstance3D in base_cube")

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

		# Second pass: set transforms and create collision shapes
		for i in range(cube_count):
			var pos = temp_positions[i]
			var world_pos = Vector3(pos.x, pos.y, pos.z) * total_size

			# Set visual transform
			var transform = Transform3D()
			transform.origin = world_pos
			multimesh.set_instance_transform(i, transform)

			# Create collision shape
			_create_collision_at(world_pos, cube_size)

	print("GridStructureComponent: Added %d cubes using MultiMesh with collisions" % cube_count)
	structure_generation_complete.emit(cube_count)

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
func get_cube_at(x: int, y: int, z: int) -> Node3D:
	return null

# Clear all cubes
func clear_structure():
	print("GridStructureComponent: Clearing all cubes")

	# Clear MultiMesh instances
	if multimesh:
		multimesh.instance_count = 0

	cube_positions.clear()
	grid.clear()

	# Clean up collision shapes
	if collision_parent and is_instance_valid(collision_parent):
		for child in collision_parent.get_children():
			child.queue_free()

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
	
	# Mark position as occupied
	grid[x][y][z] = true
	
	# Add to positions array
	var pos = Vector3i(x, y, z)
	cube_positions.append(pos)
	
	# Update MultiMesh instance count
	if multimesh:
		var current_count = multimesh.instance_count
		multimesh.instance_count = cube_positions.size()
		
		# Set transform for the new instance
		var total_size = cube_size + gutter
		var world_pos = Vector3(pos.x, pos.y, pos.z) * total_size
		var transform = Transform3D()
		transform.origin = world_pos
		multimesh.set_instance_transform(current_count, transform)
		
		# Create collision shape
		_create_collision_at(world_pos, cube_size)
		
		print("GridStructureComponent: Added cube at (%d, %d, %d)" % [x, y, z])
		return true
	
	return false
