extends Node3D
class_name PrimitivePillar

# @identity
# essence: a COLUMN THAT IS A STACK OF DECISIONS — a pillar built by piling one primitive on
#   another, course by course, from the floor to a height it is told the room can hold. Origin at
#   the floor centre, growing +Y. columns x rows repeats the stack into a field, so the same token
#   is one pillar in a corridor and a grove of them filling a room.
# desire: to make the column admit what it is made of. A fluted marble shaft hides its courses;
#   this one shows them, and lets you change the stock, the bond and the colour of every course.
# critical_parameter: height_m clamped by clearance — a pillar taller than the room is a pillar
#   through the ceiling, and the museum's ceiling soffit sits at 4.64 m over a 4.5 m wall.
# triggers: _ready reads config metadata and builds; apply_grid_config re-reads and rebuilds,
#   in either call order (the grid calls it after _ready, the museum before).
# emerges: at columns=1 it reads as architecture — one shaft you walk past. At columns=3, rows=5
#   the same numbers read as a grove you walk INTO, and the stock you chose becomes a floor plan.
# needs: floor at y=0 [present]; a clearance number from the room [config, default 4.40].
# relationships: the parametric sibling of [[pillarcolorcollection]], whose 24 pillars are fixed
#   and whose apply_grid_config is a no-op; built from the same vocabulary as [[cube_scene]],
#   [[sphere]] and [[grab_trihedron]]; wash=gradient is [[gradient_interpolator]]'s ramp stood
#   upright and made walkable-past.
# truth: a column is not a form. It is a decision about what to put on top of what, repeated
#   until you run out of room.

@export_group("Figure")
## The primitive vocabulary the column is cut from. mixed draws one of the four per
## course, deterministically, from rng_seed.
@export_enum("box", "drum", "wedge", "ball", "mixed") var stock: String = "box"
## How colour travels up the column: one colour, alternating courses, a two-colour ramp,
## or the full hue wheel.
@export_enum("mono", "courses", "gradient", "spectrum") var wash: String = "mono"
## How one course meets the next.
@export_enum("stacked", "staggered", "gyre", "taper") var bond: String = "stacked"

@export_group("Size")
## Pillar height in metres, measured from the floor. Clamped by clearance.
@export var height_m: float = 4.20
## The room's clear height in metres. The museum's ceiling soffit is 4.64 m over a 4.5 m
## wall, so 4.40 leaves a shadow gap; raise it only in an open_roof hall.
@export var clearance: float = 4.40
## Width of one course, in metres.
@export var girth: float = 0.80
## Nominal height of one course. The real height is height_m divided by a whole number of
## courses, so the stack always reaches the top exactly.
@export var course_m: float = 0.55

@export_group("Field")
## Stacks across X. 1 is a corridor pillar; 3 or more is a room.
@export var columns: int = 1
## Stacks along Z.
@export var rows: int = 1
@export var spacing_x: float = 2.00
@export var spacing_z: float = 2.00

@export_group("Colour")
@export var base_color: Color = Color(0.72, 0.68, 0.58)
@export var accent_color: Color = Color(0.86, 0.28, 0.18)
## Saturation of the spectrum wash.
@export var saturation: float = 0.62

@export_group("Detail")
## The 0.4 m footer the pillar family stands on.
@export var footer: bool = true
## Degrees each course turns past the one below it, when bond is gyre.
@export var twist_deg: float = 18.0
## Width of the topmost course as a fraction of the base, when bond is taper.
@export var taper_ratio: float = 0.42
## Give each stack a collider, so it is a wall and not a hologram.
@export var solid: bool = true
## Seeds every draw this artifact makes. Same seed, same pillar, forever.
@export var rng_seed: int = 7

const FOOTER_H := 0.40
const FOOTER_MARGIN := 0.20
const KINDS := ["box", "drum", "wedge", "ball"]

var _built: bool = false
var _owned: Array[Node] = []
var _mesh_cache: Dictionary = {}
var _mat_cache: Dictionary = {}
var _courses: int = 0

func _ready() -> void:
	_read_metadata_overrides()
	if not _built:
		_build()

# THE TWO CALL ORDERS. The grid stamps config metadata and then call_deferred's this, so it
# lands AFTER _ready. The endless museum calls it directly on a node that is not in the tree
# yet, so it lands BEFORE _ready. Reading the metadata in both places and only rebuilding when
# something is already built covers each case without building twice.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear()
		_build()

func _read_metadata_overrides() -> void:
	if has_meta("config_stock"): stock = str(get_meta("config_stock")).strip_edges().to_lower()
	if has_meta("config_wash"): wash = str(get_meta("config_wash")).strip_edges().to_lower()
	if has_meta("config_bond"): bond = str(get_meta("config_bond")).strip_edges().to_lower()
	if has_meta("config_height_m"): height_m = float(str(get_meta("config_height_m")))
	if has_meta("config_height"): height_m = float(str(get_meta("config_height")))
	if has_meta("config_clearance"): clearance = float(str(get_meta("config_clearance")))
	if has_meta("config_girth"): girth = float(str(get_meta("config_girth")))
	if has_meta("config_course_m"): course_m = float(str(get_meta("config_course_m")))
	if has_meta("config_columns"): columns = int(float(str(get_meta("config_columns"))))
	if has_meta("config_rows"): rows = int(float(str(get_meta("config_rows"))))
	if has_meta("config_spacing_x"): spacing_x = float(str(get_meta("config_spacing_x")))
	if has_meta("config_spacing_z"): spacing_z = float(str(get_meta("config_spacing_z")))
	# footprint:"3x5" — the field written the way a map author says it out loud.
	if has_meta("config_footprint"):
		var fp: String = str(get_meta("config_footprint")).to_lower().replace(" ", "")
		var parts: PackedStringArray = fp.split("x")
		if parts.size() >= 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			columns = int(parts[0])
			rows = int(parts[1])
	if has_meta("config_base_color"): base_color = _parse_color(str(get_meta("config_base_color")), base_color)
	if has_meta("config_accent_color"): accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_saturation"): saturation = float(str(get_meta("config_saturation")))
	if has_meta("config_footer"): footer = _as_bool(get_meta("config_footer"))
	if has_meta("config_twist_deg"): twist_deg = float(str(get_meta("config_twist_deg")))
	if has_meta("config_taper_ratio"): taper_ratio = float(str(get_meta("config_taper_ratio")))
	if has_meta("config_solid"): solid = _as_bool(get_meta("config_solid"))
	if has_meta("config_rng_seed"): rng_seed = int(float(str(get_meta("config_rng_seed"))))
	if has_meta("config_seed"): rng_seed = int(float(str(get_meta("config_seed"))))

func _clear() -> void:
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()
	_mesh_cache.clear()
	_mat_cache.clear()
	_built = false

# Only ever frees what this artifact made. Sweeping every ownerless child instead would free
# nodes other systems park under an artifact while it is running.
func _own(n: Node) -> Node:
	_owned.append(n)
	add_child(n)
	return n

func _build() -> void:
	_built = true
	if not KINDS.has(stock) and stock != "mixed":
		push_warning("primitive_pillar: unknown stock '%s' — building box" % stock)
		stock = "box"
	if not ["mono", "courses", "gradient", "spectrum"].has(wash):
		push_warning("primitive_pillar: unknown wash '%s' — building mono" % wash)
		wash = "mono"
	if not ["stacked", "staggered", "gyre", "taper"].has(bond):
		push_warning("primitive_pillar: unknown bond '%s' — building stacked" % bond)
		bond = "stacked"

	var clear_h: float = maxf(clearance, 0.60)
	var h: float = clampf(height_m, 0.60, clear_h)
	var g: float = clampf(girth, 0.08, 4.0)
	var cm: float = clampf(course_m, 0.12, 2.0)
	var base_y: float = FOOTER_H if footer else 0.0
	var body_h: float = maxf(h - base_y, cm)
	var n: int = maxi(int(round(body_h / cm)), 2)
	var uh: float = body_h / float(n)
	_courses = n

	var cols: int = clampi(columns, 1, 24)
	var rws: int = clampi(rows, 1, 24)
	var sx: float = maxf(spacing_x, g * 1.05)
	var sz: float = maxf(spacing_z, g * 1.05)

	for cx in range(cols):
		for cz in range(rws):
			var px: float = (float(cx) - float(cols - 1) * 0.5) * sx
			var pz: float = (float(cz) - float(rws - 1) * 0.5) * sz
			_build_stack(Vector3(px, 0.0, pz), g, uh, n, base_y, h,
				int(rng_seed * 1000003 + int(cx) * 977 + int(cz) * 31))

func _build_stack(at: Vector3, g: float, uh: float, n: int, base_y: float, h: float, seed_i: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i

	if footer:
		var fm: Material = _material(base_color.darkened(0.55))
		_unit("box", at + Vector3(0.0, FOOTER_H * 0.5, 0.0),
			Vector3(g + FOOTER_MARGIN, FOOTER_H, g + FOOTER_MARGIN), fm)

	for course in range(n):
		var i: int = int(course)
		var t: float = float(i) / float(maxi(n - 1, 1))
		var w: float = g
		if bond == "taper":
			w = g * lerpf(1.0, clampf(taper_ratio, 0.08, 1.0), t)
		var off := Vector3.ZERO
		if bond == "staggered":
			var s: float = g * 0.22
			off = Vector3((s if i % 2 == 0 else -s), 0.0, (s if i % 4 < 2 else -s))
		var kind: String = stock
		if stock == "mixed":
			kind = str(KINDS[rng.randi_range(0, KINDS.size() - 1)])
		var mi: MeshInstance3D = _unit(kind,
			at + off + Vector3(0.0, base_y + uh * (float(i) + 0.5), 0.0),
			Vector3(w, uh, w), _course_material(i, n, t))
		if bond == "gyre":
			mi.rotation.y = deg_to_rad(twist_deg) * float(i)

	if solid:
		# The collider follows what the BOND did to the footprint. A staggered stack throws
		# courses 0.22 g off centre and a gyre turns them 45 degrees at worst, so a plain
		# g-wide box would leave the corners of the pillar walk-through-able.
		var cw: float = g
		if bond == "staggered":
			cw = g * 1.44
		elif bond == "gyre":
			cw = g * 1.415
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(cw, h, cw)
		cs.shape = shape
		cs.position = at + Vector3(0.0, h * 0.5, 0.0)
		body.add_child(cs)
		_own(body)

func _unit(kind: String, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_for(kind, size)
	mi.material_override = mat
	mi.position = center
	_own(mi)
	return mi

func _mesh_for(kind: String, size: Vector3) -> Mesh:
	var key: String = "%s|%.4f|%.4f" % [kind, size.x, size.y]
	if _mesh_cache.has(key):
		return _mesh_cache[key] as Mesh
	var m: Mesh = null
	match kind:
		"drum":
			var cyl := CylinderMesh.new()
			cyl.top_radius = size.x * 0.5
			cyl.bottom_radius = size.x * 0.5
			cyl.height = size.y
			cyl.radial_segments = 20
			cyl.rings = 1
			m = cyl
		"wedge":
			var pr := PrismMesh.new()
			pr.size = size
			pr.left_to_right = 0.5
			m = pr
		"ball":
			var sp := SphereMesh.new()
			sp.radius = size.x * 0.5
			sp.height = size.y
			sp.radial_segments = 20
			sp.rings = 10
			m = sp
		_:
			var bx := BoxMesh.new()
			bx.size = size
			m = bx
	_mesh_cache[key] = m
	return m

func _course_material(i: int, n: int, t: float) -> Material:
	var c: Color = base_color
	match wash:
		"courses":
			c = base_color if i % 2 == 0 else base_color.lerp(accent_color, 0.65)
		"gradient":
			c = base_color.lerp(accent_color, t)
		"spectrum":
			c = Color.from_hsv(fposmod(float(i) / float(maxi(n, 1)), 1.0),
				clampf(saturation, 0.0, 1.0), 0.92)
		_:
			c = base_color
	return _material(c)

func _material(c: Color) -> Material:
	var key: String = c.to_html(false)
	if _mat_cache.has(key):
		return _mat_cache[key] as Material
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.72
	m.metallic = 0.06
	_mat_cache[key] = m
	return m

func _as_bool(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]

func _parse_color(s: String, fallback: Color) -> Color:
	var txt: String = s.strip_edges()
	if txt.begins_with("#") and txt.is_valid_html_color():
		return Color(txt)
	var p: PackedStringArray = txt.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]),
		1.0 if p.size() < 4 else float(p[3]))

## The built course count, for anything that wants to measure the pillar rather than
## read its exports back.
func course_count() -> int:
	return _courses
