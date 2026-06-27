extends Node3D
class_name StationAscent

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the PASSAGE piece of the station kit — a painted-metal way UP onto a tall stage or between two heights, built as a flight of treads, a two-stile ladder, or an inclined ramp deck sized to a given rise. Origin at the FOOT (the bottom of the climb on the floor), so it seats where the body starts; the last tread / top of the run lands at rise. Worn treads, an emissive nosing line on every step edge, optional handrail.
# desire: to be climbed — the only station piece that admits the body must move to see. The plinth raises the thing; the ascent raises the looker, so a tall stage stops being a wall and becomes a place you can get onto.
# critical_parameter: rise × style — how high the climb is and whether it is a stair (treads you walk up), a ladder (rungs you haul up, steepest, smallest footprint), or a ramp (an inclined deck you roll up, gentlest, longest footprint). rise sets the tread count / rung count / run length; style sets how much floor the passage claims.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new rise/style.
# emerges: stair = a public, dignified ascent onto a low-to-mid stage; ladder = a tight service climb up a tall face where there is no floor to spend; ramp = a long, no-step grade that lets anything wheeled or unsteady reach the deck. The handrail turns any of them from a hazard into an invitation.
# needs: a foot landing / kick plate on the floor [present]; a run of treads OR two stiles + rungs OR an inclined deck sized to rise [present]; an emissive nosing line per step edge [present]; a top landing lip at rise [present]; an optional handrail with posts along the climb [optional]; worn-metal stringers / side rails framing the run [present].
# relationships: the vertical complement of [[station_stage]] (the stage is the height; the ascent is how you reach it) and of [[station_floorline]] (the floor that points you toward the climb); shares the grid + HangarKit body with [[station_plinth]]; placed against a stage edge by [[curation_station]].
# truth: every raised thing is also a refusal until there is a way up. To build the ascent is to decide the height was meant to be reached, not only seen — the kit's first admission that looking is a thing the body does with its legs.

@export_group("Passage")
## Total height to climb, in metres — the top of the run / last tread lands here.
@export var rise: float = 1.0
## "stair" (a flight of treads) | "ladder" (two stiles + rungs) | "ramp" (an inclined deck).
@export var style: String = "stair"
## Clear width of the climb in metres (tread width / rung span / ramp deck width).
@export var width: float = 1.0
## A handrail (posts + a top rail) running up the climb on both sides (stair/ramp) or one face (ladder).
@export var handrail: bool = true

@export_group("Style")
## Worn-metal side stringers (stair) / side rails (ramp) framing the run.
@export var stringers: bool = true
## An emissive nosing line on each step edge / rung front / ramp lip (the lit safety stripe).
@export var nosing_light: bool = true
## A diagonal caution-stripe kick band on the foot landing (stand-here / mind-the-step).
@export var hazard_foot: bool = true

@export_group("Surface")
@export var wear: float = 0.14
## Faint vertical dust streaks down the side stringer (subtle, deterministic).
@export var dust: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var tread_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const RISER_MAX := 0.19        # max comfortable step rise (m) — sets tread count
const TREAD_DEPTH := 0.30      # going per tread (m) — sets the stair footprint
const TREAD_THICK := 0.045     # tread slab thickness
const RUNG_SPACING := 0.28     # vertical gap between ladder rungs (m)
const RAMP_THICK := 0.08       # inclined deck slab thickness
const RAIL_HEIGHT := 0.95      # handrail top height above the walking surface
const NOSE_W := 0.018          # emissive nosing strip cross-section

var _built := false

func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_rise"): rise = float(str(get_meta("config_rise")))
	if has_meta("config_style"): style = str(get_meta("config_style")).to_lower()
	if has_meta("config_width"): width = float(str(get_meta("config_width")))
	if has_meta("config_handrail"): handrail = _b(get_meta("config_handrail"))
	if has_meta("config_stringers"): stringers = _b(get_meta("config_stringers"))
	if has_meta("config_nosing_light"): nosing_light = _b(get_meta("config_nosing_light"))
	if has_meta("config_hazard_foot"): hazard_foot = _b(get_meta("config_hazard_foot"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_dust"): dust = _b(get_meta("config_dust"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_tread_color"): tread_color = _pc(str(get_meta("config_tread_color")), tread_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var h: float = maxf(rise, 0.2)
	var w: float = clampf(width, 0.5, 4.0)
	match style:
		"ladder": _build_ladder(h, w)
		"ramp": _build_ramp(h, w)
		_: _build_stair(h, w)


# ── STAIR: a flight of treads sized to the rise ───────────────────────────
func _build_stair(h: float, w: float) -> void:
	var steps: int = maxi(int(ceil(h / RISER_MAX)), 1)
	var riser: float = h / float(steps)
	var run: float = float(steps) * TREAD_DEPTH        # total horizontal travel along +Z
	var body_mat := _mat(body_color)
	var tread_mat := HangarKit.worn_metal(tread_color)
	var string_mat := HangarKit.worn_metal(body_color.darkened(0.06))

	# Foot landing / kick plate at the start of the climb (z near 0).
	add_child(_box(Vector3(0, 0.012, -0.06), Vector3(w + 0.08, 0.024, 0.28), body_mat))
	if hazard_foot:
		var hz := HangarKit.striped_mat()
		add_child(_box(Vector3(0, 0.026, -0.16), Vector3(w + 0.06, 0.006, 0.10), hz))

	# Treads — each one riser higher and one TREAD_DEPTH further along +Z. Top tread lands at h.
	for i in range(steps):
		var top_y: float = riser * float(i + 1)
		var cz: float = TREAD_DEPTH * (float(i) + 0.5)
		# the closed riser face under the tread nose
		add_child(_box(Vector3(0, top_y - riser * 0.5, cz - TREAD_DEPTH * 0.5 + 0.012),
			Vector3(w, riser, 0.024), body_mat))
		# the tread slab
		add_child(_box(Vector3(0, top_y - TREAD_THICK * 0.5, cz), Vector3(w, TREAD_THICK, TREAD_DEPTH), tread_mat))
		# emissive nosing line on the leading edge of the tread
		if nosing_light:
			var nose := _emi(accent_color, 0.7)
			add_child(_box(Vector3(0, top_y - TREAD_THICK * 0.5, cz - TREAD_DEPTH * 0.5 + NOSE_W * 0.5),
				Vector3(w * 0.96, TREAD_THICK * 0.7, NOSE_W), nose))

	# Top landing lip at the deck level (a short flush plate the stair delivers you onto).
	add_child(_box(Vector3(0, h - 0.012, run + 0.10), Vector3(w + 0.04, 0.024, 0.20), tread_mat))

	# Side stringers — sloped worn-metal closers framing the run on ±X.
	if stringers:
		var sx: float = w * 0.5 + 0.03
		for s in [1.0, -1.0]:
			_build_stair_stringer(s * sx, steps, riser, run, string_mat)

	# Handrail along both sides, climbing with the treads.
	if handrail:
		var hx: float = w * 0.5 + 0.07
		for s in [1.0, -1.0]:
			_build_sloped_rail(Vector3(s * hx, 0.0, 0.0), Vector3(s * hx, h, run), HangarKit.worn_metal(body_color.darkened(0.1)))

	if dust:
		var ds: Node3D = HangarKit.dust_streaks(run * 0.7, h * 0.7, w * 0.5 + 0.031, maxi(steps, 3))
		ds.position = Vector3(0, h * 0.5, run * 0.45)
		add_child(ds)


func _build_stair_stringer(x: float, steps: int, riser: float, run: float, mat: Material) -> void:
	# Approximate the sawtooth underside with a single sloped slab on each side — the diagonal closer.
	var span: float = sqrt(run * run + (riser * float(steps)) * (riser * float(steps)))
	var ang: float = atan2(riser * float(steps), run)
	var mi := _box(Vector3(x, (riser * float(steps)) * 0.5 - 0.04, run * 0.5),
		Vector3(0.05, 0.30, span + 0.06), mat)
	mi.rotation = Vector3(ang, 0, 0)
	add_child(mi)


# ── LADDER: two stiles + rungs ────────────────────────────────────────────
func _build_ladder(h: float, w: float) -> void:
	var stile_w: float = clampf(w, 0.4, 0.9)          # rung span (a ladder is narrow)
	var body_mat := HangarKit.worn_metal(body_color)
	var rung_mat := HangarKit.worn_metal(tread_color)
	var sx: float = stile_w * 0.5

	# Foot landing under the climb.
	add_child(_box(Vector3(0, 0.012, 0.10), Vector3(stile_w + 0.20, 0.024, 0.34), _mat(body_color)))
	if hazard_foot:
		add_child(_box(Vector3(0, 0.026, 0.10), Vector3(stile_w + 0.16, 0.006, 0.12), HangarKit.striped_mat()))

	# Two vertical stiles, slightly stood off the wall (centred over z≈0.06 mount line).
	var sz: float = 0.06
	for s in [1.0, -1.0]:
		add_child(_box(Vector3(s * sx, h * 0.5, sz), Vector3(0.06, h, 0.06), body_mat))
	# Top extension posts above the deck (the grab handles you pull up on).
	for s in [1.0, -1.0]:
		add_child(_box(Vector3(s * sx, h + 0.20, sz), Vector3(0.05, 0.40, 0.05), body_mat))

	# Rungs evenly up the rise.
	var rungs: int = maxi(int(h / RUNG_SPACING), 1)
	for i in range(rungs + 1):
		var y: float = clampf(RUNG_SPACING * float(i) + 0.16, 0.16, h)
		var cyl := _cyl(Vector3(0, y, sz), stile_w, 0.022, rung_mat)
		cyl.rotation = Vector3(0, 0, PI * 0.5)   # lay the rung horizontal along X
		add_child(cyl)
		if nosing_light:
			add_child(_box(Vector3(0, y, sz + 0.026), Vector3(stile_w * 0.9, NOSE_W, NOSE_W), _emi(accent_color, 0.7)))

	# A simple safety hoop near the top on the climb face (handrail role for a ladder).
	if handrail:
		var hoop := _emi(accent_color, 0.5)
		add_child(_box(Vector3(0, h - 0.10, sz + 0.20), Vector3(stile_w + 0.10, 0.04, 0.04), HangarKit.worn_metal(body_color.darkened(0.1))))
		add_child(_box(Vector3(sx + 0.02, h - 0.45, sz + 0.12), Vector3(0.04, 0.74, 0.04), HangarKit.worn_metal(body_color.darkened(0.1))))
		add_child(_box(Vector3(-sx - 0.02, h - 0.45, sz + 0.12), Vector3(0.04, 0.74, 0.04), HangarKit.worn_metal(body_color.darkened(0.1))))

	if dust:
		var ds: Node3D = HangarKit.dust_streaks(stile_w * 0.8, h * 0.8, sz + 0.05, 3)
		ds.position = Vector3(0, h * 0.5, 0)
		add_child(ds)


# ── RAMP: an inclined deck ─────────────────────────────────────────────────
func _build_ramp(h: float, w: float) -> void:
	# A gentle grade (~1:6) so it reads as walkable: run derived from rise.
	var run: float = maxf(h * 6.0, 1.2)
	var span: float = sqrt(run * run + h * h)
	var ang: float = atan2(h, run)
	var body_mat := _mat(body_color)
	var deck_mat := HangarKit.worn_metal(tread_color)

	# Foot landing.
	add_child(_box(Vector3(0, 0.012, -0.06), Vector3(w + 0.10, 0.024, 0.30), body_mat))
	if hazard_foot:
		add_child(_box(Vector3(0, 0.026, -0.16), Vector3(w + 0.08, 0.006, 0.10), HangarKit.striped_mat()))

	# The inclined deck slab (origin foot at z≈0, rising along +Z to the deck at h).
	var deck := _box(Vector3(0, h * 0.5, run * 0.5), Vector3(w, RAMP_THICK, span), deck_mat)
	deck.rotation = Vector3(ang, 0, 0)
	add_child(deck)

	# A supporting wedge body under the deck (closed side so it isn't a floating plane).
	var wedge := _box(Vector3(0, h * 0.5 - 0.06, run * 0.5), Vector3(w * 0.9, h * 0.86, span * 0.96), body_mat)
	wedge.rotation = Vector3(ang, 0, 0)
	add_child(wedge)

	# Anti-slip cross-cleats up the deck + an emissive lip line at top and edges.
	var cleats: int = maxi(int(run / 0.4), 2)
	for i in range(cleats):
		var t: float = (float(i) + 0.5) / float(cleats)
		var p: Vector3 = Vector3(0, h * t, run * t)
		var cl := _box(p + Vector3(0, RAMP_THICK * 0.5 + 0.012, 0), Vector3(w * 0.9, 0.02, 0.05), HangarKit.worn_metal(body_color.darkened(0.12)))
		cl.rotation = Vector3(ang, 0, 0)
		add_child(cl)
	if nosing_light:
		# Lit edge lines down both long sides of the deck.
		for s in [1.0, -1.0]:
			var edge := _box(Vector3(s * w * 0.5, h * 0.5 + 0.01, run * 0.5), Vector3(NOSE_W, NOSE_W, span * 0.98), _emi(accent_color, 0.7))
			edge.rotation = Vector3(ang, 0, 0)
			add_child(edge)
		# Top lip line at the deck level.
		add_child(_box(Vector3(0, h - 0.006, run + 0.02), Vector3(w * 0.96, NOSE_W, NOSE_W), _emi(accent_color, 0.7)))

	# Top landing lip.
	add_child(_box(Vector3(0, h - 0.012, run + 0.10), Vector3(w + 0.04, 0.024, 0.20), deck_mat))

	# Side rails framing the deck.
	if stringers:
		for s in [1.0, -1.0]:
			var rail := _box(Vector3(s * (w * 0.5 + 0.03), h * 0.5 + 0.06, run * 0.5), Vector3(0.05, 0.16, span + 0.04), HangarKit.worn_metal(body_color.darkened(0.06)))
			rail.rotation = Vector3(ang, 0, 0)
			add_child(rail)

	# Handrail climbing the grade on both sides.
	if handrail:
		var hx: float = w * 0.5 + 0.07
		for s in [1.0, -1.0]:
			_build_sloped_rail(Vector3(s * hx, 0.0, 0.0), Vector3(s * hx, h, run), HangarKit.worn_metal(body_color.darkened(0.1)))

	if dust:
		var ds: Node3D = HangarKit.dust_streaks(run * 0.6, h * 0.7, w * 0.5 + 0.031, maxi(cleats, 3))
		ds.position = Vector3(0, h * 0.5, run * 0.45)
		add_child(ds)


# A handrail running from `foot` (on the floor) up to `top` (at deck level), with a top rail at
# RAIL_HEIGHT above the walking line and a few posts up the run.
func _build_sloped_rail(foot: Vector3, top: Vector3, mat: Material) -> void:
	var up := Vector3(0, RAIL_HEIGHT, 0)
	var a: Vector3 = foot + up
	var b: Vector3 = top + up
	# Top rail.
	add_child(_pipe(a, b, 0.022, mat))
	# Posts: foot, top, and intermediates.
	var posts: int = clampi(int(foot.distance_to(top) / 0.7) + 1, 2, 6)
	for i in range(posts + 1):
		var t: float = float(i) / float(posts)
		var basep: Vector3 = foot.lerp(top, t)
		var topp: Vector3 = basep + up
		add_child(_pipe(basep, topp, 0.018, mat))


func _mat(c: Color) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _cyl(center: Vector3, height: float, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _pipe(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
