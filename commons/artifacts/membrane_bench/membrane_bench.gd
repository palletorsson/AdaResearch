extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MembraneBench

## @identity
## name: "The membrane"
## tier: medium
## lineage: A selectively-permeable wall standing on a bench. Small particles drift through
##   the pores; big ones strike it and bounce. The boundary chooses what counts as inside.
## truth: "THE MARKOV BLANKET MADE FLESH — IT LETS THE SMALL THROUGH, TURNS THE LARGE AWAY"
## applications: ion channels, cell walls, the Markov blanket of active inference — a self
##   defined by what it admits and what it refuses.
## axis: assay — what the apparatus does with a boundary's verdict (see the ASSAY section).

const N_SMALL: int = 18
const N_BIG: int = 7

@export var wall_w: float = 0.9
@export var wall_h: float = 0.55
@export var membrane_col: Color = Color(0.45, 0.78, 0.95)
@export var small_col: Color = Color(0.55, 0.95, 0.60)
@export var big_col: Color = Color(0.95, 0.45, 0.40)
@export var bench_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## across the soft-body bench family (see the ASSAY section at the foot of this file).
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## Seed for the scatter of the two particle populations in the tank. -1 randomizes exactly
## as this bench always has, so the default lineage is unchanged; any value >= 0 makes the
## medium reproducible, without which a sweep photographs a different tank per variant and
## reports the scatter as a confident finding about the axis.
@export var seed_value: int = -1

var _t: float = 0.0
var _small_mm: MultiMesh = null
var _big_mm: MultiMesh = null
var _small_p: Array = []   # each: { pos, vel, phase }
var _big_p: Array = []
var _wall_z: float = 0.0
var _origin := Vector3(0.0, 0.85 + 0.3, 0.0)   # bench top + half wall height


func _ready() -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("wall_w"):
		wall_w = clampf(float(config["wall_w"]), 0.6, 1.4)
	if config.has("membrane_col"):
		membrane_col = _parse_color(config["membrane_col"], membrane_col)
	if config.has("assay"):
		var _a: String = str(config["assay"]).strip_edges().to_lower()
		assay = _a if ASSAYS.has(_a) else assay
	if config.has("seed_value"):
		seed_value = int(config["seed_value"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_small_mm = null
	_big_mm = null
	_small_p.clear()
	_big_p.clear()
	if seed_value >= 0:
		_rng.seed = seed_value
	_build()


func _build() -> void:
	# Bench the membrane stands on.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.2, 0.84, 0.7), _matte_mat(bench_col, 0.85)))

	var top: float = 0.86
	# A clear tank to hold the medium, the membrane bisecting it.
	add_child(_box(Vector3(0.0, top + wall_h * 0.5, 0.0), Vector3(wall_w + 0.1, wall_h, 0.55), _glass_mat(Color(0.6, 0.7, 0.85), 0.12)))

	# The membrane wall itself — a perforated sheet facing +Z, at z = 0.
	add_child(_box(Vector3(0.0, top + wall_h * 0.5, _wall_z), Vector3(wall_w, wall_h, 0.012), _glass_mat(membrane_col, 0.35)))
	# Pore studs along the membrane so it reads as porous, not solid.
	for i in range(6):
		var px: float = (float(i) - 2.5) * (wall_w / 6.0)
		add_child(_torus(Vector3(px, top + wall_h * 0.5, _wall_z), 0.03, 0.006, _glow_mat(membrane_col, 0.7)))

	_origin = Vector3(0.0, top + wall_h * 0.5, 0.0)

	# Small particles — start on +Z side, will pass through to -Z.
	_small_mm = _make_field(N_SMALL, 0.018, small_col)
	for i in range(N_SMALL):
		_small_p.append({
			"pos": _rand_in_tank(0.18),
			"vel": Vector3(0, 0, -_rng.randf_range(0.06, 0.14)),
			"phase": _rng.randf() * TAU,
		})
	# Big particles — bounce off, stay on +Z side.
	_big_mm = _make_field(N_BIG, 0.05, big_col)
	for i in range(N_BIG):
		_big_p.append({
			"pos": _rand_in_tank(0.16) + Vector3(0, 0, 0.08),
			"vel": Vector3(0, 0, -_rng.randf_range(0.05, 0.10)),
			"phase": _rng.randf() * TAU,
		})

	_refresh()

	add_child(_billboard_label("THE MARKOV BLANKET MADE FLESH —\nSMALL THROUGH, LARGE TURNED AWAY", Vector3(0.0, 1.6, 0.0), 17, label_col))

	# ASSAY apparatus, appended LAST so every child index and position above is untouched
	# on the legacy path. "none" falls through and adds nothing at all.
	_assay_dressing()


func _make_field(n: int, r: float, col: Color) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = _glow_mat(col, 0.7)
	add_child(mi)
	return mm


func _rand_in_tank(zmin: float) -> Vector3:
	return _origin + Vector3(
		_rng.randf_range(-wall_w * 0.42, wall_w * 0.42),
		_rng.randf_range(-wall_h * 0.4, wall_h * 0.4),
		_rng.randf_range(zmin, 0.22),
	)


func _refresh() -> void:
	for i in range(_small_p.size()):
		var t := Transform3D.IDENTITY
		t.origin = (_small_p[i]["pos"] as Vector3) - _origin
		_small_mm.set_instance_transform(i, t)
	for i in range(_big_p.size()):
		var bt := Transform3D.IDENTITY
		var s: float = 1.0 + sin(_t * 2.0 + float(_big_p[i]["phase"])) * 0.08
		bt.basis = Basis().scaled(Vector3(s, s, s))
		bt.origin = (_big_p[i]["pos"] as Vector3) - _origin
		_big_mm.set_instance_transform(i, bt)


func _step_particles(arr: Array, can_pass: bool) -> void:
	for i in range(arr.size()):
		var p: Dictionary = arr[i]
		var pos: Vector3 = p["pos"]
		var vel: Vector3 = p["vel"]
		pos += vel
		var local: Vector3 = pos - _origin
		# Membrane at z = _wall_z; big particles bounce, small pass.
		if not can_pass and local.z <= _wall_z + 0.02 and vel.z < 0.0:
			vel.z = absf(vel.z)
		# Wrap-around inside the tank so the demo never empties.
		if local.z < -0.24:
			local.z = 0.24
			local.x = _rng.randf_range(-wall_w * 0.42, wall_w * 0.42)
			pos = _origin + local
			vel.z = -absf(vel.z)
		if absf(local.x) > wall_w * 0.46:
			vel.x = -vel.x
		# Gentle vertical drift.
		pos.y = _origin.y + sin(_t * 1.2 + float(p["phase"])) * wall_h * 0.32
		p["pos"] = pos
		p["vel"] = vel


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_step_particles(_small_p, true)
	_step_particles(_big_p, false)
	_refresh()

# ── ASSAY ────────────────────────────────────────────────────────────────────────────────
# One axis, five values, shared word for word with mass_spring_bench,
# energy_landscape_bench, rigidity_dial_bench, abject_bench, octopus_bench and
# becoming_bench: one kit, one vocabulary, so a room of benches cannot disagree with
# itself about what a demonstration is for.
#
# THE AXIS IS ON THE APPARATUS, NEVER ON THE STARTING CONDITIONS. A soft body relaxes: five
# lattices started five different ways settle into the same slump and photograph as one
# object five times. The bench is the thing that holds still, so the bench is the thing that
# can carry a claim — and the claim is that a laboratory decides what counts as a result.
#
#   none     nothing. The specimen alone on its pillar; trust the eye. The legacy lineage.
#   gauge    a graduated column and an indicator arm reaching in — the slump gets a number.
#   control  an empty reference cage on its own plinth — the slump gets a comparison.
#   chart    a plotted board standing behind it — the slump gets a history.
#   vitrine  a glass case on posts, capped and captioned — the slump gets a canon.
#
# The same settled shape, five times over, is a curiosity, a measurement, a difference, a
# record and an exhibit. Nothing about the soft body changes between them.

const ASSAY_TOP := 0.86                        # the bench working surface, family-wide
const ASSAY_READ := Color(0.98, 0.74, 0.26)    # the instrument accent: readings and ink
const ASSAY_WIRE := Color(0.55, 0.88, 0.98)    # the reference standard's cool wire


## Where this bench puts its apparatus. The tank covers nearly the whole top, so the gauge
## stands behind it and the reference cage gets a floor stand of its own beside the bench —
## a standard is no use to anybody submerged in the medium it is meant to be compared with.
func _assay_dressing() -> void:
	var tank: float = (wall_w + 0.1) * 0.5
	match assay:
		"gauge":
			_assay_gauge(Vector3(-maxf(0.55, tank + 0.06), 0.0, -0.31), 0.52, 0.84)
		"control":
			_assay_control(Vector3(-(tank + 0.30), ASSAY_TOP, 0.0), 0.0)
		"chart":
			_assay_chart(0.90, -0.335, 0.84)
		"vitrine":
			_assay_vitrine(Vector3(0.0, ASSAY_TOP + 0.32, 0.0),
				Vector3(maxf(wall_w + 0.22, 1.06), 0.64, 0.62))
		_:
			pass                                # "none" — the legacy lineage


## GAUGE — a graduated column standing beside the bench with a cantilever indicator arm
## reaching in over the specimen and a stylus dropping onto it. The bench stops merely
## holding a shape and starts reporting a height.
func _assay_gauge(post: Vector3, reach: float, stand_y: float) -> void:
	var steel: StandardMaterial3D = _steel_mat(Color(0.42, 0.45, 0.50))
	var tick: StandardMaterial3D = _matte_mat(Color(0.88, 0.88, 0.84), 0.5)
	var read: StandardMaterial3D = _glow_mat(ASSAY_READ, 0.95)
	var top_y: float = ASSAY_TOP + 0.58
	add_child(_box(Vector3(post.x, stand_y + 0.015, post.z), Vector3(0.17, 0.03, 0.17), steel))
	add_child(_box(Vector3(post.x, (stand_y + top_y) * 0.5, post.z),
		Vector3(0.05, maxf(top_y - stand_y, 0.05), 0.05), steel))
	# Graduations up the inward face — every fifth one long and lit, the rest hairlines.
	for i in range(13):
		var ty: float = ASSAY_TOP + 0.02 + float(i) * 0.045
		var tl: float = 0.085 if (i % 5) == 0 else 0.045
		add_child(_box(Vector3(post.x + 0.025 + tl * 0.5, ty, post.z), Vector3(tl, 0.008, 0.012),
			read if (i % 5) == 0 else tick))
	# The reading itself: a collar clamped on the column, an arm out over the specimen, a
	# lit point and a stylus dropped from it.
	var ay: float = ASSAY_TOP + 0.30
	add_child(_box(Vector3(post.x, ay, post.z), Vector3(0.09, 0.06, 0.09),
		_matte_mat(Color(0.20, 0.21, 0.25), 0.6)))
	add_child(_box(Vector3(post.x + reach * 0.5 + 0.03, ay, post.z), Vector3(reach, 0.024, 0.024), read))
	add_child(_sphere(Vector3(post.x + reach + 0.03, ay, post.z), 0.028, read))
	add_child(_box(Vector3(post.x + reach + 0.03, (ay + ASSAY_TOP + 0.10) * 0.5, post.z),
		Vector3(0.012, maxf(ay - ASSAY_TOP - 0.10, 0.02), 0.012), read))
	add_child(_billboard_label("GAUGE", Vector3(post.x, top_y + 0.07, post.z), 11, ASSAY_READ))


## CONTROL — the reference the bench keeps beside the specimen: an empty cage at the size
## the body had before anything happened to it, on its own witness plinth. The settled
## shape stops being a thing and becomes a difference from something.
func _assay_control(at: Vector3, stand_y: float) -> void:
	var pale: StandardMaterial3D = _matte_mat(Color(0.80, 0.80, 0.76), 0.6)
	var wire: StandardMaterial3D = _glow_mat(ASSAY_WIRE, 0.9)
	if at.y - stand_y > 0.05:
		add_child(_box(Vector3(at.x, (stand_y + at.y) * 0.5, at.z),
			Vector3(0.07, at.y - stand_y, 0.07), _steel_mat(Color(0.38, 0.40, 0.45))))
	add_child(_box(Vector3(at.x, at.y + 0.02, at.z), Vector3(0.24, 0.04, 0.24), pale))
	# Twelve edges of an undeformed cube with nothing inside it.
	var s: float = 0.10
	var cy: float = at.y + 0.05 + s
	for sx in [-s, s]:
		for sz in [-s, s]:
			add_child(_box(Vector3(at.x + sx, cy, at.z + sz), Vector3(0.009, s * 2.0, 0.009), wire))
	for sy in [-s, s]:
		for sz in [-s, s]:
			add_child(_box(Vector3(at.x, cy + sy, at.z + sz), Vector3(s * 2.0, 0.009, 0.009), wire))
		for sx in [-s, s]:
			add_child(_box(Vector3(at.x + sx, cy + sy, at.z), Vector3(0.009, 0.009, s * 2.0), wire))
	for sx2 in [-s, s]:
		for sy2 in [-s, s]:
			for sz2 in [-s, s]:
				add_child(_sphere(Vector3(at.x + sx2, cy + sy2, at.z + sz2), 0.016, wire))
	add_child(_billboard_label("CONTROL", Vector3(at.x, cy + s + 0.09, at.z), 11, ASSAY_WIRE))


## CHART — a record board at the back of the bench carrying the settling trace: an
## oscillation that damps out onto the rest line. The bench stops showing a state and starts
## keeping a history, and what you are looking at is the END of a line that was drawn.
func _assay_chart(board_w: float, bz: float, stand_y: float) -> void:
	var board_h: float = 0.52
	var by: float = ASSAY_TOP + 0.06 + board_h * 0.5
	var frame: StandardMaterial3D = _matte_mat(Color(0.26, 0.27, 0.31), 0.7)
	var paper: StandardMaterial3D = _matte_mat(Color(0.87, 0.86, 0.81), 0.85)
	var rule: StandardMaterial3D = _matte_mat(Color(0.58, 0.58, 0.54), 0.7)
	var ink: StandardMaterial3D = _glow_mat(ASSAY_READ, 1.0)
	var foot: float = by - board_h * 0.5
	for lx in [-board_w * 0.36, board_w * 0.36]:
		add_child(_box(Vector3(lx, (stand_y + foot) * 0.5, bz),
			Vector3(0.03, maxf(foot - stand_y, 0.02), 0.03), frame))
	add_child(_box(Vector3(0.0, by, bz - 0.012), Vector3(board_w + 0.04, board_h + 0.04, 0.016), frame))
	add_child(_box(Vector3(0.0, by, bz), Vector3(board_w, board_h, 0.012), paper))
	var x0: float = -board_w * 0.42
	var x1: float = board_w * 0.42
	var y0: float = by - board_h * 0.34
	var y1: float = by + board_h * 0.34
	add_child(_box(Vector3(0.0, y0, bz + 0.009), Vector3(board_w * 0.86, 0.008, 0.006), rule))
	add_child(_box(Vector3(x0, by, bz + 0.009), Vector3(0.008, board_h * 0.70, 0.006), rule))
	for i in range(4):
		add_child(_box(Vector3(0.0, lerpf(y0, y1, float(i + 1) / 5.0), bz + 0.008),
			Vector3(board_w * 0.86, 0.003, 0.004), rule))
	# The trace is CLOSED FORM, not sampled from the running sim: a plot that came out
	# different on every launch would be noise wearing the costume of a record.
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(29):
		var f: float = float(i) / 28.0
		var v: float = exp(-3.4 * f) * cos(f * 13.0)
		pts.append(Vector3(lerpf(x0, x1, f), lerpf(y0, y1, 0.5 + v * 0.44), bz + 0.015))
	for i in range(pts.size() - 1):
		add_child(_cylinder_between(pts[i], pts[i + 1], 0.006, ink))
	add_child(_sphere(pts[pts.size() - 1], 0.015, ink))
	add_child(_billboard_label("CHART", Vector3(0.0, by + board_h * 0.5 + 0.07, bz), 11, ASSAY_READ))


## VITRINE — a case. The demonstration stops being something you can reach into and becomes
## an exhibit: glass on four posts, a capping plate, a caption on the front rail. The
## specimen goes on moving inside and can no longer be touched.
func _assay_vitrine(c: Vector3, s: Vector3) -> void:
	var post: StandardMaterial3D = _steel_mat(Color(0.30, 0.32, 0.36))
	var cap: StandardMaterial3D = _matte_mat(Color(0.20, 0.21, 0.25), 0.7)
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var y0: float = c.y - s.y * 0.5
	var y1: float = c.y + s.y * 0.5
	add_child(_box(c, s, _glass_mat(Color(0.72, 0.84, 0.95), 0.09)))
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			add_child(_box(Vector3(c.x + sx, c.y, c.z + sz), Vector3(0.034, s.y, 0.034), post))
	# Rails, not floors: a solid pan at the base would hide whatever the bench has down there.
	for yy in [y0, y1]:
		for sz2 in [-hz, hz]:
			add_child(_box(Vector3(c.x, yy, c.z + sz2), Vector3(s.x, 0.026, 0.026), post))
		for sx2 in [-hx, hx]:
			add_child(_box(Vector3(c.x + sx2, yy, c.z), Vector3(0.026, 0.026, s.z), post))
	add_child(_box(Vector3(c.x, y1 + 0.026, c.z), Vector3(s.x + 0.05, 0.03, s.z + 0.05), cap))
	add_child(_box(Vector3(c.x, y0 + 0.06, c.z + hz + 0.014), Vector3(minf(s.x * 0.5, 0.34), 0.07, 0.012),
		_matte_mat(Color(0.13, 0.14, 0.17), 0.8)))
	add_child(_billboard_label("VITRINE", Vector3(c.x, y0 + 0.06, c.z + hz + 0.035), 11,
		Color(0.90, 0.92, 0.97)))
