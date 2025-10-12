# ===========================================================================
# NOC Example: Custom Tileset (WFC)
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

# Example: Custom WFC Tileset
# Shows how to create a more complex tileset with paths/corridors

@onready var wfc_grid = $WFCGrid3D

func _ready():
	# Clear default tiles
	wfc_grid.tile_types.clear()
	wfc_grid.solver.tile_types.clear()

	# Create custom tileset for corridors/rooms
	create_corridor_tileset()

	print("Custom tileset created with ", wfc_grid.tile_types.size(), " tile types")
	print("Press SPACE to generate")

func create_corridor_tileset():
	"""Create a tileset for generating corridor-like structures"""

	# Straight corridor (horizontal X)
	var corridor_x = WFCTile.new("corridor_x", 1.0)
	corridor_x.color = Color(0.8, 0.8, 0.8)
	corridor_x.set_compatible(Vector3.RIGHT, ["corridor_x", "corner_xz", "corner_x-z", "junction"])
	corridor_x.set_compatible(Vector3.LEFT, ["corridor_x", "corner_xz", "corner_x-z", "junction"])
	corridor_x.set_compatible(Vector3.UP, ["empty"])
	corridor_x.set_compatible(Vector3.DOWN, ["corridor_x", "corner_xz", "corner_x-z"])
	corridor_x.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
	corridor_x.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])
	wfc_grid.add_tile_type(corridor_x)

	# Straight corridor (vertical Z)
	var corridor_z = WFCTile.new("corridor_z", 1.0)
	corridor_z.color = Color(0.8, 0.8, 0.8)
	corridor_z.set_compatible(Vector3.RIGHT, ["wall", "empty"])
	corridor_z.set_compatible(Vector3.LEFT, ["wall", "empty"])
	corridor_z.set_compatible(Vector3.UP, ["empty"])
	corridor_z.set_compatible(Vector3.DOWN, ["corridor_z", "corner_xz", "corner_-xz"])
	corridor_z.set_compatible(Vector3(0, 0, 1), ["corridor_z", "corner_xz", "corner_-xz", "junction"])
	corridor_z.set_compatible(Vector3(0, 0, -1), ["corridor_z", "corner_xz", "corner_-xz", "junction"])
	wfc_grid.add_tile_type(corridor_z)

	# Corner piece (connects X and Z)
	var corner_xz = WFCTile.new("corner_xz", 0.8)
	corner_xz.color = Color(0.7, 0.7, 0.9)
	corner_xz.set_compatible(Vector3.RIGHT, ["corridor_x", "corner_xz", "junction"])
	corner_xz.set_compatible(Vector3.LEFT, ["wall", "empty"])
	corner_xz.set_compatible(Vector3.UP, ["empty"])
	corner_xz.set_compatible(Vector3.DOWN, ["corner_xz"])
	corner_xz.set_compatible(Vector3(0, 0, 1), ["corridor_z", "corner_xz", "junction"])
	corner_xz.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])
	wfc_grid.add_tile_type(corner_xz)

	# Corner piece (connects -X and Z)
	var corner_nxz = WFCTile.new("corner_-xz", 0.8)
	corner_nxz.color = Color(0.7, 0.9, 0.7)
	corner_nxz.set_compatible(Vector3.RIGHT, ["wall", "empty"])
	corner_nxz.set_compatible(Vector3.LEFT, ["corridor_x", "corner_-xz", "junction"])
	corner_nxz.set_compatible(Vector3.UP, ["empty"])
	corner_nxz.set_compatible(Vector3.DOWN, ["corner_-xz"])
	corner_nxz.set_compatible(Vector3(0, 0, 1), ["corridor_z", "corner_-xz", "junction"])
	corner_nxz.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])
	wfc_grid.add_tile_type(corner_nxz)

	# Corner piece (connects X and -Z)
	var corner_xnz = WFCTile.new("corner_x-z", 0.8)
	corner_xnz.color = Color(0.9, 0.7, 0.7)
	corner_xnz.set_compatible(Vector3.RIGHT, ["corridor_x", "corner_x-z", "junction"])
	corner_xnz.set_compatible(Vector3.LEFT, ["wall", "empty"])
	corner_xnz.set_compatible(Vector3.UP, ["empty"])
	corner_xnz.set_compatible(Vector3.DOWN, ["corner_x-z"])
	corner_xnz.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
	corner_xnz.set_compatible(Vector3(0, 0, -1), ["corridor_z", "corner_x-z", "junction"])
	wfc_grid.add_tile_type(corner_xnz)

	# Junction (4-way)
	var junction = WFCTile.new("junction", 0.3)
	junction.color = Color(0.9, 0.9, 0.5)
	junction.set_compatible(Vector3.RIGHT, ["corridor_x", "corner_xz", "corner_x-z", "junction"])
	junction.set_compatible(Vector3.LEFT, ["corridor_x", "corner_xz", "corner_x-z", "junction"])
	junction.set_compatible(Vector3.UP, ["empty"])
	junction.set_compatible(Vector3.DOWN, ["junction"])
	junction.set_compatible(Vector3(0, 0, 1), ["corridor_z", "corner_xz", "corner_-xz", "junction"])
	junction.set_compatible(Vector3(0, 0, -1), ["corridor_z", "corner_xz", "corner_-xz", "junction"])
	wfc_grid.add_tile_type(junction)

	# Wall
	var wall = WFCTile.new("wall", 3.0)
	wall.color = Color(0.3, 0.2, 0.15)
	wall.set_compatible(Vector3.RIGHT, ["wall", "empty", "corridor_z"])
	wall.set_compatible(Vector3.LEFT, ["wall", "empty", "corridor_z"])
	wall.set_compatible(Vector3.UP, ["empty", "wall"])
	wall.set_compatible(Vector3.DOWN, ["wall"])
	wall.set_compatible(Vector3(0, 0, 1), ["wall", "empty", "corridor_x"])
	wall.set_compatible(Vector3(0, 0, -1), ["wall", "empty", "corridor_x"])
	wfc_grid.add_tile_type(wall)

	# Empty/air
	var empty = WFCTile.new("empty", 5.0)
	empty.color = Color(0.05, 0.05, 0.05, 0.1)
	empty.set_compatible(Vector3.RIGHT, ["empty", "wall", "corridor_z", "corner_-xz"])
	empty.set_compatible(Vector3.LEFT, ["empty", "wall", "corridor_z", "corner_xz"])
	empty.set_compatible(Vector3.UP, ["empty"])
	empty.set_compatible(Vector3.DOWN, ["empty"])
	empty.set_compatible(Vector3(0, 0, 1), ["empty", "wall", "corridor_x", "corner_x-z"])
	empty.set_compatible(Vector3(0, 0, -1), ["empty", "wall", "corridor_x", "corner_xz"])
	wfc_grid.add_tile_type(empty)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("\n=== Generating Custom WFC Grid ===")
			wfc_grid.generate()
