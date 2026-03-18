class_name RailingParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade railing parts — simple railing, balustrade, iron railing.
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


static func _root(rname: String) -> Node3D:
	var r := Node3D.new()
	r.name = rname
	return r


# ==========================================================================
# RAILINGS
# ==========================================================================

## Simple railing: top rail + bottom rail + horizontal bars between end posts.
static func simple_railing(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("SimpleRailing")
	var rail_h: float = h * 0.06
	var post_w: float = w * 0.04
	var rail_depth: float = h * 0.3
	var bar_count: int = p.get("bar_count", 3)
	var cx := w * 0.5

	# Bottom rail
	var _mat_srail := _M.stone(Color(0.82, 0.78, 0.72))
	var bottom_rail := _box("BottomRail", Vector3(w, rail_h, rail_depth),
		Vector3(cx, rail_h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_srail)
	root.add_child(bottom_rail)

	# Top rail
	var top_rail := _box("TopRail", Vector3(w, rail_h, rail_depth),
		Vector3(cx, h - rail_h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_srail)
	root.add_child(top_rail)

	# End posts
	var left_post := _box("PostLeft", Vector3(post_w, h, rail_depth),
		Vector3(post_w * 0.5, h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_srail)
	root.add_child(left_post)

	var right_post := _box("PostRight", Vector3(post_w, h, rail_depth),
		Vector3(w - post_w * 0.5, h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_srail)
	root.add_child(right_post)

	# Horizontal bars
	var inner_h := h - rail_h * 2.0
	var bar_spacing := inner_h / float(bar_count + 1)
	var bar_h := rail_h * 0.5
	var inner_w := w - post_w * 2.0

	for i in range(bar_count):
		var by := rail_h + bar_spacing * float(i + 1)
		var bar := _box("Bar_%d" % i,
			Vector3(inner_w, bar_h, rail_depth * 0.6),
			Vector3(cx, by, rail_depth * 0.3),
			CSGShape3D.OPERATION_UNION, _mat_srail)
		root.add_child(bar)

	return root


## Balustrade: top rail, bottom rail, tapered balusters, end posts.
## Ported from CSGFacadeElements.balustrade.
static func balustrade(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Balustrade")
	var count: int = p.get("baluster_count", clampi(int(w / (h * 0.3)), 5, 7))
	var rail_h: float = h * 0.08
	var post_w: float = w * 0.04
	var rail_depth: float = h * 0.4
	var cx := w * 0.5

	# Bottom rail
	var _mat_bstone := _M.stone(Color(0.82, 0.78, 0.72))
	var _mat_baluster := _M.stone(Color(0.85, 0.82, 0.76))
	var bottom_rail := _box("BottomRail", Vector3(w, rail_h, rail_depth),
		Vector3(cx, rail_h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_bstone)
	root.add_child(bottom_rail)

	# Top rail
	var top_rail := _box("TopRail", Vector3(w, rail_h, rail_depth),
		Vector3(cx, h - rail_h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_bstone)
	root.add_child(top_rail)

	# End posts
	var left_post := _box("PostLeft", Vector3(post_w, h, rail_depth),
		Vector3(post_w * 0.5, h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_bstone)
	root.add_child(left_post)

	var right_post := _box("PostRight", Vector3(post_w, h, rail_depth),
		Vector3(w - post_w * 0.5, h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_bstone)
	root.add_child(right_post)

	# Balusters
	var baluster_h: float = h - rail_h * 2.0
	var inner_w: float = w - post_w * 2.0
	var spacing: float = inner_w / float(count + 1)
	var baluster_r: float = spacing * 0.2

	for i in range(count):
		var bx := post_w + spacing * float(i + 1)
		var by := rail_h + baluster_h * 0.5

		var bal := _cyl("Baluster_%d" % i, baluster_r, baluster_h,
			Vector3(bx, by, rail_depth * 0.5), 8,
			CSGShape3D.OPERATION_UNION, _mat_baluster)
		root.add_child(bal)

		# Belly
		var belly := _cyl("Belly_%d" % i, baluster_r * 1.5, baluster_h * 0.25,
			Vector3(bx, by, rail_depth * 0.5), 8,
			CSGShape3D.OPERATION_UNION, _mat_baluster)
		root.add_child(belly)

	return root


## Iron railing: vertical iron bars with decorative finials at top.
static func iron_railing(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("IronRailing")
	var rail_h: float = h * 0.04
	var post_w: float = w * 0.03
	var rail_depth: float = 0.03
	var bar_count: int = p.get("bar_count", clampi(int(w / 0.06), 5, 20))
	var cx := w * 0.5

	# Top rail
	var _mat_iron := _M.metal(Color(0.2, 0.2, 0.22))
	var _mat_finial := _M.metal(Color(0.25, 0.25, 0.28))
	var top_rail := _box("TopRail", Vector3(w, rail_h, rail_depth),
		Vector3(cx, h - rail_h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_iron)
	root.add_child(top_rail)

	# Bottom rail
	var bottom_rail := _box("BottomRail", Vector3(w, rail_h * 0.6, rail_depth),
		Vector3(cx, rail_h * 0.3, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_iron)
	root.add_child(bottom_rail)

	# End posts (slightly thicker)
	var left_post := _box("PostLeft", Vector3(post_w, h, rail_depth),
		Vector3(post_w * 0.5, h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_iron)
	root.add_child(left_post)

	var right_post := _box("PostRight", Vector3(post_w, h, rail_depth),
		Vector3(w - post_w * 0.5, h * 0.5, rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_iron)
	root.add_child(right_post)

	# Vertical iron bars with finials
	var inner_w := w - post_w * 2.0
	var bar_spacing := inner_w / float(bar_count + 1)
	var bar_radius := 0.006
	var bar_h := h - rail_h * 1.5
	var finial_radius := bar_radius * 2.5
	var finial_h := h * 0.04

	for i in range(bar_count):
		var bx := post_w + bar_spacing * float(i + 1)

		# Bar
		var bar := _cyl("Bar_%d" % i, bar_radius, bar_h,
			Vector3(bx, rail_h * 0.6 + bar_h * 0.5, rail_depth * 0.5), 6,
			CSGShape3D.OPERATION_UNION, _mat_iron)
		root.add_child(bar)

		# Finial (small sphere-like stub at top)
		var finial := _cyl("Finial_%d" % i, finial_radius, finial_h,
			Vector3(bx, h - rail_h + finial_h * 0.3, rail_depth * 0.5), 8,
			CSGShape3D.OPERATION_UNION, _mat_finial)
		root.add_child(finial)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"simple_railing":
			return simple_railing(w, h, params)
		"balustrade":
			return balustrade(w, h, params)
		"iron_railing":
			return iron_railing(w, h, params)
		_:
			push_warning("RailingParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"simple_railing", "balustrade", "iron_railing",
	])
