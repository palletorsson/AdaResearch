class_name CSGFacadeElements
extends RefCounted

## Static library that generates CSG node trees for architectural facade elements.
## Each method takes cell_width, cell_height, and a params Dictionary,
## returning a Node3D subtree of CSGShape3D nodes ready to be added to a scene.
##
## Cell origin (0,0,0) = bottom-left-front of the cell.
## +X = right, +Y = up, +Z = toward viewer (out of wall face).
##
## Naming convention: every CSG node gets a descriptive name.
## All CSGShape3D nodes have use_collision = false for performance.

# ==========================================================================
# Internal helpers
# ==========================================================================

## Create a CSGBox3D with common defaults.
static func _box(bname: String, size: Vector3, pos: Vector3 = Vector3.ZERO,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = bname
	b.size = size
	b.position = pos
	b.operation = op
	b.use_collision = false
	return b


## Create a CSGCylinder3D with common defaults.
static func _cyl(cname: String, radius: float, height: float,
		pos: Vector3 = Vector3.ZERO, sides: int = 16,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.name = cname
	c.radius = radius
	c.height = height
	c.sides = sides
	c.position = pos
	c.operation = op
	c.use_collision = false
	return c


## Create a CSGCombiner3D for boolean groups.
static func _combiner(cname: String,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION) -> CSGCombiner3D:
	var c := CSGCombiner3D.new()
	c.name = cname
	c.operation = op
	c.use_collision = false
	return c


## Create a CSGPolygon3D extruded along Z with given 2D profile points.
static func _polygon(pname: String, profile: PackedVector2Array, depth: float,
		pos: Vector3 = Vector3.ZERO,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION) -> CSGPolygon3D:
	var p := CSGPolygon3D.new()
	p.name = pname
	p.polygon = profile
	p.depth = depth
	p.mode = CSGPolygon3D.MODE_DEPTH
	p.position = pos
	p.operation = op
	p.use_collision = false
	return p


## Wrap children under a plain Node3D root.
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

## Tuscan column: plain shaft with taper=0.8, simple base and capital.
static func col_tuscan(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColTuscan")
	var taper: float = p.get("taper", 0.8)
	var radius: float = w * 0.12
	var base_h: float = h * 0.05
	var capital_h: float = h * 0.04
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5

	# Base — simple torus-like cylinder wider than shaft
	var base := _cyl("Base", radius * 1.3, base_h,
		Vector3(cx, base_h * 0.5, 0.0), 16)
	root.add_child(base)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 16)
	shaft.cone = true
	# CSGCylinder3D cone mode tapers to 0; we simulate taper by stacking
	# Actually in Godot 4, cone just makes it pointy. We'll use a non-cone cylinder.
	shaft.cone = false
	root.add_child(shaft)

	# Capital — echinus (rounded cushion) + abacus (flat slab)
	var echinus_h := capital_h * 0.5
	var abacus_h := capital_h * 0.5
	var echinus := _cyl("Echinus", radius * 1.15, echinus_h,
		Vector3(cx, base_h + shaft_h + echinus_h * 0.5, 0.0), 16)
	root.add_child(echinus)

	var abacus := _box("Abacus", Vector3(radius * 2.6, abacus_h, radius * 2.6),
		Vector3(cx, base_h + shaft_h + echinus_h + abacus_h * 0.5, 0.0))
	root.add_child(abacus)

	return root


## Doric column: taper=0.83, 20 flutes, plain capital.
static func col_doric(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColDoric")
	var radius: float = w * 0.12
	var base_h: float = h * 0.04
	var capital_h: float = h * 0.045
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var flute_count: int = p.get("flute_count", 20)

	# Base
	var base := _cyl("Base", radius * 1.2, base_h,
		Vector3(cx, base_h * 0.5, 0.0), 20)
	root.add_child(base)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 20)
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
		Vector3(cx, y_base + necking_h * 0.5, 0.0), 20)
	root.add_child(necking)

	var echinus := _cyl("Echinus", radius * 1.2, echinus_h,
		Vector3(cx, y_base + necking_h + echinus_h * 0.5, 0.0), 20)
	root.add_child(echinus)

	var abacus := _box("Abacus", Vector3(radius * 2.8, abacus_h, radius * 2.8),
		Vector3(cx, y_base + necking_h + echinus_h + abacus_h * 0.5, 0.0))
	root.add_child(abacus)

	return root


## Ionic column: taper=0.85, 24 flutes, volute capital with scrolls.
static func col_ionic(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColIonic")
	var radius: float = w * 0.11
	var base_h: float = h * 0.06
	var capital_h: float = h * 0.06
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var flute_count: int = p.get("flute_count", 24)

	# Attic base — two torus-like stacked cylinders + plinth
	var plinth_h := base_h * 0.3
	var torus_h := base_h * 0.35
	var plinth := _box("BasePlinth", Vector3(radius * 2.8, plinth_h, radius * 2.8),
		Vector3(cx, plinth_h * 0.5, 0.0))
	root.add_child(plinth)

	var lower_torus := _cyl("LowerTorus", radius * 1.35, torus_h,
		Vector3(cx, plinth_h + torus_h * 0.5, 0.0), 24)
	root.add_child(lower_torus)

	var upper_torus := _cyl("UpperTorus", radius * 1.2, torus_h,
		Vector3(cx, plinth_h + torus_h + torus_h * 0.5, 0.0), 24)
	root.add_child(upper_torus)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 24)
	root.add_child(shaft)

	# Flutes
	_add_flutes(root, radius, shaft_h,
		flute_count, Vector3(cx, base_h + shaft_h * 0.5, 0.0))

	# Ionic capital — abacus + echinus + two volute scrolls
	var cap_y := base_h + shaft_h
	var abacus_h := capital_h * 0.25
	var echinus_h := capital_h * 0.3
	var volute_h := capital_h * 0.45

	# Echinus (egg-and-dart band)
	var echinus := _cyl("Echinus", radius * 1.15, echinus_h,
		Vector3(cx, cap_y + echinus_h * 0.5, 0.0), 24)
	root.add_child(echinus)

	# Volute scrolls — two cylinders on each side (simplified spiral)
	var scroll_r := radius * 0.45
	var scroll_y := cap_y + echinus_h + volute_h * 0.4

	var scroll_left := _cyl("VoluteLeft", scroll_r, volute_h * 0.6,
		Vector3(cx - radius * 1.3, scroll_y, 0.0), 16)
	scroll_left.rotation_degrees.z = 90.0
	root.add_child(scroll_left)

	var scroll_right := _cyl("VoluteRight", scroll_r, volute_h * 0.6,
		Vector3(cx + radius * 1.3, scroll_y, 0.0), 16)
	scroll_right.rotation_degrees.z = 90.0
	root.add_child(scroll_right)

	# Connecting cushion between volutes
	var cushion := _box("VolyteCushion", Vector3(radius * 2.6, volute_h * 0.5, radius * 1.8),
		Vector3(cx, cap_y + echinus_h + volute_h * 0.25, 0.0))
	root.add_child(cushion)

	# Abacus
	var abacus := _box("Abacus", Vector3(radius * 2.8, abacus_h, radius * 2.8),
		Vector3(cx, cap_y + echinus_h + volute_h + abacus_h * 0.5, 0.0))
	root.add_child(abacus)

	return root


## Corinthian column: taper=0.87, 24 flutes, bell capital with acanthus layers.
static func col_corinthian(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ColCorinthian")
	var radius: float = w * 0.11
	var base_h: float = h * 0.06
	var capital_h: float = h * 0.09
	var shaft_h: float = h - base_h - capital_h
	var cx := w * 0.5
	var flute_count: int = p.get("flute_count", 24)

	# Attic base (same as Ionic)
	var plinth_h := base_h * 0.3
	var torus_h := base_h * 0.35
	var plinth := _box("BasePlinth", Vector3(radius * 2.8, plinth_h, radius * 2.8),
		Vector3(cx, plinth_h * 0.5, 0.0))
	root.add_child(plinth)

	var lower_torus := _cyl("LowerTorus", radius * 1.35, torus_h,
		Vector3(cx, plinth_h + torus_h * 0.5, 0.0), 24)
	root.add_child(lower_torus)

	var upper_torus := _cyl("UpperTorus", radius * 1.2, torus_h,
		Vector3(cx, plinth_h + torus_h + torus_h * 0.5, 0.0), 24)
	root.add_child(upper_torus)

	# Shaft
	var shaft := _cyl("Shaft", radius, shaft_h,
		Vector3(cx, base_h + shaft_h * 0.5, 0.0), 24)
	root.add_child(shaft)

	# Flutes
	_add_flutes(root, radius, shaft_h,
		flute_count, Vector3(cx, base_h + shaft_h * 0.5, 0.0))

	# Corinthian capital — bell shape with acanthus leaf layers
	var cap_y := base_h + shaft_h
	var bell_h := capital_h * 0.7
	var abacus_h := capital_h * 0.15
	var lip_h := capital_h * 0.15

	# Lower acanthus row (wider ring)
	var acanthus_lower := _cyl("AcanthusLower", radius * 1.3, bell_h * 0.35,
		Vector3(cx, cap_y + bell_h * 0.175, 0.0), 24)
	root.add_child(acanthus_lower)

	# Upper acanthus row (slightly narrower, taller)
	var acanthus_upper := _cyl("AcanthusUpper", radius * 1.5, bell_h * 0.35,
		Vector3(cx, cap_y + bell_h * 0.5, 0.0), 24)
	root.add_child(acanthus_upper)

	# Bell top / caulicoli zone
	var bell_top := _cyl("BellTop", radius * 1.2, bell_h * 0.3,
		Vector3(cx, cap_y + bell_h * 0.85, 0.0), 24)
	root.add_child(bell_top)

	# Lip (flared ring at top of bell)
	var lip := _cyl("Lip", radius * 1.6, lip_h,
		Vector3(cx, cap_y + bell_h + lip_h * 0.5, 0.0), 24)
	root.add_child(lip)

	# Abacus (concave-sided square — approximated with box)
	var abacus := _box("Abacus", Vector3(radius * 3.0, abacus_h, radius * 3.0),
		Vector3(cx, cap_y + bell_h + lip_h + abacus_h * 0.5, 0.0))
	root.add_child(abacus)

	return root


## Pilaster: flat column, CSGBox3D shaft with small capital box on top.
static func pilaster(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Pilaster")
	var depth: float = p.get("depth", 0.08)
	var pilaster_w: float = w * 0.25
	var capital_h: float = h * 0.04
	var base_h: float = h * 0.03
	var shaft_h: float = h - capital_h - base_h
	var cx := w * 0.5

	# Base
	var base := _box("Base", Vector3(pilaster_w * 1.2, base_h, depth * 1.3),
		Vector3(cx, base_h * 0.5, depth * 0.5))
	root.add_child(base)

	# Shaft
	var shaft := _box("Shaft", Vector3(pilaster_w, shaft_h, depth),
		Vector3(cx, base_h + shaft_h * 0.5, depth * 0.5))
	root.add_child(shaft)

	# Capital
	var capital := _box("Capital", Vector3(pilaster_w * 1.3, capital_h, depth * 1.4),
		Vector3(cx, base_h + shaft_h + capital_h * 0.5, depth * 0.5))
	root.add_child(capital)

	return root


# ==========================================================================
# OPENINGS
# ==========================================================================

## Rectangular window with frame, optional mullion and transom.
static func rect_window(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("RectWindow")
	var inset: float = p.get("inset", 0.15)
	var frame_t: float = p.get("frame_thickness", 0.04)
	var wall_depth: float = p.get("wall_depth", 0.25)
	var has_mullion: bool = p.get("mullion", false)
	var has_transom: bool = p.get("transom", false)
	var margin_x: float = w * inset
	var margin_y: float = h * 0.1
	var opening_w: float = w - margin_x * 2.0
	var opening_h: float = h - margin_y * 2.0
	var cx := w * 0.5
	var cy := h * 0.5

	# Wall with void cut out (CSGCombiner SUBTRACTION)
	var subtractor := _combiner("WallCut", CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(subtractor)

	var void_box := _box("Void", Vector3(opening_w, opening_h, wall_depth * 1.5),
		Vector3(cx, cy, 0.0), CSGShape3D.OPERATION_UNION)
	subtractor.add_child(void_box)

	# Frame strips (lintel, sill, left jamb, right jamb)
	var lintel := _box("Lintel", Vector3(opening_w + frame_t * 2.0, frame_t, wall_depth * 0.3),
		Vector3(cx, cy + opening_h * 0.5 + frame_t * 0.5, wall_depth * 0.15))
	root.add_child(lintel)

	var sill := _box("Sill", Vector3(opening_w + frame_t * 3.0, frame_t, wall_depth * 0.4),
		Vector3(cx, cy - opening_h * 0.5 - frame_t * 0.5, wall_depth * 0.2))
	root.add_child(sill)

	var jamb_left := _box("JambLeft", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, cy, wall_depth * 0.15))
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, cy, wall_depth * 0.15))
	root.add_child(jamb_right)

	# Optional mullion (vertical bar)
	if has_mullion:
		var mullion := _box("Mullion", Vector3(frame_t * 0.7, opening_h, wall_depth * 0.2),
			Vector3(cx, cy, wall_depth * 0.1))
		root.add_child(mullion)

	# Optional transom (horizontal bar)
	if has_transom:
		var transom := _box("Transom", Vector3(opening_w, frame_t * 0.7, wall_depth * 0.2),
			Vector3(cx, cy + opening_h * 0.15, wall_depth * 0.1))
		root.add_child(transom)

	return root


## Arched window: rectangular lower portion + semicircular arch at top, keystone.
static func arched_window(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ArchedWindow")
	var inset: float = p.get("inset", 0.12)
	var frame_t: float = p.get("frame_thickness", 0.04)
	var wall_depth: float = p.get("wall_depth", 0.25)
	var margin_x: float = w * inset
	var margin_y: float = h * 0.08
	var opening_w: float = w - margin_x * 2.0
	var arch_r: float = opening_w * 0.5
	var rect_h: float = h - margin_y * 2.0 - arch_r
	var cx := w * 0.5
	var rect_cy := margin_y + rect_h * 0.5

	# Subtraction combiner for the void
	var subtractor := _combiner("WallCut", CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(subtractor)

	# Rectangular void
	var rect_void := _box("RectVoid", Vector3(opening_w, rect_h, wall_depth * 1.5),
		Vector3(cx, rect_cy, 0.0), CSGShape3D.OPERATION_UNION)
	subtractor.add_child(rect_void)

	# Arch void — half cylinder (rotate to cut semicircle)
	var arch_void := _cyl("ArchVoid", arch_r, wall_depth * 1.5,
		Vector3(cx, margin_y + rect_h, 0.0), 24, CSGShape3D.OPERATION_UNION)
	arch_void.rotation_degrees.x = 90.0
	# Only top half — we place it at the spring line; the bottom half will be
	# coincident with rect_void, so it effectively creates the arch shape.
	subtractor.add_child(arch_void)

	# Frame — sill
	var sill := _box("Sill", Vector3(opening_w + frame_t * 3.0, frame_t, wall_depth * 0.4),
		Vector3(cx, margin_y - frame_t * 0.5, wall_depth * 0.2))
	root.add_child(sill)

	# Frame — jambs
	var jamb_left := _box("JambLeft", Vector3(frame_t, rect_h, wall_depth * 0.3),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, rect_cy, wall_depth * 0.15))
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t, rect_h, wall_depth * 0.3),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, rect_cy, wall_depth * 0.15))
	root.add_child(jamb_right)

	# Keystone at arch crown
	var keystone_h := arch_r * 0.25
	var keystone := _box("Keystone",
		Vector3(frame_t * 2.0, keystone_h, wall_depth * 0.35),
		Vector3(cx, margin_y + rect_h + arch_r - keystone_h * 0.3, wall_depth * 0.18))
	root.add_child(keystone)

	return root


## Door: taller opening reaching ground, two panels inside, handle.
static func door(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Door")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.05)
	var margin_x: float = w * 0.15
	var opening_w: float = w - margin_x * 2.0
	var opening_h: float = h * 0.92  # Almost full height, small lintel gap at top
	var cx := w * 0.5
	var cy := opening_h * 0.5

	# Subtraction for door void
	var subtractor := _combiner("WallCut", CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(subtractor)

	var void_box := _box("Void", Vector3(opening_w, opening_h, wall_depth * 1.5),
		Vector3(cx, cy, 0.0), CSGShape3D.OPERATION_UNION)
	subtractor.add_child(void_box)

	# Lintel
	var lintel := _box("Lintel", Vector3(opening_w + frame_t * 2.5, frame_t * 1.5, wall_depth * 0.35),
		Vector3(cx, opening_h + frame_t * 0.75, wall_depth * 0.18))
	root.add_child(lintel)

	# Jambs
	var jamb_left := _box("JambLeft", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, cy, wall_depth * 0.15))
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, cy, wall_depth * 0.15))
	root.add_child(jamb_right)

	# Two panels inside the door (upper and lower)
	var panel_w := opening_w * 0.8
	var panel_gap := opening_h * 0.05
	var panel_h := (opening_h - panel_gap * 3.0) * 0.5
	var panel_depth := 0.02

	var upper_panel := _box("UpperPanel", Vector3(panel_w, panel_h, panel_depth),
		Vector3(cx, opening_h - panel_gap - panel_h * 0.5, wall_depth * 0.08))
	root.add_child(upper_panel)

	var lower_panel := _box("LowerPanel", Vector3(panel_w, panel_h, panel_depth),
		Vector3(cx, panel_gap + panel_h * 0.5, wall_depth * 0.08))
	root.add_child(lower_panel)

	# Door handle
	var handle := _cyl("Handle", 0.015, 0.04,
		Vector3(cx + opening_w * 0.3, opening_h * 0.45, wall_depth * 0.12), 8)
	handle.rotation_degrees.x = 90.0
	root.add_child(handle)

	return root


## Arcade arch: two piers with a spanning arch and impost blocks.
static func arcade_arch(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ArcadeArch")
	var pier_w: float = w * 0.12
	var pier_depth: float = p.get("pier_depth", 0.2)
	var impost_h: float = h * 0.03
	var arch_spring_y: float = h * 0.55  # Spring line height
	var arch_r: float = (w - pier_w * 2.0) * 0.5
	var cx := w * 0.5

	# Left pier
	var pier_left := _box("PierLeft", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5))
	root.add_child(pier_left)

	# Right pier
	var pier_right := _box("PierRight", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(w - pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5))
	root.add_child(pier_right)

	# Impost blocks at spring line
	var impost_left := _box("ImpostLeft",
		Vector3(pier_w * 1.3, impost_h, pier_depth * 1.2),
		Vector3(pier_w * 0.5, arch_spring_y + impost_h * 0.5, pier_depth * 0.5))
	root.add_child(impost_left)

	var impost_right := _box("ImpostRight",
		Vector3(pier_w * 1.3, impost_h, pier_depth * 1.2),
		Vector3(w - pier_w * 0.5, arch_spring_y + impost_h * 0.5, pier_depth * 0.5))
	root.add_child(impost_right)

	# Arch — half cylinder spanning between piers
	var arch := _cyl("Arch", arch_r, pier_depth,
		Vector3(cx, arch_spring_y + impost_h, pier_depth * 0.5), 24)
	arch.rotation_degrees.x = 90.0
	root.add_child(arch)

	# Subtract the interior void below the arch to leave just the ring
	var arch_inner := _cyl("ArchInner", arch_r - pier_w * 0.6, pier_depth * 1.5,
		Vector3(cx, arch_spring_y + impost_h, pier_depth * 0.5), 24,
		CSGShape3D.OPERATION_SUBTRACTION)
	arch_inner.rotation_degrees.x = 90.0
	root.add_child(arch_inner)

	return root


# ==========================================================================
# BANDS & CORNICES
# ==========================================================================

## Dentil course: row of small cube blocks on a backing strip.
static func dentil(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("DentilCourse")
	var block_size: float = h * 0.5
	var count: int = p.get("count", maxi(int(w / (block_size * 2.0)), 4))
	var spacing: float = w / float(count)
	var backing_depth: float = h * 0.3
	var cy := h * 0.5

	# Backing strip
	var backing := _box("Backing", Vector3(w, h, backing_depth),
		Vector3(w * 0.5, cy, backing_depth * 0.5))
	root.add_child(backing)

	# Dentil blocks
	for i in range(count):
		var bx := spacing * 0.5 + spacing * float(i)
		var block := _box("Dentil_%d" % i,
			Vector3(spacing * 0.5, block_size, block_size * 0.8),
			Vector3(bx, cy, backing_depth + block_size * 0.4))
		root.add_child(block)

	return root


## Cyma recta: S-curve profile extruded along width.
static func cyma_recta(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("CymaRecta")
	var depth: float = p.get("depth", h * 0.6)

	# S-curve profile in Y-Z plane (2D cross-section)
	var profile := PackedVector2Array()
	var steps: int = 12
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		# Cyma recta: concave at top, convex at bottom
		var y_val := t * h
		var z_val: float
		if t < 0.5:
			# Lower convex curve
			z_val = depth * (2.0 * t * t)
		else:
			# Upper concave curve
			z_val = depth * (1.0 - 2.0 * (1.0 - t) * (1.0 - t))
		profile.append(Vector2(y_val, z_val))

	# Close the profile back to the wall
	profile.append(Vector2(h, 0.0))
	profile.append(Vector2(0.0, 0.0))

	var poly := _polygon("CymaProfile", profile, w, Vector3(0.0, 0.0, 0.0))
	# CSGPolygon3D extrudes along local Z by default in DEPTH mode;
	# we want it along X (width). Rotate accordingly.
	poly.rotation_degrees.y = -90.0
	poly.position = Vector3(w, 0.0, 0.0)
	root.add_child(poly)

	return root


## String course: simple horizontal band with slight projection.
static func string_course(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("StringCourse")
	var depth: float = p.get("depth", 0.03)

	var band := _box("Band", Vector3(w, h, depth),
		Vector3(w * 0.5, h * 0.5, depth * 0.5))
	root.add_child(band)

	return root


## Fascia: flat band flush with wall surface.
static func fascia(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Fascia")
	var depth: float = p.get("depth", 0.005)

	var band := _box("Band", Vector3(w, h, depth),
		Vector3(w * 0.5, h * 0.5, depth * 0.5))
	root.add_child(band)

	return root


# ==========================================================================
# SURFACES
# ==========================================================================

## Rusticated blocks: grid of slightly offset blocks with gaps.
static func rusticated_block(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("RusticatedBlock")
	var rows: int = p.get("rows", 4)
	var cols: int = p.get("cols", 2)
	var gap: float = p.get("gap", 0.005)
	var base_depth: float = p.get("depth", 0.02)
	var block_w: float = (w - gap * float(cols + 1)) / float(cols)
	var block_h: float = (h - gap * float(rows + 1)) / float(rows)

	for row in range(rows):
		for col in range(cols):
			var bx := gap + block_w * 0.5 + float(col) * (block_w + gap)
			var by := gap + block_h * 0.5 + float(row) * (block_h + gap)
			# Alternating depth for texture
			var depth_offset: float
			if (row + col) % 2 == 0:
				depth_offset = base_depth
			else:
				depth_offset = base_depth * 0.5
			var block := _box("Block_%d_%d" % [row, col],
				Vector3(block_w, block_h, depth_offset),
				Vector3(bx, by, depth_offset * 0.5))
			root.add_child(block)

	return root


## Balustrade: top rail, bottom rail, tapered balusters, end posts.
static func balustrade(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Balustrade")
	var count: int = p.get("baluster_count", clampi(int(w / (h * 0.3)), 5, 7))
	var rail_h: float = h * 0.08
	var post_w: float = w * 0.04
	var rail_depth: float = h * 0.4
	var cx := w * 0.5

	# Bottom rail
	var bottom_rail := _box("BottomRail", Vector3(w, rail_h, rail_depth),
		Vector3(cx, rail_h * 0.5, rail_depth * 0.5))
	root.add_child(bottom_rail)

	# Top rail
	var top_rail := _box("TopRail", Vector3(w, rail_h, rail_depth),
		Vector3(cx, h - rail_h * 0.5, rail_depth * 0.5))
	root.add_child(top_rail)

	# End posts
	var left_post := _box("PostLeft", Vector3(post_w, h, rail_depth),
		Vector3(post_w * 0.5, h * 0.5, rail_depth * 0.5))
	root.add_child(left_post)

	var right_post := _box("PostRight", Vector3(post_w, h, rail_depth),
		Vector3(w - post_w * 0.5, h * 0.5, rail_depth * 0.5))
	root.add_child(right_post)

	# Balusters (tapered: wider at middle)
	var baluster_h: float = h - rail_h * 2.0
	var inner_w: float = w - post_w * 2.0
	var spacing: float = inner_w / float(count + 1)
	var baluster_r: float = spacing * 0.2

	for i in range(count):
		var bx := post_w + spacing * float(i + 1)
		var by := rail_h + baluster_h * 0.5

		# Main baluster shaft (slightly tapered)
		var bal := _cyl("Baluster_%d" % i, baluster_r, baluster_h,
			Vector3(bx, by, rail_depth * 0.5), 8)
		root.add_child(bal)

		# Belly — wider middle portion
		var belly := _cyl("Belly_%d" % i, baluster_r * 1.5, baluster_h * 0.25,
			Vector3(bx, by, rail_depth * 0.5), 8)
		root.add_child(belly)

	return root


## Plain wall: returns empty Node3D (wall surface shows through).
static func plain_wall(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PlainWall")
	# Intentionally empty — the wall surface behind is the visual
	return root


# ==========================================================================
# CROWNS
# ==========================================================================

## Triangular pediment with oculus in tympanum.
static func triangular_pediment(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("TriangularPediment")
	var depth: float = p.get("depth", 0.08)
	var peak_h: float = p.get("peak_height", h * 0.8)

	# Triangular cross-section via CSGPolygon3D
	var profile := PackedVector2Array()
	profile.append(Vector2(0.0, 0.0))           # Bottom-left
	profile.append(Vector2(w, 0.0))              # Bottom-right
	profile.append(Vector2(w * 0.5, peak_h))     # Peak
	# Profile is in X-Y, extruded along local Z

	var triangle := _polygon("Tympanum", profile, depth, Vector3(0.0, 0.0, 0.0))
	root.add_child(triangle)

	# Cornice line along bottom
	var cornice := _box("Cornice", Vector3(w * 1.05, h * 0.12, depth * 1.3),
		Vector3(w * 0.5, h * 0.06, depth * 0.5))
	root.add_child(cornice)

	# Oculus — small cylinder in the center of the tympanum
	var oculus_r := minf(w, peak_h) * 0.08
	var oculus := _cyl("Oculus", oculus_r, depth * 2.0,
		Vector3(w * 0.5, peak_h * 0.35, depth * 0.5), 16,
		CSGShape3D.OPERATION_SUBTRACTION)
	oculus.rotation_degrees.x = 90.0
	root.add_child(oculus)

	return root


## Broken pediment: two halves with gap, finial/urn in center.
static func broken_pediment(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("BrokenPediment")
	var depth: float = p.get("depth", 0.08)
	var peak_h: float = p.get("peak_height", h * 0.8)
	var gap_w: float = w * 0.2

	# Left half triangle
	var left_profile := PackedVector2Array()
	left_profile.append(Vector2(0.0, 0.0))
	left_profile.append(Vector2(w * 0.5 - gap_w * 0.5, 0.0))
	left_profile.append(Vector2(w * 0.5 - gap_w * 0.5, peak_h * 0.7))
	left_profile.append(Vector2(0.0, 0.0))  # back to origin via slope

	# Simplified: use proper triangle slope
	var left_profile2 := PackedVector2Array()
	left_profile2.append(Vector2(0.0, 0.0))
	left_profile2.append(Vector2(w * 0.5 - gap_w * 0.5, 0.0))
	var left_peak_y := peak_h * (w * 0.5 - gap_w * 0.5) / (w * 0.5)
	left_profile2.append(Vector2(w * 0.5 - gap_w * 0.5, left_peak_y))

	var left_tri := _polygon("LeftHalf", left_profile2, depth, Vector3(0.0, 0.0, 0.0))
	root.add_child(left_tri)

	# Right half triangle (mirrored)
	var right_start := w * 0.5 + gap_w * 0.5
	var right_profile := PackedVector2Array()
	right_profile.append(Vector2(right_start, left_peak_y))
	right_profile.append(Vector2(right_start, 0.0))
	right_profile.append(Vector2(w, 0.0))

	var right_tri := _polygon("RightHalf", right_profile, depth, Vector3(0.0, 0.0, 0.0))
	root.add_child(right_tri)

	# Cornice along bottom
	var cornice := _box("Cornice", Vector3(w * 1.05, h * 0.12, depth * 1.3),
		Vector3(w * 0.5, h * 0.06, depth * 0.5))
	root.add_child(cornice)

	# Finial / urn in the gap
	var finial_r := gap_w * 0.25
	var finial_h := peak_h * 0.5

	# Urn body
	var urn_body := _cyl("UrnBody", finial_r, finial_h * 0.6,
		Vector3(w * 0.5, left_peak_y + finial_h * 0.3, depth * 0.5), 12)
	root.add_child(urn_body)

	# Urn lip
	var urn_lip := _cyl("UrnLip", finial_r * 1.3, finial_h * 0.1,
		Vector3(w * 0.5, left_peak_y + finial_h * 0.65, depth * 0.5), 12)
	root.add_child(urn_lip)

	# Urn base
	var urn_base := _box("UrnBase", Vector3(finial_r * 2.0, finial_h * 0.1, finial_r * 2.0),
		Vector3(w * 0.5, left_peak_y - finial_h * 0.05, depth * 0.5))
	root.add_child(urn_base)

	return root


# ==========================================================================
# ZONE PANELS
# ==========================================================================

## Plinth zone: stepped base, slightly wider than wall.
static func plinth_zone(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PlinthZone")
	var overhang: float = p.get("overhang", 0.02)
	var step_count: int = p.get("steps", 2)
	var total_depth: float = p.get("depth", 0.04)
	var cx := w * 0.5

	for i in range(step_count):
		var t := float(i) / float(step_count)
		var step_h := h / float(step_count)
		var step_overhang := overhang * (1.0 - t)
		var step_depth := total_depth * (1.0 - t * 0.3)
		var step := _box("Step_%d" % i,
			Vector3(w + step_overhang * 2.0, step_h, step_depth),
			Vector3(cx, step_h * 0.5 + step_h * float(i), step_depth * 0.5))
		root.add_child(step)

	return root


## Piano nobile zone: empty Node3D (proportions handled by layout).
static func piano_nobile_zone(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PianoNobileZone")
	# Intentionally empty — proportions and elements placed by the layout system
	return root


## Entablature zone: three stacked strips (architrave, frieze, cornice).
static func entablature_zone(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("EntablatureZone")
	var cx := w * 0.5

	# Classical proportions: architrave ~40%, frieze ~30%, cornice ~30%
	var arch_h := h * 0.4
	var frieze_h := h * 0.3
	var cornice_h := h * 0.3

	# Increasing projection from bottom to top
	var arch_depth: float = p.get("architrave_depth", 0.02)
	var frieze_depth: float = p.get("frieze_depth", 0.025)
	var cornice_depth: float = p.get("cornice_depth", 0.05)

	# Architrave — lowest band, minimal projection
	var architrave := _box("Architrave", Vector3(w, arch_h, arch_depth),
		Vector3(cx, arch_h * 0.5, arch_depth * 0.5))
	root.add_child(architrave)

	# Frieze — middle band, slightly more projection
	var frieze := _box("Frieze", Vector3(w, frieze_h, frieze_depth),
		Vector3(cx, arch_h + frieze_h * 0.5, frieze_depth * 0.5))
	root.add_child(frieze)

	# Cornice — top band, most projection (with drip edge)
	var cornice := _box("Cornice", Vector3(w + 0.02, cornice_h, cornice_depth),
		Vector3(cx, arch_h + frieze_h + cornice_h * 0.5, cornice_depth * 0.5))
	root.add_child(cornice)

	return root


# ==========================================================================
# ELEMENT FACTORY
# ==========================================================================

## Look up and create a CSG element by name.
## Returns a Node3D subtree, or an empty Node3D if unknown.
static func create(element_name: String, w: float, h: float, p: Dictionary = {}) -> Node3D:
	match element_name:
		# Columns
		"col_tuscan":
			return col_tuscan(w, h, p)
		"col_doric":
			return col_doric(w, h, p)
		"col_ionic":
			return col_ionic(w, h, p)
		"col_corinthian":
			return col_corinthian(w, h, p)
		"pilaster":
			return pilaster(w, h, p)
		# Openings
		"rect_window":
			return rect_window(w, h, p)
		"arched_window":
			return arched_window(w, h, p)
		"door":
			return door(w, h, p)
		"arcade_arch":
			return arcade_arch(w, h, p)
		# Bands & Cornices
		"dentil":
			return dentil(w, h, p)
		"cyma_recta":
			return cyma_recta(w, h, p)
		"string_course":
			return string_course(w, h, p)
		"fascia":
			return fascia(w, h, p)
		# Surfaces
		"rusticated_block":
			return rusticated_block(w, h, p)
		"balustrade":
			return balustrade(w, h, p)
		"plain_wall":
			return plain_wall(w, h, p)
		# Crowns
		"triangular_pediment":
			return triangular_pediment(w, h, p)
		"broken_pediment":
			return broken_pediment(w, h, p)
		# Zone panels
		"plinth_zone":
			return plinth_zone(w, h, p)
		"piano_nobile_zone":
			return piano_nobile_zone(w, h, p)
		"entablature_zone":
			return entablature_zone(w, h, p)
		_:
			push_warning("CSGFacadeElements: Unknown element '%s'" % element_name)
			var fallback := Node3D.new()
			fallback.name = "Unknown_%s" % element_name
			return fallback


## Get all available element names.
static func get_element_names() -> PackedStringArray:
	return PackedStringArray([
		# Columns
		"col_tuscan", "col_doric", "col_ionic", "col_corinthian", "pilaster",
		# Openings
		"rect_window", "arched_window", "door", "arcade_arch",
		# Bands & Cornices
		"dentil", "cyma_recta", "string_course", "fascia",
		# Surfaces
		"rusticated_block", "balustrade", "plain_wall",
		# Crowns
		"triangular_pediment", "broken_pediment",
		# Zone panels
		"plinth_zone", "piano_nobile_zone", "entablature_zone",
	])
