# pompeii_mosaic_floor.gd
# Procedural Pompeii mosaic floor — single ImmediateMesh, no shader bridge.
# Builds border quads + truchet triangles + grout lines in one mesh.
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

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 10
@export var border_widths: Array[int] = [2, 1, 2]
@export var border_motif: int = BorderMotifs.Motif.SAWTOOTH
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
	wear_level = float(config.get("wear_level", wear_level))
	var bw = config.get("border_widths", null)
	if bw is Array:
		border_widths.clear()
		for v in bw:
			border_widths.append(int(v))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()

	# Grid dimensions
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_each * 2
	var ts := short_m / float(total_short)  # tile size in meters
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short  # grid width in tiles
	var gh: int = total_short if is_wide else total_long   # grid height in tiles

	var fw := gw * ts  # floor width in meters
	var fh := gh * ts  # floor height in meters

	# Field region (inside borders)
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	# Grout absolute width
	var grout_w := ts * grout_width_fraction

	# Build everything into arrays, then create ArrayMesh
	# Using ArrayMesh with 3 surfaces: dark, light, grout
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad (2 triangles) in XZ plane at y=0
	# x, z are world positions, w/h are sizes
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
	var inset: int = 0
	for i in border_widths.size():
		var bw: int = border_widths[i]
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			inset * ts, inset * ts,
			(gw - inset * 2) * ts, (gh - inset * 2) * ts,
			bw * ts, ts,
			border_motif, i % 2 == 1
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]
		inset += bw

	# ── 2. Truchet field ──
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts

			var even_diag := ((tx + ty) % 2) == 0
			var flip := ((ty - fy0) % 2) == 1

			# Which triangle is dark vs light
			# even_diag + no flip → dark = upper-left (TL-BR split)
			# even_diag + flip   → dark = lower-right
			var dark_ul := even_diag == (not flip)

			if even_diag:
				# TL-BR diagonal ╲
				if dark_ul:
					# Dark: top-left triangle
					dark_verts.append(Vector3(x, 0, z))
					dark_verts.append(Vector3(x + ts, 0, z))
					dark_verts.append(Vector3(x, 0, z + ts))
					# Light: bottom-right triangle
					light_verts.append(Vector3(x + ts, 0, z))
					light_verts.append(Vector3(x + ts, 0, z + ts))
					light_verts.append(Vector3(x, 0, z + ts))
				else:
					light_verts.append(Vector3(x, 0, z))
					light_verts.append(Vector3(x + ts, 0, z))
					light_verts.append(Vector3(x, 0, z + ts))
					dark_verts.append(Vector3(x + ts, 0, z))
					dark_verts.append(Vector3(x + ts, 0, z + ts))
					dark_verts.append(Vector3(x, 0, z + ts))
			else:
				# TR-BL diagonal ╱
				if dark_ul:
					# Dark: top-right triangle
					dark_verts.append(Vector3(x, 0, z))
					dark_verts.append(Vector3(x + ts, 0, z))
					dark_verts.append(Vector3(x + ts, 0, z + ts))
					# Light: bottom-left triangle
					light_verts.append(Vector3(x, 0, z))
					light_verts.append(Vector3(x + ts, 0, z + ts))
					light_verts.append(Vector3(x, 0, z + ts))
				else:
					light_verts.append(Vector3(x, 0, z))
					light_verts.append(Vector3(x + ts, 0, z))
					light_verts.append(Vector3(x + ts, 0, z + ts))
					dark_verts.append(Vector3(x, 0, z))
					dark_verts.append(Vector3(x + ts, 0, z + ts))
					dark_verts.append(Vector3(x, 0, z + ts))

	# ── 3. Grout lines ──
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
		# Diagonal grout in field
		var diag_w := grout_w * 0.7
		var dh := diag_w * 0.7071  # perpendicular offset
		for ty in range(fy0, fy1):
			for tx in range(fx0, fx1):
				var x := tx * ts
				var z := ty * ts
				var even_diag := ((tx + ty) % 2) == 0
				if even_diag:
					# TL-BR: line from (x, z+ts) to (x+ts, z)
					grout_verts.append(Vector3(x - dh, 0, z + ts + dh))
					grout_verts.append(Vector3(x + ts + dh, 0, z - dh))
					grout_verts.append(Vector3(x + ts - dh, 0, z + dh))
					grout_verts.append(Vector3(x - dh, 0, z + ts + dh))
					grout_verts.append(Vector3(x + ts - dh, 0, z + dh))
					grout_verts.append(Vector3(x + dh, 0, z + ts - dh))
				else:
					# TR-BL: line from (x, z) to (x+ts, z+ts)
					grout_verts.append(Vector3(x - dh, 0, z - dh))
					grout_verts.append(Vector3(x + ts + dh, 0, z + ts + dh))
					grout_verts.append(Vector3(x + ts - dh, 0, z + ts - dh))
					grout_verts.append(Vector3(x - dh, 0, z - dh))
					grout_verts.append(Vector3(x + ts - dh, 0, z + ts - dh))
					grout_verts.append(Vector3(x + dh, 0, z + dh))


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

	print("[PompeiiMosaicFloor] Built %dx%d grid (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
