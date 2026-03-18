class_name CorniceParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade cornice and band parts — dentil, cyma recta, string course, fascia, modillion.
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

## Dentil course: row of small cube blocks on a backing strip.
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


## Cyma recta: S-curve profile extruded along width.
static func cyma_recta(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("CymaRecta")
	var depth: float = p.get("depth", h * 0.6)

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
	poly.position = Vector3(w, 0.0, 0.0)
	root.add_child(poly)

	return root


## String course: simple horizontal band with slight projection.
static func string_course(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("StringCourse")
	var depth: float = p.get("depth", 0.03)

	var band := _box("Band", Vector3(w, h, depth),
		Vector3(w * 0.5, h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.82, 0.78, 0.72)))
	root.add_child(band)

	return root


## Fascia: flat band flush with wall surface.
static func fascia(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Fascia")
	var depth: float = p.get("depth", 0.005)

	var band := _box("Band", Vector3(w, h, depth),
		Vector3(w * 0.5, h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.82, 0.78, 0.72)))
	root.add_child(band)

	return root


## Modillion cornice: cornice with bracket supports (scroll-shaped corbels).
static func modillion(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Modillion")
	var depth: float = p.get("depth", h * 0.8)
	var bracket_count: int = p.get("count", maxi(int(w / (h * 1.5)), 3))
	var bracket_spacing := w / float(bracket_count)
	var bracket_w := h * 0.3
	var bracket_h := h * 0.6
	var cornice_h := h * 0.3
	var cy := h * 0.5

	# Top cornice slab (overhanging)
	var _mat_body := _M.stone(Color(0.82, 0.78, 0.72))
	var _mat_modillion := _M.stone(Color(0.75, 0.72, 0.66))
	var slab := _box("Slab", Vector3(w + 0.02, cornice_h, depth),
		Vector3(w * 0.5, h - cornice_h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(slab)

	# Backing strip
	var backing := _box("Backing", Vector3(w, h - cornice_h, depth * 0.3),
		Vector3(w * 0.5, (h - cornice_h) * 0.5, depth * 0.15),
		CSGShape3D.OPERATION_UNION, _mat_body)
	root.add_child(backing)

	# Bracket corbels
	for i in range(bracket_count):
		var bx := bracket_spacing * 0.5 + bracket_spacing * float(i)
		var bracket := _box("Bracket_%d" % i,
			Vector3(bracket_w, bracket_h, depth * 0.7),
			Vector3(bx, h - cornice_h - bracket_h * 0.5, depth * 0.35),
			CSGShape3D.OPERATION_UNION, _mat_modillion)
		root.add_child(bracket)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"dentil_cornice":
			return dentil_cornice(w, h, params)
		"cyma_recta":
			return cyma_recta(w, h, params)
		"string_course":
			return string_course(w, h, params)
		"fascia":
			return fascia(w, h, params)
		"modillion":
			return modillion(w, h, params)
		_:
			push_warning("CorniceParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"dentil_cornice", "cyma_recta", "string_course", "fascia", "modillion",
	])
