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
## The flat pad renders as a thin bounding-box FRAME (colour + edge size) at
## floor level rather than a grid of solid cubes. Bright emissive cyan so the
## footprint reads clearly on any floor — a UI-like indicator, not a shadow.
const FRAME_COLOR: Color = Color(0.30, 0.85, 0.95)
const FRAME_THICK: float = 0.07
const FRAME_Y: float = 0.04
## The monument TRUE-extent frame + scale post — an accent so it reads as "the real size".
const MONUMENT_FRAME_COLOR: Color = Color(0.86, 0.34, 0.11)
const SIZE_ORACLE_PATH: String = "res://commons/data/artifact_sizes.json"
const DRESSING_ROOMS_DIR: String = "res://commons/artifacts/dressing_rooms/"
const ELEMENT_CATALOG_PATH: String = "res://commons/data/posture_to_station.json"
const STAGING_DNA_PATH: String = "res://commons/data/staging_dna.json"

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
## Load the Staging DNA — the full environment template per artifact TYPE
## (specimen / instrument / performer / terrain / apparition / well / tableau):
## staging footing + support prop + dressing (light, caption, cordon).
## Returns {posture_id: template} for direct lookup by a room's posture.
static func load_staging_dna() -> Dictionary:
	if not FileAccess.file_exists(STAGING_DNA_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(STAGING_DNA_PATH))
	if not (parsed is Dictionary and parsed.get("templates") is Dictionary):
		return {}
	var by_posture: Dictionary = {}
	for tname in parsed["templates"].keys():
		var t = parsed["templates"][tname]
		if t is Dictionary:
			var td: Dictionary = t
			td["_type"] = tname
			by_posture[str(td.get("posture", tname))] = td
	return by_posture


## Instantiate a registry-listed prop scene and apply its grid config.
## Returns null (caller falls back / skips) on any miss.
static func _instantiate_registered(lookup: String, cfg: Dictionary,
		artifact_registry_lookup: Callable) -> Node3D:
	if lookup.is_empty() or not artifact_registry_lookup.is_valid():
		return null
	var info = artifact_registry_lookup.call(lookup)
	var sp: String = str(info.get("scene", "")) if info is Dictionary else ""
	if sp == "" or not ResourceLoader.exists(sp):
		return null
	var packed := ResourceLoader.load(sp) as PackedScene
	if packed == null:
		return null
	var node := packed.instantiate()
	if not (node is Node3D):
		if node: node.queue_free()
		return null
	if node.has_method("apply_grid_config") and not cfg.is_empty():
		node.apply_grid_config(cfg)
	return node as Node3D


## Substitute placeholders in a cfg template. The TWO TEXT SLOTS every
## artifact carries, filled from the registry automatically:
##   {artifact}   = the TITLE (lookup_name, unspaced) — binds to the support's
##                  own surface (stencil / caption ON the prop)
##   {info_lines} = the SIMULATION INFO (registry description, wrapped to
##                  short lines) — binds to an INFO PLATE beside the support
## Plus size fills: {height_m} / {raised_w} / {raised_d}.
static func _fill_cfg(cfg_in, raised_w: int, raised_d: int, height_m: float,
		artifact: String = "", info_lines: Array = []) -> Dictionary:
	var out: Dictionary = {}
	if not (cfg_in is Dictionary):
		return out
	for k in cfg_in.keys():
		var v = cfg_in[k]
		if v is String:
			match v:
				"{height_m}": out[k] = height_m
				"{raised_w}": out[k] = raised_w
				"{raised_d}": out[k] = raised_d
				"{artifact}": out[k] = artifact.replace("_", " ")
				"{info_lines}": out[k] = info_lines
				_: out[k] = v
		else:
			out[k] = v
	return out


## Wrap prose into at most `max_lines` lines of ~`width` chars (word-safe,
## ellipsis on truncation) — registry descriptions onto an info plate.
static func _wrap_text(text: String, width: int = 30, max_lines: int = 4) -> Array:
	var lines: Array = []
	var cur := ""
	for w in text.strip_edges().split(" ", false):
		if cur == "":
			cur = w
		elif cur.length() + 1 + w.length() <= width:
			cur += " " + w
		else:
			lines.append(cur)
			cur = w
			if lines.size() >= max_lines:
				break
	if lines.size() < max_lines and cur != "":
		lines.append(cur)
	elif lines.size() >= max_lines:
		lines[max_lines - 1] = str(lines[max_lines - 1]).left(width - 1) + "…"
	return lines


## Load the Element Catalog (posture -> station prop mapping). Cached-free —
## it's a small file and build() isn't hot.
static func load_element_catalog() -> Dictionary:
	if not FileAccess.file_exists(ELEMENT_CATALOG_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ELEMENT_CATALOG_PATH))
	if parsed is Dictionary and parsed.get("elements") is Dictionary:
		return parsed["elements"]
	return {}


## In STAGED mode, resolve a posture's raised footing region to a real station
## prop + its apply_grid_config dict. Returns {} when the element has no
## wall-form (floor/float/pit — catalog nulls) or the catalog is absent.
## raised_w/raised_d = the raised region's tile extents; height_m = its top.
static func _resolve_station_for_posture(posture: String, raised_w: int,
		raised_d: int, height_m: float) -> Dictionary:
	var elements := load_element_catalog()
	var el = elements.get(posture)
	if not (el is Dictionary):
		return {}
	var candidates = el.get("station")
	if not (candidates is Array) or candidates.is_empty():
		return {}
	var lookup := str(candidates[0])
	# Fill the prop's real config keys from the footing recipe. Every station
	# prop sizes via *_cells + one height key (see apply_grid_config contract).
	var cfg: Dictionary = {}
	match posture:
		"pedestal":
			cfg = {"width_cells": raised_w, "depth_cells": raised_d, "top_height": height_m}
		"table":
			cfg = {"length_cells": raised_w, "depth_cells": raised_d, "top_height": height_m}
		"platform":
			cfg = {"width_cells": raised_w, "depth_cells": raised_d, "step_height": height_m}
		"wall":
			cfg = {"length_cells": raised_w, "height": height_m}
		_:
			return {}
	return {"lookup": lookup, "cfg": cfg}


static func build(data: Dictionary, rotation_deg: int = 0,
		artifact_registry_lookup: Callable = Callable(), staged: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "DressingRoom_" + str(data.get("lookup_name", "unknown"))

	var footing: Dictionary = data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	var anchor: Array = footing.get("anchor", [0, 0])
	var extras: Array = data.get("extras", [])

	# Composition toggles (web UI): show the base prop, the light, the info board
	# independently. show_base:false in staged mode = FOOTPRINT ONLY — no prop AND
	# no blockout cube, the artifact drops to the floor inside the footprint frame.
	var show_base: bool = bool(data.get("show_base", true))
	var show_light: bool = bool(data.get("show_light", true))
	var light_mode: String = str(data.get("light_mode", "glow"))
	var show_info: bool = bool(data.get("show_info", true))
	# The "floor" (terrain) type: the artifact IS the ground — no support prop AND
	# no raised blockout pillar, and it seats flush at y=0 (a pedestal only appears
	# for raised types). This is what makes y=0 mean the same "artifact base sits
	# here" in every type: the floor for terrain, the prop's top for a pedestal.
	var posture: String = str(data.get("posture", ""))
	# Rooms written before postures existed (~35%) lack the field. Default to the
	# museum pose so they get a real plinth, not a bare grey blockout cube — the
	# classifier's own default is "pedestal" too.
	if posture.is_empty():
		posture = "pedestal"
	# MONUMENT: a super-large / very-long artifact (a corridor, a field) is a
	# SPACE, not an object — no props, no pillar, seated flush, and the footprint
	# frame is drawn at its TRUE oracle extent (not the small footing pad).
	var is_monument: bool = posture == "monument"
	var is_flat_ground: bool = posture == "floor" or is_monument
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

	# ── Staged mode: the full DNA environment ─────────────────────────
	# Staging DNA (staging_dna.json) defines each artifact TYPE's complete
	# environment: SUPPORT (the station prop the raised footing IS — a plinth
	# is station_plinth) + DRESSING (light, caption, cordon that make it
	# read). Falls back to the thin Element Catalog for support, and to
	# blockout cubes on any miss.
	var staged_prop_placed: bool = false
	var staged_top_override: float = -1.0   # support prop's REAL top (e.g. the stage clamps lower than the blockout)
	if staged and artifact_registry_lookup.is_valid() and not is_flat_ground:
		# Raised-region bounds (tiles above the 1-unit floor pad).
		var r_min: int = rows
		var r_max: int = -1
		var c_min: int = cols
		var c_max: int = -1
		var v_max: int = 0
		for rr in range(rows):
			var row_a = rotated_tiles[rr]
			if not (row_a is Array): continue
			for cc in range(row_a.size()):
				var vv: int = int(row_a[cc])
				if vv > 1:
					r_min = mini(r_min, rr); r_max = maxi(r_max, rr)
					c_min = mini(c_min, cc); c_max = maxi(c_max, cc)
					v_max = maxi(v_max, vv)
		var raised_w: int = (c_max - c_min + 1) if r_max >= 0 else 0
		var raised_d: int = (r_max - r_min + 1) if r_max >= 0 else 0
		var height_m: float = float(v_max) * STEP_HEIGHT
		var tmpl: Dictionary = {}
		if not posture.is_empty():
			tmpl = load_staging_dna().get(posture, {})

		# SUPPORT — the raised footing rendered as its real prop. The well's
		# rim and terrain's flat pad have support:null (their tiles ARE the
		# staging), so those keep blockout tiles by design.
		var artifact_name := str(data.get("lookup_name", ""))
		# The info text slot — the artifact's registry description, wrapped.
		var info_lines: Array = []
		var reg_entry = artifact_registry_lookup.call(artifact_name)
		if reg_entry is Dictionary:
			var desc := str(reg_entry.get("description", ""))
			if desc != "":
				info_lines = _wrap_text(desc, 30, 4)
		var sup: Dictionary = {}
		if tmpl.get("support") is Dictionary:
			sup = {"lookup": str(tmpl["support"].get("prop", "")),
				"cfg": _fill_cfg(tmpl["support"].get("cfg", {}), raised_w, raised_d, height_m, artifact_name, info_lines)}
		elif tmpl.is_empty() and r_max >= 0:
			sup = _resolve_station_for_posture(posture, raised_w, raised_d, height_m)
		if sup.get("cfg") is Dictionary:
			_apply_composition(sup["cfg"], show_light, light_mode, show_info)
		if r_max >= 0 and show_base and not sup.is_empty() and str(sup.get("lookup", "")) != "":
			var prop := _instantiate_registered(str(sup.lookup), sup.cfg, artifact_registry_lookup)
			if prop:
				prop.name = "StationProp"
				prop.position = Vector3(
					origin_x + (float(c_min) + float(c_max)) * 0.5 * CELL_SIZE,
					0.0,
					origin_z + (float(r_min) + float(r_max)) * 0.5 * CELL_SIZE)
				root.add_child(prop)
				staged_prop_placed = true
				if tmpl.get("support") is Dictionary and tmpl["support"].has("top_m"):
					staged_top_override = float(tmpl["support"]["top_m"])

		# DRESSING — cordon / backdrop / threshold at anchor-relative offsets
		# ([rows_south, cols_east, y_above_tile_top], rotated with the room).
		# These are base staging props (the well's fence, the apparition's
		# backdrop) — suppressed with the base prop, so footprint-only is bare.
		var dressing = tmpl.get("dressing", [])
		if show_base and dressing is Array and not dressing.is_empty():
			var dress_root := Node3D.new()
			dress_root.name = "Dressing"
			root.add_child(dress_root)
			for piece in dressing:
				if not (piece is Dictionary): continue
				var off = piece.get("offset", [0, 0, 0])
				if not (off is Array and off.size() >= 3): continue
				var rot_off := _rotate_offset_2d([int(off[0]), int(off[1])], rotation_deg)
				var pr: int = int(rotated_anchor[0]) + int(rot_off[0])
				var pc: int = int(rotated_anchor[1]) + int(rot_off[1])
				var base_y: float = _tile_top_height(rotated_tiles, pr, pc)
				# y_level (absolute metres, in the DNA) wins over the tile-relative
				# offset y — e.g. an info board mounted at a fixed 2 m reading height.
				var y_pos: float = base_y + float(off[2])
				if piece.has("y_level"):
					y_pos = float(piece["y_level"])
				var dprop := _instantiate_registered(str(piece.get("prop", "")),
					_fill_cfg(piece.get("cfg", {}), raised_w, raised_d, height_m, artifact_name, info_lines),
					artifact_registry_lookup)
				if dprop:
					dprop.position = Vector3(
						origin_x + pc * CELL_SIZE,
						y_pos,
						origin_z + pr * CELL_SIZE)
					dress_root.add_child(dprop)

		# Softbox POLE LIGHT — the "light" option as a floor-standing gallery
		# softbox beside the base (station_task_light), aimed at the artifact.
		if show_light and light_mode == "softbox":
			_place_softbox_pole(root, origin_x, cols, artifact_registry_lookup)

	# ── Footprint bounding box + raised blockout ─────────────────────
	# The flat pad is drawn as a thin bounding-box FRAME marking where the
	# staging sits — not a grid of solid cubes (those competed with the
	# artifact). Raised tiles (v>1) still show as blockout cubes in BLOCKOUT
	# mode; the station prop stands in for them when STAGED.
	var footing_root := Node3D.new()
	footing_root.name = "Footing"
	root.add_child(footing_root)
	# Footprint extent over all non-void cells → one bounding-box frame.
	var fp_rmin: int = rows
	var fp_rmax: int = -1
	var fp_cmin: int = cols
	var fp_cmax: int = -1
	for r in range(rows):
		var frow = rotated_tiles[r]
		if not (frow is Array): continue
		for c in range(frow.size()):
			if int(frow[c]) > 0:
				fp_rmin = mini(fp_rmin, r); fp_rmax = maxi(fp_rmax, r)
				fp_cmin = mini(fp_cmin, c); fp_cmax = maxi(fp_cmax, c)
	if fp_rmax >= 0:
		var fw: float = float(fp_cmax - fp_cmin + 1) * CELL_SIZE
		var fd: float = float(fp_rmax - fp_rmin + 1) * CELL_SIZE
		var fcx: float = origin_x + (float(fp_cmin) + float(fp_cmax)) * 0.5 * CELL_SIZE
		var fcz: float = origin_z + (float(fp_rmin) + float(fp_rmax)) * 0.5 * CELL_SIZE
		_add_footprint_frame(footing_root, fcx, fcz, fw, fd)
	# Monument: mark the TRUE extent (from the size oracle) in accent, centred on
	# the artifact — so an 86 m corridor reads at its real size, not a tiny pad.
	if is_monument:
		var ext: Vector2 = _monument_extent(str(data.get("lookup_name", "")))
		if ext.x > 0.0 and ext.y > 0.0:
			_add_footprint_frame(footing_root, 0.0, 0.0, ext.x, ext.y, MONUMENT_FRAME_COLOR)
			# A 1.8 m human-scale post at the near corner, so the scale reads.
			var post := MeshInstance3D.new()
			var pmesh := BoxMesh.new(); pmesh.size = Vector3(0.3, 1.8, 0.3)
			post.mesh = pmesh
			var pmat := StandardMaterial3D.new(); pmat.albedo_color = MONUMENT_FRAME_COLOR
			pmat.emission_enabled = true; pmat.emission = MONUMENT_FRAME_COLOR
			pmat.emission_energy_multiplier = 0.3
			post.material_override = pmat
			post.position = Vector3(-ext.x * 0.5 - 0.4, 0.9, ext.y * 0.5 + 0.4)
			footing_root.add_child(post)
	# Raised blockout tiles — only when the staged prop isn't standing in.
	for r in range(rows):
		var row_arr = rotated_tiles[r]
		if not (row_arr is Array): continue
		for c in range(row_arr.size()):
			var v: int = int(row_arr[c])
			if v <= 1:
				continue  # flat pad = the frame; void = nothing
			if staged_prop_placed:
				continue  # the station prop stands in for the raised tiles
			if staged and not show_base:
				continue  # footprint-only: no base cube, just the frame
			if staged and is_flat_ground:
				continue  # floor type: the artifact IS the ground — no pillar
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
			# The pillar/blockout cube is solid in-game too.
			footing_root.add_child(_box_collider(box.size, cube.position))

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
	# Staged mode: the support prop's real top wins over the blockout tile
	# height (a dais is lower than the abstract 1m block) — seat the artifact
	# on the PROP, not on the abstraction.
	if staged_top_override >= 0.0:
		anchor_height = staged_top_override
	if staged and (not show_base or is_flat_ground):
		anchor_height = 0.0   # footprint-only OR floor type: the artifact rests on the floor
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
	# Fine offset (metres). Rotates with the dressing room so the offset
	# is "intrinsic" to the staging — e.g., a slider that always sits 30cm
	# in front of its plinth keeps that relationship at every rotation.
	var offset_raw = data.get("artifact_offset", [0.0, 0.0, 0.0])
	var off_x: float = 0.0
	var off_y: float = 0.0
	var off_z: float = 0.0
	if offset_raw is Array and offset_raw.size() >= 3:
		off_x = float(offset_raw[0])
		off_y = float(offset_raw[1])
		off_z = float(offset_raw[2])
	# Rotate (off_x, off_z) by rotation_deg around Y. Y is unchanged.
	var rot_rad: float = deg_to_rad(rotation_deg)
	var rot_off_x: float = off_x * cos(rot_rad) + off_z * sin(rot_rad)
	var rot_off_z: float = -off_x * sin(rot_rad) + off_z * cos(rot_rad)
	artifact_root.position = Vector3(
		origin_x + rotated_anchor[1] * CELL_SIZE + rot_off_x,
		anchor_height + off_y,
		origin_z + rotated_anchor[0] * CELL_SIZE + rot_off_z
	)
	var lookup: String = str(data.get("lookup_name", ""))
	var loaded_artifact: Node = null
	if not lookup.is_empty() and artifact_registry_lookup.is_valid():
		var info: Dictionary = artifact_registry_lookup.call(lookup)
		if info is Dictionary:
			var scene_path: String = str(info.get("scene", ""))
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
		var etype: String = str(extra.get("type", ""))
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
				lbl.text = str(extra.get("text", "?"))
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
				lbl2.text = "tt:" + str(extra.get("key", ""))
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

## A StaticBody3D box collider (default layer, matching GridStructureComponent's
## structure cubes) — the pillar/blockout cube and the softbox mast are solid.
static func _box_collider(size: Vector3, center: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Collider"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.position = center
	return body


## Apply the web composition toggles to a support prop's cfg: integrated cap
## glow only when the light is on and in "glow" mode; strip the integrated info
## screen (plinth/bench info_* and wall screen_*) when the info board is off.
static func _apply_composition(cfg: Dictionary, show_light: bool, light_mode: String, show_info: bool) -> void:
	if cfg.has("glow_light"):
		cfg["glow_light"] = show_light and light_mode == "glow"
	if not show_info:
		for k in ["info_lines", "info_header", "screen_lines", "screen_header"]:
			cfg.erase(k)
		if cfg.has("screen_slot"):
			cfg["screen_slot"] = false


## A floor-standing gallery softbox PYLON on house-left: a weighted foot + a
## tall mast, with a station_task_light softbox head up top reaching +X and
## angled DOWN onto the artifact at centre (a proper pole light, not a desk lamp).
static func _place_softbox_pole(root: Node3D, origin_x: float, cols: int, lookup_cb: Callable) -> void:
	var base_x: float = origin_x - 0.7
	var mast_h: float = 1.45
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.74, 0.72, 0.68)
	mat.roughness = 0.7
	# Weighted foot disc.
	var foot := MeshInstance3D.new()
	var fm := CylinderMesh.new(); fm.top_radius = 0.16; fm.bottom_radius = 0.19; fm.height = 0.05
	foot.mesh = fm; foot.material_override = mat
	foot.position = Vector3(base_x, 0.025, 0.0)
	root.add_child(foot)
	# Mast.
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new(); mm.top_radius = 0.028; mm.bottom_radius = 0.034; mm.height = mast_h
	mast.mesh = mm; mast.material_override = mat
	mast.position = Vector3(base_x, mast_h * 0.5, 0.0)
	root.add_child(mast)
	# Solid in-game: a slim collider on the foot + mast so the pole is a real object.
	root.add_child(_box_collider(Vector3(0.24, mast_h, 0.24), Vector3(base_x, mast_h * 0.5, 0.0)))
	# Softbox head atop the mast, reaching toward the artifact and angled down.
	var reach: float = clampf(absf(base_x) * 0.7, 0.4, 1.0)
	var cfg := {
		"clamp_style": "base_plate", "head_style": "softbox", "head_size": 0.36,
		"reach": reach, "post_height": 0.25, "head_tilt": 40.0,
		"light_energy": 2.8, "spot_angle": 52.0, "spot_range": 5.0,
		"caution_stripe": false, "grime": false, "with_cable": true,
	}
	var lamp := _instantiate_registered("station_task_light", cfg, lookup_cb)
	if lamp:
		lamp.name = "SoftboxPole"
		lamp.position = Vector3(base_x, mast_h, 0.0)   # head up top, over the artifact
		root.add_child(lamp)


## Draw the footprint as a thin bounding-box FRAME (4 edges) on the floor,
## centred at (cx, cz) with extent w × d. Marks where the staging sits
## without the visual weight of solid tile cubes.
static func _add_footprint_frame(parent: Node3D, cx: float, cz: float, w: float, d: float, col: Color = FRAME_COLOR) -> void:
	var edges := [
		[Vector3(w, FRAME_THICK, FRAME_THICK), Vector3(0.0, FRAME_Y, -d * 0.5)],  # north
		[Vector3(w, FRAME_THICK, FRAME_THICK), Vector3(0.0, FRAME_Y,  d * 0.5)],  # south
		[Vector3(FRAME_THICK, FRAME_THICK, d), Vector3(-w * 0.5, FRAME_Y, 0.0)],  # west
		[Vector3(FRAME_THICK, FRAME_THICK, d), Vector3( w * 0.5, FRAME_Y, 0.0)],  # east
	]
	for e in edges:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = e[0]
		mi.mesh = b
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 1.1   # bright enough to read on any floor
		m.metallic = 0.0
		m.roughness = 0.9
		mi.material_override = m
		mi.position = Vector3(cx, 0.0, cz) + e[1]
		parent.add_child(mi)


## The artifact's TRUE extent (w × d, metres) from the size oracle's grid_cells,
## for the monument frame. 0 if unmeasured. Oracle cached across builds.
static var _size_oracle: Dictionary = {}
static func _monument_extent(name: String) -> Vector2:
	if _size_oracle.is_empty() and FileAccess.file_exists(SIZE_ORACLE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SIZE_ORACLE_PATH))
		if parsed is Dictionary:
			_size_oracle = parsed.get("sizes", parsed)
	var e = _size_oracle.get(name, null)
	if e is Dictionary:
		var gc = e.get("grid_cells", null)
		if gc is Array and gc.size() >= 2:
			return Vector2(float(gc[0]) * CELL_SIZE, float(gc[1]) * CELL_SIZE)
	return Vector2.ZERO


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
