extends Node3D
class_name PassageLedger

## passage_ledger — a SYNTHESIS artifact. One passage, told five ways.
##
## @identity
## essence: Five bays in a row, each holding the SAME axis_translation_cube body at the
##   SAME instant of the SAME motion, and differing only in what account the artifact
##   gives of that motion — the sampled path, the swept solid, the two ends, the rule
##   written out, or nothing at all. The cube, the rail, the bar, the termini and the
##   plate are the source's own geometry at 1:1, built by the source's own arithmetic
##   from cube_size 0.15, travel_distance r and travel_speed 0.3.
## desire: To be read as five theories of what a still frame can hold of a motion —
##   which is law 5 of this corpus turned into subject matter rather than obeyed.
## critical_parameter: `state` — WHEN you looked. Both moving values pin the cube at
##   offset 0.000 with the same lerp parameter, the same colour and the same emission,
##   so the two frames are identical everywhere except in the trail. The only thing in
##   the whole ledger that knows which way the object is going is the one deposit the
##   runtime has never actually drawn.
## triggers: none. No _process, no Timer, no await, no physics, no randf anywhere in
##   this file. Everything is computed synchronously in _ready from the two exports.
## emerges: that `ghost` and `none` are the SAME builder branch (_build_account is a
##   bare `pass` for both, axis_translation_cube.gd:577,:579), separated only by what
##   was cleared before it ran — one clears nothing, the other clears everything.
## needs: the source's body at 1:1 and not a gauge of it [has]; the FSM's own offsets
##   and not chosen ones [has, _pinned_offset]; a spatialised trail whose step is the
##   only step that makes four samples a complete record [has, _trail_history]; one
##   constant-extent anchor so the sheet is not a picture of a zoom [has, _add_anchor];
##   no random number anywhere [has]
## relationships: every value word, every colour and every dimension is
##   [[axis_translation_cube]]'s, read out of its ACCOUNTS array and its State enum at
##   build time rather than retyped. `ghost` and `none` are the words this wave is
##   asking about across two families.
## truth: A translation leaves no evidence of itself. Everything in these five bays
##   except the cube is an INSTRUMENT — and the account named for holding history holds
##   none whenever the object is at rest, at every reach, which is most of the time.
##
## ═══════════════════════════════════════════════════════════════════════════════
## WHAT `account` MEANS IN THIS FAMILY, FROM THE CODE
## ═══════════════════════════════════════════════════════════════════════════════
##
## GHOST is not a trail. It is THE UN-SUBTRACTED WHOLE. _read_dna's match falls through
## to a bare `pass` (axis_translation_cube.gd:161-162) so all three want-flags stay
## true, and _build_account adds nothing for it (:578-579). What makes a frame "ghost"
## is purely that NOTHING WAS CLEARED: the legacy build survives entire — rail, two end
## markers, three labels, a four-instance MultiMesh.
##
## And the thing it is NAMED for has never been visible, in any still or in any motion.
## _trail_history[0] is the cube's CURRENT offset (:453) and the array shifts one slot
## per RENDERED FRAME (:451-452), so the four samples lag by 0, 1, 2, 3 frames — 0, 5,
## 10, 15 mm at 60 fps — while their half-extents are 37.5, 43.1, 48.8 and 54.4 mm
## against the cube's 75 mm. Grid.gdshader writes no ALPHA and declares no blend mode
## (:2-3, :79-80), so the cube is fully opaque and swallows all four. The exact
## visibility condition is i*step > 0.075*(1 + scale_i), binding at i = 1:
## step > 0.118125 m, i.e. travel_speed/fps > 0.118125, i.e. FPS <= 2.54.
## THE TRAIL IS VISIBLE ONLY BELOW 2.54 FRAMES PER SECOND.
##
## So in this family `ghost` means: everything, minus nothing — including the one part
## of itself nobody has ever seen. The value named ghost is a ghost of a ghost.
##
## NONE is the only value that clears the labels as well as the rail and the trail
## (:157-160), and like ghost it ADDS nothing. But `none` is not empty and never has
## been: _setup_controls (:129, :354-366) is called unconditionally and BEFORE
## _build_account, so the cream RackTemplates panel titled "TRANSLATION" stands 0.6 m
## in front of the cube in `none` exactly as in the other four, and _add_travel_anchor
## (:671-687) leaves a 0.95 m invisible box behind. `none` is the result plus its
## instrument plus its frame: the operation is withheld, the apparatus is not.
##
## THE WAVE QUESTION. If the other family's `ghost` means "a translucent copy of a
## former state", then the two words DO NOT AGREE and this family is the one that
## breaks: here `ghost` is a DEFAULT — the un-subtracted lineage — and its copies are
## opaque, GROWING (0.500 newest to 0.725 oldest, :457), enclosed inside the object and
## never rendered. The two families agree about `none` only halfway: both use it for
## withholding, and this one shows that withholding the account does not withhold the
## apparatus. Neither word describes a picture. Both name an operation on a BUILD — one
## that clears nothing, one that clears everything — and the pictures they produce were
## never checked against them.
##
## ═══════════════════════════════════════════════════════════════════════════════
## LAW 2 — CORRECTIONS, VERIFIED AGAINST THE CODE
## ═══════════════════════════════════════════════════════════════════════════════
##
##  1. The trail's "fading" is worse than discarded alpha. Grid.gdshader:59-65 selects
##     instanceColor as the BASE colour whenever its alpha < 0.99 — every trail instance
##     is 0.25 or less — so a visible ghost renders its interior at full (0.3,0.6,1.0),
##     BRIGHTER than the cube's own interior (0.06,0.12,0.20). The faintest ghost would
##     be the most luminous body in the bay.
##  2. _account_sweep's modelColor is cube_color * 0.18 (:600), not * 0.2.
##  3. Both wait states print the identical second line (:441-442), so the live readout
##     cannot tell them apart — only the sign of the number can.
##  4. _update_trail's guard is `not show_trail or not _trail_mm` (:447) and never
##     checks _want_trail; safety is indirect, through _trail_mm staying null.
##  5. trail_count is @export_range(1,20) and ghost_scale divides by maxf(trail_count,1),
##     so no instance is ever scale 1.0 — the trail never reaches the cube's size.
##  6. show_interior is DEAD: Grid.gdshader:70-76 runs the identical mix() in both
##     branches.
##  7. :668-670 claims the TravelAnchor's extent "is exactly the rail's". False — the
##     anchor is cube_size wide (0.150) while the markers reach x = 0.200. It stabilises
##     the travel axis, not the frame.
##  8. const COURSES (:67) is ["lateral","lift","depth"] while transforms.json:6-10
##     declares ["lift","lateral","depth"] — the registry and the code disagree on order.
##  9. THE PALETTE IS THE SWEPT TOKEN'S, AND ITS SIBLINGS DIFFER. axis_translation_cube
##     .tscn overrides nothing, so cube_color is the script default Color(0.3,0.6,1.0).
##     The sibling that carries course = "lift" — y_translation_cube.tscn — overrides
##     cube_color to Color(0.3,0.8,0.4), GREEN. This ledger is the swept token's blue,
##     because the swept token is what declares the axes; a viewer who knows the lift
##     member from a map will have met it green.
##
## ═══════════════════════════════════════════════════════════════════════════════
## WHAT THIS ARTIFACT ARGUES
## ═══════════════════════════════════════════════════════════════════════════════
##
## That the account is not a rendering choice, it is an epistemology, and the five are
## not five styles but five different claims about where the motion went. Read left to
## right the row is a subtraction: ghost keeps everything and shows a hairline; sweep
## trades the history for the orbit; terminus throws away the middle and gains the two
## instants when its own claim is true; formula gives up the picture entirely and is the
## only bay a still can hold COMPLETELY; none keeps the result and admits nothing.
##
## And the row's proportions are themselves the finding. The pitch is set by the one bay
## whose content is TEXT: the formula plate is 0.66-0.76 m wide against a 0.15 m cube,
## 4.4x to 5.1x the object it describes. WRITING THE RULE OUT TAKES FIVE TIMES THE ROOM
## THAT DOING IT TAKES.
##
## ═══════════════════════════════════════════════════════════════════════════════
## THE AXES
## ═══════════════════════════════════════════════════════════════════════════════
##
## `state` FIRST (law 15 — the gallery trims from the tail of the later axis). It is the
## family's OWN list: the State enum at axis_translation_cube.gd:24, in enum order,
## lowercased. The offsets are the FSM's own, not chosen — WAIT_POSITIVE/WAIT_NEGATIVE
## clamp _current_offset to exactly +/-travel_distance (:386, :398) and both moving
## values are pinned at offset 0.000, the instant the cube crosses its own base_position.
## So the two moving frames put the cube in the SAME place with the SAME lerp parameter
## t = (0/r + 1)/2 = 0.5, the same wireframe colour (0.315, 0.645, 0.910), the same
## emission x1.5 and the same emission_strength 0.7 (:484-489). EVERYTHING THAT SEPARATES
## THEM IS THE TRAIL.
##
## `phase` (traverse|crest|steepest|trough) was REFUSED. It is the nearest neighbour's
## word for the same question — y_oscillation_cube, velocity_arrow, slope_tangent_demo,
## partial_derivative_terrain — but this motion is piecewise LINEAR at 0.3 m/s and has no
## steepest point, so importing that list would ship a designed twin with no referent.
## `state` is unused as an axis anywhere in the corpus.
##
## `reach` SECOND — how far the passage goes, in units of the thing that goes. It is
## travel_distance, @export_range(0.05, 2.0, 0.05) at :31, and the three values are the
## export's own landmarks, not taste:
##   stride = 0.40  the shipped default and every frame this family has ever produced
##   body   = 0.15  exactly cube_size (:29) — the passage is one object long
##   nudge  = 0.05  the export's own MINIMUM — one third of a body
## Declared stride-first so a tail trim drops nudge and leaves two.
##
## It cannot borrow signal from `account`: travel_distance is read BEFORE the account
## branch runs (_ready order :123-132; _build_account is appended LAST) and all five
## branches consume the same float — span = 2r + 0.15 (:197, :586, :672), termini at
## base +/- up*r (:617-619), the plate's interval printed from r (:653-655), markers at
## +/-r (:237-244).
##
## DECLARED CONDITIONAL CROSSING (the standing lesson: group by VALUE PAIR, not by
## context mean). `reach` moves the cube only at the two WAIT states; the ghost trail
## exists only at the two MOVING states. The two axes are independent in construction
## and interacting in effect. And `reach` is exactly what decides whether ghost exists
## at all: ghost i clears the opaque cube iff i*r/3 > 0.075*(1 + 0.5 + i*0.075), i.e.
## r > 0.354375 (i=1), 0.185625 (i=2), 0.129375 (i=3) — so stride shows THREE ghosts,
## body shows ONE, nudge shows NONE. _check_ghost_census() gates that table at run time.
##
## ═══════════════════════════════════════════════════════════════════════════════
## THE FRAME (law 7/8/9/10/11) — every number here is asserted at run time
## ═══════════════════════════════════════════════════════════════════════════════
##
## Five bays along +X at pitch 0.86, in the ACCOUNTS order character for character:
## ghost -1.72, sweep -0.86, terminus 0.00, formula +0.86, none +1.72. At yaw 0.62 the
## screen-right vector is (0.81388, 0, -0.58104), so +X reads left-to-right and the row
## reads in declared order. The camera stands at +X +Y +Z, and +Z projects screen-LEFT —
## which is why the formula plate at z = +0.18 overhangs toward terminus, not toward none.
##
## COURSE IS PINNED TO "lift" AND THE REFUSAL IS DECLARED (law 13, dna.declines). Two
## measured reasons. (1) The row is a row: at `lateral` the 0.95 m run lies along the row
## axis, the widest tenant's screen-x half-extent rises 0.183 -> 0.430, law 9 then demands
## pitch >= 1.18, the union AABB goes 3.59 -> 5.67 m and every mark loses 36% — the
## formula plate's em falls from 11.9 px to 9.8 px, and the bay whose entire body is text
## has to be readable or law 1 fails there. (2) The critic crops to the union subject box
## and resizes NON-UNIFORMLY to 160x160: this row crops 631 x 347, squashing horizontal
## detail 3.95x and vertical only 2.17x, so `lift` puts the whole state axis on the
## better-preserved screen axis, worth 1.8x on the measurement.
##
## LAW 9, DAYLIGHT, at the widest variant of BOTH axes (the envelopes are constant across
## all 12 tiles — state and reach move things only vertically). Screen-x half-extent of a
## box = 0.81388*hx + 0.58104*hz; a centre offset in z shifts screen-x by -0.58104*z.
##   bays 1-3 envelope  x in [-0.225, +0.236] -> screen-x [-0.183, +0.192]
##                      (the widest tenant is NOT the geometry, it is the legacy readout,
##                       LEFT-aligned at local x = -cube_size*1.5)
##   bay 4 (formula)    plate half-width 0.38 at z = +0.18 -> screen-x [-0.414, +0.205]
##   bay 5 (none)       cube only -> +/-0.105
##   PITCH * cos(0.62) = 0.700
##   1->2, 2->3 : 0.700 - (0.192 + 0.183) = +0.325 m   (~50 projected px)
##   3->4 BIND  : 0.700 - (0.192 + 0.414) = +0.094 m   (~22 px at em 0.60, ~35 at 0.52)
##   4->5       : 0.700 - (0.205 + 0.105) = +0.390 m   (~108 px)
## At pitch 0.74 the binding gap would be +1 px — touching. That is why the pitch is 0.86.
##
## LAW 10, Z-STACK, depth key k = 0.56151x + 0.25708y + 0.78652z (larger = nearer),
## quoted in bay-local coordinates:
##   datum rod      z in [-0.143,-0.137]                k ~ -0.110   farthest, behind all
##   sweep bar      x,z in [-0.0465,+0.0465]            k <= +0.063
##   rail           x in [+0.097,+0.113], z +/-0.008    k in [+0.048,+0.070]
##   trail ghosts   x,z in [-0.0544,+0.0544]            k <= +0.073
##   markers        x in [+0.085,+0.125], z +/-0.02     k in [+0.032,+0.086]
##   live cube      x,z in [-0.075,+0.075]              k in [-0.101,+0.101]  nearest opaque
##   terminus cubes same x,z, different y               k in [-0.101,+0.101]
##   formula plate  z = +0.18                           k = +0.1416 + 0.25708y
##                  nearer than the cube, but a Label3D draws only glyph pixels and its
##                  screen-y band [+0.182,+0.318] misses the cube's [-0.073,+0.073] at
##                  both moving states, grazing it by ~1 px at wait_positive
##   legacy labels  z = 0, offset in x only, never over the cube at any of the four states
##   name plates    y = 1.236, above everything
## THE THREE OCCLUSIONS ARE THE SOURCE'S OWN AND ARE KEPT: (1) the cube hides 0.15 m of
## the 0.95 m rail; (2) the cube hides the bar's middle 0.15 m — the capital-on-a-column
## reading; (3) at wait_positive the cube sits ON the green marker and swallows it, at
## wait_negative the red one. That third one explains the existing pixels:
## doc/reports/sweep_y_translation_cube.png was shot at offset +0.356 and shows a cube, a
## hairline rail and ONE RED DOT. The ledger reproduces the fact rather than tidying it.
##
## THE ONE DELIBERATE COINCIDENCE: at wait_positive, bay 3's live wireframe cube and its
## solid "after" cube have IDENTICAL transforms (:410 and :619 compute the same point).
## That is not an error to dodge — it is the finding that TERMINUS IS TRUE EXACTLY TWICE
## PER 7.333 s PERIOD, and at those instants the moving object disappears into the claim.
## It is made deterministic by draw order: the live cube is the last opaque body added to
## its bay, never by a fudge offset.
##
## LAW 11: 13 MeshInstance3D + 1 MultiMeshInstance3D (4 instances) + 14 Label3D = 28
## visual nodes, IDENTICAL in all 12 tiles because `account` is EXHIBITED, not swept.
## 13 of ~3200 = 0.4% of the ceiling. The single ledger anchor discharges law 11 for the
## MultiMesh (which contributes nothing to the capture AABB, so bay 1 would otherwise
## contribute only its cube) and replaces five per-bay anchors, so the union AABB is one
## authored box that cannot drift when reach changes every bay's vertical extent by 8x.
##
## LAW 8, THE PIXEL GAUGE IS PER BAY. The row spreads 1.358x in depth (bay 1 at 7.323 m,
## bay 5 at 5.392 m from a camera at dist 6.3575), so one number for the row would be
## wrong by up to 36%. mm/px = D_bay * 2 * tan(17 deg) / 760:
##   bay 1 ghost    7.323 m  5.892 mm/px  169.7 px/m  <- WORST BAY, and the finest marks
##   bay 2 sweep    6.840 m  5.503 mm/px  181.7 px/m
##   bay 3 terminus 6.357 m  5.115 mm/px  195.5 px/m
##   bay 4 formula  5.875 m  4.726 mm/px  211.6 px/m
##   bay 5 none     5.392 m  4.338 mm/px  230.5 px/m
## Gauged AT THE WORST BAY unless the mark lives elsewhere: cube edge 25.5 px; travel run
## 161.2 px; ghost cubes 14.6 / 16.5 / 18.5 px; ghost step r/3 = 22.6 px (gaps 2.6, 7.0,
## 5.1 px — a caterpillar, not a blur); marker sphere 6.8 px (UNDER the ~10 px floor,
## declared secondary); rail diameter 2.7 px (a hairline in the source too — a 16 mm
## thread beside a 150 mm cube — NOT load-bearing). Elsewhere: sweep bar width 16.9 px and
## length 172.6 px; terminus cubes 29.3 px, separation 156.4 px; formula em 14.9 px, cap
## height ~10.4 px; none cube 34.6 px. Ghost's load-bearing marks are its three trail
## cubes at 14.6-18.5 px.
##
## FRAMING 0.55. Union AABB (mesh only; the anchor IS the union) = 3.59 x 0.95 x 0.218,
## centre (0, 0.475, -0.034), half-diagonal radius 1.8600. At framing 1.0 the half-frame
## is 3.534 m against a furthest projected point of 1.827 m — 48% of the frame thrown
## away, because the capture fits by the DIAGONAL and this row is 16x wider than deep.
## 0.55 gives dist 6.3575 m, half-frame 1.9437 m, worst point at 94.0%. Tighter clips
## (0.50 -> 100.2%); looser costs 1.8% per 0.01 on every mark.
##
## PREDICTED, BEFORE THE CAPTURE — and these are FLOORS, not forecasts (four prior
## predictions in this corpus under-shot by 1.5x, 1.7x, 3.5x and 6.7x; a result BELOW a
## prediction is the alarm):
##  1. EQUALITY, the thesis. At any fixed reach, moving_positive and moving_negative are
##     IDENTICAL inside the screen rects of bays 2, 3 and 5. They differ ONLY in bay 1's
##     three ghosts, mirrored about the datum, and four glyphs of direction word.
##     Changed area ~1658 px of 577,600 -> focus floor 0.083, the LOWEST of the six state
##     pairs, while every pair involving a wait state is >= 0.45.
##  2. EQUALITY. At either moving state, bay 5's screen rect is PIXEL-IDENTICAL across all
##     three reaches — a cube at offset 0 with nothing around it cannot report a distance.
##     Bay 4 in the same comparison changes by exactly four characters and a 0.19 m slide
##     of a plate whose SIZE never changes. The algebra is scale-free because it is a
##     rule; `none` is scale-free because it is silent. Opposite reasons, same measurement.
##  3. dna.predicted_degeneracy — the closest pair in the 12-tile sweep, named in advance:
##     (moving_positive, nudge) vs (moving_negative, nudge), floor focus 0.010, a TRUE
##     TWIN under TWIN_FOCUS = 0.060. At r = 0.05 the oldest ghost lags 0.05 m, under the
##     0.129375 m it needs to clear the cube, so claim 1's ghost term vanishes too and the
##     frames differ only in four direction words. It is the design's own sentence: below
##     a certain reach, nothing in the ledger records direction at all.
## Subject share ~2.40% of frame (the number to beat was 1.59%, doc/reports/
## sweep_y_translation_cube_bite.json). Both headline verdicts will be PEAKS — read the
## per-pair rows, never the headline.
##
## DECLARED OMISSION (dna.omits) AND IT IS THE DESIGN'S ONE KNOWING GAP: the RackTemplates
## panel (:129, :354-366) is omitted from all five bays. It is present in ALL FIVE values
## and therefore carries zero account signal, but five of them would be ~40 meshes and
## 5 x 0.0219 m^2 of Color(0.90,0.87,0.80) — the brightest surface in the frame — against
## the cube's 0.0225 m^2 of (0.06,0.12,0.20) interior, and each panel's screen-x centre
## sits 0.349 m LEFT of its own bay, 41% of the way into its neighbour, forcing the pitch
## from 0.86 to >= 1.15. The cost of keeping it is the loss of the thing being claimed.
## The cost of dropping it is that BAY 5 PHOTOGRAPHS AS THE DOCSTRING'S CLAIM (:92-93)
## RATHER THAN THE CODE'S FACT — that `none` is the result plus its instrument. The
## correction survives only in this header and in the registry text. Also omitted: the
## hidden formula label (:282-293, visible = false, draws nothing).
##
## SWEEP: 4 states x 3 reaches = 12 tiles. build_dna_gallery --max DEFAULTS TO 9 and must
## be run with --max=12 or three tiles vanish silently.

# ═══════════════════════════════════════════════════════════════════════════════
# THE SOURCE
# ═══════════════════════════════════════════════════════════════════════════════

## The family itself. Every value word, every colour, every dimension and the direction
## glyphs are read out of this at build time rather than retyped — see _probe_source().
const SRC := preload("res://commons/artifacts/axis_translation_cube/axis_translation_cube.gd")
const GRID_SHADER := preload("res://commons/resourses/shaders/Grid.gdshader")

# ═══════════════════════════════════════════════════════════════════════════════
# THE AXES — `state` FIRST (law 15: the gallery trims the tail of the LATER axis)
# ═══════════════════════════════════════════════════════════════════════════════

## WHEN you looked. The State enum at axis_translation_cube.gd:24, in enum order,
## lowercased. Checked against SRC.State.keys() at run time — the code wins.
## ONE LINE, DELIBERATELY. Godot accepts the annotation on its own line and this was
## written that way; tools/check_dna_declarations.py:381-382 cannot see it there, because
## has_export matches `@export[^\n]*\bvar\s+<axis>` and `[^\n]*` will not cross a newline.
## Split across two lines this axis reported NO_EXPORT against a real @export_enum and the
## gate exited red on a correct declaration. `reach` below was already on one line and
## passed, which is the tell.
@export_enum("moving_positive", "wait_positive", "moving_negative", "wait_negative") var state: String = "moving_positive"
const STATES: PackedStringArray = [
	"moving_positive", "wait_positive", "moving_negative", "wait_negative"
]

## HOW FAR the passage goes, in units of the thing that goes. travel_distance's own
## landmarks: the shipped default, exactly one cube_size, and the export's minimum.
@export_enum("stride", "body", "nudge") var reach: String = "stride"
const REACHES: PackedStringArray = ["stride", "body", "nudge"]

# ═══════════════════════════════════════════════════════════════════════════════
# THE ARITHMETIC — every number below is asserted against the source in _ready
# ═══════════════════════════════════════════════════════════════════════════════

## travel_distance, metres. stride = the shipped default (:31); body = cube_size (:29);
## nudge = the export_range minimum (:31). Consts drive the BUILD so every published
## number stays reproducible; the probe drives an ERROR CHECK so drift is loud.
const STRIDE_M: float = 0.40
const BODY_M: float = 0.15
const NUDGE_M: float = 0.05

const CUBE_SIZE: float = 0.15      # :29
const TRAVEL_SPEED: float = 0.3    # :33 — piecewise LINEAR, which is why `phase` is refused
const WAIT_TIME: float = 1.0       # :35
const TRAIL_COUNT: int = 4         # :43

## Bay pitch, set by the ONE BAY WHOSE CONTENT IS TEXT. See law 9 in the header.
const BAY_PITCH: float = 0.86

## The source's grounding offset base_position = (0.075, 0.075, 0.075) (:124) becomes
## (bay_x, BASE_Y, 0): a PURE TRANSLATION, so the bottom of the longest run sits on
## y = 0 and every offset the code computes FROM base is preserved exactly.
const BASE_Y: float = STRIDE_M + CUBE_SIZE * 0.5          # 0.475

## The union AABB, authored rather than emergent. Asserted in _check_frame().
const ROW_W: float = 4.0 * BAY_PITCH + CUBE_SIZE          # 3.59
const ROW_H: float = 2.0 * STRIDE_M + CUBE_SIZE           # 0.95
const DATUM_Z: float = -0.140
const DATUM_T: float = 0.006
const ROW_Z_NEAR: float = CUBE_SIZE * 0.5                 # +0.075
const ROW_Z_FAR: float = DATUM_Z - DATUM_T * 0.5          # -0.143
const ROW_D: float = ROW_Z_NEAR - ROW_Z_FAR               # 0.218
const ROW_CZ: float = (ROW_Z_NEAR + ROW_Z_FAR) * 0.5      # -0.034

## Name plates. The tallest thing below them is the stride readout, whose top sits at
## 1.0922; a font-96 plate's own half-height is ~0.0576, so its bottom is at ~1.1784 —
## 0.086 m of clear air. Fixed across all 12 tiles so the plates never move.
const NAME_Y: float = 1.236
const NAME_FONT: int = 96

## Fallback only. The live table is read off the source in _probe_source(); if the two
## disagree the CODE WINS and the mismatch is pushed as an error. Order matches STATES.
const DIR_FALLBACK: PackedStringArray = ["↑ up", "⏸ wait", "↓ down", "⏸ wait"]

# ── probed off the source, never typed ────────────────────────────────────────
var _accounts: PackedStringArray = PackedStringArray()
var _dir_words: PackedStringArray = PackedStringArray()
var _axis_letter: String = "Y"
var _cube_color: Color = Color(0.3, 0.6, 1.0)

var _row: Node3D = null
var _built: bool = false
var _n_mesh: int = 0
var _n_label: int = 0
var _n_multimesh: int = 0


func _ready() -> void:
	_read_grid_config_meta()
	_probe_source()
	_check_vocabularies()
	_check_frame()
	_build()
	_check_ghost_census()
	_check_element_budget()


# ═══════════════════════════════════════════════════════════════════════════════
# DERIVE, NEVER TRANSCRIBE (law 2)
# ═══════════════════════════════════════════════════════════════════════════════

## Instantiates the source script as an ORPHAN — _ready never runs, _process never runs —
## reads its shipped defaults, its ACCOUNTS array, its State enum and its own direction
## glyphs, then frees it. Nothing here reaches the scene tree and nothing here is async.
func _probe_source() -> void:
	_accounts = SRC.ACCOUNTS
	var probe: Object = SRC.new()
	if probe == null:
		push_error("passage_ledger: could not instantiate axis_translation_cube.gd — using fallbacks")
		_dir_words = DIR_FALLBACK
		return

	var col: Variant = probe.get("cube_color")
	if col is Color:
		_cube_color = col
	else:
		push_error("passage_ledger: source cube_color did not read back as a Color")
	_axis_letter = str(probe.call("_get_axis_name"))

	# The FSM's four states, each asked for its own word. `_state` is enum-typed, and a
	# typed set() of the wrong type is refused IN SILENCE — so it is read back.
	_dir_words = PackedStringArray()
	for i in STATES.size():
		probe.set("_state", i)
		if int(probe.get("_state")) != i:
			push_error("passage_ledger: set('_state', %d) was refused — read back %d" % [
				i, int(probe.get("_state"))])
		_dir_words.append(str(probe.call("_get_direction_name")))

	# The shipped defaults this ledger's arithmetic is built on.
	_expect_f("cube_size", float(probe.get("cube_size")), CUBE_SIZE)
	_expect_f("travel_speed", float(probe.get("travel_speed")), TRAVEL_SPEED)
	_expect_f("wait_time", float(probe.get("wait_time")), WAIT_TIME)
	_expect_f("travel_distance (stride)", float(probe.get("travel_distance")), STRIDE_M)
	_expect_f("cube_size (body)", float(probe.get("cube_size")), BODY_M)
	if int(probe.get("trail_count")) != TRAIL_COUNT:
		push_error("passage_ledger: source trail_count is %d, this ledger draws %d" % [
			int(probe.get("trail_count")), TRAIL_COUNT])
	if not bool(probe.get("show_rail")) or not bool(probe.get("show_trail")):
		push_error("passage_ledger: source no longer ships show_rail/show_trail true — `ghost` is no longer the un-subtracted whole")

	# `nudge` is the export's own minimum, read out of the range hint.
	for p in probe.get_property_list():
		if str(p.get("name", "")) == "travel_distance":
			var bits: PackedStringArray = str(p.get("hint_string", "")).split(",", false)
			if bits.size() >= 1:
				_expect_f("travel_distance range minimum (nudge)", float(bits[0]), NUDGE_M)

	probe.free()

	if _dir_words.size() != DIR_FALLBACK.size():
		_dir_words = DIR_FALLBACK
		return
	for i in _dir_words.size():
		if _dir_words[i] != DIR_FALLBACK[i]:
			# LAW 2: the code wins. The derived word is kept and the drift is reported.
			push_error("passage_ledger: state %d reads '%s' in the source and '%s' in this file — using the source" % [
				i, _dir_words[i], DIR_FALLBACK[i]])


func _expect_f(what: String, got: float, want: float) -> void:
	if absf(got - want) > 0.0001:
		push_error("passage_ledger: source %s is %.4f, this ledger's arithmetic assumes %.4f — every framing number above is void" % [
			what, got, want])


# ═══════════════════════════════════════════════════════════════════════════════
# THE SELF-CHECKS — a declaration that cannot drift from the code
# ═══════════════════════════════════════════════════════════════════════════════

## An @export_enum literal cannot be derived from a const at parse time, so reading
## hint_string back out of get_property_list() is the only defence. science_screen
## shipped a hand-typed block declaring none|bezel|hooded|cabinet against a code enum of
## stand|wall|console|rig: the sweep set an invalid value, the artifact fell back to its
## default, sixteen identical frames were published and the critic reported the axis
## INERT at 0.69%. Every stage green, and the verdict was a fact about a typo.
func _check_vocabularies() -> void:
	_check_hint("state", STATES)
	_check_hint("reach", REACHES)
	if not STATES.has(state):
		push_error("passage_ledger: the default state '%s' is not in the declared list" % state)
	if not REACHES.has(reach):
		push_error("passage_ledger: the default reach '%s' is not in the declared list" % reach)

	# `state` is the family's OWN list — the State enum, lowercased, in enum order.
	# Held as a Variant on the way out: reading SRC.State directly is deliberate (it fails
	# at PARSE time if the enum is ever deleted, which is the failure mode worth having),
	# but assigning it to a Dictionary-typed local would be a static type error, and
	# get_script_constant_map() is non-static and cannot be called on the class at all.
	var enum_map: Variant = SRC.State
	var from_code: PackedStringArray = PackedStringArray()
	for k in enum_map.keys():
		from_code.append(String(k).to_lower())
	if from_code.size() != STATES.size():
		push_error("passage_ledger: axis_translation_cube.State has %d members, `state` declares %d" % [
			from_code.size(), STATES.size()])
	for i in from_code.size():
		if i < STATES.size() and from_code[i] != STATES[i]:
			push_error("passage_ledger: State member %d is '%s' in the code and '%s' in `state`" % [
				i, from_code[i], STATES[i]])

	# The bays ARE the family's ACCOUNTS array — read, not retyped (law 13).
	if _accounts.size() != 5:
		push_error("passage_ledger: axis_translation_cube.ACCOUNTS has %d values, this ledger has 5 bays" % _accounts.size())


func _check_hint(prop: String, allow: PackedStringArray) -> void:
	var hint: String = ""
	for p in get_property_list():
		if str(p.get("name", "")) == prop:
			hint = str(p.get("hint_string", ""))
	var declared: PackedStringArray = hint.split(",", false)
	if declared.size() != allow.size():
		push_error("passage_ledger: export '%s' declares %d values, the allow-list has %d" % [
			prop, declared.size(), allow.size()])
	for i in declared.size():
		if not allow.has(declared[i]):
			push_error("passage_ledger: export '%s' declares '%s', the allow-list does not" % [
				prop, declared[i]])
	for j in allow.size():
		if not declared.has(allow[j]):
			push_error("passage_ledger: allow-list has '%s', the '%s' export hint does not" % [
				allow[j], prop])
		# LAW 13 — order as well as membership. A list that agrees as a set but not as a
		# sequence would silently reorder this sweep's tiles against the family's.
		if j < declared.size() and declared[j] != allow[j]:
			push_error("passage_ledger: '%s' value %d is '%s' in the export and '%s' in the allow-list" % [
				prop, j, declared[j], allow[j]])


## RISK 9, gated. No `measurements` block exists for a born-promoted token, so nothing
## downstream will catch a wrong anchor: if it is authored at any size other than
## (3.59, 0.95, 0.218) the camera silently refits and every framing number above is void.
func _check_frame() -> void:
	_expect_f("row width", ROW_W, 3.59)
	_expect_f("row height", ROW_H, 0.95)
	_expect_f("row depth", ROW_D, 0.218)
	_expect_f("row centre z", ROW_CZ, -0.034)
	_expect_f("base y", BASE_Y, 0.475)
	var radius: float = 0.5 * sqrt(ROW_W * ROW_W + ROW_H * ROW_H + ROW_D * ROW_D)
	_expect_f("fit radius", radius, 1.8600)
	# Law 7: dist = radius / tan(FOV/2) * PAD * framing, FOV 34 deg, PAD 1.9, framing 0.55
	var dist: float = radius / tan(deg_to_rad(17.0)) * 1.9 * 0.55
	_expect_f("capture distance", dist, 6.3575)
	# Law 9, the binding pair: terminus -> formula.
	var daylight: float = BAY_PITCH * cos(0.62) - (0.192 + 0.414)
	if daylight <= 0.0:
		push_error("passage_ledger: bays 3 and 4 OVERLAP on screen by %.3f m" % -daylight)
	# The stride readout must clear the name plates.
	var readout_top: float = BASE_Y + STRIDE_M + 0.15 + 56.0 * 0.001 * 1.2
	if NAME_Y - NAME_FONT * 0.001 * 0.6 <= readout_top:
		push_error("passage_ledger: the name plates sit on the stride readout")


## The ghost census IS the crossing this artifact declares: reach decides whether ghost
## exists at all. stride 3, body 1, nudge 0. If this table ever changes, the registry's
## conditional-crossing claim is wrong and the sheet is arguing something else.
func _check_ghost_census() -> void:
	var want: Dictionary = {"stride": 3, "body": 1, "nudge": 0}
	for w in want.keys():
		var r: float = STRIDE_M
		if String(w) == "body":
			r = BODY_M
		elif String(w) == "nudge":
			r = NUDGE_M
		var seen: int = 0
		var hist: PackedFloat32Array = _trail_history(r, "moving_positive")
		for i in range(1, hist.size()):
			if _ghost_clears_cube(i, hist[i] - hist[0]):
				seen += 1
		if seen != int(want[w]):
			push_error("passage_ledger: reach '%s' clears %d ghosts, the declared crossing says %d" % [
				String(w), seen, int(want[w])])
	# And at rest the account named for holding history holds none, at EVERY reach.
	for w2 in want.keys():
		var r2: float = STRIDE_M
		if String(w2) == "body":
			r2 = BODY_M
		elif String(w2) == "nudge":
			r2 = NUDGE_M
		var h2: PackedFloat32Array = _trail_history(r2, "wait_positive")
		for j in range(1, h2.size()):
			if _ghost_clears_cube(j, h2[j] - h2[0]):
				push_error("passage_ledger: reach '%s' shows ghost %d at rest — the saturation claim is wrong" % [
					String(w2), j])


func _check_element_budget() -> void:
	if _n_mesh != 13 or _n_multimesh != 1 or _n_label != 14:
		push_error("passage_ledger: built %d meshes / %d multimesh / %d labels, the declared budget is 13 / 1 / 14" % [
			_n_mesh, _n_multimesh, _n_label])


# ═══════════════════════════════════════════════════════════════════════════════
# THE FSM, RUN BACKWARDS — the source's own offsets, not chosen ones
# ═══════════════════════════════════════════════════════════════════════════════
#
# Steady-state cycle, phase 0 at the start of MOVING_POSITIVE (offset -r):
#   [0, Tr)              rising    offset = -r + v*phase        Tr = 2r/v
#   [Tr, Tr+W)           held at +r
#   [Tr+W, 2Tr+W)        falling   offset = +r - v*(phase-Tr-W)
#   [2Tr+W, 2Tr+2W)      held at -r
# Period = 2Tr + 2W = 7.3333 s at stride.

func _reach_metres() -> float:
	if reach == "body":
		return BODY_M
	if reach == "nudge":
		return NUDGE_M
	return STRIDE_M


func _ramp_seconds(r: float) -> float:
	return 2.0 * r / TRAVEL_SPEED


func _period(r: float) -> float:
	return 2.0 * _ramp_seconds(r) + 2.0 * WAIT_TIME


## The FSM's own clamp (:386, :398), exactly. Both moving values are pinned at the
## instant the cube crosses base_position, which is why they share every colour.
func _pinned_offset(r: float, st: String) -> float:
	if st == "wait_positive":
		return r
	if st == "wait_negative":
		return -r
	return 0.0


## The pinned instant, as a phase. The WAIT states are pinned at the END of the wait —
## the moment of maximum saturation, and the one that makes the history degenerate.
func _pinned_phase(r: float, st: String) -> float:
	var tr: float = _ramp_seconds(r)
	if st == "wait_positive":
		return tr + WAIT_TIME
	if st == "moving_negative":
		return tr * 1.5 + WAIT_TIME
	if st == "wait_negative":
		return _period(r)
	return tr * 0.5


func _offset_at(ph: float, r: float) -> float:
	var tr: float = _ramp_seconds(r)
	var p: float = fposmod(ph, _period(r))
	if p < tr:
		return -r + TRAVEL_SPEED * p
	if p < tr + WAIT_TIME:
		return r
	if p < 2.0 * tr + WAIT_TIME:
		return r - TRAVEL_SPEED * (p - tr - WAIT_TIME)
	return -r


## SPATIALISED HISTORY, DECLARED (law 5). The runtime shifts one array slot per RENDERED
## FRAME, which at 60 fps is 5 mm and is why the trail has never been seen. This ledger
## sets the step to travel_distance/3 = travel_distance/(trail_count-1), which is not a
## taste but THE ONLY STEP for which the four samples are a COMPLETE record of the
## current half-run: three steps back is exactly r/0.3 seconds, exactly r metres, exactly
## the instant the run began. So at moving_positive the samples are [0, -r/3, -2r/3, -r]
## and the oldest ghost sits precisely ON the red end marker; at moving_negative they
## mirror onto the green one. At either WAIT state the FSM's own clamp saturates them —
## at stride [+0.400, +0.400, +0.400, +0.300], and 0.100 < 0.075 + 0.0544, so all four
## are still inside the cube.
func _trail_history(r: float, st: String) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	var dt: float = (r / float(TRAIL_COUNT - 1)) / TRAVEL_SPEED
	var ph: float = _pinned_phase(r, st)
	out.append(_pinned_offset(r, st))
	for i in range(1, TRAIL_COUNT):
		out.append(_offset_at(ph - float(i) * dt, r))
	return out


## :457, character for character: 0.500 / 0.575 / 0.650 / 0.725. Note that maxf(count,1)
## in the divisor means no instance is ever 1.0 — the trail never reaches the cube's size.
func _ghost_scale(i: int) -> float:
	return 0.5 + float(i) / maxf(TRAIL_COUNT, 1) * 0.3


## :328, character for character: 0.10 / 0.15 / 0.20 / 0.25. Written and then DISCARDED —
## Grid.gdshader writes no ALPHA. Worse: :59-65 selects instanceColor as the BASE colour
## whenever its alpha < 0.99, so a visible ghost renders at full (0.3, 0.6, 1.0) —
## BRIGHTER than the cube's own (0.06, 0.12, 0.20) interior.
func _ghost_alpha(i: int) -> float:
	return 0.1 + (float(i) / maxf(TRAIL_COUNT, 1)) * 0.2


func _ghost_clears_cube(i: int, delta_m: float) -> bool:
	return absf(delta_m) > CUBE_SIZE * 0.5 * (1.0 + _ghost_scale(i))


## _update_color_feedback (:475-489), reproduced at the pinned instant.
##   moving_*        t = 0.5  -> wire (0.315, 0.645, 0.910), emission x1.5,  strength 0.7
##   wait_positive   t = 1.0  -> wire (0.330, 0.690, 0.820), emission x1.25, strength 0.5
##   wait_negative   t = 0.0  -> wire (0.300, 0.600, 1.000), emission x1.25, strength 0.5
func _feedback_wire(r: float, st: String) -> Color:
	var t: float = (_pinned_offset(r, st) / maxf(r, 0.0001) + 1.0) / 2.0
	var c: Color = _cube_color.lerp(Color(0.4, 0.9, 0.4), t * 0.3)
	return c


func _is_moving() -> bool:
	return state == "moving_positive" or state == "moving_negative"


func _feedback_intensity() -> float:
	return 1.0 if _is_moving() else 0.5


# ═══════════════════════════════════════════════════════════════════════════════
# THE BUILD — five bays, 1:1 with the source, no rack, no slat, no pad, no gauge
# ═══════════════════════════════════════════════════════════════════════════════

func _build() -> void:
	_n_mesh = 0
	_n_label = 0
	_n_multimesh = 0
	_row = Node3D.new()
	_row.name = "Ledger"
	add_child(_row)

	_add_anchor()
	_add_datum()
	for i in _accounts.size():
		_build_bay(i, String(_accounts[i]))
	_built = true


## LAW 11, and it is required twice over: `reach` changes every bay's vertical extent by
## 8x (0.95 m at stride, 0.25 m at nudge) and would otherwise make the sheet a picture of
## a zoom (the source's own TravelAnchor argument, :663-670, extended to the row); and
## bay 1's trail is a MultiMeshInstance3D, invisible to the capture AABB, so bay 1 would
## otherwise contribute only its cube. ONE anchor, not five, so the union AABB is an
## authored box rather than an emergent sum.
func _add_anchor() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "LedgerAnchor"
	var box := BoxMesh.new()
	box.size = Vector3(ROW_W, ROW_H, ROW_D)
	mi.mesh = box
	mi.position = Vector3(0.0, BASE_Y, ROW_CZ)
	mi.layers = 0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_row.add_child(mi)
	_n_mesh += 1


## The source's own base_position — the offset-zero plane — made visible across five bays
## and placed BEHIND everything, so it occludes nothing. The rail's grey, opaque.
func _add_datum() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Datum"
	var box := BoxMesh.new()
	box.size = Vector3(ROW_W, DATUM_T, DATUM_T)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.6, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.2
	mi.material_override = mat
	mi.position = Vector3(0.0, BASE_Y, DATUM_Z)
	_row.add_child(mi)
	_n_mesh += 1


func _build_bay(index: int, word: String) -> void:
	var bay := Node3D.new()
	bay.name = "Bay_%d_%s" % [index, word]
	_row.add_child(bay)

	var base := Vector3((float(index) - 2.0) * BAY_PITCH, BASE_Y, 0.0)
	var r: float = _reach_metres()

	_add_name_plate(bay, base, word)

	match word:
		"ghost":
			_account_ghost(bay, base, r)
		"sweep":
			_account_sweep(bay, base, r)
		"terminus":
			_account_terminus(bay, base, r)
		"formula":
			_account_formula(bay, base, r)
		"none":
			pass                                  # the result only — nothing to add
		_:
			push_error("passage_ledger: unknown account '%s' in ACCOUNTS" % word)

	# The two legacy Label3Ds the code never gates by account. Only `none` clears them
	# (:157-160), which is why they survive in the formula bay too.
	if word != "none":
		_legacy_labels(bay, base, r)

	# LAST. At the two wait states bay 3's live cube is COINCIDENT with one terminus cube
	# (identical transforms, :410 and :619) — determinism comes from draw order, never
	# from a fudge offset.
	_add_live_cube(bay, base, r)


# ── the cube, in every bay ────────────────────────────────────────────────────

func _add_live_cube(bay: Node3D, base: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Cube"
	var box := BoxMesh.new()
	box.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	mi.mesh = box

	var wire: Color = _feedback_wire(r, state)
	var mat := ShaderMaterial.new()
	mat.shader = GRID_SHADER
	mat.set_shader_parameter("modelColor", _cube_color * 0.2)
	mat.set_shader_parameter("wireframeColor", wire)
	mat.set_shader_parameter("emissionColor", wire * (1.0 + _feedback_intensity() * 0.5))
	mat.set_shader_parameter("width", 3.0)
	mat.set_shader_parameter("blur", 0.5)
	mat.set_shader_parameter("emission_strength", 0.3 + _feedback_intensity() * 0.4)
	# show_interior is DEAD (Grid.gdshader:70-76 runs the identical mix() in both
	# branches). Set anyway, because the source sets it and this is the source's body.
	mat.set_shader_parameter("show_interior", true)
	mi.material_override = mat

	# The shader draws BARYCENTRIC triangle edges, so every quad face carries its
	# diagonal. That diagonal is the family's signature at a glance.
	mi.position = base + Vector3.UP * _pinned_offset(r, state)
	bay.add_child(mi)
	_n_mesh += 1


# ── BAY 1 — ghost: the un-subtracted whole ────────────────────────────────────

func _account_ghost(bay: Node3D, base: Vector3, r: float) -> void:
	# THE RAIL (:193-220). The only genuinely translucent surface in the whole family,
	# and a 2.7 px hairline at the worst bay — a 16 mm thread beside a 150 mm cube, in
	# the source too. Not load-bearing.
	var rail := MeshInstance3D.new()
	rail.name = "Rail"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.height = r * 2.0 + CUBE_SIZE
	rail.mesh = cyl
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.4, 0.5, 0.6, 0.6)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.emission_enabled = true
	rmat.emission = Color(0.3, 0.5, 0.7)
	rmat.emission_energy_multiplier = 0.2
	rail.material_override = rmat
	rail.position = base + Vector3(CUBE_SIZE * 0.7, 0.0, 0.0)   # :214
	bay.add_child(rail)
	_n_mesh += 1

	# THE TWO END MARKERS (:223-244, :247-261). Green at +r, red at -r, 6.8 px across at
	# the worst bay — under the ~10 px floor, declared secondary. At wait_positive the
	# cube sits ON the green one and swallows it; at wait_negative, the red one.
	_marker(bay, base + Vector3(CUBE_SIZE * 0.7, r, 0.0), Color(0.3, 0.8, 0.4), "MarkerPositive")
	_marker(bay, base + Vector3(CUBE_SIZE * 0.7, -r, 0.0), Color(0.8, 0.4, 0.3), "MarkerNegative")

	# THE TRAIL (:306-352, :446-461), spatialised.
	var hist: PackedFloat32Array = _trail_history(r, state)
	var box := BoxMesh.new()
	box.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = box
	mm.instance_count = TRAIL_COUNT
	for i in TRAIL_COUNT:
		var s: float = _ghost_scale(i)
		var xf := Transform3D()
		xf = xf.scaled(Vector3(s, s, s))
		xf.origin = base + Vector3.UP * hist[i]
		mm.set_instance_transform(i, xf)
		mm.set_instance_color(i, Color(_cube_color.r, _cube_color.g, _cube_color.b, _ghost_alpha(i)))

	var tmat := ShaderMaterial.new()
	tmat.shader = GRID_SHADER
	tmat.set_shader_parameter("modelColor", Color(
		_cube_color.r * 0.2, _cube_color.g * 0.2, _cube_color.b * 0.2, 0.15))
	tmat.set_shader_parameter("wireframeColor", Color(
		_cube_color.r, _cube_color.g, _cube_color.b, 0.2))
	tmat.set_shader_parameter("emissionColor", Color(
		_cube_color.r, _cube_color.g, _cube_color.b, 0.1))
	tmat.set_shader_parameter("width", 2.0)
	tmat.set_shader_parameter("blur", 0.6)
	tmat.set_shader_parameter("emission_strength", 0.2)
	tmat.set_shader_parameter("show_interior", false)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Trail"
	mmi.multimesh = mm
	mmi.material_override = tmat
	bay.add_child(mmi)
	_n_multimesh += 1


func _marker(bay: Node3D, at: Vector3, color: Color, nm: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sph := SphereMesh.new()
	sph.radius = 0.02
	sph.height = 0.04
	mi.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	mi.position = at
	bay.add_child(mi)
	_n_mesh += 1


# ── BAY 2 — sweep: the path as a solid ────────────────────────────────────────

## :585-610. thin = cube_size * 0.62 = 0.093, NARROWER than the cube, so the bar runs
## THROUGH it and the cube reads as a capital on a column — exactly as in the existing
## sheet. modelColor is * 0.18 here, not * 0.2 (law 2 correction 2).
func _account_sweep(bay: Node3D, base: Vector3, r: float) -> void:
	var span: float = r * 2.0 + CUBE_SIZE
	var thin: float = CUBE_SIZE * 0.62
	var mi := MeshInstance3D.new()
	mi.name = "SweepBar"
	var box := BoxMesh.new()
	box.size = Vector3(thin, span, thin)
	mi.mesh = box
	var mat := ShaderMaterial.new()
	mat.shader = GRID_SHADER
	mat.set_shader_parameter("modelColor", Color(
		_cube_color.r * 0.18, _cube_color.g * 0.18, _cube_color.b * 0.18, 0.35))
	mat.set_shader_parameter("wireframeColor", Color(
		_cube_color.r, _cube_color.g, _cube_color.b, 0.85))
	mat.set_shader_parameter("emissionColor", _cube_color * 0.8)
	mat.set_shader_parameter("width", 2.5)
	mat.set_shader_parameter("blur", 0.5)
	mat.set_shader_parameter("emission_strength", 0.3)
	mat.set_shader_parameter("show_interior", false)
	mi.material_override = mat
	mi.position = base
	bay.add_child(mi)
	_n_mesh += 1


# ── BAY 3 — terminus: before and after, nothing between ───────────────────────

## :616-637. THREE cubes stand here, not two: the code never removes the live one and
## never stops it (:373-378, :408-410). At the two wait states the live cube is
## COINCIDENT with one of these, so the bay photographs as two — terminus is true exactly
## twice per 7.333 s period, and at those instants the moving object disappears into the
## claim.
func _account_terminus(bay: Node3D, base: Vector3, r: float) -> void:
	var offset: Vector3 = Vector3.UP * r
	_terminus_cube(bay, base - offset, 0.12, "TerminusBefore")
	_terminus_cube(bay, base + offset, 0.9, "TerminusAfter")


func _terminus_cube(bay: Node3D, at: Vector3, energy: float, nm: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var box := BoxMesh.new()
	box.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(_cube_color.r, _cube_color.g, _cube_color.b, 1.0)
	mat.roughness = 0.45
	mat.emission_enabled = true
	mat.emission = _cube_color
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	mi.position = at
	bay.add_child(mi)
	_n_mesh += 1


# ── BAY 4 — formula: the operation written out instead of drawn ───────────────

## :642-660. Its whole body is text — the ONE bay a still can hold completely — and it is
## the only mark in the ledger whose SIZE is invariant under `reach`: the plate is
## 0.66-0.76 x 0.14 m at every value, it only slides 0.19 m (y = base + r*0.55) and four
## characters change. The algebra is scale-free because it is a rule.
func _account_formula(bay: Node3D, base: Vector3, r: float) -> void:
	var letter: String = _axis_letter.to_lower()
	var plate := Label3D.new()
	plate.name = "FormulaPlate"
	plate.pixel_size = 0.0011
	plate.font_size = 64
	plate.outline_size = 8
	# Deliberately ASCII in the source, and kept so: an algebra glyph that falls back to a
	# box is not the operation written out.
	plate.text = "p'.%s = p.%s + d\nd = -%.2f .. +%.2f" % [letter, letter, r, r]
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.modulate = Color(0.72, 0.88, 1.0)
	plate.position = base + Vector3(0.0, r * 0.55, CUBE_SIZE * 1.2)
	bay.add_child(plate)
	_n_label += 1


# ── the legacy labels, in four of five bays ───────────────────────────────────

## :264-303, minus the hidden formula label (:282-293, visible = false, draws nothing).
## The readout is the WIDEST TENANT of bays 1-3 — wider than any geometry in them — which
## is what sets the row's pitch alongside the formula plate.
func _legacy_labels(bay: Node3D, base: Vector3, r: float) -> void:
	var readout := Label3D.new()
	readout.name = "Readout"
	readout.pixel_size = 0.001
	readout.font_size = 56
	readout.outline_size = 6
	readout.text = "%s = %.3f\n%s" % [
		_axis_letter.to_lower(), _pinned_offset(r, state), _direction_word()
	]
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	readout.position = base + Vector3(-CUBE_SIZE * 1.5, r + 0.15, 0.0)
	readout.modulate = Color(0.8, 0.9, 1.0)
	bay.add_child(readout)
	_n_label += 1

	var axis_label := Label3D.new()
	axis_label.name = "AxisLabel"
	axis_label.pixel_size = 0.001
	axis_label.font_size = 48
	axis_label.text = "%s-axis" % _axis_letter
	axis_label.position = base + Vector3(CUBE_SIZE * 1.0, r * 0.5, 0.0)
	axis_label.modulate = _cube_color
	bay.add_child(axis_label)
	_n_label += 1


## _get_direction_name (:429-443), read off the source. Both WAIT states return the
## IDENTICAL word, so the live readout cannot tell them apart — only the sign of the
## number can (law 2 correction 3).
func _direction_word() -> String:
	var i: int = STATES.find(state)
	if i < 0 or i >= _dir_words.size():
		return ""
	return _dir_words[i]


# ── ledger furniture ──────────────────────────────────────────────────────────

## The account word, verbatim from ACCOUNTS. No plinth, no case, no rack, no gauge, no
## shared scale bar — the bay carries the body, not a reading of it.
func _add_name_plate(bay: Node3D, base: Vector3, word: String) -> void:
	var plate := Label3D.new()
	plate.name = "Name"
	plate.pixel_size = 0.001
	plate.font_size = NAME_FONT
	plate.text = word
	plate.modulate = Color(0.8, 0.9, 1.0)
	plate.position = Vector3(base.x, NAME_Y, 0.0)
	bay.add_child(plate)
	_n_label += 1


# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

## Read on the way IN, before _ready builds, so the ledger is built once in the right
## form instead of built and torn down. GridInteractablesComponent stamps this metadata
## on the instantiated root before it calls apply_grid_config.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_state"):
			_choose_state(str(node.get_meta("config_state")))
		if node.has_meta("config_reach"):
			_choose_reach(str(node.get_meta("config_reach")))
		node = node.get_parent()


func _choose_state(raw: String) -> void:
	var w: String = raw.strip_edges().to_lower()
	if STATES.has(w):
		state = w
	else:
		push_warning("passage_ledger: unknown state '%s' — keeping '%s'" % [raw, state])


func _choose_reach(raw: String) -> void:
	var w: String = raw.strip_edges().to_lower()
	if REACHES.has(w):
		reach = w
	else:
		push_warning("passage_ledger: unknown reach '%s' — keeping '%s'" % [raw, reach])


## GUARDED ON CHANGE. The grid reaches this twice for one placement, and a placement
## carrying any other token arrives with neither key; an unguarded rebuild would tear the
## ledger down and raise it again on both, for nothing.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	var was_state: String = state
	var was_reach: String = reach
	if config_data.has("state"):
		_choose_state(str(config_data["state"]))
	if config_data.has("reach"):
		_choose_reach(str(config_data["reach"]))
	if _built and (state != was_state or reach != was_reach):
		_rebuild()


func _rebuild() -> void:
	if _row != null:
		remove_child(_row)
		_row.queue_free()
		_row = null
	_built = false
	_build()
	_check_ghost_census()
	_check_element_budget()
