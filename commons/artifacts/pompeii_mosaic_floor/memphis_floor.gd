# memphis_floor.gd
# Procedural pixel art floor — Memphis Group / Sottsass inspired pattern.
# Pastel pink background with scattered black triangles, yellow dots, teal zigzags.
#
# @identity
#   essence: a floor encoding the exuberant geometry of 1980s Memphis design
#   desire: players look down and see scattered postmodern shapes on a pastel field
#   critical_parameter: tiles_short — pixel resolution on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that pseudo-random placement of shape templates creates visual energy
#   needs: [implemented] procedural mesh, shape templates, hash-based placement
#   relationships: glitch_grid_floor (scattered aesthetic cousin), neon_chevron_floor (bold color sibling)
#   truth: Memphis design rejected minimalism — decoration IS the structure

extends Node3D
class_name MemphisFloor

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 36
@export var border_width: int = 2

var _mi: MeshInstance3D
#var _body: StaticBody3D

const COLOR_PASTEL_PINK := Color(1.0, 0.714, 0.757, 1.0)  # #FFB6C1
const COLOR_BLACK := Color(0.1, 0.1, 0.1, 1.0)
const COLOR_YELLOW := Color(1.0, 0.843, 0.0, 1.0)          # #FFD700
const COLOR_TEAL := Color(0.0, 0.502, 0.502, 1.0)          # #008080
const COLOR_WHITE := Color(1.0, 1.0, 1.0, 1.0)

# Triangle template: 3x3 pixels (top-left triangle)
const TRI_TEMPLATE: Array = [
	[1, 1, 1],
	[1, 1, 0],
	[1, 0, 0],
]

# Dot template: 3x3 circle
const DOT_TEMPLATE: Array = [
	[0, 1, 0],
	[1, 1, 1],
	[0, 1, 0],
]

# Zigzag template: 3x5 zigzag line
const ZIG_TEMPLATE: Array = [
	[1, 0, 0, 1, 0],
	[0, 1, 0, 0, 1],
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


func _hash2d(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + 1274126177) & 0x7FFFFFFF
	h = ((h >> 13) ^ h) * 1274126177
	h = h & 0x7FFFFFFF
	return float(h) / float(0x7FFFFFFF)


func _build() -> void:
	if _mi:
		_mi.queue_free()
	#if _body:
		#_body.queue_free()

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

	# 5 surfaces: pink bg, black (triangles), yellow (dots), teal (zigzags), white (border accent)
	var pink_verts := PackedVector3Array()
	var black_verts := PackedVector3Array()
	var yellow_verts := PackedVector3Array()
	var teal_verts := PackedVector3Array()
	var white_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Overlay grid to track which field cells have shapes
	var field_w := field_x1 - field_x0
	var field_h := field_y1 - field_y0
	var shape_map := {}  # (lx, ly) -> color_index (0=black, 1=yellow, 2=teal)

	# Place shapes using hash-based pseudo-random positions
	# Divide field into 8x8 sectors, place one shape per sector
	var sector_w: int = 8
	var sector_h: int = 8
	var sectors_x := field_w / sector_w
	var sectors_y := field_h / sector_h

	for sy in range(0, sectors_y):
		for sx in range(0, sectors_x):
			var h := _hash2d(sx + 42, sy + 73)
			# Shape type: 0=triangle, 1=dot, 2=zigzag
			var shape_type := int(h * 3.0) % 3

			# Position within sector
			var h2 := _hash2d(sx + 200, sy + 300)
			var h3 := _hash2d(sx + 500, sy + 700)
			var ox := int(h2 * float(sector_w - 4))
			var oy := int(h3 * float(sector_h - 4))

			var base_x := sx * sector_w + ox
			var base_y := sy * sector_h + oy

			var template: Array
			var color_idx: int
			if shape_type == 0:
				template = TRI_TEMPLATE
				color_idx = 0  # black
			elif shape_type == 1:
				template = DOT_TEMPLATE
				color_idx = 1  # yellow
			else:
				template = ZIG_TEMPLATE
				color_idx = 2  # teal

			for row_i in template.size():
				var row: Array = template[row_i]
				for col_i in row.size():
					if row[col_i] == 1:
						var lx := base_x + col_i
						var ly := base_y + row_i
						if lx >= 0 and lx < field_w and ly >= 0 and ly < field_h:
							shape_map[Vector2i(lx, ly)] = color_idx

	# Border
	for ty in range(0, gh):
		for tx in range(0, gw):
			var in_field := tx >= field_x0 and tx < field_x1 and ty >= field_y0 and ty < field_y1
			if not in_field:
				var x := tx * ts
				var z := ty * ts
				var edge := tx == 0 or tx == gw - 1 or ty == 0 or ty == gh - 1
				if edge:
					black_verts = _add_rect.call(black_verts, x, z, ts, ts)
				else:
					var dist := mini(mini(tx, gw - 1 - tx), mini(ty, gh - 1 - ty))
					if dist % 2 == 1:
						yellow_verts = _add_rect.call(yellow_verts, x, z, ts, ts)
					else:
						pink_verts = _add_rect.call(pink_verts, x, z, ts, ts)

	# Field cells
	for ty in range(field_y0, field_y1):
		for tx in range(field_x0, field_x1):
			var x := tx * ts
			var z := ty * ts
			var lx := tx - field_x0
			var ly := ty - field_y0
			var key := Vector2i(lx, ly)

			if shape_map.has(key):
				var ci: int = shape_map[key]
				if ci == 0:
					black_verts = _add_rect.call(black_verts, x, z, ts, ts)
				elif ci == 1:
					yellow_verts = _add_rect.call(yellow_verts, x, z, ts, ts)
				else:
					teal_verts = _add_rect.call(teal_verts, x, z, ts, ts)
			else:
				pink_verts = _add_rect.call(pink_verts, x, z, ts, ts)

	# Y offsets
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts

	pink_verts = _offset_y.call(pink_verts, 0.0)
	black_verts = _offset_y.call(black_verts, 0.001)
	yellow_verts = _offset_y.call(yellow_verts, 0.001)
	teal_verts = _offset_y.call(teal_verts, 0.001)

	# Build ArrayMesh
	var arr_mesh := ArrayMesh.new()

	var surfaces: Array = [
		[pink_verts, COLOR_PASTEL_PINK, false],
		[black_verts, COLOR_BLACK, false],
		[yellow_verts, COLOR_YELLOW, true],
		[teal_verts, COLOR_TEAL, true],
	]

	for surf in surfaces:
		var verts: PackedVector3Array = surf[0]
		if verts.size() > 0:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, _create_neon_material(surf[1], surf[2]))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	#_body.position = Vector3(0.0, 0.0, 0.0)
	#add_child(_body)

	print("[MemphisFloor] Built %dx%d grid" % [gw, gh])
