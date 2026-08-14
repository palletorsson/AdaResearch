extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GhostCourt

## @identity
## name: Ghost Court
## concept: the four QFEP benches stood in one rank, their shared companion vocabulary
##   varied together — QFE = F − λE(S) + φΔE(S,t)
## tier: large
## truth: the four benches share one word for what stands beside them and four different
##   words for whether they are alive.
##
## ── WHAT THIS IS ──────────────────────────────────────────────────────────────
## A SYNTHESIS. Four floor-standing instruments — [[f_order_bench]] (F, the crystal),
## [[lambda_dial_bench]] (λ, the dial and its field), [[phi_rate_bench]] (φ, the floating
## flame) and [[qfep_reactor_bench]] (the whole formula, a console) — rebuilt at 1:1 by
## their own arithmetic, in their own palettes, standing in one rank on one deck. Nothing
## here is normalised onto a shared rail. There is no rack, no slat, no bar chart. Each
## bay is a faithful miniature-at-full-size of its source, and the two axes vary what the
## four instruments say about themselves.
##
## Every mesh comes out of `embodied_prop`'s own `_cylinder/_box/_torus/_sphere/
## _cylinder_between/_glow_mat/_matte_mat/_steel_mat/_glass_mat`, which is what the four
## sources are built from: material identity, not imitation.
##
## ── AXIS 1 — COMPLEMENT: what else stands in the frame ────────────────────────
## Word for word the family's own list, shared by all four benches:
##   none | ghost | supply | redaction | quorum
##
## In EVERY one of the four sources the `match complement` statement ends in a bare
## `pass` (f_order:201-202, lambda_dial:202-203, phi_rate:188-189, reactor:209-210) and
## the same comment says the dressing is appended LAST so that on `none` every child
## index above is untouched.
##
##   NONE — zero meshes, zero glyphs. NOT a default: a POSITION. Each bench isolates one
##     term of QFE = F − λE(S) + φΔE(S,t) and records nothing of the terms it dropped.
##     f_order:31-35 states it: "That silence is a position, not a neutral. An instrument
##     that isolates a variable is making a claim about what can be held still while you
##     look at something else, and the claim is invisible precisely because nothing on the
##     bench records it." For the reactor it is worse than silence — the bench is titled
##     "QFEP REACTOR BENCH — THE WHOLE FORMULA" (:196) and carries a dial for F, λ and φ
##     while having no dial, pipe or mention of S, the system every term is a term OF
##     (:37-42). So in this family NONE = ABSENCE UNMARKED.
##   GHOST — `_comp_ghost_one` (f_order:277-284, lambda_dial:305-317, phi_rate:278-289,
##     reactor:334-349, byte-identical apart from the anchor constants): per absent term a
##     capped stub post, a torus collar sealing its top, a backing plate, a smaller BLANKED
##     face plate in darker grey, and the term's glyph engraved dead-grey on the blank.
##     Every material is `_matte_mat`. Nothing emits. Nothing connects to the phenomenon.
##     So GHOST = PROVISION MADE AND NEVER FITTED — the socket the missing term would have
##     been bolted into, capped, its face plate blank, its tag unlit.
##     Three things it is NOT: it is not a depiction of the absent term (no small λ, no
##     small φ, no miniature system); it is not a residue or afterimage of anything; and it
##     is not a former state of the phenomenon in the frame. The absent thing is never the
##     subject's own past — it is ANOTHER PARTY, another term of the equation the subject
##     is one term of. Ghost here is hardware for a third party who never arrived.
##   SUPPLY — lit tributary conduits rise off the deck and plug into the hub under the
##     phenomenon, in the family's colour for that term, tagged at the base on bone. The
##     term is not self-standing; it is being fed.
##   REDACTION — a bone plate carrying the whole formula, the term this bench runs boxed
##     or underlined in accent, the others struck under matte-black bars. The bench prints
##     what it cut. NOTE: the struck terms are never instantiated — the else-branch adds
##     only the bar — so the bars redact BLANK BONE, and this court draws them over nothing
##     exactly as the code does, not as the docstring says.
##   QUORUM — lit satellite dials stand with the phenomenon, masts, faces, rings, needles,
##     each wired back into the hub. The bench admits it cannot mean anything alone.
##
## The ladder is monotone: none (not acknowledged) → ghost (acknowledged as unfitted
## hardware) → supply (acknowledged and fed) → redaction (acknowledged in writing and
## struck) → quorum (acknowledged, instrumented and wired in). Every step makes the absent
## term MORE present and MORE powered.
##
## THE COURT NAMES ITS BAYS BY THEIR ABSENCES. Each bay carries the two terms its bench
## does not run: A carries λ and φ, B carries F and φ, C carries F and λ, D carries E and
## S. At `none` there is not one glyph anywhere in the frame and the four bays stand
## unlabelled — which is the value, drawn. Term colours are consistent across the three
## benches that name terms (F always 0.55,0.92,0.99 · λ always 0.62,0.55,0.98 · φ always
## 0.55,0.99,0.78) while the reactor's pair is amber and rose, a palette nobody else uses,
## because E and S are not terms of the equation but the SYSTEM the terms are about. Three
## bays ghost each other; the fourth ghosts the referent.
##
## ── AXIS 2 — VERDICT: whether the bench is alive ──────────────────────────────
##   frozen | alive | noise
##
## THE FAMILY'S OWN WORD, taken from the code and not coined.
## `qfep_reactor_bench._verdict_state()` (:233-238) returns exactly "FROZEN" / "ALIVE" /
## "NOISE" on thresholds 0.28 and 0.72. `lambda_dial_bench` (:264-271) prints FROZEN /
## LIFE / NOISE. `phi_rate_bench` (:242,:245) prints "FROZEN = DEAD" and "MOVING = ALIVE".
## This court takes the reactor's triple character for character and REFUSES lambda_dial's
## "LIFE", because ALIVE occurs in two benches and LIFE in one.
##
## AND THIS IS THE ARGUMENT NO SINGLE BENCH CAN MAKE. The four share a companion vocabulary
## word for word — `ghost` is literally one object bolted to four different machines — and
## they do NOT share a vocabulary for their own life:
##   · lambda_dial and qfep_reactor print all three words.
##   · phi_rate prints two. `_rate` is clamped to [0.04, 1.0] (:224-230) and `_apply_form`
##     lerps ONE dead pose to ONE alive pose. There is no third state and no noise colour.
##     Bay C therefore builds IDENTICALLY at alive and at noise, to the byte. That equality
##     is the court's own self-test (see PREDICTION below) and it is also the finding: the
##     φ bench cannot be photographed at noise because it has nowhere to go.
##   · f_order_bench prints NO state word at any value. Its readout is "F ↓ %.2f" (:237),
##     its subtitle "minimize F → perfect crystal" (:139), and the word its own truth line
##     uses — "a perfect, frozen, dead thing" (:8) — never reaches the furniture.
## So bay A's FROZEN cell is its bench's stated GOAL (F = 0.05, the lowest free energy it
## can reach, meter down to a 3 px stub) while the same cell is the other three benches'
## stated DEATH. That contradiction is invisible in any single tile and unmissable in a
## rank of four. Reading left to right at verdict = frozen: a bench celebrating, three
## benches dying, in the same pose.
##
## PINNED SO THE AXES CANNOT BORROW FROM EACH OTHER. Disjoint geometry, disjoint code
## paths, disjoint z. `complement` writes ONLY the flank kit at |x| = COMP_X on the deck
## plane; `verdict` writes ONLY the unit transforms and the unit / meter / needle colours
## of each body, at the bodies' own heights. Not one mesh is shared. The single measured
## coupling is an occlusion: at (redaction, noise) a few of bay B's sprayed cubes float in
## front of the bone plate, because at λ = 1 the λ field overflows its own plinth and
## reaches almost a metre toward the camera. Declared, not discovered.
##
## ── WHAT THIS ARTIFACT ARGUES ─────────────────────────────────────────────────
## That a shared vocabulary is not the same as a shared position. Four instruments that
## speak identically about their absences — the same five words, the same hardware, the
## same ladder — turn out to have no common language at all for the one thing an instrument
## is for, which is saying whether the thing on it is alive. One of them cannot say it, one
## of them can only say two thirds of it, one says it in a different word, and the one that
## says it in full prints QFE = 1.00 for both a dead lattice and the living edge
## (reactor:249-252). The court is the only place that shows it, because the claim is a
## claim about a family and a family has no single tile.
##
## And one thing the code itself predicts, which the court is built to test: all four files
## carry the same comment at the head of `_comp_ghost_one` — grey and not black on purpose,
## "the capture stage is near-black, and a black value is an invisible one". The authors
## flagged, in the source, that ghost is the value at risk of measuring as nothing. If
## none|ghost comes back a twin pair, that is the finding and must be REPORTED, not fixed
## by inflating the mount. The mount's geometry is the family's and is not this file's to
## change.
##
## ── STILL, NOT PROCESS ────────────────────────────────────────────────────────
## The court has no `_process` and calls `set_process(false)`. Every source animates; the
## court freezes each at t = 0 and spatialises the sweep instead: three verdict states as
## three separate photographs, never a rate. All randomness is a deterministic hash of
## (index, draw, bay salt, court_seed) — never RandomNumberGenerator — so a variant is not
## also a different scatter. It preserves each source's distribution and DRAW ORDER (4
## draws per unit for A, B and D; 2 for C) but will not match Godot's PCG32, so the court's
## scatter is not the same scatter any solo tile shows. Declared.
##
## ── CORRECTIONS: THE CODE BEAT THE BRIEF ──────────────────────────────────────
## C1. THREE OF FOUR BODIES NEVER RENDER THE COLOUR THEY COMPUTE. f_order sets
##     `_mm.use_colors = true` (:177) and writes scatter→crystal colours (:218-219) under
##     `material_override = _glow_mat(crystal_color, 1.8)` (:185); lambda_dial writes
##     crystal→life→noise (:235-240) under `_glow_mat(Color(1,1,1), 1.8)` (:186); phi_rate
##     writes dead→alive→hot (:214) under `_glow_mat(Color(1,1,1), 2.2)` (:172).
##     `embodied_prop._glow_mat` (:25-32) never sets `vertex_color_use_as_albedo`, so a
##     StandardMaterial3D discards the instance colour: f_order photographs uniformly
##     crystal-blue and its violet scatter has never been seen, lambda_dial and phi_rate
##     photograph WHITE. Only qfep_reactor_bench renders its palette, because it builds 14
##     individual MeshInstance3D and assigns `material_override` per particle (:299). A
##     court "with the bays in their own palettes" is therefore impossible to build by
##     instancing the sources, so the court builds 187 individual MeshInstance3D and shows
##     what the arithmetic computes. One-line fix for the three sources:
##     `m.vertex_color_use_as_albedo = true` in `_glow_mat`.
## C2. THE REACTOR'S OWN SCALAR CANNOT TELL FROZEN FROM ALIVE. From :249-252,
##     qfe = (0.5 + (1−s)·0.5) − 0.5s + 0.5·aliveness(s). At s = 0 that is
##     1.0 − 0 + 0.00022 = 1.00; at s = 0.5 it is 0.75 − 0.25 + 0.5 = 1.00. The bench
##     titled THE WHOLE FORMULA prints QFE = 1.00 for a dead lattice and for the living
##     edge; only its verdict WORD separates them.
## C3. The lambda dial is NOT "tilted toward viewer" as :133 says. The backing cylinder
##     (:135) and the rim torus (:136) are UNROTATED — horizontal pucks — while the 11
##     ticks, the gold arc and the needle live in the vertical XY plane. The rendered dial
##     is a vertical clock intersecting a horizontal ring. The court copies the code.
## C4. The reactor's dial faces are NOT "tilted up on the deck" as :214 says. `_cylinder`
##     builds them with the Y axis up (:215), so the faces are HORIZONTAL and the needles
##     (:222, :260-266, rotating about Y) are read from above. This is why bay D's needles
##     are the weakest marks in the court — a fact about the reactor, not about the court.
## C5. The reactor's readout screen has never been visible. The panel (:188) spans
##     z −0.130..−0.110 and the screen (:189) sits at z −0.1205..−0.1155, fully inside it.
##     This court mounts it PROUD at z −0.1085..−0.1035 and says so: it does not copy a
##     defect it can see.
## C6. The complement kit is byte-identical across the four benches except FOUR constants
##     and TWO builders — one more of each than the source reports found. phi_rate sets
##     COMP_X = 0.34 where the others set 0.40; the reactor sets COMP_Y = 0.615 /
##     COMP_Z = 0.0 where the others set 0.145 / 0.10; the reactor's SUPPLY intake collar
##     is a torus of radius 0.26 tube 0.022 (:369) where the other three use 0.09 / 0.02;
##     and the reactor's redaction plate is a different function (:375-393 — two inks, two
##     lit underlines, two bars over EMPTY positions, and no mounting strut) from the
##     three-slot `_comp_formula_plate(keep)` the other three share. So `ghost` is one
##     object built four times, but `supply` and `redaction` are not. The court shows both.
## C7. The camera-depth sign in the wave brief is inverted. `capture_config_sweep.gd:443`
##     builds `dir = (sin yaw·cos pitch, −sin pitch, cos yaw·cos pitch)` and places the
##     camera at `c + dir·dist`, so with pitch = −0.26 the camera is ABOVE the subject and
##     a point HIGHER in the frame is CLOSER. Bay C's floating column is the closest body
##     in the court, not the farthest. Every layout number below was recomputed from the
##     source's own expression.
## C8. The brief's gold arc is 16 segment boxes; the source (:394-423) builds ONE
##     ImmediateMesh. The court reproduces the ImmediateMesh — more faithful and 15 meshes
##     cheaper.
##
## ── LAYOUT, AND WHY IT IS SOLVED AND NOT GUESSED ──────────────────────────────
## The court is one Node3D yawed +0.62 rad about Y. From the camera expression above, the
## standpoint's screen-right is r = (cos 0.62, 0, −sin 0.62) and r · dir = 0.4570 − 0.4570
## = 0 EXACTLY, so a rank laid along court-local x sits at ONE camera depth. In court-local
## coordinates the camera direction reduces to (0, 0.2571, 0.9664) and the right vector to
## (1, 0, 0): court-local x IS screen-x and court-local z IS depth. That is the direct
## answer to the wave-8 fault — the depth spread across bay centres is 1.000x by
## construction, and every bay's front faces the standpoint square.
##
## Bay order left→right is the equation's own order: A (F) · B (λ) · C (φ) · D (the whole
## formula). Pitch is GUTTER-DRIVEN, not uniform: each gap is set by the two neighbours'
## widest tenants over all fifteen cells plus a fixed 0.22 m of daylight, and the widths
## are recomputed AT BUILD TIME from the actual unit positions over all three verdicts and
## all five complements — so the layout is identical in every cell (the axes cannot couple
## through it) and survives any `court_seed`. A first pass at uniform pitch wasted a metre
## of court and shrank every mark.
##
## Measured court width 5.380 m, deck 5.540 x 0.07 x 1.04, at seed 20260814.
##
## THE WIDEST TENANT IS NOT ALWAYS FURNITURE, WHICH IS THE THING TO CHECK. In bays A, C and
## D it is the quorum ring (mast at COMP_X plus ring outer 0.129 → 0.529 / 0.469) or the
## F-meter rail at x −0.525 or the ΔE/Δt rail at −0.485. In bay B it is the PHENOMENON: at
## λ = 1 the 49 cubes reach x −0.78 / +0.66 and z +1.04, overflowing their own 0.46 m
## plinth radius by 1.7x and standing a metre nearer the camera than the bay plane. Bay B
## measures 1.489 m wide at noise against 1.359 m at frozen and alive, so the court is
## spaced by the noise state and at the other two the extra daylight is visible — which is
## itself the reading: the noise state does not fit on the bench.
##
## LAW 9 CHECKED BY PROJECTION, NOT BY THE FLAT FORMULA. Because the bays are yawed square
## to the camera the world-aligned formula hx·cos 0.62 + hz·sin 0.62 over-reads bay A by
## 32%, which is exactly what the yaw buys. But perspective still magnifies near tenants,
## so each bay's half-extents are inflated by ref/(ref − 0.9664·Δz − 0.2571·Δy) before the
## gutters are laid out. Replayed with this file's own constants at seed 20260814,
## framing 0.39, 760 px, projecting every unit's silhouette and every static AABB corner:
##   bay screen-x  A [16.7, 186.4]  B [197.8, 400.1]  C [428.0, 564.1]  D [576.6, 743.1]
##   DAYLIGHT  +11.4 px (A|B)   +27.9 px (B|C)   +12.5 px (C|D)
## All positive at the widest variant of BOTH axes, and all three are floors: the static
## part is measured from AABB corners, which pairs extreme x with extreme z even where no
## mesh does. The binding gaps are A|B and C|D, and A|B is closed by bay B's near cloud,
## not by any piece of furniture. Without the perspective inflation the same 0.22 m gutter
## measures −2.0 px at A|B — the bays would OVERLAP, which is the wave-8 fault exactly.
##
## ── FRAMING 0.39, SOLVED ──────────────────────────────────────────────────────
## The court is a wide flat thing and PAD 1.9 fits the DIAGONAL, the corpus's documented
## failure mode for exactly this shape. World union after the yaw is 5.61 x 2.66 x 4.76 m,
## diagonal 7.83, R = 3.913. At framing 1.0 the visible width at the subject plane is
## 3.8·R = 14.9 m for a court 5.38 m wide — the court would fill 36% of the frame, every
## mark would shrink 2.6x, the ghost face plate would measure 10 px instead of 26 and bay
## D's particles 1.6 px instead of 4.1, and the exhibit would be the "too small to measure"
## failure rather than an axis. framing = court_w · 1.06 / (3.8 · R) = 0.3835, declared
## 0.39 for a little margin, which puts the camera at 9.484 m and gives 128.9 px/m at the
## complement plane. Verified by projection: the court spans screen-x 13.6..746.4 px (96%
## of frame width) and screen-y 202.8..564.3 px. 48% of the frame height is deliberately
## empty, and it is empty for a reason worth photographing — the court's height is set by
## bay C's column floating at y 1.65..2.59 while the other three top out at 1.25, 1.30 and
## 1.33. THAT VACANT BAND IS THE phi_rate DOUBLE-ADD, 167 px tall, and the air between the
## emitter ring and the bottom of the thing it is supposed to emit is 138 px (see R6).
##
## ── PIXEL GAUGE: PER BAY, AT ITS OWN DEPTH ────────────────────────────────────
## Complement plane: A 128.9 · B 128.9 · C 128.9 · D 129.3 px/m. Spread 1.003x — the rank
## is iso-depth by construction, so unlike wave 8 there is one honest number here. The
## WORST bay is A/B/C at 128.9 px/m; bay D is fractionally NEARER, because it alone sets
## COMP_Z = 0.0 and COMP_Y = 0.615 and the camera is above looking down, so higher is
## nearer (C7). Every number below is quoted at the worst bay:
##   ghost face plate 0.20x0.24 → 25.8 x 30.9 px · backing 0.23x0.27 → 29.7 x 34.8 px
##   ghost capped post ⌀0.10x0.30 → 12.9 x 38.7 px · glyph, font 26 → ~17 px cap height
##   supply riser ⌀0.056x0.28 → 7.2 x 36.1 px · bone tag 0.13x0.11 → 16.8 x 14.2 px
##   redaction plate 0.74x0.22 → 95.4 x 28.4 px (bay D's is 0.88 → 113.5) · bar → 20 x 17
##   quorum ring OD 0.258 → 33.3 px lit · dial face 0.20 → 25.8 px · mast → 9.0 x 61.9 px
##   quorum needle 0.014x0.085 → 1.8 x 11.0 px  ← the smallest thing in the kit
## The needle is a hairline and is NOT what carries quorum; the ring (33 px, lit) and the
## mast (62 px) are. Everything else clears 12 px in at least one dimension, and the ghost
## mount — the value most at risk — presents a 30x35 px plate plus a 13x39 px post per
## side, eight times per frame.
## Body planes, at each bay's own depth, which is where the verdict axis is gauged:
##   A 128.9 px/m — lattice 58 px → half-gathered 69 px → cloud 90 x 82 px;
##                  F-meter fill 64.5 px at F=1.00 falling to 3.2 px at F=0.05
##   B 129.1-129.5 — flat field 114 x 13 px → travelling wave 114 x 44 px →
##                  cloud 187 x 167 px; dial OD 72 px, needle sweeping 270° at 28 px
##   C 131.5-132.9 (the closest body in the court) — pile 25 x 27 px → column 58 x 126 px
##   D 128.2-128.8 — ring 36 x 19 px → swarm 28 x 29 px → cloud 36 x 32 px; glass 56 px;
##                  deck dial OD 24.5 px, its needle 9.0 px, one particle 4.1 px
## TWO MARKS SIT UNDER THE ~10 px BAR AND BOTH ARE DECLARED RATHER THAN RELIED ON: the
## quorum needle, and bay D's 14 particles at 4.1 px which carry their verdict by COLOUR —
## (0.40,0.64,1.0) → (0.50,0.99,0.74) → (0.78,0.52,0.98) across a 36 px cloud — not by
## outline. Its three deck needles at 9.0 px are nearly edge-on anyway (C4). Bay D is
## therefore the weakest verdict bay, and if it reads static that is a fact about the
## reactor: the console that claims the whole formula changes less across its own life
## than any of the three single-term benches.
##
## ── Z-STACK: NOTHING OPAQUE IN FRONT OF A MARK ────────────────────────────────
## Bay-local, +z toward the camera. COMP_Z = 0.10 for A/B/C, 0.0 for D.
## · ghost: post 0.050..0.150 (y ends 0.445) | backing 0.090..0.110 | blanked face
##   0.106..0.126 | glyph ink plane 0.135, 9 mm proud of the face. The post's front is
##   ahead of the ink but tops out below it in screen-y. Clear.
## · supply: base torus 0.082..0.118 | riser 0.072..0.128 | conduit to hub | bone tag
##   0.1475..0.1625 | glyph ink 0.170, 7.5 mm proud. Clear.
## · redaction A/B/C: strut 0.030..0.143 | steel 0.133..0.153 | bone 0.145..0.165 | accent
##   glow 0.163..0.169 | bars 0.164..0.176 | "QFE =" ink 0.175 | kept-term ink 0.180.
##   Front to back: kept ink > bars > QFE ink > accent > bone > steel. Every mark is in
##   front of its own plate and the bars are in front of everything, which is the point.
##   One tight clearance carried over from the source: bar slot 0 spans x −0.113..−0.017
##   and the "QFE =" ink ends at x −0.115 — a 2 mm gap, 0.26 px. Non-overlapping, noted.
## · redaction D: steel 0.268..0.288 | bone 0.280..0.300 | lit underlines 0.298..0.304 |
##   ink 0.310 | bars 0.299..0.311. The bars are front-most by 1 mm, deliberately, and bar
##   0 clips the last 13 mm (1.7 px) of "QFE = F − λE". That clip is in the source, kept.
## · quorum: mast 0.065..0.135 | dial face 0.0925..0.1075 | ring (rotated 90° about X, so
##   it stands in XY) 0.098..0.126 | needle 0.124..0.136 | glyph ink 0.130. The ink is 4 mm
##   in front of the ring's front tube and wins on depth. Clear.
## · Bay A's glass cage is alpha 0.08 — a 92%-transmissive tint, not an occluder — and at
##   noise part of the crystal pokes through it, as it does in the source. Bay D's glass
##   sphere is alpha 0.13, likewise. Bay C is the cleanest bay in the court: its complement
##   kit occupies y 0.145..0.745 and its column floats at y 1.65..2.59, so they never
##   overlap in screen-y and nothing the complement axis draws can touch the φ body.
## · The deck (y −0.070..0.000) is below every mark in the court.
##
## ── PREDICTION, MADE BEFORE THE CAPTURE ───────────────────────────────────────
## 1. THE EQUALITY, AND THE ONE THAT GATES THE RUN. Bay C at `alive` and bay C at `noise`
##    are the same build to the byte (see AXIS 2). Cropped to bay C's screen box, x 428..564
##    px, those two frames MUST measure 0.00%. Anything above ~0.5% there means the builder
##    is not deterministic — a hash or child-ordering fault — and no number from the run is
##    about either axis. Cheapest possible self-test, free with the sweep.
## 2. THE CLOSEST FULL-FRAME PAIR IS none|ghost, at every verdict, and by the same amount
##    at each to within about 0.1 pp (the ghost kit is byte-identical across the three
##    verdicts and its projected area does not depend on the bodies' state). THE
##    ARITHMETIC, at the measured 128.9 px/m: per mount the backing plate is 29.7 x 34.8 =
##    1,034 px², the post adds 12.9 x 18.0 = 232 px² below it, and the collar torus is
##    narrower than the plate and hidden — call it 1,270 px² per mount, 8 mounts, ~10,100
##    px² changed, 1.75% of the 760² frame. The critic's focus window is the hottest 5% =
##    28,880 px², so the changed pixels fill about 35% of it and the rest of the window is
##    zero: focus ≈ 0.35 x amplitude. Amplitude is small because the mount's largest face
##    is the blanked plate at albedo (0.21,0.22,0.27) against a (0.055,0.055,0.070) stage —
##    flat-shaded that is ~0.16, giving ~5.6%. The real render adds a key, a fill and
##    FILMIC and should roughly double matte amplitude, so EXPECT 6–12%, straddling
##    TWIN_FOCUS 6.0%. If it lands under 6.0%, ghost and none are photographically the same
##    claim in this family and that is the WAVE FINDING, to be reported and not fixed. If
##    it lands BELOW ~5.6%, STOP AND INVESTIGATE: the corpus's four prior predictions
##    under-shot by 1.5x, 1.7x, 3.5x and 6.7x, and the only artifact ever to measure below
##    its own prediction was broken.
## 3. BOTH AXES BITE, and the ordering matters more than the peak: complement peak is
##    redaction|quorum, minimum none|ghost; verdict peak is frozen|noise, minimum
##    frozen|alive. READ THE PER-PAIR ROWS. A two-axis sweep's headline is a PEAK, so a
##    live axis hides a dead one — that is exactly how tier_terrarium published ten frames
##    of its default.
## 4. THE AXES ARE INDEPENDENT TO WITHIN ONE COUPLING, SIGNED IN ADVANCE: at
##    complement = redaction the verdict difference should DIP slightly, because bay B's
##    λ = 1 spray puts a few cubes in front of the bone plate. If any OTHER complement
##    value shifts a verdict pair by more than about 1.3 pp, the two axes are sharing
##    geometry somewhere this file has not accounted for.
##
## ── RISKS ─────────────────────────────────────────────────────────────────────
## R1. none|ghost may be flagged a twin pair. See prediction 2 — report it, do not fix it
##     by inflating the mount.
## R2. Bay D is the weakest verdict bay (4.1 px particles, 9.0 px needles on horizontal
##     faces). If it reads static, that is a fact about the reactor. Report, do not patch.
## R3. THE LAYOUT DEPENDS ON A SEED — bay B's λ = 1 cloud sets the A|B daylight. Mitigated
##     by construction: extents are computed at build time from the actual positions, so
##     the gutter survives any seed. `dna.framing` 0.39 was solved for seed 20260814 and
##     would drift a percent or two under another.
## R4. The hash is not Godot's PCG32 (see STILL, NOT PROCESS).
## R5. The +0.62 yaw is what makes the per-bay pixel equality true, and it costs footprint:
##     roughly 6x5 grid cells placed, against 6x2 at `court_yaw = 0.0`. The export exists so
##     a map can stand the rank square to a room; every pixel claim here holds only at 0.62.
## R6. THE φ COLUMN FLOATS 1.07 m ABOVE THE RING THAT IS SUPPOSED TO EMIT IT, and the
##     supply and quorum plumbing terminates at a hub the column never touches. A viewer
##     will read that as a defect in the synthesis. It is phi_rate_bench.gd:194 + :212
##     double-adding `column_center`: bottom = 1.05 − 0.45 = 0.60, alive_pos.y =
##     0.60 + 0.9·h01, and then `pos = column_center + dead.lerp(alive, rate)` adds 1.05
##     again, so the column stands at y 1.65..2.55. Its own registry AABB height of 2.55 m
##     proves this is the shipped code path. The vacant 167 px band above three of the four
##     bays, and the 138 px of empty air between the emitter ring and the bottom of the
##     thing it is supposed to emit, are the most legible things in the frame about it.
## R7. Every billboard title, subtitle and readout of all four benches is OMITTED.
##     `_billboard_label` sets outline 10 and no_depth_test, and GridInteractablesComponent
##     runs LabelFramer on billboards at spawn, which builds a bezel and a panel behind each
##     one; four of those in a rank would out-mass the phenomena. The only Label3D in the
##     court are the 8 complement glyphs, which are `_comp_ink` (BILLBOARD_DISABLED,
##     depth-tested, outline 0) and which LabelFramer skips. So the court has ZERO framed
##     text, shows no bench name and no verdict word, and the state is read off each
##     source's own meter, needle and colour. Anyone expecting the court to caption itself
##     will find it mute, deliberately.
## R8. NO MultiMesh anywhere — 187 individual MeshInstance3D. Law 11 is discharged by
##     construction (nothing to anchor, the capture AABB sees every unit) and it is the
##     only way C1's palettes render at all. Worst cell is 299 meshes + 8 Label3D = 307
##     nodes against the ~3200 ceiling, and it is a static non-animating build.

# ── AXES ─────────────────────────────────────────────────────────────────────
# Declared order is load-bearing: the gallery trims from the END of the LATER axis,
# so the longer list goes first.
@export_enum("none", "ghost", "supply", "redaction", "quorum") var complement: String = "none"
const COMPLEMENTS: PackedStringArray = ["none", "ghost", "supply", "redaction", "quorum"]

@export_enum("frozen", "alive", "noise") var verdict: String = "alive"
const VERDICTS: PackedStringArray = ["frozen", "alive", "noise"]

## Yaw of the whole rank about Y. 0.62 rad stands every bay square to the sweep
## standpoint, which is what makes the four bays iso-depth. 0.0 stands the rank square
## to a room instead, at the cost of every pixel claim in the header.
@export var court_yaw: float = 0.62

## Deterministic scatter seed. No RandomNumberGenerator anywhere: a variant must never
## also be a different scatter.
@export var court_seed: int = 20260814

## Daylight between neighbouring bays, in metres, before perspective inflation.
@export var court_gutter: float = 0.22

## Nominal camera distance used ONLY to widen the gutters for tenants that lean toward
## the standpoint (bay B's λ = 1 cloud reaches 1.04 m forward). The solved distance at
## framing 0.39 is 9.484 m; this is a second-order correction, so the nominal 9.37 that
## every number in the header was verified against is close enough and is what ships.
@export var court_ref_dist: float = 9.37

# ── camera, in court-local components (see C7) ───────────────────────────────
const CAM_DZ: float = 0.96634
const CAM_DY: float = 0.25708

# ── bay salts, so four bays do not draw the same hash sequence ───────────────
const SALT_A: int = 0
const SALT_B: int = 1013
const SALT_C: int = 2026
const SALT_D: int = 3039

# ── BAY A — f_order_bench ────────────────────────────────────────────────────
const A_N: int = 4
const A_PITCH: float = 0.12
const A_CENTER := Vector3(0.0, 1.0, 0.0)
const A_CRYSTAL := Color(0.5, 0.8, 1.0)
const A_SCATTER := Color(0.65, 0.6, 0.95)
const A_FRAME := Color(0.55, 0.7, 0.95)
const A_ORDER := [1.0, 0.5, 0.0]                 # frozen · alive · noise

# ── BAY B — lambda_dial_bench ────────────────────────────────────────────────
const B_N: int = 7
const B_PITCH: float = 0.13
const B_CENTER := Vector3(0.0, 1.05, 0.0)
const B_DIAL := Vector3(-0.55, 1.05, 0.0)
const B_CRYSTAL := Color(0.45, 0.75, 1.0)
const B_LIFE := Color(0.5, 1.0, 0.65)
const B_NOISE := Color(0.95, 0.5, 0.85)
const B_LAMBDA := [0.0, 0.4, 1.0]
const GOLD_LO: float = 0.3
const GOLD_HI: float = 0.5

# ── BAY C — phi_rate_bench ───────────────────────────────────────────────────
const C_COUNT: int = 60
const C_RADIUS: float = 0.16
const C_HEIGHT: float = 0.9
const C_CENTER := Vector3(0.0, 1.05, 0.0)
const C_ALIVE := Color(0.4, 0.95, 1.0)
const C_HOT := Color(0.7, 0.95, 1.0)
const C_DEAD := Color(0.32, 0.34, 0.4)
const C_RATE := [0.04, 1.0, 1.0]                 # NO third state — see AXIS 2 / prediction 1

# ── BAY D — qfep_reactor_bench ───────────────────────────────────────────────
const D_COUNT: int = 14
const D_CHAMBER := Vector3(0.0, 0.78, 0.0)
const D_CHAMBER_R: float = 0.20
const D_DIAL_R: float = 0.085
const D_BODY := Color(0.14, 0.16, 0.23)
const D_GLASS := Color(0.46, 0.78, 0.98)
const D_FROZEN := Color(0.40, 0.64, 1.0)
const D_ALIVE := Color(0.50, 0.99, 0.74)
const D_NOISE := Color(0.78, 0.52, 0.98)
const D_PANEL := Color(0.07, 0.09, 0.13)
const D_READOUT := Color(0.55, 0.98, 0.85)
const D_SWEEP := [0.0, 0.5, 1.0]

# ── the family's term colours (identical constants in all four sources) ──────
const TERM_F := Color(0.55, 0.92, 0.99)
const TERM_L := Color(0.62, 0.55, 0.98)
const TERM_P := Color(0.55, 0.99, 0.78)
const TERM_E := Color(0.98, 0.78, 0.42)
const TERM_S := Color(0.98, 0.55, 0.62)

# ── complement anchors, per bay (C6: four constants differ, not three) ───────
const COMP_X := [0.40, 0.40, 0.34, 0.40]
const COMP_Y := [0.145, 0.145, 0.145, 0.615]
const COMP_Z := [0.10, 0.10, 0.10, 0.0]
const PLATE_PY := [0.60, 0.62, 0.36, 0.34]
const PLATE_KEEP := [0, 1, 2, -1]                # -1 = the reactor's own plate builder
const GLYPH_A := ["λ", "F", "F", "E"]
const GLYPH_B := ["φ", "φ", "λ", "S"]
const BAY_NAMES := ["A_FOrder", "B_LambdaDial", "C_PhiRate", "D_QfepReactor"]

## Merged AABB of each bay's FURNITURE plus ALL FIVE complement kits — the part of a
## bay that does not depend on either axis. Bodies are measured live in _bay_bounds.
## [x_lo, x_hi, y_lo, y_hi, z_lo, z_hi], bay-local.
const STATIC := [
	[-0.529, 0.529, 0.0, 1.250, -0.460, 0.460],
	[-0.830, 0.529, 0.0, 1.295, -0.460, 0.460],
	[-0.485, 0.469, 0.0, 1.325, -0.440, 0.440],
	[-0.529, 0.529, 0.0, 1.330, -0.300, 0.433],
]

## Half-diagonal of one unit, per bay — a rotated cube's silhouette, a sphere's radius.
const UNIT_R := [0.12 * 0.42 * 0.8660254, 0.13 * 0.46 * 0.8660254, 0.03, 0.016]

var _bay_x: PackedFloat32Array = PackedFloat32Array()
var _deck_w: float = 5.44


func _ready() -> void:
	_read_dna_meta()
	_axis_self_check()
	_build()
	set_process(false)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("emissive"):
		emissive = bool(config_data["emissive"])
	if config_data.has("complement"):
		var c_in: String = str(config_data["complement"]).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if config_data.has("verdict"):
		var v_in: String = str(config_data["verdict"]).strip_edges().to_lower()
		verdict = v_in if VERDICTS.has(v_in) else verdict
	if config_data.has("court_seed"):
		court_seed = int(str(config_data["court_seed"]))
	if config_data.has("court_yaw"):
		court_yaw = float(str(config_data["court_yaw"]))
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the first
# build; apply_grid_config (deferred) covers the rebuild path. Unknown words keep the
# default — an axis must never be able to blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_complement"):
		var c_in: String = str(get_meta("config_complement")).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if has_meta("config_verdict"):
		var v_in: String = str(get_meta("config_verdict")).strip_edges().to_lower()
		verdict = v_in if VERDICTS.has(v_in) else verdict
	if has_meta("config_court_seed"):
		court_seed = int(str(get_meta("config_court_seed")))
	if has_meta("config_court_yaw"):
		court_yaw = float(str(get_meta("config_court_yaw")))


# ── SELF-CHECK ───────────────────────────────────────────────────────────────
# A declaration that disagrees with the code runs every gate green and reports a fact
# about a typo. science_screen shipped `none|bezel|hooded|cabinet` against a code enum
# of `stand|wall|console|rig`, swept sixteen identical frames and was called INERT at
# 0.69%. Both directions, and in order.
func _axis_self_check() -> void:
	_check_axis("complement", COMPLEMENTS)
	_check_axis("verdict", VERDICTS)


func _check_axis(prop: String, list: PackedStringArray) -> void:
	var hint: String = ""
	var found: bool = false
	for p in get_property_list():
		if String(p.get("name", "")) == prop:
			hint = String(p.get("hint_string", ""))
			found = true
			break
	if not found:
		push_error("ghost_court: no exported property named '%s'" % prop)
		return
	var parts: PackedStringArray = hint.split(",")
	if parts.size() != list.size():
		push_error("ghost_court: %s hint has %d values, const list has %d — '%s'"
			% [prop, parts.size(), list.size(), hint])
		return
	for i in range(list.size()):
		if parts[i] != list[i]:
			push_error("ghost_court: %s value %d is '%s' in the hint and '%s' in the const list"
				% [prop, i, parts[i], list[i]])
	for i in range(list.size()):
		if not parts.has(list[i]):
			push_error("ghost_court: %s const value '%s' is missing from the hint" % [prop, list[i]])
	for i in range(parts.size()):
		if not list.has(parts[i]):
			push_error("ghost_court: %s hint value '%s' is missing from the const list" % [prop, parts[i]])


func _verdict_index() -> int:
	for i in range(VERDICTS.size()):
		if VERDICTS[i] == verdict:
			return i
	return 1


# ── DETERMINISTIC HASH ───────────────────────────────────────────────────────
func _h(i: int, k: int, salt: int) -> float:
	var v: float = sin(float(i + salt) * 127.1 + float(k) * 311.7 + 19.19 + float(court_seed)) * 43758.5453
	return v - floorf(v)


func _hs(i: int, k: int, salt: int) -> float:
	return _h(i, k, salt) * 2.0 - 1.0


# ── UNIT POSITIONS ───────────────────────────────────────────────────────────
# ONE source of truth: the layout scan and the builder both call this, so the two can
# never drift. Every source's formula, evaluated at t = 0 (law 5: a still, not a rate).
func _unit_positions(bay: int, v: int) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	match bay:
		0:
			# f_order_bench.gd:152-172 (sites + scatter) and :205-219 (_apply_units)
			var order: float = A_ORDER[v]
			var span: float = float(A_N - 1) * A_PITCH + 0.12
			var rscatter: float = span * 0.55
			var amp: float = A_PITCH * 0.5 * (1.0 - order)
			var off_a: float = float(A_N - 1) * 0.5
			out.resize(A_N * A_N * A_N)
			var ia: int = 0
			for ix in range(A_N):
				for iy in range(A_N):
					for iz in range(A_N):
						var site: Vector3 = A_CENTER + Vector3(
							(float(ix) - off_a) * A_PITCH,
							(float(iy) - off_a) * A_PITCH,
							(float(iz) - off_a) * A_PITCH)
						var sc: Vector3 = A_CENTER + Vector3(
							_hs(ia, 0, SALT_A), _hs(ia, 1, SALT_A), _hs(ia, 2, SALT_A)) * rscatter
						var ph: float = _h(ia, 3, SALT_A) * TAU
						var dis: Vector3 = sc + Vector3(sin(ph), cos(ph * 1.7), sin(ph * 0.6)) * amp
						out[ia] = dis.lerp(site, order)
						ia += 1
		1:
			# lambda_dial_bench.gd:163-174 (grid + seed_off) and :213-240 (_apply_field)
			var lam: float = B_LAMBDA[v]
			var life: float = _life_strength(lam)
			var noise_w: float = clampf((lam - GOLD_HI) / (1.0 - GOLD_HI), 0.0, 1.0)
			var spread: float = B_PITCH * float(B_N) * 0.5
			var off_b: float = float(B_N - 1) * 0.5
			out.resize(B_N * B_N)
			var ib: int = 0
			for ix2 in range(B_N):
				for iz2 in range(B_N):
					var site2: Vector3 = B_CENTER + Vector3(
						(float(ix2) - off_b) * B_PITCH, 0.0, (float(iz2) - off_b) * B_PITCH)
					var ph2: float = _h(ib, 3, SALT_B) * TAU
					var nz: Vector3 = Vector3(
						_hs(ib, 0, SALT_B), _hs(ib, 1, SALT_B), _hs(ib, 2, SALT_B)) * spread * noise_w
					nz += Vector3(sin(ph2), cos(ph2 * 1.4), sin(ph2 * 0.7)) * (B_PITCH * 1.6 * noise_w)
					var wave: float = sin((site2.x + site2.z) * 6.0 + ph2 * 0.2)
					out[ib] = site2 + nz + Vector3(0.0, wave * B_PITCH * 0.9 * life, 0.0)
					ib += 1
		2:
			# phi_rate_bench.gd:151-158 (helix) and :192-215 (_apply_form).
			# The double-add at :194 + :212 is REPRODUCED, not repaired — see R6.
			var rate: float = C_RATE[v]
			var bottom: float = C_CENTER.y - C_HEIGHT * 0.5
			out.resize(C_COUNT)
			for ic in range(C_COUNT):
				var h01: float = float(ic) / float(C_COUNT)
				var ba: float = h01 * TAU * 3.0 + _h(ic, 0, SALT_C) * 0.3
				var ph3: float = _h(ic, 1, SALT_C) * TAU
				var taper: float = 1.0 - h01 * 0.6
				var rad: float = C_RADIUS * taper
				var breath: float = 1.0 + 0.35 * sin(ph3)
				var alive_pos: Vector3 = Vector3(
					cos(ba) * rad * breath,
					bottom + h01 * C_HEIGHT + sin(ph3) * 0.04 * rate,
					sin(ba) * rad * breath)
				var dead_pos: Vector3 = Vector3(
					cos(ph3) * C_RADIUS * 1.3 * h01 * 0.4,
					bottom + h01 * 0.12,
					sin(ph3) * C_RADIUS * 1.3 * h01 * 0.4)
				out[ic] = C_CENTER + dead_pos.lerp(alive_pos, rate)
		_:
			# qfep_reactor_bench.gd:173-185 (order + chaos homes) and :284-298 (_process)
			var s: float = D_SWEEP[v]
			var alv: float = _aliveness(s)
			var jf: float = clampf((s - 0.5) * 2.0, 0.0, 1.0)
			out.resize(D_COUNT)
			for id in range(D_COUNT):
				var ang: float = TAU * float(id) / float(D_COUNT)
				var ordp: Vector3 = D_CHAMBER + Vector3(
					cos(ang), sin(ang * 2.3) * 0.5, sin(ang)) * (D_CHAMBER_R * 0.62)
				var dirv: Vector3 = Vector3(
					_hs(id, 0, SALT_D), _hs(id, 1, SALT_D), _hs(id, 2, SALT_D)).normalized()
				var chp: Vector3 = D_CHAMBER + dirv * (D_CHAMBER_R * (0.45 + _h(id, 3, SALT_D) * 0.47))
				var home: Vector3 = ordp.lerp(chp, s)
				var breath2: Vector3 = Vector3(
					sin(float(id) * 1.3), cos(float(id) * 0.8), sin(float(id))) * (0.02 * alv)
				var jit: Vector3 = Vector3(
					sin(float(id)), cos(float(id) * 2.1), sin(float(id) * 0.7)) * (0.012 * jf)
				out[id] = home + breath2 + jit
	return out


func _life_strength(lam: float) -> float:
	# lambda_dial_bench.gd:206-210
	var mid: float = (GOLD_LO + GOLD_HI) * 0.5
	var d: float = absf(lam - mid) / 0.28
	return clampf(1.0 - d * d, 0.0, 1.0)


func _aliveness(s: float) -> float:
	# qfep_reactor_bench.gd:228-230
	return exp(-pow((s - 0.5) / 0.18, 2.0))


func _state_color(s: float) -> Color:
	# qfep_reactor_bench.gd:241-244
	if s < 0.5:
		return D_FROZEN.lerp(D_ALIVE, s * 2.0)
	return D_ALIVE.lerp(D_NOISE, (s - 0.5) * 2.0)


# ── LAYOUT ───────────────────────────────────────────────────────────────────
# Two passes. Pass 1 is flat and only fixes the court's y/z centre; pass 2 inflates each
# bay's screen half-extents for depth, because perspective magnifies a tenant that leans
# toward the standpoint and bay B's λ = 1 cloud leans a full metre. Computed over ALL
# THREE verdicts and ALL FIVE complements every time, so the rank is identical in every
# cell — the axes cannot couple through the layout.
func _layout() -> void:
	var flat: Array = []
	for b in range(4):
		flat.append(_bay_bounds(b, 0.0, 0.0, 0.0))
	var ylo: float = -0.07
	var yhi: float = 0.0
	var zlo: float = -0.52
	var zhi: float = 0.52
	for b2 in range(4):
		var q: PackedFloat32Array = flat[b2]
		ylo = minf(ylo, q[2])
		yhi = maxf(yhi, q[3])
		zlo = minf(zlo, q[4])
		zhi = maxf(zhi, q[5])
	var yc: float = (ylo + yhi) * 0.5
	var zc: float = (zlo + zhi) * 0.5

	var spans: Array = []
	var total: float = 0.0
	for b3 in range(4):
		var q2: PackedFloat32Array = _bay_bounds(b3, court_ref_dist, yc, zc)
		spans.append(q2)
		total += q2[1] - q2[0]
	var court_w: float = total + court_gutter * 3.0
	_deck_w = court_w + 0.16
	_bay_x.resize(4)
	var cur: float = -court_w * 0.5
	for b4 in range(4):
		var q3: PackedFloat32Array = spans[b4]
		_bay_x[b4] = cur - q3[0]
		cur += (q3[1] - q3[0]) + court_gutter


func _inflate(y: float, z: float, ref: float, yc: float, zc: float) -> float:
	if ref <= 0.0:
		return 1.0
	return ref / maxf(ref - CAM_DZ * (z - zc) - CAM_DY * (y - yc), 0.5)


func _bay_bounds(bay: int, ref: float, yc: float, zc: float) -> PackedFloat32Array:
	var st: Array = STATIC[bay]
	var sx0: float = st[0]
	var sx1: float = st[1]
	var sy0: float = st[2]
	var sy1: float = st[3]
	var sz0: float = st[4]
	var sz1: float = st[5]
	var lo: float = 1.0e9
	var hi: float = -1.0e9
	for xi in range(2):
		var px: float = sx0 if xi == 0 else sx1
		for yi in range(2):
			var py: float = sy0 if yi == 0 else sy1
			for zi in range(2):
				var pz: float = sz0 if zi == 0 else sz1
				var k: float = _inflate(py, pz, ref, yc, zc)
				lo = minf(lo, px * k)
				hi = maxf(hi, px * k)
	var ylo: float = sy0
	var yhi: float = sy1
	var zlo: float = sz0
	var zhi: float = sz1
	var r: float = UNIT_R[bay]
	for v in range(3):
		var ps: PackedVector3Array = _unit_positions(bay, v)
		for p in ps:
			ylo = minf(ylo, p.y - r)
			yhi = maxf(yhi, p.y + r)
			zlo = minf(zlo, p.z - r)
			zhi = maxf(zhi, p.z + r)
			for xj in range(2):
				var qx: float = (p.x - r) if xj == 0 else (p.x + r)
				for zj in range(2):
					var qz: float = (p.z - r) if zj == 0 else (p.z + r)
					var k2: float = _inflate(p.y, qz, ref, yc, zc)
					lo = minf(lo, qx * k2)
					hi = maxf(hi, qx * k2)
	return PackedFloat32Array([lo, hi, ylo, yhi, zlo, zhi])


# ── BUILD ────────────────────────────────────────────────────────────────────
func _build() -> void:
	_layout()
	var v: int = _verdict_index()

	var court: Node3D = Node3D.new()
	court.name = "Court"
	court.rotation = Vector3(0.0, court_yaw, 0.0)
	add_child(court)

	# One deck. A floor, not a rail: it carries no mark, no tick and no datum.
	court.add_child(_box(Vector3(0.0, -0.035, 0.0), Vector3(_deck_w, 0.07, 1.04),
		_matte_mat(Color(0.09, 0.10, 0.13), 0.95)))

	for b in range(4):
		var bay: Node3D = Node3D.new()
		bay.name = BAY_NAMES[b]
		bay.position = Vector3(_bay_x[b], 0.0, 0.0)
		court.add_child(bay)
		match b:
			0:
				_bay_f_order(bay, v)
			1:
				_bay_lambda_dial(bay, v)
			2:
				_bay_phi_rate(bay, v)
			_:
				_bay_reactor(bay, v)
		_complement(bay, b)


# ── BAY A — the crystal ──────────────────────────────────────────────────────
func _bay_f_order(bay: Node3D, v: int) -> void:
	var order: float = A_ORDER[v]
	var span: float = float(A_N - 1) * A_PITCH + 0.12

	bay.add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.46, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	bay.add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.40, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	bay.add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.05, 0.6, _steel_mat(A_FRAME * 0.7)))

	# containment cage: cool glass at alpha 0.08 plus twelve glowing edges
	bay.add_child(_box(A_CENTER, Vector3(span, span, span), _glass_mat(A_CRYSTAL, 0.08)))
	_box_frame(bay, A_CENTER, span, 0.008, _glow_mat(A_FRAME, 2.0))

	# the F meter: rail plus a fill that DROPS as order rises. At frozen the fill is a
	# 25 mm stub — the bench's stated goal, three pixels tall.
	bay.add_child(_box(Vector3(-0.5, 1.0, 0.0), Vector3(0.04, 0.5, 0.04), _matte_mat(Color(0.1, 0.13, 0.2))))
	var f_val: float = 1.0 - 0.95 * order
	var fh: float = clampf(f_val, 0.02, 1.0) * 0.5
	var fmat: StandardMaterial3D = _glow_mat(Color(0.95, 0.55, 0.35), 2.2)
	fmat.emission = Color(0.95, 0.55, 0.35).lerp(A_CRYSTAL, order)
	bay.add_child(_box(Vector3(-0.5, 0.75 + fh * 0.5, 0.0), Vector3(0.05, fh, 0.05), fmat))

	# the units. The source's colour is uniform per cell (it depends only on `order`),
	# so one material is faithful — but it is scatter→crystal, which the MultiMesh path
	# has never shown (C1).
	var ps: PackedVector3Array = _unit_positions(0, v)
	var axis: Vector3 = Vector3(0.3, 1.0, 0.2).normalized()
	var umat: StandardMaterial3D = _glow_mat(A_SCATTER.lerp(A_CRYSTAL, order), 1.8)
	var edge: float = A_PITCH * 0.42
	for i in range(ps.size()):
		var ph: float = _h(i, 3, SALT_A) * TAU
		var spin: float = (1.0 - order) * ph
		var mi: MeshInstance3D = _box(Vector3.ZERO, Vector3.ONE * edge, umat)
		mi.transform = Transform3D(Basis().rotated(axis, spin), ps[i])
		bay.add_child(mi)


# ── BAY B — the dial and the field ───────────────────────────────────────────
func _bay_lambda_dial(bay: Node3D, v: int) -> void:
	var lam: float = B_LAMBDA[v]
	var life: float = _life_strength(lam)
	var noise_w: float = clampf((lam - GOLD_HI) / (1.0 - GOLD_HI), 0.0, 1.0)

	bay.add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.46, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	bay.add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.40, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	bay.add_child(_cylinder(Vector3(0.0, 0.42, 0.0), 0.05, 0.6, _steel_mat(Color(0.4, 0.5, 0.7))))

	# The dial exactly as the CODE has it, not as its comment claims (C3): the backing
	# puck and the rim torus are unrotated horizontals, the ticks / arc / needle are
	# vertical. A vertical clock intersecting a horizontal ring.
	bay.add_child(_cylinder(B_DIAL + Vector3(0.0, 0.0, -0.03), 0.26, 0.04, _matte_mat(Color(0.1, 0.13, 0.2))))
	bay.add_child(_torus(B_DIAL, 0.26, 0.02, _steel_mat(Color(0.6, 0.66, 0.8))))
	for ti in range(11):
		var frac: float = float(ti) / 10.0
		var a: float = lerp(2.356, -2.356, frac)
		var tip: Vector3 = B_DIAL + Vector3(cos(a), sin(a), 0.0) * 0.24
		var inn: Vector3 = B_DIAL + Vector3(cos(a), sin(a), 0.0) * 0.20
		bay.add_child(_cylinder_between(inn, tip, 0.006, _glow_mat(Color(0.7, 0.8, 1.0), 1.4)))
	bay.add_child(_gold_arc(B_DIAL, 0.215, GOLD_LO, GOLD_HI, _glow_mat(Color(1.0, 0.85, 0.3), 2.6)))

	# the needle: 135° at λ = 0, 27° and inside the gold band at λ = 0.4, −135° at λ = 1
	var na: float = lerp(2.356, -2.356, lam)
	var ndir: Vector3 = Vector3(cos(na), sin(na), 0.0)
	var nmat: StandardMaterial3D = _glow_mat(Color(1.0, 0.4, 0.4), 2.4)
	nmat.emission = Color(1.0, 0.4, 0.4).lerp(Color(1.0, 0.85, 0.3), life)
	var needle: MeshInstance3D = _cylinder(Vector3.ZERO, 0.008, 0.22, nmat)
	needle.transform = Transform3D(_basis_y_to(ndir), B_DIAL + ndir * 0.11)
	bay.add_child(needle)
	bay.add_child(_sphere(B_DIAL, 0.03, _steel_mat(Color(0.8, 0.85, 0.95))))

	# the field that reads the dial. Colour is uniform per cell and is the colour the
	# MultiMesh path throws away — this bay has only ever photographed WHITE (C1).
	var col: Color = B_CRYSTAL.lerp(B_LIFE, life) if lam <= GOLD_HI else B_LIFE.lerp(B_NOISE, noise_w)
	var umat: StandardMaterial3D = _glow_mat(col, 1.8)
	var ps: PackedVector3Array = _unit_positions(1, v)
	var axis: Vector3 = Vector3(0.4, 1.0, 0.2).normalized()
	var edge: float = B_PITCH * 0.46
	for i in range(ps.size()):
		var ph: float = _h(i, 3, SALT_B) * TAU
		var spin: float = noise_w * ph
		var mi: MeshInstance3D = _box(Vector3.ZERO, Vector3.ONE * edge, umat)
		mi.transform = Transform3D(Basis().rotated(axis, spin), ps[i])
		bay.add_child(mi)


# ── BAY C — the floating flame ───────────────────────────────────────────────
func _bay_phi_rate(bay: Node3D, v: int) -> void:
	var rate: float = C_RATE[v]

	bay.add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.44, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	bay.add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.38, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	bay.add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.05, 0.5, _steel_mat(Color(0.4, 0.5, 0.7))))
	# the emitter ring, at the foot of a column that starts 1.07 m above it (R6)
	bay.add_child(_torus(C_CENTER + Vector3(0.0, -C_HEIGHT * 0.5 - 0.02, 0.0),
		C_RADIUS + 0.04, 0.02, _glow_mat(C_ALIVE, 2.2)))

	# the ΔE/Δt meter
	bay.add_child(_box(Vector3(-0.46, 1.05, 0.0), Vector3(0.04, 0.55, 0.04), _matte_mat(Color(0.1, 0.13, 0.2))))
	var rh: float = clampf(rate, 0.02, 1.0) * 0.55
	var rmat: StandardMaterial3D = _glow_mat(C_ALIVE, 2.2)
	rmat.emission = C_DEAD.lerp(C_ALIVE, rate)
	bay.add_child(_box(Vector3(-0.46, (1.05 - 0.275) + rh * 0.5, 0.0), Vector3(0.05, rh, 0.05), rmat))

	# the form. THE ONLY BAY WITH A GENUINELY PER-UNIT COLOUR: dead → alive → hot runs
	# up the column with h01, and the MultiMesh path renders every one of them white.
	var ps: PackedVector3Array = _unit_positions(2, v)
	for i in range(ps.size()):
		var h01: float = float(i) / float(C_COUNT)
		var col: Color = C_DEAD.lerp(C_ALIVE.lerp(C_HOT, h01), rate)
		var mi: MeshInstance3D = _sphere(ps[i], 0.03, _glow_mat(col, 2.2))
		var sm: SphereMesh = mi.mesh as SphereMesh
		if sm != null:
			sm.radial_segments = 7
			sm.rings = 4
		bay.add_child(mi)


# ── BAY D — the reactor ──────────────────────────────────────────────────────
func _bay_reactor(bay: Node3D, v: int) -> void:
	var s: float = D_SWEEP[v]
	var alv: float = _aliveness(s)
	var col: Color = _state_color(s)

	bay.add_child(_box(Vector3(0.0, 0.30, 0.0), Vector3(0.95, 0.60, 0.55), _matte_mat(D_BODY, 0.85)))
	bay.add_child(_box(Vector3(0.0, 0.605, 0.0), Vector3(0.97, 0.02, 0.57), _steel_mat(Color(0.32, 0.34, 0.40))))
	bay.add_child(_box(Vector3(0.0, 0.01, 0.0), Vector3(1.0, 0.02, 0.60), _matte_mat(Color(0.08, 0.09, 0.12), 0.9)))

	# three dials, F / λ / φ. Their faces are HORIZONTAL (C4) and their needles turn
	# about Y, which is why they are nearly edge-on from the standpoint.
	var cf: Vector3 = Vector3(-0.32, 0.62, 0.30)
	var cl: Vector3 = Vector3(0.0, 0.62, 0.34)
	var cp: Vector3 = Vector3(0.32, 0.62, 0.30)
	_deck_dial(bay, cf, TERM_F, 1.0 - s)
	_deck_dial(bay, cl, TERM_L, s)
	_deck_dial(bay, cp, TERM_P, alv)

	bay.add_child(_cylinder_between(cf + Vector3(0.0, 0.02, 0.0),
		D_CHAMBER + Vector3(-0.12, -0.18, 0.0), 0.012, _glow_mat(TERM_F, 0.7)))
	bay.add_child(_cylinder_between(cl + Vector3(0.0, 0.02, 0.0),
		D_CHAMBER + Vector3(0.0, -0.20, 0.0), 0.012, _glow_mat(TERM_L, 0.7)))
	bay.add_child(_cylinder_between(cp + Vector3(0.0, 0.02, 0.0),
		D_CHAMBER + Vector3(0.12, -0.18, 0.0), 0.012, _glow_mat(TERM_P, 0.7)))

	bay.add_child(_cylinder(D_CHAMBER + Vector3(0.0, -0.22, 0.0), 0.10, 0.10, _steel_mat(Color(0.28, 0.30, 0.36))))
	bay.add_child(_sphere(D_CHAMBER, D_CHAMBER_R + 0.02, _glass_mat(D_GLASS, 0.13)))

	# the particles — the ONE body in the family whose palette the source actually
	# renders, because it builds individual meshes and sets material_override (:299)
	var ps: PackedVector3Array = _unit_positions(3, v)
	var pmat: StandardMaterial3D = _glow_mat(col, 0.9 + alv * 0.6)
	for i in range(ps.size()):
		bay.add_child(_sphere(ps[i], 0.016, pmat))

	# readout panel. The screen is mounted PROUD (C5): the source buries it inside the
	# slab, where it has never been visible, and this court does not copy a defect it
	# can see. The text itself is a billboard in the source and is omitted (R7).
	bay.add_child(_box(Vector3(0.0, 1.18, -0.12), Vector3(0.72, 0.30, 0.02), _matte_mat(D_PANEL, 0.4)))
	bay.add_child(_box(Vector3(0.0, 1.18, -0.106), Vector3(0.70, 0.28, 0.005),
		_glow_mat(Color(0.12, 0.18, 0.24), 0.25)))


func _deck_dial(bay: Node3D, center: Vector3, col: Color, frac: float) -> void:
	bay.add_child(_cylinder(center, D_DIAL_R, 0.02, _matte_mat(Color(0.90, 0.92, 0.96), 0.4)))
	bay.add_child(_torus(center + Vector3(0.0, 0.012, 0.0), D_DIAL_R, 0.008, _glow_mat(col, 0.9)))
	bay.add_child(_box(center + Vector3(-D_DIAL_R * 0.78, 0.018, 0.0), Vector3(0.008, 0.004, 0.016), _glow_mat(col, 0.8)))
	bay.add_child(_box(center + Vector3(0.0, 0.018, D_DIAL_R * 0.78), Vector3(0.016, 0.004, 0.008), _glow_mat(Color(1, 1, 1), 1.0)))
	bay.add_child(_box(center + Vector3(D_DIAL_R * 0.78, 0.018, 0.0), Vector3(0.008, 0.004, 0.016), _glow_mat(col, 0.8)))
	var needle: MeshInstance3D = _box(Vector3.ZERO, Vector3(0.010, 0.006, D_DIAL_R * 0.8),
		_glow_mat(Color(0.10, 0.11, 0.14), 0.2))
	# qfep_reactor_bench.gd:260-266 — sweep +70° → −70° about Y
	var ang: float = lerpf(deg_to_rad(70.0), deg_to_rad(-70.0), frac)
	needle.transform = Transform3D(Basis(Vector3.UP, ang),
		center + Vector3(0.0, 0.02, 0.0)).translated_local(Vector3(0.0, 0.0, D_DIAL_R * 0.4))
	bay.add_child(needle)


# ── COMPLEMENT ───────────────────────────────────────────────────────────────
# The family's kit, reproduced per bay from each bench's own anchors. `none` falls
# through and adds nothing at all — which is the value.
func _complement(bay: Node3D, b: int) -> void:
	match complement:
		"ghost":
			_comp_ghost(bay, b)
		"supply":
			_comp_supply(bay, b)
		"redaction":
			_comp_redaction(bay, b)
		"quorum":
			_comp_quorum(bay, b)
		_:
			pass


func _hub(b: int) -> Vector3:
	if b == 0:
		return A_CENTER + Vector3(0.0, -0.26, 0.0)            # under the crystal cage
	if b == 1:
		return B_CENTER + Vector3(0.0, -0.10, 0.0)            # under the λ field
	if b == 2:
		return C_CENTER + Vector3(0.0, -C_HEIGHT * 0.5, 0.0)  # the emitter ring
	return D_CHAMBER + Vector3(0.0, -0.10, 0.0)               # the chamber underside


func _accent(b: int) -> Color:
	if b == 0:
		return A_CRYSTAL
	if b == 1:
		return B_LIFE
	if b == 2:
		return C_ALIVE
	return D_READOUT


func _term_color(b: int, second: bool) -> Color:
	var g: String = GLYPH_B[b] if second else GLYPH_A[b]
	if g == "F":
		return TERM_F
	if g == "λ":
		return TERM_L
	if g == "φ":
		return TERM_P
	if g == "E":
		return TERM_E
	return TERM_S


## Engraved text: NOT _billboard_label. Depth-tested and non-billboard so the black
## redaction bars can actually cover it, and so LabelFramer leaves it alone.
func _comp_ink(text: String, pos: Vector3, font: int, col: Color) -> Label3D:
	var l: Label3D = Label3D.new()
	l.text = text
	l.font_size = font
	l.modulate = col
	l.outline_size = 0
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.no_depth_test = false
	l.position = pos
	return l


## GHOST — provision, unfitted. Grey and not black on purpose: all four sources carry
## the same comment saying the capture stage is near-black and a black value is an
## invisible one. This court is the test of that worry.
func _comp_ghost_one(bay: Node3D, b: int, sx: float, glyph: String) -> void:
	var cy: float = COMP_Y[b]
	var cz: float = COMP_Z[b]
	var post_mat: StandardMaterial3D = _matte_mat(Color(0.34, 0.36, 0.42), 0.85, 0.3)
	var face_mat: StandardMaterial3D = _matte_mat(Color(0.21, 0.22, 0.27), 0.95, 0.1)
	bay.add_child(_cylinder(Vector3(sx, cy + 0.15, cz), 0.05, 0.30, post_mat))
	bay.add_child(_torus(Vector3(sx, cy + 0.30, cz), 0.075, 0.016, post_mat))
	bay.add_child(_box(Vector3(sx, cy + 0.42, cz), Vector3(0.23, 0.27, 0.02), post_mat))
	bay.add_child(_box(Vector3(sx, cy + 0.42, cz + 0.016), Vector3(0.20, 0.24, 0.02), face_mat))
	bay.add_child(_comp_ink(glyph, Vector3(sx, cy + 0.42, cz + 0.035), 26, Color(0.52, 0.54, 0.60)))


func _comp_ghost(bay: Node3D, b: int) -> void:
	var x: float = COMP_X[b]
	_comp_ghost_one(bay, b, -x, GLYPH_A[b])
	_comp_ghost_one(bay, b, x, GLYPH_B[b])


## SUPPLY — the term is fed. A lit conduit rises off the deck and elbows into the hub.
func _comp_supply_one(bay: Node3D, b: int, sx: float, glyph: String, col: Color) -> void:
	var cy: float = COMP_Y[b]
	var cz: float = COMP_Z[b]
	var lit: StandardMaterial3D = _glow_mat(col, 1.6)
	bay.add_child(_torus(Vector3(sx, cy + 0.02, cz), 0.07, 0.018, _steel_mat(col.darkened(0.45))))
	bay.add_child(_cylinder(Vector3(sx, cy + 0.16, cz), 0.028, 0.28, lit))
	bay.add_child(_cylinder_between(Vector3(sx, cy + 0.28, cz), _hub(b), 0.026, lit))
	bay.add_child(_box(Vector3(sx, cy + 0.34, cz + 0.055), Vector3(0.13, 0.11, 0.015),
		_matte_mat(Color(0.87, 0.86, 0.82), 0.55)))
	bay.add_child(_comp_ink(glyph, Vector3(sx, cy + 0.34, cz + 0.07), 20, Color(0.10, 0.11, 0.15)))


func _comp_supply(bay: Node3D, b: int) -> void:
	var x: float = COMP_X[b]
	_comp_supply_one(bay, b, -x, GLYPH_A[b], _term_color(b, false))
	_comp_supply_one(bay, b, x, GLYPH_B[b], _term_color(b, true))
	# C6: the reactor's intake collar RINGS the glass at the point of entry (r 0.26,
	# tube 0.022) instead of sitting inside it as a hidden disc. `supply` is not one
	# object built four times.
	if b == 3:
		bay.add_child(_torus(_hub(b), 0.26, 0.022, _steel_mat(Color(0.55, 0.60, 0.72))))
	else:
		bay.add_child(_torus(_hub(b), 0.09, 0.02, _steel_mat(Color(0.55, 0.60, 0.72))))


## REDACTION — the bench prints what it cut. NOTE the struck terms are never
## instantiated: the else-branch adds only the bar, so the bars redact BLANK BONE.
## Drawn as the code does it, not as the docstring says.
func _comp_formula_plate(bay: Node3D, b: int, keep: int) -> void:
	var py: float = PLATE_PY[b]
	var pz: float = 0.155
	var bone: StandardMaterial3D = _matte_mat(Color(0.87, 0.86, 0.82), 0.55)
	var steel: StandardMaterial3D = _steel_mat(Color(0.42, 0.45, 0.52))
	var bar: StandardMaterial3D = _matte_mat(Color(0.05, 0.05, 0.07), 0.98)
	bay.add_child(_cylinder_between(Vector3(0.0, py, 0.03), Vector3(0.0, py, pz - 0.012), 0.02, steel))
	bay.add_child(_box(Vector3(0.0, py, pz - 0.012), Vector3(0.78, 0.26, 0.02), steel))
	bay.add_child(_box(Vector3(0.0, py, pz), Vector3(0.74, 0.22, 0.02), bone))
	bay.add_child(_comp_ink("QFE =", Vector3(-0.20, py, pz + 0.02), 13, Color(0.10, 0.11, 0.15)))
	var slot_x: PackedFloat32Array = PackedFloat32Array([-0.065, 0.055, 0.225])
	var slot_w: PackedFloat32Array = PackedFloat32Array([0.075, 0.135, 0.175])
	var slot_t: PackedStringArray = PackedStringArray(["F", "- λE", "+ φΔE"])
	for i in range(3):
		if i == keep:
			bay.add_child(_box(Vector3(slot_x[i], py, pz + 0.011),
				Vector3(slot_w[i] + 0.03, 0.15, 0.006), _glow_mat(_accent(b), 1.4)))
			bay.add_child(_comp_ink(slot_t[i], Vector3(slot_x[i], py, pz + 0.025), 13,
				Color(0.06, 0.07, 0.10)))
		else:
			bay.add_child(_box(Vector3(slot_x[i], py, pz + 0.015),
				Vector3(slot_w[i] + 0.02, 0.135, 0.012), bar))


## The reactor's plate is a DIFFERENT builder (C6): the terms it runs are UNDERLINED
## rather than boxed, there is no mounting strut, and the bars strike the two places
## the SYSTEM is named — the terms kept, their referent blacked out.
func _comp_reactor_plate(bay: Node3D) -> void:
	var py: float = PLATE_PY[3]
	var pz: float = 0.29
	var bone: StandardMaterial3D = _matte_mat(Color(0.87, 0.86, 0.82), 0.55)
	var steel: StandardMaterial3D = _steel_mat(Color(0.42, 0.45, 0.52))
	var bar: StandardMaterial3D = _matte_mat(Color(0.05, 0.05, 0.07), 0.98)
	var ink: Color = Color(0.10, 0.11, 0.15)
	bay.add_child(_box(Vector3(0.0, py, pz - 0.012), Vector3(0.92, 0.28, 0.02), steel))
	bay.add_child(_box(Vector3(0.0, py, pz), Vector3(0.88, 0.24, 0.02), bone))
	bay.add_child(_comp_ink("QFE = F - λE", Vector3(-0.20, py, pz + 0.02), 13, ink))
	bay.add_child(_comp_ink("+ φΔE", Vector3(0.185, py, pz + 0.02), 13, ink))
	var lit: StandardMaterial3D = _glow_mat(D_READOUT, 1.4)
	bay.add_child(_box(Vector3(-0.20, py - 0.075, pz + 0.011), Vector3(0.40, 0.012, 0.006), lit))
	bay.add_child(_box(Vector3(0.185, py - 0.075, pz + 0.011), Vector3(0.17, 0.012, 0.006), lit))
	bay.add_child(_box(Vector3(0.05, py, pz + 0.015), Vector3(0.12, 0.15, 0.012), bar))
	bay.add_child(_box(Vector3(0.355, py, pz + 0.015), Vector3(0.19, 0.15, 0.012), bar))


func _comp_redaction(bay: Node3D, b: int) -> void:
	var keep: int = PLATE_KEEP[b]
	if keep < 0:
		_comp_reactor_plate(bay)
	else:
		_comp_formula_plate(bay, b, keep)


## QUORUM — terms in session. Lit satellite dials stand with the phenomenon, each tied
## back into the hub: the bench admits it cannot mean anything alone.
func _comp_quorum_one(bay: Node3D, b: int, sx: float, glyph: String, col: Color) -> void:
	var cy: float = COMP_Y[b]
	var cz: float = COMP_Z[b]
	var steel: StandardMaterial3D = _steel_mat(Color(0.55, 0.60, 0.72))
	bay.add_child(_cylinder(Vector3(sx, cy + 0.24, cz), 0.035, 0.48, steel))
	bay.add_child(_box(Vector3(sx, cy + 0.50, cz), Vector3(0.20, 0.20, 0.015),
		_matte_mat(Color(0.88, 0.90, 0.94), 0.4)))
	var ring: MeshInstance3D = _torus(Vector3(sx, cy + 0.50, cz + 0.012), 0.115, 0.014, _glow_mat(col, 2.0))
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	bay.add_child(ring)
	var needle: MeshInstance3D = _box(Vector3(sx, cy + 0.548, cz + 0.03),
		Vector3(0.014, 0.085, 0.012), _glow_mat(Color(1.0, 0.85, 0.40), 2.2))
	needle.rotation_degrees = Vector3(0.0, 0.0, 22.0)
	bay.add_child(needle)
	bay.add_child(_comp_ink(glyph, Vector3(sx, cy + 0.455, cz + 0.03), 20, Color(0.10, 0.11, 0.15)))
	bay.add_child(_cylinder_between(Vector3(sx, cy + 0.50, cz),
		_hub(b) + Vector3(0.0, -0.02, 0.0), 0.014, _glow_mat(col, 1.2)))


func _comp_quorum(bay: Node3D, b: int) -> void:
	var x: float = COMP_X[b]
	_comp_quorum_one(bay, b, -x, GLYPH_A[b], _term_color(b, false))
	_comp_quorum_one(bay, b, x, GLYPH_B[b], _term_color(b, true))


# ── HELPERS ──────────────────────────────────────────────────────────────────
func _box_frame(bay: Node3D, center: Vector3, size: float, r: float, mat: Material) -> void:
	var hh: float = size * 0.5
	var corners: Array = [
		Vector3(-hh, -hh, -hh), Vector3(hh, -hh, -hh), Vector3(hh, -hh, hh), Vector3(-hh, -hh, hh),
		Vector3(-hh, hh, -hh), Vector3(hh, hh, -hh), Vector3(hh, hh, hh), Vector3(-hh, hh, hh)]
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	for e in edges:
		var a: Vector3 = center + corners[e[0]]
		var b: Vector3 = center + corners[e[1]]
		bay.add_child(_cylinder_between(a, b, r, mat))


## lambda_dial_bench.gd:394-423 — ONE ImmediateMesh, not a row of boxes (C8).
func _gold_arc(center: Vector3, radius: float, frac_lo: float, frac_hi: float, mat: Material) -> MeshInstance3D:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	var inner: float = radius - 0.03
	var outer: float = radius + 0.03
	var segs: int = 16
	var a_lo: float = lerp(2.356, -2.356, frac_lo)
	var a_hi: float = lerp(2.356, -2.356, frac_hi)
	for s in range(segs):
		var t0: float = float(s) / float(segs)
		var t1: float = float(s + 1) / float(segs)
		var aa: float = lerp(a_lo, a_hi, t0)
		var ab: float = lerp(a_lo, a_hi, t1)
		var i0: Vector3 = Vector3(cos(aa) * inner, sin(aa) * inner, 0.0)
		var o0: Vector3 = Vector3(cos(aa) * outer, sin(aa) * outer, 0.0)
		var i1: Vector3 = Vector3(cos(ab) * inner, sin(ab) * inner, 0.0)
		var o1: Vector3 = Vector3(cos(ab) * outer, sin(ab) * outer, 0.0)
		im.surface_add_vertex(i0)
		im.surface_add_vertex(o0)
		im.surface_add_vertex(o1)
		im.surface_add_vertex(i0)
		im.surface_add_vertex(o1)
		im.surface_add_vertex(i1)
	im.surface_end()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = im
	mi.position = center + Vector3(0.0, 0.0, 0.01)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
