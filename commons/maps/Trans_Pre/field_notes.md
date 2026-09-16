# Trans_Pre — field notes

## Principle markers, 2026-09-09

The first cube is now centred at (4,2). At (4,5), (4,8), (4,11), secondary Y-translation, rotation and uniform-scale markers stand two metres beside the cumulative pickup demonstrations. Translation and rotation reuse existing artifacts; uniform_scale_marker adds a compact animated cube, fixed reference cage and live factor. The book keeps one primary pickup passage and describes the markers within it. The physical probe now passes 76 checks, including all three marker placements and scale-factor limits.


## Current ruling: build the pickup, then a small level

Palle replaced the paired-copy itinerary on 2026-09-09: inert cube, vertical oscillation, add rotation, add scale; then a wedge ramp and a platform with five cubes. The prior draft below is historical. Current intent and final.md follow this new order. The card, sphere and duplicate static comparisons have been removed from this hall.

The implementation reuses existing pickup modes and wedge utilities. Four demonstrations use hold:demo; the five platform cubes use motion:all and remain collectible. Physical ray measurements corrected the ascent to wp:0 at row 16 and descent to wp:180 at row 20. A capsule climbs to one metre, crosses and descends. Evidence: ada_run/trans_pre_build_up_checks.json (67 passing checks).

Point_Line_Grid receives simulation_grid at (15,7), inside a new side room occupying previously empty columns; existing trace artifacts and basin remain. The plan has 25 one-metre cells, a five-metre collider and indices 0-4. It is a floor for placement and walking, not another trace recorder. Museum capture confirms unit scale and collision at all 25 cells.

## Book trial — 2026-09-09

The current `final.md` follows the pickup cube family and the transformation card. Its opening question is “What would have to change for you to call it another cube?” Comparison precedes naming; code follows an observation; the paragraph returns to a consequence or a question. “You took a route. The difference between their positions contains no ramp.” is the first bridge back to the Primitives sequence.

Source inspection found that the old still comparisons had become default animated, collectible pickup cubes. The nine early placements now explicitly request `hold:demo` and `motion:still`. The four existing motion demonstrations and the last collectible retain their behaviours. Structure, utilities and artifact positions are unchanged from the staging snapshot. This is a deliberate configuration change after that snapshot, not a loss in the museum conversion.

The live GridSystem probe `commons/testing/probe_trans_pre_book.gd` passed 36 checks: fourteen cube instances, nine stable noncollectible comparisons, displacement (4,1,0), yaw difference 45 degrees, uniform factor 1.5, mesh-centre lift 0.25 m, separated animation channels, fixed pulse centre and scaling from saved size. It does not verify headset traversal, sightlines or a reader's understanding. Evidence: `ada_run/trans_pre_book_checks.json` and `ada_run/trans_pre_book.log`.

Use four provisional questions through the chapter: What changed? What persisted? What became possible between us? What remains after returning? Give each hall a particular encounter that can complicate one of these questions. Do not answer the whole chapter with preserved identity before testing its material.

Next actionable pass: Trans_Introduction. Test each transport cube's actual crossing, then write the change from watching an operation to depending on it. Keep the scale-target and carry-behaviour issues visible in the audit until measured or repaired.

The older notes below preserve the earlier design history; their Mario cube inventory and sightline claims are not current validation.

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The ruling

Palle, 2026-09-05, after the five transformation halls were rebuilt so that
every hole is the trace of a ride: *"in the first map in transformation
trans_pre Some time ago I also explained translation and scale with the mario
cube. By adding the difference first the cube, then translation, then rotation,
then scale. Something like Transformation_1 but improved, all stages."*

Transformation_1 in the 2025 repository (`G:\ada_2025\AdaResearch\commons\maps\Transformation_1`)
was a 7x10 "Cube Transformation Primer": on one row `cube_scene:0:0:0.2`,
`transformation_cube:0:0:0.2`, `rotating_cube:0:0:0.2`, `pick_up_cube:0:0:0.2`
and `clipboard#transformation_axioms`, with a `spin` and a `dark_sphere`, a
`wp` and a pick-up gate wanting one. Four different artifacts stood for four
ideas. This room uses ONE artifact for all of them and lets the map token carry
the difference.

## Exactness decisions

- **One artifact, five stages.** `mario_cube` alone at (4,2); the pairs at
  rows 4, 6, 8, 10: `mario_cube` at x2 beside `mario_cube` (translation),
  `mario_cube:45` (rotation), `mario_cube:0:0:1.5` (scale), `mario_cube:45:1:1.5`
  (rotation, a metre up, and scale). The token grammar is `token:rot:y:scale`,
  the same that places `x_translation_cube:180:1:2` in Trans_AxisDecomposition.
  Never write the y field as `0.0`: a float zero un-grounds the body.
- **The rainbow.** Every Mario cube raises a seven-band rainbow when reached
  (mario_cube.gd `_show_rainbow`, built at the moment of the crossing since
  2026-09-05). It also removes the nearest node named DarkSphere; this room has
  none, so the cube prints "No DarkSphere found" and raises the rainbow alone.
  The text says "once", which is `_activated`.
- **The card.** `clipboard:0:0#transformation_axioms:180:0:0.5` is Trans_Scale's
  clipboard token with the page swapped; the page is
  `commons/context/clipboard/tutorial_text/transformation_axioms.md`, one of
  the sequence's declared axiom files. It fades in by camera distance (2.0 to
  1.5 m), whether or not it is held.
- **No dark sphere, no pick-ups, no gate.** The primer is the differences at
  rest; the gate rule starts in Trans_Translation.
- The `3t` captions at x4 name each stage; the museum's door hall refuses `3t`
  and `an`, as it does everywhere, so in the museum the pairs stand uncaptioned
  and the card carries the words.

## Open

Nobody has walked the room. The museum hall is derived from the map by
`tools/em_map_halls.py` and needs its pearl baked; the book pearl "trans pre"
carries the lines.

## 2026-09-06 - the room learns to climb, and three lanes learn the map

Palle: *"for trans_pre I mean something like this"*, with the 2025 Route Field
map. Four layouts were drawn and each adversarially refuted before this one was
written; the winner was "the difference you climb", and its own skeptic's fixes
are in it: one pair per stage and never a triad, the rotation and scale pairs on
the same two columns so no accidental pair reads as a fifth stage, the climb as
the route rather than a spur, both members of a pair carrying the same token
shape so the two engines ground them alike, a dark_sphere on the highest ground
(ten cubes had been raising rainbows over nothing), and the card on the descent
so no row is spent on nothing.

**What the rebuild found in the engine, which is the larger half of the day.**
A hall whose chapter is map-authored is not built by the plan lane. It is built
by `_transplant_from_map` and `_stamp_map_utilities`, and neither had been
taught anything the plan lane knew:

- a `wp` in a map's utility layer was instantiated by hand, skipping
  `_stamp_wedge`, so the wedge entered neither the walk map nor the climb set:
  the way up was scenery and the level above it unreachable;
- `cell["top"]` was hardcoded 0, so a body on a raised floor stood a metre sunk
  in it;
- the token's fourth field, the scale, was dropped, so `mario_cube:0:0:1.5`
  stood the same size as its original. **The old flat room's scale stage was two
  identical cubes in the museum, and its composed stage a repeat of the rotation
  stage** - the primer has not taught its own lesson in the museum for as long
  as it has been in it;
- and a structure "2" was read as a plinth, which is right only under the legacy
  reading where a 2 is not floor; with heights it lifted the body a second metre.

All four are fixed, and the museum's own record now puts every body exactly
where the map says: the deck pair at 0.0, the plinth copy and the shelf pairs at
1.0, the summit original at 2.0, and the composed copy at 3.0 - two metres of
floor plus the metre its own token asks for.

**Left standing.** The captions are `3t` and the museum refuses them, so the
room is built to read without them: the inner wall gives stage one its silence,
the pairs rhyme down two columns, and the summit is the standpoint from which
every difference is one picture. The rainbows are still unmeasured with ten
cubes in one hall. Nobody has walked it in the headset.

## 2026-09-06 - the motion gallery

Palle: *"trans_pre we should show case motion transformation one pick up cube up
down oscillation one cube rotate, one cube scale oscillation, then combine them,
result this is how we a mario pick up cube, tutorial basic motion, get me"*.

The room gained a second half: a threshold wall with one door, three cubes in
single file each doing one motion, then the composition and the plain pick-up
cube side by side with the card between them. 11x21 became 11x27.

**The punchline had to be corrected before it could be built.** The proposal was
that the three composed IS the pick-up cube. It is not: `pick_up_cube.gd`
composes exactly two - `rotate_y` and a sine on y - and has no scale. A skeptic
caught it. What is true, and better, is what the room now says: the pick-up cube
does two of the three, and performs the third once, as its collection effect
tweens the mesh to 1.5x on the way out. So the last pair's difference is a
SUBTRACTION, the only one in the room: everything until then added a difference.

**The artifact.** `pick_up_cube` gained `motion` (idle / slide / turn / swell /
all / still), `pulse_scale` + `pulse_speed`, and `hold` (collect / demo). All
default-off: `motion: "idle"` writes nothing, so the 186 placements across 64
maps are untouched. `commons/testing/probe_pickup_motion.gd` measures each word
over half a second and asserts what moved.

**Why the motion is a WORD and not a rate.** The grid's config parser reads an
unlisted key with a float value as the tutorial shorthand
(`GridInteractablesComponent._parse_config_token`), so `#pulse_scale:0.3` is
swallowed there while working in the museum. A word-valued key takes the same
path in both engines. The numeric keys are read too, for a hand that wants an
exact rate, but they only reach the artifact in a museum hall until
`CONFIG_PARAM_NAMES` learns their names - **which also means the one existing
`#bob_height:0.0` in the corpus (Museum_AAA_Test_Cohort_10) is broken in the grid
today**, and so are five `#rotation_speed:` tails on other artifacts.

**The pulse writes the visuals, never the root.** The root's scale is already
spoken for by the token's fourth field, by the dress key and by the museum's own
stamp, so it scales `CubeBaseMesh` and the `DnaDressing` holder about the cube's
centre. The museum's seal is measured in the frame the body is added, before the
first pulse, so it seals the rest size - a 0.3 amplitude on a 0.5 m cube peaks at
0.65 m and still fits its cell.

**Left standing.** Nobody has walked it in the headset. The five pick-up cubes
are a second artifact family in a room whose notes say "one artifact, five
stages" - that is deliberate punctuation (the static half is the yellow mario
cube, the motion half the black wire pickup) but it is a change of voice worth
Palle's eye.
