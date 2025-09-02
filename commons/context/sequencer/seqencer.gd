extends Node3D

@export var speed: float = 0.1  # Speed of the running light
@onready var seqencer = $seqencer  # Reference to the parent node containing the tiles
var tiles: Array = []  # Array to hold all tiles
var current_index: int = 0  # Current active tile index
@export var pattern_duration: float = 1.0  # Duration for each pattern
@export var selected_patterns: Array[int] = [1, 2, 3]  # List of selected patterns to play
var patterns_active: bool = true  # Control whether patterns are running

# Map pattern numbers to their respective functions
var patterns: Dictionary = {
	1: play_running_light,
	2: play_block_light,
	3: play_random_tiles,
	4: play_rows_and_columns,
	5: play_checkerboard,
	6: play_diagonal_sweep,
}

func _ready():
	# Initialize tiles from existing children
	for child in seqencer.get_children():
		tiles.append(child)

	# Start running the selected patterns
	if tiles.size() > 0:
		run_selected_patterns()

func run_selected_patterns() -> void:
	# Loop through the selected patterns
	while patterns_active:
		for pattern_id in selected_patterns:
			if pattern_id in patterns:
				await patterns[pattern_id].call()  # Run the pattern
	await restart_patterns()

func restart_patterns() -> void:
	# Wait briefly before restarting
	await get_tree().create_timer(1.0).timeout  # Short delay before restarting
	run_selected_patterns() 
	
func run_patterns() -> void:
	while true:
		await play_running_light()
		await play_block_light()
		await play_random_tiles()
		await play_rows_and_columns()
		await play_checkerboard()
		await play_diagonal_sweep()

func play_running_light() -> void:
	var elapsed_time = 0.0
	while elapsed_time < pattern_duration:
		# Turn off all tiles
		for tile in tiles:
			var material = tile.material_override as StandardMaterial3D
			material.albedo_color = Color(1, 1, 1)  # White/off color

		# Turn on the current tile
		var active_tile = tiles[current_index]
		var active_material = active_tile.material_override as StandardMaterial3D
		if active_material:
			active_material.albedo_color = Color(1, 0, 0)  # Red/on color

		# Move to the next tile
		current_index = (current_index + 1) % tiles.size()

		# Wait before the next light update
		await get_tree().create_timer(speed).timeout
		elapsed_time += speed

func play_block_light() -> void:
	var elapsed_time = 0.0
	while elapsed_time < pattern_duration:
		# Calculate the current row and column
		var row = current_index / tiles.size()
		var col = current_index % tiles.size()

		# Turn off all tiles
		for tile in tiles:
			var material = tile.material_override as StandardMaterial3D
			material.albedo_color = Color(1, 1, 1)  # White/off color

		# Light up the current row and column
		for i in range(tiles.size()):
			if i / tiles.size() == row or i % tiles.size() == col:
				var tile = tiles[i]
				var material = tile.material_override as StandardMaterial3D
				material.albedo_color = Color(0, 1, 0)  # Green/on color

		# Move to the next row/column
		current_index = (current_index + 1) % tiles.size()

		# Wait before the next light update
		await get_tree().create_timer(speed).timeout
		elapsed_time += speed

func play_random_tiles() -> void:
	var elapsed_time = 0.0
	while elapsed_time < pattern_duration:
		# Turn off all tiles
		for tile in tiles:
			var material = tile.material_override as StandardMaterial3D
			material.albedo_color = Color(1, 1, 1)  # White/off color

		# Randomly light up some tiles
		for x in range(5):  # Light up 5 random tiles
			var random_index = randi() % tiles.size()
			var random_tile = tiles[random_index]
			var material = random_tile.material_override as StandardMaterial3D
			if material:
				material.albedo_color = Color(0, 0, 1)  # Blue/on color

		# Wait before the next light update
		await get_tree().create_timer(speed).timeout
		elapsed_time += speed

func play_rows_and_columns() -> void:
	var elapsed_time = 0.0
	while elapsed_time < pattern_duration:
		var total_tiles = tiles.size()
		var rows = 4  # Replace with the actual number of rows in your setup
		var cols = total_tiles / rows  # Derive the number of columns

		# Turn on rows one by one
		for row in range(rows):
			turn_off_all_tiles()
			for col in range(cols):
				var index = row * cols + col
				var tile = tiles[index]
				var material = tile.material_override as StandardMaterial3D
				if material:
					material.albedo_color = Color(1, 1, 0)  # Yellow/on color
			await get_tree().create_timer(speed).timeout

		# Turn on columns one by one
		for col in range(cols):
			turn_off_all_tiles()
			for row in range(rows):
				var index = row * cols + col
				var tile = tiles[index]
				var material = tile.material_override as StandardMaterial3D
				if material:
					material.albedo_color = Color(0, 1, 1)  # Cyan/on color
			await get_tree().create_timer(speed).timeout
			
func play_checkerboard() -> void:
	var elapsed_time = 0.0
	while elapsed_time < pattern_duration:
		# Turn on tiles in a checkerboard pattern
		var rows = 4  # Replace with the actual number of rows in your setup
		var cols = tiles.size() / rows

		for row in range(rows):
			for col in range(cols):
				var index = row * cols + col
				var tile = tiles[index]
				var material = tile.material_override as StandardMaterial3D
				if material:
					if (row + col) % 2 == 0:
						material.albedo_color = Color(1, 0, 0)  # Red/on color
					else:
						material.albedo_color = Color(1, 1, 1)  # White/off color
			await get_tree().create_timer(speed).timeout


func play_diagonal_sweep() -> void:
	# Turn on tiles diagonally one by one
	var rows = 4  # Replace with the actual number of rows in your setup
	var cols = tiles.size() / rows
	var max_diagonal = rows + cols - 1

	for diagonal in range(max_diagonal):
		turn_off_all_tiles()
		for row in range(rows):
			var col = diagonal - row
			if col >= 0 and col < cols:
				var index = row * cols + col
				var tile = tiles[index]
				var material = tile.material_override as StandardMaterial3D
				if material:
					material.albedo_color = Color(0, 0, 1)  # Blue/on color
		await get_tree().create_timer(speed).timeout
		
func turn_off_all_tiles() -> void:
	# Helper function to turn off all tiles
	for tile in tiles:
		var material = tile.material_override as StandardMaterial3D
		material.albedo_color = Color(1, 1, 1)  # White/off color
