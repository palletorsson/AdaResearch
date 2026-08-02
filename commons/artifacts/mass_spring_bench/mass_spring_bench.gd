extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MassSpringBench

## @identity
## name: "Mass-spring networks"
## tier: medium
## lineage: the lattice from the toy — a whole grid of Hooke springs, no shape authored
## essence: A bench-top grid of masses and springs, ~0.6m of jelly, sitting on a pillar.
##   Nobody modelled its form. We placed nodes on a lattice, wired each to its neighbours,
##   and let gravity and the springs argue. The shape it settles into — the slump, the bulge —
##   is what the network agrees on. The springs are drawn as thin wires so you see the net.
## truth: "NOBODY MODELLED THIS SHAPE — THE SPRINGS DID" — form emerges from the lattice
## applications: cloth, soft robots, deformable props — model the connections, not the surface.
## axis: assay — what the apparatus does with a shape nobody specified (see the ASSAY section).

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var nx: int = 4
@export var ny: int = 3
@export var nz: int = 4
@export var cell: float = 0.16
@export var stiffness: float = 0.6
@export var pre_steps: int = 80
@export var body_col: Color = Color(0.92, 0.45, 0.58)
@export var wire_col: Color = Color(0.30, 0.85, 0.95)
@export var base_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## across the soft-body bench family (see the ASSAY section at the foot of this file).
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## Seed for the tiny asymmetric tilt below, which decides WHICH WAY the lattice slumps.
## -1 randomizes exactly as this bench always has, so the default lineage is unchanged; any
## value >= 0 makes the settled shape reproducible, which is the precondition for a sweep
## measuring an axis rather than measuring the tilt.
@export var seed_value: int = -1

var _t: float = 0.0
var _sway: Node3D = null


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
	if config.has("nx"):
		nx = clampi(int(config["nx"]), 2, 6)
	if config.has("ny"):
		ny = clampi(int(config["ny"]), 2, 5)
	if config.has("nz"):
		nz = clampi(int(config["nz"]), 2, 6)
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.2, 0.95)
	if config.has("body_col"):
		body_col = _parse_color(config["body_col"], body_col)
	if config.has("wire_col"):
		wire_col = _parse_color(config["wire_col"], wire_col)
	if config.has("assay"):
		var _a: String = str(config["assay"]).strip_edges().to_lower()
		assay = _a if ASSAYS.has(_a) else assay
	if config.has("seed_value"):
		seed_value = int(config["seed_value"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	if seed_value >= 0:
		_rng.seed = seed_value
	_build()


func _build() -> void:
	# Bench base + pillar (medium tier staging)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(base_col, 0.85)))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.5, _steel_mat(Color(0.34, 0.36, 0.40))))
	# A thin tray the jelly rests on
	add_child(_box(Vector3(0.0, 0.84, 0.0), Vector3(nx * cell + 0.2, 0.02, nz * cell + 0.2), _matte_mat(Color(0.22, 0.23, 0.27), 0.7)))

	var sway := Node3D.new()
	sway.name = "JellySway"
	add_child(sway)
	_sway = sway

	# Build a jelly lattice and let it settle — the shape nobody specified.
	var sim = SBShapes.make_jelly_grid(nx, ny, nz, cell, stiffness)
	# Rest it on the tray, not on the engine's far-down floor.
	sim.floor_y = 0.0
	sim.gravity = Vector3(0.0, -4.5, 0.0)
	sim.damping = 0.985
	# Give a tiny asymmetric tilt so it slumps to one side — visible disagreement.
	for i in sim.positions.size():
		sim.positions[i] += Vector3(_rng.randf_range(-0.01, 0.01), 0.0, _rng.randf_range(-0.01, 0.01))
		sim.prev_positions[i] = sim.positions[i]
	for _i in pre_steps:
		sim.step()

	# Snapshot node: spheres at masses + thin wires along springs (show the net).
	var node: Node3D = SBShapes.to_node3d(sim, {
		"color": [body_col.r, body_col.g, body_col.b],
		"show_wires": true,
		"wire_color": [wire_col.r, wire_col.g, wire_col.b],
		"particle_radius": 0.03,
		"roughness": 0.45,
	})
	# Lift the settled body up onto the tray surface.
	node.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(node)

	add_child(_billboard_label("NOBODY MODELLED THIS SHAPE — THE SPRINGS DID", Vector3(0.0, 1.6, 0.0), 22, label_col))

	# ASSAY apparatus, appended LAST so every child index and position above is untouched
	# on the legacy path. "none" falls through and adds nothing at all.
	_assay_dressing()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.35) * 0.14


# ── ASSAY ────────────────────────────────────────────────────────────────────────────────
# One axis, five values, shared word for word with energy_landscape_bench,
# membrane_bench, rigidity_dial_bench, abject_bench, octopus_bench and becoming_bench:
# one kit, one vocabulary, so a room of benches cannot disagree with itself about what a
# demonstration is for.
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


## Where this bench puts its apparatus. Each member of the family answers this differently
## because each has a different top: a pillar with a tray, or a solid box.
func _assay_dressing() -> void:
	match assay:
		"gauge":
			_assay_gauge(Vector3(-0.46, 0.0, -0.26), 0.52, 0.20)
		"control":
			_assay_control(Vector3(0.40, ASSAY_TOP, 0.0), 0.20)
		"chart":
			_assay_chart(0.86, -0.335, 0.20)
		"vitrine":
			_assay_vitrine(Vector3(0.0, ASSAY_TOP + 0.33, 0.0), Vector3(0.82, 0.66, 0.82))
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
