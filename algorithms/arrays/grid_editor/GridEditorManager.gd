extends Node3D

## Grid Editor Manager
## Manages the dual-grid system with miniature and full-scale versions

class_name GridEditorManager

# Grid configuration
@export var grid_size: Vector3i = Vector3i(8, 8, 8)  # 8x8x8 snap resolution
@export var miniature_cell_size: float = 0.125  # 1m / 8 = 0.125m per cell
@export var fullscale_cell_size: float = 1.0    # 1 meter per cube (large version)
@export var initial_cube_count: Vector3i = Vector3i(3, 1, 3)  # 3x3 on XZ plane (no Y stacking)

# Grid positions (LOCAL coordinates - relative to where scene is placed in map)
@export var miniature_origin: Vector3 = Vector3(0, 1.3, 0)  # Raised for better VR reachability
@export var fullscale_offset: Vector3 = Vector3(0, 0, 3)    # Offset from miniature (3 units in +Z)

# Visualization
@export var show_grid_lines: bool = true
@export var grid_line_color: Color = Color(0.5, 0.5, 0.5, 0.3)

# References
var miniature_grid_container: Node3D
var fullscale_grid_container: Node3D
var cube_pairs: Array[Dictionary] = []  # [{miniature: GridEditorCube, fullscale: GridEditorCube}]

# Cube scene
var cube_scene: PackedScene

func _ready() -> void:
	# Load the cube scene
	cube_scene = preload("res://algorithms/arrays/grid_editor/GridEditorCube.tscn")
	
	# Create grid containers
	miniature_grid_container = Node3D.new()
	miniature_grid_container.name = "MiniatureGrid"
	miniature_grid_container.position = miniature_origin
	add_child(miniature_grid_container)
	
	fullscale_grid_container = Node3D.new()
	fullscale_grid_container.name = "FullScaleGrid"
	
	# Determine vertical offset to hit World Y=0
	# We want: global_position.y = 0
	
	# Determine horizontal offset to align with World Grid (Integer coordinates)
	# We want: fullscale_global_pos = round(scene_global_pos + offset)
	# But actually, we want the grid to start at the nearest integer world coordinate + offset
	
	var scene_global_pos = global_position
	
	# Where we ideally want the fullscale grid to start (snapped to world grid)
	# We apply the Z-offset logic relative to the Snapped Editor Position
	var target_world_x = round(scene_global_pos.x) + fullscale_offset.x
	var target_world_z = round(scene_global_pos.z) + fullscale_offset.z
	var target_world_y = 0.0 # Floor
	
	# Apply specific offsets requested by user:
	# "Standing on current level should be one unit down" -> Y - 1.0
	# "x and z position is 0.5 off" -> Shift by 0.5 (usually to center on grid lines)
	var correction_offset = Vector3(0.5, -1.0, 0.5)
	
	var target_world_pos = Vector3(target_world_x, target_world_y, target_world_z) + correction_offset
	
	# Calculate local position needed to achieve this global target
	# local_pos = target_global - parent_global
	# (Note: ignoring parent rotation for now, assuming grid aligned)
	fullscale_grid_container.position = target_world_pos - scene_global_pos
	
	add_child(fullscale_grid_container)
	
	# Create grid visualization
	if show_grid_lines:
		create_grid_visualization()
	
	# Initialize with 3x3x3 cubes
	initialize_cubes()
	
	print("GridEditorManager: Initialized with %d cube pairs" % cube_pairs.size())

## Initialize the starting 3x3x3 cube layout AND spawner row
func initialize_cubes() -> void:
	# Standard blocks
	for x in range(initial_cube_count.x):
		for y in range(initial_cube_count.y):
			for z in range(initial_cube_count.z):
				var grid_pos = Vector3i(x, y, z)
				add_cube_at_position(grid_pos)
	
	# Spawner row at X=7 (at the back/side)
	for z in range(grid_size.z):
		# Create a column of spawners? Or just one floor row? 
		# Let's clean the edge -> X=grid_size.x-1 (7)
		var spawner_pos = Vector3i(grid_size.x - 1, 0, z)
		# Only spawn if empty (though it should be)
		add_cube_at_position(spawner_pos, true)

## Add a cube pair at the specified grid position (or single spawner)
func add_cube_at_position(grid_pos: Vector3i, is_spawner: bool = false) -> Dictionary:
	# Create miniature cube
	var mini_cube = cube_scene.instantiate() as GridEditorCube
	mini_cube.name = "MiniCube_%d_%d_%d%s" % [grid_pos.x, grid_pos.y, grid_pos.z, "_Spawner" if is_spawner else ""]
	mini_cube.grid_size = Vector3(grid_size)
	mini_cube.cell_size = miniature_cell_size
	mini_cube.is_miniature = true
	mini_cube.is_spawner = is_spawner
	mini_cube.grid_position = grid_pos
	mini_cube.grid_origin = Vector3.ZERO  # Relative to container
	mini_cube.grid_manager = self
	miniature_grid_container.add_child(mini_cube)
	
	if is_spawner:
		print("GridEditorManager: Added SPAWNER at %s" % grid_pos)
		return {"miniature": mini_cube}
	
	# Create full-scale cube (only for real cubes)
	var full_cube = _create_fullscale_cube(grid_pos)
	
	# Pair the cubes
	mini_cube.set_paired_cube(full_cube)
	full_cube.set_paired_cube(mini_cube)
	
	# Store the pair
	var pair = {
		"miniature": mini_cube,
		"fullscale": full_cube,
		"grid_position": grid_pos
	}
	cube_pairs.append(pair)
	
	print("GridEditorManager: Added cube pair at %s" % grid_pos)
	return pair

func _create_fullscale_cube(grid_pos: Vector3i) -> GridEditorCube:
	var full_cube = cube_scene.instantiate() as GridEditorCube
	full_cube.name = "FullCube_%d_%d_%d" % [grid_pos.x, grid_pos.y, grid_pos.z]
	full_cube.grid_size = Vector3(grid_size)
	full_cube.cell_size = fullscale_cell_size
	full_cube.is_miniature = false
	full_cube.grid_position = grid_pos
	full_cube.grid_origin = Vector3.ZERO
	full_cube.grid_manager = self
	fullscale_grid_container.add_child(full_cube)
	return full_cube

# Logic called by GridEditorCube when a spawner is used
func spawn_replacement_spawner(grid_pos: Vector3i) -> void:
	# Wait a frame to ensure physics state doesn't conflict? 
	# Actually, immediate replacement is fine since the old cube has moved/is being held.
	add_cube_at_position(grid_pos, true)

func create_pair_for_cube(mini_cube: GridEditorCube) -> void:
	if mini_cube.paired_cube:
		return # Already has pair
		
	var grid_pos = mini_cube.grid_position
	var full_cube = _create_fullscale_cube(grid_pos)
	
	# Pair them
	mini_cube.set_paired_cube(full_cube)
	full_cube.set_paired_cube(mini_cube)
	
	# Track it
	var pair = {
		"miniature": mini_cube,
		"fullscale": full_cube,
		"grid_position": grid_pos
	}
	cube_pairs.append(pair)


## Remove a cube pair
func remove_cube_at_position(grid_pos: Vector3i) -> void:
	for i in range(cube_pairs.size()):
		var pair = cube_pairs[i]
		if pair.grid_position == grid_pos:
			pair.miniature.queue_free()
			pair.fullscale.queue_free()
			cube_pairs.remove_at(i)
			print("GridEditorManager: Removed cube pair at %s" % grid_pos)
			return

## Create visual grid lines for reference
func create_grid_visualization() -> void:
	# Create miniature grid lines
	create_grid_box(miniature_grid_container, grid_size, miniature_cell_size, "MiniatureGridLines")
	
	# Create full-scale grid lines
	create_grid_box(fullscale_grid_container, grid_size, fullscale_cell_size, "FullScaleGridLines")

## Create a grid box visualization
func create_grid_box(parent: Node3D, size: Vector3i, cell_size: float, node_name: String) -> void:
	var grid_lines = MeshInstance3D.new()
	grid_lines.name = node_name
	
	var immediate_mesh = ImmediateMesh.new()
	grid_lines.mesh = immediate_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = grid_line_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_lines.material_override = material
	
	# Draw grid lines
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var total_size = Vector3(size) * cell_size
	
	# Draw edges of the bounding box
	var corners = [
		Vector3(0, 0, 0),
		Vector3(total_size.x, 0, 0),
		Vector3(total_size.x, 0, total_size.z),
		Vector3(0, 0, total_size.z),
		Vector3(0, total_size.y, 0),
		Vector3(total_size.x, total_size.y, 0),
		Vector3(total_size.x, total_size.y, total_size.z),
		Vector3(0, total_size.y, total_size.z),
	]
	
	# Bottom face
	_add_line(immediate_mesh, corners[0], corners[1])
	_add_line(immediate_mesh, corners[1], corners[2])
	_add_line(immediate_mesh, corners[2], corners[3])
	_add_line(immediate_mesh, corners[3], corners[0])
	
	# Top face
	_add_line(immediate_mesh, corners[4], corners[5])
	_add_line(immediate_mesh, corners[5], corners[6])
	_add_line(immediate_mesh, corners[6], corners[7])
	_add_line(immediate_mesh, corners[7], corners[4])
	
	# Vertical edges
	_add_line(immediate_mesh, corners[0], corners[4])
	_add_line(immediate_mesh, corners[1], corners[5])
	_add_line(immediate_mesh, corners[2], corners[6])
	_add_line(immediate_mesh, corners[3], corners[7])
	
	immediate_mesh.surface_end()
	
	parent.add_child(grid_lines)

func _add_line(mesh: ImmediateMesh, from: Vector3, to: Vector3) -> void:
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)

## Get cube pair at grid position
func get_cube_at_position(grid_pos: Vector3i) -> Dictionary:
	for pair in cube_pairs:
		if pair.grid_position == grid_pos:
			return pair
	return {}

## API for future extensibility - add different object types
func add_object(object_type: String, grid_pos: Vector3i) -> void:
	match object_type:
		"cube":
			add_cube_at_position(grid_pos)
		_:
			push_warning("GridEditorManager: Unknown object type '%s'" % object_type)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

