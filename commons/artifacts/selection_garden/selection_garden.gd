extends Node3D

# @identity
# essence: one founding population, generated once and seeded, run under all five of the
#   `selection` family's regimes to the SAME generation count, standing side by side
# desire: to stop meeting the five theories of what does the selecting one at a time, in
#   five different rooms, each on its own population, where none of them can be compared
# critical_parameter: variation — the heritable spread the regimes are given to act on,
#   and therefore the ceiling on anything any of them can do
# triggers: nothing. No interaction, no animation, no randomness, no clock.
# emerges: that drift is not the absence of a result — on this seed the null hypothesis
#   moved the mean further than three of the four pressures did
# needs: five plots from one founding set [has]; the founders standing on every plot
#   [has, `evidence` = trace]; a fixed gauge and the two means ruled [has, = longhand]
# relationships: synthesis of the `selection` family (evolved_creatures, evolving_flowers,
#   evolvingflowers, non_teleological_evolution, evolutionary_algorithms,
#   particle_randomness_evolutionary), whose word and value list it reads out of
#   non_teleological_evolution.gd rather than retyping
# truth: a selection regime cannot be told from its outcome — you have to be shown the
#   founders, and even then the null hypothesis can outrun the pressures

# ─────────────────────────────────────────────────────────────────────────────
# KIND: SERIES. THE FAMILY WORD IS EXHIBITED, NOT SWEPT.
#
# `selection` is declared by six artifacts in two vocabularies, and the split is a
# SUBSET, not a disagreement:
#
#   drift | uniform | culled | runaway | split   — evolved_creatures,
#     evolving_flowers, evolvingflowers, non_teleological_evolution (the owner)
#   drift | uniform | culled | split             — evolutionary_algorithms and
#     particle_randomness_evolutionary, which are ONE scene under two names
#
# The fuller list is taken. The two that drop `runaway` do so because they CANNOT
# express it, and they said so on the record before this pass existed: their
# population is a fixed 100 bodies that neither reproduces nor grows, so the value
# that means "standing at your own max_population ceiling with the field paved"
# could only have been renamed to mean something else — the dishonest half of a
# shared vocabulary. It is a refusal, not an oversight. Recorded again in dna.kin.
#
# THE VALUES SIT SIDE BY SIDE, NOT NESTED, and the evidence is the members' code:
# non_teleological_evolution._spawn_population() is a five-branch `match` whose
# arms call five different builders and never each other; evolvedcreatures sets
# `_active_count = CULLED_SLOTS.size() if selection == "culled" else
# POPULATION_SIZE` and then picks ONE body plan of five; evolvingflowers is the
# same shape again. No value's geometry contains another's, and no value is
# another plus a mark. Parallel values are exactly the case where showing them all
# at once is NOT merely the top rung — it is the object. So the word stands,
# lettered on the apron, five plots wide, and the axes vary the RUN instead.
#
# WHAT THE FIVE PLOTS DISAGREE ABOUT is what does the selecting:
#   drift    nothing does. Equal fitness, finite resampling. The null hypothesis.
#   uniform  one reward, run to completion — stabilising selection at the founding
#            mean, which spends the variety without moving the mean anywhere. The
#            end state is a population selection can no longer tell apart, which is
#            both the family's picture (one size, one hue) and the reading "selects
#            everyone equally, so it does no work" — the same photograph, named
#            from its two ends.
#   culled   truncation WITHOUT replacement: the bottom dies and is not replaced,
#            so the plot ends as a remnant on bare ground. The family's own picture
#            (6 of 30, 4 of 20, 3 of 16 — all ~20%) and its arithmetic.
#   runaway  positive feedback: the slope of selection grows with how far the mean
#            has already been carried, so the trait is selected because it is being
#            selected.
#   split    disruptive selection, the middle worst — PLUS assortative mating, which
#            is not decoration. Measured on this founding set, disruptive fitness
#            alone went UNIMODAL: the heavier tail simply won. Like breeds with like
#            is the standard requirement for two morphs to survive it, and it is
#            part of what `split` names.
#
# NOT AXES, and each refused for a reason:
#   generations — the brief's own instruction and the right one. Every plot runs to
#     GENERATIONS. Sweeping it would photograph the clock instead of the regime, and
#     the family already refused the same knob twice (genetic_tree_sculptor's
#     `generations`, evolvingflowers' `generation_time`).
#   the per-generation rates — mutation is a rate, but it is consumed at BUILD time
#     and the still is of the outcome at a fixed generation count, which is why
#     `variation` is admissible where `generation_time` is not.
# ─────────────────────────────────────────────────────────────────────────────

## The word's owner. Preloaded, not retyped: non_teleological_evolution.gd is the
## file whose header the word came from, and it is safe to preload because it has
## no class_name, no preload of its own and no reference to a global class, so
## reading its const cannot drag a third party's parse failure in here.
## Read as SCRIPT.SELECTIONS directly — get_script_constant_map() is non-static and
## fails on a preloaded class, and this form fails at PARSE time if the const ever
## disappears, which is the better failure.
const SELECTION_SRC := preload("res://algorithms/machinelearning/non_teleological_evolution/non_teleological_evolution.gd")

## DNA axis — how much heritable variation the founding population carries into the
## run: the raw material every regime has to act on, and the ceiling on anything any
## of them can reach. A MONOTONE LADDER, not a nesting and not a set of parallel
## cases: each rung is the same quantity, larger.
##   none    every founder identical. All five regimes produce ONE photograph,
##           because with no variance there is no differential to select on, no
##           bottom to cull and no tails to split. The degenerate rung is the
##           point, not a gap in the sweep.
##   narrow  founders spread +/- 0.10 of the trait range; the regimes separate, but
##           none of them travels far.
##   wide    founders spread +/- 0.30; every regime reaches its characteristic end
##           state. Measured: runaway ends at a mean of 0.8425 — the top of the
##           FOUNDING range (0.800) plus what six generations of mutation at 0.018
##           could add on top — and NOT at the scale's ceiling of 1.000, because a
##           pressure cannot reach past the material it was given.
@export_enum("none", "narrow", "wide") var variation: String = "wide"

## DNA axis — how much proof is standing that all five plots came from one founding
## population. The family word (45 declarations across the corpus), taken with the
## three-rung sub-list eight siblings already carry. `axiom` refused: see dna.declines.
##   result    the five plots and nothing else.
##   trace     + the founder TICKED on every blade: a bone mark at that lineage's OWN
##             founding height, proud on the blade's face. Where the coloured blade
##             rises above the tick the lineage gained; where the tick stands above
##             the blade on its riser it lost. The tick is drawn on every SLOT,
##             including the ones a cull emptied, so `culled` reads as a removal -
##             ten founders, three bodies - rather than as a shorter rank.
##   longhand  + the fixed gauge (one stile per plot, ticked at 0.00/0.25/0.50/0.75/
##             1.00 of the trait, the SAME five heights in every plot at every rung)
##             and the two means ruled across the rank: the founding mean in bone,
##             the plot's own final mean in accent. The gap between them is the
##             response to selection, as a length, against a fixed scale.
@export_enum("result", "trace", "longhand") var evidence: String = "longhand"

const VARIATIONS: PackedStringArray = ["none", "narrow", "wide"]
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand"]

## The five plots this garden stands. NOT the canon — the canon is
## SELECTION_SRC.SELECTIONS — but the list _check_family_list() holds the canon
## against, in BOTH directions.
const PLOTS: PackedStringArray = ["drift", "uniform", "culled", "runaway", "split"]

# ── the population: ONE copy of the arithmetic (law 3) ───────────────────────
# An integer hash rather than RandomNumberGenerator, for the same three reasons
# noise_quarry gives: it is exactly replicable in Python so dna.predicted_degeneracy
# is arithmetic on this geometry rather than an estimate; it has no state at all, so
# there is nothing a fixture could forget to pin; and it keeps this file out of any
# generator vocabulary it has not earned.
#
# EVERY REGIME DRAWS FROM THE SAME STREAM. The parent-choice and mutation hashes are
# keyed on (generation, slot) and NOT on which regime is running, so the five plots
# are one founding population under one sequence of chance with five weightings on
# it. That makes `drift` the literal control for the other four: whatever drift did,
# they all did, plus their selection. The first version keyed the stream on the
# regime and the plots were five experiments instead of one.
const HASH_SEED: int = 20260813
const HASH_MASK: int = 0xFFFFFFFF

const N_LINEAGES: int = 10
## The same for every plot, by instruction and by argument: varying it would
## photograph the clock rather than the selection.
const GENERATIONS: int = 6

## uniform's single reward, and split's worst phenotype. Both sit at the founding
## mean, which is 0.5 at every rung because the founders are centred by construction
## — so uniform's signature is variance collapse with the mean UNMOVED, and split's
## two morphs are symmetric about the place the population started.
const OPT: float = 0.5
const MID: float = 0.5
## Stabilising width. 0.05 of the trait range: narrow enough that six generations
## converge, which is what "run to completion" has to mean if the still is of the end.
const SEL_S: float = 0.05
## runaway: slope = RUN_B0 + RUN_BK * (mean so far - founding mean). The feedback IS
## the second term — the further the population has been carried, the harder it is
## pushed, which is the whole of what the word names.
const RUN_B0: float = 6.0
const RUN_BK: float = 60.0
## split: fitness rises with distance from MID, so the middle is worst.
const SPLIT_GD: float = 9.0
## culled: the fraction that survives each generation, truncating from the bottom
## WITHOUT replacement. int() of 10 * 0.88 = 8, then 7, 6, 5, 4, 3 — three of ten
## standing after six generations, which is the family's own ~20-30% remnant.
const CULL_SURV: float = 0.88

## The rungs of `variation`: (founding half-spread, per-generation mutation half-width).
## Both are zero at `none`, which is what makes the degenerate rung exact rather than
## nearly exact.
const VAR_SPREAD: Array[float] = [0.00, 0.10, 0.30]
const VAR_MUTATE: Array[float] = [0.000, 0.006, 0.018]

# ── layout ───────────────────────────────────────────────────────────────────
# Every number here was checked against the sweep's own rig before anything was
# built: FOV 34, PAD 1.9, RES 760, framing 0.55 puts the camera 11.199 m out and the
# frame at 6.8475 m, i.e. 110.99 px per metre. Screen sizes use the standpoint's
# |right.x| = 0.81388 and |right.z| = 0.58104 along the frame's long axis and
# cos(pitch) = 0.96644 for verticals. See dna.framing_why for the whole gauge table.
const P: float = 0.098                 # blade pitch: 8.69 px, leaving a 2.89 px gap
const BLADE_W: float = 0.056           # 5.80 px of screen width with the depth
const BLADE_D: float = 0.014
const H_MIN: float = 0.09              # a trait of 0.0 is still a body, not a hole
const H_SPAN: float = 0.72             # 0.1 of trait = 7.72 px of height
## THE FOUNDER MARK IS A TICK, NOT A BODY, AND THAT WAS SETTLED BY LOOKING. It was
## first a full-height bone rib standing proud on each blade's face. Every number was
## green - `evidence` measured 18.98% mean focus, above the WEAK bar, no twins - and
## the rendered tile was a white scaffold in which the coloured blades were slivers:
## the axis that adds the proof was hiding the trait the other axis moves. A rib
## 3.85 px wide on a blade 5.96 px wide covers 65% of its face.
##
## The tick costs bite and is worth it: `evidence` fell to 17.16% mean and `variation`
## ROSE from 23.72% to 24.93%, because the trait is now visible for it to change.
## TAB_W 0.090 is chosen against the PITCH, not against the blade: 0.090 x 0.81388 +
## 0.020 x 0.58104 = 0.08487 m of screen against 0.07976 m of pitch, so adjacent ticks
## abut with 0.57 px of overlap. A rank of equal founders therefore reads as one
## continuous line, which is what equal founders are; ticks at different heights never
## meet. The overhang past the blade is 1.54 px each side.
const TAB_W: float = 0.090             # 9.42 px, centred ON the founder height
const TAB_T: float = 0.030             # 3.68 px
const TAB_D: float = 0.020
## Only drawn where the founder stands ABOVE the blade's top, so the tick is never a
## floating mark: a lineage that lost height carries a bone post up to where it began,
## and a lineage that is GONE carries one all the way from the bed.
const RISER_W: float = 0.020           # 2.71 px
const RISER_D: float = 0.014

const APRON_H: float = 0.05
const SLAB_H: float = 0.02
const BED_Y: float = 0.07              # APRON_H + SLAB_H — every blade's base
const RANK_W: float = 0.98             # N_LINEAGES * P, asserted at _ready
const STILE_BAY: float = 0.12
const RIGHT_MARGIN: float = 0.05
const PLOT_W: float = 1.15             # STILE_BAY + RANK_W + RIGHT_MARGIN
const PLOT_GAP: float = 0.13
const PLOT_D: float = 0.24
const APRON_MARGIN: float = 0.10
const APRON_Z0: float = -0.16
const APRON_Z1: float = 0.30
const RUN_W: float = 6.27              # 5 * PLOT_W + 4 * PLOT_GAP
const APRON_W: float = 6.47            # RUN_W + 2 * APRON_MARGIN

const STILE_DX: float = -0.52          # -PLOT_W * 0.5 + 0.055, inside the bay
const STILE_W: float = 0.026
const STILE_D: float = 0.020
const STILE_H: float = 0.86
const TICK_L: float = 0.050
const TICK_T: float = 0.022
const TICK_D: float = 0.016
## THE GAUGE IS FIXED ACROSS BOTH AXES (law 5). These are trait values, not
## quantiles and not fractions of whatever this plot happens to span, so a tick means
## the same number in all nine tiles and in all five plots.
const TICKS: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]

const RAIL_T: float = 0.024
const RAIL_D: float = 0.012
## BOTH MEAN RAILS STAND IN FRONT OF THE RANK. The first version hung the founding
## rail 0.09 m BEHIND the blades, where the arithmetic says it would have been
## invisible: at this standpoint a sight line descends 0.2660 m per metre of ground
## travel, so 0.09 m of standoff buys only 0.0195 m of clearance and every blade
## taller than 0.4815 m — most of runaway's rank — would have hidden it. A mark
## drawn behind the artifact's own furniture is the operations_gallery fault, and it
## is cheaper to catch it in arithmetic than in a render.
const RAIL_Z_FOUND: float = 0.092
const RAIL_Z_FINAL: float = 0.050

const STONE: Color = Color(0.34, 0.345, 0.36)
const BED_C: Color = Color(0.285, 0.29, 0.305)
## Bone, not grey. The founder mark started at Color(0.60, 0.61, 0.63) and measured
## 3.80% against the blade it stands on at `variation = none` — under the twin bar —
## because a mid grey and a mid-trait blade have almost the same luminance. Lifting it
## to bone moved that pair to 16.10%. It stays LIGHT rather than going dark so it is
## still legible where it rises ABOVE a blade, against the dark backdrop.
const GHOST_C: Color = Color(0.88, 0.89, 0.84)
const ACCENT: Color = Color(0.95, 0.55, 0.12)
## The trait ramp. Fixed endpoints at trait 0.0 and 1.0, identical in every plot and
## at every rung of both axes, so a colour means one number everywhere in the garden.
const COLD: Color = Color(0.20, 0.40, 0.80)
const WARM: Color = Color(0.92, 0.62, 0.18)

## True once _ready has built the garden. apply_grid_config before that is a value
## change with no geometry to answer it — the force_pad fault.
var _built: bool = false


func _ready() -> void:
	# The grid stamps config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config deferred, i.e. after this, so the meta read happens here.
	_read_grid_config_meta()
	_check_family_list()
	_check_arithmetic()
	_build()
	_built = true


# ── the vocabulary ───────────────────────────────────────────────────────────
func _family() -> PackedStringArray:
	return SELECTION_SRC.SELECTIONS


## Push an error in BOTH directions. A family value with no plot here would be a
## regime this garden silently drops; a plot with no family value would be a sixth
## theory this garden invented. Neither is allowed to pass quietly, and neither is
## catchable by check_dna_declarations, which reads @export_enum hints out of the
## source text and has no opinion about a list that is not an axis.
func _check_family_list() -> void:
	var canon: PackedStringArray = _family()
	for i in range(canon.size()):
		var value: String = canon[i]
		if not PLOTS.has(value):
			push_error("selection_garden: the selection family declares '%s' and this garden stands no plot for it. Add one or refuse the value on the record." % value)
	for i in range(PLOTS.size()):
		var mine: String = PLOTS[i]
		if not canon.has(mine):
			push_error("selection_garden: this garden stands a '%s' plot and the selection family no longer declares it. The vocabulary has moved." % mine)


## The layout constants are written out so the doc comments and the build are the
## same numbers, which means they can drift. This is the one place that says so.
func _check_arithmetic() -> void:
	if not is_equal_approx(RANK_W, float(N_LINEAGES) * P):
		push_error("selection_garden: RANK_W %f is not N_LINEAGES * P %f" % [RANK_W, float(N_LINEAGES) * P])
	if not is_equal_approx(PLOT_W, STILE_BAY + RANK_W + RIGHT_MARGIN):
		push_error("selection_garden: PLOT_W %f is not the bay plus the rank plus the margin" % PLOT_W)
	if not is_equal_approx(RUN_W, 5.0 * PLOT_W + 4.0 * PLOT_GAP):
		push_error("selection_garden: RUN_W %f does not fit five plots and four gaps" % RUN_W)
	if not is_equal_approx(APRON_W, RUN_W + 2.0 * APRON_MARGIN):
		push_error("selection_garden: APRON_W %f is not the run plus two margins" % APRON_W)
	if not is_equal_approx(BED_Y, APRON_H + SLAB_H):
		push_error("selection_garden: BED_Y %f is not the apron plus the slab" % BED_Y)


# ── the hash ─────────────────────────────────────────────────────────────────
func _hash3(a: int, b: int, c: int) -> int:
	var h: int = (a * 374761393 + b * 668265263 + c * 1442695041 + HASH_SEED * 2246822519) & HASH_MASK
	h = (h ^ (h >> 13)) & HASH_MASK
	h = (h * 1274126177) & HASH_MASK
	return (h ^ (h >> 16)) & HASH_MASK


func _u01(a: int, b: int, c: int) -> float:
	return float(_hash3(a, b, c)) / 4294967296.0


func _rung() -> int:
	var i: int = VARIATIONS.find(variation)
	return i if i >= 0 else VARIATIONS.size() - 1


# ── the founding population ──────────────────────────────────────────────────
## ONE founding set, drawn once, centred exactly, scaled to the rung's half-spread
## and SORTED. The sort is what makes a slot mean a lineage AND makes the rank
## readable: slot order is founding rank, so a plot is a profile, and `split`'s two
## morphs land as two contiguous blocks rather than as scattered dots. The layout is
## a presentation order that is stated; the heights on it are the model's output.
##
## Scaling by the widest member rather than by a standard deviation is deliberate:
## it makes the rung mean EXACTLY what it says — at `wide` the founding set spans
## 0.5 +/- 0.30 — so the gauge on the stile and the rung on the knob are the same
## number. The SHAPE inside that range is still the hash's, not a designer's ramp.
func _founders() -> Array[float]:
	var spread: float = VAR_SPREAD[_rung()]
	var raw: Array[float] = []
	raw.resize(N_LINEAGES)
	var total: float = 0.0
	for i in range(N_LINEAGES):
		raw[i] = 2.0 * _u01(0, 0, i) - 1.0
		total += raw[i]
	var mean: float = total / float(N_LINEAGES)
	var widest: float = 0.000001
	for i in range(N_LINEAGES):
		raw[i] = raw[i] - mean
		widest = maxf(widest, absf(raw[i]))
	var out: Array[float] = []
	out.resize(N_LINEAGES)
	for i in range(N_LINEAGES):
		out[i] = clampf(0.5 + spread * (raw[i] / widest), 0.0, 1.0)
	return _sorted(out)


## Insertion sort with a strict comparison, so equal values keep their input order.
## Array.sort_custom is not stable and at `variation = none` every founder is equal —
## a sort whose result depends on the algorithm would make two builds of one value
## two different objects. Ten elements; the cost is nothing.
func _sorted(v: Array[float]) -> Array[float]:
	# Copied element by element rather than with duplicate(), whose return type on a
	# typed array is exactly the kind of thing that parses today and fails on a
	# different engine build. Ten elements.
	var out: Array[float] = []
	out.resize(v.size())
	for i in range(v.size()):
		out[i] = v[i]
	for i in range(1, out.size()):
		var key: float = out[i]
		var j: int = i - 1
		while j >= 0 and out[j] > key:
			out[j + 1] = out[j]
			j -= 1
		out[j + 1] = key
	return out


# ── the run: ONE function, five weightings ───────────────────────────────────
## Fitness under `regime`, given the standing traits, the current mean and the
## founding mean. This is the only place the five theories differ.
func _fitness(regime: String, xs: Array[float], xbar: float, xbar0: float) -> Array[float]:
	var w: Array[float] = []
	w.resize(N_LINEAGES)
	var beta: float = RUN_B0 + RUN_BK * (xbar - xbar0)
	for i in range(N_LINEAGES):
		if regime == "uniform":
			var d: float = (xs[i] - OPT) / SEL_S
			w[i] = exp(-(d * d))
		elif regime == "runaway":
			w[i] = exp(beta * (xs[i] - xbar))
		elif regime == "split":
			w[i] = exp(SPLIT_GD * absf(xs[i] - MID))
		else:
			# `drift` has no fitness function at all, and `culled` never breeds.
			w[i] = 1.0
	return w


## Run ONE regime on the founding set to GENERATIONS. Writes the surviving traits
## into `xs` and the alive mask into `alive`. Every plot in the garden is one call.
func _run_regime(regime: String, founders: Array[float], xs: Array[float], alive: Array[bool]) -> void:
	var mutate: float = VAR_MUTATE[_rung()]
	var xbar0: float = 0.0
	for i in range(N_LINEAGES):
		xs[i] = founders[i]
		alive[i] = true
		xbar0 += founders[i]
	xbar0 /= float(N_LINEAGES)

	for t in range(GENERATIONS):
		var live: PackedInt32Array = PackedInt32Array()
		var sum_live: float = 0.0
		for i in range(N_LINEAGES):
			if alive[i]:
				live.append(i)
				sum_live += xs[i]
		if live.size() == 0:
			return
		var xbar: float = sum_live / float(live.size())

		if regime == "culled":
			# TRUNCATION WITHOUT REPLACEMENT — a cull removes, it does not breed.
			# STRICTLY below the threshold dies, so at `variation = none` there is no
			# bottom and nobody is removed. That is not a special case bolted on; it is
			# what "remove the unfit" means when nobody is less fit than anybody.
			var k: int = maxi(1, int(float(live.size()) * CULL_SURV))
			var ordered: Array[float] = []
			for i in range(live.size()):
				ordered.append(xs[live[i]])
			ordered = _sorted(ordered)
			var thr: float = ordered[ordered.size() - k]
			for i in range(live.size()):
				if xs[live[i]] < thr:
					alive[live[i]] = false
			for i in range(N_LINEAGES):
				if alive[i]:
					xs[i] = clampf(xs[i] + mutate * (2.0 * _u01(300 + t, 0, i) - 1.0), 0.0, 1.0)
			continue

		var w: Array[float] = _fitness(regime, xs, xbar, xbar0)
		var nxt: Array[float] = []
		nxt.resize(N_LINEAGES)
		for j in range(N_LINEAGES):
			# ASSORTATIVE MATING IS PART OF WHAT `split` NAMES, and it is the one place
			# a regime touches the parent POOL rather than the weights. Disruptive
			# fitness on its own was measured on this founding set and went unimodal —
			# the heavier tail won outright and the plot was a second `runaway`. Like
			# breeds with like is the textbook requirement for two morphs to survive
			# disruptive selection, so it is stated here rather than hidden in a
			# fitness curve that would have had to be bent until the picture came out.
			var pool: PackedInt32Array = PackedInt32Array()
			if regime == "split":
				var side: bool = xs[j] > MID
				for i in range(N_LINEAGES):
					if (xs[i] > MID) == side:
						pool.append(i)
			if pool.size() == 0:
				for i in range(N_LINEAGES):
					pool.append(i)
			var total: float = 0.0
			for i in range(pool.size()):
				total += w[pool[i]]
			var r: float = _u01(100 + t, 1, j) * total
			var acc: float = 0.0
			var parent: int = pool[pool.size() - 1]
			for i in range(pool.size()):
				acc += w[pool[i]]
				if r <= acc:
					parent = pool[i]
					break
			nxt[j] = clampf(xs[parent] + mutate * (2.0 * _u01(200 + t, 2, j) - 1.0), 0.0, 1.0)
		for i in range(N_LINEAGES):
			xs[i] = nxt[i]


# ── construction ─────────────────────────────────────────────────────────────
func _height(trait_value: float) -> float:
	return H_MIN + H_SPAN * trait_value


func _ramp(trait_value: float) -> Color:
	return COLD.lerp(WARM, clampf(trait_value, 0.0, 1.0))


func _plot_cx(k: int) -> float:
	return -RUN_W * 0.5 + PLOT_W * 0.5 + float(k) * (PLOT_W + PLOT_GAP)


func _build() -> void:
	# remove_child first: queue_free is deferred, so a rebuild would otherwise stand
	# the new garden inside the old one for a frame — and a capture taken in that
	# frame is a photograph of two variants at once.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_box(st, Vector3(0.0, APRON_H * 0.5, (APRON_Z0 + APRON_Z1) * 0.5),
		Vector3(APRON_W, APRON_H, APRON_Z1 - APRON_Z0), STONE)

	var founders: Array[float] = _founders()
	var fmean: float = 0.0
	for i in range(N_LINEAGES):
		fmean += founders[i]
	fmean /= float(N_LINEAGES)

	for k in range(PLOTS.size()):
		var regime: String = PLOTS[k]
		var cx: float = _plot_cx(k)
		_box(st, Vector3(cx, APRON_H + SLAB_H * 0.5, 0.0), Vector3(PLOT_W, SLAB_H, PLOT_D), BED_C)

		var xs: Array[float] = []
		xs.resize(N_LINEAGES)
		var alive: Array[bool] = []
		alive.resize(N_LINEAGES)
		_run_regime(regime, founders, xs, alive)

		var rank_x0: float = cx - PLOT_W * 0.5 + STILE_BAY
		for i in range(N_LINEAGES):
			var bx: float = rank_x0 + (float(i) + 0.5) * P
			if alive[i]:
				var h: float = _height(xs[i])
				_box(st, Vector3(bx, BED_Y + h * 0.5, 0.0), Vector3(BLADE_W, h, BLADE_D), _ramp(xs[i]))
			if evidence != "result":
				# The founder of THIS lineage, on this blade, in every plot - and on
				# every slot, INCLUDING the ones a cull emptied, which is what makes
				# `culled` legible as a removal rather than as a short rank. Proud in
				# +z so the tick is never a body standing behind one.
				var gh: float = _height(founders[i])
				var top: float = _height(xs[i]) if alive[i] else 0.0
				if gh > top:
					var rise: float = gh - top
					_box(st, Vector3(bx, BED_Y + top + rise * 0.5, BLADE_D * 0.5 + RISER_D * 0.5),
						Vector3(RISER_W, rise, RISER_D), GHOST_C)
				_box(st, Vector3(bx, BED_Y + gh, BLADE_D * 0.5 + TAB_D * 0.5),
					Vector3(TAB_W, TAB_T, TAB_D), GHOST_C)

		if evidence == "longhand":
			_rule_plot(st, cx, xs, alive, fmean)

		# The exhibited word, present at EVERY value of both axes, so no tile carries
		# a rendered word naming its own variant.
		_letter(regime, cx)

	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Garden"
	mi.mesh = mesh
	mi.material_override = _vertex_material()
	add_child(mi)


## The gauge, and the two means. The stile carries five FIXED trait levels; the rails
## carry the founding mean (bone) and this plot's own final mean (accent). Their
## separation is the response to selection, read against a scale that does not move.
func _rule_plot(st: SurfaceTool, cx: float, xs: Array[float], alive: Array[bool], fmean: float) -> void:
	var sx: float = cx + STILE_DX
	_box(st, Vector3(sx, BED_Y + STILE_H * 0.5, 0.0), Vector3(STILE_W, STILE_H, STILE_D), STONE)
	for i in range(TICKS.size()):
		var y: float = BED_Y + _height(TICKS[i])
		# Tabs point LEFT, into the plot gap, away from the rank. Pointing them right
		# would put a 0.05 m tab 0.033 m from the first blade's centre, i.e. inside it.
		_box(st, Vector3(sx - STILE_W * 0.5 - TICK_L * 0.5, y, 0.0),
			Vector3(TICK_L, TICK_T, TICK_D), ACCENT)

	var live_sum: float = 0.0
	var live_n: int = 0
	for i in range(N_LINEAGES):
		if alive[i]:
			live_sum += xs[i]
			live_n += 1
	var xmean: float = live_sum / float(maxi(1, live_n))
	var rx: float = cx - PLOT_W * 0.5 + STILE_BAY + RANK_W * 0.5
	_box(st, Vector3(rx, BED_Y + _height(fmean), RAIL_Z_FOUND), Vector3(RANK_W, RAIL_T, RAIL_D), GHOST_C)
	_box(st, Vector3(rx, BED_Y + _height(xmean), RAIL_Z_FINAL), Vector3(RANK_W, RAIL_T, RAIL_D), ACCENT)


## ALIGNMENT IS NOT ASSUMED. Label3D defaults to HORIZONTAL_ALIGNMENT_CENTER, so a
## tab hung at the plot's centre x is centred on it — but it is set explicitly here,
## because a LEFT-aligned block hangs from its origin and runs right, which is how
## operations_gallery pushed a 0.467 m block past its own panel.
##
## Billboard is OFF, which also keeps LabelFramer out: frame_labels() returns false
## for BILLBOARD_DISABLED (LabelFramer.gd:99) and would otherwise bolt an opaque
## panel and a bezel behind every one of these.
##
## THE LETTERING OCCLUDES A BAND AND THE BAND WAS MEASURED, in ONE frame of
## reference — absolute y from the artifact origin — because mixing the blade's
## LENGTH with its TOP is how this arithmetic goes wrong. At font 80 x pixel_size
## 0.0013 the em is 0.104 m, so the word spans absolute y 0.056 .. 0.160 at z = 0.285.
## A sight line to the rank plane rises 0.2660 x 0.81388 x 0.285 = 0.0617 m, so on the
## rank the word screens absolute y 0.1177 .. 0.2217. The shortest blade anywhere in
## the sweep is split's low morph at `wide`: trait 0.226, length 0.2527, top at
## BED_Y + 0.2527 = 0.3227 absolute — clear of the band by 0.101 m, i.e. 10.8 px of
## visible blade above the word. The word is identical in every tile, so what it hides
## it hides from all nine equally.
func _letter(word: String, cx: float) -> void:
	var label := Label3D.new()
	label.name = "Plot_" + word
	label.text = word
	label.font_size = 80
	label.pixel_size = 0.0013
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.modulate = Color(0.88, 0.90, 0.94)
	label.position = Vector3(cx, APRON_H + 0.006, APRON_Z1 - 0.015)
	add_child(label)


# ── mesh helpers ─────────────────────────────────────────────────────────────
func _vertex_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.85
	m.metallic = 0.0
	# No emission anywhere in this file. curation_station hands every artifact it
	# curates {"emissive": false}; here that key is a genuine no-op rather than a
	# silently ignored one, and apply_grid_config says so.
	return m


## THE NORMAL IS PASSED IN, NOT DERIVED FROM THE WINDING. Every quad here is
## axis-aligned and its outward direction is known at the call site.
func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c: Color, nrm: Vector3) -> void:
	var pts: Array[Vector3] = [p0, p1, p2, p0, p2, p3]
	for i in range(6):
		st.set_color(c)
		st.set_normal(nrm)
		st.add_vertex(pts[i])


func _box(st: SurfaceTool, centre: Vector3, size: Vector3, c: Color) -> void:
	var x0: float = centre.x - size.x * 0.5
	var x1: float = centre.x + size.x * 0.5
	var y0: float = centre.y - size.y * 0.5
	var y1: float = centre.y + size.y * 0.5
	var z0: float = centre.z - size.z * 0.5
	var z1: float = centre.z + size.z * 0.5
	_quad(st, Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1), c, Vector3.UP)
	_quad(st, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x0, y0, z0), c, Vector3.DOWN)
	_quad(st, Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0), c, Vector3.FORWARD)
	_quad(st, Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x1, y1, z1), c, Vector3.BACK)
	_quad(st, Vector3(x0, y0, z1), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x0, y1, z1), c, Vector3.LEFT)
	_quad(st, Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), c, Vector3.RIGHT)


# ── the three doors, one validator each ──────────────────────────────────────
func _is_variation(v: String) -> bool:
	return VARIATIONS.has(v)


func _is_evidence(v: String) -> bool:
	return EVIDENCES.has(v)


## Walk the ancestor chain for config_* metadata the grid stamps before _ready.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_variation"):
			var a: String = str(node.get_meta("config_variation")).strip_edges().to_lower()
			if _is_variation(a):
				variation = a
		if node.has_meta("config_evidence"):
			var e: String = str(node.get_meta("config_evidence")).strip_edges().to_lower()
			if _is_evidence(e):
				evidence = e
		node = node.get_parent()


## Guarded: rebuild only when a declared axis actually CHANGED, and only after
## _ready has built once. An unrecognised word keeps the standing value, so a typo
## in a map token lands on the shipped look rather than on a half-recognised state.
## A key this artifact does not own (curation_station's `emissive`) falls straight
## through and rebuilds nothing.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("variation"):
		var a: String = str(config_data["variation"]).strip_edges().to_lower()
		if _is_variation(a) and a != variation:
			variation = a
			changed = true
	if config_data.has("evidence"):
		var e: String = str(config_data["evidence"]).strip_edges().to_lower()
		if _is_evidence(e) and e != evidence:
			evidence = e
			changed = true
	if changed and _built:
		_build()
