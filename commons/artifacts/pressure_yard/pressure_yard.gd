## pressure_yard — the `selection` family, all four substrates standing at once.
##
## SIX registry names declare `selection`. They resolve to FOUR scenes:
## evolving_flowers/evolvingflowers are one, evolutionary_algorithms/
## particle_randomness_evolutionary are one. Four bays IS the whole family;
## nothing has been dropped. (One scene under many registry names is this
## corpus's most common hidden family — found here for the sixth and seventh
## time. The tell is identical export counts across sibling tokens.)
##
## ── WHAT THE WORD MEANS IN EACH CODEBASE, AND ITS CURRENCY ───────────────────
##
## The four members agree on the VOCABULARY — drift, uniform, culled, runaway,
## split, character for character in three of them — and agree on nothing else.
## Each measures its population in a different quantity, and there is no unit
## conversion between them:
##
##   A  evolved_creatures            LEG LENGTH IN METRES. leg_size.y, one scalar
##      evolvedcreatures.gd          taking 0.45 / 0.80 / 1.15 / 1.60 / 2.50 m.
##   B  evolvingflowers              CROWN RADIUS IN METRES. center_size +
##      evolvingflowers.gd           petal_length; create_petal_mesh writes the
##                                   vertex z as `length + genome.center_size`.
##   C  non_teleological_evolution   SPHERE RADIUS IN METRES. There is no body
##      non_teleological_*.gd        plan at all: a creature is one sphere, and
##                                   `size` IS the radius (base mesh r = 0.03,
##                                   scaled by size/0.03).
##   D  evolutionary_algorithms      DISTANCE FROM THE POPULATION'S OWN CENTROID,
##      extrem_randomness.gd         IN METRES. This substrate has no genome and
##                                   no trait, so the thing selection acts on IS
##                                   the coordinate.
##
## WHERE THEY AGREE. Three of the four say the same thing about `culled`, and
## they were written by three different hands: culling removes members WITHOUT
## TOUCHING THE SURVIVOR. Leg 1.15 m either way (evolvedcreatures.gd:316-329);
## crown 0.30 + 1.00 m either way (both branches call _optimum_genome); sphere
## radius UNIFORM_RADIUS 0.035 == CULLED_RADIUS 0.035 (:86, :92). So in the
## spread channel bays A, B and C at uniform and at culled must be IDENTICAL TO
## THE BYTE. That is three independent codebases agreeing to zero, and it is the
## sharpest falsifiable thing this row asserts.
##
## WHERE THEY DISAGREE, and it is not a detail:
##
##  1. `runaway` DOES NOT EXIST in bay D. extrem_randomness.gd:86 declares FOUR
##     strings — ["drift", "uniform", "culled", "split"] — verified character for
##     character. _apply_selection (:634-638) returns early on anything else and
##     _winner_count (:501-506) has no runaway branch. The family's runaway means
##     the population at its own max_population ceiling; this substrate has no
##     ceiling because it has no birth (`particles` is appended to only inside
##     create_particles and is never grown or shortened). So bay D stands EMPTY
##     at runaway, with its pad, the plinth beneath it and the rail above it
##     still there. LAW 13 refusal, declared, not discovered.
##     THE REJECTED ALTERNATIVE was to reproduce the runtime behaviour, where an
##     unknown value silently leaves whatever was last built in force. That would
##     publish a silent fallback as an answer — the science_screen failure
##     exactly, where a typo ran every stage green and the verdict was a fact
##     about the registry.
##  2. Only ONE bay's runaway is a headcount. C grows 30 -> 120 bodies; A and B
##     keep their 20 and 16 and grow the BODY instead. So the word names a
##     population size in one vocabulary and a body size in two others.
##  3. `culled` is the only value that moves the headcount in A, B and C, and it
##     moves NOTHING in D — where nothing is ever born and nothing ever dies.
##
## ── WHAT THIS ARTIFACT ARGUES ────────────────────────────────────────────────
##
## A selection statement makes TWO separable claims about a population: how far
## apart its members stand in their own currency, and how many of them are still
## standing. `channel` picks which one the rack answers, and each value PINS the
## other so it cannot leak:
##
##   spread  every bay carries EXACTLY SIX slats at every selection value, six
##           order statistics at p = (k+0.5)/6. Headcount is the constant 6, so
##           count carries literally zero signal; only the heights move.
##   count   the six slats are pinned to a FIXED RUNG LADDER — identical world
##           heights in every bay at every value — and only how many rungs are
##           occupied varies. Height is the constant, so spread carries zero.
##
## Neither channel can read the other's number. This is tier_terrarium's
## construction (body varied extent at a pinned facet count; grain varied facet
## count at a pinned height) applied to the two halves of a selection statement.
##
## THE FINDING THE ROW EXISTS FOR: counted by heads, a five-word vocabulary is
## THREE words. No substrate changes headcount between drift, uniform and split
## — 20/20/20, 16/16/16, 30/30/30, 100/100/100 — so those three tiles are byte
## identical in all four bays. The critic's twin check will name all three pairs
## and the axis mean will sag. Read the CONDITIONAL split by co-axis context,
## not the mean (the csg_union_demo precedent, where flush/seam/shared measured
## 0.00% to the byte at fusion=distinct because there was no join to mark).
## Those three zeros are also a deliberate SELF-TEST: any nonzero reading there
## is not a finding about selection, it is proof that the rig is not
## deterministic, and it invalidates every other number in the pass.
##
## ── WHAT THE GAUGE FOUND, BEFORE THE SHUTTER ─────────────────────────────────
##
## The whole row was rasterised through the harness camera with a z-buffer
## before a line of this file was written. Four things came back that paper
## arithmetic had not said, and each changed the geometry or the claim:
##
##  1. NESTING IN x AND z IS NOT ENOUGH. Slat k+1 is shorter and shallower than
##     slat k so that a monomorphic population renders as slat 0 alone — but at
##     equal value their top and bottom faces were COPLANAR, which is z-fighting
##     speckle, i.e. a non-deterministic still. The slats therefore shrink in y
##     as well (0.290 - 0.002k), which cost 0.020 m of rail height to keep the
##     thinnest slat over the 10 px bar: slat 5 measures 10.08 px and slat 0
##     10.54 px against a floor of 10.
##  2. BAY D AT `culled` IS ONE FUSED BAR, AND THAT IS CORRECT. Its six order
##     statistics are 0.97 px apart — ten times under this rack's own resolution
##     of 0.0962 in v units. The population has collapsed into a knot, and the
##     rack photographs a collapse as a collapse. Do not read the merge as a
##     render fault; the source substrate's own knot is likewise under the
##     legibility floor at its own canonical camera.
##  3. `split` IS BIMODAL IN THREE CURRENCIES AND UNIMODAL IN THE FOURTH. Bays
##     A, B and C separate their two morphs by 47.81, 36.37 and 54.04 px. Bay D
##     separates by 1.94 px and renders ONE bar — because its currency is
##     distance from the centroid, and splitting a population into two SYMMETRIC
##     knots leaves every member the SAME distance out. One word; in three
##     vocabularies it is a fork, and in the fourth it is invisible by
##     construction. That is the sharpest thing the currency choice says.
##  4. BAY B's drift fan does not fully separate: its rungs are 8.66 px apart
##     against a 10.54 px slat, so the six touch. Named in advance. They are the
##     quantiles of a TRAPEZOIDAL sum of two uniforms, which piles up in the
##     middle; every slat still owns 3200-3700 px of the 760 frame.
##
## EVERY LADDER'S RUNG SEPARATION, measured, in local screen-y px. 0.00 means a
## monomorphic population, which is a rack of one mark and not a fault; the three
## marked lines are the ones under the 10 px floor and each is a fact about the
## substrate rather than about the drawing:
##
##          drift   uniform  culled   runaway  split
##     A      0.00     0.00    0.00      0.00   47.81
##     B      8.66 <   0.00    0.00      0.00   36.37
##     C     10.39     0.00    0.00      0.00   54.04
##     D     17.31    10.27    0.97 <   (none)   1.94 <
##
## Bay D's uniform at 10.27 px is the whole row's tightest legal rung and it
## clears by 0.27 px. If anything downstream lowers dna.framing, that ladder is
## the first thing to go — but framing does NOT move this number, because the
## critic crops to the subject bbox before resizing (see the CAMERA note below),
## and the bbox is set by furniture that never moves. Changing the TRAVEL or the
## slat thickness would move it; changing the framing would not.
##
## ── THE PREDICTION, PRE-REGISTERED ───────────────────────────────────────────
##
## THE HEADLINE IS AN 80-CELL ZERO/NON-ZERO TABLE: 10 selection pairs x 2
## channels x 4 bays. 24 cells must change by NOTHING AT ALL and 56 must change.
## Verified against the z-buffer raster before the shutter: 24 / 56, exactly.
## An equality across 80 declared cells cannot come out right by luck.
## To check it against the real tiles, crop each bay's screen column out of the
## published 760 PNGs — a bay spans its centre-screen-x +- 0.412729 m, i.e.
## 106.6 px wide with 40.5 px of daylight either side — and diff.
## FALSIFIED IF any predicted-zero cell measures focus > 2.0% on its bay crop,
## or any predicted-non-zero cell measures < 2.0%.
##
## PREDICTED CLOSEST PAIRS. The design's parallelogram model and this file's
## z-buffer raster disagree by about 2x, so BOTH are recorded and the LOWER is
## the gate. Every prediction in this corpus that named a pair and a number has
## UNDER-predicted — by 1.5x, 1.7x, 3.5x and 6.7x — because a flat-shaded model
## has no shadow, no AO and no antialiasing. The number is a FLOOR, not a
## forecast:
##
##                                 design model   z-buffer raster
##   count   drift/uniform             0.000%           0.000%    designed
##   count   drift/split               0.000%           0.000%    byte-identity
##   count   uniform/split             0.000%           0.000%    (the null test)
##   spread  uniform/culled            3.944%           8.012%    <- THE GATE
##   spread  culled/runaway            5.414%           8.801%
##   LOUDEST spread  drift/runaway    14.200%          24.914%
##
## IF THE SWEEP COMES BACK BELOW 3.944% ON spread uniform/culled, STOP. That is
## the operations_gallery signature — the only case in the corpus to land under
## its own prediction, and the only one that was broken.
##
## SUBJECT SHARE swings 8.23% -> 21.29% across the ten tiles, because a
## monomorphic bay renders one slat where a dispersed bay renders six. The critic
## takes the MAX over tiles, so it will report ~21.3% and there is no NO RENDER
## risk. LAW 10 SEPARATELY: the union box is 76.88% OF FRAME WIDTH. The row is
## sparse inside its own box BY CONSTRUCTION — most of a bay's bounding volume is
## the empty travel above and below its slats — so the swing in subject share is
## the axis working, not inconsistent framing, and is not a reason to crop in.
##
## ── CORRECTIONS TO THE RECORD (LAW 1: the code wins) ─────────────────────────
##
##  · machinelearning.json:2102 says evolved_creatures' "Morphology and behavior
##    co-evolve". FALSE at all five values. _mutate touches hip amplitude,
##    frequency, phase and the two masses only — never torso_size or leg_size —
##    and _apply_morph overwrites the crossover's lerp with the value's fixed
##    constant every generation. The drawn body is a constant. Only masses
##    (never drawn) and gait (invisible in a still) evolve.
##  · evolvingflowers' `_optimum_genome` is not the optimum. Run its own
##    calculate_fitness on the authored genomes: optimum 104.00, runaway 112.75,
##    split-east 111.00. `uniform` there is an also-ran, and the row must not be
##    captioned as if runaway overshoots the taste — on the numbers this
##    substrate says the opposite. Not load-bearing here: bay B renders crown
##    radius, not fitness.
##  · evolutionary_algorithms has never been photographed at all. The sweep's
##    AABB counts MeshInstance3D and MultiMeshInstance3D only; that artifact is
##    built from CSGSphere3D, so _subtree_aabb falls through to its 1 m fallback
##    box and the population lands OUTSIDE the frame. Four values would have
##    produced four near-identical fringe tiles. Hence: this artifact's body is
##    MeshInstance3D throughout, and inherits no framing assumption from it.
##  · BAY D'S NUMBERS ARE THE ONLY ONES THAT ARE NOT LITERALS, and this is the
##    weakest thing in the pass. A, B and C read their spread off named
##    constants. extrem_randomness has no trait and no literal spread except
##    SPLIT_SEPARATION = 1.25 (:95); its drift, uniform and culled extents come
##    from integrating PER-FRAME velocity constants (0.9 damping, 0.5 follow,
##    2.0 beeline — none scaled by delta) over the harness's 1.1 s settle, so
##    they move with frame rate and are facts about the capture as much as about
##    the artifact. They are baked here as declared constants because LAWS 4 and
##    5 forbid simulating them. Read the other way this is the row's sharpest
##    answer: in one of the four currencies the word does not name a quantity
##    that exists at t = 0.
##
## ── WHAT THE ROW FORECLOSES ──────────────────────────────────────────────────
##
## Six order statistics cannot show WHICH members survive. evolved_creatures'
## culled keeps the four CORNER slots [0,4,15,19]; evolvingflowers keeps plots
## [0,6,11], no two sharing a row or column; non_teleological RE-PACKS six
## survivors into a fresh 3x2 block rather than keeping a subset of the thirty.
## Survivorship pattern is gone. So is the third question the family answers —
## how many distinct KINDS are left — which is the only readout that would
## separate drift from uniform where headcount cannot.
##
## ── LAWS 4 AND 5 ─────────────────────────────────────────────────────────────
##
## Every source substrate is live at at least one value and every one of them
## destroys its own still: evolved_creatures spawns RigidBody3D with 1.2 m of
## air under the feet and they land ~0.6 s before the shutter; evolvingflowers
## spins each head at 0.2 rad/s and tweens from scale 0.01 with TRANS_ELASTIC
## overshoot; non_teleological runs _process at drift only; evolutionary_
## algorithms chases a Lissajous target driven by Time.get_ticks_msec. So this
## file builds once in _ready, has no _process, no timer, no signal, no physics,
## no clock read, and no RandomNumberGenerator in it at all.
extends Node3D
class_name PressureYard

# ═════════════════════════════════════════════════════════════════════════════
# THE AXES — declared order is load bearing
# ═════════════════════════════════════════════════════════════════════════════
#
# `selection` FIRST because it is the longer list. build_dna_gallery trims values
# from the END of the LATER axis to fit the cross-product cap, so the longer list
# must lead or its tail values are the first casualties. At cap 16 this shape
# (5 x 2 = 10) fits whole; at a lowered cap `count` would lose values before
# `split` did, which is the right order of sacrifice.

## The family word, reused CHARACTER FOR CHARACTER (LAW 13). Three of the four
## substrates declare exactly this list; the fourth declares four of the five and
## its refusal is drawn rather than papered over — see the header.
## Default `drift`: it is the @export default of three of the four scenes
## (evolvedcreatures.gd:45, evolvingflowers.gd:63, non_teleological:71), and it
## is the un-pressured gen-0 state every other value is a departure from.
const SELECTIONS: PackedStringArray = ["drift", "uniform", "culled", "runaway", "split"]
@export_enum("drift", "uniform", "culled", "runaway", "split") var selection: String = "drift"

## WHICH half of a selection statement the rack answers. `channel` is deliberately
## reused rather than newly minted: it is a 2-member word across 2 files
## (operational_eye, tier_terrarium), measured not assumed, against `regime` at 15
## members over 13 vocabularies and `readout` at 18 over 7. Growing a 2-member
## word is cheaper than a sixth name for "which output of the same instrument is
## on show", and it makes this row and tier_terrarium directly comparable.
## Default `spread`: the strongest single reading. At spread all ten selection
## pairs differ somewhere; at count three of the five values are one picture.
const CHANNELS: PackedStringArray = ["spread", "count"]
@export_enum("spread", "count") var channel: String = "spread"

# ═════════════════════════════════════════════════════════════════════════════
# THE FOUR BAYS — every number below is read off the substrate that owns it
# ═════════════════════════════════════════════════════════════════════════════

const BAY_A: int = 0    ## evolved_creatures
const BAY_B: int = 1    ## evolvingflowers  (also `evolving_flowers`)
const BAY_C: int = 2    ## non_teleological_evolution
const BAY_D: int = 3    ## evolutionary_algorithms  (also `particle_randomness_evolutionary`)
const N_BAYS: int = 4

## BAY A — evolvedcreatures.gd. Currency: leg_size.y in metres.
## Normaliser is the largest leg the artifact can draw, so v = 1.000 is its own
## ceiling and not an invented one.
const A_NORM: float = 2.50          ## LEG_SIZE_RUNAWAY.y      :60
const A_WILD: float = 0.80          ## LEG_SIZE_WILD.y         :56
const A_CONVERGED: float = 1.15     ## LEG_SIZE_CONVERGED.y    :58
const A_SPLIT_SHORT: float = 0.45   ## LEG_SIZE_SPLIT_SHORT.y  :61
const A_SPLIT_LONG: float = 1.60    ## LEG_SIZE_SPLIT_LONG.y   :62

## BAY B — evolvingflowers.gd. Currency: crown radius = center_size + petal_length.
## drift is the only value with a DISTRIBUTION rather than authored genomes: the
## two draws are independent uniforms (:362, :365), so the crown radius is their
## TRAPEZOIDAL sum and its quantiles pile up in the middle. Normaliser is the
## supremum of that sum, 0.5 + 1.5.
const B_NORM: float = 2.00
const B_CS_LO: float = 0.20         ## center_size  randf_range(0.2, 0.5)  :365
const B_CS_HI: float = 0.50
const B_PL_LO: float = 0.50         ## petal_length randf_range(0.5, 1.5)  :362
const B_PL_HI: float = 1.50
const B_OPTIMUM: float = 0.30 + 1.00        ## _optimum_genome  center 0.3 + petal 1.0
const B_RUNAWAY: float = 0.40 + 1.50        ## _runaway_genome
const B_SPLIT_WEST: float = 0.25 + 0.70     ## _split_genome(true)
const B_SPLIT_EAST: float = 0.35 + 1.30     ## _split_genome(false)

## BAY C — non_teleological_evolution.gd. Currency: sphere radius in metres.
## RUNAWAY_RADIUS is also the top of drift's own draw range, which is why the
## normaliser and drift's ceiling are the same number.
const C_NORM: float = 0.05          ## RUNAWAY_RADIUS          :97
const C_DRIFT_LO: float = 0.02      ## randf_range(0.02, 0.05) :289
const C_DRIFT_HI: float = 0.05
const C_UNIFORM: float = 0.035      ## UNIFORM_RADIUS          :86
const C_CULLED: float = 0.035       ## CULLED_RADIUS           :92 — the SAME radius
const C_SPLIT_SMALL: float = 0.022  ## SPLIT_SMALL_RADIUS      :106
const C_SPLIT_LARGE: float = 0.048  ## SPLIT_LARGE_RADIUS      :107

## BAY D — extrem_randomness.gd. Currency: |x - xbar| in metres.
## READ THE HEADER BEFORE TRUSTING THESE. Only D_SPLIT_HALF is a literal
## (SPLIT_SEPARATION :95). The other three extents are integrated from per-frame
## velocity constants over the harness settle and are baked, not simulated.
const D_NORM: float = 1.60          ## half of drift's 3.2 m cloud, its widest state
const D_DRIFT_MAX: float = 1.600    ## the whole cloud: v runs the full 0..1
const D_UNIFORM_MAX: float = 0.950  ## a coherent streak still in transit at 2.0 m/s
const D_CULLED_MAX: float = 0.090   ## the knot: followers overrun the elites 2.5:1
const D_SPLIT_HALF: float = 1.25    ## SPLIT_SEPARATION :95 — the 2.50 m gap, halved

## HEADCOUNTS, per bay per selection, and each bay's own Nmax. The count channel
## reads nothing else. -1 marks the refusal (bay D has no runaway) and is NOT a
## zero: the word does not exist in that vocabulary, so no number is being
## reported as small.
##   A  POPULATION_SIZE 20 :23      CULLED_SLOTS.size() 4  :98
##   B  POPULATION_SIZE 16 :53      CULLED_PLOTS.size() 3  :75
##   C  initial_population 30 :45   CULLED_COUNT 6 :89     max_population 120 :46
##   D  num_particles 100 :8        never grown, never shortened
const HEADCOUNT: Array = [
	[20, 20, 4, 20, 20],
	[16, 16, 3, 16, 16],
	[30, 30, 6, 120, 30],
	[100, 100, 100, -1, 100],
]

# ═════════════════════════════════════════════════════════════════════════════
# THE RACK — every dimension gauged in pixels before it was chosen
# ═════════════════════════════════════════════════════════════════════════════
#
# CAMERA (capture_config_sweep.gd:67-72, :435-445): yaw 0.62, pitch -0.26,
# FOV 34, PAD 1.9, 760 px square. The projection basis is read off the harness's
# own look_at, not assumed:
#   screen-x half = 0.81388*hx + 0.58104*hz
#   screen-y half = 0.14937*hx + 0.96639*hy + 0.20923*hz
#
# UNION AABB over all 5 x 2 = 10 variants: (5.400, 4.040, 0.240), diagonal
# 6.74827, radius 3.374137. At dna.framing 0.46 the camera stands 9.6457 m out
# and the frame is 5.89799 m wide.
#
# THE GAUGE THE VERDICT IS COMPUTED ON IS NOT THE FRAME. artifact_dna_critic
# crops each pair to the union subject bbox (:60-66, :320-334) and only THEN
# resizes to 160x160 (:93), so framing cancels out of the mark gauge entirely:
#   35.286 px per screen-x metre, 33.606 px per screen-y metre.
# Computing from the visible frame width instead gives 27.176 px/m, a 1.30x
# understatement of every mark.
#
# AND A SLAB'S LAW-9 SIZE IS ITS LOCAL SCREEN THICKNESS, NOT ITS BBOX EXTENT.
# A slat's screen-y bbox spans 14.8 px, but 4.5 px of that is the rake of its own
# 0.900 m length across the pitched view. What a vertical move actually sweeps at
# a fixed screen-x is 2*(hy*0.96639 + hz*0.20923) = 10.54 px. Sizing off the bbox
# would have shipped a 6.3 px mark reported as 15.

## LAW 7, on the widest tenant over all ten variants (slat 0: hx 0.450, hz 0.080).
## The six slats are coaxial in x and z, so there is no intra-bay occlusion term.
##   tenant screen-x half = 0.450*0.81388 + 0.080*0.58104        = 0.412729 m
##   bay centres on screen = PITCH*0.81388                       = 1.139432 m
##   DAYLIGHT              = 1.139432 - 2*0.412729               = 0.313974 m
## which is 11.08 px on the critic's crop and 40.5 px in the published tile.
## Minimum legal pitch is 2*0.412729/0.81388 = 1.014 m; 1.400 is 1.38x that, so
## the daylight is a margin and not a hairline. A previous synthesis drafted at
## too small a pitch and every bay stood in front of the next.
const PITCH_M: float = 1.400
const BAY_X: Array = [-2.100, -0.700, 0.700, 2.100]

const N_SLATS: int = 6
## THE PACKING LIMIT, AND WHY SIX. Six marks needing 10 px of body and 10 px of
## gap want 120 px against a travel of 103.93 px. That is why the rack holds six
## slats and not eight, and why each population is rendered as six ORDER
## STATISTICS rather than as its 20 / 16 / 30 / 100 individuals — drawing the real
## headcount would put every individual at 3-5 px, which is exactly the size at
## which the source artifacts' own marks already measure as nothing (evolved_
## creatures' largest mark, the 2.50 m runaway leg, is 3.58 px after downsample
## in its own canonical sweep).
const SLAT_LEN: float = 0.900       ## 29.13 px of screen-x width
const SLAT_LEN_STEP: float = 0.012
## 0.290 and not 0.160: the thickness is what a height change sweeps, so it is
## the mark. See header finding 1 for why it shrinks in y at all.
## THE 10.54 px THIS ONCE CARRIED WAS MEASURED WHERE THERE IS NO MARK. It came from
## the orthographic basis below, which is a correct BASIS and a useless SCALE: the sweep
## camera is a 34-degree perspective camera standing ~9.65 m from a row 5.400 m wide laid
## along a direction 0.56 aligned with the view axis, so the four bays sit at 10.799 /
## 10.013 / 9.227 / 8.441 m — a 1.28x depth spread — and every mark in the row has its own
## pixel size. The single number quoted for all of them was the value at x = 0, which falls
## between bays B and C, where this artifact builds nothing.
##
## Projected through the real camera and put through artifact_dna_critic's own crop and
## 160x160 resize, at 0.290 the slats measured:
##
##     bay A  9.30 / 8.89 px      bay B  10.03 / 9.59 px
##     bay C 10.89 / 10.41 px     bay D  11.90 / 11.38 px      (slat 0 / slat 5)
##
## Bay A failed the 10 px floor at every slat and bay B from slat 1 down — a third of the
## row measuring as nothing, in the one artifact whose whole argument is that four bays can
## be compared. It is NOT a framing fault and dna.framing cannot fix it: the crop-then-resize
## makes mark size nearly framing-invariant but not bay-invariant, and moving the camera IN
## widens the depth ratio from 1.12x to 1.28x, making it worse.
##
## 0.330 puts bay A's thinnest slat at 10.05 px and its slat 0 at 10.45 px. It spends 0.040 m
## of the 0.110 m rail clearance (bay A screen clearance 3.25 -> ~2.1 px, still positive) and
## widens three already-fused ladders. That is the trade this file believed it had made.
const SLAT_THICK: float = 0.330     ## bay A 10.45 px at k=0, 10.05 px at k=5 — the WORST bay
const SLAT_THICK_STEP: float = 0.002
const SLAT_DEPTH: float = 0.160
const SLAT_DEPTH_STEP: float = 0.004

const BASE_Y: float = 0.200         ## the pad top: v = 0 stands on the bay pad
## v = 0..1 maps here: 103.93 px of screen-y, so the smallest resolvable step is
## dv 0.0962. Three ladders in the row fall under that and are named in the header.
const TRAVEL: float = 3.200

## THE PINNED LADDER the count channel stands on: identical world heights in
## every bay at every selection value, so only the OCCUPANCY varies. Six rungs
## 0.190 apart in v = 19.75 px, comfortably over a 10.54 px slat.
const RUNGS: Array = [0.045, 0.235, 0.425, 0.615, 0.805, 0.995]

# FURNITURE — identical in all ten variants, and that is load bearing.
#
# capture_config_sweep.gd:435 recomputes the radius from the variant's own box
# whenever no union pre-pass is available, and :442-444 places the camera from
# it. Because bay D empties at runaway and every rack changes height with the
# value, a row WITHOUT the plinth and rail would move the camera between tiles
# and the critic would diff two differently-scaled images — measuring the
# harness, not the axis. The furniture is what makes the ten crops congruent,
# and it is why the critic's subject bbox is identical in all ten tiles. Being
# byte-identical it also contributes exactly 0 px to every one of the twenty
# pair-diffs; it costs the measurement nothing and only has to be legible to a
# person, which at 4.8-5.6 px it is.
const PLINTH_SIZE: Vector3 = Vector3(5.400, 0.120, 0.240)
const PLINTH_Y: float = -0.060      ## spans -0.120 .. 0.000
const PAD_SIZE: Vector3 = Vector3(0.980, 0.200, 0.120)
## The rail marks the CEILING of the travel: it clears the top of a slat standing
## at v = 1.000 (y 3.690) by 0.110 m, so nothing the rack can build ever touches
## it. In the count channel it means less — the top rung sits at v = 0.995 just
## under it — and a reader may over-read it there.
const RAIL_SIZE: Vector3 = Vector3(5.280, 0.120, 0.120)
const RAIL_Y: float = 3.860         ## spans 3.800 .. 3.920

var _built: bool = false
var _yard: Node3D = null
var _slat_mat: StandardMaterial3D = null
var _frame_mat: StandardMaterial3D = null


func _ready() -> void:
	_check_vocabularies()
	_check_relationship()
	_build()


# ═════════════════════════════════════════════════════════════════════════════
# THE ARITHMETIC — derived once, read two ways
# ═════════════════════════════════════════════════════════════════════════════

## The order-statistic probability of slat k. Six marks, so p = (k+0.5)/6 — the
## midpoint rule, which puts no mark at either extreme of the distribution and
## spaces them evenly in probability rather than in value.
func _p_of(k: int) -> float:
	return (float(k) + 0.5) / float(N_SLATS)


## Six order statistics of a uniform on [lo, hi], normalised by `norm`.
func _uniform_ladder(lo: float, hi: float, norm: float) -> Array:
	var out: Array = []
	for k in N_SLATS:
		out.append((lo + (hi - lo) * _p_of(k)) / norm)
	return out


## Six copies of one value — a MONOMORPHIC population. Nesting means this renders
## as slat 0 alone with no z-fighting: the correct picture of twenty identical
## bodies, not an artefact.
func _flat_ladder(v: float, norm: float) -> Array:
	var out: Array = []
	for _k in N_SLATS:
		out.append(v / norm)
	return out


## Three of one morph and three of the other. Bimodal, and the two groups are
## drawn from slat sets {0,1,2} and {3,4,5}, which are differently sized, so the
## two marks are visibly two marks and not one mark twice.
func _split_ladder(a: float, b: float, norm: float) -> Array:
	var out: Array = []
	for k in N_SLATS:
		out.append((a if k < 3 else b) / norm)
	return out


## Quantile of the sum of two independent uniforms — bay B's drift crown radius,
## which is center_size + petal_length with both drawn independently. This is a
## TRAPEZOID, not a uniform, and that is the whole reason bay B's drift fan piles
## up in the middle at 8.66 px between rungs instead of spreading evenly.
## Re-derived here rather than typed as six decimals so the two draw ranges stay
## the only inputs.
func _trapezoid_quantile(p: float, w_narrow: float, w_wide: float) -> float:
	var corner: float = w_narrow / (2.0 * w_wide)
	if p <= corner:
		return sqrt(2.0 * w_narrow * w_wide * p)
	if p >= 1.0 - corner:
		return (w_narrow + w_wide) - sqrt(2.0 * w_narrow * w_wide * (1.0 - p))
	return p * w_wide + w_narrow * 0.5


func _flower_drift_ladder() -> Array:
	var w_cs: float = B_CS_HI - B_CS_LO
	var w_pl: float = B_PL_HI - B_PL_LO
	var floor_sum: float = B_CS_LO + B_PL_LO
	var out: Array = []
	for k in N_SLATS:
		var s: float = _trapezoid_quantile(_p_of(k), minf(w_cs, w_pl), maxf(w_cs, w_pl))
		out.append((floor_sum + s) / B_NORM)
	return out


## Every bay's six v-values at one selection value, or an EMPTY array for the one
## declared refusal. v is a fraction of that substrate's own attainable currency;
## it is never a metre count, because the four currencies do not convert.
## `if` on the bay and `match` on the word, deliberately: a bare identifier in a
## match PATTERN is a value pattern only when it resolves to a constant, and the
## same text is a capture binding under other circumstances. An axis is not worth
## risking on that distinction, and integer comparison cannot be misread.
func _spread_ladder(bay: int, sel: String) -> Array:
	if bay == BAY_A:
		match sel:
			"drift":   return _flat_ladder(A_WILD, A_NORM)
			"uniform": return _flat_ladder(A_CONVERGED, A_NORM)
			"culled":  return _flat_ladder(A_CONVERGED, A_NORM)   # the SAME body
			"runaway": return _flat_ladder(A_NORM, A_NORM)
			"split":   return _split_ladder(A_SPLIT_SHORT, A_SPLIT_LONG, A_NORM)
	elif bay == BAY_B:
		match sel:
			"drift":   return _flower_drift_ladder()
			"uniform": return _flat_ladder(B_OPTIMUM, B_NORM)
			"culled":  return _flat_ladder(B_OPTIMUM, B_NORM)     # the SAME genome
			"runaway": return _flat_ladder(B_RUNAWAY, B_NORM)
			"split":   return _split_ladder(B_SPLIT_WEST, B_SPLIT_EAST, B_NORM)
	elif bay == BAY_C:
		match sel:
			"drift":   return _uniform_ladder(C_DRIFT_LO, C_DRIFT_HI, C_NORM)
			"uniform": return _flat_ladder(C_UNIFORM, C_NORM)
			"culled":  return _flat_ladder(C_CULLED, C_NORM)      # the SAME radius
			"runaway": return _flat_ladder(C_NORM, C_NORM)
			"split":   return _split_ladder(C_SPLIT_SMALL, C_SPLIT_LARGE, C_NORM)
	elif bay == BAY_D:
		# Two symmetric knots: every member sits at SPLIT_SEPARATION from the
		# centroid, give or take the knot's own residual width. Which is why this
		# is the one bay where `split` renders ONE bar and not two.
		match sel:
			"drift":   return _uniform_ladder(0.0, D_DRIFT_MAX, D_NORM)
			"uniform": return _uniform_ladder(0.0, D_UNIFORM_MAX, D_NORM)
			"culled":  return _uniform_ladder(0.0, D_CULLED_MAX, D_NORM)
			"runaway": return []                                  # THE REFUSAL
			"split":   return _uniform_ladder(D_SPLIT_HALF - D_CULLED_MAX, D_SPLIT_HALF + D_CULLED_MAX, D_NORM)
	return []


## How many of the six rungs this bay's population fills, filling from the bottom.
## ceil so that any surviving population shows at least one rung — a headcount of
## 6 out of 120 is 0.3 rungs and must not round to nothing.
func _occupied_rungs(bay: int, sel: String) -> int:
	var counts: Array = HEADCOUNT[bay]
	var idx: int = _index_of(sel)
	if idx < 0:
		return 0
	var n: int = int(counts[idx])
	if n < 0:
		return 0                        ## the refusal, not a zero count
	var nmax: int = 0
	for c in counts:
		nmax = maxi(nmax, int(c))
	if nmax <= 0:
		return 0
	var rungs: float = ceil(float(N_SLATS) * float(n) / float(nmax))
	return clampi(int(rungs), 0, N_SLATS)


func _index_of(sel: String) -> int:
	for i in SELECTIONS.size():
		if SELECTIONS[i] == sel:
			return i
	return -1


# ═════════════════════════════════════════════════════════════════════════════
# THE BUILD — synchronous, from the exports alone
# ═════════════════════════════════════════════════════════════════════════════

func _build() -> void:
	if _yard != null:
		remove_child(_yard)           ## not queue_free alone: deferred frees would
		_yard.queue_free()            ## leave two yards standing in one frame
		_yard = null
	_yard = Node3D.new()
	_yard.name = "Yard"
	add_child(_yard)

	_slat_mat = StandardMaterial3D.new()
	_slat_mat.albedo_color = Color(0.84, 0.81, 0.76)
	_slat_mat.roughness = 0.50
	_slat_mat.metallic = 0.0
	## ONE material for every slat in every bay. A per-bay colour would let a
	## reader think the bays differ in kind; they are the same instrument at the
	## same pixel scale, so any inequality in measured response is about the
	## vocabulary and not about the drawing.
	_frame_mat = StandardMaterial3D.new()
	_frame_mat.albedo_color = Color(0.29, 0.30, 0.33)
	_frame_mat.roughness = 0.70
	_frame_mat.metallic = 0.0

	_box(PLINTH_SIZE, Vector3(0.0, PLINTH_Y, 0.0), _frame_mat, "Plinth")
	_box(RAIL_SIZE, Vector3(0.0, RAIL_Y, 0.0), _frame_mat, "DatumRail")
	for b in N_BAYS:
		_box(PAD_SIZE, Vector3(float(BAY_X[b]), PAD_SIZE.y * 0.5, 0.0),
			_frame_mat, "Pad%d" % b)
		_build_bay(b)
	_built = true


func _build_bay(bay: int) -> void:
	var vs: Array = []
	if channel == "spread":
		vs = _spread_ladder(bay, selection)
	else:
		var n: int = _occupied_rungs(bay, selection)
		for k in n:
			vs.append(float(RUNGS[k]))
	## An empty bay keeps its pad, the plinth beneath it and the rail above it, so
	## it reads as an UNPOPULATED BAY rather than a short row. Anyone reading the
	## contact sheet without the note will file it as NO RENDER; it is the fourth
	## vocabulary saying it does not have the word.
	for k in vs.size():
		var v: float = float(vs[k])
		var fk: float = float(k)
		## Concentric nesting in all three axes. Slat k+1 is strictly inside slat
		## k, so at equal value the inner ones are hidden and no two ever share a
		## face plane. LAW 8: the only enclosing bodies in this scene are slats,
		## and they enclose only slats carrying the identical number.
		var slat_size: Vector3 = Vector3(
			SLAT_LEN - SLAT_LEN_STEP * fk,
			SLAT_THICK - SLAT_THICK_STEP * fk,
			SLAT_DEPTH - SLAT_DEPTH_STEP * fk)
		## Centred on the same mid-height at equal v, so a thinner slat sits
		## INSIDE a thicker one rather than resting on it.
		var mid: float = BASE_Y + TRAVEL * v + SLAT_THICK * 0.5
		_box(slat_size, Vector3(float(BAY_X[bay]), mid, 0.0), _slat_mat,
			"Bay%dSlat%d" % [bay, k])


func _box(box_size: Vector3, centre: Vector3, mat: StandardMaterial3D, nm: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	# On the mesh, not material_override: override would also have worked here,
	# but it is the thing that breaks a pickup highlight swap elsewhere in the
	# corpus, and there is no reason to teach the pattern.
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = centre
	mi.name = nm
	_yard.add_child(mi)


# ═════════════════════════════════════════════════════════════════════════════
# THE SELF-CHECKS — a declaration that cannot drift from the code
# ═════════════════════════════════════════════════════════════════════════════

## LAW 1, both directions, at run time. An @export_enum literal cannot be derived
## from a const at parse time, so reading hint_string back out of
## get_property_list() is the only defence. science_screen shipped a hand-typed
## block declaring none|bezel|hooded|cabinet against a code enum of
## stand|wall|console|rig: the sweep set an invalid value, the artifact fell back
## to its default, sixteen identical frames were published and the critic reported
## the axis INERT at 0.69%. Every stage green, and the verdict was a fact about a
## typo.
func _check_vocabularies() -> void:
	_check_hint("selection", SELECTIONS)
	_check_hint("channel", CHANNELS)
	if not SELECTIONS.has("drift"):
		push_error("PressureYard: the default 'drift' is not in the declared list")
	if not CHANNELS.has("spread"):
		push_error("PressureYard: the default 'spread' is not in the declared list")
	if HEADCOUNT.size() != N_BAYS:
		push_error("PressureYard: HEADCOUNT has %d rows, there are %d bays" % [
			HEADCOUNT.size(), N_BAYS])
	for b in N_BAYS:
		if (HEADCOUNT[b] as Array).size() != SELECTIONS.size():
			push_error("PressureYard: bay %d declares %d headcounts for %d values" % [
				b, (HEADCOUNT[b] as Array).size(), SELECTIONS.size()])
	if RUNGS.size() != N_SLATS:
		push_error("PressureYard: %d rungs for %d slats" % [RUNGS.size(), N_SLATS])


func _check_hint(prop: String, allow: PackedStringArray) -> void:
	var hint: String = ""
	for p in get_property_list():
		if str(p.get("name", "")) == prop:
			hint = str(p.get("hint_string", ""))
	var declared: PackedStringArray = hint.split(",", false)
	if declared.size() != allow.size():
		push_error("PressureYard: export '%s' declares %d values, the allow-list has %d" % [
			prop, declared.size(), allow.size()])
	for i in declared.size():
		if not allow.has(declared[i]):
			push_error("PressureYard: export '%s' declares '%s', the allow-list does not" % [
				prop, declared[i]])
	for j in allow.size():
		if not declared.has(allow[j]):
			push_error("PressureYard: allow-list has '%s', the '%s' export hint does not" % [
				allow[j], prop])
		# LAW 13, and it is the point of reusing the word: order as well as
		# membership. A list that agrees as a set but not as a sequence would
		# silently reorder the sweep's tiles against the family's.
		if j < declared.size() and declared[j] != allow[j]:
			push_error("PressureYard: '%s' value %d is '%s' in the export and '%s' in the allow-list" % [
				prop, j, declared[j], allow[j]])


## LAW 20 — the relationship, asserted before the shutter rather than discovered
## after it. Each of these is the geometric form of a claim in the header, and
## each is falsifiable to the bit.
##
##  1. THE PINNING, both directions. In `spread` every populated bay carries
##     exactly six slats at every value, so headcount carries zero signal. In
##     `count` every occupied slat stands on a RUNG, so height carries zero.
##     If either leaks the two channels are entangled and neither number means
##     what the header says it does.
##  2. THE NULL TEST. No substrate changes headcount between drift, uniform and
##     split, so those three count-channel tiles must be byte identical in all
##     four bays. Any nonzero reading there is proof the rig is not
##     deterministic, and it invalidates every other number in the pass.
##  3. THE EQUALITY. Three independently written codebases all say culling does
##     not touch the survivor, so bays A, B and C must be identical between
##     uniform and culled in the spread channel — and bay D must not.
##  4. THE COUNT INTEGER. An 80.00% cull and an 81.25% cull must land on the
##     same mark: ceil(6*4/20) = ceil(1.2) = 2 and ceil(6*3/16) = ceil(1.125) = 2.
func _check_relationship() -> void:
	for b in N_BAYS:
		for i in SELECTIONS.size():
			var sel: String = SELECTIONS[i]
			var ladder: Array = _spread_ladder(b, sel)
			var expect: int = 0 if (b == BAY_D and sel == "runaway") else N_SLATS
			if ladder.size() != expect:
				push_error("PressureYard: spread bay %d '%s' has %d slats, expected %d" % [
					b, sel, ladder.size(), expect])
			for v in ladder:
				if float(v) < 0.0 or float(v) > 1.0:
					push_error("PressureYard: spread bay %d '%s' leaves 0..1 at v = %f" % [
						b, sel, float(v)])
	var drift_l: Array = []
	var uniform_l: Array = []
	var split_l: Array = []
	for b in N_BAYS:
		drift_l.append(_occupied_rungs(b, "drift"))
		uniform_l.append(_occupied_rungs(b, "uniform"))
		split_l.append(_occupied_rungs(b, "split"))
	for b in N_BAYS:
		if int(drift_l[b]) != int(uniform_l[b]) or int(drift_l[b]) != int(split_l[b]):
			push_error("PressureYard: the count null test fails at bay %d - %d/%d/%d rungs" % [
				b, int(drift_l[b]), int(uniform_l[b]), int(split_l[b])])
	if _occupied_rungs(BAY_A, "culled") != _occupied_rungs(BAY_B, "culled"):
		push_error("PressureYard: bays A and B disagree on the culled integer - %d vs %d" % [
			_occupied_rungs(BAY_A, "culled"), _occupied_rungs(BAY_B, "culled")])
	if _occupied_rungs(BAY_D, "runaway") != 0:
		push_error("PressureYard: bay D must stand empty at runaway")
	var agreeing: Array = [BAY_A, BAY_B, BAY_C]
	for a in agreeing.size():
		var bi: int = int(agreeing[a])
		var u: Array = _spread_ladder(bi, "uniform")
		var c: Array = _spread_ladder(bi, "culled")
		for k in N_SLATS:
			if absf(float(u[k]) - float(c[k])) > 1e-9:
				push_error("PressureYard: bay %d moves between uniform and culled - the substrate says it does not" % bi)
	var du: Array = _spread_ladder(BAY_D, "uniform")
	var dc: Array = _spread_ladder(BAY_D, "culled")
	if absf(float(du[0]) - float(dc[0])) < 1e-9:
		push_error("PressureYard: bay D does NOT move between uniform and culled - the one bay that must")
	## The tallest thing the rack can build must clear the rail, or the datum
	## stops being a datum. 0.200 + 3.200 + 0.290 = 3.690 against a rail bottom
	## of 3.800.
	var tallest: float = BASE_Y + TRAVEL * 1.0 + SLAT_THICK
	if tallest >= RAIL_Y - RAIL_SIZE.y * 0.5:
		push_error("PressureYard: a v=1.000 slat tops out at %f and the rail starts at %f" % [
			tallest, RAIL_Y - RAIL_SIZE.y * 0.5])


# ═════════════════════════════════════════════════════════════════════════════

## Rebuild ONLY on a value this artifact owns, and only after _ready has built
## once. force_pad rebuilt itself on every call, including ones naming nothing
## of its own.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("selection"):
		var s: String = str(config_data["selection"])
		if SELECTIONS.has(s) and s != selection:
			selection = s
			dirty = true
	if config_data.has("channel"):
		var c: String = str(config_data["channel"])
		if CHANNELS.has(c) and c != channel:
			channel = c
			dirty = true
	if dirty and _built:
		_build()
