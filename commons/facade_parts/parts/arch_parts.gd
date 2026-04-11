class_name ArchParts
extends RefCounted

## Facade arch parts — standalone arch forms for arcades and openings.
## Cell origin (0,0,0) = bottom-left-front of the cell.

const _M := preload("res://commons/facade_parts/facade_materials.gd")

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
# ARCHES
# ==========================================================================

## Round arch: simple semicircular arch with piers.
static func round_arch(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("RoundArch")
	var pier_w: float = w * 0.1
	var pier_depth: float = p.get("pier_depth", 0.15)
	var arch_thickness: float = p.get("arch_thickness", pier_w * 0.8)
	var arch_spring_y: float = h * 0.5
	var arch_r: float = (w - pier_w * 2.0) * 0.5
	var cx := w * 0.5

	# Piers
	var pier_mat := _M.stone(Color(0.75, 0.72, 0.66))
	var pier_left := _box("PierLeft", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_left)

	var pier_right := _box("PierRight", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(w - pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_right)

	# Arch ring (outer cylinder - inner cylinder)
	var arch_outer := _cyl("ArchOuter", arch_r, pier_depth,
		Vector3(cx, arch_spring_y, pier_depth * 0.5), 24,
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.80, 0.76, 0.70)))
	arch_outer.rotation_degrees.x = 90.0
	root.add_child(arch_outer)

	var arch_inner := _cyl("ArchInner", arch_r - arch_thickness, pier_depth * 1.5,
		Vector3(cx, arch_spring_y, pier_depth * 0.5), 24,
		CSGShape3D.OPERATION_SUBTRACTION)
	arch_inner.rotation_degrees.x = 90.0
	root.add_child(arch_inner)

	# Dark void fill — visible through the opening
	var void_mat := _M.stone(Color(0.06, 0.06, 0.08))
	var void_rect := _box("VoidRect", Vector3(w - pier_w * 2.0, arch_spring_y, 0.01),
		Vector3(cx, arch_spring_y * 0.5, 0.03), CSGShape3D.OPERATION_UNION, void_mat)
	root.add_child(void_rect)
	var void_arch := _cyl("VoidArch", arch_r - arch_thickness, 0.01,
		Vector3(cx, arch_spring_y, 0.03), 24, CSGShape3D.OPERATION_UNION, void_mat)
	void_arch.rotation_degrees.x = 90.0
	root.add_child(void_arch)

	return root


## Pointed arch (Gothic): two intersecting arcs meeting at a point.
static func pointed_arch(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PointedArch")
	var pier_w: float = w * 0.1
	var pier_depth: float = p.get("pier_depth", 0.15)
	var arch_spring_y: float = h * 0.45
	var span: float = w - pier_w * 2.0
	var cx := w * 0.5

	# Piers
	var pier_mat := _M.stone(Color(0.75, 0.72, 0.66))
	var pier_left := _box("PierLeft", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_left)

	var pier_right := _box("PierRight", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(w - pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_right)

	# Pointed arch — approximate with a triangle polygon extruded
	var peak_y := h * 0.95
	var arch_t := pier_w * 0.6

	# Outer triangle
	var outer_profile := PackedVector2Array()
	outer_profile.append(Vector2(pier_w, arch_spring_y))
	outer_profile.append(Vector2(cx, peak_y))
	outer_profile.append(Vector2(w - pier_w, arch_spring_y))

	var outer_tri := _polygon("OuterArch", outer_profile, pier_depth,
		Vector3(0.0, 0.0, 0.0), CSGShape3D.OPERATION_UNION,
		_M.stone(Color(0.80, 0.76, 0.70)))
	root.add_child(outer_tri)

	# Inner triangle (subtraction for hollow arch)
	var inner_profile := PackedVector2Array()
	inner_profile.append(Vector2(pier_w + arch_t, arch_spring_y))
	inner_profile.append(Vector2(cx, peak_y - arch_t * 1.5))
	inner_profile.append(Vector2(w - pier_w - arch_t, arch_spring_y))

	var inner_tri := _polygon("InnerArch", inner_profile, pier_depth * 1.5,
		Vector3(0.0, 0.0, -pier_depth * 0.1), CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(inner_tri)

	# Dark void fill
	var void_mat := _M.stone(Color(0.06, 0.06, 0.08))
	var void_rect := _box("VoidRect", Vector3(span - arch_t * 2.0, arch_spring_y, 0.01),
		Vector3(cx, arch_spring_y * 0.5, 0.03), CSGShape3D.OPERATION_UNION, void_mat)
	root.add_child(void_rect)
	var void_tri := _polygon("VoidTri", inner_profile, 0.01,
		Vector3(0.0, 0.0, 0.03), CSGShape3D.OPERATION_UNION, void_mat)
	root.add_child(void_tri)

	return root


## Arcade arch: two piers with a spanning arch and impost blocks.
## Ported from CSGFacadeElements.arcade_arch.
static func arcade_arch(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ArcadeArch")
	var pier_w: float = w * 0.12
	var pier_depth: float = p.get("pier_depth", 0.2)
	var impost_h: float = h * 0.03
	var arch_spring_y: float = h * 0.55
	var arch_r: float = (w - pier_w * 2.0) * 0.5
	var cx := w * 0.5

	# Left pier
	var pier_mat := _M.stone(Color(0.75, 0.72, 0.66))
	var pier_left := _box("PierLeft", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_left)

	# Right pier
	var pier_right := _box("PierRight", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(w - pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_right)

	# Impost blocks
	var impost_mat := _M.stone(Color(0.70, 0.66, 0.60))
	var impost_left := _box("ImpostLeft",
		Vector3(pier_w * 1.3, impost_h, pier_depth * 1.2),
		Vector3(pier_w * 0.5, arch_spring_y + impost_h * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, impost_mat)
	root.add_child(impost_left)

	var impost_right := _box("ImpostRight",
		Vector3(pier_w * 1.3, impost_h, pier_depth * 1.2),
		Vector3(w - pier_w * 0.5, arch_spring_y + impost_h * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, impost_mat)
	root.add_child(impost_right)

	# Arch
	var arch := _cyl("Arch", arch_r, pier_depth,
		Vector3(cx, arch_spring_y + impost_h, pier_depth * 0.5), 24,
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.80, 0.76, 0.70)))
	arch.rotation_degrees.x = 90.0
	root.add_child(arch)

	var arch_inner := _cyl("ArchInner", arch_r - pier_w * 0.6, pier_depth * 1.5,
		Vector3(cx, arch_spring_y + impost_h, pier_depth * 0.5), 24,
		CSGShape3D.OPERATION_SUBTRACTION, _M.stone(Color(0.06, 0.06, 0.08)))
	arch_inner.rotation_degrees.x = 90.0
	root.add_child(arch_inner)

	# Dark void fill — visible through the opening
	var void_mat := _M.stone(Color(0.06, 0.06, 0.08))
	var inner_r := arch_r - pier_w * 0.6
	var void_rect := _box("VoidRect", Vector3(inner_r * 2.0, arch_spring_y + impost_h, 0.01),
		Vector3(cx, (arch_spring_y + impost_h) * 0.5, 0.03), CSGShape3D.OPERATION_UNION, void_mat)
	root.add_child(void_rect)
	var void_arch := _cyl("VoidArch", inner_r, 0.01,
		Vector3(cx, arch_spring_y + impost_h, 0.03), 24, CSGShape3D.OPERATION_UNION, void_mat)
	void_arch.rotation_degrees.x = 90.0
	root.add_child(void_arch)

	return root


## Segmental arch: shallow arc (less than semicircle).
static func segmental_arch(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("SegmentalArch")
	var pier_w: float = w * 0.1
	var pier_depth: float = p.get("pier_depth", 0.15)
	var arch_spring_y: float = h * 0.6
	var span: float = w - pier_w * 2.0
	var rise: float = h * 0.25  # Shallow rise
	var cx := w * 0.5

	# Piers
	var pier_mat := _M.stone(Color(0.75, 0.72, 0.66))
	var pier_left := _box("PierLeft", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_left)

	var pier_right := _box("PierRight", Vector3(pier_w, arch_spring_y, pier_depth),
		Vector3(w - pier_w * 0.5, arch_spring_y * 0.5, pier_depth * 0.5),
		CSGShape3D.OPERATION_UNION, pier_mat)
	root.add_child(pier_right)

	# Segmental arch — use a large-radius cylinder positioned below the spring line
	# so only the top segment is visible.
	# Calculate radius from span and rise: R = (span^2 / (8*rise)) + rise/2
	var arch_r := (span * span / (8.0 * rise)) + rise * 0.5
	var center_y := arch_spring_y - (arch_r - rise)

	var arch_outer := _cyl("ArchOuter", arch_r, pier_depth,
		Vector3(cx, center_y, pier_depth * 0.5), 32,
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.80, 0.76, 0.70)))
	arch_outer.rotation_degrees.x = 90.0
	root.add_child(arch_outer)

	# Subtract inner and bottom portion
	var arch_inner := _cyl("ArchInner", arch_r - pier_w * 0.7, pier_depth * 1.5,
		Vector3(cx, center_y, pier_depth * 0.5), 32,
		CSGShape3D.OPERATION_SUBTRACTION, _M.stone(Color(0.06, 0.06, 0.08)))
	arch_inner.rotation_degrees.x = 90.0
	root.add_child(arch_inner)

	# Clip below spring line
	var clip := _box("Clip", Vector3(w * 2.0, arch_r * 2.0, pier_depth * 2.0),
		Vector3(cx, center_y - arch_r, pier_depth * 0.5),
		CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(clip)

	# Dark void fill — visible through the opening
	var void_mat := _M.stone(Color(0.06, 0.06, 0.08))
	var inner_r := arch_r - pier_w * 0.7
	var void_rect := _box("VoidRect", Vector3(span, arch_spring_y, 0.01),
		Vector3(cx, arch_spring_y * 0.5, 0.03), CSGShape3D.OPERATION_UNION, void_mat)
	root.add_child(void_rect)
	# Segmental void arc — same large radius, clipped by the same spring line
	var void_arc := _cyl("VoidArc", inner_r, 0.01,
		Vector3(cx, center_y, 0.03), 32, CSGShape3D.OPERATION_UNION, void_mat)
	void_arc.rotation_degrees.x = 90.0
	root.add_child(void_arc)
	# Clip void below spring line too
	var void_clip := _box("VoidClip", Vector3(w * 2.0, arch_r * 2.0, 0.05),
		Vector3(cx, center_y - arch_r, 0.03),
		CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(void_clip)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"round_arch":
			return round_arch(w, h, params)
		"pointed_arch":
			return pointed_arch(w, h, params)
		"arcade_arch":
			return arcade_arch(w, h, params)
		"segmental_arch":
			return segmental_arch(w, h, params)
		_:
			push_warning("ArchParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"round_arch", "pointed_arch", "arcade_arch", "segmental_arch",
	])
