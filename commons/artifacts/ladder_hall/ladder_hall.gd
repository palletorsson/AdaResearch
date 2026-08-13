extends Node3D
class_name LadderHall

## LADDER HALL — a measuring rack that REPORTS ON four fractal benches. It does not
## reproduce them, and anyone reading the tile as a picture of four fractals will be
## wrong. There is no gasket here, no arcade, no escape-time panel. Four bays stand in
## one row on one plinth under one datum rail, and each bay holds a stack of plain slats
## whose HEIGHTS are two order statistics read off one of the four benches' own code.
##
## The refusal to draw the figures is arithmetic, not taste, and the numbers are in
## ELEMENT BUDGET below: at this hall's frame width a faithful Sierpinski at depth 6 and
## one at depth 3 would be the same photograph — a grey patch of the right density.
##
##
## ── THE FOUR MEMBERS, AND WHAT EACH ONE ACTUALLY CONSTRUCTS ───────────────────
##
## A  fractal_arch_bench   SUBSTITUTION. `_arch(a,b,h,d)` draws one half-ellipse over an
##                         interval, then replaces the interval with two copies of itself
##                         at half width and half rise (gd:141-168). Cantor-style
##                         bisection of a SEGMENT. 2^d - 1 arches, 11 cylinders each.
## B  sierpinski_bench     REMOVAL. `_collect` recurses into three corner sub-triangles
##                         and never into the middle one; only LEAVES are instanced
##                         (gd:103-115). The omission is the construction. 3^d leaves.
## C  mandelbrot_bench     ESCAPE-TIME on the PARAMETER plane. A fixed 72x72 lattice of
##                         5184 boxes; each box is a sample c, tested by z <- z^2 + c
##                         from z = 0. The escape count drives COLOUR only (gd:118-162).
## D  julia_bench          ESCAPE-TIME on the DYNAMICAL plane. The same 5184 boxes, but
##                         each box is a starting z0 and c is held fixed (gd:140-155).
##                         One line of difference from C, and a different kind of object.
##
##
## ── WHERE `ladder` AGREES ACROSS THE FOUR ─────────────────────────────────────
##
## The VALUE LIST is identical character for character in all four files
## (fractal_arch_bench.gd:56, sierpinski_bench.gd:56, mandelbrot_bench.gd:47,
## julia_bench.gd:48) and in all four registry blocks. This hall reuses it verbatim.
## The ROLES agree too:
##   figure   the legacy build, untouched; the guard `if ladder != "figure"` falls through
##   series   the whole climb tiled in SPACE — which is the only reason any of this is
##            legal for a still: an iteration count laid out sideways is visible, played
##            in time it is not
##   seed     the first rung at full size — the rule stated once
##   relief   every rung as a complete figure on its own z plane, dark at the back
##   section  ONE figure cut across the ladder, PLUS a lit rail on every seam. All four
##            benches draw a lit MeshInstance3D on `section` and on nothing else (arch's
##            plumb rod, sierpinski's seam bar, mandelbrot's and julia's five hairlines).
##            That is the single strongest thing the four agree on, and it is why the
##            seam post here exists at `section` and at no other value.
##
##
## ── WHERE `ladder` DISAGREES, AND WHY THE ROW IS RAGGED ───────────────────────
##
## 1. THE RUNG COUNT IS NOT SHARED. `_rungs()` is four different functions.
##    A: range(1, depth+1) = [1,2,3,4].   B: the same shape at depth 5 = [1,2,3,4,5].
##    C and D: fractional budgets maxi(int(round(70*f)),2) for f in [.06,.09,.14,.22,
##    .45,1.0] = [4,6,10,15,32,70], six rungs. mandelbrot_bench.gd:23-27 claims the four
##    "duplicate one another's helper code verbatim"; the value LIST does, `_rungs()`
##    does not. So this row is 4 / 5 / 6 / 6 slats at `series` and `relief`. The
##    raggedness is a fact about the family, not a layout error.
##
## 2. WHAT A RUNG *IS* SPLITS THE FAMILY IN HALF. For A and B a rung is a recursion
##    DEPTH, decided before any geometry exists, and every level is a finished figure.
##    For C and D it is a per-pixel RESULT: the mesh count is 5184 at 4 iterations and
##    5184 at 70. Iteration MULTIPLIES elements on one side of the family and REFINES a
##    raster of constant size on the other. That split is the whole reason `reckoning`
##    has two values (see below).
##
## 3. `section` CUTS DIFFERENTLY. A cuts left/right haunches at two depths (3 pieces).
##    B cuts three sub-triangles at depths 1 / 0 / 5 (3 pieces). C and D cut six vertical
##    BANDS of 12 columns (6 pieces).
##
## 4. `seed` IS THE CLEANEST DISAGREEMENT IN THE FAMILY. A's seed is one arch FATTER
##    than its figure (rscale 3.0 against 1.0) — 11 cylinders against 165. B's seed is
##    three big plates against 243 specks. C's and D's seed is THE SAME 5184 BOXES,
##    recoloured. The seed of an escape-time test is not a smaller object; it is the same
##    object asked a shorter question. That is why bays C and D carry the only two zero
##    cells in this hall's whole matrix and bays A and B cannot.
##
## 5. `relief` is the only value where C's and D's part counts move at all, because
##    `_shell` emits INTERIORS ONLY (mandelbrot_bench.gd:263, julia_bench.gd:293).
##
##
## ── WHAT THIS ARTIFACT ARGUES ─────────────────────────────────────────────────
##
## A recursive construction makes two separable claims at every rung and BOTH survive a
## still: how much of its own field it still COVERS, and how many PIECES it is in. The
## four benches answer them in different directions, and that is the finding.
##
##   MASS  (covered fraction, each bay normalised by its own ceiling)
##     A rises   0.0975 -> 0.4105 across relief d=1..4: substitution ADDS material.
##     B falls   by exactly 3/4 a rung, forever: removal is multiplication by 3/4.
##     C falls   0.3665 -> 0.1725 toward a POSITIVE limit: the Mandelbrot set has area.
##     D falls   0.2689 -> 0.0664 toward ZERO. c = -0.4+0.6i is OUTSIDE M — I re-ran the
##               orbit of 0 and it escapes at iteration 25 — so the true filled Julia set
##               is a Cantor dust of measure zero. D's ladder converges on NOTHING.
##
##   COUNT (log2(parts+1) / log2(5185), ONE shared normaliser, 5184 the family maximum)
##     A rises   11 / 33 / 77 / 165
##     B rises   3 / 9 / 27 / 81 / 243
##     C and D   ARE FLAT LINES. 5184 at figure, 5184 at seed, 900 per series tile, 864
##               per section band. Only `relief` moves.
##
## Counted by parts, half the family is not climbing at all. Counted by measure, all four
## move. The two readings disagree about which benches are climbing — and about the
## DIRECTION for A, which is the only bay where mass rises with the rung.
##
## THE PINNING, structural rather than statistical, in both directions:
##   `ladder` ALONE fixes how many slats, their LENGTHS, their Z, and whether the seam
##   post exists. Those four are byte-identical between mass and count at every ladder
##   value. `reckoning` ALONE fixes the slat HEIGHTS and touches nothing else.
##   mass cannot read count: every rung is EXACTLY ONE slat in both reckonings, so
##   headcount carries literally zero signal in mass. count cannot read mass: every slat
##   is the same size, so covered fraction carries literally zero signal in count. The
##   two quantities come from disjoint derivations — MEASURE from a rasterised or counted
##   coverage test, PARTS from instantiation counts — with no arithmetic path between.
##
## THE WORD `reckoning` is reused character for character from grain_block.gd:104,
## `@export_enum("none", "mass", "void", "count")` — the corpus's only prior use, where
## `mass` is a register filled with MATTER and `count` the same register filled with
## PIECES. Two of its four, in its own order. `none` is refused because it draws no
## register at all and half this axis would publish blank; `void` is refused because it
## draws what the division REMOVED, which does not exist for an escape-time test — three
## of four bays have no such quantity, so `void` would be a refusal in three bays out of
## four rather than a reading.
##
##
## ── LAW 1: FIVE CORRECTIONS AND ONE WITHDRAWAL. THE CODE WON EVERY TIME ───────
##
## C1. THE ARCH COVERAGE WAS MEASURED WITH THE WRONG CAP AND IT MOVES BAY A's WHOLE MASS
##     COLUMN. The design brief rasterised the arch tubes as capsules (round caps).
##     `_cylinder_between` builds a CylinderMesh, whose silhouette viewed perpendicular
##     to its axis is a RECTANGLE — flat caps. Re-rastered flat on a 900 grid (converged:
##     a 1600 grid agrees to 1e-4), bay A's relief column is 0.0975/0.1994/0.3070/0.4105
##     against the brief's 0.0980/0.2016/0.3121/0.4207, and the bay ceiling is 0.820007
##     against 0.855458. Every bay-A mass slat here is up to 0.030 m (0.8 px) off where
##     the brief put it. The flat numbers are the ones in MEASURE below.
##
## C2. THE MANDELBROT SECTION BANDS. The bench report gives band 5 as "392 vs 392". Band
##     5's interior at its own budget of 70 is 38 cells of 864, not 392; the 392 is band
##     4's figure transcribed one row down. Confirmed: 28/114/190/362/404/38.
##     THE BRIEF'S CORRECTION IS RIGHT AND ITS CHECK IS NOT — it says "mine sum to
##     exactly 894"; they sum to 1136, because each band is evaluated at its OWN budget.
##     The sum that must come to 894 is the per-band count at the UNIFORM budget of 70,
##     0+16+126+322+392+38, and that is what makes the correction stand.
##
## C3. julia_bench's six-value declaration IS ALREADY FIXED. The brief and two bench
##     reports flag registry/fractals.json as declaring `ladder` with "figure" twice.
##     HEAD declares five, in family order; commit c00e666f0 removed the duplicate. All
##     four benches now agree with their code. Nothing to do.
##
## C4. THE BRIEF's "tallest slats differ by 0.401215 m" NAMES THE WRONG SLATS. In count,
##     bay C's and bay D's relief columns diverge most at the LAST rung (k=5, v 0.7946 vs
##     0.6832 = 0.4012 m), not the tallest, which is k=0 (0.8827 vs 0.8465 = 0.1303 m).
##     The number and the 12.05 px are right; the label is not.
##
## C5. THE BRIEF's FUSION TABLE CONTRADICTS ITSELF AT ONE CELL. It gives "D series 2 of
##     6" and "D relief 4 of 6" under mass — but bay D's series and relief carry the SAME
##     height list in mass, so they must resolve alike. Both are 4 of 6.
##
## C6. NOT A CORRECTION — A WITHDRAWN ONE, KEPT BECAUSE IT IS THE MISTAKE THIS ARTIFACT
##     IS ABOUT. The brief's "PROJECTED SUBJECT WIDTH = 58.8% of the frame" is derived
##     orthographically (5.0866 / 8.6765 = 58.6%). Projecting the union AABB's CORNERS
##     through the real perspective camera gives 469.3 of 760 px = 61.8%, and I wrote that
##     down as a correction before rendering anything. Rendered, the ten variants measure
##     439 to 446 px = 57.8% to 58.7%. The brief was right and the corner projection was
##     wrong, because the corners of this row's bounding box are EMPTY — which is Law 11's
##     whole point, arriving as a fact about my own arithmetic. LAW 11, stated plainly:
##     the union box is 67.4% of frame width in world units and 58% projected, while the
##     marks-only subject share swings from about 5% at figure to about 33% at section. A
##     row of four separated bays leaves most of its bounding volume empty BY
##     CONSTRUCTION — the empty travel above and below every slat IS the measuring scale —
##     so that swing is the axis working and is not a reason to crop in.
##
## Everything else in the four bench reports reproduced exactly: the mandelbrot interiors
## 1900/1450/1174/1042/936/894, the julia interiors 1394/1160/992/904/686/344, the julia
## section bands 55/198/302/280/109/10, sierpinski's exact (3/4)^d, and the arch's
## 11/33/77/165. Two things this hall does NOT inherit: the claim that the arch's big
## span "stands on" half-arches (all 15 arches spring from ONE baseline — the recursion
## bisects the segment, it does not stack), and the claim that muting is what keeps the
## five values framing at one distance (those benches' bodies are MultiMeshInstance3D and
## were never in the capture AABB in the first place).
##
##
## ── THE GAUGE. LAW 7, PER BAY, THROUGH THE REAL PERSPECTIVE CAMERA ────────────
##
## The row lies 0.56 aligned with the view axis, so the four bays sit at four different
## depths and each has its own pixel scale. One number for the row would be a number for
## a point where this artifact builds nothing.
##
## Measured off a rendered raster of all ten variants, cropped to the subject bbox and
## resized 160x160 by the critic's own arithmetic — not off the orthographic basis, which
## is legitimate for a width RATIO and is not a pixel scale.
##
##   bay             depth m   slat len px  slat thickness px  travel px  seam post px
##   A_arch           15.579      19.32          10.70            96.59    8.77 x 107.9
##   B_sierpinski     14.653      21.84          11.33           102.30    9.58 x 114.3
##   C_mandelbrot     13.727      24.88          12.04           108.74   10.52 x 121.4
##   D_julia          12.800      28.62          12.84           116.03   11.65 x 129.4
##
## Depth spread 1.217x. WORST BAY IS A, THE FARTHEST, and its smallest mark is the slat's
## SCREEN THICKNESS at 10.70 px, clearing Law 10's floor by 0.70 px. Thickness is measured
## as what a VERTICAL move sweeps at fixed screen-x, not as the slat's bbox: a 0.900 m
## slat rakes 0.149373 * 0.900 = 0.134 m of screen-y, so its bbox spans about 15 px while
## the mark is 10.70. Sizing off the bbox would ship a 10.7 px mark reported as 15 — the
## same class of error that cost the last wave a repair.
##
## Bay-to-bay daylight measures 11.35 px at the A|B gap, the tightest of the three.
## The 2D subject bbox drifts 1.59% across the ten variants (439 to 446 px of 760), because
## a v = 1 slat at the near end of the row projects marginally wider than the plinth. The
## 3D capture AABB — the thing that actually sets the camera distance — is byte-identical
## in all ten, verified box by box, because the pads are exactly as wide as the widest
## slat and the plinth and rail hold y and z alone. The critic unions the pair's boxes
## before it crops, so neither drift can bias a diff.
##
## CONSEQUENCE, named in advance: the resolvable value step is dv = thickness / travel =
## 0.1108 AT EVERY BAY — an invariant of THICK/TRAVEL that framing cannot move. THE RACK
## HAS ABOUT NINE DISTINGUISHABLE LEVELS, and a reader recovers an order of magnitude
## from the count reading, never a part count. A linear tally is impossible: 13 bits at
## the 10 px floor need 226 px in a 160 px frame.
##
##
## ── LAW 8: DAYLIGHT, AT THE WIDEST VARIANT OF BOTH AXES ───────────────────────
##
## Camera right X = (0.813878, 0, -0.581035), read off the harness's own look_at, so a
## box of half-extents (hx, hy, hz) has screen-x half = 0.813878*hx + 0.581035*hz.
##   relief slat 0  (len 0.900, |z| 0.075, depth 0.160)   0.456306 m   <- WIDEST TENANT
##   bay pad        (0.900 x 0.200)                       0.424349 m
##   flat slat 0    (len 0.900, z 0, depth 0.160)         0.412728 m
##   seam post      (0.320 x 0.100 at z -0.220)           0.287100 m
## THE WIDEST TENANT IS A MARK, NOT THE FURNITURE — deliberately, and it is why the pad
## was cut to 0.900 x 0.200. Law 8 warns the widest tenant is usually the plinth pad.
##   bay centres on screen  1.650 * 0.813878 = 1.342899 m
##   DAYLIGHT               1.342899 - 2*0.456306 = 0.430287 m = 11.35 crop px at A|B
##   minimum legal pitch    2*0.456306 / 0.813878 = 1.121312 ; 1.650 is 1.471x that.
## RELIEF_DZ sets the widest tenant and is the constant most at risk: raising it from
## 0.030 to 0.060 puts the tenant at 0.474 m and forces the pitch to 1.72.
##
##
## ── THE DIVIDERS, AND THE REFUSAL OF FULL-HEIGHT ONES ─────────────────────────
##
## Three kerb fins stand in the daylight at x = -1.650 / 0.000 / +1.650, 0.140 x 0.260 x
## 0.240, topping out at y 0.260 — 0.0442 m BELOW the lowest slat any variant can build
## (bay D, section, mass, rung 5, bottom 0.3042). They divide the row on the ground and
## are categorically incapable of standing in front of a mark. In the DNA still they are
## about 6.7 px wide and 7 px tall; at 1:1 in a map they are knee-high and obvious.
##
## FULL-HEIGHT DIVIDERS ARE ARITHMETICALLY FORECLOSED, and the number is why the design
## refused them rather than a preference. Total daylight is 11.35 px. A divider that
## READS (Law 10's 10 px) and leaves 10 px of daylight on each side needs 1.1393 m of
## screen daylight, hence PITCH 2.5212, hence a row 8.4636 m wide, hence a frame 11.278 m
## wide against this one's 8.6765 — every mark shrinks by 0.769 and bay A's slat
## thickness falls to 8.19 px, UNDER Law 10's floor. A full-height divider costs either
## Law 8 or Law 10; there is no pitch at which it costs neither.
##
##
## ── LAW 9: THE Z STACK. NOTHING OPAQUE SITS IN FRONT OF A MARK ────────────────
##
##   seam post                  -0.270 .. -0.170   only at `section`, STRICTLY BEHIND
##   kerb dividers              -0.120 .. +0.120   but y <= 0.260, below every slat, and
##                                                 0.750 m away in x from any bay
##   plinth and pads            -0.280 .. +0.280   but y <= 0.180, below every slat
##   flat slats (slat k)        -0.080+0.002k .. +0.080-0.002k
##   relief slat 0  len 0.900   -0.1550 .. +0.0050
##   relief slat 5  len 0.550   +0.0050 .. +0.1450
##   datum rail                 -0.050 .. +0.050   at y 4.290, over a v=1 slat's 4.180 top
##
## NO GLASS, NO BEZEL, NO CASE, NO FRAME. operations_gallery built its bezel as one solid
## 24 mm slab enclosing the panel face and every mark its axis drew; four values were four
## photographs of one slab and every gate was green.
##
## THE ONE PLACE A MARK COULD STAND IN FRONT OF ANOTHER IS `relief`, AND IT IS NESTED SO
## IT CANNOT: screen-x shift per z step is 0.581035*0.030 = 0.017431 m, while the screen-x
## half-width shrinks 0.813878*0.035 + 0.581035*0.002 = 0.029648 m per step. 0.017431 <
## 0.029648, so every nearer slat sits STRICTLY INSIDE the previous one's screen-x span
## and no slat is ever fully hidden. At EQUAL heights the farther slat still shows
## 0.047079 m (1.36 px) on its right and 0.012217 m (0.35 px) on its left; at heights more
## than one slat thickness apart there is no occlusion at all. That sliver is deliberate,
## and it is the sources' own behaviour rather than a compromise: all four benches
## build relief as solid nested plates that hide one another, and all four of their relief
## z-steps measure under 1 px after the critic's downsample — THE DEPTH IS ALREADY
## INVISIBLE IN THE SOURCE. Relief here is carried by the nested TAPER (slat 5 is 0.550 m
## against slat 0's 0.900), not by the rake. A rake deep enough to separate six slats
## would need RELIEF_DZ 0.47, a 2.35 m fan and a row 9.3 m wide, costing 22% of every
## mark's pixel size.
##
## SLATS NEST IN ALL THREE AXES ON PURPOSE (length -0.012k, thickness -0.002k, depth
## -0.004k), so no two ever share a face plane. Coplanar faces are z-fighting speckle,
## i.e. a NON-DETERMINISTIC still, which cost pressure_yard a pass. The nesting also buys
## the right failure mode: two slats at equal value photograph as ONE box, because the
## smaller is wholly inside the larger — a fused fan is a rack of one mark, and that is
## the correct picture of a constant.
##
##
## ── LAW 12: ELEMENT BUDGET. WORST VARIANT 31 MeshInstance3D BoxMesh, 0.97% ────
##
##   section: 1 plinth + 1 rail + 4 pads + 3 kerbs + 18 slats + 4 posts  = 31
##   series / relief: 2 + 4 + 3 + 21 slats                               = 30
##   figure / seed:   2 + 4 + 3 + 4 slats                                = 13
## No MultiMeshInstance3D anywhere, so the capture AABB sees every mark and no layers = 0
## anchor is needed. A faithful reproduction was priced before the cap was chosen: at
## `relief` the four benches together instantiate 286 + 363 + 7396 + 5480 = 13525 elements,
## 4.23x the budget; cutting to fit leaves 1275 per escape-time bay, 212 cells a panel,
## a grid of 14 against the source's 72, and a cell that projects to 1.6 px — under the
## floor. There is no depth at which drawing the fractals answers anything here.
##
## WHAT THE CAP COSTS, plainly, because the sieve's second question deserves a number and
## not a shrug: the tile does not show what a Sierpinski gasket looks like, and a viewer
## cannot verify from the picture that bay B is a removal at all. What is foreclosed is
## the SIGHT of the four figures and with it any reading of WHERE in the plane each
## construction acts — two order statistics cannot show that the Mandelbrot's interior is
## a cardioid and the Julia's a dust, only that one converges to 17.2% and the other to
## 6.6%. What is bought is the one reading the gauge permits: four construction
## principles compared at the same pixel scale under one word.
##
##
## ── PREDICTED DEGENERACY, WRITTEN BEFORE THE SHUTTER ──────────────────────────
##
## CLOSEST PAIR: figure/count vs seed/count. In `count`, bays C and D are the SAME
## PICTURE at those two values and bays A and B cannot be — the seed of a Sierpinski is a
## triangle you remove from (3 leaves against 243, a 48.9 px move at bay B); the seed of a
## Mandelbrot is a formula asked of a plane where nothing is built at all (5184 against
## 5184, zero). Bay A moves 29.5 px, bay B 48.9 px, bays C and D move nothing. An
## independent flat raster of all ten variants through this camera, cropped and resized by
## the critic's own arithmetic, ranks that pair quietest and series/count vs relief/count
## second — the same two the brief named. It puts the magnitude at 16.9%, far above the
## brief's 4.457%, which is quoted here because a prediction is a FLOOR: if the sweep
## returns BELOW 4.457% on that pair, stop, because the only artifact in this corpus ever
## to land under its own prediction was the only one that was broken.
##
## SIX EXACT ZEROS ARE DECLARED, and every one is checkable on a bay crop:
##   2 within-bay of 80 ladder-pair cells — bay C and bay D, count, figure vs seed.
##   4 cross-bay of 10 — C vs D in count at figure, seed, series and section, congruent
##   to the last bit because two escape-time tests instantiate the same raster whatever
##   they are asked. The fifth, relief, must NOT be: 0.4012 m = 12.05 px apart.
## Fourteen heights agreeing exactly across two separately-written files (353 lines and
## 381) cannot come out right by luck. If any predicted-zero cell measures focus > 2%,
## that is not a finding about `ladder` — it is proof the rig is not deterministic, and
## it voids every other number in the pass.
##
## MARK COUNTS, 40 declared integers, "how many distinct bars this bay column shows":
##   mass  figure  A1 B1 C1 D1   series A4 B3 C3 D4   seed A1 B1 C1 D1
##         relief  A4 B3 C3 D4   section A3 B3 C4 D5
##   count figure  A1 B1 C1 D1   series A2 B4 C1 D1   seed A1 B1 C1 D1
##         relief  A2 B4 C1 D1   section A2 B2 C1 D1
## Those C and D ones are the finding, not a fault: counted by parts, an escape-time test
## photographs as ONE mark where the removal bench shows four.
##
##
## ── WHAT COULD STILL GO WRONG ─────────────────────────────────────────────────
##
## R1. PER-BAY CEILINGS CAN MANUFACTURE A COINCIDENCE. In `mass`, C's and D's seed slats
##     land 1.6 px apart (0.7838 vs 0.7693) purely because 0.366512/0.467593 happens to
##     sit near 0.268904/0.349537. That is a normalisation accident and must never be
##     reported as an equality. Every equality declared above is in `count`, where the
##     normaliser is ONE shared constant and equality means the part counts are equal.
##
## R2. BAY C'S COUNT COLUMN IS NEARLY INERT ACROSS `ladder` BY DESIGN: figure = seed at
##     1.0000, series 0.7954, section 0.7906 — 0.46 px apart — and relief a fused block
##     spanning 0.7946..0.8827. Four of its five values sit within 9 px. THE SEAM POST IS
##     WHAT SEPARATES series FROM section THERE. It is load-bearing and is not furniture;
##     narrow it and that pair goes twin. At the worst bay its 8.77 px width is under Law
##     10's blob floor, which is why it is sized as a LINE — 8.77 x 107.9 = 947 contiguous
##     px, 3.70% of the crop — and quoted as one. A narrower post would be nothing.
##
## R3. SERIES AND RELIEF SHARE THEIR HEIGHT LIST IN SIX OF EIGHT BAY-BY-RECKONING
##     COLUMNS (all of B, C, D under mass; A and B under count), because both draw the
##     same rung set. In those six the pair is carried ENTIRELY by relief's z fan and
##     taper, not by any number. That is intended — relief is "the same rungs,
##     un-flattened" — but it is why series/relief is the second-quietest pair and why
##     RELIEF_LEN_K, not RELIEF_DZ, is the constant that keeps it alive.
##
## R4. THE MARGINS ARE THIN. Worst-bay slat 10.70 px against a 10 px floor; daylight
##     11.35 px; relief's far-slat sliver 1.36 px. Dropping dna.framing below about 0.55,
##     raising RELIEF_DZ above 0.030, or lengthening TRAVEL past 3.60 breaks one of the
##     three, and TRAVEL trades directly against dv.
##
## R5. BAY A'S MEASURE IS THE ONLY ONE THAT HAD TO BE RASTERISED rather than counted. A
##     different field convention moves its entire mass column — see C1, where one moved
##     it. It is also the only bay whose measure depends on the ladder value's own tube
##     scaling: series at d=4 covers 82.0% of its box while relief at d=4 covers 41.1%,
##     because the series bay is a 27.57% scale copy carrying tubes at 75%. That is the
##     code, and it is a real finding, but it is the softest number in the row.
##
## R6. LAWS 4 AND 5. Three of the four sources animate (arch sways at sin(t*0.4)*0.06,
##     sierpinski at sin(t*0.4)*0.05, julia rebuilds its whole field every frame from a
##     drifting c) and all four call `_rng.randomize()` as dead code. THIS FILE HAS NO
##     _process, NO timer, NO signal, NO clock read and NO RandomNumberGenerator in it at
##     all. Every position is arithmetic over constants derived from the four benches.
##     One consequence worth naming: julia_bench's own `figure` is not reproducible from
##     a still (animate_c defaults true and at t=0 the drift moves c to -0.40+0.68i, where
##     the 72x72 grid yields ZERO body cells). Bay D's numbers here are taken at the
##     BUILD-TIME c = -0.40+0.60i and must not be captioned as "what julia_bench
##     photographs".

# ── AXES ──────────────────────────────────────────────────────────────────────
# DECLARED ORDER IS LOAD BEARING. build_dna_gallery sweeps the first two axes as a
# matrix and trims values from the END of the LATER axis to fit the cap; an axis trimmed
# below 2 values is DROPPED, not shortened. `ladder` (5) must therefore lead `reckoning`
# (2). 5 x 2 = 10 fits the cap 16 whole, so nothing is ever trimmed.

## Which rungs of the four benches' own ladders this rack reports, and how they are
## arranged. Reused character for character from all four members.
@export_enum("figure", "series", "seed", "relief", "section") var ladder: String = "series"

## What each rung is reckoned against. `mass` is how much of its own field the
## construction still covers; `count` is how many pieces it is in. See the header for
## why `none` and `void`, the other two words grain_block declares, are refused.
@export_enum("mass", "count") var reckoning: String = "mass"

## Gates emission on the seam post and the slat tint lift. Not an axis.
@export var emissive: bool = true

const LADDERS: PackedStringArray = ["figure", "series", "seed", "relief", "section"]
const RECKONINGS: PackedStringArray = ["mass", "count"]

# ── THE DERIVED TABLES ────────────────────────────────────────────────────────
# Indexed [bay][ladder], bays A B C D, ladders in LADDERS order. Every number was
# recomputed from the four benches' own code, not transcribed from any report.
#
# MEASURE — covered fraction of that rung's own field.
#   A rasterised flat-capped on a 900 grid over the arch's span x rise rectangle, jamb
#     stubs (which hang to y = -0.21) outside it. Converged: a 1600 grid agrees to 1e-4.
#   B closed form: 0.86*0.74*edge^2*3^d over the triangle = 1.469703 * (3/4)^d, exact and
#     scale-free, which is why section's uncut third (d=0) is the bay ceiling.
#   C, D interior cells / 5184 on the benches' own 72x72 lattices; section per band / 864.
const MEASURE: Array = [
	[[0.462565], [0.271901, 0.508464, 0.716185, 0.820007], [0.259815], [0.097494, 0.199427, 0.307020, 0.410506], [0.152281, 0.278593, 0.586494]],
	[[0.348767], [1.102277, 0.826708, 0.620031, 0.465023, 0.348767], [1.102277], [1.102277, 0.826708, 0.620031, 0.465023, 0.348767], [1.102277, 1.469703, 0.348767]],
	[[0.172454], [0.366512, 0.279707, 0.226466, 0.201003, 0.180556, 0.172454], [0.366512], [0.366512, 0.279707, 0.226466, 0.201003, 0.180556, 0.172454], [0.032407, 0.131944, 0.219907, 0.418981, 0.467593, 0.043981]],
	[[0.066358], [0.268904, 0.223765, 0.191358, 0.174383, 0.132330, 0.066358], [0.268904], [0.268904, 0.223765, 0.191358, 0.174383, 0.132330, 0.066358], [0.063657, 0.229167, 0.349537, 0.324074, 0.126157, 0.011574]],
]

# PARTS — how many pieces the bench instantiates for that rung.
#   A 11 cylinders per arch (9 polyline segments + 2 jamb stubs) x (2^d - 1) arches.
#   B 3^d leaves; section's middle third is d=0, which is ONE plate.
#   C, D 5184 boxes at every budget; 900 per series tile, 864 per section band. Only
#     relief moves, because _shell emits interiors only.
const PARTS: Array = [
	[[165], [11, 33, 77, 165], [11], [11, 33, 77, 165], [11, 11, 77]],
	[[243], [3, 9, 27, 81, 243], [3], [3, 9, 27, 81, 243], [3, 1, 243]],
	[[5184], [900, 900, 900, 900, 900, 900], [5184], [1900, 1450, 1174, 1042, 936, 894], [864, 864, 864, 864, 864, 864]],
	[[5184], [900, 900, 900, 900, 900, 900], [5184], [1394, 1160, 992, 904, 686, 344], [864, 864, 864, 864, 864, 864]],
]

# Each bay's own ceiling: the max measure over every rung THAT BAY draws, so mass fills
# the rack in every column. A is series at d=4, B is section's uncut third at d=0, C is
# section band 4, D is section band 2.
const CEILING: Array = [0.820007, 1.469703, 0.467593, 0.349537]

# ONE shared normaliser for count, 5184 being the largest element count in the family.
const MAX_PARTS: int = 5185

const BAY_NAME: PackedStringArray = ["fractal_arch_bench", "sierpinski_bench", "mandelbrot_bench", "julia_bench"]
const BAY_X: Array = [-2.475, -0.825, 0.825, 2.475]
# Constant per bay in all ten variants, so it cancels in every diff. Each is read off
# that bench's own palette: arch stone, sierpinski fill, mandelbrot warm ramp, julia cool.
const BAY_TINT: Array = [[0.74, 0.69, 0.56], [0.70, 0.55, 1.00], [0.95, 0.45, 0.16], [0.20, 0.85, 0.85]]

# ── GEOMETRY ──────────────────────────────────────────────────────────────────
# Row width 5.850 = 3 * PITCH_M + SLAT_LEN, written over the constants it comes from.
const PITCH_M: float = 1.650
const BASE_Y: float = 0.180          # pad top: a v = 0 slat stands on it
const TRAVEL: float = 3.600
const HALF_T: float = 0.200          # half the base thickness, so v = 0 seats the slat
const SLAT_LEN: float = 0.900
const SLAT_LEN_K: float = 0.012
const SLAT_THK: float = 0.400
const SLAT_THK_K: float = 0.002
const SLAT_DEP: float = 0.160
const SLAT_DEP_K: float = 0.004
const RELIEF_Z0: float = -0.075
const RELIEF_DZ: float = 0.030
const RELIEF_LEN_K: float = 0.070    # the taper is what carries relief; see R3
const POST_SIZE: Array = [0.320, 4.060, 0.100]
const POST_Z: float = -0.220
const KERB_SIZE: Array = [0.140, 0.260, 0.240]
const PLINTH_SIZE: Array = [5.850, 0.100, 0.560]
const PAD_SIZE: Array = [0.900, 0.180, 0.200]
const RAIL_SIZE: Array = [5.730, 0.100, 0.100]
const RAIL_Y: float = 4.290


func _ready() -> void:
	_check_axis_declarations()
	_read_grid_meta()
	# _rebuild, not _build: some grid paths call apply_grid_config BEFORE the node enters
	# the tree, and a plain _build() would then stack a second rack on top of the first —
	# 62 boxes, every mark doubled, and a still that looks almost right.
	_rebuild()


## The sweep and GridInteractablesComponent both reach the artifact through here. It is
## synchronous and re-entrant: nothing below waits on a frame, a timer or a signal.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("emissive"):
		emissive = bool(config_data["emissive"])
	if config_data.has("ladder"):
		ladder = _pick(str(config_data["ladder"]), LADDERS, ladder)
	if config_data.has("reckoning"):
		reckoning = _pick(str(config_data["reckoning"]), RECKONINGS, reckoning)
	_rebuild()


# GridInteractablesComponent writes config_* metadata on the ROOT before _ready. Reading
# it here is what makes both axes reachable from a plain map token.
func _read_grid_meta() -> void:
	if has_meta("config_ladder"):
		ladder = _pick(str(get_meta("config_ladder")), LADDERS, ladder)
	if has_meta("config_reckoning"):
		reckoning = _pick(str(get_meta("config_reckoning")), RECKONINGS, reckoning)
	if has_meta("config_emissive"):
		emissive = bool(get_meta("config_emissive"))


func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if allowed.has(v):
		return v
	push_warning("[LadderHall] unknown value '%s'; keeping '%s'" % [raw, fallback])
	return fallback


# ── THE DECLARATION GATE ──────────────────────────────────────────────────────
# science_screen shipped a hand-typed axis block naming values its code enum did not
# have: the sweep set an invalid value, the artifact silently fell back to its default,
# sixteen identical frames were published and the critic reported the axis INERT at
# 0.69%. Every stage green, and the verdict was a fact about a typo. This reads the hint
# string BACK OUT of the engine and compares it to the const list in both directions AND
# in order, so the two cannot drift apart inside one file.
func _check_axis_declarations() -> void:
	_check_axis("ladder", LADDERS)
	_check_axis("reckoning", RECKONINGS)


func _check_axis(prop: String, expect: PackedStringArray) -> void:
	var hint: String = ""
	var found: bool = false
	for entry in get_property_list():
		if str(entry.get("name", "")) == prop:
			hint = str(entry.get("hint_string", ""))
			found = true
			break
	if not found:
		push_error("[LadderHall] axis '%s' has no exported property at all." % prop)
		return
	var declared := PackedStringArray()
	for piece in hint.split(","):
		var s: String = str(piece).strip_edges()
		# An int-backed @export_enum would read "name:0"; these are String-backed, but
		# strip the ordinal anyway so the gate survives a type change.
		var colon: int = s.find(":")
		if colon >= 0:
			s = s.substr(0, colon)
		if s != "":
			declared.append(s)
	if declared.size() != expect.size():
		push_error("[LadderHall] axis '%s': hint has %d values, const has %d — %s vs %s"
			% [prop, declared.size(), expect.size(), declared, expect])
		return
	for i in range(expect.size()):
		if declared[i] != expect[i]:
			push_error("[LadderHall] axis '%s' ORDER drift at %d: hint '%s', const '%s'"
				% [prop, i, declared[i], expect[i]])
	for want in expect:
		if not declared.has(want):
			push_error("[LadderHall] axis '%s': const value '%s' missing from the hint." % [prop, want])
	for got in declared:
		if not expect.has(got):
			push_error("[LadderHall] axis '%s': hint value '%s' missing from the const." % [prop, got])
	# The tables are indexed by LADDERS order; a table that does not cover every declared
	# value would build an empty bay and photograph as a fact about an array length.
	if prop == "ladder":
		for b in range(4):
			var meas: Array = MEASURE[b]
			var parts: Array = PARTS[b]
			if meas.size() != expect.size() or parts.size() != expect.size():
				push_error("[LadderHall] bay %d has %d/%d rung lists for %d ladder values."
					% [b, meas.size(), parts.size(), expect.size()])
				continue
			for li in range(expect.size()):
				if (meas[li] as Array).size() != (parts[li] as Array).size():
					push_error("[LadderHall] bay %d value '%s': %d measures but %d part counts."
						% [b, expect[li], (meas[li] as Array).size(), (parts[li] as Array).size()])


# ── BUILD ─────────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build()


func _build() -> void:
	var li: int = LADDERS.find(ladder)
	if li < 0:
		li = LADDERS.find("series")

	# FURNITURE, byte-identical in all ten variants. This is what holds the framing: the
	# camera is re-fitted per tile from the variant's own AABB, so anything that moved
	# with the axis would make the critic diff two differently-scaled images. The pads
	# are 0.900 wide, exactly the widest slat, so x reaches +/-2.925 even at `figure`
	# where each bay carries one slat.
	var deck: StandardMaterial3D = _matte(Color(0.13, 0.14, 0.17), 0.85, 0.0)
	var steel: StandardMaterial3D = _matte(Color(0.30, 0.32, 0.36), 0.45, 0.55)
	add_child(_box("Plinth", Vector3(0.0, -0.050, 0.0), _v3(PLINTH_SIZE), deck))
	add_child(_box("DatumRail", Vector3(0.0, RAIL_Y, 0.0), _v3(RAIL_SIZE), steel))
	for i in range(4):
		add_child(_box("Pad_%s" % BAY_NAME[i], Vector3(float(BAY_X[i]), 0.090, 0.0), _v3(PAD_SIZE), steel))
	# Kerbs: dividers that cannot occlude, because they stop 44 mm below the lowest slat
	# any variant builds. See the header for why full-height ones are foreclosed.
	for i in range(3):
		var kx: float = (float(BAY_X[i]) + float(BAY_X[i + 1])) * 0.5
		add_child(_box("Kerb%d" % i, Vector3(kx, float(KERB_SIZE[1]) * 0.5, 0.0), _v3(KERB_SIZE), deck))

	var relief: bool = (ladder == "relief")
	var section: bool = (ladder == "section")
	for bay in range(4):
		var vals: Array = _bay_values(bay, li)
		var tint: Color = _tint(bay)
		for k in range(vals.size()):
			var v: float = float(vals[k])
			var length: float = SLAT_LEN - (RELIEF_LEN_K if relief else SLAT_LEN_K) * float(k)
			var thick: float = SLAT_THK - SLAT_THK_K * float(k)
			var depth: float = SLAT_DEP - SLAT_DEP_K * float(k)
			var z: float = (RELIEF_Z0 + RELIEF_DZ * float(k)) if relief else 0.0
			var y: float = BASE_Y + HALF_T + TRAVEL * v
			add_child(_box("Slat_%d_%d" % [bay, k], Vector3(float(BAY_X[bay]), y, z),
				Vector3(length, thick, depth), _matte(tint, 0.72, 0.0)))
		if section:
			# The lit rail all four benches draw on `section` and on nothing else. It
			# spans pad top to rail bottom exactly, and it is the only thing separating
			# bay C's series from its section (R2) — load-bearing, not furniture.
			add_child(_box("Seam_%d" % bay, Vector3(float(BAY_X[bay]), BASE_Y + float(POST_SIZE[1]) * 0.5, POST_Z),
				_v3(POST_SIZE), _glow(Color(1.00, 0.90, 0.62), 1.5)))


## The heights, and the whole argument. `mass` divides by the bay's own ceiling, so the
## four columns are each other's scale-free comparison; `count` divides by ONE shared
## logarithm, so equal heights across bays mean equal part counts and nothing else.
func _bay_values(bay: int, li: int) -> Array:
	var out: Array = []
	if reckoning == "count":
		var norm: float = log(float(MAX_PARTS))
		for p in (PARTS[bay][li] as Array):
			out.append(log(float(p) + 1.0) / norm)
	else:
		var ceiling: float = float(CEILING[bay])
		for m in (MEASURE[bay][li] as Array):
			out.append(float(m) / ceiling)
	return out


func _tint(bay: int) -> Color:
	var c: Array = BAY_TINT[bay]
	return Color(float(c[0]), float(c[1]), float(c[2]))


func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _box(node_name: String, centre: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	return mi


func _matte(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emissive:
		# A small untinted lift so the slats read against the showcase ground without
		# any of them becoming the hottest pixels — the seam post has to keep that job.
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.12
	return m


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy if emissive else energy * 0.3
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m
