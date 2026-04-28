class_name DressingRoomBuilder
extends RefCounted

## Reads a dressing-room JSON (commons/artifacts/dressing_rooms/<name>.json)
## and builds the staging in 3D as a Node3D tree:
##   - footing tiles → coloured cubes at appropriate heights
##   - artifact      → loaded from registry scene at the anchor
##   - extras        → Label3D / OmniLight3D / placeholder boxes
##
## Used by DressingRoomCatalog3D for visual review of each artifact's
## staging before composer placement.

const CELL_SIZE: float = 1.0   # Each grid cell is 1 metre
const STEP_HEIGHT: float = 0.5  # Each height-unit = 0.5m
const DRESSING_ROOMS_DIR: String = "res://commons/artifacts/dressing_rooms/"

# Tile colours by value.
const TILE_COLORS: Dictionary = {
	0: Color(0.05, 0.05, 0.06),   # void — barely visible
	1: Color(0.42, 0.42, 0.46),   # floor — grey
	2: Color(0.32, 0.32, 0.36),   # wall step
	3: Color(0.24, 0.24, 0.28),   # plinth
	4: Color(0.14, 0.14, 0.18),   # tall wall
}

const ANCHOR_COLOR: Color = Color(0.82, 0.23, 0.43)
const EXTRA_3T_COLOR: Color = Color(0.85, 0.63, 0.30)
const EXTRA_TT_COLOR: Color = Color(0.23, 0.42, 0.69)
const EXTRA_EL_COLOR: Color = Color(0.82, 0.23, 0.43)


## Load a dressing-room JSON by lookup_name. Returns the parsed dict, or
## null if the file doesn't exist or fails to parse.
static func load_dressing_room(lookup_name: String) -> Variant:
	var path := DRESSING_ROOMS_DIR + lookup_name + ".json"
	if not FileAccess.file_exists(path):
		return null
	var raw := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return null
	return parsed


## List every dressing-room file in the project.
static func list_dressing_rooms() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(DRESSING_ROOMS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			out.append(fname.replace(".json", ""))
		fname = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


## Build the dressing-room as a Node3D. Returns the root container.
##
## Args:
##   data: the parsed dressing-room dict
##   rotation_deg: which rotation to apply (must be in data.rotations)
##   artifact_registry_lookup: callable returning artifact info (scene path)
##                              given a lookup_name. Pass null to skip
##                              loading the artifact scene; a magenta
##                              placeholder cube is used instead.
static func build(data: Dictionary, rotation_deg: int = 0,
		artifact_registry_lookup: Callable = Callable()) -> Node3D:
	var root := Node3D.new()
	root.name = "DressingRoom_" + str(data.get("lookup_name", "unknown"))

	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	var anchor: Array = footing.get("anchor", [0, 0])
	var extras: Array = data.get("extras", [])
	var footprint: Array = data.get("footprint", [1.0, 1.0, 1.0])

	# Apply rotation by rotating the tile array in-memory.
	rotation_deg = int(rotation_deg) % 360
	if rotation_deg < 0:
		rotation_deg += 360

	var rotated_tiles: Array = _rotate_tiles(tiles, rotation_deg)
	var rotated_anchor: Array = _rotate_anchor(anchor, tiles, rotation_deg)
	var rows: int = rotated_tiles.size()
	var cols: int = 0
	for row in rotated_tiles:
		if row is Array and row.size() > cols:
			cols = row.size()
	if rows == 0 or cols == 0:
		rows = 1; cols = 1
		rotated_tiles = [[1]]
		rotated_anchor = [0, 0]

	# Centre the dressing room on the world origin so the catalog camera
	# can frame it predictably regardless of footing dimensions.
	var origin_x: float = -float(cols - 1) * 0.5 * CELL_SIZE
	var origin_z: float = -float(rows - 1) * 0.5 * CELL_SIZE

	# ── Footing cubes ────────────────────────────────────────────────
	var footing_root := Node3D.new()
	footing_root.name = "Footing"
	root.add_child(footing_root)
	for r in range(rows):
		var row_arr = rotated_tiles[r]
		if not (row_arr is Array): continue
		for c in range(row_arr.size()):
			var v: int = int(row_arr[c])
			if v <= 0:
				continue  # skip void
			var cube := MeshInstance3D.new()
			cube.name = "Tile_%d_%d" % [r, c]
			var box := BoxMesh.new()
			box.size = Vector3(CELL_SIZE * 0.96, STEP_HEIGHT * v, CELL_SIZE * 0.96)
			cube.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = TILE_COLORS.get(v, Color(0.4, 0.4, 0.4))
			mat.metallic = 0.05
			mat.roughness = 0.85
			cube.material_override = mat
			cube.position = Vector3(
				origin_x + c * CELL_SIZE,
				STEP_HEIGHT * v * 0.5,
				origin_z + r * CELL_SIZE
			)
			footing_root.add_child(cube)

	# ── Anchor marker (semi-transparent so it doesn't fight the artifact) ──
	var anchor_marker := MeshInstance3D.new()
	anchor_marker.name = "AnchorMarker"
	var marker_box := BoxMesh.new()
	marker_box.size = Vector3(CELL_SIZE * 0.55, 0.08, CELL_SIZE * 0.55)
	anchor_marker.mesh = marker_box
	var marker_mat := StandardMaterial3D.new()
	marker_mat.albedo_color = ANCHOR_COLOR
	marker_mat.emission_enabled = true
	marker_mat.emission = ANCHOR_COLOR
	marker_mat.emission_energy_multiplier = 0.6
	marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_mat.albedo_color.a = 0.55
	anchor_marker.material_override = marker_mat
	var anchor_height: float = _tile_top_height(rotated_tiles, rotated_anchor[0], rotated_anchor[1])
	anchor_marker.position = Vector3(
		origin_x + rotated_anchor[1] * CELL_SIZE,
		anchor_height + 0.04,
		origin_z + rotated_anchor[0] * CELL_SIZE
	)
	root.add_child(anchor_marker)

	# ── Artifact (load scene from registry) ──────────────────────────
	var artifact_root := Node3D.new()
	artifact_root.name = "Artifact"
	root.add_child(artifact_root)
	artifact_root.position = Vector3(
		origin_x + rotated_anchor[1] * CELL_SIZE,
		anchor_height,
		origin_z + rotated_anchor[0] * CELL_SIZE
	)
	var lookup: String = String(data.get("lookup_name", ""))
	var loaded_artifact: Node = null
	if not lookup.is_empty() and artifact_registry_lookup.is_valid():
		var info: Dictionary = artifact_registry_lookup.call(lookup)
		if info is Dictionary:
			var scene_path: String = String(info.get("scene", ""))
			if scene_path != "" and ResourceLoader.exists(scene_path):
				var packed: PackedScene = ResourceLoader.load(scene_path)
				if packed != null:
					loaded_artifact = packed.instantiate()
	if loaded_artifact == null:
		# Magenta placeholder cube sized to the footprint.
		var ph := MeshInstance3D.new()
		ph.name = "ArtifactPlaceholder"
		var ph_box := BoxMesh.new()
		ph_box.size = Vector3(
			max(0.5, float(footprint[0])) * CELL_SIZE * 0.7,
			max(0.5, float(footprint[2])) * STEP_HEIGHT * 0.9,
			max(0.5, float(footprint[1])) * CELL_SIZE * 0.7
		)
		ph.mesh = ph_box
		var ph_mat := StandardMaterial3D.new()
		ph_mat.albedo_color = Color(0.78, 0.27, 0.65)
		ph_mat.emission_enabled = true
		ph_mat.emission = Color(0.78, 0.27, 0.65)
		ph_mat.emission_energy_multiplier = 0.4
		ph.material_override = ph_mat
		ph.position = Vector3(0, ph_box.size.y * 0.5, 0)
		artifact_root.add_child(ph)
		loaded_artifact = ph
	else:
		loaded_artifact.position = Vector3.ZERO
		artifact_root.add_child(loaded_artifact)
	# Apply rotation to the artifact (the tiles already rotated).
	artifact_root.rotation_degrees = Vector3(0, -float(rotation_deg), 0)

	# ── Extras (3t labels, tt placeholders, el lights) ────────────────
	var extras_root := Node3D.new()
	extras_root.name = "Extras"
	root.add_child(extras_root)
	for extra in extras:
		if not (extra is Dictionary): continue
		var etype: String = String(extra.get("type", ""))
		var off_raw = extra.get("offset", [0, 0, 0])
		var off: Array = off_raw if off_raw is Array else [0, 0, 0]
		while off.size() < 3:
			off.append(0)
		# Rotate offset (dr, dc) like the tiles.
		var rot_off: Array = _rotate_offset_2d([int(off[0]), int(off[1])], rotation_deg)
		var ex_r: int = rotated_anchor[0] + rot_off[0]
		var ex_c: int = rotated_anchor[1] + rot_off[1]
		var ex_h_offset: float = float(off[2]) * STEP_HEIGHT
		var base_h: float = _tile_top_height(rotated_tiles, ex_r, ex_c)
		var x: float = origin_x + ex_c * CELL_SIZE
		var z: float = origin_z + ex_r * CELL_SIZE
		match etype:
			"3t":
				var lbl := Label3D.new()
				lbl.text = String(extra.get("text", "?"))
				lbl.font_size = 64
				lbl.outline_size = 6
				lbl.modulate = EXTRA_3T_COLOR
				lbl.no_depth_test = true
				lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				lbl.position = Vector3(x, base_h + 1.0 + ex_h_offset, z)
				lbl.pixel_size = 0.005
				extras_root.add_child(lbl)
			"tt":
				# tt panels are large reading panels in-world; show as a
				# thin rectangular placeholder so the dressing room
				# layout stays honest.
				var pnl := MeshInstance3D.new()
				var pnl_box := BoxMesh.new()
				pnl_box.size = Vector3(CELL_SIZE * 0.7, 0.5, 0.06)
				pnl.mesh = pnl_box
				var pnl_mat := StandardMaterial3D.new()
				pnl_mat.albedo_color = EXTRA_TT_COLOR
				pnl_mat.emission_enabled = true
				pnl_mat.emission = EXTRA_TT_COLOR
				pnl_mat.emission_energy_multiplier = 0.25
				pnl.material_override = pnl_mat
				pnl.position = Vector3(x, base_h + 0.5 + ex_h_offset, z)
				extras_root.add_child(pnl)
				var lbl2 := Label3D.new()
				lbl2.text = "tt:" + String(extra.get("key", ""))
				lbl2.font_size = 28
				lbl2.modulate = Color(0.85, 0.92, 1.0)
				lbl2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				lbl2.position = Vector3(x, base_h + 0.85 + ex_h_offset, z)
				lbl2.pixel_size = 0.0035
				extras_root.add_child(lbl2)
			"el":
				var light := OmniLight3D.new()
				light.light_color = EXTRA_EL_COLOR
				light.light_energy = 1.6
				light.omni_range = 4.0
				light.position = Vector3(x, base_h + 1.0 + ex_h_offset, z)
				extras_root.add_child(light)
				# Tiny sphere so the light source is visible too.
				var bulb := MeshInstance3D.new()
				var bulb_mesh := SphereMesh.new()
				bulb_mesh.radius = 0.08
				bulb_mesh.height = 0.16
				bulb.mesh = bulb_mesh
				var bulb_mat := StandardMaterial3D.new()
				bulb_mat.albedo_color = EXTRA_EL_COLOR
				bulb_mat.emission_enabled = true
				bulb_mat.emission = EXTRA_EL_COLOR
				bulb_mat.emission_energy_multiplier = 1.5
				bulb.material_override = bulb_mat
				bulb.position = Vector3(x, base_h + 1.0 + ex_h_offset, z)
				extras_root.add_child(bulb)
			_:
				# Unknown extra type — skip silently.
				pass

	return root


# ── Helpers ──────────────────────────────────────────────────────────

static func _tile_top_height(tiles: Array, r: int, c: int) -> float:
	if r < 0 or r >= tiles.size():
		return 0.0
	var row = tiles[r]
	if not (row is Array) or c < 0 or c >= row.size():
		return 0.0
	return float(int(row[c])) * STEP_HEIGHT


static func _rotate_tiles(tiles: Array, deg: int) -> Array:
	deg = deg % 360
	if deg == 0:
		return tiles.duplicate(true)
	if deg == 180:
		var flipped: Array = []
		for r in range(tiles.size() - 1, -1, -1):
			var row = tiles[r]
			if row is Array:
				var rev := []
				for c in range(row.size() - 1, -1, -1):
					rev.append(row[c])
				flipped.append(rev)
			else:
				flipped.append([])
		return flipped
	if deg == 90:
		# Clockwise 90: new[r][c] = old[rows-1-c][r]
		var rows: int = tiles.size()
		var cols: int = 0
		for row in tiles:
			if row is Array and row.size() > cols:
				cols = row.size()
		var out: Array = []
		for r in range(cols):
			var new_row: Array = []
			for c in range(rows):
				var src_row = tiles[rows - 1 - c]
				var val = 0
				if src_row is Array and r < src_row.size():
					val = src_row[r]
				new_row.append(val)
			out.append(new_row)
		return out
	if deg == 270:
		return _rotate_tiles(_rotate_tiles(_rotate_tiles(tiles, 90), 90), 90)
	return tiles.duplicate(true)


static func _rotate_anchor(anchor: Array, tiles: Array, deg: int) -> Array:
	if anchor.size() < 2:
		return [0, 0]
	deg = deg % 360
	var ar: int = int(anchor[0])
	var ac: int = int(anchor[1])
	var rows: int = tiles.size()
	var cols: int = 0
	for row in tiles:
		if row is Array and row.size() > cols:
			cols = row.size()
	if deg == 0:
		return [ar, ac]
	if deg == 90:
		return [ac, rows - 1 - ar]
	if deg == 180:
		return [rows - 1 - ar, cols - 1 - ac]
	if deg == 270:
		return [cols - 1 - ac, ar]
	return [ar, ac]


static func _rotate_offset_2d(off: Array, deg: int) -> Array:
	var dr: int = int(off[0])
	var dc: int = int(off[1])
	deg = deg % 360
	if deg == 0:   return [dr, dc]
	if deg == 90:  return [dc, -dr]
	if deg == 180: return [-dr, -dc]
	if deg == 270: return [-dc, dr]
	return [dr, dc]
