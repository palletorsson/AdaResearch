# pattern_loader.gd
# Loads pattern packages exported from the web Pattern Studio.
#
# A pattern package consists of:
#   - domain_NxN_GROUP.png  — fundamental domain texture
#   - pattern_NxN_GROUP.json — metadata (group, tile_scale, grout, etc.)
#
# Usage:
#   var pkg := PatternLoader.load_package("res://commons/patterns/my_pattern.json")
#   if pkg:
#       PatternLoader.apply_to_material(shader_material, pkg)
#
# Or apply directly to a MeshInstance3D:
#   PatternLoader.apply_to_mesh(mesh_instance, pkg)
extends Node
class_name PatternLoader

## Loaded pattern package data
class PatternPackage:
	var name: String = "Unnamed"
	var group: int = 0           # Wallpaper group index (0-16)
	var zone: String = "field"
	var domain_size: int = 4
	var tile_scale: float = 6.0
	var tile_shape: int = 0       # 0=square, 1=diagonal TL-BR, 4=TR-BL, 5=tumbling
	var grout_width: float = 0.0
	var noise_distort: float = 0.0
	var palette: PackedColorArray = PackedColorArray()
	var domain_texture: ImageTexture = null
	var domain_data: Array = []  # 2D array of color indices
	# Aging & weathering
	var wear_amount: float = 0.0
	var dust_amount: float = 0.0
	var fade_amount: float = 0.0
	var crack_density: float = 0.0
	var stain_amount: float = 0.0
	var chip_amount: float = 0.0

## Group name to shader index mapping
const GROUP_MAP: Dictionary = {
	"p1": 0, "p2": 1, "pm": 2, "pg": 3, "cm": 4,
	"pmm": 5, "pmg": 6, "pgg": 7, "cmm": 8,
	"p4": 9, "p4m": 10, "p4g": 11,
	"p3": 12, "p3m1": 13, "p31m": 14, "p6": 15, "p6m": 16
}

## Load a pattern package from a JSON file path.
## The domain PNG is expected alongside the JSON or embedded as palette+domain data.
static func load_package(json_path: String) -> PatternPackage:
	if not FileAccess.file_exists(json_path):
		push_warning("[PatternLoader] File not found: %s" % json_path)
		return null

	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_warning("[PatternLoader] Cannot open: %s" % json_path)
		return null

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("[PatternLoader] JSON parse error in %s: %s" % [json_path, json.get_error_message()])
		return null

	var data: Dictionary = json.data
	var pkg := PatternPackage.new()

	# Basic metadata
	pkg.name = data.get("name", "Unnamed")
	pkg.zone = data.get("zone", "field")
	pkg.domain_size = int(data.get("domain_size", 4))
	pkg.tile_scale = float(data.get("tile_scale", 6.0))
	pkg.tile_shape = int(data.get("tile_shape", 0))
	pkg.grout_width = float(data.get("grout_width", 0.0))
	pkg.noise_distort = float(data.get("noise_distort", 0.0))

	# Aging & weathering
	pkg.wear_amount = float(data.get("wear_amount", 0.0))
	pkg.dust_amount = float(data.get("dust_amount", 0.0))
	pkg.fade_amount = float(data.get("fade_amount", 0.0))
	pkg.crack_density = float(data.get("crack_density", 0.0))
	pkg.stain_amount = float(data.get("stain_amount", 0.0))
	pkg.chip_amount = float(data.get("chip_amount", 0.0))

	# Wallpaper group — accept string name or int index
	var group_val = data.get("group", 0)
	if group_val is String:
		pkg.group = GROUP_MAP.get(group_val.to_lower(), 0)
	else:
		pkg.group = clampi(int(group_val), 0, 16)

	# Palette colors
	var palette_arr: Array = data.get("palette", [])
	for hex_str in palette_arr:
		if hex_str is String:
			pkg.palette.append(Color.html(hex_str))

	# Domain data — 2D array of color indices
	var domain_arr: Array = data.get("domain", [])
	pkg.domain_data = domain_arr

	# Build domain texture from palette + domain data
	if pkg.palette.size() > 0 and domain_arr.size() > 0:
		pkg.domain_texture = _build_domain_texture(domain_arr, pkg.palette, pkg.domain_size)
	else:
		# Try loading companion PNG
		var png_path := json_path.get_base_dir().path_join(
			"domain_%dx%d_%s.png" % [pkg.domain_size, pkg.domain_size, _group_name(pkg.group)]
		)
		if FileAccess.file_exists(png_path):
			var img := Image.load_from_file(png_path)
			if img:
				pkg.domain_texture = ImageTexture.create_from_image(img)

	if not pkg.domain_texture:
		push_warning("[PatternLoader] No domain texture could be created for %s" % json_path)

	return pkg


## Build an ImageTexture from domain data (2D int array) + palette colors
static func _build_domain_texture(domain_data: Array, palette: PackedColorArray, size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		if y >= domain_data.size():
			break
		var row: Array = domain_data[y]
		for x in size:
			if x >= row.size():
				break
			var idx: int = int(row[x])
			var color: Color = palette[idx] if idx < palette.size() else Color.WHITE
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


## Get lowercase group name from index
static func _group_name(group_idx: int) -> String:
	for key in GROUP_MAP:
		if GROUP_MAP[key] == group_idx:
			return key
	return "p1"


## Apply a loaded pattern package to a ShaderMaterial.
## The material must already use wallpaper_tile.gdshader.
static func apply_to_material(mat: ShaderMaterial, pkg: PatternPackage) -> void:
	if not mat or not pkg:
		return
	if pkg.domain_texture:
		mat.set_shader_parameter("domain_texture", pkg.domain_texture)
	mat.set_shader_parameter("wallpaper_group", pkg.group)
	mat.set_shader_parameter("tile_scale", pkg.tile_scale)
	mat.set_shader_parameter("tile_shape", pkg.tile_shape)
	mat.set_shader_parameter("grout_width", pkg.grout_width)
	mat.set_shader_parameter("noise_distort", pkg.noise_distort)
	# Aging & weathering
	mat.set_shader_parameter("wear_amount", pkg.wear_amount)
	mat.set_shader_parameter("dust_amount", pkg.dust_amount)
	mat.set_shader_parameter("fade_amount", pkg.fade_amount)
	mat.set_shader_parameter("crack_density", pkg.crack_density)
	mat.set_shader_parameter("stain_amount", pkg.stain_amount)
	mat.set_shader_parameter("chip_amount", pkg.chip_amount)


## Create a new ShaderMaterial with wallpaper_tile shader and apply the pattern.
static func create_material(pkg: PatternPackage) -> ShaderMaterial:
	if not pkg:
		return null
	var shader := load("res://commons/resourses/shaders/wallpaper_tile.gdshader") as Shader
	if not shader:
		push_warning("[PatternLoader] Cannot load wallpaper_tile.gdshader")
		return null
	var mat := ShaderMaterial.new()
	mat.shader = shader
	apply_to_material(mat, pkg)
	return mat


## Apply a pattern to a MeshInstance3D (creates a new ShaderMaterial).
static func apply_to_mesh(mesh_instance: MeshInstance3D, pkg: PatternPackage) -> void:
	var mat := create_material(pkg)
	if mat:
		mesh_instance.material_override = mat


## ── Composite Mosaic Loading ─────────────────────────────────────

## Loaded composite mosaic data (multi-zone floor)
class MosaicComposite:
	var name: String = "Unnamed"
	var technique: String = "opus_tessellatum"
	var period: String = "roman_republican"
	var palette: PackedColorArray = PackedColorArray()
	var palette_hex: Array = []
	var border_width: int = 3
	var zones: Dictionary = {}  # zone_name -> PatternPackage
	var composed_texture: ImageTexture = null


## Load a multi-zone mosaic composite from JSON.
## Returns a MosaicComposite with per-zone PatternPackages and a composed texture.
static func load_composite(json_path: String, compose_size: int = 64) -> MosaicComposite:
	if not FileAccess.file_exists(json_path):
		push_warning("[PatternLoader] Composite not found: %s" % json_path)
		return null

	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return null

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("[PatternLoader] JSON parse error in %s: %s" % [json_path, json.get_error_message()])
		return null

	var data: Dictionary = json.data
	var composite := MosaicComposite.new()
	composite.name = data.get("name", "Unnamed")
	composite.technique = data.get("technique", "opus_tessellatum")
	composite.period = data.get("period", "roman_republican")
	composite.border_width = int(data.get("border_width", 3))

	# Parse palette
	var palette_arr: Array = data.get("palette", [])
	composite.palette_hex = palette_arr
	for hex_str in palette_arr:
		if hex_str is String:
			composite.palette.append(Color.html(hex_str))

	# Parse each zone into a PatternPackage
	var zones_data: Dictionary = data.get("zones", {})
	for zone_name in zones_data:
		var zd: Dictionary = zones_data[zone_name]
		var pkg := PatternPackage.new()
		pkg.name = str(zd.get("motif", zone_name))
		pkg.zone = zone_name

		var group_val = zd.get("group", "P1")
		if group_val is String:
			pkg.group = GROUP_MAP.get(group_val.to_lower(), 0)
		else:
			pkg.group = clampi(int(group_val), 0, 16)

		pkg.domain_size = int(zd.get("domain_size", 4))
		pkg.domain_data = zd.get("domain", [])
		pkg.palette = composite.palette

		# Weathering
		var w: Dictionary = zd.get("weathering", {})
		pkg.wear_amount = float(w.get("wear_amount", 0.0))
		pkg.dust_amount = float(w.get("dust_amount", 0.0))
		pkg.fade_amount = float(w.get("fade_amount", 0.0))
		pkg.crack_density = float(w.get("crack_density", 0.0))
		pkg.stain_amount = float(w.get("stain_amount", 0.0))
		pkg.chip_amount = float(w.get("chip_amount", 0.0))

		# Build zone domain texture
		if composite.palette.size() > 0 and pkg.domain_data.size() > 0:
			pkg.domain_texture = _build_domain_texture(pkg.domain_data, composite.palette, pkg.domain_size)

		composite.zones[zone_name] = pkg

	# Compose all zones into a single baked texture
	composite.composed_texture = _compose_zones(composite, compose_size)

	return composite


## Compose multiple zones into a single ImageTexture.
## Border fills all, field overwrites center, corners overwrite corners, threshold bottom strip.
static func _compose_zones(composite: MosaicComposite, size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var bw: int = composite.border_width

	# Helper: get color for a pixel from a zone's tiled domain
	var _get_zone_color := func(pkg: PatternPackage, x: int, y: int) -> Color:
		if pkg.domain_data.size() == 0 or pkg.domain_size <= 0:
			return Color.WHITE
		var ds: int = pkg.domain_size
		var row: Array = pkg.domain_data[y % ds] if (y % ds) < pkg.domain_data.size() else []
		var idx: int = int(row[x % ds]) if (x % ds) < row.size() else 0
		return composite.palette[idx] if idx < composite.palette.size() else Color.WHITE

	# 1. Border fills everything
	var border_pkg: PatternPackage = composite.zones.get("border")
	if border_pkg:
		for y in size:
			for x in size:
				image.set_pixel(x, y, _get_zone_color.call(border_pkg, x, y))

	# 2. Field overwrites inner rectangle
	var field_pkg: PatternPackage = composite.zones.get("field")
	if field_pkg:
		var fw: int = size - bw * 2
		var fh: int = size - bw * 2
		if fw > 0 and fh > 0:
			for y in fh:
				for x in fw:
					image.set_pixel(x + bw, y + bw, _get_zone_color.call(field_pkg, x, y))

	# 3. Corners overwrite 4 border corner squares
	var corner_pkg: PatternPackage = composite.zones.get("corner")
	if corner_pkg and bw > 0:
		for y in bw:
			for x in bw:
				var c: Color = _get_zone_color.call(corner_pkg, x, y)
				image.set_pixel(x, y, c)                          # top-left
				image.set_pixel(size - bw + x, y, c)              # top-right
				image.set_pixel(x, size - bw + y, c)              # bottom-left
				image.set_pixel(size - bw + x, size - bw + y, c)  # bottom-right

	# 4. Threshold overwrites bottom strip
	var thresh_pkg: PatternPackage = composite.zones.get("threshold")
	if thresh_pkg:
		var th: int = maxi(2, bw)
		for y in th:
			for x in size:
				if (size - th + y) >= 0:
					image.set_pixel(x, size - th + y, _get_zone_color.call(thresh_pkg, x, y))

	return ImageTexture.create_from_image(image)
