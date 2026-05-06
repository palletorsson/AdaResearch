extends Node3D
class_name GroundLayerComponent

## ground_layer_component.gd
##
## Consumes a `ground_paint` 2D array (tokens from
## commons/biome_layers/ground_types.json) and renders the ground as
## one MultiMeshInstance3D PER USED TYPE. Each multimesh has N
## instances of a 1×1m unit plane, transformed to each cell's world
## position. Material per multimesh = the type's living_ground
## material (kingdom-context-free here — kingdom presence overlays
## come from the biome_paint dispatcher's existing flow).
##
## Tokens accepted:
##   "mo" / "moss"      "so" / "soil"   "st" / "stone"   "sd" / "sand"
##   "sn" / "snow"      "as" / "ash"    "wd" / "wood"    "vd" / "void"
##   ""  / "-"          → no ground tile (stays untiled, e.g. for
##                       structure-layer cubes that already cover the
##                       footprint)
##
## VR cost: one draw call per ground type used in the map. A 100-cell
## grid with 4 types in use = 4 draw calls (vs 100 for one-mesh-per-cell).

const GROUND_TYPES_PATH := "res://commons/biome_layers/ground_types.json"
const SHADER_PATH := "res://algorithms/nature_system/shaders/living_ground.gdshader"

var _types_catalog: Dictionary = {}
var _kingdom_to_ground: Dictionary = {}
var _terrain_mode_to_ground: Dictionary = {}


func _ready() -> void:
	_load_catalog()


func _load_catalog() -> void:
	if not _types_catalog.is_empty():
		return
	var f := FileAccess.open(GROUND_TYPES_PATH, FileAccess.READ)
	if f == null:
		push_warning("[GroundLayer] catalog missing: %s" % GROUND_TYPES_PATH)
		return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		var d: Dictionary = parsed
		_types_catalog = d.get("types", {})
		_kingdom_to_ground = d.get("kingdom_to_ground", {})
		_terrain_mode_to_ground = d.get("terrain_mode_to_ground", {})


## Apply ground_paint to the world with a smart fallback chain.
##
## Per-cell ground type resolution, in priority order:
##   1. Explicit ground_paint cell (a token from the catalog) — used directly
##   2. Empty ground_paint cell + biome_paint cell with a kingdom →
##      look up the kingdom in `kingdom_to_ground` (e.g. f3 → soil, t2 → moss)
##   3. Empty ground_paint cell + empty biome_paint cell + a `terrain_mode` →
##      look up the mode in `terrain_mode_to_ground` (e.g. "stone_floor" → stone)
##   4. Otherwise no tile (cell stays bare floor)
##
## The point: authors usually only paint biome_paint, and the ground "just
## works". They reach for ground_paint only for orthogonal cases —
## stone path through grass, fungus on a fallen log, lab floor with potted
## plants, etc.
##
## Two layer formats accepted (matches biome_paint conventions):
##   1. Array of String rows, space-separated  —  ["mo mo so", "mo so st"]
##   2. Array of Array-of-String rows           —  [["mo","mo","so"], ...]
##
## Args:
##   layer        — Array, ground_paint layer (either format above)
##   ctx          — Dictionary with:
##                    grid_center   : Vector3
##                    grid_dims     : Vector3i (cells)
##                    cube_size     : float
##                    biome_paint   : Array (optional — for kingdom fallback)
##                    terrain_mode  : String (optional — for terrain fallback)
##
## Returns: { "draw_calls": int, "tiles": int, "by_source": Dictionary }
func apply(layer: Array, ctx: Dictionary) -> Dictionary:
	_load_catalog()
	# Drop any prior ground we built (idempotent rebuild).
	for child in get_children():
		child.queue_free()

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(0, 0, 0))
	var cube_size: float = float(ctx.get("cube_size", 1.0))
	var biome_paint: Array = ctx.get("biome_paint", [])
	var terrain_mode: String = String(ctx.get("terrain_mode", ""))

	# Resolve the fallback ground from terrain_mode (used when both
	# ground_paint and biome_paint cells are empty).
	# Some entries in terrain_mode_to_ground map to JSON null (e.g. "flat" →
	# no ground tile at all). Godot 4's String() constructor rejects null,
	# so type-check before coercing.
	var raw_default: Variant = _terrain_mode_to_ground.get(terrain_mode, "")
	var terrain_default: String = ""
	if raw_default is String:
		terrain_default = raw_default

	# Bucket cells by type. Track source counts for diagnostics.
	var by_type: Dictionary = {}  # type_id -> Array[Vector3]
	var src_counts: Dictionary = {"explicit": 0, "kingdom": 0, "terrain": 0, "skipped": 0}

	# Determine the iteration grid. Use the larger of the two layers'
	# dimensions so we don't miss cells.
	var ground_rows: int = layer.size()
	var biome_rows: int = biome_paint.size()
	var n_rows: int = maxi(ground_rows, biome_rows)
	# If both are empty and terrain_mode has no default, we still want
	# to iterate the full grid_dims so terrain-only fallback paints.
	if n_rows == 0:
		n_rows = grid_dims.z

	for z in n_rows:
		var ground_tokens: PackedStringArray = _row_to_tokens(layer, z)
		var biome_tokens: PackedStringArray = _row_to_tokens(biome_paint, z)
		var n_cols: int = maxi(ground_tokens.size(), biome_tokens.size())
		if n_cols == 0:
			n_cols = grid_dims.x
		for x in n_cols:
			var resolved: String = ""
			# 1. Explicit ground_paint
			if x < ground_tokens.size():
				var raw: String = ground_tokens[x].strip_edges()
				if not raw.is_empty() and raw != "-":
					resolved = _normalise_token(raw)
					if not resolved.is_empty():
						src_counts.explicit += 1
			# 2. Kingdom inference from biome_paint
			if resolved.is_empty() and x < biome_tokens.size():
				var bt: String = biome_tokens[x].strip_edges()
				if not bt.is_empty():
					# Strip intensity digit: "f3" → "f", but keep "-"
					var key: String = bt
					if key.length() > 1 and key[0] != "-":
						key = key.substr(0, 1)
					var inferred: String = String(_kingdom_to_ground.get(key, ""))
					if not inferred.is_empty():
						resolved = inferred
						src_counts.kingdom += 1
			# 3. Terrain mode default
			if resolved.is_empty() and not terrain_default.is_empty():
				resolved = terrain_default
				src_counts.terrain += 1
			# 4. Skip
			if resolved.is_empty():
				src_counts.skipped += 1
				continue

			if not by_type.has(resolved):
				by_type[resolved] = []
			# Convert (x, z) cell to world, top-of-floor surface.
			var wx: float = grid_center.x + (float(x) - float(grid_dims.x) * 0.5 + 0.5) * cube_size
			var wz: float = grid_center.z + (float(z) - float(grid_dims.z) * 0.5 + 0.5) * cube_size
			var wy: float = grid_center.y + 0.01
			(by_type[resolved] as Array).append(Vector3(wx, wy, wz))

	# Build one MultiMesh per type.
	var tile_count: int = 0
	for type_id in by_type:
		var positions: Array = by_type[type_id] as Array
		if positions.is_empty():
			continue
		_spawn_multimesh_for_type(type_id, positions, cube_size)
		tile_count += positions.size()

	return {
		"draw_calls": by_type.size(),
		"tiles": tile_count,
		"by_source": src_counts,
	}


## Normalise a row from either format to a PackedStringArray of cell tokens.
func _row_to_tokens(layer: Array, z: int) -> PackedStringArray:
	if z >= layer.size():
		return PackedStringArray()
	var row_raw = layer[z]
	if row_raw is String:
		return (row_raw as String).split(" ", false)
	elif row_raw is Array:
		var tokens := PackedStringArray()
		for cell in row_raw:
			tokens.append(str(cell))
		return tokens
	return PackedStringArray()


## Map both short tokens ("mo") and long tokens ("moss") to the
## type-id used as the catalog key.
func _normalise_token(token: String) -> String:
	# If the token IS a catalog key, use it directly.
	if _types_catalog.has(token):
		return token
	# Otherwise look up by short token field.
	for type_id in _types_catalog:
		var def: Dictionary = _types_catalog[type_id]
		if def.get("token", "") == token:
			return type_id
	return ""


func _spawn_multimesh_for_type(type_id: String,
		positions: Array, cube_size: float) -> void:
	var type_def: Dictionary = _types_catalog.get(type_id, {})
	if type_def.is_empty():
		return

	# Canonical mesh — 1×1m plane, 8×8 subdivision so per-cell vertex
	# displacement from the shader has somewhere to displace into. (Higher
	# subdivision improves detail but multiplies vertex count by N tiles.)
	var plane := PlaneMesh.new()
	plane.size = Vector2(cube_size, cube_size)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8

	var mat := _make_material(type_def, cube_size)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.use_custom_data = false
	mm.mesh = plane
	mm.instance_count = positions.size()
	for i in positions.size():
		var t := Transform3D(Basis(), positions[i])
		mm.set_instance_transform(i, t)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Ground_%s_Multimesh" % type_id
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)


func _make_material(type_def: Dictionary, cube_size: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	if not ResourceLoader.exists(SHADER_PATH):
		push_warning("[GroundLayer] shader missing: %s" % SHADER_PATH)
		return mat
	mat.shader = load(SHADER_PATH)

	# We don't write per-tile presence here — that's the biome_paint
	# dispatcher's job (it deposits into PresenceGrid as organisms
	# spawn). Pass a 1-pixel empty texture so the shader has something
	# to sample; world_size is set so per-tile UV maps cleanly within
	# its own cell.
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	mat.set_shader_parameter("presence_map",
		ImageTexture.create_from_image(img))
	mat.set_shader_parameter("world_size", Vector2(cube_size, cube_size))
	mat.set_shader_parameter("world_offset", Vector2.ZERO)

	# Per-type material params.
	var warm_arr: Array = type_def.get("base_color_warm",
		[0.28, 0.22, 0.15])
	var cool_arr: Array = type_def.get("base_color_cool",
		[0.18, 0.20, 0.16])
	mat.set_shader_parameter("base_color_warm",
		Color(float(warm_arr[0]), float(warm_arr[1]), float(warm_arr[2])))
	mat.set_shader_parameter("base_color_cool",
		Color(float(cool_arr[0]), float(cool_arr[1]), float(cool_arr[2])))
	mat.set_shader_parameter("displacement_strength",
		float(type_def.get("displacement_strength", 0.04)))
	mat.set_shader_parameter("base_texture_scale",
		float(type_def.get("base_texture_scale", 8.0)))

	return mat
