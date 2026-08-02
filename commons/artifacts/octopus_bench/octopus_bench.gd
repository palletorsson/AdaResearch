extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OctopusBench

## @identity
## name: "Tentacle & octopus"
## tier: medium
## lineage: A single octopus arm on a bench — a tapered chain of segments that curls and coils,
##   a sine wave running down its length, suckers along the underside. No bone anywhere; the
##   shape is the muscle and the muscle is the shape.
## truth: "DISTRIBUTED SOFT COGNITION; NO BONE — THE ARM THINKS WHERE IT TOUCHES"
## applications: soft robot arms, continuum manipulators, octopus muscular hydrostats — limbs
##   that bend anywhere because they bend everywhere.
## axis: assay — what the apparatus does with a limb that has no pose (see the ASSAY section).

@export var segments: int = 16
@export var arm_len: float = 0.9
@export var coil_rate: float = 0.5
@export var arm_col: Color = Color(0.80, 0.35, 0.55)
@export var sucker_col: Color = Color(0.95, 0.78, 0.82)
@export var bench_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## across the soft-body bench family (see the ASSAY section at the foot of this file).
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

var _t: float = 0.0
var _seg_nodes: Array = []     # MeshInstance3D per segment
var _sucker_mm: MultiMesh = null
var _base := Vector3(0.0, 0.86, -0.25)   # bench top, arm rises and reaches +Z


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("segments"):
		segments = int(clampf(float(config["segments"]), 8, 24))
	if config.has("arm_len"):
		arm_len = clampf(float(config["arm_len"]), 0.6, 1.2)
	if config.has("arm_col"):
		arm_col = _parse_color(config["arm_col"], arm_col)
	if config.has("assay"):
		var _a: String = str(config["assay"]).strip_edges().to_lower()
		assay = _a if ASSAYS.has(_a) else assay
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_seg_nodes.clear()
	_sucker_mm = null
	_build()


func _build() -> void:
	# Bench.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.2, 0.84, 0.7), _matte_mat(bench_col, 0.85)))
	# Mount stub the arm grows from.
	add_child(_cylinder(Vector3(_base.x, _base.y + 0.02, _base.z), 0.07, 0.06, _steel_mat(Color(0.4, 0.4, 0.45))))

	var arm_mat := _glow_mat(arm_col, 0.4)
	# Build tapered segments as spheres; positions set each frame.
	for i in range(segments):
		var f: float = float(i) / float(segments - 1)
		var r: float = lerpf(0.06, 0.012, f)   # tapers to a tip
		var seg := _sphere(Vector3.ZERO, r, arm_mat)
		add_child(seg)
		_seg_nodes.append(seg)

	# Suckers: one MultiMesh, two per segment along the underside.
	var n: int = segments * 2
	_sucker_mm = MultiMesh.new()
	_sucker_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 1.4
	sm.radial_segments = 6
	sm.rings = 3
	_sucker_mm.mesh = sm
	_sucker_mm.instance_count = n
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _sucker_mm
	smi.material_override = _glow_mat(sucker_col, 0.6)
	add_child(smi)

	_update_arm(0.0)

	add_child(_billboard_label("DISTRIBUTED SOFT COGNITION; NO BONE", Vector3(0.0, 1.6, 0.0), 17, label_col))

	# ASSAY apparatus, appended LAST so every child index and position above is untouched
	# on the legacy path. "none" falls through and adds nothing at all.
	_assay_dressing()


func _arm_point(f: float, tt: float) -> Vector3:
	# f in [0,1] along the arm. A sine running down the length curls it; the whole arm
	# also coils gently in Z over time.
	var along: float = f * arm_len
	var bend: float = sin(f * PI * 2.2 - tt * TAU * coil_rate) * (0.18 + f * 0.22)
	var rise: float = sin(f * PI) * 0.25 + f * 0.15
	var sway: float = cos(f * PI * 1.5 - tt * coil_rate) * f * 0.12
	return _base + Vector3(bend + sway, rise, along)


func _update_arm(tt: float) -> void:
	for i in range(_seg_nodes.size()):
		var f: float = float(i) / float(segments - 1)
		var seg: MeshInstance3D = _seg_nodes[i]
		seg.position = _arm_point(f, tt)
	# Place suckers just beneath each segment, facing down.
	if _sucker_mm != null:
		for i in range(segments):
			var f2: float = float(i) / float(segments - 1)
			var p: Vector3 = _arm_point(f2, tt)
			var rr: float = lerpf(0.018, 0.005, f2)
			for k in range(2):
				var idx: int = i * 2 + k
				var offx: float = (-0.02 if k == 0 else 0.02) * (1.0 - f2)
				var pos := p + Vector3(offx, -lerpf(0.05, 0.012, f2), 0.0)
				_sucker_mm.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3(rr, rr * 0.6, rr)), pos))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_update_arm(_t)

# ── ASSAY ────────────────────────────────────────────────────────────────────────────────
# One axis, five values, shared word for word with mass_spring_bench,
# energy_landscape_bench, membrane_bench, rigidity_dial_bench, abject_bench and
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


## Where this bench puts its apparatus. The arm reaches a long way in +Z, so the gauge and
## the reference cage both keep to the back half; the case is sized to the bench and the
## arm's last third goes through the glass, which is the one thing this specimen was always
## going to do.
func _assay_dressing() -> void:
	match assay:
		"gauge":
			_assay_gauge(Vector3(-0.53, 0.0, -0.28), 0.50, 0.84)
		"control":
			_assay_control(Vector3(0.46, ASSAY_TOP, -0.24), 0.84)
		"chart":
			_assay_chart(0.90, -0.335, 0.84)
		"vitrine":
			_assay_vitrine(Vector3(0.0, ASSAY_TOP + 0.33, 0.0), Vector3(1.10, 0.66, 0.64))
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
