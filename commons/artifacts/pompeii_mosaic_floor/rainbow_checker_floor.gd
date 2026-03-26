# rainbow_checker_floor.gd
# Procedural pixel art floor — rainbow checkerboard.
# Each row pair uses a different color from the spectrum paired with black.
# Red, orange, yellow, green, blue, purple — then repeat.
#
# @identity
#   essence: a floor encoding the full visible spectrum as a discrete checkerboard
#   desire: players look down and see bold rainbow rows of alternating color and black
#   critical_parameter: tiles_short — pixel resolution on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that modular arithmetic on row index maps to a color cycle
#   needs: [implemented] procedural mesh, rainbow palette, checkerboard logic
#   relationships: neon_chevron_floor (color cycling sibling), pixel_cross_floor (bold pattern cousin)
#   truth: a checkerboard is the simplest 2-coloring of a grid — rainbow makes it six

extends Node3D
class_name RainbowCheckerFloor

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 30
@export var border_width: int = 1

var _mi: MeshInstance3D
#var _body: StaticBody3D

const COLOR_RED := Color(1.0, 0.0, 0.0, 1.0)
const COLOR_ORANGE := Color(1.0, 0.5, 0.0, 1.0)
const COLOR_YELLOW := Color(1.0, 0.843, 0.0, 1.0)
const COLOR_GREEN := Color(0.0, 0.8, 0.0, 1.0)
const COLOR_BLUE := Color(0.0, 0.4, 1.0, 1.0)
const COLOR_PURPLE := Color(0.545, 0.0, 1.0, 1.0)
const COLOR_BLACK := Color(0.04, 0.04, 0.04, 1.0)

const RAINBOW: Array = []  # populated in _build


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

	var rainbow: Array = [COLOR_RED, COLOR_ORANGE, COLOR_YELLOW, COLOR_GREEN, COLOR_BLUE, COLOR_PURPLE]

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

	# 7 surfaces: 6 rainbow colors + black
	var color_verts: Array = []
	for i in 7:
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

			var in_field := tx >= field_x0 and tx < field_x1 and ty >= field_y0 and ty < field_y1

			if not in_field:
				# Border: rainbow gradient
				var ci := ty % 6
				color_verts[ci] = _add_rect.call(color_verts[ci], x, z, ts, ts)
				continue

			# Checkerboard: row determines color, alternating with black
			var row_in_field := ty - field_y0
			var ci := row_in_field % 6  # which rainbow color
			var is_checker := (tx + ty) % 2 == 0

			if is_checker:
				color_verts[ci] = _add_rect.call(color_verts[ci], x, z, ts, ts)
			else:
				color_verts[6] = _add_rect.call(color_verts[6], x, z, ts, ts)

	# Y offsets
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts

	color_verts[6] = _offset_y.call(color_verts[6], 0.0)
	for i in 6:
		color_verts[i] = _offset_y.call(color_verts[i], 0.001)

	# Build ArrayMesh
	var arr_mesh := ArrayMesh.new()
	var all_colors: Array = []
	for c in rainbow:
		all_colors.append(c)
	all_colors.append(COLOR_BLACK)

	for i in 7:
		if color_verts[i].size() > 0:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = color_verts[i]
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var emit := i < 6
			arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, _create_neon_material(all_colors[i], emit))

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

	var total_tris: int = 0
	for i in 7:
		total_tris += color_verts[i].size() / 3
	print("[RainbowCheckerFloor] Built %dx%d grid (%d total tris)" % [gw, gh, total_tris])
