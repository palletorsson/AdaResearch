# glitch_grid_floor.gd
# Procedural pixel art floor — digital noise / glitch aesthetic.
# Mostly black grid with ~15-20% of cells lit in bright neon colors.
# Deterministic hash ensures reproducible "random" pattern.
#
# @identity
#   essence: a floor encoding the visual language of digital corruption
#   desire: players look down and see scattered bright pixels like a glitched screen
#   critical_parameter: tiles_short — pixel resolution on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that a hash function deterministically maps coordinates to noise
#   needs: [implemented] procedural mesh, hash-based coloring, neon palette
#   relationships: pixel_invader_floor (aesthetic sibling), memphis_floor (scattered shapes cousin)
#   truth: a deterministic hash applied to a grid is indistinguishable from randomness

extends Node3D
class_name GlitchGridFloor

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 40
@export var border_width: int = 1
@export var glitch_density: float = 0.18  # ~18% of cells colored

var _mi: MeshInstance3D
var _body: StaticBody3D

const COLOR_BLACK := Color(0.04, 0.04, 0.04, 1.0)     # #0A0A0A
const COLOR_HOT_PINK := Color(1.0, 0.078, 0.576, 1.0)  # #FF1493
const COLOR_CYAN := Color(0.0, 1.0, 1.0, 1.0)          # #00FFFF
const COLOR_LIME := Color(0.0, 1.0, 0.0, 1.0)          # #00FF00
const COLOR_RED := Color(1.0, 0.0, 0.0, 1.0)           # #FF0000
const COLOR_WHITE := Color(1.0, 1.0, 1.0, 1.0)         # #FFFFFF


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	glitch_density = float(config.get("glitch_density", glitch_density))
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


# Simple deterministic hash for (x, y) -> 0..1
func _hash2d(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + 1274126177) & 0x7FFFFFFF
	h = ((h >> 13) ^ h) * 1274126177
	h = h & 0x7FFFFFFF
	return float(h) / float(0x7FFFFFFF)


func _build() -> void:
	if _mi:
		_mi.queue_free()
	if _body:
		_body.queue_free()

	var glitch_colors: Array = [COLOR_HOT_PINK, COLOR_CYAN, COLOR_LIME, COLOR_RED, COLOR_WHITE]

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

	# 6 surfaces: 5 neon colors + black
	var color_verts: Array = []
	for i in 6:
		color_verts.append(PackedVector3Array())

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	for ty in range(0, gh):
		for tx in range(0, gw):
			var x := tx * ts
			var z := ty * ts

			var in_border := tx < border_width or tx >= gw - border_width or ty < border_width or ty >= gh - border_width
			if in_border:
				# Border: thin neon line
				var edge := tx == 0 or tx == gw - 1 or ty == 0 or ty == gh - 1
				if edge:
					color_verts[1] = _add_rect.call(color_verts[1], x, z, ts, ts)  # cyan border
				else:
					color_verts[5] = _add_rect.call(color_verts[5], x, z, ts, ts)  # black
				continue

			# Hash determines if cell is glitched
			var h := _hash2d(tx, ty)
			if h < glitch_density:
				# Pick color based on second hash
				var h2 := _hash2d(tx + 1000, ty + 1000)
				var ci := int(h2 * 5.0) % 5
				color_verts[ci] = _add_rect.call(color_verts[ci], x, z, ts, ts)
			else:
				color_verts[5] = _add_rect.call(color_verts[5], x, z, ts, ts)

	# Y offsets
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts

	color_verts[5] = _offset_y.call(color_verts[5], 0.0)  # black base
	for i in 5:
		color_verts[i] = _offset_y.call(color_verts[i], 0.001)

	# Build ArrayMesh
	var arr_mesh := ArrayMesh.new()
	var all_colors: Array = [COLOR_HOT_PINK, COLOR_CYAN, COLOR_LIME, COLOR_RED, COLOR_WHITE, COLOR_BLACK]
	var all_emission: Array = [true, true, true, true, false, false]

	for i in 6:
		if color_verts[i].size() > 0:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = color_verts[i]
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, _create_neon_material(all_colors[i], all_emission[i]))

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

	var total_tris: int = 0
	for i in 6:
		total_tris += color_verts[i].size() / 3
	print("[GlitchGridFloor] Built %dx%d grid (%d total tris)" % [gw, gh, total_tris])
