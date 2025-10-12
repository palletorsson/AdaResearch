extends Node3D

# Room & Corridor Tileset for WFC
# Creates rooms connected by corridors with various opening directions

@onready var wfc_grid = $WFCGrid3D

func _ready():
	wfc_grid.tile_types.clear()
	wfc_grid.solver.tile_types.clear()

	create_room_corridor_tiles()

	print("=== Room & Corridor Tileset ===")
	print("Tile types:")
	print("  - Rooms (enclosed spaces)")
	print("  - Straight corridors (N-S, E-W)")
	print("  - Corner corridors (4 types)")
	print("  - T-junctions (4 types)")
	print("  - 4-way crossroads")
	print("  - Doorways (4 directions)")
	print("Press SPACE to generate")
	print("================================")

func create_room_corridor_tiles():
	"""Create a complete room and corridor tileset"""

	# ROOMS - Enclosed spaces
	var room = WFCTile.new("room", 0.5)
	room.color = Color(0.8, 0.6, 0.4)  # Tan/beige
	# Rooms can only connect to doorways on all sides
	room.set_compatible(Vector3.RIGHT, ["doorway_E", "wall", "empty"])
	room.set_compatible(Vector3.LEFT, ["doorway_W", "wall", "empty"])
	room.set_compatible(Vector3.UP, ["empty"])
	room.set_compatible(Vector3.DOWN, ["floor"])
	room.set_compatible(Vector3(0, 0, 1), ["doorway_S", "wall", "empty"])
	room.set_compatible(Vector3(0, 0, -1), ["doorway_N", "wall", "empty"])
	wfc_grid.add_tile_type(room)

	# DOORWAYS - Connect rooms to corridors
	create_doorway("doorway_N", Vector3(0, 0, -1), Color(0.9, 0.7, 0.5))  # North door
	create_doorway("doorway_S", Vector3(0, 0, 1), Color(0.9, 0.7, 0.5))   # South door
	create_doorway("doorway_E", Vector3.RIGHT, Color(0.9, 0.7, 0.5))      # East door
	create_doorway("doorway_W", Vector3.LEFT, Color(0.9, 0.7, 0.5))       # West door

	# STRAIGHT CORRIDORS
	# North-South corridor
	var corridor_ns = WFCTile.new("corridor_NS", 1.0)
	corridor_ns.color = Color(0.6, 0.6, 0.7)
	corridor_ns.set_compatible(Vector3.RIGHT, ["wall", "empty"])
	corridor_ns.set_compatible(Vector3.LEFT, ["wall", "empty"])
	corridor_ns.set_compatible(Vector3.UP, ["empty"])
	corridor_ns.set_compatible(Vector3.DOWN, ["floor"])
	corridor_ns.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross", "doorway_S"])
	corridor_ns.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross", "doorway_N"])
	wfc_grid.add_tile_type(corridor_ns)

	# East-West corridor
	var corridor_ew = WFCTile.new("corridor_EW", 1.0)
	corridor_ew.color = Color(0.6, 0.7, 0.6)
	corridor_ew.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross", "doorway_E"])
	corridor_ew.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross", "doorway_W"])
	corridor_ew.set_compatible(Vector3.UP, ["empty"])
	corridor_ew.set_compatible(Vector3.DOWN, ["floor"])
	corridor_ew.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
	corridor_ew.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])
	wfc_grid.add_tile_type(corridor_ew)

	# CORNER CORRIDORS
	# Northeast corner (opens to North and East)
	var corner_ne = WFCTile.new("corner_NE", 0.8)
	corner_ne.color = Color(0.7, 0.6, 0.8)
	corner_ne.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross", "doorway_E"])
	corner_ne.set_compatible(Vector3.LEFT, ["wall", "empty"])
	corner_ne.set_compatible(Vector3.UP, ["empty"])
	corner_ne.set_compatible(Vector3.DOWN, ["floor"])
	corner_ne.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
	corner_ne.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross", "doorway_N"])
	wfc_grid.add_tile_type(corner_ne)

	# Northwest corner
	var corner_nw = WFCTile.new("corner_NW", 0.8)
	corner_nw.color = Color(0.8, 0.6, 0.7)
	corner_nw.set_compatible(Vector3.RIGHT, ["wall", "empty"])
	corner_nw.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross", "doorway_W"])
	corner_nw.set_compatible(Vector3.UP, ["empty"])
	corner_nw.set_compatible(Vector3.DOWN, ["floor"])
	corner_nw.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
	corner_nw.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross", "doorway_N"])
	wfc_grid.add_tile_type(corner_nw)

	# Southeast corner
	var corner_se = WFCTile.new("corner_SE", 0.8)
	corner_se.color = Color(0.7, 0.8, 0.6)
	corner_se.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross", "doorway_E"])
	corner_se.set_compatible(Vector3.LEFT, ["wall", "empty"])
	corner_se.set_compatible(Vector3.UP, ["empty"])
	corner_se.set_compatible(Vector3.DOWN, ["floor"])
	corner_se.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross", "doorway_S"])
	corner_se.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])
	wfc_grid.add_tile_type(corner_se)

	# Southwest corner
	var corner_sw = WFCTile.new("corner_SW", 0.8)
	corner_sw.color = Color(0.6, 0.8, 0.7)
	corner_sw.set_compatible(Vector3.RIGHT, ["wall", "empty"])
	corner_sw.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross", "doorway_W"])
	corner_sw.set_compatible(Vector3.UP, ["empty"])
	corner_sw.set_compatible(Vector3.DOWN, ["floor"])
	corner_sw.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross", "doorway_S"])
	corner_sw.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])
	wfc_grid.add_tile_type(corner_sw)

	# T-JUNCTIONS (3-way intersections)
	# T-junction North (opens N, E, W)
	var tjunc_n = WFCTile.new("tjunc_N", 0.6)
	tjunc_n.color = Color(0.8, 0.7, 0.9)
	tjunc_n.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross", "doorway_E"])
	tjunc_n.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross", "doorway_W"])
	tjunc_n.set_compatible(Vector3.UP, ["empty"])
	tjunc_n.set_compatible(Vector3.DOWN, ["floor"])
	tjunc_n.set_compatible(Vector3(0, 0, 1), ["wall", "empty"])
	tjunc_n.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross", "doorway_N"])
	wfc_grid.add_tile_type(tjunc_n)

	# T-junction South (opens S, E, W)
	var tjunc_s = WFCTile.new("tjunc_S", 0.6)
	tjunc_s.color = Color(0.9, 0.7, 0.8)
	tjunc_s.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross", "doorway_E"])
	tjunc_s.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross", "doorway_W"])
	tjunc_s.set_compatible(Vector3.UP, ["empty"])
	tjunc_s.set_compatible(Vector3.DOWN, ["floor"])
	tjunc_s.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross", "doorway_S"])
	tjunc_s.set_compatible(Vector3(0, 0, -1), ["wall", "empty"])
	wfc_grid.add_tile_type(tjunc_s)

	# T-junction East (opens N, S, E)
	var tjunc_e = WFCTile.new("tjunc_E", 0.6)
	tjunc_e.color = Color(0.7, 0.9, 0.8)
	tjunc_e.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross", "doorway_E"])
	tjunc_e.set_compatible(Vector3.LEFT, ["wall", "empty"])
	tjunc_e.set_compatible(Vector3.UP, ["empty"])
	tjunc_e.set_compatible(Vector3.DOWN, ["floor"])
	tjunc_e.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross", "doorway_S"])
	tjunc_e.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross", "doorway_N"])
	wfc_grid.add_tile_type(tjunc_e)

	# T-junction West (opens N, S, W)
	var tjunc_w = WFCTile.new("tjunc_W", 0.6)
	tjunc_w.color = Color(0.8, 0.9, 0.7)
	tjunc_w.set_compatible(Vector3.RIGHT, ["wall", "empty"])
	tjunc_w.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross", "doorway_W"])
	tjunc_w.set_compatible(Vector3.UP, ["empty"])
	tjunc_w.set_compatible(Vector3.DOWN, ["floor"])
	tjunc_w.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross", "doorway_S"])
	tjunc_w.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross", "doorway_N"])
	wfc_grid.add_tile_type(tjunc_w)

	# 4-WAY CROSSROADS
	var cross = WFCTile.new("cross", 0.3)
	cross.color = Color(0.9, 0.9, 0.7)
	cross.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross", "doorway_E"])
	cross.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross", "doorway_W"])
	cross.set_compatible(Vector3.UP, ["empty"])
	cross.set_compatible(Vector3.DOWN, ["floor"])
	cross.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross", "doorway_S"])
	cross.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross", "doorway_N"])
	wfc_grid.add_tile_type(cross)

	# SUPPORT TILES
	add_support_tiles()

func create_doorway(id: String, opens_to: Vector3, col: Color):
	"""Create a doorway tile that opens in one direction"""
	var door = WFCTile.new(id, 0.7)
	door.color = col

	# Doorway connects room to corridor in one direction
	if opens_to == Vector3.RIGHT:  # East doorway
		door.set_compatible(Vector3.RIGHT, ["corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "cross"])
		door.set_compatible(Vector3.LEFT, ["room"])
		door.set_compatible(Vector3(0, 0, 1), ["wall", "room"])
		door.set_compatible(Vector3(0, 0, -1), ["wall", "room"])
	elif opens_to == Vector3.LEFT:  # West doorway
		door.set_compatible(Vector3.RIGHT, ["room"])
		door.set_compatible(Vector3.LEFT, ["corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "cross"])
		door.set_compatible(Vector3(0, 0, 1), ["wall", "room"])
		door.set_compatible(Vector3(0, 0, -1), ["wall", "room"])
	elif opens_to == Vector3(0, 0, 1):  # South doorway
		door.set_compatible(Vector3.RIGHT, ["wall", "room"])
		door.set_compatible(Vector3.LEFT, ["wall", "room"])
		door.set_compatible(Vector3(0, 0, 1), ["corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "cross"])
		door.set_compatible(Vector3(0, 0, -1), ["room"])
	elif opens_to == Vector3(0, 0, -1):  # North doorway
		door.set_compatible(Vector3.RIGHT, ["wall", "room"])
		door.set_compatible(Vector3.LEFT, ["wall", "room"])
		door.set_compatible(Vector3(0, 0, 1), ["room"])
		door.set_compatible(Vector3(0, 0, -1), ["corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "cross"])

	door.set_compatible(Vector3.UP, ["empty"])
	door.set_compatible(Vector3.DOWN, ["floor"])
	wfc_grid.add_tile_type(door)

func add_support_tiles():
	"""Add wall, floor, and empty tiles"""
	# Wall
	var wall = WFCTile.new("wall", 3.0)
	wall.color = Color(0.3, 0.3, 0.35)
	wall.set_compatible(Vector3.RIGHT, ["wall", "empty", "room", "doorway_E", "doorway_W", "doorway_N", "doorway_S"])
	wall.set_compatible(Vector3.LEFT, ["wall", "empty", "room", "doorway_E", "doorway_W", "doorway_N", "doorway_S"])
	wall.set_compatible(Vector3.UP, ["wall", "empty"])
	wall.set_compatible(Vector3.DOWN, ["wall", "floor"])
	wall.set_compatible(Vector3(0, 0, 1), ["wall", "empty", "corridor_NS", "corner_NE", "corner_NW", "tjunc_N", "tjunc_E", "tjunc_W", "doorway_N", "doorway_S", "room"])
	wall.set_compatible(Vector3(0, 0, -1), ["wall", "empty", "corridor_NS", "corner_SE", "corner_SW", "tjunc_S", "tjunc_E", "tjunc_W", "doorway_N", "doorway_S", "room"])
	wfc_grid.add_tile_type(wall)

	# Floor
	var floor = WFCTile.new("floor", 2.0)
	floor.color = Color(0.4, 0.35, 0.3)
	floor.set_compatible(Vector3.RIGHT, ["floor", "wall"])
	floor.set_compatible(Vector3.LEFT, ["floor", "wall"])
	floor.set_compatible(Vector3.UP, ["room", "corridor_NS", "corridor_EW", "corner_NE", "corner_NW", "corner_SE", "corner_SW", "tjunc_N", "tjunc_S", "tjunc_E", "tjunc_W", "cross", "doorway_N", "doorway_S", "doorway_E", "doorway_W"])
	floor.set_compatible(Vector3.DOWN, ["floor"])
	floor.set_compatible(Vector3(0, 0, 1), ["floor", "wall"])
	floor.set_compatible(Vector3(0, 0, -1), ["floor", "wall"])
	wfc_grid.add_tile_type(floor)

	# Empty
	var empty = WFCTile.new("empty", 4.0)
	empty.color = Color(0.05, 0.05, 0.05, 0.05)
	empty.set_compatible(Vector3.RIGHT, ["empty", "wall", "room", "doorway_E", "doorway_W"])
	empty.set_compatible(Vector3.LEFT, ["empty", "wall", "room", "doorway_E", "doorway_W"])
	empty.set_compatible(Vector3.UP, ["empty"])
	empty.set_compatible(Vector3.DOWN, ["empty", "room", "corridor_NS", "corridor_EW", "corner_NE", "corner_NW", "corner_SE", "corner_SW", "tjunc_N", "tjunc_S", "tjunc_E", "tjunc_W", "cross"])
	empty.set_compatible(Vector3(0, 0, 1), ["empty", "wall", "corridor_EW", "corner_NE", "corner_SE", "tjunc_E", "tjunc_N", "tjunc_S", "doorway_N", "doorway_S", "room"])
	empty.set_compatible(Vector3(0, 0, -1), ["empty", "wall", "corridor_EW", "corner_NW", "corner_SW", "tjunc_W", "tjunc_N", "tjunc_S", "doorway_N", "doorway_S", "room"])
	wfc_grid.add_tile_type(empty)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				print("\n=== Generating Room & Corridor Grid ===")
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
	print("Total tiles: ", wfc_grid.tile_nodes.size())
