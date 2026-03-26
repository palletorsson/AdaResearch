# polka_dot_field_floor.gd
# Procedural Pompeii mosaic floor — dark field with scattered small light tesserae.
# Common in Pompeii vestibules and corridors: a large dark rectangle with small
# light square dots arranged in a regular grid with slight organic jitter.
#
# @identity
#   essence: a floor that maps the Roman practice of scattering light stones on dark ground
#   desire: players look down and see the simplest possible pattern — dots on a field
#   critical_parameter: dot_spacing — tesserae per grid cell side
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that randomness constrained to a grid produces organic regularity
#   needs: [implemented] procedural mesh, border bands, dot field, grout
#   relationships: pompeii_mosaic_floor (sibling pattern), pattern_maker_station (web editor)
#   truth: the simplest pattern is still a pattern

extends Node3D
class_name PolkaDotFieldFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.0, 0.75)
@export var tiles_short: int = 8
@export var border_width: int = 2
@export var border_motif: int = BorderMotifs.Motif.MEANDER
@export var dot_spacing: int = 3           ## tesserae between dots (in sub-tile units)
@export var dot_size_fraction: float = 0.125  ## dot size relative to tile size (1/8)
@export var jitter_amount: float = 0.15    ## random offset fraction of dot spacing
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	border_width = int(config.get("border_width", border_width))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	dot_size_fraction = float(config.get("dot_size_fraction", dot_size_fraction))
	jitter_amount = float(config.get("jitter_amount", jitter_amount))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()

	# Grid dimensions
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_width * 2
	var ts := short_m / float(total_short)  # tile size in meters
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short  # grid width in tiles
	var gh: int = total_short if is_wide else total_long   # grid height in tiles

	var fw := gw * ts  # floor width in meters
	var fh := gh * ts  # floor height in meters

	# Field region (inside borders)
	var fx0 := border_width
	var fy0 := border_width
	var fx1 := gw - border_width
	var fy1 := gh - border_width

	# Grout absolute width
	var grout_w := ts * grout_width_fraction

	# Build vertex arrays for surfaces: dark_field, light_dots, border_dark, border_light, grout
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad (2 triangles) in XZ plane at y=0
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Border bands ──
	var terra_verts := PackedVector3Array()
	if border_width > 0:
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			0.0, 0.0,
			float(gw) * ts, float(gh) * ts,
			float(border_width) * ts, ts,
			border_motif, false
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]

	# ── 2. Dark field (solid background) ──
	# Fill entire field area with dark quads
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts
			dark_verts = _add_rect.call(dark_verts, x, z, ts, ts)

	# ── 3. Light dots scattered on the field ──
	# Place dots at regular intervals with slight random jitter
	# Dot spacing is in sub-tile units; we place dots across the full field
	var field_x0 := fx0 * ts
	var field_z0 := fy0 * ts
	var field_w := (fx1 - fx0) * ts
	var field_h := (fy1 - fy0) * ts

	var dot_size := ts * dot_size_fraction
	var spacing := ts / float(dot_spacing)  # distance between dot centers
	var half_dot := dot_size * 0.5

	# Number of dots across each dimension
	var dots_x := int(field_w / spacing)
	var dots_z := int(field_h / spacing)

	# Margin to center the dot grid within the field
	var margin_x := (field_w - dots_x * spacing) * 0.5
	var margin_z := (field_h - dots_z * spacing) * 0.5

	# Deterministic pseudo-random jitter using simple hash
	for dz in range(dots_z):
		for dx in range(dots_x):
			# Base position
			var cx := field_x0 + margin_x + (dx + 0.5) * spacing
			var cz := field_z0 + margin_z + (dz + 0.5) * spacing

			# Deterministic jitter based on grid position
			var hash_val := _hash_2d(dx, dz)
			var jx := (hash_val - 0.5) * 2.0 * jitter_amount * spacing
			var jz := (_hash_2d(dx + 97, dz + 53) - 0.5) * 2.0 * jitter_amount * spacing

			var px := cx + jx - half_dot
			var pz := cz + jz - half_dot

			# Ensure dot stays within field bounds
			px = clampf(px, field_x0 + half_dot, field_x0 + field_w - dot_size - half_dot)
			pz = clampf(pz, field_z0 + half_dot, field_z0 + field_h - dot_size - half_dot)

			# Add light dot quad (slightly above the dark field)
			light_verts.append(Vector3(px, 0.0005, pz))
			light_verts.append(Vector3(px + dot_size, 0.0005, pz))
			light_verts.append(Vector3(px + dot_size, 0.0005, pz + dot_size))
			light_verts.append(Vector3(px, 0.0005, pz))
			light_verts.append(Vector3(px + dot_size, 0.0005, pz + dot_size))
			light_verts.append(Vector3(px, 0.0005, pz + dot_size))

	# ── 4. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Horizontal lines
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		# Vertical lines
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	grout_verts = _offset_y.call(grout_verts, -0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(0, MosaicPalette.create_material(color_dark, wear_level))

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_light, wear_level))

	if terra_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = terra_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(MosaicPalette.TERRACOTTA, wear_level))

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)  # Center the floor
	add_child(_mi)

	# Add StaticBody3D with CollisionShape3D for floor collision
	var body := StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	body.add_child(col)
	body.position = Vector3(0, 0.005, 0)
	add_child(body)

	print("[PolkaDotFieldFloor] Built %dx%d grid, %d dots (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dots_x * dots_z,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])


## Deterministic pseudo-random hash for jitter (returns 0.0 to 1.0)
func _hash_2d(x: int, y: int) -> float:
	var n := x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7FFFFFFF) / float(0x7FFFFFFF)
