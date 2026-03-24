# basket_weave_floor.gd
# Procedural Pompeii mosaic floor — basket weave / opus spicatum pattern.
# Alternating horizontal and vertical pairs of 2:1 rectangular tiles
# in a checkerboard arrangement creating a woven textile appearance.
#
# @identity
#   essence: a floor encoding the Roman textile-to-stone translation
#   desire: players look down and see woven fabric frozen in tesserae
#   critical_parameter: tiles_short — number of weave cells on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that rotation alone generates pattern from uniformity
#   needs: [implemented] procedural mesh, border bands, basket weave field, grout
#   relationships: pompeii_mosaic_floor (sibling pattern), pattern_maker_station (web editor)
#   truth: a pair of rectangles rotated 90 degrees becomes a completely different surface

extends Node3D
class_name BasketWeaveFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.0, 0.75)
@export var tiles_short: int = 8
@export var border_widths: Array[int] = [2, 1, 1]
@export var border_motif: int = BorderMotifs.Motif.SAWTOOTH
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
@export_range(0.0, 1.0) var wear_level: float = 0.3

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
	var bw = config.get("border_widths", null)
	if bw is Array:
		border_widths.clear()
		for v in bw:
			border_widths.append(int(v))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
	if _body:
		_body.queue_free()

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

	# Build vertex arrays for 3 surfaces: dark, light, grout
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

	# ── 1. Border bands (dark(2), light(1), dark(1)) ──
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

	# ── 2. Basket weave field ──
	# Each cell is ts x ts. Inside each cell we draw a pair of 2:1 rectangles.
	# Checkerboard determines orientation:
	#   even cells (fx_rel + fy_rel even) → horizontal pair (two rects stacked vertically)
	#   odd cells → vertical pair (two rects side by side)
	# Even cells are dark, odd cells are light (alternating weave).
	var inset_frac := grout_w * 0.5  # inset each rect by half-grout for spacing

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var x := tx * ts
			var z := ty * ts

			var fx_rel := tx - fx0
			var fy_rel := ty - fy0
			var is_even := ((fx_rel + fy_rel) % 2) == 0

			# Pick which vert array to draw into
			var pair_verts: PackedVector3Array = dark_verts if is_even else light_verts

			var g := inset_frac  # grout gap

			if is_even:
				# Horizontal pair: two rectangles stacked (each ts wide, ts/2 tall)
				# Top rectangle
				pair_verts = _add_rect.call(pair_verts,
					x + g, z + g,
					ts - g * 2.0, ts * 0.5 - g * 1.5)
				# Bottom rectangle
				pair_verts = _add_rect.call(pair_verts,
					x + g, z + ts * 0.5 + g * 0.5,
					ts - g * 2.0, ts * 0.5 - g * 1.5)
			else:
				# Vertical pair: two rectangles side by side (each ts/2 wide, ts tall)
				# Left rectangle
				pair_verts = _add_rect.call(pair_verts,
					x + g, z + g,
					ts * 0.5 - g * 1.5, ts - g * 2.0)
				# Right rectangle
				pair_verts = _add_rect.call(pair_verts,
					x + ts * 0.5 + g * 0.5, z + g,
					ts * 0.5 - g * 1.5, ts - g * 2.0)

			# Write back
			if is_even:
				dark_verts = pair_verts
			else:
				light_verts = pair_verts

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Outer grid lines: horizontal
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		# Outer grid lines: vertical
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

		# Interior grout: divider inside each field cell
		for ty in range(fy0, fy1):
			for tx in range(fx0, fx1):
				var x := tx * ts
				var z := ty * ts

				var fx_rel := tx - fx0
				var fy_rel := ty - fy0
				var is_even := ((fx_rel + fy_rel) % 2) == 0

				if is_even:
					# Horizontal pair: horizontal divider at cell midpoint
					grout_verts = _add_rect.call(grout_verts,
						x, z + ts * 0.5 - half,
						ts, grout_w)
				else:
					# Vertical pair: vertical divider at cell midpoint
					grout_verts = _add_rect.call(grout_verts,
						x + ts * 0.5 - half, z,
						grout_w, ts)

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
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)  # Center at origin, y=0.005
	add_child(_mi)

	# ── StaticBody3D + CollisionShape3D ──
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0.0, 0.0, 0.0)  # Centered since mesh is centered
	add_child(_body)

	print("[BasketWeaveFloor] Built %dx%d grid (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
