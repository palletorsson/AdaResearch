extends Node3D

# Corridor Tileset for WFC
# 6-tile system with doorways and connections

@onready var wfc_grid = $WFCGrid3D

func _ready():
	# Clear default tiles
	wfc_grid.tile_types.clear()
	wfc_grid.solver.tile_types.clear()

	# Create custom corridor tileset
	create_corridor_tiles()

	print("=== Corridor Tileset Created ===")
	print("6 tiles with doorway connections")
	print("Press SPACE to generate")
	print("================================")

func create_corridor_tiles():
	"""Create a 6-tile corridor system with doorways"""

	# Define which tiles can connect to which
	# Format: [left_door, right_door, up_door, down_door, forward_door, back_door]
	# true = open/door, false = wall

	# Tiles 1-5: Corridor modules (left + right doors)
	for i in range(1, 6):
		var tile = WFCTile.new("corridor_" + str(i), 1.0)

		# Color gradient for visual distinction
		var hue = float(i - 1) / 5.0
		tile.color = Color.from_hsv(hue, 0.6, 0.8)

		# LEFT/RIGHT: Can connect to any corridor or terminal
		tile.set_compatible(Vector3.LEFT, [
			"corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"
		])
		tile.set_compatible(Vector3.RIGHT, [
			"corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"
		])

		# UP: Open ceiling (can be empty or another corridor)
		tile.set_compatible(Vector3.UP, ["empty", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5"])

		# DOWN: Floor (can be floor or corridor)
		tile.set_compatible(Vector3.DOWN, ["floor", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5"])

		# FORWARD/BACK: Walls (no doors in Z direction for these tiles)
		tile.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
		tile.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])

		wfc_grid.add_tile_type(tile)

	# Tile 6: Terminal module (right wall sealed, left door open)
	var terminal = WFCTile.new("terminal", 0.5)
	terminal.color = Color(0.2, 0.8, 0.3)  # Green for terminal

	# LEFT: Can connect to corridors
	terminal.set_compatible(Vector3.LEFT, [
		"corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5"
	])

	# RIGHT: Sealed wall (only wall or empty)
	terminal.set_compatible(Vector3.RIGHT, ["wall", "empty"])

	# UP: Open ceiling
	terminal.set_compatible(Vector3.UP, ["empty"])

	# DOWN: Floor
	terminal.set_compatible(Vector3.DOWN, ["floor", "terminal"])

	# FORWARD/BACK: Walls
	terminal.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
	terminal.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])

	wfc_grid.add_tile_type(terminal)

	# Add supporting tiles

	# Wall tiles
	var wall = WFCTile.new("wall", 2.0)
	wall.color = Color(0.3, 0.3, 0.3)
	wall.set_compatible(Vector3.RIGHT, ["wall", "empty", "terminal"])
	wall.set_compatible(Vector3.LEFT, ["wall", "empty", "terminal"])
	wall.set_compatible(Vector3.UP, ["wall", "empty"])
	wall.set_compatible(Vector3.DOWN, ["wall", "floor"])
	wall.set_compatible(Vector3(0, 0, 1), ["wall", "empty", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"])
	wall.set_compatible(Vector3(0, 0, -1), ["wall", "empty", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"])
	wfc_grid.add_tile_type(wall)

	# Floor tiles
	var floor = WFCTile.new("floor", 1.5)
	floor.color = Color(0.5, 0.4, 0.3)
	floor.set_compatible(Vector3.RIGHT, ["floor", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"])
	floor.set_compatible(Vector3.LEFT, ["floor", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"])
	floor.set_compatible(Vector3.UP, ["corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal", "empty"])
	floor.set_compatible(Vector3.DOWN, ["floor"])
	floor.set_compatible(Vector3(0, 0, 1), ["floor", "wall"])
	floor.set_compatible(Vector3(0, 0, -1), ["floor", "wall"])
	wfc_grid.add_tile_type(floor)

	# Empty/air tiles
	var empty = WFCTile.new("empty", 3.0)
	empty.color = Color(0.1, 0.1, 0.1, 0.1)
	empty.set_compatible(Vector3.RIGHT, ["empty", "wall", "terminal"])
	empty.set_compatible(Vector3.LEFT, ["empty", "wall"])
	empty.set_compatible(Vector3.UP, ["empty"])
	empty.set_compatible(Vector3.DOWN, ["empty", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"])
	empty.set_compatible(Vector3(0, 0, 1), ["empty", "wall", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"])
	empty.set_compatible(Vector3(0, 0, -1), ["empty", "wall", "corridor_1", "corridor_2", "corridor_3", "corridor_4", "corridor_5", "terminal"])
	wfc_grid.add_tile_type(empty)

	print("Created tiles: corridor_1 through corridor_5, terminal, wall, floor, empty")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				print("\n=== Generating Corridor WFC Grid ===")
				wfc_grid.generate()
			KEY_R:
				print("\n=== Regenerating ===")
				wfc_grid.regenerate()
			KEY_A:
				wfc_grid.animate_generation = not wfc_grid.animate_generation
				print("Animation: ", "ON" if wfc_grid.animate_generation else "OFF")

func _on_generation_started():
	print("Generation started...")

func _on_generation_complete():
	print("Generation complete!")
	print("Total tiles placed: ", wfc_grid.tile_nodes.size())
