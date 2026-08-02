extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BecomingBench

## @identity
## name: "Matter that finds its shape"
## tier: medium
## lineage: A bench where a field of particles settles from disorder into an organized body. They
##   start as a roiling cloud above the tray, then fall into the silhouette of a creature — a head,
##   a spine, two limbs — hold it, then scatter and re-form. Entropy, on its way to morphology.
## truth: "ENTROPY BECOMING MORPHOLOGY — A CLOUD OF NOISE SETTLES INTO A LIVING SHAPE"
## applications: morphogenesis, self-assembly, simulated annealing, reaction-diffusion patterning —
##   the descent from high-entropy disorder to low-entropy organized form.
## axis: assay — what the apparatus does with a form that assembled itself (see ASSAY below).

const N: int = 260

@export var bench_w: float = 1.3
@export var form_col: Color = Color(0.60, 0.92, 0.75)
@export var noise_col: Color = Color(0.55, 0.58, 0.92)
@export var bench_col: Color = Color(0.16, 0.17, 0.20)
@export var tray_col: Color = Color(0.10, 0.30, 0.28)
@export var label_col: Color = Color(0.92, 0.97, 0.95)
@export var cycle_rate: float = 0.12

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## across the soft-body bench family (see the ASSAY section at the foot of this file).
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## Seed for the 260-particle noise cloud AND for the scatter inside each body part of the
## creature it settles into — every visible dot on this bench comes off this stream. -1
## randomizes exactly as it always has; any value >= 0 makes the cloud reproducible, without
## which five variants are five different creatures and the sweep measures the weather.
@export var seed_value: int = -1

var _t: float = 0.0
var _mm: MultiMesh = null
var _mi: MultiMeshInstance3D = null
var _targets: Array = []     # creature-silhouette positions
var _noise: Array = []       # scattered cloud positions
var _origin := Vector3(0.0, 1.1, 0.0)
var _top: float = 0.86


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
	if config.has("bench_w"):
		bench_w = clampf(float(config["bench_w"]), 0.9, 1.8)
	if config.has("form_col"):
		form_col = _parse_color(config["form_col"], form_col)
	if config.has("assay"):
		var _a: String = str(config["assay"]).strip_edges().to_lower()
		assay = _a if ASSAYS.has(_a) else assay
	if config.has("seed_value"):
		seed_value = int(config["seed_value"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mm = null
	_mi = null
	_targets.clear()
	_noise.clear()
	if seed_value >= 0:
		_rng.seed = seed_value
	_build()


func _build() -> void:
	# Bench + tray.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(bench_w + 0.2, 0.84, 0.6), _matte_mat(bench_col, 0.85)))
	add_child(_box(Vector3(0.0, _top, 0.0), Vector3(bench_w * 0.85, 0.04, 0.45), _glow_mat(tray_col, 0.25)))
	_origin = Vector3(0.0, _top + 0.45, 0.0)

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 3
	_mm.mesh = sm
	_mm.instance_count = N
	_mi = MultiMeshInstance3D.new()
	_mi.multimesh = _mm
	_mi.material_override = _glow_mat(form_col, 0.7)
	add_child(_mi)

	# Build the ORDERED target: a small creature silhouette facing +Z.
	_build_creature_targets()
	# Scatter the NOISE positions in a cloud over the tray.
	for i in range(N):
		_noise.append(_origin + Vector3(
			_rng.randf_range(-bench_w * 0.4, bench_w * 0.4),
			_rng.randf_range(-0.05, 0.45),
			_rng.randf_range(-0.2, 0.2),
		))
	_refresh(0.0)

	add_child(_billboard_label("ENTROPY BECOMING MORPHOLOGY", Vector3(0.0, 1.6, 0.0), 17, label_col))

	# ASSAY apparatus, appended LAST so every child index and position above is untouched
	# on the legacy path. "none" falls through and adds nothing at all.
	_assay_dressing()


func _build_creature_targets() -> void:
	# Distribute N particles across body parts so the cloud reads as a creature.
	var parts := [
		{ "c": Vector3(0.0, 0.18, 0.0), "r": 0.22, "w": 90 },     # body
		{ "c": Vector3(0.0, 0.42, 0.06), "r": 0.13, "w": 55 },    # head
		{ "c": Vector3(-0.26, 0.05, 0.0), "r": 0.10, "w": 35 },   # left limb
		{ "c": Vector3(0.26, 0.05, 0.0), "r": 0.10, "w": 35 },    # right limb
		{ "c": Vector3(0.0, 0.55, 0.10), "r": 0.05, "w": 18 },    # crest
		{ "c": Vector3(0.0, -0.05, -0.10), "r": 0.08, "w": 27 },  # tail nub
	]
	var idx: int = 0
	for part in parts:
		var c: Vector3 = part["c"]
		var r: float = part["r"]
		var w: int = part["w"]
		for j in range(w):
			if idx >= N:
				break
			var dir := Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
			).normalized()
			var rr: float = pow(_rng.randf(), 0.5) * r
			_targets.append(_origin + c + dir * rr)
			idx += 1
	# Pad any remainder onto the body centre.
	while _targets.size() < N:
		_targets.append(_origin + Vector3(0.0, 0.18, 0.0) + Vector3(
			_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2)))


func _refresh(order: float) -> void:
	if _mm == null:
		return
	var stud: float = 0.016
	for i in range(N):
		var noise: Vector3 = _noise[i]
		var target: Vector3 = _targets[i]
		var jit := Vector3(
			sin(_t * 1.5 + float(i) * 0.9),
			cos(_t * 1.2 + float(i) * 0.6),
			sin(_t * 1.8 + float(i) * 1.3),
		) * 0.03 * (1.0 - order)
		var p: Vector3 = noise.lerp(target, order) + jit
		_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(stud, stud, stud)), p))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Settle 0 -> 1 (disorder -> creature), hold, then scatter back.
	var raw: float = sin(_t * TAU * cycle_rate) * 0.5 + 0.5
	var order: float = smoothstep(0.15, 0.85, raw)
	_refresh(order)
	if _mi != null:
		_mi.material_override = _glow_mat(noise_col.lerp(form_col, order), 0.7)

# ── ASSAY ────────────────────────────────────────────────────────────────────────────────
# One axis, five values, shared word for word with mass_spring_bench,
# energy_landscape_bench, membrane_bench, rigidity_dial_bench, abject_bench and
# octopus_bench: one kit, one vocabulary, so a room of benches cannot disagree with
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


## Where this bench puts its apparatus. The particle cloud stands tall above the tray, so the
## case is a tall one — it has to reach y ≈ 1.9 to hold the creature at full assembly.
func _assay_dressing() -> void:
	var hw: float = (bench_w + 0.2) * 0.5
	match assay:
		"gauge":
			_assay_gauge(Vector3(-hw + 0.07, 0.0, -0.22), hw - 0.17, 0.84)
		"control":
			_assay_control(Vector3(hw - 0.09, ASSAY_TOP, 0.0), 0.84)
		"chart":
			_assay_chart(minf(hw * 1.36, 1.06), -0.285, 0.84)
		"vitrine":
			_assay_vitrine(Vector3(0.0, ASSAY_TOP + 0.53, 0.0), Vector3(hw * 1.65, 1.06, 0.58))
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
