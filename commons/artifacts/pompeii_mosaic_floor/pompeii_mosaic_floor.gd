# pompeii_mosaic_floor.gd
# Procedural Pompeii mosaic floor — builds geometry directly.
# No shader bridge needed: border quads + truchet triangles as mesh.
#
# @identity
#   essence: a floor that carries the geometry of Roman domestic space
#   desire: players look down and see 2000-year-old pattern logic still tiling
#   critical_parameter: tiles_short — number of truchet tiles on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that symmetry groups predate their mathematics
#   needs: [implemented] procedural mesh, border bands, truchet pinwheel
#   relationships: pattern_maker_station (web editor), mosaic_editor (composition)
#   truth: constraint applied to two colors on a grid produced all of Pompeii's floors

extends Node3D
class_name PompeiiMosaicFloor

## Floor dimensions in meters
@export var floor_size: Vector2 = Vector2(1.2, 0.9)

## Number of truchet tiles on the short axis
@export var tiles_short: int = 10

## Border band widths (outside → inside), in tile units
## Default: dark(2) light(1) dark(2) light(1) = 6 total
@export var border_widths: Array[int] = [2, 1, 2, 1]

## Palette: dark, light
@export var color_dark: Color = Color.html("#141418")
@export var color_light: Color = Color.html("#EBE6D9")

## Grout
@export var grout_color: Color = Color.html("#78706480")
@export_range(0.0, 0.1) var grout_width: float = 0.003

## Global wear 0-1
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _root: Node3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", 10))
	wear_level = float(config.get("wear_level", 0.3))
	grout_width = float(config.get("grout_width", 0.003))

	var bw = config.get("border_widths", null)
	if bw is Array:
		border_widths.clear()
		for v in bw:
			border_widths.append(int(v))

	_build()


func _build() -> void:
	# Clear previous
	if _root:
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "FloorMesh"
	add_child(_root)

	# Compute grid
	var short_m: float = minf(floor_size.x, floor_size.y)
	var total_border: int = 0
	for bw in border_widths:
		total_border += bw
	# Total border on each side
	var border_each: int = total_border

	# Tile size based on short axis: short_m = (tiles_short + 2*border_each) * tile_size
	var total_tiles_short: int = tiles_short + border_each * 2
	var tile_size: float = short_m / float(total_tiles_short)

	var long_m: float = maxf(floor_size.x, floor_size.y)
	var is_wide: bool = floor_size.x >= floor_size.y
	var total_tiles_long: int = int(round(long_m / tile_size))
	# Adjust long dimension to fit exactly
	var actual_long: float = total_tiles_long * tile_size

	var grid_w: int = total_tiles_long if is_wide else total_tiles_short
	var grid_h: int = total_tiles_short if is_wide else total_tiles_long
	var actual_w: float = grid_w * tile_size
	var actual_h: float = grid_h * tile_size

	# Field bounds (inside all borders)
	var field_x0: int = border_each
	var field_y0: int = border_each
	var field_x1: int = grid_w - border_each
	var field_y1: int = grid_h - border_each

	# Materials
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = color_dark
	mat_dark.roughness = 0.85

	var mat_light := StandardMaterial3D.new()
	mat_light.albedo_color = color_light
	mat_light.roughness = 0.75

	var mat_grout := StandardMaterial3D.new()
	mat_grout.albedo_color = grout_color
	mat_grout.roughness = 0.95

	# Origin: center the floor
	var origin := Vector3(-actual_w * 0.5, 0.005, -actual_h * 0.5)

	# 1. Build border bands
	var inset: int = 0
	for i in border_widths.size():
		var bw: int = border_widths[i]
		var band_color: Color = color_dark if (i % 2 == 0) else color_light
		_add_border_band(origin, grid_w, grid_h, tile_size, inset, bw, band_color)
		inset += bw

	# 2. Build truchet field
	_add_truchet_field(origin, tile_size, field_x0, field_y0, field_x1, field_y1)

	# 3. Build grout grid
	if grout_width > 0.001:
		_add_grout(origin, tile_size, grid_w, grid_h, field_x0, field_y0, field_x1, field_y1)

	print("[PompeiiMosaicFloor] Built %dx%d grid, %d field tiles, %d border bands" % [
		grid_w, grid_h,
		(field_x1 - field_x0) * (field_y1 - field_y0),
		border_widths.size()
	])


func _add_border_band(origin: Vector3, grid_w: int, grid_h: int,
		tile_size: float, inset: int, band_w: int, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8

	var rx: int = inset
	var ry: int = inset
	var rw: int = grid_w - inset * 2
	var rh: int = grid_h - inset * 2

	# Top strip
	_add_quad(origin, rx, ry, rw, band_w, tile_size, mat)
	# Bottom strip
	_add_quad(origin, rx, ry + rh - band_w, rw, band_w, tile_size, mat)
	# Left strip (between top and bottom)
	_add_quad(origin, rx, ry + band_w, band_w, rh - band_w * 2, tile_size, mat)
	# Right strip
	_add_quad(origin, rx + rw - band_w, ry + band_w, band_w, rh - band_w * 2, tile_size, mat)


func _add_quad(origin: Vector3, gx: int, gy: int, gw: int, gh: int,
		tile_size: float, mat: StandardMaterial3D) -> void:
	if gw <= 0 or gh <= 0:
		return
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(gw * tile_size, gh * tile_size)
	mi.mesh = quad
	mi.material_override = mat
	# Quad faces +Y by default, rotate to face up (floor)
	mi.rotation_degrees.x = -90
	mi.position = origin + Vector3(
		(gx + gw * 0.5) * tile_size,
		0,
		(gy + gh * 0.5) * tile_size
	)
	_root.add_child(mi)


func _add_truchet_field(origin: Vector3, tile_size: float,
		x0: int, y0: int, x1: int, y1: int) -> void:
	# Build all truchet triangles as a single ImmediateMesh for performance
	var mesh := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.rotation_degrees.x = -90
	mi.position = origin + Vector3(0, 0.0001, 0)  # Slightly above borders
	_root.add_child(mi)

	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = color_dark
	mat_dark.roughness = 0.85
	mat_dark.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mat_light := StandardMaterial3D.new()
	mat_light.albedo_color = color_light
	mat_light.roughness = 0.75
	mat_light.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Surface 0: dark triangles
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for ty in range(y0, y1):
		for tx in range(x0, x1):
			var px: float = tx * tile_size
			var py: float = ty * tile_size
			var ts: float = tile_size

			var even_diag: bool = ((tx + ty) % 2) == 0
			var flip_colors: bool = ((ty - y0) % 2) == 1

			# Determine which triangle is dark
			var dark_is_upper_left: bool
			if even_diag:
				# TL-BR diagonal: upper-left tri vs lower-right tri
				dark_is_upper_left = not flip_colors
			else:
				# TR-BL diagonal: upper-right tri vs lower-left tri
				dark_is_upper_left = not flip_colors

			if even_diag:
				# TL-BR diagonal ╲
				if dark_is_upper_left:
					# Dark = upper-left triangle
	
					mesh.surface_add_vertex(Vector3(px, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py, 0))
					mesh.surface_add_vertex(Vector3(px, py + ts, 0))
				else:
					# Dark = lower-right triangle
	
					mesh.surface_add_vertex(Vector3(px + ts, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py + ts, 0))
					mesh.surface_add_vertex(Vector3(px, py + ts, 0))
			else:
				# TR-BL diagonal ╱
				if dark_is_upper_left:
					# Dark = upper-right triangle
	
					mesh.surface_add_vertex(Vector3(px, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py + ts, 0))
				else:
					# Dark = lower-left triangle
	
					mesh.surface_add_vertex(Vector3(px, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py + ts, 0))
					mesh.surface_add_vertex(Vector3(px, py + ts, 0))
	mesh.surface_end()
	mesh.surface_set_material(0, mat_dark)

	# Surface 1: light triangles
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for ty in range(y0, y1):
		for tx in range(x0, x1):
			var px: float = tx * tile_size
			var py: float = ty * tile_size
			var ts: float = tile_size

			var even_diag: bool = ((tx + ty) % 2) == 0
			var flip_colors: bool = ((ty - y0) % 2) == 1

			var dark_is_upper_left: bool
			if even_diag:
				dark_is_upper_left = not flip_colors
			else:
				dark_is_upper_left = not flip_colors

			if even_diag:
				# TL-BR diagonal ╲
				if dark_is_upper_left:
					# Light = lower-right triangle
	
					mesh.surface_add_vertex(Vector3(px + ts, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py + ts, 0))
					mesh.surface_add_vertex(Vector3(px, py + ts, 0))
				else:
					# Light = upper-left triangle
	
					mesh.surface_add_vertex(Vector3(px, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py, 0))
					mesh.surface_add_vertex(Vector3(px, py + ts, 0))
			else:
				# TR-BL diagonal ╱
				if dark_is_upper_left:
					# Light = lower-left triangle
	
					mesh.surface_add_vertex(Vector3(px, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py + ts, 0))
					mesh.surface_add_vertex(Vector3(px, py + ts, 0))
				else:
					# Light = upper-right triangle
	
					mesh.surface_add_vertex(Vector3(px, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py, 0))
					mesh.surface_add_vertex(Vector3(px + ts, py + ts, 0))
	mesh.surface_end()
	mesh.surface_set_material(1, mat_light)


func _add_grout(origin: Vector3, tile_size: float,
		grid_w: int, grid_h: int,
		fx0: int, fy0: int, fx1: int, fy1: int) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = grout_color
	mat.roughness = 0.95
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mesh := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.rotation_degrees.x = -90
	mi.position = origin + Vector3(0, 0.0002, 0)  # Slightly above floor
	_root.add_child(mi)

	var gw: float = grout_width
	var half_gw: float = gw * 0.5
	var total_w: float = grid_w * tile_size
	var total_h: float = grid_h * tile_size

	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Horizontal grout lines
	for gy in range(0, grid_h + 1):
		var y: float = gy * tile_size
		# Thin quad as two triangles
		mesh.surface_add_vertex(Vector3(0, y - half_gw, 0))
		mesh.surface_add_vertex(Vector3(total_w, y - half_gw, 0))
		mesh.surface_add_vertex(Vector3(total_w, y + half_gw, 0))
		mesh.surface_add_vertex(Vector3(0, y - half_gw, 0))
		mesh.surface_add_vertex(Vector3(total_w, y + half_gw, 0))
		mesh.surface_add_vertex(Vector3(0, y + half_gw, 0))

	# Vertical grout lines
	for gx in range(0, grid_w + 1):
		var x: float = gx * tile_size
		mesh.surface_add_vertex(Vector3(x - half_gw, 0, 0))
		mesh.surface_add_vertex(Vector3(x + half_gw, 0, 0))
		mesh.surface_add_vertex(Vector3(x + half_gw, total_h, 0))
		mesh.surface_add_vertex(Vector3(x - half_gw, 0, 0))
		mesh.surface_add_vertex(Vector3(x + half_gw, total_h, 0))
		mesh.surface_add_vertex(Vector3(x - half_gw, total_h, 0))

	# Diagonal grout in the field
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var px: float = tx * tile_size
			var py: float = ty * tile_size
			var ts: float = tile_size
			var even_diag: bool = ((tx + ty) % 2) == 0

			# Diagonal line as a thin quad (2 triangles)
			if even_diag:
				# TL-BR: from (px, py+ts) to (px+ts, py)
				var dx: float = ts * 0.7071
				var nx: float = half_gw * 0.7071
				# Perpendicular offset for line thickness
				mesh.surface_add_vertex(Vector3(px - nx, py + ts + nx, 0))
				mesh.surface_add_vertex(Vector3(px + ts - nx, py + nx, 0))
				mesh.surface_add_vertex(Vector3(px + ts + nx, py - nx, 0))
				mesh.surface_add_vertex(Vector3(px - nx, py + ts + nx, 0))
				mesh.surface_add_vertex(Vector3(px + ts + nx, py - nx, 0))
				mesh.surface_add_vertex(Vector3(px + nx, py + ts - nx, 0))
			else:
				# TR-BL: from (px, py) to (px+ts, py+ts)
				var nx: float = half_gw * 0.7071
				mesh.surface_add_vertex(Vector3(px - nx, py - nx, 0))
				mesh.surface_add_vertex(Vector3(px + ts - nx, py + ts - nx, 0))
				mesh.surface_add_vertex(Vector3(px + ts + nx, py + ts + nx, 0))
				mesh.surface_add_vertex(Vector3(px - nx, py - nx, 0))
				mesh.surface_add_vertex(Vector3(px + ts + nx, py + ts + nx, 0))
				mesh.surface_add_vertex(Vector3(px + nx, py + nx, 0))

	mesh.surface_end()
