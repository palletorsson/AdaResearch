# pixel_invader_floor.gd
# Procedural pixel art floor — space invader sprites tiled on black field.
# Builds ArrayMesh with neon green pixel characters on a dark background.
#
# @identity
#   essence: a floor that carries the geometry of early arcade pixel art
#   desire: players look down and see 8-bit invader sprites marching across the ground
#   critical_parameter: tiles_short — pixel resolution on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that bitmap sprites are just boolean arrays rendered to grids
#   needs: [implemented] procedural mesh, invader bitmap, border bands
#   relationships: pompeii_mosaic_floor (structural sibling), glitch_grid_floor (aesthetic cousin)
#   truth: a 1-bit sprite is a small 2D array — the same data structure that tiles a Roman floor

extends Node3D
class_name PixelInvaderFloor

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 32
@export var border_width: int = 2

var _mi: MeshInstance3D
#var _body: StaticBody3D

# Space Invader bitmap: 11 wide x 8 tall (1 = green, 0 = black)
const INVADER: Array = [
	[0,0,1,0,0,0,0,0,1,0,0],
	[0,0,0,1,0,0,0,1,0,0,0],
	[0,0,1,1,1,1,1,1,1,0,0],
	[0,1,1,0,1,1,1,0,1,1,0],
	[1,1,1,1,1,1,1,1,1,1,1],
	[1,0,1,1,1,1,1,1,1,0,1],
	[1,0,1,0,0,0,0,0,1,0,1],
	[0,0,0,1,1,0,1,1,0,0,0],
]

const COLOR_GREEN := Color(0.0, 1.0, 0.255, 1.0)   # #00FF41
const COLOR_BLACK := Color(0.04, 0.04, 0.04, 1.0)   # #0A0A0A


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

	var green_verts := PackedVector3Array()
	var black_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Border: alternating green/black bands
	for ty in range(0, gh):
		for tx in range(0, gw):
			var in_field := tx >= field_x0 and tx < field_x1 and ty >= field_y0 and ty < field_y1
			if in_field:
				continue
			var x := tx * ts
			var z := ty * ts
			# Determine border band
			var dist := mini(mini(tx, gw - 1 - tx), mini(ty, gh - 1 - ty))
			if dist % 2 == 0:
				green_verts = _add_rect.call(green_verts, x, z, ts, ts)
			else:
				black_verts = _add_rect.call(black_verts, x, z, ts, ts)

	# Field: tile invaders across the interior
	var inv_w: int = 11
	var inv_h: int = 8
	var spacing_x: int = inv_w + 2  # 2 pixel gap
	var spacing_y: int = inv_h + 2

	var field_w := field_x1 - field_x0
	var field_h := field_y1 - field_y0

	for ty in range(field_y0, field_y1):
		for tx in range(field_x0, field_x1):
			var lx := tx - field_x0  # local field coords
			var ly := ty - field_y0

			var inv_lx := lx % spacing_x  # position within invader tile
			var inv_ly := ly % spacing_y

			var x := tx * ts
			var z := ty * ts

			if inv_lx < inv_w and inv_ly < inv_h:
				var row: Array = INVADER[inv_ly]
				if row[inv_lx] == 1:
					green_verts = _add_rect.call(green_verts, x, z, ts, ts)
				else:
					black_verts = _add_rect.call(black_verts, x, z, ts, ts)
			else:
				black_verts = _add_rect.call(black_verts, x, z, ts, ts)

	# Y offsets to prevent z-fighting
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	black_verts = _offset_y.call(black_verts, 0.0)
	green_verts = _offset_y.call(green_verts, 0.001)

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
	_body.position = Vector3(0.0, 0.0, 0.0)
	#add_child(_body)

	print("[PixelInvaderFloor] Built %dx%d grid (%d black tris, %d green tris)" % [
		gw, gh,
		black_verts.size() / 3,
		green_verts.size() / 3,
	])
