# Trans_Pre — field notes

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
