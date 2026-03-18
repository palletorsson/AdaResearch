class_name OrnamentParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade ornament parts — pediments, medallions, cartouches, decorative pilasters.
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


static func _cyl(cname: String, radius: float, height: float,
		pos: Vector3 = Vector3.ZERO, sides: int = 16,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION,
		mat: Material = null) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.name = cname
	c.radius = radius
	c.height = height
	c.sides = sides
	c.position = pos
	c.operation = op
	c.use_collision = false
	if mat: c.material = mat
	return c


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
# ORNAMENTS
# ==========================================================================

## Triangular pediment with oculus in tympanum.
## Ported from CSGFacadeElements.triangular_pediment.
static func pediment_tri(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PedimentTri")
	var depth: float = p.get("depth", 0.08)
	var peak_h: float = p.get("peak_height", h * 0.8)

	# Triangular cross-section
	var profile := PackedVector2Array()
	profile.append(Vector2(0.0, 0.0))
	profile.append(Vector2(w, 0.0))
	profile.append(Vector2(w * 0.5, peak_h))

	var _mat_ped := _M.stone(Color(0.82, 0.78, 0.72))
	var triangle := _polygon("Tympanum", profile, depth, Vector3(0.0, 0.0, 0.0),
		CSGShape3D.OPERATION_UNION, _mat_ped)
	root.add_child(triangle)

	# Cornice line along bottom
	var cornice := _box("Cornice", Vector3(w * 1.05, h * 0.12, depth * 1.3),
		Vector3(w * 0.5, h * 0.06, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_ped)
	root.add_child(cornice)

	# Oculus
	var oculus_r := minf(w, peak_h) * 0.08
	var oculus := _cyl("Oculus", oculus_r, depth * 2.0,
		Vector3(w * 0.5, peak_h * 0.35, depth * 0.5), 16,
		CSGShape3D.OPERATION_SUBTRACTION)
	oculus.rotation_degrees.x = 90.0
	root.add_child(oculus)

	return root


## Broken pediment: two halves with gap, finial/urn in center.
## Ported from CSGFacadeElements.broken_pediment.
static func pediment_broken(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PedimentBroken")
	var depth: float = p.get("depth", 0.08)
	var peak_h: float = p.get("peak_height", h * 0.8)
	var gap_w: float = w * 0.2

	# Left half
	var left_profile := PackedVector2Array()
	left_profile.append(Vector2(0.0, 0.0))
	left_profile.append(Vector2(w * 0.5 - gap_w * 0.5, 0.0))
	var left_peak_y := peak_h * (w * 0.5 - gap_w * 0.5) / (w * 0.5)
	left_profile.append(Vector2(w * 0.5 - gap_w * 0.5, left_peak_y))

	var _mat_bped := _M.stone(Color(0.82, 0.78, 0.72))
	var _mat_urn := _M.stone(Color(0.75, 0.72, 0.66))
	var left_tri := _polygon("LeftHalf", left_profile, depth, Vector3(0.0, 0.0, 0.0),
		CSGShape3D.OPERATION_UNION, _mat_bped)
	root.add_child(left_tri)

	# Right half
	var right_start := w * 0.5 + gap_w * 0.5
	var right_profile := PackedVector2Array()
	right_profile.append(Vector2(right_start, left_peak_y))
	right_profile.append(Vector2(right_start, 0.0))
	right_profile.append(Vector2(w, 0.0))

	var right_tri := _polygon("RightHalf", right_profile, depth, Vector3(0.0, 0.0, 0.0),
		CSGShape3D.OPERATION_UNION, _mat_bped)
	root.add_child(right_tri)

	# Cornice
	var cornice := _box("Cornice", Vector3(w * 1.05, h * 0.12, depth * 1.3),
		Vector3(w * 0.5, h * 0.06, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_bped)
	root.add_child(cornice)

	# Finial/urn
	var finial_r := gap_w * 0.25
	var finial_h := peak_h * 0.5

	var urn_body := _cyl("UrnBody", finial_r, finial_h * 0.6,
		Vector3(w * 0.5, left_peak_y + finial_h * 0.3, depth * 0.5), 12,
		CSGShape3D.OPERATION_UNION, _mat_urn)
	root.add_child(urn_body)

	var urn_lip := _cyl("UrnLip", finial_r * 1.3, finial_h * 0.1,
		Vector3(w * 0.5, left_peak_y + finial_h * 0.65, depth * 0.5), 12,
		CSGShape3D.OPERATION_UNION, _mat_urn)
	root.add_child(urn_lip)

	var urn_base := _box("UrnBase", Vector3(finial_r * 2.0, finial_h * 0.1, finial_r * 2.0),
		Vector3(w * 0.5, left_peak_y - finial_h * 0.05, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_urn)
	root.add_child(urn_base)

	return root


## Medallion: circular relief disc.
static func medallion(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Medallion")
	var depth: float = p.get("depth", 0.03)
	var cx := w * 0.5
	var cy := h * 0.5
	var radius := minf(w, h) * 0.35

	# Outer disc
	var _mat_med := _M.stone(Color(0.80, 0.76, 0.70))
	var disc := _cyl("Disc", radius, depth,
		Vector3(cx, cy, depth * 0.5), 24,
		CSGShape3D.OPERATION_UNION, _mat_med)
	disc.rotation_degrees.x = 90.0
	root.add_child(disc)

	# Inner raised relief (smaller, thicker)
	var inner := _cyl("InnerRelief", radius * 0.7, depth * 0.6,
		Vector3(cx, cy, depth + depth * 0.3), 24,
		CSGShape3D.OPERATION_UNION, _mat_med)
	inner.rotation_degrees.x = 90.0
	root.add_child(inner)

	# Border ring
	var ring := _cyl("BorderRing", radius * 1.05, depth * 0.3,
		Vector3(cx, cy, depth * 0.15), 24,
		CSGShape3D.OPERATION_UNION, _mat_med)
	ring.rotation_degrees.x = 90.0
	root.add_child(ring)

	return root


## Cartouche: oval decorative frame with scroll edges.
static func cartouche(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Cartouche")
	var depth: float = p.get("depth", 0.04)
	var cx := w * 0.5
	var cy := h * 0.5
	var rx := w * 0.35
	var ry := h * 0.4

	# Main oval body (approximated with a horizontally-stretched cylinder)
	var _mat_cart := _M.stone(Color(0.78, 0.74, 0.68))
	var oval := _cyl("OvalBody", ry, depth,
		Vector3(cx, cy, depth * 0.5), 24,
		CSGShape3D.OPERATION_UNION, _mat_cart)
	oval.rotation_degrees.x = 90.0
	oval.scale = Vector3(rx / ry, 1.0, 1.0)
	root.add_child(oval)

	# Scroll decorations at top and bottom
	var scroll_r := ry * 0.2
	var scroll_top := _cyl("ScrollTop", scroll_r, depth * 1.2,
		Vector3(cx, cy + ry * 0.85, depth * 0.6), 12,
		CSGShape3D.OPERATION_UNION, _mat_cart)
	scroll_top.rotation_degrees.x = 90.0
	root.add_child(scroll_top)

	var scroll_bottom := _cyl("ScrollBottom", scroll_r, depth * 1.2,
		Vector3(cx, cy - ry * 0.85, depth * 0.6), 12,
		CSGShape3D.OPERATION_UNION, _mat_cart)
	scroll_bottom.rotation_degrees.x = 90.0
	root.add_child(scroll_bottom)

	# Side scrolls
	var scroll_left := _cyl("ScrollLeft", scroll_r * 0.8, depth * 1.0,
		Vector3(cx - rx * 0.9, cy, depth * 0.5), 12,
		CSGShape3D.OPERATION_UNION, _mat_cart)
	scroll_left.rotation_degrees.x = 90.0
	root.add_child(scroll_left)

	var scroll_right := _cyl("ScrollRight", scroll_r * 0.8, depth * 1.0,
		Vector3(cx + rx * 0.9, cy, depth * 0.5), 12,
		CSGShape3D.OPERATION_UNION, _mat_cart)
	scroll_right.rotation_degrees.x = 90.0
	root.add_child(scroll_right)

	return root


## Pilaster ornament: flat decorative pilaster strip (thinner than structural).
static func pilaster_orn(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PilasterOrn")
	var depth: float = p.get("depth", 0.03)
	var strip_w: float = w * 0.15
	var capital_h: float = h * 0.06
	var base_h: float = h * 0.04
	var shaft_h: float = h - capital_h - base_h
	var cx := w * 0.5

	# Base molding
	var _mat_pil := _M.stone(Color(0.82, 0.78, 0.72))
	var base := _box("Base", Vector3(strip_w * 1.3, base_h, depth * 1.5),
		Vector3(cx, base_h * 0.5, depth * 0.75),
		CSGShape3D.OPERATION_UNION, _mat_pil)
	root.add_child(base)

	# Shaft
	var shaft := _box("Shaft", Vector3(strip_w, shaft_h, depth),
		Vector3(cx, base_h + shaft_h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_pil)
	root.add_child(shaft)

	# Capital
	var capital := _box("Capital", Vector3(strip_w * 1.4, capital_h, depth * 1.6),
		Vector3(cx, base_h + shaft_h + capital_h * 0.5, depth * 0.8),
		CSGShape3D.OPERATION_UNION, _mat_pil)
	root.add_child(capital)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"pediment_tri":
			return pediment_tri(w, h, params)
		"pediment_broken":
			return pediment_broken(w, h, params)
		"medallion":
			return medallion(w, h, params)
		"cartouche":
			return cartouche(w, h, params)
		"pilaster_orn":
			return pilaster_orn(w, h, params)
		_:
			push_warning("OrnamentParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"pediment_tri", "pediment_broken", "medallion", "cartouche", "pilaster_orn",
	])
