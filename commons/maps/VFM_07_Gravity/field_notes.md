# VFM_07_Gravity — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The first bench room written

The triage rated it GOOD: the tutorial runs attract → inverse-square → orbit →
third body → well → force-directed layout, one to one onto the placed
stations, with only `chaos_attractor` outside the code and reached by the
three-body beat. The blurb is four words and the intent two lines; the room's
argument lives in its tutorial and its plinths, and the text is built from
those.

## Exactness decisions

- **"No formula exists" is made exact.** Sundman's series (1912) is a
  convergent solution to the three-body problem that is useless in practice.
  The text says: "There is a series, a century old, that converges so slowly it
  is useless for anything, and so in practice there is only simulation." The
  KEEP line's force survives and the claim is true.
- **Prediction dying is a number.** `probe_gravity_tutorial.gd` nudges one
  body by 1e-6 and integrates two bodies and three side by side; the three-body
  separation must be at least 1000× the two-body one. Measured: two bodies
  drift 2.6e-5 over 12 time units, three bodies 13.1, a ratio of 510,190. The
  first draft said "grows by thousands", which undersold it by two orders of
  magnitude; the text now says "a few millionths" against "metres, half a
  million times as far".
- **Escape is √2 × circular**, and the probe integrates it: at 0.6 v_circ the
  satellite falls in, at 1.05 v_esc it is still receding at a distance of
  many radii. The text: "the orbit that never returns has a number, and it is
  not far above the circular one: the square root of two times it."
- **The tutorial's `attract` uses a `Body` class it never defines.** Quoted as
  the tutorial wrote it; the probe carries a pure version of the same
  arithmetic. The clamp gets its own beat: "where the machine stops trusting
  itself."
- **The Lorenz attractor is not gravity.** `chaos_attractor` defaults to
  LORENZ, 8000 points. The text says so: "a different system, the one Lorenz
  found in the weather, but it has the same property."
- **The well is a potential, not a force**, and the text says the slope is the
  force and the height what the slope has cost you.
- **The n-body cost is O(n²)** by the artifact's own description (Barnes-Hut
  as the consequence), tied to the law's own square.
- **The probe fell into `%e` a second time.** GDScript has no `%e`; the line
  printed raw and the numbers were skipped while the assert still passed. The
  Act IVb probe carries a comment about exactly this. Now a memory.
- Physical claims from the artifacts: the grabbable attractor whose orbit
  reshapes; twenty bodies from a cloud; the three-body configurations
  (figure_eight, lagrange as "the two famous exceptions"); coloured test
  particles on the deformable grid; repulsion k/r² on all pairs and springs on
  edges only.

## Continuity

The barycenter from Act IVa ("you stood on that point in the park"); the
springs from Act IVb inside the force-directed layout; simulation as "the
machine inventing the between" from Point_Trace, here with no formula to check
it against; graph theory "eleven chapters ahead."

## Open

- The blurb (`Attraction at every scale.`) and intent are thin against the
  room; they could be regenerated from this text.
