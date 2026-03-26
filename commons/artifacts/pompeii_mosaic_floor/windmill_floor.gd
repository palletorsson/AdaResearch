# windmill_floor.gd
# Procedural Pompeii windmill/pinwheel mosaic floor.
# Each unit: a small terracotta center square surrounded by 4 L-shaped blades
# (2 dark, 2 light opposite) creating a spinning windmill effect.
# Adjacent units rotate 90 degrees for continuous flow.
#
# @identity
#   essence: a floor whose geometry captures rotational energy frozen in stone
#   desire: players recognize the pinwheel as a tessellation distinct from truchet
#   critical_parameter: tiles_short — number of windmill units on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: understanding that 4-fold rotational symmetry generates visual motion
#   needs: [implemented] procedural mesh, border bands, windmill pinwheel
#   relationships: pattern_maker_station (web editor), mosaic_editor (composition)
#   truth: four L-shapes around a center square is one of the oldest tiling motifs

extends Node3D
class_name WindmillFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 6
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

	# Each windmill unit occupies a 3x3 sub-grid of tesserae:
	#   1 center square + 4 L-shaped blades filling the remaining 8 cells
	# So total tesserae on short axis = tiles_short * 3 + border*2
	var sub := 3  # sub-cells per windmill unit
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short * sub + border_each * 2
	var ts := short_m / float(total_short)  # tessera size in meters
	var tiles_long := int(round((long_m / ts - border_each * 2) / float(sub)))
	var total_long := tiles_long * sub + border_each * 2

	var gw: int = total_long if is_wide else total_short  # grid width in tesserae
	var gh: int = total_short if is_wide else total_long   # grid height in tesserae

	var fw := gw * ts  # floor width in meters
	var fh := gh * ts  # floor height in meters

	# Field region (inside borders), in tesserae
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	# Windmill unit counts in the field
	var units_x: int = (fx1 - fx0) / sub
	var units_y: int = (fy1 - fy0) / sub

	# Grout absolute width
	var grout_w := ts * grout_width_fraction

	# Vertex buffers
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
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

	# -- 1. Border bands --
	var inset: int = 0
	for i in border_widths.size():
		var bw_val: int = border_widths[i]
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			inset * ts, inset * ts,
			(gw - inset * 2) * ts, (gh - inset * 2) * ts,
			bw_val * ts, ts,
			border_motif, i % 2 == 1
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]
		inset += bw_val

	# -- 2. Windmill field --
	# Each windmill unit is 3x3 tesserae:
	#
	# Rotation 0 (even sum):        Rotation 1 (odd sum):
	#   D D L                          L D D
	#   D C L                          L C D
	#   L L L  (wrong)                 ...
	#
	# Actually: the windmill has a center square and 4 L-shapes.
	# In a 3x3 grid:
	#   [0,0] [1,0] [2,0]
	#   [0,1] [1,1] [2,1]
	#   [0,2] [1,2] [2,2]
	#
	# Center = [1,1] = terracotta
	# Blade A (top-left L): [0,0], [1,0], [0,1] = dark
	# Blade B (top-right L): [2,0], [2,1], [1,2]... no
	#
	# For a proper windmill with 4 blades rotating clockwise:
	# Rotation 0:
	#   [0,0]=D  [1,0]=D  [2,0]=L
	#   [0,1]=L  [1,1]=T  [2,1]=D
	#   [0,2]=L  [1,2]=L  [2,2]=D  (wrong - not L-shapes)
	#
	# Better approach: each blade is 2 cells forming an L with the center.
	# The 8 surrounding cells form 4 pairs (blades):
	#
	# Rotation 0 (clockwise pinwheel):
	#   Blade 0 (N+E): [1,0] + [2,0] = dark   (top edge + top-right)
	#   Blade 1 (E+S): [2,1] + [2,2] = light  (right edge + bottom-right)
	#   Blade 2 (S+W): [1,2] + [0,2] = dark   (bottom edge + bottom-left)
	#   Blade 3 (W+N): [0,1] + [0,0] = light  (left edge + top-left)
	#
	# This gives:
	#   L  D  D
	#   L  T  L
	#   D  D  L
	#
	# Rotation 1 (90 degrees):
	#   Blade 0 (E+S): [2,0] + [2,1] = dark
	#   Blade 1 (S+W): [1,2] + [0,2]... wait, let me just rotate the pattern:
	#
	# Rotated 90 CW:
	#   D  L  L
	#   D  T  D
	#   L  L  D
	#
	# This is just swapping dark/light from the original, which creates the
	# alternating spin effect.

	for uy in range(units_y):
		for ux in range(units_x):
			var ox := (fx0 + ux * sub) * ts
			var oz := (fy0 + uy * sub) * ts

			# Alternate rotation: even sum = rotation 0, odd = rotation 1
			var rotated := ((ux + uy) % 2) == 1

			# Center square (terracotta)
			terra_verts = _add_rect.call(terra_verts, ox + ts, oz + ts, ts, ts)

			# 8 surrounding cells in the 3x3 grid
			# Pattern for rotation 0:
			#   [0,0]=L  [1,0]=D  [2,0]=D
			#   [0,1]=L  [1,1]=T  [2,1]=L
			#   [0,2]=D  [1,2]=D  [2,2]=L
			#
			# Pattern for rotation 1 (swap D/L):
			#   [0,0]=D  [1,0]=L  [2,0]=L
			#   [0,1]=D  [1,1]=T  [2,1]=D
			#   [0,2]=L  [1,2]=L  [2,2]=D

			# Cell positions: [col, row] -> (ox + col*ts, oz + row*ts)
			# 0=light, 1=dark for rotation 0
			var pattern_r0 := [
				[0, 1, 1],  # row 0
				[0, -1, 0], # row 1 (-1 = center/skip)
				[1, 1, 0],  # row 2
			]

			for row in 3:
				for col in 3:
					var val: int = pattern_r0[row][col]
					if val == -1:
						continue  # center already drawn
					var is_dark: bool
					if rotated:
						is_dark = (val == 0)  # swap
					else:
						is_dark = (val == 1)

					var verts: PackedVector3Array = dark_verts if is_dark else light_verts
					verts = _add_rect.call(verts, ox + col * ts, oz + row * ts, ts, ts)
					if is_dark:
						dark_verts = verts
					else:
						light_verts = verts

	# -- 3. Grout lines --
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
	terra_verts = _offset_y.call(terra_verts, 0.002)
	grout_verts = _offset_y.call(grout_verts, -0.001)

	# -- Build ArrayMesh --
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

	# StaticBody3D for collision
	var body := StaticBody3D.new()
	#var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(fw, 0.01, fh)
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0, 0.0, 0)
	add_child(body)

	print("[WindmillFloor] Built %dx%d units (%d dark tris, %d light tris, %d terra tris, %d grout tris)" % [
		units_x, units_y,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])
