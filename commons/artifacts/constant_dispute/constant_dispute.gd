extends Node3D
class_name ConstantDispute

## constant_dispute — the two sliders share one vocabulary for two different SHAPES of
## claim, and three of its five words mean different things on each.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## THE BRIEF'S SUSPICION, AND WHY IT IS WRONG AT THE PREMISE.
##
## The brief expected phi_slider to be the golden ratio — (1+sqrt 5)/2, a THEOREM, exact,
## with no measurement, therefore no band, no dispute, no gap — against a lambda that is
## empirical or free. It is not. phi_slider.gd:1-6 is QFEP's phi, the rate-of-entropy-
## change sensitivity: phi < 0 resists change, phi > 0 embraces it. Both members are free
## parameters of ONE invented formula. Neither is derived, neither is measured, neither
## has an error bar anywhere in the repository. On the epistemic question the brief asked,
## the two are the SAME KIND of object and the shared vocabulary is coherent.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## BUT THE INCOMPATIBILITY IS REAL. IT IS GEOMETRIC, AND IT IS ALSO THREE VALUES OF FIVE.
##
## lambda's recommendation is a BOUNDED INTERVAL with both ends interior to its scale:
## is_at_edge() (lambda_slider.gd:887-888) returns lambda >= 0.3 and lambda <= 0.5, and
## the constants at :110-111 are those two numbers.
##
## phi's recommendation is a HALF-LINE whose far end IS the end of the scale:
## has_queer_signature() (phi_slider.gd:588-589) returns phi > 0.2, one-sided, and
## phi_slider.gd:82 converts it to t = 0.60 with an upper bound of 1.0 supplied by the
## rail rather than by the claim.
##
## That difference is not decoration. It changes what three of the five shared words do:
##
##   band     lambda_slider.gd:817-820 draws a bracket at `lo` AND at `hi`, unconditionally.
##            For lambda both brackets are thresholds. For phi, hi = 1.0
##            (phi_slider.gd:395), so the second bracket marks THE END OF THE INSTRUMENT
##            and is drawn identically to one that marks a fact. A band with one real edge
##            is a threshold wearing a tolerance's clothes.
##   gap      lambda_slider.gd:779-782 builds the plate as the spans either side of the
##            recommended region: `if lo > 0.002` and `if hi < 0.998`. For phi the second
##            test is FALSE, so phi's gap plate is a single truncated piece where
##            lambda's is two pieces around a hole. One value, two topologies — a scale
##            with a hole in it and a scale that is simply shorter are not the same claim,
##            and a shorter plate is indistinguishable from a smaller instrument.
##   dispute  lambda_slider.gd:506 flags CALIB_LO, CALIB_APEX, CALIB_HI = 0.30, 0.40, 0.50.
##            Two of those three "schools" ARE band's own two brackets (:501-502) and the
##            third is the shipped default (:83). All three lie INSIDE lambda's own band,
##            so lambda's dispute cannot disagree with lambda's band; it is one interval
##            redrawn with a tick in the middle. phi's three (phi_slider.gd:349, constants
##            at :82-85) come from three different functions, and one of them — neutral,
##            t = 0.5 — lies OUTSIDE phi's own band and denies it.
##
## Only `optimum` and `none` behave alike on both. Three of five is the same headline the
## brief predicted, arrived at by the opposite mechanism.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## THE THING THE READING TURNED UP THAT NOBODY WAS LOOKING FOR.
##
## inscribe_scale_plate's dispute branch (lambda_slider.gd:826-841) divides the plate
## between the schools at the MIDPOINTS between adjacent marks, with the outer territories
## running to the plate's ends, under a comment that says "three territories at equal
## strength, so the plate shows the disagreement rather than resolving it" (:823-825).
## The arithmetic does not do that.
##
##   lambda  marks 0.30 / 0.40 / 0.50  ->  edges 0, 0.35, 0.45, 1.0
##           territories 35% / 10% / 55%.  The SHIPPED DEFAULT gets the smallest
##           territory on the board, one fifth of the school at 0.5.
##   phi     marks 0.50 / 0.65 / 0.875  ->  edges 0, 0.575, 0.7625, 1.0
##           territories 57.5% / 18.75% / 23.75%.  The NEUTRAL school takes the majority
##           of the plate — the position phi_slider.gd:46's truth line exists to argue
##           against ("positive phi means the system does not merely tolerate change but
##           seeks it as generative").
##
## A plate built to show that no school dominates hands the largest territory to whichever
## school sits nearest an end, because an unbounded scale has no natural outer edge for a
## claim to stop at. That is the interval-versus-half-line problem again, one level down.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## WHAT THIS BENCH IS.
##
## A calibration board, yawed 0.62 rad so it faces capture_config_sweep's standpoint
## square (capture_config_sweep.gd:69 YAW := 0.62, :443 builds the camera direction as
## Vector3(sin yaw cos pitch, -sin pitch, cos yaw cos pitch), whose horizontal bearing is
## atan2(sin 0.62, cos 0.62) = 0.62 exactly). It costs only the 15 degree pitch,
## cos(0.26) = 0.966390 of the height.
##
## TWO STRIPS, ONE SCALE, TWENTY CELLS.
##
##   claim   THE SHAPE OF WHAT THE SCALE RECOMMENDS — the upper strip. Not how the mark is
##           styled: the topology of the recommended SET on [0,1], classified by how many
##           components it has and how many of its boundaries are interior to the scale.
##             interval   one component, two interior boundaries   lambda's [0.30, 0.50]
##             threshold  one component, ONE interior boundary,    phi's [0.60, end]
##                        the other end supplied by the rail
##             point      one component, measure zero              lambda's default 0.40
##             rival      TWO components, no arbiter               0.40 and 0.65, each at
##                        +-0.05, the half-spacing lambda's own dispute territories use
##             absent     empty
##           No value here is the union of the others. `rival` contains a point-claim's
##           position but its second component is in no other value's set; the union
##           check was run because wave 20 found six all-rungs values in the corpus.
##
##   record  WHAT THE INSTRUMENT SHOWS OF THE MEASUREMENTS BEHIND THE CLAIM — the lower
##           strip, 20 bins by 27 levels, and NEITHER SOURCE HAS ONE. lambda_slider and
##           phi_slider draw a recommendation and no evidence for it whatsoever; `bare` is
##           not a neutral starting cell, it is the family's complete behaviour on this
##           question, which is why it is the default.
##             bare    nothing. The claim with no support shown.
##             count   histogram: each bin's column rises from the baseline, scaled so the
##                     fullest bin reaches the top.
##             spread  the same heights, CENTRED on the strip's mid-line — a silhouette,
##                     not a skyline.
##             drift   one cell per trial at (its bin, its epoch), so the vertical axis is
##                     WHEN rather than HOW MANY.
##           The 270 trials are generated from the claim: a claim's shape is supposed to
##           be readable from the measurements it was read out of, and when it is not, the
##           instrument is asserting something the evidence does not carry.
##
## THE SHEET'S THESIS, and it is the sentence neither source can say: at claim = point the
## trial spread is exactly zero, every trial lands in one bin, and count, spread and drift
## draw THE SAME PICTURE to the byte. The three ways of showing evidence differ only
## because there is disagreement to show. A marking vocabulary — optimum, band, dispute,
## gap, none — has content only where the measurements have width, and a family whose
## instruments record no measurements at all can never find that out.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## INSTRUMENT DECISIONS, EACH COSTING SOMETHING.
##
## (1) EVERY FACE MARK IS UNSHADED AND CASTS NO SHADOW. The axis is a geometry axis; under
##     the rig's key light a measured difference between two claim shapes would be partly
##     a fact about the light, and a 3 mm plate's contact shadow carries no information
##     about a recommendation. The board and feet stay lit so the object keeps a body.
##     This is what makes the prediction below computable rather than estimated.
## (2) EVERY RECORD DRAWING IS BUILT FROM THE SAME UNIT CELL by the same helper. Drawing
##     count's column as ONE tall box would have put N-1 fewer coplanar seams in it than
##     spread's stack and destroyed the designed null, which is an identity between three
##     drawings and not merely between three areas.
## (3) THE WORLD BOX IS A CONSTANT. Board and feet set it; every mark lies inside their
##     silhouette in x and inside their depth in z (checked: the outermost post, at t = 1.0
##     and z = 0.031, rotates to |x| = 0.4341 and |z| = 0.2742 against the board's 0.4703
##     and the feet's 0.3463). So the camera never moves and no measured pair carries a
##     framing difference it did not earn.
## (4) NO NUMERIC VALUE IN EITHER AXIS. Both are word enums typed String, so
##     cabinet_sweep.coerce() has nothing to numericise and the tier_terrarium failure —
##     Object.set() refusing a typed property in silence — cannot occur. Checked, not
##     assumed.
## (5) THE ONE RANDOM DRAW IS SEEDED. `trial_seed` is an export pinned by dna.fixture, and
##     at claim = point no draw is taken at all, so the null does not depend on it.
##
## @identity
## essence: recommended_set -> lit cells on a 20 cell scale; trials -> 20 x 27 evidence lattice
## desire: see whether the claim's shape is readable from the measurements under it
## critical_parameter: claim — the topology of the recommended set, which decides what the marking words can mean
## triggers: claim / record exports, or a map token constant_dispute#claim:rival
## emerges: at point the three evidence drawings collapse into one image
## needs: two sources' regions [has], seeded trials [has], unshaded marks [has], constant world box [has]
## relationships: synthesis of lambda_slider and phi_slider; kin to qfep_reactor's readout ladder
## truth: an instrument that shows a recommendation and no measurements has hidden the only thing that could contradict it

# ── THE TWO AXES ──────────────────────────────────────────────────────────────────────

## THE SHAPE OF WHAT THE SCALE RECOMMENDS. `interval` is lambda_slider's own claim and the
## default: the source pair's primary member recommends a bounded interior interval, and
## every other value here is a step away from that.
@export_enum("interval", "threshold", "point", "rival", "absent") var claim: String = "interval":
	set(v):
		claim = v
		if _built:
			_rebuild()

## WHAT THE INSTRUMENT SHOWS OF THE MEASUREMENTS BEHIND THE CLAIM. `bare` is the default
## because it is the source family's complete behaviour: neither slider records anything.
@export_enum("bare", "count", "spread", "drift") var record: String = "bare":
	set(v):
		record = v
		if _built:
			_rebuild()

## The only randomness in the artifact. Pinned by dna.fixture so a sweep is reproducible;
## at claim = point it is never consulted.
@export var trial_seed: int = 4021:
	set(v):
		trial_seed = v
		if _built:
			_rebuild()

# ── BODY ──────────────────────────────────────────────────────────────────────────────

const BOARD_SIZE := Vector3(1.120, 0.660, 0.050)
const FOOT_SIZE := Vector3(0.140, 0.090, 0.180)
const FOOT_X := 0.400
const BOARD_Y := 0.420          ## FOOT_SIZE.y + BOARD_SIZE.y * 0.5
const FACE_Z := 0.025           ## BOARD_SIZE.z * 0.5
const BOARD_YAW := 0.62         ## capture_config_sweep.gd:69

# ── THE SCALE ─────────────────────────────────────────────────────────────────────────

const SPAN := 1.000             ## the scale's width in metres; t = 0 at -0.5, t = 1 at +0.5
const CELLS := 20               ## the scale's RESOLUTION, and the reason point is not nothing
const PITCH := 0.050
const CELL_W := 0.046
const CLAIM_H := 0.170
const CLAIM_Y := 0.105
const POST_W := 0.014
const POST_H := 0.070
const POST_Y := 0.227
const RULE_Y := -0.010
const RULE_H := 0.010
const REC_BOT := -0.300
const REC_H := 0.270
const LEVELS := 27
const LEVEL_H := 0.010          ## REC_H / LEVELS, exactly
const TRIALS := 270             ## LEVELS * 10, so drift tiles every level exactly

const Z_MARK := 0.029
const T_MARK := 0.008
const Z_POST := 0.031
const T_POST := 0.012

# ── COLOURS, READ VERBATIM FROM THE SOURCES ───────────────────────────────────────────

const COLOR_EDGE := Color(0.2, 0.9, 0.4)          ## lambda_slider.gd:184  the claimed ground
const COLOR_EMBRACE := Color(1.0, 0.8, 0.2)       ## phi_slider.gd:136     the boundary posts
const CALIB_NEUTRAL := Color(0.50, 0.51, 0.53)    ## lambda_slider.gd:113, phi_slider.gd:86
const CALIB_PLATE := Color(0.14, 0.15, 0.17)      ## lambda_slider.gd:114, phi_slider.gd:87

# ── REGIONS, READ OUT OF THE SOURCES, NEVER INVENTED ──────────────────────────────────

const LAMBDA_LO := 0.30         ## lambda_slider.gd:110 — is_at_edge() lower bound
const LAMBDA_HI := 0.50         ## lambda_slider.gd:111 — is_at_edge() upper bound
const LAMBDA_APEX := 0.40       ## lambda_slider.gd:112 and :83, the shipped default
const PHI_QUEER := 0.60         ## phi_slider.gd:82 — has_queer_signature(), phi > 0.2
const PHI_APEX := 0.65          ## phi_slider.gd:83 — the shipped default phi = 0.3
## Half the spacing between lambda's three schools (0.30 / 0.40 / 0.50), which is exactly
## the half-width inscribe_scale_plate's dispute branch gives the middle territory when it
## bisects between adjacent marks (lambda_slider.gd:828-830).
const SCHOOL_HALF := 0.05

# ── STATE ─────────────────────────────────────────────────────────────────────────────

var _built: bool = false
var _root: Node3D = null
var _unit: BoxMesh = null
var _mat_lit: StandardMaterial3D = null
var _mat_dead: StandardMaterial3D = null
var _mat_post: StandardMaterial3D = null
var _mat_evid: StandardMaterial3D = null
var _mat_rule: StandardMaterial3D = null
var _bins: PackedInt32Array = PackedInt32Array()
var _trial_bin: PackedInt32Array = PackedInt32Array()


func _ready() -> void:
	_build()
	_built = true


## MAP CONFIG — `constant_dispute#claim:rival#record:drift`. GridInteractablesComponent
## calls this deferred, after _ready() has already built one lineage, so anything that
## changes has to tear the board down and build again. A key we do not own changes nothing.
func apply_grid_config(config_data: Dictionary) -> void:
	var touched: bool = false
	if config_data.has("claim"):
		var c: String = str(config_data["claim"]).to_lower().strip_edges()
		if c in ["interval", "threshold", "point", "rival", "absent"] and c != claim:
			claim = c
			touched = true
	if config_data.has("record"):
		var r: String = str(config_data["record"]).to_lower().strip_edges()
		if r in ["bare", "count", "spread", "drift"] and r != record:
			record = r
			touched = true
	if touched:
		print("ConstantDispute: claim=%s record=%s" % [claim, record])


func _rebuild() -> void:
	if _root != null and is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = null
	_build()


# ── BUILD ─────────────────────────────────────────────────────────────────────────────

func _build() -> void:
	_make_materials()
	_build_trials()

	_root = Node3D.new()
	_root.name = "Board"
	_root.rotation = Vector3(0.0, BOARD_YAW, 0.0)
	add_child(_root)

	_body()

	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, BOARD_Y, 0.0)
	_root.add_child(face)

	_build_claim_strip(face)
	_build_rule(face)
	_build_record(face)
	_build_readout(face)


func _make_materials() -> void:
	_unit = BoxMesh.new()
	_unit.size = Vector3.ONE
	_mat_lit = _flat(COLOR_EDGE)
	_mat_dead = _flat(CALIB_PLATE.lightened(0.06))
	_mat_post = _flat(COLOR_EMBRACE)
	_mat_evid = _flat(CALIB_NEUTRAL.lightened(0.30))
	_mat_rule = _flat(CALIB_NEUTRAL.darkened(0.10))


## Unshaded, no shadow. See instrument decision (1) in the header.
func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _body() -> void:
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.19, 0.20, 0.23)
	shell.metallic = 0.20
	shell.roughness = 0.62

	var board := MeshInstance3D.new()
	board.name = "Panel"
	board.mesh = _unit
	board.scale = BOARD_SIZE
	board.position = Vector3(0.0, BOARD_Y, 0.0)
	board.material_override = shell
	_root.add_child(board)

	for sx in [-1.0, 1.0]:
		var foot := MeshInstance3D.new()
		foot.mesh = _unit
		foot.scale = FOOT_SIZE
		foot.position = Vector3(float(sx) * FOOT_X, FOOT_SIZE.y * 0.5, 0.0)
		foot.material_override = shell
		_root.add_child(foot)


# ── THE CLAIM ─────────────────────────────────────────────────────────────────────────

## The recommended set, as a list of [lo, hi] in t. A degenerate span (lo == hi) is a
## point claim; an empty list is no recommendation at all.
func _claim_spans() -> Array:
	match claim:
		"threshold":
			return [[PHI_QUEER, 1.0]]
		"point":
			return [[LAMBDA_APEX, LAMBDA_APEX]]
		"rival":
			return [[LAMBDA_APEX - SCHOOL_HALF, LAMBDA_APEX + SCHOOL_HALF],
					[PHI_APEX - SCHOOL_HALF, PHI_APEX + SCHOOL_HALF]]
		"absent":
			return []
		_:
			return [[LAMBDA_LO, LAMBDA_HI]]


## Every cell the recommended set touches. A point claim lights ONE cell, because a scale
## cannot draw a set narrower than its own resolution — which is the whole argument for
## keeping `point` and `absent` one cell apart rather than nothing apart.
func _lit_cells() -> Dictionary:
	var out: Dictionary = {}
	for sp in _claim_spans():
		var lo: float = float(sp[0])
		var hi: float = float(sp[1])
		var a: int = int(floor(lo * float(CELLS) + 0.000001))
		var b: int = a
		if hi > lo:
			b = int(ceil(hi * float(CELLS) - 0.000001)) - 1
		a = clampi(a, 0, CELLS - 1)
		b = clampi(b, 0, CELLS - 1)
		for i in range(a, b + 1):
			out[i] = true
	return out


## The boundaries of the recommended set. A degenerate span has one; every other span has
## two — INCLUDING the one at t = 1.0 under `threshold`, drawn exactly like a real
## threshold, because lambda_slider.gd:817 draws it exactly like a real threshold and that
## is the thing this bench is here to photograph.
func _claim_posts() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for sp in _claim_spans():
		var lo: float = float(sp[0])
		var hi: float = float(sp[1])
		out.append(lo)
		if hi > lo:
			out.append(hi)
	return out


func _build_claim_strip(face: Node3D) -> void:
	var lit: Dictionary = _lit_cells()
	for i in range(CELLS):
		var m: StandardMaterial3D = _mat_lit if lit.has(i) else _mat_dead
		_mark(face, Vector3(_cell_x(i), CLAIM_Y, Z_MARK),
			Vector3(CELL_W, CLAIM_H, T_MARK), m)
	for t in _claim_posts():
		_mark(face, Vector3(_t_x(float(t)), POST_Y, Z_POST),
			Vector3(POST_W, POST_H, T_POST), _mat_post)


## The datum the whole scale is read against. Constant in all twenty cells of the sheet, so
## its contrast against each strip is free evidence.
func _build_rule(face: Node3D) -> void:
	_mark(face, Vector3(0.0, RULE_Y, Z_MARK), Vector3(SPAN, RULE_H, T_MARK), _mat_rule)


# ── THE RECORD ────────────────────────────────────────────────────────────────────────

## The trials are the measurements the claim was read out of, so their shape is set BY the
## claim. At `point` the spread is exactly zero and no draw is taken, which is what makes
## the designed null seed-independent.
func _build_trials() -> void:
	_bins.resize(CELLS)
	_bins.fill(0)
	_trial_bin.resize(TRIALS)
	var rng := RandomNumberGenerator.new()
	rng.seed = trial_seed
	for k in range(TRIALS):
		var x: float = 0.0
		match claim:
			"point":
				x = LAMBDA_APEX
			"threshold":
				x = PHI_QUEER + (1.0 - PHI_QUEER) * pow(rng.randf(), 0.75)
			"rival":
				if k % 2 == 0:
					x = rng.randfn(LAMBDA_APEX, SCHOOL_HALF * 0.5)
				else:
					x = rng.randfn(PHI_APEX, SCHOOL_HALF * 0.5)
			"absent":
				x = rng.randf()
			_:
				x = rng.randfn(LAMBDA_APEX, SCHOOL_HALF)
		x = clampf(x, 0.0, 0.9999)
		var b: int = clampi(int(x * float(CELLS)), 0, CELLS - 1)
		_trial_bin[k] = b
		_bins[b] += 1


func _build_record(face: Node3D) -> void:
	if record == "bare":
		return
	var n_max: int = 1
	for b in range(CELLS):
		n_max = maxi(n_max, _bins[b])

	## Keyed by (bin, level) so no drawing can ever place two cells in one slot — which is
	## what makes drift's 270 trials resolve to the same 27 boxes count and spread build.
	var slots: Dictionary = {}
	if record == "drift":
		for k in range(TRIALS):
			var lvl: int = floori(float(k * LEVELS) / float(TRIALS))
			slots[Vector2i(_trial_bin[k], lvl)] = true
	else:
		for b2 in range(CELLS):
			var hgt: int = int(round(float(LEVELS) * float(_bins[b2]) / float(n_max)))
			if hgt <= 0:
				continue
			var base: int = 0
			if record == "spread":
				base = floori(float(LEVELS - hgt) * 0.5)
			for l in range(hgt):
				slots[Vector2i(b2, base + l)] = true

	for key in slots.keys():
		var kk: Vector2i = key
		_mark(face, Vector3(_cell_x(kk.x), _level_y(kk.y), Z_MARK),
			Vector3(CELL_W, LEVEL_H, T_MARK), _mat_evid)


# ── THE READOUT ───────────────────────────────────────────────────────────────────────

## A NUMBER IS PHOTOGRAPHABLE, which is the only reason it is here — but it is not
## load-bearing: every claim is fully legible from the strip alone, so if the font fails to
## resolve headless the sheet still answers. It is excluded from the prediction below,
## which is part of why that prediction is a floor.
func _build_readout(face: Node3D) -> void:
	var lab := Label3D.new()
	lab.name = "Readout"
	lab.text = _claim_text()
	lab.font_size = 44
	lab.pixel_size = 0.0012
	lab.modulate = CALIB_NEUTRAL.lightened(0.45)
	lab.position = Vector3(0.0, 0.295, FACE_Z + 0.006)
	face.add_child(lab)


func _claim_text() -> String:
	match claim:
		"threshold":
			return "0.60 - end"
		"point":
			return "0.40"
		"rival":
			return "0.40 / 0.65"
		"absent":
			return "--"
		_:
			return "0.30 - 0.50"


# ── HELPERS ───────────────────────────────────────────────────────────────────────────

func _cell_x(i: int) -> float:
	return -SPAN * 0.5 + (float(i) + 0.5) * PITCH


func _t_x(t: float) -> float:
	return -SPAN * 0.5 + t * SPAN


func _level_y(l: int) -> float:
	return REC_BOT + (float(l) + 0.5) * LEVEL_H


## THE ONE PLACE A FACE MARK IS MADE. Every strip, every drawing and every value goes
## through it, which is what makes count / spread / drift comparable to the byte at
## claim = point rather than merely comparable in area.
func _mark(parent: Node3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _unit
	mi.scale = size
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


# ── PUBLIC API ────────────────────────────────────────────────────────────────────────

## The recommended set as a list of [lo, hi] pairs in t. Empty means no recommendation.
func get_claim_spans() -> Array:
	return _claim_spans()


## How many of the twenty cells the claim lights. One for a point, zero for absent — the
## resolution argument, in a number.
func get_lit_cell_count() -> int:
	return _lit_cells().size()


## How many of the claim's boundaries are INTERIOR to the scale. This is the number the two
## sources disagree about and never report: 2 for lambda's interval, 1 for phi's threshold.
func get_interior_boundary_count() -> int:
	var n: int = 0
	for t in _claim_posts():
		if float(t) > 0.001 and float(t) < 0.999:
			n += 1
	return n
