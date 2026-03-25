# pixel_cross_floor.gd
# Procedural pixel art floor — large pixel crosses on dark background.
# Each cross is 5x5 cells: center + 4 arms (3 cells each direction).
# Alternating green and hot pink crosses, staggered rows for carpet effect.
#
# @identity
#   essence: a floor encoding the cross as a fundamental pixel primitive
#   desire: players look down and see bold neon crosses marching across black
#   critical_parameter: tiles_short — pixel resolution on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that a plus sign is the 4-connected neighborhood of a center pixel
#   needs: [implemented] procedural mesh, cross template, staggered placement
#   relationships: pixel_invader_floor (pixel art sibling), rainbow_checker_floor (bold pattern cousin)
#   truth: the cross is the simplest shape that encodes adjacency in a grid

extends Node3D
class_name PixelCrossFloor

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 35
@export var border_width: int = 2

var _mi: MeshInstance3D
var _body: StaticBody3D

const COLOR_GREEN := Color(0.0, 1.0, 0.255, 1.0)       # #00FF41
const COLOR_HOT_PINK := Color(1.0, 0.078, 0.576, 1.0)  # #FF1493
const COLOR_BLACK := Color(0.04, 0.04, 0.04, 1.0)       # #0A0A0A

# Cross template: 5x5 with center + arms
const CROSS_TEMPLATE: Array = [
	[0, 0, 1, 0, 0],
	[0, 0, 1, 0, 0],
	[1, 1, 1, 1, 1],
	[0, 0, 1, 0, 0],
	[0, 0, 1, 0, 0],
]


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	_build()


func _create_neon_material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.0
	mat.roughness = 0.8
	if emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3
	return mat


func _build() -> void:
	if _mi:
		_mi.queue_free()
	if _body:
		_body.queue_free()

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_width * 2
	var ts := short_m / float(total_short)
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long
	var fw := gw * ts
	var fh := gh * ts

	var field_x0 := border_width
	var field_y0 := border_width
	var field_x1 := gw - border_width
	var field_y1 := gh - border_width

	# 3 surfaces: green, pink, black
	var green_verts := PackedVector3Array()
	var pink_verts := PackedVector3Array()
	var black_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Cross tiling: 7x7 spacing (5x5 cross + 2 gap), staggered by half on odd rows
	var cross_size: int = 5
	var spacing: int = 7  # cross + 2 cell gap
	var stagger: int = spacing / 2  # half-spacing offset for odd rows

	# Build a lookup of which cells are cross pixels and their color
	var field_w := field_x1 - field_x0
	var field_h := field_y1 - field_y0
	var cross_map := {}  # Vector2i -> 0 (green) or 1 (pink)

	var cross_row: int = 0
	var cy: int = 0
	while cy < field_h:
		var cx_offset: int = stagger if (cross_row % 2 == 1) else 0
		var cross_col: int = 0
		var cx: int = cx_offset
		while cx < field_w:
			# Determine color: checkerboard of crosses
			var use_green: bool = (cross_row + cross_col) % 2 == 0
			var color_idx: int = 0 if use_green else 1

			# Stamp cross template
			for row_i in cross_size:
				var trow: Array = CROSS_TEMPLATE[row_i]
				for col_i in cross_size:
					if trow[col_i] == 1:
						var lx := cx + col_i
						var ly := cy + row_i
						if lx >= 0 and lx < field_w and ly >= 0 and ly < field_h:
							cross_map[Vector2i(lx, ly)] = color_idx

			cx += spacing
			cross_col += 1
		cy += spacing
		cross_row += 1

	# Border
	for ty in range(0, gh):
		for tx in range(0, gw):
			var in_field := tx >= field_x0 and tx < field_x1 and ty >= field_y0 and ty < field_y1
			if not in_field:
				var x := tx * ts
				var z := ty * ts
				# Alternating green/pink/black border
				var dist := mini(mini(tx, gw - 1 - tx), mini(ty, gh - 1 - ty))
				if dist == 0:
					green_verts = _add_rect.call(green_verts, x, z, ts, ts)
				elif dist == 1:
					pink_verts = _add_rect.call(pink_verts, x, z, ts, ts)
				else:
					black_verts = _add_rect.call(black_verts, x, z, ts, ts)

	# Field cells
	for ty in range(field_y0, field_y1):
		for tx in range(field_x0, field_x1):
			var x := tx * ts
			var z := ty * ts
			var lx := tx - field_x0
			var ly := ty - field_y0
			var key := Vector2i(lx, ly)

			if cross_map.has(key):
				if cross_map[key] == 0:
					green_verts = _add_rect.call(green_verts, x, z, ts, ts)
				else:
					pink_verts = _add_rect.call(pink_verts, x, z, ts, ts)
			else:
				black_verts = _add_rect.call(black_verts, x, z, ts, ts)

	# Y offsets
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts

	black_verts = _offset_y.call(black_verts, 0.0)
	green_verts = _offset_y.call(green_verts, 0.001)
	pink_verts = _offset_y.call(pink_verts, 0.001)

	# Build ArrayMesh
	var arr_mesh := ArrayMesh.new()

	if black_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = black_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(0, _create_neon_material(COLOR_BLACK))

	if green_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = green_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, _create_neon_material(COLOR_GREEN, true))

	if pink_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = pink_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, _create_neon_material(COLOR_HOT_PINK, true))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0.0, 0.0, 0.0)
	add_child(_body)

	print("[PixelCrossFloor] Built %dx%d grid (%d black, %d green, %d pink tris)" % [
		gw, gh,
		black_verts.size() / 3,
		green_verts.size() / 3,
		pink_verts.size() / 3,
	])
