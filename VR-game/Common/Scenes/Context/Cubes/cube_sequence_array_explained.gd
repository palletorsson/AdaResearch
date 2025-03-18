extends Node3D

# Preload the cube scene
var cube_scene = preload("res://adaresearch/Common/Scenes/Context/Cubes/cube_scene.tscn")

# Constants for the array construction
const CUBE_SPACING = 1.5
const GRID_ROWS = 3
const GRID_COLS = 7
const INITIAL_DELAY = 14.0

# Cube collections
var single_cube
var row_cubes = []
var grid_cubes = []

# Labels for explanation
var labels = {}

# Explanation text
const EXPLANATIONS = {
	"single": "A single element: array[0]",
	"row": "A 1D array along Z-axis: array[i]",
	"grid": "A 2D array with rows (Y) and columns (Z): array[row][col]"
}

func _ready():
	# Start sequence with delay
	print("Starting array explanation in " + str(INITIAL_DELAY) + " seconds...")
	
	# Create introductory text
	create_intro_text()
	
	# Wait before beginning the demonstration
	await get_tree().create_timer(INITIAL_DELAY).timeout
	
	# Start the sequence demonstrating arrays
	start_array_sequence()

func create_intro_text():
	# Add a large introductory text explaining arrays
	var intro_label = Label3D.new()
	intro_label.text = ""
	intro_label.font_size = 64
	intro_label.modulate = Color(1, 0, 1)  # Magenta
	intro_label.position = Vector3(0, 2, -5)  # In front of player
	intro_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(intro_label)
	
	# Store the label
	labels["intro"] = intro_label

func start_array_sequence():
	# First create a single cube (element)
	await create_single_cube()
	
	# Then create a row of cubes (1D array)
	await create_row_of_cubes()
	
	# Finally create a grid of cubes (2D array)
	await create_grid_of_cubes()

func create_single_cube():
	print("Creating single cube...")
	
	# Create a single cube at y=3
	single_cube = cube_scene.instantiate()
	single_cube.transform.origin = Vector3(-2, 0, -1)
	
	# Start with zero scale and animate up
	single_cube.scale = Vector3.ZERO
	add_child(single_cube)
	
	# Add index label (0)
	add_index_label(single_cube, "0")
	
	# Animate the scale with elastic effect
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(single_cube, "scale", Vector3.ONE, 0.5)
	
	# Wait before proceeding
	await get_tree().create_timer(3.0).timeout
	
	return

func create_row_of_cubes():
	print("Creating row of cubes...")
	
	# Create 7 cubes along Z axis
	for i in range(GRID_COLS):
		var cube = cube_scene.instantiate()
		
		# Position along Z axis
		cube.transform.origin = Vector3(-3, 2,  1+(i * CUBE_SPACING))
		
		# Start with zero scale

		add_child(cube)
		row_cubes.append(cube)
		cube.scale = Vector3.ZERO	
		# Add index label
		add_index_label(cube, str(i))
		
		# Animate appearance with slight delay between cubes
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(cube, "scale", Vector3.ONE, 0.5)
		
		# Small delay between each cube appearing
		await get_tree().create_timer(0.2).timeout
	
	
	# Wait before proceeding
	await get_tree().create_timer(3.0).timeout
	
	return

func create_grid_of_cubes():
	print("Creating grid of cubes...")
	
	# Create a grid of cubes (rows in Y, columns in Z)
	for row in range(GRID_ROWS):
		var row_array = []
		
		for col in range(GRID_COLS):
			var cube = cube_scene.instantiate()
			
			# Position in grid (Y for rows, Z for columns)
			cube.transform.origin = Vector3(7, 1 + (row * CUBE_SPACING),  1+(col * CUBE_SPACING))
			
			# Make cubes slightly smaller in the grid

			add_child(cube)
			row_array.append(cube)
			cube.scale = Vector3.ZERO			
			# Add 2D index label
			add_index_label(cube, "[" + str(row) + "][" + str(col) + "]")
			
			# Store row,col as metadata
			cube.set_meta("row", row)
			cube.set_meta("col", col)
			
			# Animate appearance with ripple effect (starting from top-left)
			var delay = (row + col) * 0.1
			await get_tree().create_timer(delay).timeout
			
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(cube, "scale", Vector3(0.8, 0.8, 0.8), 0.5)
		
		grid_cubes.append(row_array)
	
	# Create explanation label for the grid
	if grid_cubes.size() > 0 and grid_cubes[0].size() > 0:
		# Add label to center cube of grid
		var center_row = floor(GRID_ROWS / 2)
		var center_col = floor(GRID_COLS / 2)
	
	# Wait before finishing
	await get_tree().create_timer(2.0).timeout
	
	# Highlight row/column access in the grid
	highlight_array_access()
	
	return

func highlight_array_access():
	print("Highlighting array access patterns...")
	
	# First highlight a full row to demonstrate row access
	if grid_cubes.size() >= 2:
		var row_to_highlight = 1  # Middle row
		highlight_row(row_to_highlight)
		await get_tree().create_timer(2.0).timeout
		reset_grid_colors()
		
		# Then highlight a column to demonstrate column access
		var col_to_highlight = 3  # Middle column
		highlight_column(col_to_highlight)
		await get_tree().create_timer(2.0).timeout
		reset_grid_colors()
		
		# Finally highlight a specific element to demonstrate direct access
		highlight_element(1, 3)  # Element at [1][3]
		await get_tree().create_timer(1.0).timeout

func highlight_row(row_index):
	if row_index < grid_cubes.size():
		for cube in grid_cubes[row_index]:
			highlight_cube(cube, Color(1, 0.5, 0, 1))  # Orange highlight
		
		# Add explanation text
		var text = Label3D.new()
		text.text = "Accessing row " + str(row_index) + ":\narray[" + str(row_index) + "]"
		text.font_size = 24
		text.modulate = Color(1, 0.5, 0, 1)
		text.position = Vector3(5, 1.5 + (row_index * CUBE_SPACING), 0)
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(text)
		labels["row_highlight"] = text

func highlight_column(col_index):
	for row in range(grid_cubes.size()):
		if col_index < grid_cubes[row].size():
			highlight_cube(grid_cubes[row][col_index], Color(0, 1, 0, 1))  # Green highlight
	
	# Add explanation text
	var text = Label3D.new()
	text.text = "Accessing column " + str(col_index) + ":\nRequires looping through rows"
	text.font_size = 24
	text.modulate = Color(0, 1, 0, 1)
	text.position = Vector3(5, 3, -3 + (col_index * CUBE_SPACING))
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	labels["col_highlight"] = text

func highlight_element(row_index, col_index):
	if row_index < grid_cubes.size() and col_index < grid_cubes[row_index].size():
		highlight_cube(grid_cubes[row_index][col_index], Color(1, 0, 1, 1))  # Magenta highlight
		
		# Add explanation text
		var text = Label3D.new()
		text.text = "Direct element access:\narray[" + str(row_index) + "][" + str(col_index) + "]"
		text.font_size = 24
		text.modulate = Color(1, 0, 1, 1)
		text.position = Vector3(5, 1.5 + (row_index * CUBE_SPACING), -3 + (col_index * CUBE_SPACING))
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(text)
		labels["element_highlight"] = text

func reset_grid_colors():
	# Remove highlight colors from all grid cubes
	for row in grid_cubes:
		for cube in row:
			reset_cube_color(cube)
	
	# Remove any temporary highlight labels
	for label_key in ["row_highlight", "col_highlight", "element_highlight"]:
		if label_key in labels and labels[label_key] != null:
			labels[label_key].queue_free()
			labels.erase(label_key)

func highlight_cube(cube, color):
	# Change cube color to highlight it
	if cube.has_node("MeshInstance3D"):
		var mesh_instance = cube.get_node("MeshInstance3D")
		var new_material = StandardMaterial3D.new()
		new_material.albedo_color = color
		new_material.emission_enabled = true
		new_material.emission = color * 0.5
		mesh_instance.set_surface_override_material(0, new_material)

func reset_cube_color(cube):
	# Reset cube to default color
	if cube.has_node("MeshInstance3D"):
		var mesh_instance = cube.get_node("MeshInstance3D")
		mesh_instance.set_surface_override_material(0, null)  # Remove override



func add_index_label(cube, index_text):
	# Add a small label showing the index
	var label = Label3D.new()
	label.text = index_text
	label.font_size = 16
	label.position = Vector3(0, -0.75, 0)  # Below the cube
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.5, 0.8, 1.0)  # Light blue
	cube.add_child(label)
