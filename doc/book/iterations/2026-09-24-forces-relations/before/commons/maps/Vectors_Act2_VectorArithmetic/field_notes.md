# Vectors_Act2_VectorArithmetic — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Why nothing needed rewriting

The triage rated this GOOD and it was right: the nine tutorial blocks map one
to one onto the placed hand/room pairs, and the eight `sub:` cells carry one
truth per station. The text follows the subtitles' own beats and closes on the
room's reflection line, which is the KEEP: *to add is to walk; to dot is to
agree; to cross is to turn.* The tutorial was left as it is.

## Exactness decisions

- **Every quoted function is probed** (`probe_act2_tutorial.gd`, seven
  checks): the walk closes at a + b; the difference is the arrow from b's tip
  to a's; a scalar keeps the line and scales the length by the mass ratio;
  agreement is 1 / 0 / −1 for same / square / opposed and `angle_between`
  gives 90; projection plus rejection adds back exactly and the rejection is
  square to the rail; a push along the arm gives zero torque and across it
  gives |r||F|; and the room's best line is proven as a number: |r × F| equals
  |r| times what is left of F after `wasted_half` is removed, so dot and cross
  are "one question asked in opposite directions."
- **The aligner's lock is a number.** `LOCK_DOT := 0.985` in `dot_aligner.gd`;
  acos(0.985) is 9.9°, so the text says "within ten degrees."
- **The gravity ladder is 0.5, 1.5, 3.0 kg** (`MASS_LADDER`), and the text says
  the arrows differ "in exactly the ratio of the masses."
- **Physical claims were read from the artifacts**: the two pads and the
  cyan/amber/green arrows of the consoles; the ghost of +b on `vector_sub`; the
  3 m walk-in grid at 0.5 m; the turret, the drifting cube and the red-to-green
  conversion; the sun, rail and shadow; the hinge gadget; the flywheel and the
  gold axle arrow; the paddle wheel and the right-hand rule; the laser-grabbed
  pair at the far end, which the text gives one beat as a third scale.

## Continuity

The cross product was used in Point_Triangle_Context to light a face ("two
edges out of a corner, crossed"); the text says so: "you have used it before
without being told." The nine point eight from `weight_of` is called "the one
scalar you have been carrying since you arrived."

## On trigonometry

This room names cos θ, sin θ and `acos`, and so do its own subtitles
(`truth_dot`: a·b = |a||b|cos θ). The rule that keeps the angle implicit was
Palle's for the primitives chapter; forces is the fifth sequence and the
room's material already speaks in these terms, so the text does too, while
leading with "agreement" as the word and giving the cosine as what agreement
costs.

## Open

- `vector_addition_walk` and the three `_xl` exhibits are ~5 m footprints
  placed as single cells; the plan's LIVE_OVERSHOOT handles the venue, and
  nothing in the text depends on where the overshoot lands.
