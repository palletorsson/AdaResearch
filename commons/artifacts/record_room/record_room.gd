extends Node3D
class_name RecordRoom

## Record Room — a SYNTHESIS artifact. One measured signal, kept four ways, on one face.
##
## @identity
## essence: Four lanes stacked on a single chart recorder's face, sharing ONE time
##   axis, each holding the SAME single pass of a measured signal under a different
##   regime of keeping — instant, window, archive, margin. The word five instruments
##   each stand inside one value of, stacked so the nesting can be SEEN.
## desire: To be read down the face and then read across it. Every lane still has a
##   live pen at the right-hand edge, so every rung still tells you the present. What
##   changes down the column is which OTHER question the instrument can answer.
## critical_parameter: `behaviour` — what the measured thing is doing. The four
##   regimes never move and never change their order; only the signal underneath.
## triggers: none. Nothing animates, nothing is picked up, nothing is random. The
##   face is the standing record, which is the only part of this family a still
##   photograph was ever able to hold.
## emerges: measured, not asserted — of everything that changes when the signal
##   changes, the `instant` lane carries 0.9%, `window` 13.4%, `archive` 42.3% and
##   `margin` 43.4%. The fourth rung adds 1.1 points over the third on the same 47
##   segments. It is not keeping more. It is a second author.
## needs: one signal computed once [has, _run]; four lanes differing in nothing but
##   the regime [has]; a shared time axis so the truncation is visible rather than
##   claimed [has]; marks gauged to 244.616 px/m [has]; no random number anywhere
##   [has, a seeded LCG reproducible in Python]
## relationships: Synthesised from the six artifacts that declare `record` — five
##   instruments plus one outlier. The instrument case of the question
##   [[retention_corridor]] asks of a MARK and [[removal_room]] asks of a CUT.
## truth: An instrument that keeps nothing cannot be contradicted, and it cannot be
##   asked anything either. What a machine retains is not a property of its memory.
##   It is the list of questions you are allowed to put to it.

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS DNA — `behaviour`
# ═══════════════════════════════════════════════════════════════════════════
#
# BORN PROMOTED. This artifact did not exist before the batch that promoted its
# sources (4e3bb2a63, 2026-08-01, "the wavefunctions tier"). It is the cross-member
# comparison that batch left implicit, built as a body.
#
# WHAT IT IS. A chart recorder's face 2.10 m wide with four lanes cut into it, one
# above the other, ALL FED FROM ONE TIME AXIS — 48 ticks running left to right, the
# pen at the right-hand end, oldest at the left. Every lane carries the same live pen
# carriage at the same x, so the present reading never leaves. What differs is what
# is on the paper behind it, in the order all five instrument members declare:
#
#   instant   no paper at all. The well, the scale ladder and the pen. Whatever the
#             signal has been doing, this lane can only say where it is NOW
#   window    paper, inked over the newest 11 of 48 ticks and blank before that
#   archive   paper inked end to end, plus the run-out folded at the old end
#   margin    the archive, READ — printed rules, a limit rail at 0.739 of full scale,
#             a tick scale along the foot, and a hand's ring round the largest
#             excursion with its bracket
#
# THE FOUR LANES SHARE A TIME AXIS, and that is the synthesis's own contribution.
# Every member draws its record on ONE carrier, so its `window` and its `archive` can
# only ever be met one at a time, a map apart. Here `window`'s ink sits directly under
# the right-hand fifth of `archive`'s ink, at the same x, at the same scale — so the
# claim that a window is a TRUNCATION of an archive rather than a different picture is
# something a visitor reads off the alignment instead of taking on trust.
#
# ── LAW 2 — NEST, SIDE BY SIDE, OR MIXED, answered from the members' CODE ──
#
# By EXTENT the four values NEST, strictly, and by construction. All five instrument
# members run the identical shape (seismograph._build_record, multimeter._build_record,
# atmosphericmonitoring._build_record, and the same in the other two):
#
#     full = record != "window"
#     draw the carrier
#     if record == "margin": _rec_furniture()
#     count = ALL if full else WINDOW
#     draw `count` strokes          # window's strokes are a PREFIX of archive's
#     if full: _rec_fanfold()
#     if record == "margin": _rec_hand(peak)
#
# so drawn(instant) = the empty set ⊂ drawn(window) ⊂ drawn(archive) ⊂ drawn(margin).
# seismograph's own header says it in words: "Monotone, like prng_crank_machine's
# disclosure ladder: each rung carries everything the rung below it carries plus one
# more kind of account."
#
# By CLAIM it is MIXED, and the mixing is at ONE joint. Rungs 1-3 differ in how much
# of the PAST is kept — 0, then 11 of 48, then 48 of 48. Rung 4 keeps EXACTLY what
# rung 3 keeps and adds a second author: rules and a rail that were PRINTED before any
# measurement, and a ring drawn by somebody who came back. Three rungs nest on one
# dimension; the fourth adds a parallel apparatus on top of the last.
#
# AND THE ROOM MEASURES ITS OWN ANSWER. Rasterised at the sweep's own geometry and
# attributed per lane by an id-buffer, the share of everything that changes when the
# signal changes is instant 0.9%, window 13.4%, archive 42.3%, margin 43.4%. Archive
# and margin are within 1.1 points of each other and draw the same 47 segments. So the
# fourth rung's whole apparatus of reading is worth about a point of measurement, and
# the ladder is monotone in ink and NOT monotone in what the ink is about.
#
# ── THE BRIEF'S READING OF `margin` IS FALSIFIED BY THE FAMILY'S CODE ──
#
# This artifact was commissioned with the argument that `margin` "keeps not the
# readings but the BOUNDS — the highest and lowest ever seen — which is the least data
# and answers HAS THIS EVER BEEN WORSE." No member implements that. In all five,
# `margin` draws the FULL archive and adds to it; there is no branch anywhere in the
# family in which margin keeps less than archive. The bounds idea IS present — every
# member's `_rec_hand` rings the argmax of |sample| and every member's `_rec_furniture`
# prints a limit rail — but as an ANNOTATION ON a complete archive, never instead of
# one. This room builds what the code does and reports the disagreement rather than
# quietly shipping the prose version, because a synthesis that exhibits a family word
# is only worth anything if it exhibits the word the family actually means.
#
# ── `record` IS REFUSED AS THIS ARTIFACT'S AXIS, on the record ──
#
# Each of the five members uses the word to stand in ONE regime and forgo the other
# three; on this face all four stand at once and that simultaneity is the whole object.
# An axis whose every value demolishes three quarters of the exhibit is not a variation
# of it. That is retention_corridor's ruling on `retention` and removal_room's on
# `removal`, and it lands here for the same reason. The word is EXHIBITED — it names
# the artifact and it names the four lanes, engraved beside each one — and what turns
# instead is the signal underneath.
#
# THERE IS NO ORIGIN MEMBER TO DEFER TO, which is unusual in this corpus and was
# checked rather than assumed: `git log -S` on the export line returns the SAME commit
# for all five (4e3bb2a63, 2026-08-01), and seismograph.gd was created by it. `retention`
# has mystic_writing_pad and `removal` has cantor_set; `record` has five simultaneous
# births and no parent. So there is no member const to preload, and the vocabulary check
# below reads the @export_enum hint out of ALL FIVE members' scripts and compares each
# against this room's list in BOTH directions. That is stronger than deferring to one
# owner: it also catches two members drifting apart from each other.
#
# ── `behaviour` IS THIS ARTIFACT'S OWN WORD, and two candidates were refused ──
#
# `signal` was the first choice and is IMPOSSIBLE: `signal` is a GDScript keyword and
# cannot be a variable name, so the export would not parse.
#
# `waveform` is UNAVAILABLE. Three artifacts already declare it — additive_wave_demo,
# fourier_transform and timbre_sculptor — all meaning an oscillator's shape
# (sine | square | sawtooth | triangle). Taking it here for "what an instrument is
# measuring" would add a third meaning to a live word. Taking a word without its
# answers is the dishonest half of a shared vocabulary.
#
# `behaviour` is free (checked against all 465 declared axis words) and it is the
# standard instrumentation taxonomy — steady state, oscillation, drift, transient —
# which is also, exactly, the family's own census.
#
# ── THE VALUE LIST IS THE FAMILY'S OWN CENSUS OF SIGNALS, derived not invented ──
#
# All six members were read and every signal their code evaluates was counted. Ten
# distinct channels:
#
#   cycle   5 — multimeter mode 0 (AC, ac_amplitude*sin(t*f*TAU)); atmosphericmonitoring
#               pressure 0.05 Hz, temperature 0.02 Hz, humidity 0.03 Hz;
#               holographicdisplay's turn. The family's commonest signal by far
#   steady  3 — multimeter mode 1 (DC: dc_offset + noise*0.5) and mode 3 (FREQUENCY:
#               ac_frequency + noise*0.01); dual_display_test's silent-room spectrum
#   event   1 — seismograph: noise in [-0.1, 0.1] every tick plus a decaying baseline
#               from discrete events
#   drift   1 — multimeter mode 2 (RESISTANCE: 1000 + 50*sin(t*0.3) + noise*10)
#
# 5 + 3 + 1 + 1 = 10. The list partitions the family's signals exactly; nothing is left
# out and nothing is invented.
#
# ── ONE CEILING FOR THE WHOLE AXIS (LAW 5), AND WHAT IT COST ──
#
# All four behaviours are drawn against ONE full scale, ±FS metres for ±1.0 deflection,
# fixed across every value. atmosphericmonitoring normalises each channel to its own
# lane instead, and says why: "a shared axis would flatten a 0.5 degree swing against a
# 5 hPa one and draw three straight lines." That is right for three simultaneous
# channels on one card and WRONG here, because a per-value ceiling would make `steady`
# undefined (its range is exactly zero) and would draw `drift` and `cycle` at the same
# height. So the ceiling is fixed and `steady` is allowed to be a flat line, which is
# what a steady signal is.
#
# ── THE SIGNALS, AND THE ONE PLACE THE ROOM REFUSED TO COPY A NUMBER ──
#
# event   seismograph's own statistics. Noise band ±0.10, exactly its randf_range;
#         decay 15 ticks, which is its own 30-of-96 proportion on a 48-tick chart;
#         magnitudes 0.34 and 0.78, the smallest and largest of its four; onsets at
#         ticks 12 and 36, which is its own rate of one event per 24 ticks laid on this
#         room's grid. THE DECAY DIRECTION IS CORRECTED — see below.
# cycle   3 periods across the chart. The family's four sine channels draw 2.4, 2.88,
#         3.6 and 6.0 periods across their own charts; the median is 3.24 and 3 is the
#         nearest integer. Amplitude 0.5, which is multimeter's 5.0 V on its own 10 V
#         full-scale deflection.
# drift   a monotone arc over a phase window of 0.864 rad — multimeter mode 2's own
#         0.3 rad/s across its own 2.88 s tape — centred on zero so the arc runs from
#         sin(-0.432) to sin(+0.432), i.e. -0.4187 to +0.4187.
# steady  flat. Not approximately flat: multimeter mode 1 draws dc_offset + noise*0.5
#         with noise_level 0.1, so r spans ±0.025 V and the deflection clamp(r/10) spans
#         ±0.0025 of full scale = 0.4 micrometres here, which is 0.00009 px. The
#         family's steady signal is a straight line and the room draws a straight line.
#
# THE ONE AMPLITUDE THE ROOM WOULD NOT COPY IS DRIFT'S, and the arithmetic is why.
# multimeter mode 2 reads 1000 + 50*sin(0.3 t) ohms and maps it with
# clamp(log(r)/10, 0, 1)*2 - 1. Because d(log r) = dr/r, a ±5% swing in resistance
# becomes ±0.05/10*2 = ±0.01 of full-scale deflection — ONE PERCENT. The family's own
# drift member, replayed onto its own tape, draws a straight line 0.38 of the way up,
# and its noise term (randf*10 on 1000) contributes another ±0.002. So `drift` at
# multimeter's numbers would have been a second `steady` at a different height: two of
# four values photographing as one line, and the log mapping — not the design — would
# have been the finding. The SHAPE is taken exactly (a monotone fraction of a very long
# period, 0.864 rad of it) and the amplitude is gauged to this room's full scale. That
# is stated here rather than buried because it is the only number in the file that is
# not the family's.
#
# ── A FINDING ABOUT seismograph, reported rather than inherited ──
#
# seismograph._record_samples walks index 0 = NEWEST (its own comment: "the pen sits at
# the LEFT end ... index 0 is the freshest sample and the ink grows away from the pen")
# and applies each event's decay with `if i >= at and i - at <= REC_DECAY_TICKS`, i.e.
# over indices at .. at+30 — which in that indexing is the thirty ticks BEFORE the
# onset. Its detector does the opposite: `detect_seismic_activity` sets a baseline and a
# tween walks it to zero over the following 3.0 s. So on that instrument's paper every
# event's sharp attack faces the pen and its slow decay runs backwards into the past.
# It is one comparison operator. This room draws the decay forward in time, toward the
# newer end, and says so instead of copying it.
#
# ── AND A COINCIDENCE WORTH FLAGGING RATHER THAN HIDING ──
#
# The window is the newest 11 of 48 ticks, so it opens at tick 37. The newer event's
# onset lands at tick 36 — one tick outside it. Those two numbers come from independent
# family constants: 11/48 is the window fraction multimeter and seismograph share to
# five decimal places (11/48 = 22/96 = 0.229167), and 36 is 3/4 of 48 from seismograph's
# rate of one event per 24 ticks. Nothing was placed to arrange it. The consequence is
# the room's sharpest picture — at the default the `window` lane shows a large monotone
# DECLINE, from 0.728 down to 0.208, and no cause for it, while the `archive` lane above
# shows two onsets — and it is flagged because seismograph's own header admits to
# arranging the opposite on purpose: "the event TIMES are fixed ... so that the `window`
# rung (the first 22 samples) is guaranteed to contain one." A family that has already
# once put its thumb on this exact scale is a family whose next coincidence should be
# declared.
#
# ── WHY THAT DECLARED ORDER — event, cycle, drift, steady ──
#
# build_dna_gallery trims value lists from the TAIL, so the default goes first and one
# member of the predicted closest pair goes last. The closest pair is event/steady, so
# `steady` is last: a run capped at three keeps event, cycle, drift and never grades the
# pair most at risk of reading alike. `cycle` is second because it is the family's
# commonest signal — five of ten channels — so a capped sweep keeps the two values most
# of the corpus actually measures.
#
# ── LAW 7 — THE Z-STACK, written out ──
#
# Everything is a shallow relief facing +z and nothing opaque stands between the camera
# and a mark. Screen-x = cos(0.62)*x - sin(0.62)*z = 0.813878*x - 0.581035*z.
#
#   case body      z -0.140 .. +0.020
#   lane well      z +0.020 .. +0.026   (all four lanes)
#   run-out fold   z +0.020 .. +0.036   (archive, margin)
#   paper          z +0.026 .. +0.030
#   printed rules  z +0.030 .. +0.0325  (margin)
#   scale ladder   z +0.030 .. +0.0325  (all four lanes)
#   the trace      z +0.0325 .. +0.0365
#   the hand       z +0.0365 .. +0.0405 (margin)
#   pen carriage   z +0.0365 .. +0.0480 (all four lanes)
#   plinth         z -0.140 .. +0.140   (below the marks, y 0.00 .. 0.18)
#
# The three horizontal collisions were computed, not eyeballed, and two of them were
# real and were moved:
#
#   run-out right edge    -0.718067   oldest ink left    -0.701610   clear 4.03 px
#   newest ink right       0.547576   pen carriage left   0.582519   clear 8.55 px
#   nameplate right edge  -0.796428   run-out left edge  -0.779452   clear 4.15 px
#
# The nameplate row is the ONLY clearance here computed from a text metric rather than
# from a box this file controls, so it is quoted at its pessimistic end: 4.15 px assumes
# a generous 0.090 m line box for a 36 pt label at pixel_size 0.0018, where the glyph
# half-height alone (0.0324) would give 6.66 px. If a plate ever crowds a run-out, move
# NAME_X — not FOLD_X, whose 4.03 px against the oldest ink is the tighter constraint.
#
# The run-out fold stands 16 mm proud of the paper, so at this yaw it eats
# sin(0.62)*0.016 = 9.3 mm of screen daylight to its right. At the first layout it sat
# at x = -0.855 and its silhouette reached -0.688, which is 3.42 px INSIDE the oldest
# ink at -0.702 — the family's "the run-out is kept" would have been drawn standing in
# front of the two oldest ticks it is evidence for. It is at -0.900 now.
#
# THE HAND'S RING IS CLAMPED TO THE PAPER, and that is a fact about a ring and not a
# fudge: at `drift` and at `steady` the largest excursion is the NEWEST sample, so an
# unclamped ring would reach screen-x 0.592457 against the pen carriage's 0.582519 and
# hang 2.43 px over it. Clamped, it clears by 12.30 px. A reader's ring is a mark made
# ON the chart and cannot be drawn off its edge.
#
# ── LAW 4 — EVERY MARK GAUGED, at 244.616 px/m (see dna.framing_why) ──
#
#   pen           0.0280 m =  6.85 px      limit rail  0.0180 m = 4.40 px
#   sample step   0.0319 m =  7.81 px      printed rule 0.0140 m = 3.42 px
#   full scale    0.1500 m = 36.69 px      foot tick   0.0160 m = 3.91 px
#   lane pitch    0.4000 m = 97.85 px      ring bead   0.0240 m = 5.87 px
#                                          fold leaf   0.0160 m = 3.91 px
#
# Nothing is inside the 1-3 px band law 4 exists because of. The first draft had the
# rail at 1.96 px and the printed rules at 0.76 px — furniture that would have cost
# geometry and returned nothing to either the bench or a visitor.
#
# THE PEN IS DELIBERATELY FAT. 6.85 px on a 36.69 px full scale is 18.7% of the scale,
# and no real chart pen is. At the family's own line weights (seismograph draws 0.005 m
# bars) the trace here would be 1.22 px and the whole axis would sink into the noise
# floor the bite critic measures against. The consequence is stated rather than hidden:
# `steady`'s zero-amplitude noise and `event`'s ±0.1 quiet band are both INSIDE one pen
# width, so those two lanes overlap wherever nothing is happening. That is why they are
# the predicted closest pair, and it is a true fact about a chart at this line weight.
#
# ── DETERMINISM ──
#
# There is no randf, no randi, no randomize, no _process, no _physics_process, no timer
# and no node lookup outside this artifact's own children. The one stochastic term —
# `event`'s noise — comes from a seeded linear congruential generator written out in
# this file rather than from RandomNumberGenerator, which is equally deterministic
# inside Godot but cannot be reproduced in Python. Because this one can, the closest-pair
# prediction in the registry is EXACT for the tile that will be captured rather than a
# statement about a distribution.
#
# Usage in map_data.json:
#   "record_room"                        — the event
#   "record_room#behaviour:cycle"
#   "record_room#behaviour:drift"
#   "record_room#behaviour:steady"

# ═══════════════════════════════════════════════════════════════════════════
# THE FAMILY'S WORD, AND THE CHECK THAT IT IS STILL THE FAMILY'S WORD
# ═══════════════════════════════════════════════════════════════════════════

## The five instruments that declare `record`. Preloaded so a moved or renamed file
## fails at PARSE time rather than turning the check below into a silent no-op.
## harmonic_motion_demo also declares `record` and is deliberately NOT here — it
## carries both|trace|prediction|bare, which is a different question (what a physics
## demo overlays on a motion), and it is named in dna.kin as an outlier instead.
const M_SEISMOGRAPH := preload("res://commons/lab/seismograph/seismograph.gd")
const M_MULTIMETER := preload("res://commons/lab/multimeter/multimeter.gd")
const M_ATMOSPHERIC := preload("res://commons/lab/atmosphericmonitoring/atmosphericmonitoring.gd")
const M_HOLOGRAPHIC := preload("res://commons/lab/holographicdisplay/holographicdisplay.gd")
const M_DUAL := preload("res://algorithms/wavefunctions/spectralanalysis/dual_display_test.gd")

## The four regimes, top to bottom, in the order all five members declare them.
## Exhibited, never turned — see the header. Checked against every member at _ready.
const RECORDS: PackedStringArray = ["instant", "window", "archive", "margin"]

## THE AXIS — what the instrument is measuring. Default is the strongest single
## reading, not the commonest: see dna.default.
@export_enum("event", "cycle", "drift", "steady") var behaviour: String = "event"

## Allow-list, checked against the @export_enum hint above in BOTH directions at
## _ready. An @export_enum literal cannot be derived from a const, so comparing them at
## run time and shouting is the only defence against the two drifting apart.
const BEHAVIOURS: PackedStringArray = ["event", "cycle", "drift", "steady"]

# ── the case ─────────────────────────────────────────────────────────────
const CASE_W: float = 2.10
const CASE_Y0: float = 0.18            ## plinth top / case foot
const CASE_Y1: float = 1.86            ## case head
const HEAD_H: float = 0.10             ## the header rail the title is engraved on
const CORN_H: float = 0.04
const CORN_OVER: float = 0.03
const CASE_ZB: float = -0.14
const CASE_ZF: float = 0.02
const PLINTH_ZF: float = 0.14

const N_LANE: int = 4
const LANE_PITCH: float = 0.40
const LANE_H: float = 0.36
## Full scale. ±1.0 deflection maps to ±FS metres, in every lane, at every value of
## the axis. LAW 5: one ceiling, fixed across the whole axis.
const FS: float = 0.15

const NAME_X: float = -1.00            ## the rotated channel nameplates
const FOLD_X: float = -0.90            ## the run-out, clear of the oldest ink by 4.03 px
const PAPER_X0: float = -0.82          ## oldest
const PAPER_X1: float = 0.68           ## newest, under the pen
const PEN_X: float = 0.78
const SCALE_X: float = 0.95            ## the instrument's OWN scale, not the chart's

## 48 ticks, and the window is 11 of them. 11/48 = 0.229167 is multimeter's window
## fraction (REC_WINDOW_DOTS 11 of REC_DOTS 48) and seismograph's (22 of 96) to five
## decimal places — the family's two chart recorders agree exactly. The other two are
## atmosphericmonitoring at 19/78 = 0.243590 and holographicdisplay at 3/12 = 0.25, so
## 0.229167 is the median as well as the mode.
const N_TICK: int = 48
const N_WINDOW: int = 11

# ── the z-stack, written out in the header ───────────────────────────────
const Z_WELL: float = 0.023
const Z_WELL_D: float = 0.006
const Z_PAPER: float = 0.028
const Z_PAPER_D: float = 0.004
const Z_FURN: float = 0.03125
const Z_FURN_D: float = 0.0025
const Z_INK: float = 0.0345
const Z_INK_D: float = 0.004
const Z_HAND: float = 0.0385
const Z_HAND_D: float = 0.004
const Z_PEN: float = 0.04225
const Z_PEN_D: float = 0.0115
const Z_FOLD: float = 0.028
const Z_FOLD_D: float = 0.016

# ── the marks, every one gauged in the header ────────────────────────────
const TRACE_T: float = 0.028
const RULE_T: float = 0.014
const BAND_T: float = 0.018
const TICK_W: float = 0.016
const TICK_H: float = 0.030
const RING_R: float = 0.062
const RING_BEAD: float = 0.024
const RING_BEADS: int = 20

## Where the limit rail is printed, as a fraction of full scale. NOT a taste number:
## seismograph prints its band at 0.085 of a 0.115 half-height (0.739130) and multimeter
## at 0.0155 of a 0.021 swing (0.738095). The family's two chart recorders agree to
## three decimals without ever having been compared. It decides which behaviours can be
## seen to have exceeded a limit: at 0.739 only `event` (peak 0.8265) crosses it, and
## `cycle` (0.4997), `drift` (0.4187) and `steady` (0.0) do not.
const BAND_V: float = 0.739

# ── the signals ──────────────────────────────────────────────────────────
const EV_DECAY: int = 15               ## seismograph's 30 of 96 ticks, on 48
const EV_ONSET: PackedInt32Array = [12, 36]
const EV_MAG: PackedFloat32Array = [0.34, 0.78]
const EV_NOISE: float = 0.10           ## seismograph's randf_range(-0.1, 0.1), exactly
const CYC_PERIODS: float = 3.0         ## family median 3.24 of [2.4, 2.88, 3.6, 6.0]
const CYC_AMP: float = 0.5             ## multimeter's 5.0 V on its own 10 V full scale
const DRIFT_PHI: float = 0.864         ## multimeter mode 2: 0.3 rad/s over its 2.88 s tape

## A seeded LCG, so the prediction in the registry can be computed in Python and be
## EXACT rather than distributional. Numerically identical to the Python reference:
## s = (1103515245*s + 12345) & 0x7FFFFFFF, drawn once per tick in index order.
const RNG_A: int = 1103515245
const RNG_C: int = 12345
const RNG_M: int = 0x7FFFFFFF
const RNG_SEED: int = 7132026

# ── palette, character for character from all five members ───────────────
## Every one of the five declares these same five colours under these same names.
const C_PAPER := Color(0.93, 0.92, 0.86)
const C_INK := Color(0.10, 0.10, 0.12)
const C_RULE := Color(0.70, 0.68, 0.62)
const C_BAND := Color(0.86, 0.45, 0.06)
const C_MARK := Color(0.80, 0.10, 0.10)
## The case is this room's own; the family's instruments have no shared body colour.
const C_CASE := Color(0.27, 0.28, 0.30)
const C_WELL := Color(0.16, 0.17, 0.19)
const C_STONE := Color(0.30, 0.29, 0.30)
const C_STEEL := Color(0.55, 0.57, 0.60)
const C_CHALK := Color(0.88, 0.90, 0.95)

var _root: Node3D = null
var _built: bool = false
var _rng: int = RNG_SEED

## THE ONE SIGNAL. Deflection in [-1, 1], filled once in _run() and read by every lane
## that keeps anything. Nothing on this face re-derives it.
var _pass: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_check_vocabulary()
	_read_grid_config_meta()
	_rebuild()
	_built = true


## LAW 1, BOTH DIRECTIONS, at run time, because neither list can be derived from the
## other at parse time.
##
## There is no origin member for `record` (see the header), so instead of deferring to
## one owner this reads the @export_enum hint out of ALL FIVE members' scripts and
## checks each against RECORDS both ways. A push_error here means the room is exhibiting
## a vocabulary that is no longer the family's — or that two members have drifted apart
## from each other, which no per-artifact gate would catch.
##
## get_script_property_list() is called through a Script-TYPED LOCAL rather than on the
## const directly: a preloaded script whose class_name is declared gets treated as a
## type, and an instance method invoked on a type is the "non-static" failure that
## get_script_constant_map() is on record for.
func _check_vocabulary() -> void:
	var members: Dictionary = {
		"seismograph": M_SEISMOGRAPH,
		"multimeter": M_MULTIMETER,
		"atmosphericmonitoring": M_ATMOSPHERIC,
		"holographicdisplay": M_HOLOGRAPHIC,
		"dual_display_test": M_DUAL,
	}
	for who in members.keys():
		var sc: Script = members[who]
		var hint: String = ""
		var found: bool = false
		for p in sc.get_script_property_list():
			if str(p.get("name", "")) == "record":
				found = true
				hint = str(p.get("hint_string", ""))
		if not found:
			push_error("RecordRoom: %s no longer declares a `record` property" % who)
			continue
		if hint.is_empty():
			# Distinguishable from real drift on purpose: an empty hint means the engine
			# did not hand back an enum list, not that the member changed its mind.
			push_warning("RecordRoom: %s exposed no enum hint for `record`" % who)
			continue
		var theirs: PackedStringArray = hint.split(",", false)
		for word in theirs:
			if not RECORDS.has(word):
				push_error("RecordRoom: %s declares record '%s' and this face has no lane for it"
					% [who, word])
		for mine in RECORDS:
			if not theirs.has(mine):
				push_error("RecordRoom: this face exhibits '%s' and %s no longer declares it"
					% [mine, who])

	var own: String = ""
	for p2 in get_property_list():
		if str(p2.get("name", "")) == "behaviour":
			own = str(p2.get("hint_string", ""))
	var declared: PackedStringArray = own.split(",", false)
	for word2 in declared:
		if not BEHAVIOURS.has(word2):
			push_error("RecordRoom: export declares '%s', BEHAVIOURS does not" % word2)
	for word3 in BEHAVIOURS:
		if not declared.has(word3):
			push_error("RecordRoom: BEHAVIOURS has '%s', the export hint does not" % word3)


# ═══════════════════════════════════════════════════════════════════════════
# THE SIGNAL — one rule per value, and the only place each is written
# ═══════════════════════════════════════════════════════════════════════════

## The seeded stream. Drawn once per tick, in index order, whatever the value — so the
## draws `event` consumes are r[0] .. r[47] and are the same in Python.
##
## NOT named _draw: that is CanvasItem's virtual, and although a Node3D never receives
## it, a name that reads as an engine callback on a method that is not one is the kind
## of thing a later reader has to check twice.
func _rand01() -> float:
	_rng = (RNG_A * _rng + RNG_C) & RNG_M
	return float(_rng) / float(RNG_M)


## Fill the canonical pass once. Every lane that keeps anything reads this array, and
## the pen carriage in every lane reads its last element, so nothing on this face can
## drift out of agreement with anything else on it. evidence_ladder's rule taken as a
## construction constraint rather than quoted.
func _run() -> void:
	_rng = RNG_SEED
	_pass.clear()
	_pass.resize(N_TICK)
	for i in range(N_TICK):
		var u: float = float(i) / float(N_TICK - 1)
		var noise: float = _rand01() * 2.0 - 1.0
		var v: float = 0.0
		match behaviour:
			"cycle":
				v = CYC_AMP * sin(u * CYC_PERIODS * TAU)
			"drift":
				v = sin(-DRIFT_PHI * 0.5 + u * DRIFT_PHI)
			"steady":
				# EXACTLY flat, and that is measured rather than simplified. multimeter
				# mode 1's noise reaches ±0.0025 of full scale, which is 0.00009 px here.
				v = 0.0
			_:
				v = _event_baseline(i) + noise * EV_NOISE
		_pass[i] = clampf(v, -1.0, 1.0)


## EVENT — seismograph's baseline, with its decay running FORWARD in time. Its own code
## applies the decay to indices at .. at+30 while index 0 is its newest sample, so on
## that instrument the decay runs backwards into the past; here index 0 is the oldest
## and the decay follows the onset, which is what its detector's tween actually does.
func _event_baseline(i: int) -> float:
	var base: float = 0.0
	for k in range(EV_ONSET.size()):
		var at: int = EV_ONSET[k]
		if i >= at and i - at <= EV_DECAY:
			base = maxf(base, EV_MAG[k] * (1.0 - float(i - at) / float(EV_DECAY)))
	return base


func _lane_y(i: int) -> float:
	return (CASE_Y0 + CASE_Y1) * 0.5 + (0.5 * float(N_LANE - 1) - float(i)) * LANE_PITCH


func _tick_x(i: int) -> float:
	return PAPER_X0 + (PAPER_X1 - PAPER_X0) * float(i) / float(N_TICK - 1)


## The tick whose excursion a reader would ring. Ties go to the NEWEST, which is what
## decides it at `drift` (a monotone rise peaks at the pen) and at `steady` (everything
## is zero and a reader still has to mark something).
func _peak_tick() -> int:
	var pk: int = 0
	for i in range(N_TICK):
		if absf(_pass[i]) >= absf(_pass[pk]):
			pk = i
	return pk


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild() -> void:
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Face_%s" % behaviour
	add_child(_root)

	_run()
	_case(_root)

	for i in range(N_LANE):
		var lane := Node3D.new()
		lane.name = "Lane_%s" % RECORDS[i]
		lane.position = Vector3(0.0, _lane_y(i), 0.0)
		_root.add_child(lane)
		_fill_lane(lane, RECORDS[i])


## The case — plinth, body, header rail, cornice, and one nameplate per lane. Identical
## at every value of the axis and identical between lanes, so the RECORD is the only
## thing that varies, both down the face and across a sweep. Every mesh here is a
## MeshInstance3D box and the case encloses every MultiMesh in the artifact, so no
## layers = 0 extent anchor is needed and the capture AABB is the real body:
## 2.18 x 2.00 x 0.295, centre (0, 1.00, -0.0075).
func _case(root: Node3D) -> void:
	var stone: StandardMaterial3D = _matte(C_STONE)
	var shell: StandardMaterial3D = _matte(C_CASE)
	var depth: float = CASE_ZF - CASE_ZB
	var midz: float = (CASE_ZF + CASE_ZB) * 0.5

	root.add_child(_box(Vector3(0.0, CASE_Y0 * 0.5, (PLINTH_ZF + CASE_ZB) * 0.5),
		Vector3(CASE_W + 0.08, CASE_Y0, PLINTH_ZF - CASE_ZB), stone))
	root.add_child(_box(Vector3(0.0, (CASE_Y0 + CASE_Y1) * 0.5, midz),
		Vector3(CASE_W, CASE_Y1 - CASE_Y0, depth), shell))
	root.add_child(_box(Vector3(0.0, CASE_Y1 + HEAD_H * 0.5, midz),
		Vector3(CASE_W, HEAD_H, depth), shell))
	root.add_child(_box(Vector3(0.0, CASE_Y1 + HEAD_H + CORN_H * 0.5, midz),
		Vector3(CASE_W + CORN_OVER * 2.0, CORN_H, depth + CORN_OVER), stone))

	# One nameplate per lane, rotated a quarter turn — a channel label, where a chart
	# recorder puts it. Label3D hangs from its origin with HORIZONTAL_ALIGNMENT_CENTER
	# (both the class default and what _text sets explicitly), and these hang from each
	# lane's own centre line, so a centred block is right here and a left-aligned one
	# would run off the bottom of its lane.
	for i in range(N_LANE):
		var plate: Label3D = _text(RECORDS[i], Vector3(NAME_X, _lane_y(i), CASE_ZF + 0.013),
			36, 0.0018, C_CHALK)
		plate.rotation = Vector3(0.0, 0.0, PI * 0.5)
		root.add_child(plate)

	# THE TITLE DOES NOT NAME THE AXIS VALUE, deliberately. A caption carrying `event`
	# or `drift` would let a measurement of the trace be padded by a measurement of the
	# label. It is engraved on the header rail rather than floated above the cornice, so
	# it sits inside the mesh extent and cannot crop at a tighter framing — Label3D is
	# not counted by the capture AABB, which is the hazard that costs a retake.
	root.add_child(_text("one signal  ·  four records",
		Vector3(0.0, CASE_Y1 + HEAD_H * 0.5, CASE_ZF + 0.013), 40, 0.0018, C_CHALK))


func _fill_lane(lane: Node3D, regime: String) -> void:
	# THE WELL, THE SCALE AND THE PEN STAND IN ALL FOUR LANES. The instrument never
	# stops measuring, so the present reading is available at every rung — which is the
	# family's actual claim and the reason `instant` is a regime rather than a fault.
	lane.add_child(_box(Vector3((PAPER_X0 + PAPER_X1) * 0.5 - 0.01, 0.0, Z_WELL),
		Vector3(PAPER_X1 - PAPER_X0 + 0.06, LANE_H + 0.03, Z_WELL_D), _matte(C_WELL)))
	var steel: StandardMaterial3D = _matte(C_STEEL)
	for k in range(5):
		lane.add_child(_box(Vector3(SCALE_X, FS * (float(k) * 0.5 - 1.0), Z_FURN),
			Vector3(0.085, 0.008, Z_FURN_D), steel))
	lane.add_child(_box(Vector3(SCALE_X, 0.0, Z_FURN),
		Vector3(0.005, FS * 2.0, Z_FURN_D), steel))
	var pen_y: float = _pass[N_TICK - 1] * FS
	lane.add_child(_box(Vector3(PEN_X, pen_y, Z_PEN), Vector3(0.060, 0.034, Z_PEN_D), steel))
	lane.add_child(_box(Vector3(PEN_X + 0.062, pen_y, Z_PEN),
		Vector3(0.075, 0.010, Z_PEN_D), _matte(C_MARK)))

	if regime == "instant":
		# NO PAPER, and that is the value rather than an omission. The lane has its
		# well, its scale and its pen like the other three; what it does not have is
		# anywhere for the past to be. Identical at every value of `behaviour` except
		# for the pen height it shares with the other three — which is 0.9% of all the
		# change on this face, and is the whole of what an instrument that keeps
		# nothing can tell you about what it is attached to.
		return

	lane.add_child(_box(Vector3((PAPER_X0 + PAPER_X1) * 0.5, 0.0, Z_PAPER),
		Vector3(PAPER_X1 - PAPER_X0 + 0.02, LANE_H, Z_PAPER_D), _matte(C_PAPER)))

	if regime == "margin":
		_printed(lane)

	# THE TRACE. `window` draws the newest N_WINDOW ticks and nothing before them; the
	# segments it draws are the same segments, at the same x and the same scale, as the
	# right-hand end of `archive` above it — which is what makes the truncation visible
	# instead of asserted.
	var first: int = 0 if regime != "window" else N_TICK - N_WINDOW
	_trace(lane, first)

	if regime != "window":
		_runout(lane)
	if regime == "margin":
		_hand(lane)


## The trace, as one MultiMesh of segments. Each segment spans from tick i to tick i+1
## and is at least one pen wide, which is seismograph's own construction (min height
## 0.004 on its 0.005 bars) at this room's gauge.
func _trace(lane: Node3D, first: int) -> void:
	var step: float = _tick_x(1) - _tick_x(0)
	var mmi := _mm("Trace", _matte(C_INK))
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = N_TICK - 1 - first
	var n: int = 0
	for i in range(first, N_TICK - 1):
		var lo: float = minf(_pass[i], _pass[i + 1]) * FS
		var hi: float = maxf(_pass[i], _pass[i + 1]) * FS
		var h: float = maxf(hi - lo, TRACE_T)
		mm.set_instance_transform(n, Transform3D(
			Basis.IDENTITY.scaled(Vector3(step + 0.0012, h, Z_INK_D)),
			Vector3((_tick_x(i) + _tick_x(i + 1)) * 0.5, (lo + hi) * 0.5, Z_INK)))
		n += 1
	lane.add_child(mmi)


## WINDOW vs ARCHIVE, on paper: the run-out. A recorder switched on a minute ago has
## none of this; one that has been logging all shift has a concertina of it. All five
## members draw it — a fanfold on the bench, a wound spool, a fold stack — and on a
## vertical face it is three leaf edges standing at the old end of the paper. It is
## IDENTICAL at every value of the axis, so it is pure dilution to the bite measurement
## and it is kept anyway, because "the run-out is kept" is half of what the family
## means by archive and dropping it would have made the two rungs differ only in the
## length of a line.
func _runout(lane: Node3D) -> void:
	var paper: StandardMaterial3D = _matte(C_PAPER)
	for k in range(3):
		lane.add_child(_box(Vector3(FOLD_X + (float(k) - 1.0) * 0.024, 0.0, Z_FOLD),
			Vector3(0.016, LANE_H - 0.03, Z_FOLD_D), paper))


## MARGIN, part one: the chart printed to be READ AGAINST rather than merely written
## on. Three rules across it, five time rules down it, a tick scale along the foot, and
## two limit rails at ±BAND_V of full scale in the amber all five members use for a
## threshold. Every mark here is printed BEFORE any measurement and is identical at
## every value of the axis — which is the point, and is why `margin` measures barely
## more than `archive` does.
func _printed(lane: Node3D) -> void:
	var rule: StandardMaterial3D = _matte(C_RULE)
	var ink: StandardMaterial3D = _matte(C_INK)
	var band: StandardMaterial3D = _matte(C_BAND)
	var mid: float = (PAPER_X0 + PAPER_X1) * 0.5
	var span: float = PAPER_X1 - PAPER_X0
	for k in range(3):
		lane.add_child(_box(Vector3(mid, FS * (float(k) - 1.0), Z_FURN),
			Vector3(span, RULE_T, Z_FURN_D), rule))
	for k2 in range(5):
		var x: float = PAPER_X0 + span * float(k2) * 0.25
		lane.add_child(_box(Vector3(x, 0.0, Z_FURN),
			Vector3(RULE_T, LANE_H - 0.04, Z_FURN_D), rule))
		lane.add_child(_box(Vector3(x, -LANE_H * 0.5 + TICK_H * 0.5, Z_FURN),
			Vector3(TICK_W, TICK_H, Z_FURN_D), ink))
	for s in [-1.0, 1.0]:
		lane.add_child(_box(Vector3(mid, s * BAND_V * FS, Z_FURN),
			Vector3(span, BAND_T, Z_FURN_D), band))


## MARGIN, part two: the hand. Someone came back to this chart, found the largest
## excursion on it, ringed it and bracketed it — the moment a record stops being output
## and becomes evidence. All five members draw exactly this, and all five ring the
## argmax of |sample|.
##
## THE RING IS CLAMPED TO THE PAPER. At `drift` and `steady` the peak is the newest
## tick, and an unclamped ring would hang 2.43 px over the pen carriage — see law 7 in
## the header. A mark made on a chart cannot be drawn off the chart.
func _hand(lane: Node3D) -> void:
	var pk: int = _peak_tick()
	var px: float = clampf(_tick_x(pk), PAPER_X0 + RING_R + 0.012, PAPER_X1 - RING_R - 0.012)
	var py: float = _pass[pk] * FS
	var mark: StandardMaterial3D = _matte(C_MARK)

	var mmi := _mm("Ring", mark)
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = RING_BEADS
	for k in range(RING_BEADS):
		var a: float = TAU * float(k) / float(RING_BEADS)
		mm.set_instance_transform(k, Transform3D(
			Basis.IDENTITY.scaled(Vector3(RING_BEAD, RING_BEAD, Z_HAND_D)),
			Vector3(px + RING_R * cos(a), py + RING_R * sin(a), Z_HAND)))
	lane.add_child(mmi)

	var foot: float = -LANE_H * 0.5 + 0.055
	lane.add_child(_box(Vector3(px, foot, Z_HAND), Vector3(0.15, 0.010, Z_HAND_D), mark))
	for s in [-1.0, 1.0]:
		lane.add_child(_box(Vector3(px + s * 0.075, foot + 0.015, Z_HAND),
			Vector3(0.010, 0.032, Z_HAND_D), mark))


# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config, and
## the capture harness calls apply_grid_config before the scene enters the tree.
## Reading the metadata on the way in means the face is built once, correctly, instead
## of built as `event` and then torn down.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_behaviour"):
			var want: String = _clean(str(node.get_meta("config_behaviour")))
			if BEHAVIOURS.has(want):
				behaviour = want
		node = node.get_parent()


## Tokens: #behaviour:cycle · #behaviour:drift · #behaviour:steady
##
## GUARDED FOUR WAYS — the key must be present, the value must be one the code can
## build, it must differ from the one already standing, and _ready must have built once.
## This artifact has no placements today, so none of these guards is protecting a
## shipped map; they are here because the grid reaches this twice for one placement and
## an unguarded rebuild would raise four lanes twice for nothing.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("behaviour"):
		return
	var want: String = _clean(str(config["behaviour"]))
	if not BEHAVIOURS.has(want):
		return
	if want == behaviour:
		return
	behaviour = want
	if not _built:
		return          # _ready has not built yet and will build this value itself
	_rebuild()


func _clean(raw: String) -> String:
	return raw.strip_edges().to_lower()


# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════════════

func _matte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	m.metallic = 0.0
	return m


func _box(p: Vector3, s: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


## One MultiMesh over a unit box, scaled per instance — the trace's segments are all
## different sizes, so the atom is a unit cube and the size lives in the transform.
func _mm(nm: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	mm.instance_count = 0
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


## Non-billboard on purpose. LabelFramer frames HANGING labels and leaves text that
## already lies on a body alone — these lie on the case's own front face, so they keep
## their place and add no plate to the capture. Five labels in the whole artifact and
## not one of them names the axis value.
func _text(content: String, p: Vector3, size: int, px: float, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = px
	l.outline_size = 0
	l.modulate = c
	l.position = p
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
