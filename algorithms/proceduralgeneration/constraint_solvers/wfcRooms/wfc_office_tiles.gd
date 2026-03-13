# res://algorithms/proceduralgeneration/constraint_solvers/wfcRooms/wfc_office_tiles.gd
# Godot 4.x — Run from the Script Editor (EditorScript → Run).
# Generates office floor plan tiles for WFC procedural generation
@tool
extends EditorScript

# Office dimensions (larger than dungeon tiles)
const TILE_SIZE   := 4.0      # 4m x 4m office modules
const FLOOR_THICK := 0.05     # Floor slab thickness
const WALL_THICK  := 0.12     # Office wall thickness (12cm)
const WALL_HEIGHT := 2.8      # Standard office ceiling height
const DOOR_WIDTH  := 0.9      # Standard door width (90cm)
const DOOR_HEIGHT := 2.1      # Standard door height
const GLASS_HEIGHT := 2.4     # Glass partition height
const CUBICLE_HEIGHT := 1.5   # Cubicle partition height

const GRID_COLS   := 5
const GRID_GAP    := 4.5      # Visual spacing between tiles in preview

# Office color palette
const COLOR_FLOOR_CARPET := Color(0.45, 0.42, 0.40, 1.0)      # Gray carpet
const COLOR_FLOOR_TILE   := Color(0.85, 0.85, 0.82, 1.0)      # Light tile floor
const COLOR_WALL         := Color(0.92, 0.91, 0.88, 1.0)      # Off-white walls
const COLOR_GLASS        := Color(0.7, 0.85, 0.95, 0.35)      # Tinted glass
const COLOR_GLASS_FRAME  := Color(0.3, 0.3, 0.35, 1.0)        # Dark aluminum frame
const COLOR_CUBICLE      := Color(0.6, 0.58, 0.55, 1.0)       # Cubicle fabric
const COLOR_WOOD         := Color(0.55, 0.35, 0.2, 1.0)       # Wood door/trim

func _run() -> void:
	# --- Define Office Tile Set ---
	# Socket types:
	#   "open"     - Open space (connects to open)
	#   "wall"     - Solid wall (connects to wall)
	#   "door"     - Standard door opening (connects to door)
	#   "glass"    - Glass partition (connects to glass)
	#   "corridor" - Corridor opening (connects to corridor)
	#   "cubicle"  - Cubicle partition (connects to cubicle)

	var tiles : Array = [
		# === OPEN PLAN AREAS ===
		["OpenPlan",        {"N":"open", "E":"open", "S":"open", "W":"open"}, "carpet", "open_plan"],
		["OpenPlan_Wall_N", {"N":"wall", "E":"open", "S":"open", "W":"open"}, "carpet", "open_plan"],
		["OpenPlan_Wall_E", {"N":"open", "E":"wall", "S":"open", "W":"open"}, "carpet", "open_plan"],
		["OpenPlan_Wall_S", {"N":"open", "E":"open", "S":"wall", "W":"open"}, "carpet", "open_plan"],
		["OpenPlan_Wall_W", {"N":"open", "E":"open", "S":"open", "W":"wall"}, "carpet", "open_plan"],

		# === CORRIDORS ===
		["Corridor_NS",     {"N":"corridor", "E":"wall", "S":"corridor", "W":"wall"}, "tile", "corridor"],
		["Corridor_EW",     {"N":"wall", "E":"corridor", "S":"wall", "W":"corridor"}, "tile", "corridor"],
		["Corridor_Corner_NE", {"N":"corridor", "E":"corridor", "S":"wall", "W":"wall"}, "tile", "corridor"],
		["Corridor_Corner_ES", {"N":"wall", "E":"corridor", "S":"corridor", "W":"wall"}, "tile", "corridor"],
		["Corridor_Corner_SW", {"N":"wall", "E":"wall", "S":"corridor", "W":"corridor"}, "tile", "corridor"],
		["Corridor_Corner_WN", {"N":"corridor", "E":"wall", "S":"wall", "W":"corridor"}, "tile", "corridor"],
		["Corridor_T_NES",  {"N":"corridor", "E":"corridor", "S":"corridor", "W":"wall"}, "tile", "corridor"],
		["Corridor_T_ESW",  {"N":"wall", "E":"corridor", "S":"corridor", "W":"corridor"}, "tile", "corridor"],
		["Corridor_T_SWN",  {"N":"corridor", "E":"wall", "S":"corridor", "W":"corridor"}, "tile", "corridor"],
		["Corridor_T_WNE",  {"N":"corridor", "E":"corridor", "S":"wall", "W":"corridor"}, "tile", "corridor"],
		["Corridor_Cross",  {"N":"corridor", "E":"corridor", "S":"corridor", "W":"corridor"}, "tile", "corridor"],

		# === PRIVATE OFFICES (glass front, solid walls) ===
		["Office_Door_N",   {"N":"door", "E":"wall", "S":"wall", "W":"wall"}, "carpet", "office"],
		["Office_Door_E",   {"N":"wall", "E":"door", "S":"wall", "W":"wall"}, "carpet", "office"],
		["Office_Door_S",   {"N":"wall", "E":"wall", "S":"door", "W":"wall"}, "carpet", "office"],
		["Office_Door_W",   {"N":"wall", "E":"wall", "S":"wall", "W":"door"}, "carpet", "office"],

		# === CONFERENCE ROOMS (glass walls) ===
		["Conference_Glass_N", {"N":"glass", "E":"wall", "S":"wall", "W":"wall"}, "carpet", "conference"],
		["Conference_Glass_E", {"N":"wall", "E":"glass", "S":"wall", "W":"wall"}, "carpet", "conference"],
		["Conference_Glass_S", {"N":"wall", "E":"wall", "S":"glass", "W":"wall"}, "carpet", "conference"],
		["Conference_Glass_W", {"N":"wall", "E":"wall", "S":"wall", "W":"glass"}, "carpet", "conference"],
		["Conference_Glass_NE", {"N":"glass", "E":"glass", "S":"wall", "W":"wall"}, "carpet", "conference"],
		["Conference_Glass_ES", {"N":"wall", "E":"glass", "S":"glass", "W":"wall"}, "carpet", "conference"],
		["Conference_Glass_SW", {"N":"wall", "E":"wall", "S":"glass", "W":"glass"}, "carpet", "conference"],
		["Conference_Glass_WN", {"N":"glass", "E":"wall", "S":"wall", "W":"glass"}, "carpet", "conference"],

		# === CUBICLE AREAS ===
		["Cubicle_Open",    {"N":"cubicle", "E":"cubicle", "S":"cubicle", "W":"cubicle"}, "carpet", "cubicle"],
		["Cubicle_Wall_N",  {"N":"wall", "E":"cubicle", "S":"cubicle", "W":"cubicle"}, "carpet", "cubicle"],
		["Cubicle_Wall_E",  {"N":"cubicle", "E":"wall", "S":"cubicle", "W":"cubicle"}, "carpet", "cubicle"],
		["Cubicle_Wall_S",  {"N":"cubicle", "E":"cubicle", "S":"wall", "W":"cubicle"}, "carpet", "cubicle"],
		["Cubicle_Wall_W",  {"N":"cubicle", "E":"cubicle", "S":"cubicle", "W":"wall"}, "carpet", "cubicle"],

		# === TRANSITION TILES (connect different areas) ===
		# Corridor to Office door
		["Trans_Corridor_Office_N", {"N":"door", "E":"wall", "S":"corridor", "W":"wall"}, "tile", "transition"],
		["Trans_Corridor_Office_E", {"N":"wall", "E":"door", "S":"wall", "W":"corridor"}, "tile", "transition"],
		["Trans_Corridor_Office_S", {"N":"corridor", "E":"wall", "S":"door", "W":"wall"}, "tile", "transition"],
		["Trans_Corridor_Office_W", {"N":"wall", "E":"corridor", "S":"wall", "W":"door"}, "tile", "transition"],

		# Corridor to Open Plan
		["Trans_Corridor_Open_N", {"N":"open", "E":"wall", "S":"corridor", "W":"wall"}, "tile", "transition"],
		["Trans_Corridor_Open_E", {"N":"wall", "E":"open", "S":"wall", "W":"corridor"}, "tile", "transition"],
		["Trans_Corridor_Open_S", {"N":"corridor", "E":"wall", "S":"open", "W":"wall"}, "tile", "transition"],
		["Trans_Corridor_Open_W", {"N":"wall", "E":"corridor", "S":"wall", "W":"open"}, "tile", "transition"],

		# Corridor to Glass (conference room entrance)
		["Trans_Corridor_Glass_N", {"N":"glass", "E":"wall", "S":"corridor", "W":"wall"}, "tile", "transition"],
		["Trans_Corridor_Glass_E", {"N":"wall", "E":"glass", "S":"wall", "W":"corridor"}, "tile", "transition"],
		["Trans_Corridor_Glass_S", {"N":"corridor", "E":"wall", "S":"glass", "W":"wall"}, "tile", "transition"],
		["Trans_Corridor_Glass_W", {"N":"wall", "E":"corridor", "S":"wall", "W":"glass"}, "tile", "transition"],

		# Open Plan to Cubicle
		["Trans_Open_Cubicle_N", {"N":"cubicle", "E":"open", "S":"open", "W":"open"}, "carpet", "transition"],
		["Trans_Open_Cubicle_E", {"N":"open", "E":"cubicle", "S":"open", "W":"open"}, "carpet", "transition"],
		["Trans_Open_Cubicle_S", {"N":"open", "E":"open", "S":"cubicle", "W":"open"}, "carpet", "transition"],
		["Trans_Open_Cubicle_W", {"N":"open", "E":"open", "S":"open", "W":"cubicle"}, "carpet", "transition"],

		# === UTILITY ROOMS ===
		["Utility_Door_N",  {"N":"door", "E":"wall", "S":"wall", "W":"wall"}, "tile", "utility"],
		["Utility_Door_E",  {"N":"wall", "E":"door", "S":"wall", "W":"wall"}, "tile", "utility"],
		["Utility_Door_S",  {"N":"wall", "E":"wall", "S":"door", "W":"wall"}, "tile", "utility"],
		["Utility_Door_W",  {"N":"wall", "E":"wall", "S":"wall", "W":"door"}, "tile", "utility"],

		# === RECEPTION / LOBBY ===
		["Reception_NS",    {"N":"open", "E":"wall", "S":"open", "W":"wall"}, "tile", "reception"],
		["Reception_EW",    {"N":"wall", "E":"open", "S":"wall", "W":"open"}, "tile", "reception"],

		# === CORNER PIECES (exterior walls) ===
		["Corner_NE",       {"N":"wall", "E":"wall", "S":"open", "W":"open"}, "carpet", "corner"],
		["Corner_ES",       {"N":"open", "E":"wall", "S":"wall", "W":"open"}, "carpet", "corner"],
		["Corner_SW",       {"N":"open", "E":"open", "S":"wall", "W":"wall"}, "carpet", "corner"],
		["Corner_WN",       {"N":"wall", "E":"open", "S":"open", "W":"wall"}, "carpet", "corner"],
	]

	# --- Build the root preview scene ---
	var root := Node3D.new()
	root.name = "OfficeTiles"
	_add_preview_camera_and_light(root)

	# Build tiles and place in grid
	var built : Array[Node3D] = []
	for i in tiles.size():
		var tile_name = tiles[i][0]
		var sockets = tiles[i][1]
		var floor_type = tiles[i][2]
		var room_type = tiles[i][3]
		var t := _build_office_tile(tile_name, sockets, floor_type, room_type)

		# Grid placement
		var r := i / GRID_COLS
		var c := i % GRID_COLS
		t.transform.origin = Vector3(c * GRID_GAP, 0.0, r * GRID_GAP)

		root.add_child(t, false)
		t.owner = root
		_set_owner_recursive(t, root)
		t.add_to_group("tile", true)

		built.append(t)

	# Center the grid around origin
	if built.size() > 0:
		var cols = min(GRID_COLS, built.size())
		var rows := int(ceil(float(built.size()) / float(GRID_COLS)))
		var offset := Vector3((cols-1) * GRID_GAP * 0.5, 0.0, (rows-1) * GRID_GAP * 0.5)
		for o in built:
			o.transform.origin -= offset

	# --- Save as .tscn ---
	print("Packing office scene with ", root.get_child_count(), " children...")

	var scene := PackedScene.new()
	var ok := scene.pack(root)
	if ok != OK:
		push_error("Failed to pack scene. Error code: ", ok)
		return

	var path := "res://algorithms/proceduralgeneration/constraint_solvers/wfcRooms/OfficeTiles.tscn"
	var save_ok := ResourceSaver.save(scene, path)
	if save_ok != OK:
		push_error("Failed to save: %s (Error: %d)" % [path, save_ok])
		return

	print("Saved: ", path, " with ", built.size(), " office tiles")
	get_editor_interface().open_scene_from_path(path)

# ===== Tile Building =====

func _build_office_tile(tile_name: String, sockets: Dictionary, floor_type: String, room_type: String) -> Node3D:
	var tile := Node3D.new()
	tile.name = tile_name
	tile.set_meta("sockets", sockets)
	tile.set_meta("floor_type", floor_type)
	tile.set_meta("room_type", room_type)

	# Footprint visualization
	var foot := _make_plane_mesh(TILE_SIZE, TILE_SIZE, Color(0.5, 0.5, 0.55, 0.15))
	foot.name = "Footprint"
	foot.transform.origin = Vector3(TILE_SIZE * 0.5, 0.001, TILE_SIZE * 0.5)
	tile.add_child(foot, false)

	# Floor slab
	var floor_color = COLOR_FLOOR_CARPET if floor_type == "carpet" else COLOR_FLOOR_TILE
	var floor_box = _add_box_csg("Floor", Vector3(0, 0, 0), Vector3(TILE_SIZE, FLOOR_THICK, TILE_SIZE), floor_color)
	tile.add_child(floor_box, false)

	# Build walls/partitions based on sockets
	for side in ["N", "E", "S", "W"]:
		var socket_type = String(sockets.get(side, "open"))
		match socket_type:
			"wall":
				_place_solid_wall(tile, side)
			"door":
				_place_door_wall(tile, side)
			"glass":
				_place_glass_wall(tile, side)
			"corridor":
				# Corridor openings have no wall
				pass
			"cubicle":
				_place_cubicle_partition(tile, side)
			"open":
				# Open = no barrier
				pass

	# Add room-specific furniture/details
	_add_room_details(tile, room_type, sockets)

	return tile

func _place_solid_wall(parent: Node3D, side: String) -> void:
	var min_v: Vector3
	var max_v: Vector3
	var y_base = FLOOR_THICK
	var y_top = FLOOR_THICK + WALL_HEIGHT

	match side:
		"N":
			min_v = Vector3(0, y_base, TILE_SIZE - WALL_THICK)
			max_v = Vector3(TILE_SIZE, y_top, TILE_SIZE)
		"S":
			min_v = Vector3(0, y_base, 0)
			max_v = Vector3(TILE_SIZE, y_top, WALL_THICK)
		"E":
			min_v = Vector3(TILE_SIZE - WALL_THICK, y_base, 0)
			max_v = Vector3(TILE_SIZE, y_top, TILE_SIZE)
		"W":
			min_v = Vector3(0, y_base, 0)
			max_v = Vector3(WALL_THICK, y_top, TILE_SIZE)

	var wall = _add_box_csg("Wall_" + side, min_v, max_v, COLOR_WALL)
	parent.add_child(wall, false)

func _place_door_wall(parent: Node3D, side: String) -> void:
	var y_base = FLOOR_THICK
	var y_top = FLOOR_THICK + WALL_HEIGHT
	var door_lintel_y = FLOOR_THICK + DOOR_HEIGHT

	var gap = clamp(DOOR_WIDTH, 0.0, TILE_SIZE - 2.0 * WALL_THICK)
	var seg = 0.5 * (TILE_SIZE - gap)

	match side:
		"N":
			# Left segment
			parent.add_child(_add_box_csg("Wall_N_L",
				Vector3(0, y_base, TILE_SIZE - WALL_THICK),
				Vector3(seg, y_top, TILE_SIZE), COLOR_WALL), false)
			# Right segment
			parent.add_child(_add_box_csg("Wall_N_R",
				Vector3(TILE_SIZE - seg, y_base, TILE_SIZE - WALL_THICK),
				Vector3(TILE_SIZE, y_top, TILE_SIZE), COLOR_WALL), false)
			# Lintel above door
			parent.add_child(_add_box_csg("Lintel_N",
				Vector3(seg, door_lintel_y, TILE_SIZE - WALL_THICK),
				Vector3(TILE_SIZE - seg, y_top, TILE_SIZE), COLOR_WALL), false)
			# Door frame
			_add_door_frame(parent, side, seg, TILE_SIZE - seg)
		"S":
			parent.add_child(_add_box_csg("Wall_S_L",
				Vector3(0, y_base, 0),
				Vector3(seg, y_top, WALL_THICK), COLOR_WALL), false)
			parent.add_child(_add_box_csg("Wall_S_R",
				Vector3(TILE_SIZE - seg, y_base, 0),
				Vector3(TILE_SIZE, y_top, WALL_THICK), COLOR_WALL), false)
			parent.add_child(_add_box_csg("Lintel_S",
				Vector3(seg, door_lintel_y, 0),
				Vector3(TILE_SIZE - seg, y_top, WALL_THICK), COLOR_WALL), false)
			_add_door_frame(parent, side, seg, TILE_SIZE - seg)
		"E":
			parent.add_child(_add_box_csg("Wall_E_B",
				Vector3(TILE_SIZE - WALL_THICK, y_base, 0),
				Vector3(TILE_SIZE, y_top, seg), COLOR_WALL), false)
			parent.add_child(_add_box_csg("Wall_E_T",
				Vector3(TILE_SIZE - WALL_THICK, y_base, TILE_SIZE - seg),
				Vector3(TILE_SIZE, y_top, TILE_SIZE), COLOR_WALL), false)
			parent.add_child(_add_box_csg("Lintel_E",
				Vector3(TILE_SIZE - WALL_THICK, door_lintel_y, seg),
				Vector3(TILE_SIZE, y_top, TILE_SIZE - seg), COLOR_WALL), false)
			_add_door_frame(parent, side, seg, TILE_SIZE - seg)
		"W":
			parent.add_child(_add_box_csg("Wall_W_B",
				Vector3(0, y_base, 0),
				Vector3(WALL_THICK, y_top, seg), COLOR_WALL), false)
			parent.add_child(_add_box_csg("Wall_W_T",
				Vector3(0, y_base, TILE_SIZE - seg),
				Vector3(WALL_THICK, y_top, TILE_SIZE), COLOR_WALL), false)
			parent.add_child(_add_box_csg("Lintel_W",
				Vector3(0, door_lintel_y, seg),
				Vector3(WALL_THICK, y_top, TILE_SIZE - seg), COLOR_WALL), false)
			_add_door_frame(parent, side, seg, TILE_SIZE - seg)

func _add_door_frame(parent: Node3D, side: String, start: float, end: float) -> void:
	var frame_width = 0.05
	var y_base = FLOOR_THICK
	var door_top = FLOOR_THICK + DOOR_HEIGHT

	# Add wood door frame trim
	match side:
		"N", "S":
			var z_pos = TILE_SIZE - WALL_THICK * 0.5 if side == "N" else WALL_THICK * 0.5
			# Left frame
			parent.add_child(_add_box_csg("DoorFrame_L",
				Vector3(start - frame_width, y_base, z_pos - frame_width),
				Vector3(start, door_top, z_pos + frame_width), COLOR_WOOD), false)
			# Right frame
			parent.add_child(_add_box_csg("DoorFrame_R",
				Vector3(end, y_base, z_pos - frame_width),
				Vector3(end + frame_width, door_top, z_pos + frame_width), COLOR_WOOD), false)
		"E", "W":
			var x_pos = TILE_SIZE - WALL_THICK * 0.5 if side == "E" else WALL_THICK * 0.5
			# Bottom frame
			parent.add_child(_add_box_csg("DoorFrame_B",
				Vector3(x_pos - frame_width, y_base, start - frame_width),
				Vector3(x_pos + frame_width, door_top, start), COLOR_WOOD), false)
			# Top frame
			parent.add_child(_add_box_csg("DoorFrame_T",
				Vector3(x_pos - frame_width, y_base, end),
				Vector3(x_pos + frame_width, door_top, end + frame_width), COLOR_WOOD), false)

func _place_glass_wall(parent: Node3D, side: String) -> void:
	var y_base = FLOOR_THICK
	var y_top = FLOOR_THICK + GLASS_HEIGHT
	var frame_size = 0.04  # Aluminum frame thickness

	var min_v: Vector3
	var max_v: Vector3

	match side:
		"N":
			min_v = Vector3(frame_size, y_base, TILE_SIZE - frame_size)
			max_v = Vector3(TILE_SIZE - frame_size, y_top, TILE_SIZE)
		"S":
			min_v = Vector3(frame_size, y_base, 0)
			max_v = Vector3(TILE_SIZE - frame_size, y_top, frame_size)
		"E":
			min_v = Vector3(TILE_SIZE - frame_size, y_base, frame_size)
			max_v = Vector3(TILE_SIZE, y_top, TILE_SIZE - frame_size)
		"W":
			min_v = Vector3(0, y_base, frame_size)
			max_v = Vector3(frame_size, y_top, TILE_SIZE - frame_size)

	# Glass panel
	var glass = _add_box_csg("Glass_" + side, min_v, max_v, COLOR_GLASS, true)
	parent.add_child(glass, false)

	# Add aluminum frame around glass
	_add_glass_frame(parent, side, y_base, y_top)

func _add_glass_frame(parent: Node3D, side: String, y_base: float, y_top: float) -> void:
	var f = 0.04  # Frame size

	match side:
		"N":
			# Bottom rail
			parent.add_child(_add_box_csg("Frame_N_B", Vector3(0, y_base, TILE_SIZE - f), Vector3(TILE_SIZE, y_base + f, TILE_SIZE), COLOR_GLASS_FRAME), false)
			# Top rail
			parent.add_child(_add_box_csg("Frame_N_T", Vector3(0, y_top - f, TILE_SIZE - f), Vector3(TILE_SIZE, y_top, TILE_SIZE), COLOR_GLASS_FRAME), false)
			# Left post
			parent.add_child(_add_box_csg("Frame_N_L", Vector3(0, y_base, TILE_SIZE - f), Vector3(f, y_top, TILE_SIZE), COLOR_GLASS_FRAME), false)
			# Right post
			parent.add_child(_add_box_csg("Frame_N_R", Vector3(TILE_SIZE - f, y_base, TILE_SIZE - f), Vector3(TILE_SIZE, y_top, TILE_SIZE), COLOR_GLASS_FRAME), false)
		"S":
			parent.add_child(_add_box_csg("Frame_S_B", Vector3(0, y_base, 0), Vector3(TILE_SIZE, y_base + f, f), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_S_T", Vector3(0, y_top - f, 0), Vector3(TILE_SIZE, y_top, f), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_S_L", Vector3(0, y_base, 0), Vector3(f, y_top, f), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_S_R", Vector3(TILE_SIZE - f, y_base, 0), Vector3(TILE_SIZE, y_top, f), COLOR_GLASS_FRAME), false)
		"E":
			parent.add_child(_add_box_csg("Frame_E_B", Vector3(TILE_SIZE - f, y_base, 0), Vector3(TILE_SIZE, y_base + f, TILE_SIZE), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_E_T", Vector3(TILE_SIZE - f, y_top - f, 0), Vector3(TILE_SIZE, y_top, TILE_SIZE), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_E_L", Vector3(TILE_SIZE - f, y_base, 0), Vector3(TILE_SIZE, y_top, f), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_E_R", Vector3(TILE_SIZE - f, y_base, TILE_SIZE - f), Vector3(TILE_SIZE, y_top, TILE_SIZE), COLOR_GLASS_FRAME), false)
		"W":
			parent.add_child(_add_box_csg("Frame_W_B", Vector3(0, y_base, 0), Vector3(f, y_base + f, TILE_SIZE), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_W_T", Vector3(0, y_top - f, 0), Vector3(f, y_top, TILE_SIZE), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_W_L", Vector3(0, y_base, 0), Vector3(f, y_top, f), COLOR_GLASS_FRAME), false)
			parent.add_child(_add_box_csg("Frame_W_R", Vector3(0, y_base, TILE_SIZE - f), Vector3(f, y_top, TILE_SIZE), COLOR_GLASS_FRAME), false)

func _place_cubicle_partition(parent: Node3D, side: String) -> void:
	var y_base = FLOOR_THICK
	var y_top = FLOOR_THICK + CUBICLE_HEIGHT
	var part_thick = 0.06  # Cubicle partition thickness

	var min_v: Vector3
	var max_v: Vector3

	# Leave gaps at corners for walkways
	var gap = 0.8  # Gap size at each end

	match side:
		"N":
			min_v = Vector3(gap, y_base, TILE_SIZE - part_thick)
			max_v = Vector3(TILE_SIZE - gap, y_top, TILE_SIZE)
		"S":
			min_v = Vector3(gap, y_base, 0)
			max_v = Vector3(TILE_SIZE - gap, y_top, part_thick)
		"E":
			min_v = Vector3(TILE_SIZE - part_thick, y_base, gap)
			max_v = Vector3(TILE_SIZE, y_top, TILE_SIZE - gap)
		"W":
			min_v = Vector3(0, y_base, gap)
			max_v = Vector3(part_thick, y_top, TILE_SIZE - gap)

	var partition = _add_box_csg("Cubicle_" + side, min_v, max_v, COLOR_CUBICLE)
	parent.add_child(partition, false)

	# Add top cap
	var cap_height = 0.03
	match side:
		"N":
			parent.add_child(_add_box_csg("CubCap_N",
				Vector3(gap, y_top, TILE_SIZE - part_thick - 0.01),
				Vector3(TILE_SIZE - gap, y_top + cap_height, TILE_SIZE + 0.01), COLOR_GLASS_FRAME), false)
		"S":
			parent.add_child(_add_box_csg("CubCap_S",
				Vector3(gap, y_top, -0.01),
				Vector3(TILE_SIZE - gap, y_top + cap_height, part_thick + 0.01), COLOR_GLASS_FRAME), false)
		"E":
			parent.add_child(_add_box_csg("CubCap_E",
				Vector3(TILE_SIZE - part_thick - 0.01, y_top, gap),
				Vector3(TILE_SIZE + 0.01, y_top + cap_height, TILE_SIZE - gap), COLOR_GLASS_FRAME), false)
		"W":
			parent.add_child(_add_box_csg("CubCap_W",
				Vector3(-0.01, y_top, gap),
				Vector3(part_thick + 0.01, y_top + cap_height, TILE_SIZE - gap), COLOR_GLASS_FRAME), false)

func _add_room_details(parent: Node3D, room_type: String, sockets: Dictionary) -> void:
	var center = Vector3(TILE_SIZE * 0.5, FLOOR_THICK, TILE_SIZE * 0.5)

	match room_type:
		"office":
			# Add a desk
			_add_desk(parent, center + Vector3(0, 0, 0.5))
		"conference":
			# Add conference table
			_add_conference_table(parent, center)
		"cubicle":
			# Add small desk
			_add_cubicle_desk(parent, center)
		"reception":
			# Add reception desk
			_add_reception_desk(parent, center)
		"utility":
			# Add utility shelf/cabinet
			_add_utility_cabinet(parent, center)

func _add_desk(parent: Node3D, pos: Vector3) -> void:
	var desk_w = 1.5
	var desk_d = 0.75
	var desk_h = 0.75
	var leg_size = 0.06

	# Desktop
	parent.add_child(_add_box_csg("Desk_Top",
		pos + Vector3(-desk_w/2, desk_h - 0.03, -desk_d/2),
		pos + Vector3(desk_w/2, desk_h, desk_d/2), COLOR_WOOD), false)

	# Legs
	parent.add_child(_add_box_csg("Desk_Leg1",
		pos + Vector3(-desk_w/2 + 0.05, 0, -desk_d/2 + 0.05),
		pos + Vector3(-desk_w/2 + 0.05 + leg_size, desk_h - 0.03, -desk_d/2 + 0.05 + leg_size), COLOR_GLASS_FRAME), false)
	parent.add_child(_add_box_csg("Desk_Leg2",
		pos + Vector3(desk_w/2 - 0.05 - leg_size, 0, -desk_d/2 + 0.05),
		pos + Vector3(desk_w/2 - 0.05, desk_h - 0.03, -desk_d/2 + 0.05 + leg_size), COLOR_GLASS_FRAME), false)
	parent.add_child(_add_box_csg("Desk_Leg3",
		pos + Vector3(-desk_w/2 + 0.05, 0, desk_d/2 - 0.05 - leg_size),
		pos + Vector3(-desk_w/2 + 0.05 + leg_size, desk_h - 0.03, desk_d/2 - 0.05), COLOR_GLASS_FRAME), false)
	parent.add_child(_add_box_csg("Desk_Leg4",
		pos + Vector3(desk_w/2 - 0.05 - leg_size, 0, desk_d/2 - 0.05 - leg_size),
		pos + Vector3(desk_w/2 - 0.05, desk_h - 0.03, desk_d/2 - 0.05), COLOR_GLASS_FRAME), false)

func _add_conference_table(parent: Node3D, pos: Vector3) -> void:
	var table_w = 2.4
	var table_d = 1.2
	var table_h = 0.75

	# Table top
	parent.add_child(_add_box_csg("ConfTable_Top",
		pos + Vector3(-table_w/2, table_h - 0.04, -table_d/2),
		pos + Vector3(table_w/2, table_h, table_d/2), COLOR_WOOD), false)

	# Central pedestal
	parent.add_child(_add_box_csg("ConfTable_Base",
		pos + Vector3(-0.3, 0, -0.3),
		pos + Vector3(0.3, table_h - 0.04, 0.3), COLOR_GLASS_FRAME), false)

func _add_cubicle_desk(parent: Node3D, pos: Vector3) -> void:
	var desk_w = 1.2
	var desk_d = 0.6
	var desk_h = 0.72

	# Simple desk surface
	parent.add_child(_add_box_csg("CubDesk",
		pos + Vector3(-desk_w/2, desk_h - 0.025, -desk_d/2),
		pos + Vector3(desk_w/2, desk_h, desk_d/2), Color(0.7, 0.68, 0.65)), false)

func _add_reception_desk(parent: Node3D, pos: Vector3) -> void:
	var desk_w = 2.0
	var desk_d = 0.8
	var desk_h = 1.1  # Counter height

	# Main counter
	parent.add_child(_add_box_csg("RecepDesk",
		pos + Vector3(-desk_w/2, 0, -desk_d/2),
		pos + Vector3(desk_w/2, desk_h, desk_d/2), COLOR_WOOD), false)

	# Front panel (angled or straight)
	parent.add_child(_add_box_csg("RecepFront",
		pos + Vector3(-desk_w/2, 0, desk_d/2),
		pos + Vector3(desk_w/2, desk_h * 0.7, desk_d/2 + 0.1), Color(0.4, 0.38, 0.35)), false)

func _add_utility_cabinet(parent: Node3D, pos: Vector3) -> void:
	var cab_w = 0.8
	var cab_d = 0.5
	var cab_h = 1.8

	parent.add_child(_add_box_csg("Cabinet",
		pos + Vector3(-cab_w/2, 0, -cab_d/2),
		pos + Vector3(cab_w/2, cab_h, cab_d/2), Color(0.5, 0.5, 0.52)), false)

# ===== Utility Functions =====

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)

func _add_box_csg(csg_name: String, min_v: Vector3, max_v: Vector3, color: Color, transparent: bool = false) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = csg_name
	var size := (max_v - min_v)
	box.size = Vector3(absf(size.x), absf(size.y), absf(size.z))
	box.transform.origin = (min_v + max_v) * 0.5

	box.use_collision = true

	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	box.material = m
	return box

func _make_plane_mesh(w: float, h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for tri in [
		[Vector3(0,0,0), Vector3(w,0,0), Vector3(w,0,h)],
		[Vector3(0,0,0), Vector3(w,0,h), Vector3(0,0,h)],
	]:
		for v in tri:
			st.set_color(col)
			st.add_vertex(v)
	m = st.commit()
	mi.mesh = m
	mi.material_override = mat
	return mi

func _add_preview_camera_and_light(root: Node3D) -> void:
	var cam := Camera3D.new()
	cam.name = "PreviewCamera"
	var basis = Basis.looking_at(Vector3(-8, -8, -10).normalized(), Vector3.UP)
	cam.transform = Transform3D(basis, Vector3(10, 10, 12))
	root.add_child(cam, true)
	cam.owner = root

	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.light_energy = 1.5
	light.rotation_degrees = Vector3(-50, 40, 0)
	root.add_child(light, true)
	light.owner = root

	# Add ambient light for office feel
	var env := WorldEnvironment.new()
	env.name = "Environment"
	var environment := Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.95, 0.95, 1.0)
	environment.ambient_light_energy = 0.4
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.85, 0.88, 0.92)
	env.environment = environment
	root.add_child(env, true)
	env.owner = root

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

