# res://RoomTilesBuilder.gd
# Godot 4.x — Run from the Script Editor (EditorScript → Run).
# Generates res://algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn with clean, edge-aligned WFC tiles.
@tool
extends EditorScript


const TILE_SIZE   := 2.0
const FLOOR_THICK := 0.04
const WALL_THICK  := 0.18
const WALL_HEIGHT := 2.6
const DOOR_WIDTH  := 1.0
const DOOR_HEIGHT := 2.1

const GRID_COLS   := 6
const GRID_GAP    := 2.6   # visual spacing between tiles in the preview grid

func _run() -> void:
	# --- define the tile set (name + sockets) ---
	var tiles : Array = [
		["Floor",    {"N":"open","E":"open","S":"open","W":"open"}],

		["Wall_N",   {"N":"wall","E":"open","S":"open","W":"open"}],
		["Wall_E",   {"N":"open","E":"wall","S":"open","W":"open"}],
		["Wall_S",   {"N":"open","E":"open","S":"wall","W":"open"}],
		["Wall_W",   {"N":"open","E":"open","S":"open","W":"wall"}],

		["Corner_NE",{"N":"wall","E":"wall","S":"open","W":"open"}],
		["Corner_ES",{"N":"open","E":"wall","S":"wall","W":"open"}],
		["Corner_SW",{"N":"open","E":"open","S":"wall","W":"wall"}],
		["Corner_WN",{"N":"wall","E":"open","S":"open","W":"wall"}],

		["T_NES",    {"N":"wall","E":"wall","S":"wall","W":"open"}],
		["T_ESW",    {"N":"open","E":"wall","S":"wall","W":"wall"}],
		["T_SWN",    {"N":"wall","E":"open","S":"wall","W":"wall"}],
		["T_WNE",    {"N":"wall","E":"wall","S":"open","W":"wall"}],

		["+_Cross",  {"N":"wall","E":"wall","S":"wall","W":"wall"}],

		["Door_N",   {"N":"door","E":"open","S":"open","W":"open"}],
		["Door_E",   {"N":"open","E":"door","S":"open","W":"open"}],
		["Door_S",   {"N":"open","E":"open","S":"door","W":"open"}],
		["Door_W",   {"N":"open","E":"open","S":"open","W":"door"}],
	]

	# --- build the root preview scene ---
	var root := Node3D.new()
	root.name = "RoomTiles_Aligned"
	# a light + camera to make preview nice
	_add_preview_camera_and_light(root)

	# build tiles and place in grid
	var built : Array[Node3D] = []
	for i in tiles.size():
		var name = tiles[i][0]
		var sockets = tiles[i][1]
		var t := _build_tile(name, sockets)
		
		# grid placement
		var r := i / GRID_COLS
		var c := i % GRID_COLS
		t.transform.origin = Vector3(c * GRID_GAP, 0.0, r * GRID_GAP)
		
		# Add to root (NOT internal mode - so groups are saved!)
		root.add_child(t, false)  # Changed from true to false
		t.owner = root  # CRITICAL: Set owner for PackedScene to save it
		_set_owner_recursive(t, root)  # Set owner for all children too
		
		# MUST add to group AFTER setting owner (Godot 4 requirement for PackedScene)
		t.add_to_group("tile", true)  # true = persistent group (saved in scene)
		
		built.append(t)

	# center the grid around origin
	if built.size() > 0:
		var cols = min(GRID_COLS, built.size())
		var rows := int(ceil(float(built.size()) / float(GRID_COLS)))
		var offset := Vector3((cols-1) * GRID_GAP * 0.5, 0.0, (rows-1) * GRID_GAP * 0.5)
		for o in built:
			o.transform.origin -= offset

	# --- save as .tscn and open ---
	print("Packing scene with ", root.get_child_count(), " children...")
	
	var scene := PackedScene.new()
	var ok := scene.pack(root)
	if ok != OK:
		push_error("Failed to pack scene. Error code: ", ok)
		return
	
	print("Scene packed successfully!")

	var path := "res://algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn"
	var save_ok := ResourceSaver.save(scene, path)
	if save_ok != OK:
		push_error("Failed to save: %s (Error: %d)" % [path, save_ok])
		return

	print("✅ Saved: ", path, " with ", built.size(), " tiles")
	get_editor_interface().open_scene_from_path(path)

# ===== helpers =====

func _set_owner_recursive(node: Node, owner: Node):
	"""Set owner for node and all descendants (required for PackedScene.pack())"""
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)

func _build_tile(name: String, sockets: Dictionary) -> Node3D:
	var tile := Node3D.new()
	tile.name = name
	tile.set_meta("sockets", sockets) # for WFC rules
	# Note: add_to_group will be called AFTER adding to tree

	# a small origin gizmo plane for footprint (optional)
	var foot := _make_plane_mesh(TILE_SIZE, TILE_SIZE, Color(0.8, 0.8, 0.85, 0.25))
	foot.name = "Footprint"
	foot.transform.origin = Vector3(TILE_SIZE*0.5, 0.001, TILE_SIZE*0.5) # slightly above 0
	tile.add_child(foot, false)  # Normal mode so it saves properly

	# floor slab
	var floor_min := Vector3(0.0, 0.0, 0.0)
	var floor_max := Vector3(TILE_SIZE, FLOOR_THICK, TILE_SIZE)
	var floor_box = _add_box_csg("Floor", floor_min, floor_max, Color(0.9, 0.9, 0.95, 1.0))
	tile.add_child(floor_box, false)  # Normal mode so it saves properly

	# walls / doors per side
	for side in ["N","E","S","W"]:
		var state := String(sockets.get(side, "open"))
		if state == "wall":
			_place_wall_edge(tile, side, false)
		elif state == "door":
			_place_wall_edge(tile, side, true)
		# open => nothing
	return tile

func _place_wall_edge(parent: Node3D, side: String, with_door: bool) -> void:
	# exact min/max placement, matching the Blender “aligned” version
	var x0 := 0.0
	var x1 := TILE_SIZE
	var y0 := 0.0
	var y1 := TILE_SIZE
	var z0 := FLOOR_THICK
	var z1 := FLOOR_THICK + WALL_HEIGHT
	var t  := WALL_THICK

	var gap = clamp(DOOR_WIDTH, 0.0, TILE_SIZE - 2.0 * WALL_THICK)
	var seg = 0.5 * (TILE_SIZE - gap)
	var head := maxf(0.0, WALL_HEIGHT - DOOR_HEIGHT)

	match side:
		"N":
			if not with_door:
				parent.add_child(_add_box_csg("Wall_N", Vector3(x0, z0, y1 - t), Vector3(x1, z1, y1)), true)
			else:
				parent.add_child(_add_box_csg("Wall_N_L", Vector3(x0,        z0, y1 - t), Vector3(x0 + seg, z1, y1)), true)
				parent.add_child(_add_box_csg("Wall_N_R", Vector3(x1 - seg,  z0, y1 - t), Vector3(x1,       z1, y1)), true)
				if head > 0.001:
					parent.add_child(_add_box_csg("Lintel_N",
						Vector3(x0 + seg, z0 + DOOR_HEIGHT, y1 - t),
						Vector3(x1 - seg, z1,              y1)), true)
		"S":
			if not with_door:
				parent.add_child(_add_box_csg("Wall_S", Vector3(x0, z0, y0), Vector3(x1, z1, y0 + t)), true)
			else:
				parent.add_child(_add_box_csg("Wall_S_L", Vector3(x0,        z0, y0), Vector3(x0 + seg, z1, y0 + t)), true)
				parent.add_child(_add_box_csg("Wall_S_R", Vector3(x1 - seg,  z0, y0), Vector3(x1,       z1, y0 + t)), true)
				if head > 0.001:
					parent.add_child(_add_box_csg("Lintel_S",
						Vector3(x0 + seg, z0 + DOOR_HEIGHT, y0),
						Vector3(x1 - seg, z1,              y0 + t)), true)
		"E":
			if not with_door:
				parent.add_child(_add_box_csg("Wall_E", Vector3(x1 - t, z0, y0), Vector3(x1, z1, y1)), true)
			else:
				parent.add_child(_add_box_csg("Wall_E_B", Vector3(x1 - t, z0, y0),        Vector3(x1, z1, y0 + seg)), true)
				parent.add_child(_add_box_csg("Wall_E_T", Vector3(x1 - t, z0, y1 - seg),  Vector3(x1, z1, y1)), true)
				if head > 0.001:
					parent.add_child(_add_box_csg("Lintel_E",
						Vector3(x1 - t, z0 + DOOR_HEIGHT, y0 + seg),
						Vector3(x1,     z1,              y1 - seg)), true)
		"W":
			if not with_door:
				parent.add_child(_add_box_csg("Wall_W", Vector3(x0, z0, y0), Vector3(x0 + t, z1, y1)), true)
			else:
				parent.add_child(_add_box_csg("Wall_W_B", Vector3(x0, z0, y0),        Vector3(x0 + t, z1, y0 + seg)), true)
				parent.add_child(_add_box_csg("Wall_W_T", Vector3(x0, z0, y1 - seg),  Vector3(x0 + t, z1, y1)), true)
				if head > 0.001:
					parent.add_child(_add_box_csg("Lintel_W",
						Vector3(x0,     z0 + DOOR_HEIGHT, y0 + seg),
						Vector3(x0 + t, z1,              y1 - seg)), true)

func _add_box_csg(name: String, min_v: Vector3, max_v: Vector3, color: Color = Color(0.85, 0.85, 0.9, 1.0)) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = name
	var size := (max_v - min_v)
	box.size = Vector3(absf(size.x), absf(size.y), absf(size.z))
	box.transform.origin = (min_v + max_v) * 0.5
	
	# Enable collision for physics
	box.use_collision = true
	
	# simple visual material
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	box.material = m
	return box

func _make_plane_mesh(w: float, h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	for tri in [
		[Vector3(0,0,0), Vector3(w,0,0), Vector3(w,0,h)],
		[Vector3(0,0,0), Vector3(w,0,h), Vector3(0,0,h)],
	]:
		for v in tri:
			st.set_color(col)  # Godot 4: use set_color instead of add_color
			st.add_vertex(v)
	m = st.commit()
	mi.mesh = m
	mi.material_override = mat
	return mi

func _add_preview_camera_and_light(root: Node3D) -> void:
	var cam := Camera3D.new()
	cam.name = "PreviewCamera"
	# Position camera looking at the tiles
	var basis = Basis.looking_at(Vector3(-6, -6, -8).normalized(), Vector3.UP)
	cam.transform = Transform3D(basis, Vector3(6, 6, 8))
	root.add_child(cam, true)  # Keep internal mode
	cam.owner = root  # Set owner so it saves

	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.light_energy = 2.0
	light.rotation_degrees = Vector3(-45, 45, 0)
	root.add_child(light, true)  # Keep internal mode
	light.owner = root  # Set owner so it saves
