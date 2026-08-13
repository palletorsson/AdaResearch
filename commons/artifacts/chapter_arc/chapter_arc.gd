extends Node3D

# @identity
# essence: the five chapters of the randomness book standing along one rail at once, all
#   five reading the SAME hundred draws, so the arc is a spatial fact instead of a claim
# desire: to be photographable. `all` is the one value of `chapter` a still cannot hold,
#   because in every artifact that declares the word `all` means a ten-second timer
# critical_parameter: steps — how many times each station has applied its own rule to the
#   shared draw, which at 0 is the common origin and at 60 is the arc
# triggers: nothing. No interaction, no animation, no _process, no timer, no physics.
# emerges: the ladder is NOT monotone in constraint. chaos, noise and pattern leave the
#   draw's spread untouched to within 0.03 of 5.04; only emergence and evolution contract it
# needs: five stations on one apron [has]; the shared draw drawn where each rule started
#   [has]; a counted census of each station against one fixed ceiling [has]; the parent's
#   per-body emission [declined — see dna.declines]
# relationships: the SPATIAL form of extreme_randomness's `chapter = all`. Reads the five
#   station names out of extrem_randomness.gd's own CHAPTER_DEMOS and the evidence ladder
#   out of noise_quarry.gd's own EVIDENCES; retypes neither.
# truth: the five chapters were never one system at five stages — the parent stages each of
#   them from its own initial condition — and putting them on one draw is what turns the
#   curriculum's ladder from an order we assert into a thing that can be measured and fail

# ─────────────────────────────────────────────────────────────────────────────
# THE FAMILY WORD IS EXHIBITED, NOT SWEPT — and so is its first value.
#
# `chapter` is declared by six registry names over two scenes. Five of them —
# extreme_randomness, particle_randomness_pure / _perlin / _patterns / _emergent —
# carry all | chaos | noise | pattern | emergence | evolution against ONE script,
# extrem_randomness.gd. The sixth, facade_grammar_demo, carries
# all | topology | organic | compound | decoration | bridge, an ARCHITECTURAL list
# that shares only the word and the leading `all`.
#
# THE FIVE NAMED VALUES SIT SIDE BY SIDE. extrem_randomness.gd:253-258 is a flat
# five-branch `match current_demo` and :271-286 is a flat five-branch `match
# demo_index` over the stagings. update_pure_random (:301), update_perlin_noise
# (:330), update_procedural_patterns (:360), update_emergent_behavior (:400) and
# update_evolutionary_algorithms (:469) are five functions and not one of them calls
# another. No branch contains another; no value is another value plus a term.
# Parallel values are exactly the case where holding them all at once is not merely
# the top value — it is the object. So the five stand together in every tile,
# lettered on the apron, and the axes vary something else.
#
# THE ARGUMENT NESTS EVEN THOUGH THE CODE DOES NOT, which is why this artifact
# exists. The parent's own doc block (:22-35) reads the five as a progression:
# unstructured draw, then correlation, then rule, then interaction, then selection —
# each stage's rule reading everything the previous one read plus one more source.
# chaos reads nothing (three fresh draws per body per frame); noise reads POSITION
# (a smooth field, :337-339); pattern reads position under an EQUATION (:368-383);
# emergence reads every OTHER body (:421-433); evolution reads a RANKING of every
# other body against a target (:515-522). That ladder is a claim about five things
# the file builds as five separate objects, and nothing in the corpus could test it,
# because no artifact can stand two of the five at once.
#
# WHY `all` IS EXHIBITED AND NOT KEPT AS A VALUE. In extrem_randomness.gd `all` is
# the value that pins nothing: _chapter_demo_index() (:598) finds no match for it,
# returns -1, and _ready leaves display_time at 10.0 so the book turns its own pages
# on a timer. Its own registry entry says the consequence out loud — at a pinned
# chapter 0 the code freezes rather than restages, "so 'all' and 'chaos' are the same
# picture". A STILL CANNOT PHOTOGRAPH `all`. It is a time-domain union, and the
# evidence in this project is one PNG per value.
#
# This arc is that union taken out of time and laid along +x. It is therefore a
# permanent `chapter = all`, and keeping `all` as a value would mean five of six
# variants were the arc refusing to be an arc — five worse copies of five artifacts
# that already ship. The word is spent; the axes are `evidence` and `steps`.
# (disclosure_cabinet's nesting question, answered the other way: there the cabinet
# could stand inside its own top rung, here the strip IS the rung.)
#
# WHAT THE PARENT'S FIVE SILHOUETTES ACTUALLY ARE, on the record, because it is this
# artifact's reason to be built. extrem_randomness's registry says the five "differ
# in SILHOUETTE before they differ in anything else (a 10 m cube, a flat 20 x 5
# panel, a disc, a 2 m ball, a 2 m line)". Those silhouettes are STAGED, not earned:
# they are five different initial conditions written into start_demo's match block at
# :271-286, applied before any update rule has run once. So the parent's arc is five
# systems that look different because they were built different. This arc starts all
# five from ONE draw and lets only the rule separate them — which is what makes
# `steps = 0` worth photographing, and what makes the census able to disagree.
# ─────────────────────────────────────────────────────────────────────────────

## The `chapter` vocabulary, live. Not a copy: the five stations, their order, their
## count and their lettering all come out of this array at build time. extrem_randomness
## is the only member of the family that can be preloaded without dragging something
## else in — it has no class_name, no preload and no reference to a global class — and
## it is also the file whose five update rules this artifact ports, so one preload does
## both jobs and the vocabulary cannot come apart from the implementation.
const CHAPTER_SRC := preload("res://algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd")

## The `evidence` ladder, live. Forty-eight registry names carry this word; noise_quarry
## and generator_bench are the two synthesis artifacts that hold the three-rung sub-list
## in a const, and generator_bench already preloads the quarry for it. Preloading the
## same file rather than retyping means the three cannot drift apart.
const EVIDENCE_SRC := preload("res://commons/artifacts/noise_quarry/noise_quarry.gd")

## DNA axis — how much proof is standing that the five stations were handed the same
## hundred numbers. The family word with the three-rung sub-list, character for character
## and in its order.
##   result   — the five station clouds on the apron, and nothing else.
##   trace    — + the origin frame under each station, the footprint of the shared draw's
##              own +/-5 box, identical at all five; and a carry ribbon for every tenth
##              body running from where that body STARTED to where its station's rule has
##              put it. At steps = 0 the ribbons have zero length and are not drawn, which
##              is the honest consequence and not a missing mark.
##   longhand — + a counted census of each station on the board behind it: its spread and
##              how far its rule has carried the draw, both against ceilings fixed across
##              all nine frames.
@export_enum("result", "trace", "longhand") var evidence: String = "longhand"

## DNA axis — how many times each station has applied its OWN rule to the shared draw.
## Not a duration: every value is a distinct static configuration, and the arithmetic runs
## once at build time. It nests as literally as a ladder can — step k+1 is step k with one
## more application of the same function, so the k-step state is a prefix of the k+1-step
## trajectory — and at 0 the five stations are the same hundred bodies in the same places
## in the same colours, because every colour law in the parent lives inside an update
## function and start_demo (:292-293) resets albedo to the colour the body was drawn with.
@export_range(0, 60, 1) var steps: int = 60

## Retyped ONCE, because @export_enum needs a literal GDScript will not let me compute.
## _check_evidence_list() holds it against EVIDENCE_SRC.EVIDENCES in both directions at
## _ready, so a drift in either file is a push_error and not a silent fallback.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand"]
## The five stations this file can evaluate. NOT the canon — the canon is
## CHAPTER_SRC.CHAPTER_DEMOS — but the list _check_family_list holds the canon against.
const STATIONS: PackedStringArray = ["chaos", "noise", "pattern", "emergence", "evolution"]
const STEPS_MIN := 0
const STEPS_MAX := 60

# ── the draw: one seeding, one stream, shared by all five (law 3) ────────────
const BODIES := 100                     # extrem_randomness.gd:8 num_particles
const DT := 1.0 / 60.0                  # the frame the parent integrates on
const BOUND := 7.0                      # :316 and :348
const SEED_BASE := 20260813
const MASK := 0xFFFFFFFF
## A 32-bit LCG rather than RandomNumberGenerator, and the reason is not determinism —
## RandomNumberGenerator seeds deterministically too. It is that this exact generator is
## reproducible in Python, so dna.predicted_degeneracy is arithmetic on THE SAME hundred
## bodies this file builds rather than on a statistically similar draw.
const LCG_A := 1664525
const LCG_C := 1013904223
## Golden-ratio scramble so five neighbouring station seeds do not start in step; eight
## warm-up draws on top, because a plain LCG's low bits are correlated for the first few.
const LCG_STRIDE := 2654435761
const LCG_WARMUP := 8

## The parent's own fitness target with time frozen at 0: Vector3(3*sin(0), 2*cos(0),
## sin(0)) from :473. It is above the draw's centre, which is why the evolution station's
## knot sits higher than the other four rather than in the middle of its frame.
const TARGET := Vector3(0.0, 2.0, 0.0)

# ── layout, in metres ────────────────────────────────────────────────────────
## Simulation metre -> display metre. ONE factor for all five stations, so the relative
## sizes of the five clouds are the exhibit's content and not a per-station choice.
const SCALE := 0.075
const PITCH_X := 1.60
const BAY_E := 1.06
const BAY_H := 0.055
const APRON_Y := 0.10
const APRON_Z0 := -0.58
const APRON_Z1 := 0.58
const APRON_MARGIN := 0.12
const FIELD_Y := 0.70
## FIXED, not scaled by SCALE. The parent's 0.05 radius would be 3.75 mm here, which is
## 0.3 px at the sweep's 83.51 px/m. This is the ratio-1 size and every per-station radius
## law below is applied to it as a RATIO, so the parent's relative sizes survive and the
## absolute one is legible: 2 x 0.038 = 6.35 px across.
const BODY_R := 0.038
## Half the draw's own extent: the parent scatters uniform in +/-5, and 5.0 * SCALE = 0.375.
const ORIGIN_E := 0.375
const CAGE_T := 0.044                   # 3.67 px
const POST_H := 0.11
const RIBBON_T := 0.044                 # 3.67 px
## Every tenth body carries a ribbon. Ten of a hundred: enough to read the correspondence,
## few enough that the ribbons do not become the picture at the evolution station, where
## they all converge on one knot.
const CARRY_STRIDE := 10

const WALL_Z := -0.62
const WALL_T := 0.030
const BOARD_Y0 := 1.32
const BOARD_Y1 := 1.72
const BAR_T := 0.022
const BAR_H := 0.070
const BAR_GAP := 0.030
const BAR_MAX := 1.10
## FIXED ACROSS THE WHOLE SHEET. The widest spread anywhere in the nine frames is 5.09
## simulation metres (noise at steps 60) and the longest carry is 3.81 (evolution at 60),
## so these are those plus 10% and nothing is ever clipped or rescaled. A per-frame or
## per-station ceiling would make the census a picture of its own normaliser.
const SPREAD_CEIL := 5.60
const CARRY_CEIL := 4.20

const STONE := Color(0.34, 0.345, 0.36)
const BAY_C := Color(0.27, 0.275, 0.29)
const BOARD_LO := Color(0.165, 0.17, 0.185)
const BOARD_HI := Color(0.245, 0.25, 0.265)
const CAGE_C := Color(0.30, 0.52, 0.62)
const SPREAD_C := Color(0.42, 0.66, 0.92)
const CARRY_C := Color(0.92, 0.72, 0.30)

var _built: bool = false
## The arithmetic, evaluated once per `steps` value and read four ways: the bodies, their
## radii, the carry ribbons and the census. Rebuilt only when `steps` changes — `evidence`
## adds and removes marks, it does not re-run a single step.
var _read_steps: int = -1
## ARRAY AND NOT PackedVector3Array, and it is not a style choice. Godot 4 packed arrays
## are copy-on-write VALUE types: a _step_* function that took one as an argument and
## wrote to it would write to its own copy, the caller would get its draw back unmoved at
## every station, and nothing would fail loudly. Array is a reference type and the five
## rules mutate the caller's state, which is what they are for.
var _pos: Array = []                    # per station: Array[Vector3], the final places
var _col: Array = []                    # per station: Array[Color]
var _rad: Array = []                    # per station: Array[float], radius ratios
var _spread: Array[float] = []
var _carried: Array[float] = []
var _draw_pos: Array[Vector3] = []
var _draw_vel: Array[Vector3] = []
var _draw_col: Array[Color] = []


func _ready() -> void:
	# The grid stamps config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config deferred, i.e. after this, so the meta read happens here.
	_read_grid_config_meta()
	_check_family_list()
	_check_evidence_list()
	_build()
	_built = true


# ── the vocabulary ───────────────────────────────────────────────────────────
func _chapters() -> PackedStringArray:
	return CHAPTER_SRC.CHAPTER_DEMOS


## Both directions. A chapter the family declares that this arc has no station for would
## be a page silently torn out; a station this arc builds that the family no longer
## declares would be a sixth chapter this file invented. Neither may pass quietly.
## Note that `all` is correctly ABSENT from CHAPTER_DEMOS — the parent's own comment at
## :41-42 says so — which is why this check can be an exact set comparison.
func _check_family_list() -> void:
	var family: PackedStringArray = _chapters()
	for i in range(family.size()):
		if not STATIONS.has(family[i]):
			push_error("chapter_arc: the chapter family declares '%s' and this arc has no station for it. Build one or refuse the value on the record." % family[i])
	for i in range(STATIONS.size()):
		if not family.has(STATIONS[i]):
			push_error("chapter_arc: this arc stands a station for '%s' and the chapter family no longer declares it. The vocabulary has moved." % STATIONS[i])


func _check_evidence_list() -> void:
	var family: PackedStringArray = EVIDENCE_SRC.EVIDENCES
	for i in range(family.size()):
		if not EVIDENCES.has(family[i]):
			push_error("chapter_arc: the evidence family declares '%s' and this arc's export hint does not offer it." % family[i])
	for i in range(EVIDENCES.size()):
		if not family.has(EVIDENCES[i]):
			push_error("chapter_arc: this arc offers evidence '%s' and the evidence family no longer declares it." % EVIDENCES[i])


# ── the generator ────────────────────────────────────────────────────────────
var _lcg: int = 0


func _seed_lcg(s: int) -> void:
	_lcg = s & MASK
	for _i in range(LCG_WARMUP):
		_next()


func _next() -> int:
	_lcg = (_lcg * LCG_A + LCG_C) & MASK
	return _lcg


func _rf() -> float:
	return float(_next()) / 4294967296.0


func _rrange(a: float, b: float) -> float:
	return a + (b - a) * _rf()


func _ri(n: int) -> int:
	if n <= 0:
		return 0
	return _next() % n


## THE ONE DRAW. Nine numbers per body from one stream, in the parent's own order:
## position (:196 randf_range(-5,5) three times), velocity (:289 randf_range(-1,1) three
## times) and the colour the body is made with (:200 Color(randf(), randf(), randf())).
## Every station starts from THIS, unchanged.
func _make_draw() -> void:
	_seed_lcg(SEED_BASE)
	_draw_pos = []
	_draw_vel = []
	_draw_col = []
	for i in range(BODIES):
		_draw_pos.append(Vector3(_rrange(-5.0, 5.0), _rrange(-5.0, 5.0), _rrange(-5.0, 5.0)))
		_draw_vel.append(Vector3(_rrange(-1.0, 1.0), _rrange(-1.0, 1.0), _rrange(-1.0, 1.0)))
		_draw_col.append(Color(_rf(), _rf(), _rf()))


# ── the five rules, ported from the parent with time frozen at 0 ─────────────
## :582 verbatim. The parent calls it "a utility function to simulate 3D Perlin noise";
## it is a product of three sinusoids, which is not Perlin noise at all, and that is left
## exactly as it is because this arc photographs what the file DOES.
func _noise3(x: float, y: float, z: float) -> float:
	return sin(x * 7.0 + z * 3.0) * cos(y * 5.0 + x * 2.0) * sin(z * 11.0 + y * 7.0)


## :301 update_pure_random. Three fresh draws per body per step: chaos is the only station
## whose rule keeps consuming chance after the draw is made.
func _step_chaos(pos: Array[Vector3], vel: Array[Vector3]) -> void:
	for i in range(BODIES):
		var v: Vector3 = vel[i]
		var p: Vector3 = pos[i]
		v += Vector3(_rrange(-1.0, 1.0), _rrange(-1.0, 1.0), _rrange(-1.0, 1.0)) * DT
		v *= 0.99
		p += v * DT
		var m: float = p.length()
		if m > BOUND:
			var n: Vector3 = p / m
			p = n * BOUND
			v = v.bounce(n) * 0.8
		pos[i] = p
		vel[i] = v


## :330 update_perlin_noise. With time frozen the field's third argument is 0, so it has
## no z term left: it is a 2D field extruded through z, and the bodies bunch onto its
## attracting sheets. Neighbouring samples agree — which is the whole content of the word.
func _step_noise(pos: Array[Vector3], _vel: Array[Vector3]) -> void:
	for i in range(BODIES):
		var p: Vector3 = pos[i]
		var x: float = p.x * 0.1
		var y: float = p.y * 0.1
		var d: Vector3 = Vector3(_noise3(x, y, 0.0), _noise3(x + 100.0, y + 100.0, 0.0),
			_noise3(x + 200.0, y + 200.0, 0.0)).normalized()
		p += d * DT
		var m: float = p.length()
		if m > BOUND:
			p = p / m * BOUND
		pos[i] = p


## :360 update_procedural_patterns. No chance in the rule at all: a tangential term that
## winds the cloud, a sin(distance) term in z that bands it by radius, and a per-index
## drift. The same chance, filtered through an equation.
func _step_pattern(pos: Array[Vector3], _vel: Array[Vector3]) -> void:
	for i in range(BODIES):
		var p: Vector3 = pos[i]
		var d2: float = Vector2(p.x, p.y).length()
		var spiral: Vector3 = Vector3(-p.y / (d2 + 0.1), p.x / (d2 + 0.1), sin(d2)) * DT
		var osc: Vector3 = Vector3(sin(float(i) * 0.1), cos(float(i) * 0.1), sin(float(i) * 0.1)) * DT * 0.2
		pos[i] = p + spiral + osc


## :400 update_emergent_behavior, weights unchanged (0.05 / 0.03 / 0.01 / 0.01, cap 2.0).
## The separation test is the parent's `dist < 0.5` written on the SQUARE, so the sqrt is
## paid only by near pairs: identical branch, and it is what keeps a 60-step build under a
## tenth of a second instead of over a second.
func _step_emergence(pos: Array[Vector3], vel: Array[Vector3]) -> void:
	var centre := Vector3.ZERO
	var avg := Vector3.ZERO
	for i in range(BODIES):
		centre += pos[i]
		avg += vel[i]
	centre /= float(BODIES)
	avg /= float(BODIES)
	for i in range(BODIES):
		var p: Vector3 = pos[i]
		var v: Vector3 = vel[i]
		var sep := Vector3.ZERO
		for j in range(BODIES):
			if j == i:
				continue
			var d: Vector3 = pos[j] - p
			var sq: float = d.length_squared()
			if sq < 0.25 and sq > 1e-18:
				var dist: float = sqrt(sq)
				sep -= (d / dist) / maxf(dist, 0.1)
		v += sep * 0.05
		v += (avg - v) * 0.03
		v += (centre - p) * 0.01
		v += Vector3(_rrange(-1.0, 1.0), _rrange(-1.0, 1.0), _rrange(-1.0, 1.0)) * 0.01
		var sp: float = v.length()
		if sp > 2.0:
			v = v / sp * 2.0
		pos[i] = p + v * DT
		vel[i] = v


## :469 + :513 _evolve_toward at selection = culled, the shipped pressure and the one the
## parent's own `selection` axis defaults to. ELITE_FRACTION is read out of the parent
## rather than retyped, so the tenth that turns gold here is the tenth that turns gold
## there. Returns the ranking, which is also the colour and radius law.
func _step_evolution(pos: Array[Vector3], vel: Array[Vector3]) -> Array[int]:
	# The ranking is taken from the state at the START of the step, exactly as the parent
	# does: it sorts before it moves anything. Snapshotting the distances rather than
	# reading positions inside the comparator makes that explicit and cannot be broken by
	# a later edit that moves a body mid-sort.
	var dist: Array[float] = []
	var order: Array[int] = []
	for i in range(BODIES):
		dist.append(pos[i].distance_to(TARGET))
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return dist[a] < dist[b])
	var wc: int = int(float(BODIES) * float(CHAPTER_SRC.ELITE_FRACTION))
	for rank in range(BODIES):
		var i: int = order[rank]
		var p: Vector3 = pos[i]
		var v: Vector3 = vel[i]
		if rank < wc:
			v = (TARGET - p).normalized() * 2.0
			v += Vector3(_rrange(-0.5, 0.5), _rrange(-0.5, 0.5), _rrange(-0.5, 0.5))
		else:
			var w: Vector3 = pos[order[_ri(wc)]]
			v = v * 0.9 + (w - p).normalized() * 0.5
			v += Vector3(_rrange(-1.0, 1.0), _rrange(-1.0, 1.0), _rrange(-1.0, 1.0)) * 0.3
		pos[i] = p + v * DT
		vel[i] = v
	var out: Array[int] = []
	out.resize(BODIES)
	for rank in range(BODIES):
		out[order[rank]] = rank
	return out


# ── ONE COPY OF THE ARITHMETIC ───────────────────────────────────────────────
## Evaluated once per `steps` value and read four ways: the bodies stand on it, their
## radii come from it, the carry ribbons run from the draw to it, and the census counts
## it. If the census counted a second evaluation the artifact would be a picture of one
## reading with a chart of another.
func _read_stations() -> void:
	if _read_steps == steps and not _pos.is_empty():
		return
	_make_draw()
	_pos = []
	_col = []
	_rad = []
	_spread = []
	_carried = []
	_spread.resize(STATIONS.size())
	_carried.resize(STATIONS.size())
	var k: int = clampi(steps, STEPS_MIN, STEPS_MAX)
	for si in range(STATIONS.size()):
		var pos: Array[Vector3] = []
		var vel: Array[Vector3] = []
		for i in range(BODIES):
			pos.append(_draw_pos[i])
			vel.append(_draw_vel[i])
		_seed_lcg((SEED_BASE + si * LCG_STRIDE) & MASK)
		var rank: Array[int] = []
		rank.resize(BODIES)
		var ranked: bool = false
		for _s in range(k):
			match si:
				0:
					_step_chaos(pos, vel)
				1:
					_step_noise(pos, vel)
				2:
					_step_pattern(pos, vel)
				3:
					_step_emergence(pos, vel)
				_:
					rank = _step_evolution(pos, vel)
					ranked = true
		var centre := Vector3.ZERO
		for i in range(BODIES):
			centre += pos[i]
		centre /= float(BODIES)
		var sq: float = 0.0
		var moved: float = 0.0
		for i in range(BODIES):
			sq += pos[i].distance_squared_to(centre)
			moved += pos[i].distance_to(_draw_pos[i])
		_spread[si] = sqrt(sq / float(BODIES))
		_carried[si] = moved / float(BODIES)
		var cols: Array[Color] = []
		var rads: Array[float] = []
		cols.resize(BODIES)
		rads.resize(BODIES)
		var wc: int = int(float(BODIES) * float(CHAPTER_SRC.ELITE_FRACTION))
		for i in range(BODIES):
			cols[i] = _colour_for(si, i, pos[i], centre, rank, ranked, wc, k)
			rads[i] = _radius_ratio(si, pos[i], rank, ranked, i, wc, k)
		_pos.append(pos)
		_col.append(cols)
		_rad.append(rads)
	_read_steps = steps


## THE COLOUR LAW LIVES IN THE UPDATE, so at zero applications no station has one and all
## five wear the colours the draw was made with. start_demo (:292-293) resets albedo to
## `original_color`; every law below is set inside an update_* function. chaos never
## overwrites albedo at all (:324-327 touches only emission), so it wears the draw's own
## colours at every value of `steps` — the one station where the numbers are still visible
## as the numbers they were drawn as.
func _colour_for(si: int, i: int, p: Vector3, centre: Vector3, rank: Array[int],
		ranked: bool, wc: int, k: int) -> Color:
	if k <= 0 or si == 0:
		return _draw_col[i]
	if si == 1:                                         # :353
		return Color(maxf(0.0, (sin(p.x * 0.5) + 1.0) * 0.5),
			maxf(0.0, (sin(p.y * 0.5) + 1.0) * 0.5),
			maxf(0.0, (sin(p.z * 0.5) + 1.0) * 0.5))
	if si == 2:                                         # :390
		var ang: float = atan2(p.y, p.x)
		var d: float = Vector2(p.x, p.y).length()
		return Color((sin(ang * 3.0) + 1.0) * 0.5, (sin(d * 0.5) + 1.0) * 0.5, (sin(d) + 1.0) * 0.5)
	if si == 3:                                         # :462
		var dc: float = p.distance_to(centre)
		return Color(0.5 + 0.5 * sin(dc * 2.0), 0.5 + 0.5 * cos(dc * 2.0), 0.5 + 0.5 * sin(dc))
	if not ranked:
		return _draw_col[i]
	if rank[i] < wc:                                    # :536
		return Color(1.0, 0.8, 0.2)
	var rr: float = float(rank[i]) / float(BODIES)      # :559
	return Color(0.2 + 0.8 * (1.0 - rr), 0.2 + 0.6 * (1.0 - rr), 0.5)


## The parent's own radii as a RATIO to its 0.05 default, so its relative sizes survive a
## change of scale. :397 for pattern, :541 and :567 for evolution.
func _radius_ratio(si: int, p: Vector3, rank: Array[int], ranked: bool, i: int,
		wc: int, k: int) -> float:
	if k <= 0:
		return 1.0
	if si == 2:
		var d: float = Vector2(p.x, p.y).length()
		return (0.05 + 0.03 * sin(d * 2.0)) / 0.05
	if si == 4 and ranked:
		if rank[i] < wc:
			return 0.08 / 0.05
		return (0.05 - 0.02 * (float(rank[i]) / float(BODIES))) / 0.05
	return 1.0


# ── construction ─────────────────────────────────────────────────────────────
func _build() -> void:
	# remove_child first: queue_free is deferred, so a rebuild would otherwise stand the
	# new arc inside the old one for a frame — and a capture taken in that frame is a
	# photograph of two variants at once.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_read_stations()

	var names: PackedStringArray = _chapters()
	var n: int = names.size()
	var run: float = float(maxi(n - 1, 0)) * PITCH_X + BAY_E
	_slab("Apron", Vector3(0.0, APRON_Y * 0.5, (APRON_Z0 + APRON_Z1) * 0.5),
		Vector3(run + 2.0 * APRON_MARGIN, APRON_Y, APRON_Z1 - APRON_Z0), STONE)

	for si in range(n):
		var bx: float = _station_x(si, run)
		_slab("Bay_" + names[si], Vector3(bx, APRON_Y + BAY_H * 0.5, 0.0),
			Vector3(BAY_E, BAY_H, BAY_E * 0.62), BAY_C)
		_letter(names[si], bx)
		if si < _pos.size():
			_build_bodies(names[si], si, bx)
		if evidence == "trace" or evidence == "longhand":
			_origin_frame(names[si], bx)
			if si < _pos.size():
				_build_carry(names[si], si, bx)

	if evidence == "longhand":
		var mid: float = (BOARD_Y0 + BOARD_Y1) * 0.5
		_slab("BoardLower", Vector3(0.0, (BOARD_Y0 + mid) * 0.5, WALL_Z),
			Vector3(run, mid - BOARD_Y0, WALL_T), BOARD_LO)
		_slab("BoardUpper", Vector3(0.0, (mid + BOARD_Y1) * 0.5, WALL_Z),
			Vector3(run, BOARD_Y1 - mid, WALL_T), BOARD_HI)
		var zf: float = WALL_Z + WALL_T * 0.5 + BAR_T * 0.5
		for si in range(n):
			if si >= _spread.size():
				continue
			_census(si, _station_x(si, run), zf)


func _station_x(si: int, run: float) -> float:
	return -run * 0.5 + BAY_E * 0.5 + float(si) * PITCH_X


## THE CENSUS COUNTS THE THING IT CLAIMS TO COUNT. Two readings of the SAME array the
## bodies in front are standing on, never a second evaluation:
##   spread  — the rms distance of the hundred bodies from their own centre, i.e. how wide
##             the station's reading of the draw is.
##   carried — the mean distance from each body's place in the DRAW to where this station's
##             rule has put it, i.e. how far the rule has moved the numbers.
## Both against ceilings fixed across every frame of the sheet, so the same bar length
## means the same number in all nine.
func _census(si: int, bx: float, zf: float) -> void:
	var x0: float = bx - BAR_MAX * 0.5
	var readings: Array = [[_spread[si], SPREAD_CEIL, SPREAD_C], [_carried[si], CARRY_CEIL, CARRY_C]]
	for row in range(readings.size()):
		var val: float = float(readings[row][0])
		var ceil_v: float = float(readings[row][1])
		var col: Color = readings[row][2]
		var bar: float = minf(val / ceil_v, 1.0) * BAR_MAX
		if bar <= 0.0005:
			continue
		var y: float = BOARD_Y1 - 0.030 - BAR_H * 0.5 - float(row) * (BAR_H + BAR_GAP)
		_slab("Count%d_%d" % [si, row], Vector3(x0 + bar * 0.5, y, zf),
			Vector3(bar, BAR_H, BAR_T), col)


## The footprint of the shared draw's own +/-5 box, drawn as FOUR RAILS AND FOUR POSTS and
## not as a cage. A twelve-edge cage was built first and measured: at 0.75 m a side its
## screen-x extent is 1.046 m against a station pitch of 1.172 m, so neighbouring cages
## overlapped by 0.065 m, and the cyan was the loudest thing in every frame — furniture in
## front of the marks, which is law 7 exactly. Four rails on the floor of the box and four
## short corner posts say the same thing under the bodies instead of around them.
func _origin_frame(value: String, bx: float) -> void:
	var yb: float = FIELD_Y - ORIGIN_E
	for a in range(2):
		var s: float = -1.0 if a == 0 else 1.0
		_slab("OriginX%d_%s" % [a, value], Vector3(bx, yb, s * ORIGIN_E),
			Vector3(2.0 * ORIGIN_E + CAGE_T, CAGE_T, CAGE_T), CAGE_C)
		_slab("OriginZ%d_%s" % [a, value], Vector3(bx + s * ORIGIN_E, yb, 0.0),
			Vector3(CAGE_T, CAGE_T, 2.0 * ORIGIN_E), CAGE_C)
	for a in range(4):
		var sx: float = -1.0 if (a & 1) == 0 else 1.0
		var sz: float = -1.0 if (a & 2) == 0 else 1.0
		_slab("Post%d_%s" % [a, value], Vector3(bx + sx * ORIGIN_E, yb + POST_H * 0.5, sz * ORIGIN_E),
			Vector3(CAGE_T, POST_H, CAGE_T), CAGE_C)


func _build_bodies(value: String, si: int, bx: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pos: Array = _pos[si]
	var cols: Array = _col[si]
	var rads: Array = _rad[si]
	var base := Vector3(bx, FIELD_Y, 0.0)
	for i in range(BODIES):
		_octa(st, base + pos[i] * SCALE, BODY_R * rads[i], cols[i])
	var mi := MeshInstance3D.new()
	mi.name = "Bodies_" + value
	mi.mesh = st.commit()
	mi.material_override = _vertex_material()
	add_child(mi)


## The carry. Each ribbon runs from where its body STARTED — the same point at all five
## stations, because there is only one draw — to where this station's rule has put it, in
## that body's own drawn colour. At steps = 0 every ribbon has zero length and _prism
## returns without emitting, so `trace` at the origin is the origin frames alone.
func _build_carry(value: String, si: int, bx: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pos: Array = _pos[si]
	var base := Vector3(bx, FIELD_Y, 0.0)
	var any: bool = false
	var i: int = 0
	while i < BODIES:
		if _prism(st, base + _draw_pos[i] * SCALE, base + pos[i] * SCALE, RIBBON_T, _draw_col[i]):
			any = true
		i += CARRY_STRIDE
	if not any:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Carry_" + value
	mi.mesh = st.commit()
	mi.material_override = _vertex_material()
	add_child(mi)


## The exhibited word, present at EVERY value of both axes, so no tile contains a rendered
## word naming its own variant. Billboard off, which also keeps LabelFramer out — it reads
## billboard-enabled as the hanging signal and would bolt a panel and a bezel behind each
## one. Label3D defaults to HORIZONTAL_ALIGNMENT_CENTER, so the tab is centred on its
## origin and hanging it at the station's centre x is correct; a LEFT-aligned block would
## have hung from this point and run right.
func _letter(value: String, bx: float) -> void:
	var label := Label3D.new()
	label.name = "Tab_" + value
	label.text = value
	label.font_size = 64
	label.pixel_size = 0.0013
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.modulate = Color(0.88, 0.90, 0.94)
	label.position = Vector3(bx, APRON_Y + BAY_H + 0.035, APRON_Z1 - 0.015)
	add_child(label)


# ── mesh helpers ─────────────────────────────────────────────────────────────
func _vertex_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.55
	m.metallic = 0.0
	return m


func _slab(node_name: String, centre: Vector3, size: Vector3, c: Color) -> void:
	var b := BoxMesh.new()
	b.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	m.metallic = 0.0
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = b
	mi.material_override = m
	mi.position = centre
	add_child(mi)


## THE NORMAL IS COMPUTED PER FACE AND PASSED IN. An octahedron's eight faces each have
## their own outward direction — that is the whole reason a body is an octahedron here and
## not a cube: three of the eight faces catch the key light at three different angles, so
## a 6 px body still reads as round rather than as a flat lozenge.
func _octa(st: SurfaceTool, centre: Vector3, r: float, c: Color) -> void:
	var p: Array[Vector3] = [
		centre + Vector3(r, 0, 0), centre + Vector3(-r, 0, 0),
		centre + Vector3(0, r, 0), centre + Vector3(0, -r, 0),
		centre + Vector3(0, 0, r), centre + Vector3(0, 0, -r)]
	var faces: Array = [[0, 2, 4], [2, 1, 4], [1, 3, 4], [3, 0, 4],
		[2, 0, 5], [1, 2, 5], [3, 1, 5], [0, 3, 5]]
	for fi in range(faces.size()):
		var f: Array = faces[fi]
		var a: Vector3 = p[f[0]]
		var b: Vector3 = p[f[1]]
		var d: Vector3 = p[f[2]]
		var nrm: Vector3 = (b - a).cross(d - a).normalized()
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(a)
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(b)
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(d)


## A square prism from a to b. Returns false when the two ends coincide, which is what
## makes `trace` at steps = 0 draw no ribbons rather than a hundred degenerate triangles.
func _prism(st: SurfaceTool, a: Vector3, b: Vector3, t: float, c: Color) -> bool:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.002:
		return false
	d = d / l
	var up := Vector3.UP
	if absf(d.dot(up)) > 0.95:
		up = Vector3.RIGHT
	var u: Vector3 = d.cross(up).normalized()
	var w: Vector3 = d.cross(u)
	var h: float = t * 0.5
	var off: Array[Vector3] = [u * h + w * h, u * h - w * h, -u * h - w * h, -u * h + w * h]
	for i in range(4):
		var j: int = (i + 1) % 4
		var a0: Vector3 = a + off[i]
		var a1: Vector3 = a + off[j]
		var b0: Vector3 = b + off[i]
		var b1: Vector3 = b + off[j]
		# THE NORMAL WAS INWARD HERE AND IT WAS CAUGHT ON PAPER, NOT ON SCREEN. Worked
		# through for the prism whose axis is +x: u = d x up = (0,0,1), w = d x u =
		# (0,-1,0), so off[0] = (0,-h,+h) and off[1] = (0,+h,+h) both sit at z = +h and
		# that quad IS the +z face. cross(b0 - a0, b1 - a0) = (L,0,0) x (L,2h,0) =
		# (0,0,2hL), which is +z, outward, and is also the winding these triangles are
		# emitted in. A `* -1.0` here lit every carry ribbon from inside: ambient only,
		# no key and no fill, on the one mark that carries the artifact's own thesis.
		var nrm: Vector3 = (b0 - a0).cross(b1 - a0).normalized()
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(a0)
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(b0)
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(b1)
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(a0)
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(b1)
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(a1)
	return true


# ── the two doors, one validator each ────────────────────────────────────────
func _is_evidence(v: String) -> bool:
	return EVIDENCES.has(v)


func _valid_steps(v: int) -> bool:
	return v >= STEPS_MIN and v <= STEPS_MAX


## Walk the ancestor chain for config_* metadata the grid stamps before _ready.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			var e: String = str(node.get_meta("config_evidence")).strip_edges().to_lower()
			if _is_evidence(e):
				evidence = e
		if node.has_meta("config_steps"):
			var s: int = int(node.get_meta("config_steps"))
			if _valid_steps(s):
				steps = s
		node = node.get_parent()


## Guarded: rebuild only when a declared axis actually CHANGED, and only after _ready has
## built once. An unrecognised word or an out-of-range integer keeps the standing value.
## Before _ready there is nothing standing to answer a value change, so the value is only
## recorded — which is also the path the capture harness takes when it sets the exports
## directly.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("evidence"):
		var e: String = str(config_data["evidence"]).strip_edges().to_lower()
		if _is_evidence(e) and e != evidence:
			evidence = e
			changed = true
	if config_data.has("steps"):
		var s: int = int(config_data["steps"])
		if _valid_steps(s) and s != steps:
			steps = s
			changed = true
	if changed and _built:
		_build()
