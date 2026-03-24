# guilloche_border_floor.gd
# Procedural Pompeii floor with prominent guilloche (braided rope) border
# surrounding a simple grid field with a central pictorial panel inset.
# Based on Pompeii photo reference 212022.
#
# @identity
#   essence: a floor whose braided border encodes the Roman love of infinite knots
#   desire: players trace the interlocking circles and see topology before topology
#   critical_parameter: tiles_short — tesserae count on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the realization that a braid is two sine waves phase-shifted
#   needs: [implemented] procedural mesh, guilloche border, grid field, panel inset
#   relationships: pompeii_mosaic_floor (sibling), border_motifs (library)
#   truth: two intertwined paths that never cross yet never separate

extends Node3D
class_name GuillocheBorderFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 24
@export var guilloche_band_rows: int = 4
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terra: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.05
@export_range(0.0, 1.0) var wear_level: float = 0.3
@export var panel_ratio: Vector2 = Vector2(0.3, 0.25)  # fraction of field for central panel

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	tiles_short = int(config.get("tiles_short", tiles_short))
	wear_level = float(config.get("wear_level", wear_level))
	guilloche_band_rows = int(config.get("guilloche_band_rows", guilloche_band_rows))
	var pr = config.get("panel_ratio", null)
	if pr is Array and pr.size() >= 2:
		panel_ratio = Vector2(float(pr[0]), float(pr[1]))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	# ── Grid dimensions ──
	# Border structure (outside→in): dark_outer(1) + guilloche(4) + dark_inner(1) = 6 cells each side
	var outer_band: int = 1
	var inner_band: int = 1
	var border_each: int = outer_band + guilloche_band_rows + inner_band

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short
	var ts := short_m / float(total_short)  # tile size in meters
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long

	var fw := gw * ts
	var fh := gh * ts

	# Field region (inside all borders)
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	var field_w := fx1 - fx0
	var field_h := fy1 - fy0

	var grout_w := ts * grout_width_fraction

	# Vertex buffers
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Outer dark band (1-cell-wide solid frame) ──
	var outer_result := BorderMotifs.draw_border_frame(
		dark_verts, light_verts, terra_verts,
		0.0, 0.0,
		gw * ts, gh * ts,
		outer_band * ts, ts,
		BorderMotifs.Motif.SOLID, false
	)
	dark_verts = outer_result["dark"]
	light_verts = outer_result["light"]
	terra_verts = outer_result["terra"]

	# ── 2. Guilloche band (using BorderMotifs GUILLOCHE) ──
	var guil_result := BorderMotifs.draw_border_frame(
		dark_verts, light_verts, terra_verts,
		outer_band * ts, outer_band * ts,
		(gw - outer_band * 2) * ts, (gh - outer_band * 2) * ts,
		guilloche_band_rows * ts, ts,
		BorderMotifs.Motif.GUILLOCHE, false
	)
	dark_verts = guil_result["dark"]
	light_verts = guil_result["light"]
	terra_verts = guil_result["terra"]

	# ── 3. Inner dark band (1-cell-wide solid frame) ──
	var inner_offset := outer_band + guilloche_band_rows
	var inner_result := BorderMotifs.draw_border_frame(
		dark_verts, light_verts, terra_verts,
		inner_offset * ts, inner_offset * ts,
		(gw - inner_offset * 2) * ts, (gh - inner_offset * 2) * ts,
		inner_band * ts, ts,
		BorderMotifs.Motif.SOLID, false
	)
	dark_verts = inner_result["dark"]
	light_verts = inner_result["light"]
	terra_verts = inner_result["terra"]

	# ── 4. Grid field (simple square tiles, checkerboard) ──
	# Central panel dimensions in tile coords
	var panel_tw := int(round(field_w * panel_ratio.x))
	var panel_th := int(round(field_h * panel_ratio.y))
	if panel_tw < 2:
		panel_tw = 2
	if panel_th < 2:
		panel_th = 2
	# Center the panel in the field
	var panel_x0 := fx0 + int((field_w - panel_tw) / 2)
	var panel_y0 := fy0 + int((field_h - panel_th) / 2)
	var panel_x1 := panel_x0 + panel_tw
	var panel_y1 := panel_y0 + panel_th

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts

			# Check if inside central panel
			if tx >= panel_x0 and tx < panel_x1 and ty >= panel_y0 and ty < panel_y1:
				# Central panel — terracotta fill
				terra_verts = _add_rect.call(terra_verts, x, z, ts, ts)
			else:
				# Simple checkerboard grid
				var is_dark_tile := ((tx + ty) % 2) == 0
				if is_dark_tile:
					light_verts = _add_rect.call(light_verts, x, z, ts, ts)
				else:
					dark_verts = _add_rect.call(dark_verts, x, z, ts, ts)

	# ── 5. Panel inner border (1-pixel dark outline inside panel) ──
	# Top and bottom edges of panel
	for tx in range(panel_x0, panel_x1):
		dark_verts = _add_rect.call(dark_verts, tx * ts, panel_y0 * ts, ts, ts * 0.15)
		dark_verts = _add_rect.call(dark_verts, tx * ts, (panel_y1 - 1) * ts + ts * 0.85, ts, ts * 0.15)
	# Left and right edges
	for ty in range(panel_y0, panel_y1):
		dark_verts = _add_rect.call(dark_verts, panel_x0 * ts, ty * ts, ts * 0.15, ts)
		dark_verts = _add_rect.call(dark_verts, (panel_x1 - 1) * ts + ts * 0.85, ty * ts, ts * 0.15, ts)

	# ── 6. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Horizontal
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		# Vertical
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

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
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_terra, wear_level))

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	# ── StaticBody3D + CollisionShape3D ──
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0.0, 0.0, 0.0)
	add_child(_body)

	print("[GuillocheBorderFloor] Built %dx%d grid, border=%d cells/side, panel=%dx%d" % [
		gw, gh, border_each, panel_tw, panel_th
	])
