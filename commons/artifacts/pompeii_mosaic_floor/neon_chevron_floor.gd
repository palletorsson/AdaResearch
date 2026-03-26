# neon_chevron_floor.gd
# Procedural pixel art floor — bold V-shaped chevron stripes radiating from center.
# Cycling neon colors: hot pink, electric blue, yellow, purple on black.
#
# @identity
#   essence: a floor encoding directional energy through repeating V-shapes
#   desire: players look down and see bold chevrons pulsing outward from the center
#   critical_parameter: tiles_short — pixel resolution on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that a V-shape is just abs(x - center) mapped to color bands
#   needs: [implemented] procedural mesh, chevron field, color cycling
#   relationships: pixel_invader_floor (aesthetic sibling), rainbow_checker_floor (color cousin)
#   truth: the chevron is a distance function visualized — math made visible as pattern

extends Node3D
class_name NeonChevronFloor

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 32
@export var border_width: int = 1

var _mi: MeshInstance3D
#var _body: StaticBody3D

const COLOR_HOT_PINK := Color(1.0, 0.078, 0.576, 1.0)    # #FF1493
const COLOR_ELEC_BLUE := Color(0.0, 0.749, 1.0, 1.0)     # #00BFFF
const COLOR_YELLOW := Color(1.0, 0.843, 0.0, 1.0)         # #FFD700
const COLOR_PURPLE := Color(0.545, 0.0, 1.0, 1.0)         # #8B00FF
const COLOR_BLACK := Color(0.04, 0.04, 0.04, 1.0)         # #0A0A0A

const CHEVRON_COLORS: Array = []  # populated in _build


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

	var colors: Array = [COLOR_HOT_PINK, COLOR_ELEC_BLUE, COLOR_YELLOW, COLOR_PURPLE]

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

	# We need 5 surfaces: 4 neon colors + black
	var color_verts: Array = []
	for i in 5:
		color_verts.append(PackedVector3Array())

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	var center_x := (field_x0 + field_x1) * 0.5
	var center_y := (field_y0 + field_y1) * 0.5

	# Chevron band width in cells
	var band_width: int = 3

	for ty in range(0, gh):
		for tx in range(0, gw):
			var x := tx * ts
			var z := ty * ts
			var in_field := tx >= field_x0 and tx < field_x1 and ty >= field_y0 and ty < field_y1

			if not in_field:
				# Border: cycling color bands
				var dist := mini(mini(tx, gw - 1 - tx), mini(ty, gh - 1 - ty))
				var ci := dist % 4
				color_verts[ci] = _add_rect.call(color_verts[ci], x, z, ts, ts)
				continue

			# Chevron: V-shape based on distance from center row + abs(x offset)
			var dx := absf(float(tx) - center_x)
			var dy := float(ty) - float(field_y0)

			# Chevron distance: row offset + horizontal spread creates V
			var chevron_dist := int(dy + dx) / band_width

			# Alternate between colored band and black gap
			if chevron_dist % 2 == 0:
				var ci := (chevron_dist / 2) % 4
				color_verts[ci] = _add_rect.call(color_verts[ci], x, z, ts, ts)
			else:
				color_verts[4] = _add_rect.call(color_verts[4], x, z, ts, ts)

	# Y offsets
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts

	color_verts[4] = _offset_y.call(color_verts[4], 0.0)  # black base
	for i in 4:
		color_verts[i] = _offset_y.call(color_verts[i], 0.001)

	# Build ArrayMesh
	var arr_mesh := ArrayMesh.new()
	var all_colors: Array = [colors[0], colors[1], colors[2], colors[3], COLOR_BLACK]
	var all_emission: Array = [true, true, true, true, false]

	for i in 5:
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

	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	_body.position = Vector3(0.0, 0.0, 0.0)
	#add_child(_body)

	var total_tris: int = 0
	for i in 5:
		total_tris += color_verts[i].size() / 3
	print("[NeonChevronFloor] Built %dx%d grid (%d total tris)" % [gw, gh, total_tris])
