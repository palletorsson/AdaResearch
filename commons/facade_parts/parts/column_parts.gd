class_name ColumnParts
extends RefCounted

## Facade column parts — CSG-based classical orders + procedural solomonic/composite.
## Cell origin (0,0,0) = bottom-left-front of the cell.
## +X = right, +Y = up, +Z = toward viewer (out of wall face).

const _FPC := preload("res://commons/facade_parts/procedural_columns.gd")
const _M := preload("res://commons/facade_parts/facade_materials.gd")


# ==========================================================================
# Internal helpers (duplicated from CSG pipeline for self-containment)
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
	if mat:
		b.material = mat
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
	if mat:
		c.material = mat
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


## Add fluting (subtractive thin cylinders around a shaft).
static func _add_flutes(parent: Node3D, shaft_radius: float, shaft_height: float,
		flute_count: int, shaft_center: Vector3) -> void:
	var combiner := _combiner("Flutes", CSGShape3D.OPERATION_SUBTRACTION)
	combiner.position = shaft_center
	parent.add_child(combiner)

	var flute_radius := shaft_radius * 0.08
	var flute_orbit := shaft_radius * 0.92

	for i in range(flute_count):
		var angle := TAU * float(i) / float(flute_count)
		var fx := cos(angle) * flute_orbit
		var fz := sin(angle) * flute_orbit
		var flute := _cyl("Flute_%d" % i, flute_radius, shaft_height * 1.02,
			Vector3(fx, 0.0, fz), 6, CSGShape3D.OPERATION_UNION)
		combiner.add_child(flute)


# ==========================================================================
# COLUMNS
# ==========================================================================

## Tuscan column: plain shaft, simple base and capital.
static func col_tuscan(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColTuscan")
	var radius: float = w * 0.12
	var base_h: float = h * 0.05
	var capital_h: float = h * 0.04
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var shaft_mat := _M.stone(Color(0.85, 0.82, 0.76))
	var cap_mat := _M.stone(Color(0.80, 0.76, 0.70))

	# Base
	var base := _cyl("Base", radius * 1.3, base_h,
		Vector3(cx, base_h * 0.5, 0.0), 16,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(base)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 16,
		CSGShape3D.OPERATION_UNION, shaft_mat)
	shaft.cone = false
	root.add_child(shaft)

	# Capital — echinus + abacus
	var echinus_h := capital_h * 0.5
	var abacus_h := capital_h * 0.5
	var echinus := _cyl("Echinus", radius * 1.15, echinus_h,
		Vector3(cx, base_h + shaft_h + echinus_h * 0.5, 0.0), 16,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(echinus)

	var abacus := _box("Abacus", Vector3(radius * 2.6, abacus_h, radius * 2.6),
		Vector3(cx, base_h + shaft_h + echinus_h + abacus_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(abacus)

	return root


## Doric column: 20 flutes, plain capital.
static func col_doric(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColDoric")
	var radius: float = w * 0.12
	var base_h: float = h * 0.04
	var capital_h: float = h * 0.045
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var flute_count: int = p.get("flute_count", 20)
	var shaft_mat := _M.stone(Color(0.85, 0.82, 0.76))
	var cap_mat := _M.stone(Color(0.80, 0.76, 0.70))

	# Base
	var base := _cyl("Base", radius * 1.2, base_h,
		Vector3(cx, base_h * 0.5, 0.0), 20,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(base)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 20,
		CSGShape3D.OPERATION_UNION, shaft_mat)
	root.add_child(shaft)

	# Flutes
	_add_flutes(root, radius, shaft_h,
		flute_count, Vector3(cx, base_h + shaft_h * 0.5, 0.0))

	# Capital — necking ring + echinus + abacus
	var necking_h := capital_h * 0.2
	var echinus_h := capital_h * 0.35
	var abacus_h := capital_h * 0.45
	var y_base := base_h + shaft_h

	var necking := _cyl("Necking", radius * 0.95, necking_h,
		Vector3(cx, y_base + necking_h * 0.5, 0.0), 20,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(necking)

	var echinus := _cyl("Echinus", radius * 1.2, echinus_h,
		Vector3(cx, y_base + necking_h + echinus_h * 0.5, 0.0), 20,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(echinus)

	var abacus := _box("Abacus", Vector3(radius * 2.8, abacus_h, radius * 2.8),
		Vector3(cx, y_base + necking_h + echinus_h + abacus_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(abacus)

	return root


## Ionic column: 24 flutes, volute capital with scrolls.
static func col_ionic(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColIonic")
	var radius: float = w * 0.11
	var base_h: float = h * 0.06
	var capital_h: float = h * 0.06
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var flute_count: int = p.get("flute_count", 24)
	var shaft_mat := _M.stone(Color(0.85, 0.82, 0.76))
	var cap_mat := _M.stone(Color(0.80, 0.76, 0.70))

	# Attic base
	var plinth_h := base_h * 0.3
	var torus_h := base_h * 0.35
	var plinth := _box("BasePlinth", Vector3(radius * 2.8, plinth_h, radius * 2.8),
		Vector3(cx, plinth_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(plinth)

	var lower_torus := _cyl("LowerTorus", radius * 1.35, torus_h,
		Vector3(cx, plinth_h + torus_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(lower_torus)

	var upper_torus := _cyl("UpperTorus", radius * 1.2, torus_h,
		Vector3(cx, plinth_h + torus_h + torus_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(upper_torus)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, shaft_mat)
	root.add_child(shaft)

	# Flutes
	_add_flutes(root, radius, shaft_h,
		flute_count, Vector3(cx, base_h + shaft_h * 0.5, 0.0))

	# Ionic capital
	var cap_y := base_h + shaft_h
	var abacus_h := capital_h * 0.25
	var echinus_h := capital_h * 0.3
	var volute_h := capital_h * 0.45

	var echinus := _cyl("Echinus", radius * 1.15, echinus_h,
		Vector3(cx, cap_y + echinus_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(echinus)

	var scroll_r := radius * 0.45
	var scroll_y := cap_y + echinus_h + volute_h * 0.4

	var scroll_left := _cyl("VoluteLeft", scroll_r, volute_h * 0.6,
		Vector3(cx - radius * 1.3, scroll_y, 0.0), 16,
		CSGShape3D.OPERATION_UNION, cap_mat)
	scroll_left.rotation_degrees.z = 90.0
	root.add_child(scroll_left)

	var scroll_right := _cyl("VoluteRight", scroll_r, volute_h * 0.6,
		Vector3(cx + radius * 1.3, scroll_y, 0.0), 16,
		CSGShape3D.OPERATION_UNION, cap_mat)
	scroll_right.rotation_degrees.z = 90.0
	root.add_child(scroll_right)

	var cushion := _box("VoluteCushion", Vector3(radius * 2.6, volute_h * 0.5, radius * 1.8),
		Vector3(cx, cap_y + echinus_h + volute_h * 0.25, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(cushion)

	var abacus := _box("Abacus", Vector3(radius * 2.8, abacus_h, radius * 2.8),
		Vector3(cx, cap_y + echinus_h + volute_h + abacus_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(abacus)

	return root


## Corinthian column: 24 flutes, bell capital with acanthus layers.
static func col_corinthian(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColCorinthian")
	var radius: float = w * 0.11
	var base_h: float = h * 0.06
	var capital_h: float = h * 0.09
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var flute_count: int = p.get("flute_count", 24)
	var shaft_mat := _M.stone(Color(0.85, 0.82, 0.76))
	var cap_mat := _M.stone(Color(0.80, 0.76, 0.70))

	# Attic base (same as Ionic)
	var plinth_h := base_h * 0.3
	var torus_h := base_h * 0.35
	var plinth := _box("BasePlinth", Vector3(radius * 2.8, plinth_h, radius * 2.8),
		Vector3(cx, plinth_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(plinth)

	var lower_torus := _cyl("LowerTorus", radius * 1.35, torus_h,
		Vector3(cx, plinth_h + torus_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(lower_torus)

	var upper_torus := _cyl("UpperTorus", radius * 1.2, torus_h,
		Vector3(cx, plinth_h + torus_h + torus_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(upper_torus)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, shaft_mat)
	root.add_child(shaft)

	# Flutes
	_add_flutes(root, radius, shaft_h,
		flute_count, Vector3(cx, base_h + shaft_h * 0.5, 0.0))

	# Corinthian capital — bell shape with acanthus leaf layers
	var cap_y := base_h + shaft_h
	var bell_h := capital_h * 0.7
	var abacus_h := capital_h * 0.15
	var lip_h := capital_h * 0.15

	var acanthus_lower := _cyl("AcanthusLower", radius * 1.3, bell_h * 0.35,
		Vector3(cx, cap_y + bell_h * 0.175, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(acanthus_lower)

	var acanthus_upper := _cyl("AcanthusUpper", radius * 1.5, bell_h * 0.35,
		Vector3(cx, cap_y + bell_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(acanthus_upper)

	var bell_top := _cyl("BellTop", radius * 1.2, bell_h * 0.3,
		Vector3(cx, cap_y + bell_h * 0.85, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(bell_top)

	var lip := _cyl("Lip", radius * 1.6, lip_h,
		Vector3(cx, cap_y + bell_h + lip_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(lip)

	var abacus := _box("Abacus", Vector3(radius * 3.0, abacus_h, radius * 3.0),
		Vector3(cx, cap_y + bell_h + lip_h + abacus_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(abacus)

	return root


## Pilaster: flat column, CSGBox3D shaft with small capital box on top.
## Optional params:
##   style: "plain" | "ionic" | "corinthian" | "doric" — changes the capital form.
##   fluted: bool — adds vertical flute grooves on the shaft face.
##   depth: float — projection from wall (default 0.08).
static func pilaster(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Pilaster")
	var depth: float = p.get("depth", 0.08)
	var style: String = p.get("style", "plain")
	var fluted: bool = p.get("fluted", false)
	var pilaster_w: float = w * 0.25
	var capital_h: float = h * 0.05 if style == "ionic" or style == "corinthian" else h * 0.04
	var base_h: float = h * 0.03
	var shaft_h: float = h - capital_h - base_h
	var cx := w * 0.5
	var body_mat := _M.stone(Color(0.82, 0.78, 0.72))
	var cap_mat := _M.stone(Color(0.80, 0.76, 0.70))

	# Base
	var base := _box("Base", Vector3(pilaster_w * 1.2, base_h, depth * 1.3),
		Vector3(cx, base_h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(base)

	# Shaft
	var shaft := _box("Shaft", Vector3(pilaster_w, shaft_h, depth),
		Vector3(cx, base_h + shaft_h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, body_mat)
	root.add_child(shaft)

	# Fluting: vertical grooves on the front face of the shaft
	if fluted:
		var flute_count: int = p.get("flute_count", 5)
		var flute_w: float = pilaster_w / float(flute_count * 2 + 1)
		var flute_depth: float = depth * 0.15
		var flute_combiner := _combiner("Flutes", CSGShape3D.OPERATION_SUBTRACTION)
		flute_combiner.position = Vector3.ZERO
		root.add_child(flute_combiner)
		for i in range(flute_count):
			var fx := cx - pilaster_w * 0.5 + flute_w + float(i) * flute_w * 2.0 + flute_w * 0.5
			var flute := _box("Flute_%d" % i,
				Vector3(flute_w * 0.7, shaft_h * 0.92, flute_depth),
				Vector3(fx, base_h + shaft_h * 0.5, depth + flute_depth * 0.3),
				CSGShape3D.OPERATION_UNION, body_mat)
			flute_combiner.add_child(flute)

	# Capital — style-dependent
	var cap_y := base_h + shaft_h
	match style:
		"ionic":
			# Ionic capital: echinus band + volute scrolls + abacus
			var echinus_h := capital_h * 0.30
			var volute_h := capital_h * 0.40
			var abacus_h := capital_h * 0.30
			# Echinus
			var echinus := _box("Echinus",
				Vector3(pilaster_w * 1.15, echinus_h, depth * 1.2),
				Vector3(cx, cap_y + echinus_h * 0.5, depth * 0.5),
				CSGShape3D.OPERATION_UNION, cap_mat)
			root.add_child(echinus)
			# Volute scrolls (small cylinders at sides)
			var scroll_r := pilaster_w * 0.25
			var scroll_y := cap_y + echinus_h + volute_h * 0.45
			var scroll_left := _cyl("VoluteLeft", scroll_r, depth * 0.8,
				Vector3(cx - pilaster_w * 0.55, scroll_y, depth * 0.5), 12,
				CSGShape3D.OPERATION_UNION, cap_mat)
			scroll_left.rotation_degrees.x = 90.0
			root.add_child(scroll_left)
			var scroll_right := _cyl("VoluteRight", scroll_r, depth * 0.8,
				Vector3(cx + pilaster_w * 0.55, scroll_y, depth * 0.5), 12,
				CSGShape3D.OPERATION_UNION, cap_mat)
			scroll_right.rotation_degrees.x = 90.0
			root.add_child(scroll_right)
			# Cushion connecting scrolls
			var cushion := _box("VoluteCushion",
				Vector3(pilaster_w * 1.1, volute_h * 0.5, depth * 1.0),
				Vector3(cx, cap_y + echinus_h + volute_h * 0.25, depth * 0.5),
				CSGShape3D.OPERATION_UNION, cap_mat)
			root.add_child(cushion)
			# Abacus
			var abacus := _box("Abacus",
				Vector3(pilaster_w * 1.3, abacus_h, depth * 1.4),
				Vector3(cx, cap_y + echinus_h + volute_h + abacus_h * 0.5, depth * 0.5),
				CSGShape3D.OPERATION_UNION, cap_mat)
			root.add_child(abacus)
		"corinthian":
			# Simplified Corinthian: bell with two acanthus tiers + abacus
			var bell_h := capital_h * 0.65
			var abacus_h := capital_h * 0.35
			var tier1 := _box("AcanthusLower",
				Vector3(pilaster_w * 1.15, bell_h * 0.5, depth * 1.2),
				Vector3(cx, cap_y + bell_h * 0.25, depth * 0.5),
				CSGShape3D.OPERATION_UNION, cap_mat)
			root.add_child(tier1)
			var tier2 := _box("AcanthusUpper",
				Vector3(pilaster_w * 1.3, bell_h * 0.5, depth * 1.3),
				Vector3(cx, cap_y + bell_h * 0.75, depth * 0.5),
				CSGShape3D.OPERATION_UNION, cap_mat)
			root.add_child(tier2)
			var abacus := _box("Abacus",
				Vector3(pilaster_w * 1.4, abacus_h, depth * 1.5),
				Vector3(cx, cap_y + bell_h + abacus_h * 0.5, depth * 0.5),
				CSGShape3D.OPERATION_UNION, cap_mat)
			root.add_child(abacus)
		_:
			# Plain / doric: simple capital block
			var capital := _box("Capital", Vector3(pilaster_w * 1.3, capital_h, depth * 1.4),
				Vector3(cx, cap_y + capital_h * 0.5, depth * 0.5),
				CSGShape3D.OPERATION_UNION, cap_mat)
			root.add_child(capital)

	return root


## Half-column (engaged column): semi-circular cross-section projecting from the wall.
## The shaft is a full CSGCylinder3D positioned so the back half sits behind z=0 (the wall
## face), giving the appearance of a column embedded in masonry. Supports Ionic (default),
## Corinthian, or Doric style capitals, and optional fluting.
static func half_column(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("HalfColumn")
	var style: String = p.get("style", "ionic")
	var fluted: bool = p.get("fluted", true)
	var radius: float = p.get("radius", w * 0.35)
	var flute_count: int = p.get("flute_count", 20)

	# Proportions
	var base_h: float = h * 0.06
	var capital_h: float = h * 0.07 if style == "corinthian" else h * 0.06
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	# Push center to z=0 so the front half projects forward
	var cz := 0.0

	# Cream/ivory stone colors matching Galleria Vittorio Emanuele
	var shaft_color := Color(0.90, 0.87, 0.80)   # cream/ivory
	var cap_color := Color(0.88, 0.84, 0.76)      # slightly darker cream
	var shaft_mat := _M.stone(shaft_color, 0.75)
	var cap_mat := _M.stone(cap_color, 0.70)

	# --- Clipper: a box behind the wall plane to subtract the back half ---
	var clip := _combiner("WallClip", CSGShape3D.OPERATION_SUBTRACTION)
	# We add the clip last so it cuts everything. Build parts inside a combiner first.
	var body := _combiner("Body", CSGShape3D.OPERATION_UNION)
	root.add_child(body)

	# --- Base molding ---
	# Torus-shaped base (wider cylinder)
	var base_plinth := _cyl("BasePlinth", radius * 1.4, base_h * 0.4,
		Vector3(cx, base_h * 0.2, cz), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	body.add_child(base_plinth)

	var base_torus := _cyl("BaseTorus", radius * 1.25, base_h * 0.6,
		Vector3(cx, base_h * 0.7, cz), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	body.add_child(base_torus)

	# --- Shaft ---
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, cz), 24,
		CSGShape3D.OPERATION_UNION, shaft_mat)
	body.add_child(shaft)

	# --- Fluting (front-half only visible after clipping) ---
	if fluted:
		_add_flutes(body, radius, shaft_h,
			flute_count, Vector3(cx, base_h + shaft_h * 0.5, cz))

	# --- Capital (style-dependent) ---
	var cap_y := base_h + shaft_h

	match style:
		"doric":
			# Necking + echinus + abacus
			var necking_h := capital_h * 0.2
			var echinus_h := capital_h * 0.35
			var abacus_h := capital_h * 0.45

			var necking := _cyl("Necking", radius * 0.95, necking_h,
				Vector3(cx, cap_y + necking_h * 0.5, cz), 20,
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(necking)

			var echinus := _cyl("Echinus", radius * 1.25, echinus_h,
				Vector3(cx, cap_y + necking_h + echinus_h * 0.5, cz), 20,
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(echinus)

			var abacus := _box("Abacus", Vector3(radius * 2.8, abacus_h, radius * 2.0),
				Vector3(cx, cap_y + necking_h + echinus_h + abacus_h * 0.5, cz),
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(abacus)

		"corinthian":
			# Bell capital with acanthus layers
			var bell_h := capital_h * 0.65
			var lip_h := capital_h * 0.15
			var abacus_h := capital_h * 0.2

			var acanthus_lo := _cyl("AcanthusLower", radius * 1.25, bell_h * 0.4,
				Vector3(cx, cap_y + bell_h * 0.2, cz), 24,
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(acanthus_lo)

			var acanthus_hi := _cyl("AcanthusUpper", radius * 1.45, bell_h * 0.35,
				Vector3(cx, cap_y + bell_h * 0.55, cz), 24,
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(acanthus_hi)

			var lip := _cyl("Lip", radius * 1.55, lip_h,
				Vector3(cx, cap_y + bell_h + lip_h * 0.5, cz), 24,
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(lip)

			var abacus := _box("Abacus", Vector3(radius * 3.0, abacus_h, radius * 2.0),
				Vector3(cx, cap_y + bell_h + lip_h + abacus_h * 0.5, cz),
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(abacus)

		_:
			# Ionic (default) — echinus + volute scrolls + abacus
			var echinus_h := capital_h * 0.30
			var volute_h := capital_h * 0.45
			var abacus_h := capital_h * 0.25

			var echinus := _cyl("Echinus", radius * 1.15, echinus_h,
				Vector3(cx, cap_y + echinus_h * 0.5, cz), 24,
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(echinus)

			# Volute scrolls (left and right)
			var scroll_r := radius * 0.40
			var scroll_y := cap_y + echinus_h + volute_h * 0.4

			var scroll_left := _cyl("VoluteLeft", scroll_r, volute_h * 0.55,
				Vector3(cx - radius * 1.2, scroll_y, cz), 16,
				CSGShape3D.OPERATION_UNION, cap_mat)
			scroll_left.rotation_degrees.z = 90.0
			body.add_child(scroll_left)

			var scroll_right := _cyl("VoluteRight", scroll_r, volute_h * 0.55,
				Vector3(cx + radius * 1.2, scroll_y, cz), 16,
				CSGShape3D.OPERATION_UNION, cap_mat)
			scroll_right.rotation_degrees.z = 90.0
			body.add_child(scroll_right)

			var cushion := _box("VoluteCushion",
				Vector3(radius * 2.4, volute_h * 0.45, radius * 1.6),
				Vector3(cx, cap_y + echinus_h + volute_h * 0.22, cz),
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(cushion)

			var abacus := _box("Abacus", Vector3(radius * 2.8, abacus_h, radius * 2.0),
				Vector3(cx, cap_y + echinus_h + volute_h + abacus_h * 0.5, cz),
				CSGShape3D.OPERATION_UNION, cap_mat)
			body.add_child(abacus)

	# --- Wall-clip box: remove everything behind z=0 (the wall face) ---
	# The clip box extends behind the wall to cut the back half of all cylinders.
	var clip_depth := radius * 2.0
	var clip_box := _box("ClipBox",
		Vector3(w * 2.0, h * 1.1, clip_depth),
		Vector3(cx, h * 0.5, -clip_depth * 0.5),
		CSGShape3D.OPERATION_UNION)
	clip.add_child(clip_box)
	body.add_child(clip)

	return root


## Composite column: Corinthian body with Ionic volutes added.
static func col_composite(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColComposite")
	var radius: float = w * 0.11
	var base_h: float = h * 0.06
	var capital_h: float = h * 0.10
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var flute_count: int = p.get("flute_count", 24)
	var shaft_mat := _M.stone(Color(0.85, 0.82, 0.76))
	var cap_mat := _M.stone(Color(0.80, 0.76, 0.70))

	# Attic base
	var plinth_h := base_h * 0.3
	var torus_h := base_h * 0.35
	var plinth := _box("BasePlinth", Vector3(radius * 2.8, plinth_h, radius * 2.8),
		Vector3(cx, plinth_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(plinth)

	var lower_torus := _cyl("LowerTorus", radius * 1.35, torus_h,
		Vector3(cx, plinth_h + torus_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(lower_torus)

	var upper_torus := _cyl("UpperTorus", radius * 1.2, torus_h,
		Vector3(cx, plinth_h + torus_h + torus_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(upper_torus)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 24,
		CSGShape3D.OPERATION_UNION, shaft_mat)
	root.add_child(shaft)

	# Flutes
	_add_flutes(root, radius, shaft_h,
		flute_count, Vector3(cx, base_h + shaft_h * 0.5, 0.0))

	# Composite capital — Corinthian bell + Ionic volutes
	var cap_y := base_h + shaft_h
	var bell_h := capital_h * 0.55
	var volute_h := capital_h * 0.25
	var abacus_h := capital_h * 0.2

	# Acanthus layers (Corinthian)
	var acanthus_lower := _cyl("AcanthusLower", radius * 1.3, bell_h * 0.4,
		Vector3(cx, cap_y + bell_h * 0.2, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(acanthus_lower)

	var acanthus_upper := _cyl("AcanthusUpper", radius * 1.5, bell_h * 0.35,
		Vector3(cx, cap_y + bell_h * 0.55, 0.0), 24,
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(acanthus_upper)

	# Ionic volutes on top
	var scroll_r := radius * 0.4
	var scroll_y := cap_y + bell_h + volute_h * 0.4

	var scroll_left := _cyl("VoluteLeft", scroll_r, volute_h * 0.6,
		Vector3(cx - radius * 1.3, scroll_y, 0.0), 16,
		CSGShape3D.OPERATION_UNION, cap_mat)
	scroll_left.rotation_degrees.z = 90.0
	root.add_child(scroll_left)

	var scroll_right := _cyl("VoluteRight", scroll_r, volute_h * 0.6,
		Vector3(cx + radius * 1.3, scroll_y, 0.0), 16,
		CSGShape3D.OPERATION_UNION, cap_mat)
	scroll_right.rotation_degrees.z = 90.0
	root.add_child(scroll_right)

	var cushion := _box("VoluteCushion", Vector3(radius * 2.6, volute_h * 0.5, radius * 1.8),
		Vector3(cx, cap_y + bell_h + volute_h * 0.25, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(cushion)

	# Abacus
	var abacus := _box("Abacus", Vector3(radius * 3.0, abacus_h, radius * 3.0),
		Vector3(cx, cap_y + bell_h + volute_h + abacus_h * 0.5, 0.0),
		CSGShape3D.OPERATION_UNION, cap_mat)
	root.add_child(abacus)

	return root


## Solomonic column — delegate to _FPC.
static func col_solomonic(w: float, h: float, p: Dictionary = {}) -> Node3D:
	return _FPC.solomonic(w, h, p)


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"col_tuscan":
			return col_tuscan(w, h, params)
		"col_doric":
			return col_doric(w, h, params)
		"col_ionic":
			return col_ionic(w, h, params)
		"col_corinthian":
			return col_corinthian(w, h, params)
		"pilaster":
			return pilaster(w, h, params)
		"half_column", "engaged_column":
			return half_column(w, h, params)
		"col_solomonic":
			return col_solomonic(w, h, params)
		"col_composite":
			return col_composite(w, h, params)
		_:
			push_warning("ColumnParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"col_tuscan", "col_doric", "col_ionic", "col_corinthian",
		"pilaster", "half_column", "engaged_column",
		"col_solomonic", "col_composite",
	])
