extends Node3D

# Parameters for cube generation
@export var cube_size = 0.5
@export var spacing = 0.2
@export var row_count = 5
@export var column_count = 5
@export var layers_count = 5

# Called when the node enters the scene tree for the first time
func _ready():
	create_all_arrangements()

# Create all cube arrangements
func create_all_arrangements():
	# Single cube at origin
	var single_cube = create_single_cube()
	single_cube.position = Vector3(-10, 0, 0)
	add_child(single_cube)
	
	# Row of cubes along X axis
	var row_of_cubes = create_row_of_cubes()
	row_of_cubes.position = Vector3(-5, 0, 0)
	add_child(row_of_cubes)
	
	# Column of cubes along Y axis
	var column_of_cubes = create_column_of_cubes()
	column_of_cubes.position = Vector3(0, 0, 0)
	add_child(column_of_cubes)
	
	# Grid of cubes in XZ plane
	var grid_of_cubes = create_grid_of_cubes()
	grid_of_cubes.position = Vector3(5, 0, 0)
	add_child(grid_of_cubes)
	
	# Grid of altered cubes in XZ plane
	var altered_grid = create_altered_grid()
	altered_grid.position = Vector3(5, 0, -5)
	add_child(altered_grid)
	
	print("Created all cube arrangements")

# Create a single cube
func create_single_cube(size_override = null, color_override = null):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Cube"
	
	# Create cube mesh
	var size = size_override if size_override != null else cube_size
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(size, size, size)
	mesh_instance.mesh = cube_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	if color_override != null:
		material.albedo_color = color_override
	else:
		material.albedo_color = Color(0.2, 0.6, 1.0)
	mesh_instance.material_override = material
	
	return mesh_instance

# Create a row of cubes along X axis
func create_row_of_cubes():
	var parent = Node3D.new()
	parent.name = "RowOfCubes"
	
	var total_width = row_count * (cube_size + spacing) - spacing
	var start_x = -total_width / 2
	
	for i in range(row_count):
		var cube = create_single_cube()
		var x_pos = start_x + i * (cube_size + spacing) + cube_size/2
		cube.position = Vector3(x_pos, 0, 0)
		cube.name = "Cube_Row_" + str(i)
		
		# Change color based on position
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(
			0.2 + 0.6 * (float(i) / row_count),
			0.6,
			1.0
		)
		cube.material_override = material
		
		parent.add_child(cube)
	
	return parent

# Create a column of cubes along Y axis
func create_column_of_cubes():
	var parent = Node3D.new()
	parent.name = "ColumnOfCubes"
	
	var total_height = column_count * (cube_size + spacing) - spacing
	var start_y = 0  # Start from ground and go up
	
	for i in range(column_count):
		var cube = create_single_cube()
		var y_pos = start_y + i * (cube_size + spacing) + cube_size/2
		cube.position = Vector3(0, y_pos, 0)
		cube.name = "Cube_Column_" + str(i)
		
		# Change color based on height
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(
			0.6,
			0.2 + 0.6 * (float(i) / column_count),
			1.0
		)
		cube.material_override = material
		
		parent.add_child(cube)
	
	return parent

# Create a grid of cubes in XZ plane
func create_grid_of_cubes():
	var parent = Node3D.new()
	parent.name = "GridOfCubes"
	
	var total_width = row_count * (cube_size + spacing) - spacing
	var total_depth = column_count * (cube_size + spacing) - spacing
	
	var start_x = -total_width / 2
	var start_z = -total_depth / 2
	
	for i in range(row_count):
		for j in range(column_count):
			var cube = create_single_cube()
			var x_pos = start_x + i * (cube_size + spacing) + cube_size/2
			var z_pos = start_z + j * (cube_size + spacing) + cube_size/2
			cube.position = Vector3(x_pos, 0, z_pos)
			cube.name = "Cube_Grid_" + str(i) + "_" + str(j)
			
			# Change color based on position
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(
				0.2 + 0.6 * (float(i) / row_count),
				0.2 + 0.6 * (float(j) / column_count),
				0.8
			)
			cube.material_override = material
			
			parent.add_child(cube)
	
	return parent

# Create an altered grid with variations
func create_altered_grid():
	var parent = Node3D.new()
	parent.name = "AlteredGrid"
	
	var total_width = row_count * (cube_size + spacing) - spacing
	var total_depth = column_count * (cube_size + spacing) - spacing
	var total_height = layers_count * (cube_size + spacing) - spacing
	
	var start_x = -total_width / 2
	var start_z = -total_depth / 2
	var start_y = 0
	
	for i in range(row_count):
		for j in range(column_count):
			for k in range(layers_count):
				# Generate a procedural size based on position
				var size_factor = 0.5 + 0.5 * sin(i * 0.5) * cos(j * 0.5) * sin(k * 0.5)
				var cube_size_altered = cube_size * size_factor
				
				# Skip some cubes to create interesting patterns
				if (i + j + k) % 3 == 0:
					continue
					
				var cube = create_single_cube(cube_size_altered)
				
				# Calculate position with variations
				var x_pos = start_x + i * (cube_size + spacing) + cube_size/2
				var y_pos = start_y + k * (cube_size + spacing) + cube_size/2
				var z_pos = start_z + j * (cube_size + spacing) + cube_size/2
				
				# Add some sine wave variation to y position
				y_pos += 0.2 * sin(i * 0.8) * cos(j * 0.8)
				
				cube.position = Vector3(x_pos, y_pos, z_pos)
				cube.name = "Cube_Altered_" + str(i) + "_" + str(j) + "_" + str(k)
				
				# Also rotate the cubes based on position
				cube.rotation.x = i * 0.2
				cube.rotation.y = j * 0.2
				cube.rotation.z = k * 0.2
				
				# Change color based on position with more variation
				var material = StandardMaterial3D.new()
				material.albedo_color = Color(
					0.2 + 0.8 * abs(sin(i * 0.7)),
					0.2 + 0.8 * abs(sin(j * 0.7)),
					0.2 + 0.8 * abs(sin(k * 0.7))
				)
				cube.material_override = material
				
				parent.add_child(cube)
	
	return parent

# Optional: Add interaction for VR
func make_cubes_interactive(parent_node):
	for cube in parent_node.get_children():
		if cube is MeshInstance3D:
			# Create a rigid body
			var rigid_body = RigidBody3D.new()
			rigid_body.name = cube.name + "_Body"
			
			# Create collision shape
			var collision_shape = CollisionShape3D.new()
			var box_shape = BoxShape3D.new()
			box_shape.size = (cube.mesh as BoxMesh).size
			collision_shape.shape = box_shape
			
			# Set up the hierarchy
			parent_node.remove_child(cube)
			rigid_body.add_child(cube)
			cube.position = Vector3.ZERO  # Reset position relative to parent
			rigid_body.add_child(collision_shape)
			parent_node.add_child(rigid_body)
			rigid_body.position = cube.position
