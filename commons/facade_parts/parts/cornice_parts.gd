class_name CorniceParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade cornice and band parts — dentil, cyma recta, string course, fascia, modillion,
## cornice shelf, dentil band, rect window band.
## Cell origin (0,0,0) = bottom-left-front of the cell.


# ==========================================================================
# Internal helpers
# ==========================================================================

static func _box(bname: String, size: Vector3, pos: Vector3 = Vector3.ZERO,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION,
		mat: Material = null) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = bname
	b.size = size
	b.position = pos
	b.operation = op
	b.use_collision = false
	if mat: b.material = mat
	return b


static func _polygon(pname: String, profile: PackedVector2Array, depth: float,
		pos: Vector3 = Vector3.ZERO,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION,
		mat: Material = null) -> CSGPolygon3D:
	var p := CSGPolygon3D.new()
	p.name = pname
	p.polygon = profile
	p.depth = depth
	p.mode = CSGPolygon3D.MODE_DEPTH
	p.position = pos
	p.operation = op
	p.use_collision = false
	if mat: p.material = mat
	return p


static func _root(rname: String) -> Node3D:
	var r := Node3D.new()
	r.name = rname
	return r


# ==========================================================================
# CORNICES & BANDS
# ==========================================================================

## Dentil course (legacy): row of small cube blocks on a backing strip.
static func dentil_cornice(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("DentilCornice")
	var block_size: float = h * 0.5
	var count: int = p.get("count", maxi(int(w / (block_size * 2.0)), 4))
	var spacing: float = w / float(count)
	var backing_depth: float = h * 0.3
	var cy := h * 0.5

	# Backing strip
	var _mat_body := _M.stone(Color(0.82, 0.78, 0.72))
	var _mat_dentil := _M.stone(Color(0.75, 0.72, 0.66))
	var backing := _box("Backing", Vector3(w, h, backing_depth),
		Vector3(w * 0.5, cy, backing_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(backing)

	# Dentil blocks
	for i in range(count):
		var bx := spacing * 0.5 + spacing * float(i)
		var block := _box("Dentil_%d" % i,
			Vector3(spacing * 0.5, block_size, block_size * 0.8),
			Vector3(bx, cy, backing_depth + block_size * 0.4),
			CSGShape3D.OPERATION_UNION, _mat_dentil)
		root.add_child(block)

	return root


## Dentil band: classical row of small evenly-spaced rectangular blocks.
## Produces 30-50 small dentil blocks (0.03w x 0.04h x 0.02d) across the width,
## projecting from a thin backing strip. More detailed than dentil_cornice.
static func dentil_band(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("DentilBand")

	var block_w: float = p.get("block_w", 0.03)
	var block_h: float = p.get("block_h", minf(0.04, h * 0.85))
	var block_d: float = p.get("block_d", 0.025)
	var gap: float = p.get("gap", block_w * 0.6)
	var spacing: float = block_w + gap
	var count: int = p.get("count", maxi(int(w / spacing), 6))
	# Re-compute spacing to distribute evenly
	spacing = w / float(count)

	var backing_d: float = 0.008
	var cy := h * 0.5

	var _mat_body := _M.stone(Color(0.88, 0.84, 0.78))
	var _mat_dentil := _M.stone(Color(0.80, 0.76, 0.70))

	# Thin backing strip behind the dentils
	var backing := _box("Backing", Vector3(w, h, backing_d),
		Vector3(w * 0.5, cy, backing_d * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(backing)

	# Dentil blocks — each one a small rectangular prism
	for i in range(count):
		var bx := spacing * 0.5 + spacing * float(i)
		var block := _box("Dentil_%d" % i,
			Vector3(block_w, block_h, block_d),
			Vector3(bx, cy, backing_d + block_d * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_dentil)
		root.add_child(block)

	return root


## Cyma recta: S-curve profile extruded along width.
static func cyma_recta(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("CymaRecta")
	var depth: float = p.get("depth", minf(h * 0.4, 0.05))

	# S-curve profile in Y-Z plane
	var profile := PackedVector2Array()
	var steps: int = 12
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var y_val := t * h
		var z_val: float
		if t < 0.5:
			z_val = depth * (2.0 * t * t)
		else:
			z_val = depth * (1.0 - 2.0 * (1.0 - t) * (1.0 - t))
		profile.append(Vector2(y_val, z_val))

	# Close the profile
	profile.append(Vector2(h, 0.0))
	profile.append(Vector2(0.0, 0.0))

	var poly := _polygon("CymaProfile", profile, w, Vector3(0.0, 0.0, 0.0),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.82, 0.78, 0.72)))
	poly.rotation_degrees.y = -90.0
	poly.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(poly)

	return root


## Cyma recta moulding: S-curve with greater projection for cornice crown.
## Same profile as cyma_recta but defaults to deeper projection.
static func cyma_recta_moulding(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var params := p.duplicate()
	if not params.has("depth"):
		params["depth"] = minf(h * 0.5, 0.06)
	var root := cyma_recta(w, h, params)
	root.name = "CymaRectaMoulding"
	return root


## Cornice shelf: a heavy projecting horizontal slab that casts deep shadow.
## Projection kept small (0.06m default) so geometry stays within facade width.
static func cornice_shelf(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("CorniceShelf")
	var projection: float = p.get("projection", 0.06)
	var slab_h: float = h * 0.5
	var drip_h: float = h * 0.08

	var _mat_body := _M.stone(Color(0.85, 0.82, 0.76))
	var _mat_shadow := _M.stone(Color(0.65, 0.62, 0.56))

	# Main projecting slab — stays within facade width (no +0.04 overhang)
	var slab := _box("Slab", Vector3(w, slab_h, projection),
		Vector3(w * 0.5, h - slab_h * 0.5, projection * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(slab)

	# Soffit / underside shadow strip — thin dark strip under the slab
	var soffit := _box("Soffit", Vector3(w, drip_h, projection * 0.95),
		Vector3(w * 0.5, h - slab_h - drip_h * 0.5, projection * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_shadow)
	root.add_child(soffit)

	# Drip edge — tiny lip at the front edge underside
	var drip := _box("Drip", Vector3(w, drip_h * 0.5, 0.01),
		Vector3(w * 0.5, h - slab_h - drip_h * 0.25, projection - 0.005),
		CSGShape3D.OPERATION_UNION, _mat_shadow)
	root.add_child(drip)

	# Lower fillet — transition from shelf down to wall
	var fillet := _box("Fillet", Vector3(w, h - slab_h - drip_h, 0.02),
		Vector3(w * 0.5, (h - slab_h - drip_h) * 0.5, 0.01),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(fillet)

	return root


## String course: simple horizontal band with slight projection.
static func string_course(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("StringCourse")
	var depth: float = p.get("depth", 0.02)

	var band := _box("Band", Vector3(w, h, depth),
		Vector3(w * 0.5, h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.82, 0.78, 0.72)))
	root.add_child(band)

	return root


## Fascia: flat band flush with or slightly projecting from wall surface.
static func fascia(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Fascia")
	var depth: float = p.get("depth", 0.012)

	var band := _box("Band", Vector3(w, h, depth),
		Vector3(w * 0.5, h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.85, 0.82, 0.76)))
	root.add_child(band)

	return root


## Rect window band: a row of small rectangular windows (mezzanine style).
## Places multiple small rectangular openings evenly spaced across a bay,
## each with a simple flat stone frame and dark glass fill.
## Params:
##   window_count (int=5)       — number of windows in the band
##   window_ratio (float=0.6)   — window width as fraction of slot width (fallback)
##   win_width (float=auto)     — override: absolute window width in meters
##   win_height (float=auto)    — override: absolute window height in meters
##   frame_width (float=0.02)   — frame thickness around each window
##   frame_depth (float=0.015)  — how far the frame projects forward
static func rect_window_band(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("RectWindowBand")
	var window_count: int = p.get("window_count", 5)
	var window_ratio: float = p.get("window_ratio", 0.6)
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_w: float = p.get("frame_width", 0.02)
	var frame_depth: float = p.get("frame_depth", 0.015)

	var slot_w := w / float(window_count)

	# Window dimensions — use explicit overrides or fall back to ratio-based
	var win_w: float = p.get("win_width", slot_w * window_ratio)
	win_w = minf(win_w, slot_w - frame_w * 3.0)
	var win_h: float = p.get("win_height", h * 0.55)
	win_h = minf(win_h, h - frame_w * 3.0)

	var cy := h * 0.5

	var _mat_body := _M.stone(Color(0.85, 0.82, 0.76))
	var _mat_frame := _M.stone(Color(0.78, 0.75, 0.68))

	# Dark glass material
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.04, 0.05, 0.08)
	mat_glass.roughness = 0.1
	mat_glass.metallic = 0.5
	mat_glass.metallic_specular = 0.8
	mat_glass.cull_mode = BaseMaterial3D.CULL_BACK
	mat_glass.resource_name = "MezzGlass"

	# Background strip
	var strip := _box("Strip", Vector3(w, h, 0.008),
		Vector3(w * 0.5, cy, 0.004),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(strip)

	for i in range(window_count):
		var cx := slot_w * 0.5 + slot_w * float(i)

		# Dark glass pane (recessed slightly behind frame)
		var glass := _box("Glass_%d" % i,
			Vector3(win_w, win_h, 0.008),
			Vector3(cx, cy, 0.003),
			CSGShape3D.OPERATION_UNION, mat_glass)
		root.add_child(glass)

		# Frame — four strips around the window opening
		# Top (lintel)
		var lintel := _box("Lintel_%d" % i,
			Vector3(win_w + frame_w * 2.0, frame_w, frame_depth),
			Vector3(cx, cy + win_h * 0.5 + frame_w * 0.5, frame_depth * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_frame)
		root.add_child(lintel)

		# Bottom (sill) — slightly wider and deeper
		var sill := _box("Sill_%d" % i,
			Vector3(win_w + frame_w * 3.0, frame_w, frame_depth * 1.3),
			Vector3(cx, cy - win_h * 0.5 - frame_w * 0.5, frame_depth * 0.65),
			CSGShape3D.OPERATION_UNION, _mat_frame)
		root.add_child(sill)

		# Left jamb
		var jl := _box("JambL_%d" % i,
			Vector3(frame_w, win_h, frame_depth),
			Vector3(cx - win_w * 0.5 - frame_w * 0.5, cy, frame_depth * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_frame)
		root.add_child(jl)

		# Right jamb
		var jr := _box("JambR_%d" % i,
			Vector3(frame_w, win_h, frame_depth),
			Vector3(cx + win_w * 0.5 + frame_w * 0.5, cy, frame_depth * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_frame)
		root.add_child(jr)

	return root


## Modillion cornice: cornice with bracket supports (scroll-shaped corbels).
## Depth kept modest so brackets stay within facade footprint.
static func modillion(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Modillion")
	var depth: float = p.get("depth", minf(h * 0.5, 0.06))
	var bracket_count: int = p.get("count", maxi(int(w / 0.30), 5))
	var bracket_spacing := w / float(bracket_count)
	var bracket_w: float = 0.04
	var bracket_h := h * 0.55
	var bracket_d := depth * 0.75
	var cornice_h := h * 0.30
	var soffit_h := h * 0.08

	# Top cornice slab — no side overhang, stays within facade width
	var _mat_body := _M.stone(Color(0.85, 0.82, 0.76))
	var _mat_modillion := _M.stone(Color(0.78, 0.74, 0.68))
	var _mat_shadow := _M.stone(Color(0.62, 0.58, 0.52))

	var slab := _box("Slab", Vector3(w, cornice_h, depth),
		Vector3(w * 0.5, h - cornice_h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(slab)

	# Soffit shadow strip under slab
	var soffit := _box("Soffit", Vector3(w, soffit_h, depth * 0.9),
		Vector3(w * 0.5, h - cornice_h - soffit_h * 0.5, depth * 0.45),
		CSGShape3D.OPERATION_UNION, _mat_shadow)
	root.add_child(soffit)

	# Backing strip (connects to wall)
	var backing := _box("Backing", Vector3(w, h - cornice_h - soffit_h, 0.02),
		Vector3(w * 0.5, (h - cornice_h - soffit_h) * 0.5, 0.01),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(backing)

	# Bracket/modillion corbels — scroll-like supports under the shelf
	for i in range(bracket_count):
		var bx := bracket_spacing * 0.5 + bracket_spacing * float(i)
		# Main bracket body
		var bracket := _box("Bracket_%d" % i,
			Vector3(bracket_w, bracket_h, bracket_d),
			Vector3(bx, h - cornice_h - soffit_h - bracket_h * 0.5, bracket_d * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_modillion)
		root.add_child(bracket)
		# Small volute/scroll cap on top of bracket
		var cap := _box("BracketCap_%d" % i,
			Vector3(bracket_w + 0.01, bracket_h * 0.12, bracket_d + 0.01),
			Vector3(bx, h - cornice_h - soffit_h - bracket_h * 0.06, bracket_d * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_modillion)
		root.add_child(cap)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"dentil_cornice":
			return dentil_cornice(w, h, params)
		"dentil_band":
			return dentil_band(w, h, params)
		"cyma_recta":
			return cyma_recta(w, h, params)
		"cyma_recta_moulding":
			return cyma_recta_moulding(w, h, params)
		"string_course":
			return string_course(w, h, params)
		"fascia":
			return fascia(w, h, params)
		"rect_window_band":
			return rect_window_band(w, h, params)
		"cornice_shelf":
			return cornice_shelf(w, h, params)
		"modillion":
			return modillion(w, h, params)
		_:
			push_warning("CorniceParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"dentil_cornice", "dentil_band", "cyma_recta", "cyma_recta_moulding",
		"string_course", "fascia", "rect_window_band", "cornice_shelf", "modillion",
	])
