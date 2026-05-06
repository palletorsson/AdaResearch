class_name BalconyParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade balcony parts — juliet, projecting, and loggia.
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


static func _combiner(cname: String,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION) -> CSGCombiner3D:
	var c := CSGCombiner3D.new()
	c.name = cname
	c.operation = op
	c.use_collision = false
	return c


static func _root(rname: String) -> Node3D:
	var r := Node3D.new()
	r.name = rname
	return r


# ==========================================================================
# BALCONIES
# ==========================================================================

## Juliet balcony: decorative iron railing flush with wall + window opening behind.
static func juliet_balcony(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("JulietBalcony")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = 0.04
	var margin_x: float = w * 0.1
	var opening_w: float = w - margin_x * 2.0
	var opening_h: float = h * 0.75
	var railing_h: float = h * 0.35
	var cx := w * 0.5

	# Window void (taller, reaching lower)
	var subtractor := _combiner("WallCut", CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(subtractor)

	var void_box := _box("Void", Vector3(opening_w, opening_h, wall_depth * 1.5),
		Vector3(cx, h * 0.12 + opening_h * 0.5, 0.0), CSGShape3D.OPERATION_UNION)
	subtractor.add_child(void_box)

	# Frame
	var lintel := _box("Lintel", Vector3(opening_w + frame_t * 2.0, frame_t, wall_depth * 0.3),
		Vector3(cx, h * 0.12 + opening_h + frame_t * 0.5, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.08, 0.1, 0.15)))
	root.add_child(lintel)

	# Railing — horizontal top bar
	var rail_depth := 0.06
	var _mat_rail := _M.metal(Color(0.25, 0.25, 0.28))
	var top_rail := _box("TopRail", Vector3(opening_w + 0.04, frame_t * 0.8, rail_depth),
		Vector3(cx, h * 0.12 + railing_h, wall_depth * 0.5 + rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_rail)
	root.add_child(top_rail)

	# Bottom rail
	var bottom_rail := _box("BottomRail", Vector3(opening_w + 0.04, frame_t * 0.6, rail_depth),
		Vector3(cx, h * 0.12, wall_depth * 0.5 + rail_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_rail)
	root.add_child(bottom_rail)

	# Vertical iron bars
	var bar_count: int = p.get("bar_count", clampi(int(opening_w / 0.08), 5, 15))
	var bar_spacing := opening_w / float(bar_count + 1)
	var bar_radius := 0.008

	for i in range(bar_count):
		var bx := cx - opening_w * 0.5 + bar_spacing * float(i + 1)
		var bar := _cyl("Bar_%d" % i, bar_radius, railing_h,
			Vector3(bx, h * 0.12 + railing_h * 0.5, wall_depth * 0.5 + rail_depth * 0.5), 6,
			CSGShape3D.OPERATION_UNION, _mat_rail)
		root.add_child(bar)

	return root


## Projecting balcony: stone/iron platform extending from wall with brackets.
static func projecting_balcony(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ProjectingBalcony")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = 0.04
	var margin_x: float = w * 0.08
	var opening_w: float = w - margin_x * 2.0
	var balcony_depth: float = p.get("balcony_depth", 0.6)
	var platform_h: float = 0.06
	var railing_h: float = h * 0.3
	var sill_y: float = h * 0.35
	var cx := w * 0.5

	# Window opening above the platform
	var window_h: float = h * 0.5
	var subtractor := _combiner("WallCut", CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(subtractor)

	var void_box := _box("Void", Vector3(opening_w, window_h, wall_depth * 1.5),
		Vector3(cx, sill_y + window_h * 0.5, 0.0), CSGShape3D.OPERATION_UNION)
	subtractor.add_child(void_box)

	# Platform slab
	var _mat_platform := _M.stone(Color(0.78, 0.74, 0.68))
	var platform := _box("Platform",
		Vector3(opening_w + 0.1, platform_h, balcony_depth),
		Vector3(cx, sill_y - platform_h * 0.5, wall_depth * 0.5 + balcony_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_platform)
	root.add_child(platform)

	# Support brackets (corbels)
	var bracket_count: int = p.get("bracket_count", 3)
	var bracket_spacing := opening_w / float(bracket_count + 1)
	var bracket_w := 0.06
	var bracket_h := sill_y * 0.4

	var _mat_bracket := _M.stone(Color(0.72, 0.68, 0.62))
	for i in range(bracket_count):
		var bx := cx - opening_w * 0.5 + bracket_spacing * float(i + 1)
		var bracket := _box("Bracket_%d" % i,
			Vector3(bracket_w, bracket_h, balcony_depth * 0.7),
			Vector3(bx, sill_y - platform_h - bracket_h * 0.5,
				wall_depth * 0.5 + balcony_depth * 0.35),
			CSGShape3D.OPERATION_UNION, _mat_bracket)
		root.add_child(bracket)

	# Railing on the platform edge
	var _mat_prail := _M.metal(Color(0.25, 0.25, 0.28))
	var rail_front := _box("RailFront",
		Vector3(opening_w + 0.1, frame_t * 0.8, frame_t),
		Vector3(cx, sill_y + railing_h, wall_depth * 0.5 + balcony_depth - frame_t * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_prail)
	root.add_child(rail_front)

	# Side rails
	var rail_left := _box("RailLeft",
		Vector3(frame_t, railing_h, balcony_depth),
		Vector3(cx - opening_w * 0.5 - 0.05 + frame_t * 0.5,
			sill_y + railing_h * 0.5, wall_depth * 0.5 + balcony_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_prail)
	root.add_child(rail_left)

	var rail_right := _box("RailRight",
		Vector3(frame_t, railing_h, balcony_depth),
		Vector3(cx + opening_w * 0.5 + 0.05 - frame_t * 0.5,
			sill_y + railing_h * 0.5, wall_depth * 0.5 + balcony_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_prail)
	root.add_child(rail_right)

	return root


## Loggia: recessed open gallery with columns.
static func loggia(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Loggia")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var recess_depth: float = p.get("recess_depth", 0.5)
	var col_count: int = p.get("column_count", 3)
	var base_h: float = h * 0.05
	var capital_h: float = h * 0.04
	var beam_h: float = h * 0.05
	var col_h: float = h - base_h - capital_h - beam_h
	var col_radius: float = w * 0.04
	var cx := w * 0.5

	# Recessed void in wall
	var subtractor := _combiner("WallCut", CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(subtractor)

	var void_box := _box("Void", Vector3(w * 0.9, h * 0.9, recess_depth),
		Vector3(cx, h * 0.5, 0.0), CSGShape3D.OPERATION_UNION)
	subtractor.add_child(void_box)

	# Top beam (lintel spanning the loggia)
	var _mat_loggia_stone := _M.stone(Color(0.85, 0.82, 0.76))
	var beam := _box("Beam", Vector3(w * 0.92, beam_h, recess_depth * 0.8),
		Vector3(cx, h - beam_h * 0.5, wall_depth * 0.1 + recess_depth * 0.4),
		CSGShape3D.OPERATION_UNION, _mat_loggia_stone)
	root.add_child(beam)

	# Floor slab
	var floor_slab := _box("Floor", Vector3(w * 0.92, base_h, recess_depth * 0.8),
		Vector3(cx, base_h * 0.5, wall_depth * 0.1 + recess_depth * 0.4),
		CSGShape3D.OPERATION_UNION, _mat_loggia_stone)
	root.add_child(floor_slab)

	# Columns
	var col_spacing := w * 0.9 / float(col_count + 1)
	for i in range(col_count):
		var col_x := w * 0.05 + col_spacing * float(i + 1)
		# Column shaft
		var shaft := _cyl("Column_%d" % i, col_radius, col_h,
			Vector3(col_x, base_h + col_h * 0.5, wall_depth * 0.5), 12,
			CSGShape3D.OPERATION_UNION, _mat_loggia_stone)
		root.add_child(shaft)

		# Simple capital
		var cap := _box("Capital_%d" % i,
			Vector3(col_radius * 3.0, capital_h, col_radius * 3.0),
			Vector3(col_x, base_h + col_h + capital_h * 0.5, wall_depth * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_loggia_stone)
		root.add_child(cap)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"juliet_balcony":
			return juliet_balcony(w, h, params)
		"projecting_balcony":
			return projecting_balcony(w, h, params)
		"loggia":
			return loggia(w, h, params)
		_:
			push_warning("BalconyParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"juliet_balcony", "projecting_balcony", "loggia",
	])
