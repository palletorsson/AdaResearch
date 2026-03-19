@tool
extends Node3D
class_name TilingSystem

## Architectural Tiling System — General-Purpose
##
## Multi-layer tiling composition for analyzing and reproducing any
## floor or wall tiling pattern algorithmically. Region-specific content
## (palettes, motifs, techniques) loaded from study pack JSON files.
##
## Universal composition zones (field, border, corner, threshold, medallion)
## work across all architectural traditions.

## Composition zones — universal across all traditions
enum CompositionZone {
	FIELD,       ## Main repeating area
	BORDER,      ## Surrounding frame band
	CORNER,      ## Corner treatments
	THRESHOLD,   ## Doorway/transition strips
	MEDALLION    ## Central focal point
}

## Tile shape types for mesh generation
enum TileShape {
	SQUARE,      ## Regular square grid
	HEXAGONAL,   ## Hexagonal tessellation
	TRIANGULAR,  ## Triangular grid
	IRREGULAR,   ## Irregular / organic
	POLYGON,     ## Large cut polygons (opus sectile)
	MIXED        ## Mix of shapes (cosmatesque)
}

## === EXPORTS ===

@export_group("Grid")
## Fundamental domain size (width = height for square domains)
@export var tile_size: int = 8:
	set(v):
		tile_size = clampi(v, 2, 32)
		if is_inside_tree() and not Engine.is_editor_hint():
			_rebuild()

## Total field size in tiles
@export var field_size: Vector2i = Vector2i(4, 4)

## Border width in cells
@export var border_width: int = 2

## Cell size in meters
@export var cell_size: float = 0.05

@export_group("Composition")
## Enable border layer
@export var has_border: bool = true

## Enable corner treatments
@export var has_corners: bool = true

## Enable central medallion
@export var has_medallion: bool = false

@export_group("Study Pack")
## Active study pack name (e.g., "italy", "japan")
@export var study_pack_name: String = "":
	set(v):
		if v == study_pack_name:
			return
		study_pack_name = v
		if v != "" and is_inside_tree():
			load_study_pack(v)

## Active technique from the loaded pack
@export var technique: String = ""

## Active period from the loaded pack
@export var period: String = ""

## Active site preset from the loaded pack
@export var site: String = ""

@export_group("Preview")
## Preview offset from editor
@export var preview_offset: Vector3 = Vector3(0, 0, -0.8)

## Show grid lines on preview
@export var show_grid_lines: bool = true

## === SIGNALS ===
signal composition_changed()
signal study_pack_loaded(pack_name: String)
signal motif_loaded(motif_name: String, zone: CompositionZone)

## === INTERNAL STATE ===

## Composition layers
var _layers: Dictionary = {}  # CompositionZone -> TilingLayer

## Loaded study pack data
var _pack_data: Dictionary = {}

## Active palette
var _palette: Array[Color] = [
	Color(0.95, 0.92, 0.85),
	Color(0.1, 0.1, 0.12),
	Color(0.8, 0.2, 0.15),
	Color(0.7, 0.55, 0.2)
]

## Composited output grid
var _composition: Array = []
var _composition_width: int = 0
var _composition_height: int = 0

## Tile shape config from technique
var _tile_shape: TileShape = TileShape.SQUARE
var _grout_width: float = 0.02
var _regularity: float = 1.0

## Visuals
var _preview_mesh: MeshInstance3D
var _preview_container: Node3D
var _analyzer: TilingAnalyzer

## Internal PatternTilePuzzle for active layer editing
var _active_zone: int = CompositionZone.FIELD


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_analyzer = TilingAnalyzer.new()

	# Initialize layers
	for zone in CompositionZone.values():
		_layers[zone] = TilingLayer.new()
		_layers[zone].zone = zone

	_create_preview()

	# Load study pack if set
	if study_pack_name != "":
		load_study_pack(study_pack_name)
	else:
		# Default: simple checkerboard
		var default_domain = [[0, 1], [1, 0]]
		_layers[CompositionZone.FIELD].set_fundamental_domain(
			default_domain, WallpaperGroups.Group.P4M,
			field_size.x * tile_size, field_size.y * tile_size)
		compose()


## === STUDY PACK MANAGEMENT ===

## Load a study pack JSON file by name.
func load_study_pack(pack_name: String) -> void:
	var path := "res://commons/primitives/arrays/study_packs/%s_tiling.json" % pack_name
	if not FileAccess.file_exists(path):
		push_warning("TilingSystem: Study pack not found: %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("TilingSystem: Could not open study pack: %s" % path)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("TilingSystem: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return

	_pack_data = json.data
	study_pack_name = pack_name
	study_pack_loaded.emit(pack_name)
	print("TilingSystem: Loaded study pack '%s'" % pack_name)


## Get available techniques from the loaded pack.
func get_available_techniques() -> Array[String]:
	var result: Array[String] = []
	if _pack_data.has("techniques"):
		for key in _pack_data["techniques"].keys():
			result.append(key)
	return result


## Get available periods from the loaded pack.
func get_available_periods() -> Array[String]:
	var result: Array[String] = []
	if _pack_data.has("periods"):
		for key in _pack_data["periods"].keys():
			result.append(key)
	return result


## Get available motifs from the loaded pack, optionally filtered by zone.
func get_available_motifs(zone_filter: int = -1) -> Array[String]:
	var result: Array[String] = []
	if _pack_data.has("motifs"):
		for key in _pack_data["motifs"].keys():
			if zone_filter < 0:
				result.append(key)
			else:
				var zone_str := _zone_to_string(zone_filter)
				if _pack_data["motifs"][key].get("zone", "") == zone_str:
					result.append(key)
	return result


## Get available site presets from the loaded pack.
func get_available_sites() -> Array[String]:
	var result: Array[String] = []
	if _pack_data.has("sites"):
		for key in _pack_data["sites"].keys():
			result.append(key)
	return result


## === TECHNIQUE AND PERIOD ===

## Set the active technique (configures tile shape, grout, regularity).
func set_technique(technique_name: String) -> void:
	technique = technique_name
	if not _pack_data.has("techniques") or not _pack_data["techniques"].has(technique_name):
		return

	var tech: Dictionary = _pack_data["techniques"][technique_name]
	_grout_width = tech.get("grout_width", 0.02)
	_regularity = tech.get("regularity", 1.0)

	var shape_str: String = tech.get("tile_shape", "square")
	match shape_str:
		"square": _tile_shape = TileShape.SQUARE
		"hexagonal": _tile_shape = TileShape.HEXAGONAL
		"triangular": _tile_shape = TileShape.TRIANGULAR
		"irregular": _tile_shape = TileShape.IRREGULAR
		"polygon": _tile_shape = TileShape.POLYGON
		"mixed": _tile_shape = TileShape.MIXED
		_: _tile_shape = TileShape.SQUARE


## Set the active period (loads palette).
func set_period(period_name: String) -> void:
	period = period_name
	if not _pack_data.has("periods") or not _pack_data["periods"].has(period_name):
		return

	var period_data: Dictionary = _pack_data["periods"][period_name]
	var hex_palette: Array = period_data.get("palette", [])
	_palette.clear()
	for hex_color in hex_palette:
		_palette.append(Color.html(hex_color))

	# Update preview with new palette
	_update_preview()


## Load a site preset (sets technique, period, palette, and default motifs).
func load_site(site_name: String) -> void:
	site = site_name
	if not _pack_data.has("sites") or not _pack_data["sites"].has(site_name):
		push_warning("TilingSystem: Site not found: %s" % site_name)
		return

	var site_data: Dictionary = _pack_data["sites"][site_name]

	# Set palette from site
	if site_data.has("palette"):
		_palette.clear()
		for hex_color in site_data["palette"]:
			_palette.append(Color.html(hex_color))

	# Set technique
	if site_data.has("default_technique"):
		set_technique(site_data["default_technique"])

	# Set period
	if site_data.has("default_period"):
		period = site_data["default_period"]

	# Load default motifs
	if site_data.has("default_motifs"):
		var motifs: Dictionary = site_data["default_motifs"]
		for zone_str in motifs:
			var zone := _string_to_zone(zone_str)
			if zone >= 0:
				load_motif(motifs[zone_str], zone)

	compose()


## === MOTIF MANAGEMENT ===

## Load a named motif from the current study pack into a composition zone.
func load_motif(motif_name: String, zone: int) -> void:
	if not _pack_data.has("motifs") or not _pack_data["motifs"].has(motif_name):
		push_warning("TilingSystem: Motif not found: %s" % motif_name)
		return

	var motif: Dictionary = _pack_data["motifs"][motif_name]
	var domain: Array = motif.get("domain", [])
	var group_str: String = motif.get("group", "P1")
	var group := _parse_wallpaper_group(group_str)

	# Calculate target size based on zone
	var target_w: int
	var target_h: int
	match zone:
		CompositionZone.FIELD:
			target_w = field_size.x * tile_size
			target_h = field_size.y * tile_size
		CompositionZone.BORDER:
			target_w = (field_size.x + 2) * tile_size
			target_h = border_width * tile_size
		CompositionZone.CORNER:
			target_w = border_width * tile_size
			target_h = border_width * tile_size
		CompositionZone.THRESHOLD:
			target_w = field_size.x * tile_size
			target_h = tile_size
		CompositionZone.MEDALLION:
			var med_size := mini(field_size.x, field_size.y) * tile_size / 2
			target_w = med_size
			target_h = med_size
		_:
			target_w = field_size.x * tile_size
			target_h = field_size.y * tile_size

	if zone in _layers:
		_layers[zone].set_fundamental_domain(domain, group, target_w, target_h)
		_layers[zone].enabled = true

	motif_loaded.emit(motif_name, zone)
	compose()


## Set a layer's fundamental domain directly (for custom patterns).
func set_layer_domain(zone: CompositionZone, domain: Array, group: WallpaperGroups.Group) -> void:
	if zone not in _layers:
		return
	var layer: TilingLayer = _layers[zone]
	var target_w := field_size.x * tile_size
	var target_h := field_size.y * tile_size
	layer.set_fundamental_domain(domain, group, target_w, target_h)
	compose()


## Switch which layer is "active" for VR editing.
func set_active_layer(zone: CompositionZone) -> void:
	_active_zone = zone


## Get the active layer.
func get_active_layer() -> TilingLayer:
	return _layers.get(_active_zone, null)


## === COMPOSITION ===

## Assemble all layers into the composited output grid.
func compose() -> Array:
	# Calculate total composition size including borders
	var total_w: int
	var total_h: int

	if has_border:
		total_w = (field_size.x * tile_size) + (border_width * 2)
		total_h = (field_size.y * tile_size) + (border_width * 2)
	else:
		total_w = field_size.x * tile_size
		total_h = field_size.y * tile_size

	_composition_width = total_w
	_composition_height = total_h

	# Initialize with background color (0)
	_composition.clear()
	for y in range(total_h):
		var row: Array = []
		row.resize(total_w)
		row.fill(0)
		_composition.append(row)

	# Layer 1: Field (center area)
	var field_layer: TilingLayer = _layers[CompositionZone.FIELD]
	if field_layer.enabled:
		var fx := border_width if has_border else 0
		var fy := border_width if has_border else 0
		var fw := field_size.x * tile_size
		var fh := field_size.y * tile_size
		field_layer.fill_rect(fx, fy, fw, fh, _composition)

	# Layer 2: Borders (frame around field)
	if has_border:
		var border_layer: TilingLayer = _layers[CompositionZone.BORDER]
		if border_layer.enabled:
			# Top border
			border_layer.fill_rect(0, 0, total_w, border_width, _composition)
			# Bottom border
			border_layer.fill_rect(0, total_h - border_width, total_w, border_width, _composition)
			# Left border
			border_layer.fill_rect(0, border_width, border_width, total_h - border_width * 2, _composition)
			# Right border
			border_layer.fill_rect(total_w - border_width, border_width, border_width, total_h - border_width * 2, _composition)

	# Layer 3: Corners (overwrites border corners)
	if has_corners and has_border:
		var corner_layer: TilingLayer = _layers[CompositionZone.CORNER]
		if corner_layer.enabled:
			corner_layer.fill_rect(0, 0, border_width, border_width, _composition)
			corner_layer.fill_rect(total_w - border_width, 0, border_width, border_width, _composition)
			corner_layer.fill_rect(0, total_h - border_width, border_width, border_width, _composition)
			corner_layer.fill_rect(total_w - border_width, total_h - border_width, border_width, border_width, _composition)

	# Layer 4: Medallion (center of field, overwrites field)
	if has_medallion:
		var med_layer: TilingLayer = _layers[CompositionZone.MEDALLION]
		if med_layer.enabled and med_layer.width > 0 and med_layer.height > 0:
			var mx := (total_w - med_layer.width) / 2
			var my := (total_h - med_layer.height) / 2
			med_layer.fill_rect(mx, my, med_layer.width, med_layer.height, _composition)

	# Layer 5: Threshold (bottom edge of field, optional)
	var threshold_layer: TilingLayer = _layers[CompositionZone.THRESHOLD]
	if threshold_layer.enabled:
		var tx := border_width if has_border else 0
		var ty := total_h - (border_width if has_border else 0) - tile_size
		threshold_layer.fill_rect(tx, ty, field_size.x * tile_size, tile_size, _composition)

	_update_preview()
	composition_changed.emit()
	return _composition


## Get the composited output grid.
func get_composition() -> Array:
	return _composition


## Get the active palette.
func get_palette() -> Array[Color]:
	return _palette


## === ANALYSIS ===

## Analyze a 2D color grid to determine its symmetry.
func analyze_pattern(grid_data: Array) -> Dictionary:
	if not _analyzer:
		_analyzer = TilingAnalyzer.new()
	var h := grid_data.size()
	var w: int = grid_data[0].size() if h > 0 else 0
	return _analyzer.analyze(grid_data, w, h)


## === 3D OUTPUT ===

## Spawn a floor mesh with the composited pattern at the given position.
func spawn_floor(at_position: Vector3, floor_size: Vector2 = Vector2(2.0, 2.0)) -> Node3D:
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "TiledFloor"

	var quad := QuadMesh.new()
	quad.size = floor_size
	floor_mesh.mesh = quad

	# Generate texture from composition
	var texture := _generate_texture()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.95
	floor_mesh.material_override = mat

	# Rotate to lie flat
	floor_mesh.rotation_degrees.x = -90
	floor_mesh.global_position = at_position

	# Add to scene
	var scene_root := get_tree().current_scene
	if scene_root:
		scene_root.add_child(floor_mesh)

	return floor_mesh


## Spawn a wall panel with the composited pattern.
func spawn_wall(at_position: Vector3, wall_size: Vector2 = Vector2(2.0, 2.0), normal: Vector3 = Vector3.FORWARD) -> Node3D:
	var wall_mesh := MeshInstance3D.new()
	wall_mesh.name = "TiledWall"

	var quad := QuadMesh.new()
	quad.size = wall_size
	wall_mesh.mesh = quad

	var texture := _generate_texture()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.9
	wall_mesh.material_override = mat

	wall_mesh.global_position = at_position
	# Orient wall to face the given normal
	if normal != Vector3.FORWARD:
		wall_mesh.look_at(at_position + normal, Vector3.UP)

	var scene_root := get_tree().current_scene
	if scene_root:
		scene_root.add_child(wall_mesh)

	return wall_mesh


## === GRID CONFIG INTEGRATION ===

## Apply configuration from grid system / artifact registry.
## Accepts: study_pack, technique, period, site, motif, etc.
func apply_grid_config(config_data: Dictionary) -> void:
	print("TilingSystem: Applying config: %s" % config_data)

	if config_data.has("study_pack"):
		load_study_pack(str(config_data["study_pack"]))

	if config_data.has("technique"):
		set_technique(str(config_data["technique"]))

	if config_data.has("period"):
		set_period(str(config_data["period"]))

	if config_data.has("site"):
		load_site(str(config_data["site"]))

	if config_data.has("tile_size"):
		tile_size = int(config_data["tile_size"])

	if config_data.has("field_size"):
		var fs = config_data["field_size"]
		if fs is String and "x" in fs:
			var parts = fs.split("x")
			field_size = Vector2i(int(parts[0]), int(parts[1]))

	if config_data.has("border_width"):
		border_width = int(config_data["border_width"])

	if config_data.has("has_border"):
		has_border = _to_bool(config_data["has_border"])

	if config_data.has("has_medallion"):
		has_medallion = _to_bool(config_data["has_medallion"])

	# Load motifs by zone
	if config_data.has("field_motif"):
		load_motif(str(config_data["field_motif"]), CompositionZone.FIELD)
	if config_data.has("border_motif"):
		load_motif(str(config_data["border_motif"]), CompositionZone.BORDER)
	if config_data.has("corner_motif"):
		load_motif(str(config_data["corner_motif"]), CompositionZone.CORNER)
	if config_data.has("medallion_motif"):
		load_motif(str(config_data["medallion_motif"]), CompositionZone.MEDALLION)

	# Shorthand: just a motif name as the key
	if _pack_data.has("motifs"):
		for key in config_data.keys():
			if key in _pack_data["motifs"]:
				var motif_data: Dictionary = _pack_data["motifs"][key]
				var zone := _string_to_zone(motif_data.get("zone", "field"))
				if zone >= 0:
					load_motif(key, zone)


## === PRIVATE ===

func _create_preview() -> void:
	_preview_container = Node3D.new()
	_preview_container.name = "Preview"
	_preview_container.position = preview_offset
	add_child(_preview_container)

	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.name = "PreviewMesh"
	_preview_container.add_child(_preview_mesh)


func _update_preview() -> void:
	if not _preview_mesh or _composition.is_empty():
		return

	var texture := _generate_texture()

	var quad := QuadMesh.new()
	quad.size = Vector2(
		_composition_width * cell_size,
		_composition_height * cell_size
	)
	_preview_mesh.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.95
	_preview_mesh.material_override = mat


func _generate_texture() -> ImageTexture:
	if _composition.is_empty():
		return ImageTexture.new()

	var image := Image.create(_composition_width, _composition_height, false, Image.FORMAT_RGBA8)

	for py in range(_composition_height):
		for px in range(_composition_width):
			var color_idx: int = _composition[py][px]
			var color: Color = _palette[color_idx] if color_idx < _palette.size() else Color.WHITE
			image.set_pixel(px, py, color)

	return ImageTexture.create_from_image(image)


func _rebuild() -> void:
	compose()


func _zone_to_string(zone: int) -> String:
	match zone:
		CompositionZone.FIELD: return "field"
		CompositionZone.BORDER: return "border"
		CompositionZone.CORNER: return "corner"
		CompositionZone.THRESHOLD: return "threshold"
		CompositionZone.MEDALLION: return "medallion"
	return "field"


func _string_to_zone(s: String) -> int:
	match s.to_lower().strip_edges():
		"field": return CompositionZone.FIELD
		"border": return CompositionZone.BORDER
		"corner": return CompositionZone.CORNER
		"threshold": return CompositionZone.THRESHOLD
		"medallion": return CompositionZone.MEDALLION
	return -1


func _parse_wallpaper_group(s: String) -> WallpaperGroups.Group:
	var group_map := {
		"p1": WallpaperGroups.Group.P1,
		"p2": WallpaperGroups.Group.P2,
		"pm": WallpaperGroups.Group.PM,
		"pg": WallpaperGroups.Group.PG,
		"cm": WallpaperGroups.Group.CM,
		"pmm": WallpaperGroups.Group.PMM,
		"pmg": WallpaperGroups.Group.PMG,
		"pgg": WallpaperGroups.Group.PGG,
		"cmm": WallpaperGroups.Group.CMM,
		"p4": WallpaperGroups.Group.P4,
		"p4m": WallpaperGroups.Group.P4M,
		"p4g": WallpaperGroups.Group.P4G,
		"p3": WallpaperGroups.Group.P3,
		"p3m1": WallpaperGroups.Group.P3M1,
		"p31m": WallpaperGroups.Group.P31M,
		"p6": WallpaperGroups.Group.P6,
		"p6m": WallpaperGroups.Group.P6M
	}
	return group_map.get(s.to_lower().strip_edges(), WallpaperGroups.Group.P1)


func _to_bool(value) -> bool:
	if value is bool:
		return value
	var s := str(value).to_lower().strip_edges()
	return s == "true" or s == "1" or s == "yes" or s == "on"


## === DEMO HELPERS ===
## Called via call_deferred from demo scenes after _ready().

func _demo_setup(motif_name: String, period_name: String) -> void:
	load_study_pack("italy")
	if period_name != "":
		set_period(period_name)
	load_motif(motif_name, CompositionZone.FIELD)


func _demo_composed_setup(site_name: String, field_motif: String, border_motif: String) -> void:
	load_study_pack("italy")
	if site_name != "":
		load_site(site_name)
	load_motif(field_motif, CompositionZone.FIELD)
	load_motif(border_motif, CompositionZone.BORDER)
