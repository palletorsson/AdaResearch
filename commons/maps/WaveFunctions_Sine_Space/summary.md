# Sine Space — What a wave can hold

Two primary encounters carry the book, in walking order: `sine_flow_tray`, then `sine_wall_corridor`.

The 14 by 36 map adds a six-row forecourt. A contact tray at (3,4), rotated 180 degrees, has a side desk facing the central approach. RELEASE creates 32 spheres; RELIEF selects 0.12, 0.30 or 0.55 m peak-to-trough height; SIZE selects radius 45, 75 or 105 mm at fixed mass 0.1 kg; RESET restores relief 0.30 m and radius 75 mm; RULE reveals the sampled sine and collision construction. Every release has a twelve-second observation counter. Outlet, still in and other exit are distinct counts. Exited bodies move to a collection display and stop colliding. All bodies freeze at the deadline.

The original hall is shifted six rows as a unit. Its seven-metre corridor now sits at (6,10), rotated 90 degrees. The west mouth, entrance controls and east mouth retain their relationship to the bridge at x=10. AMP changes wall amplitude, PHASE the relative offset, FREEZE the running phase, and RESET the declared settings. At half-turn offset the two walls bend together with a constant 2 m separation along local X, which does not claim constant shortest clearance around a bend.

The corridor walls have no collision; the thin floor slab supplies support. The forecourt tray has a collision shape made from the same sampled mesh that is drawn. A stationary contact surface and a moving visible passage make different possibilities available to a body. Neither their visual similarity nor their shared sine operation settles what each does.

The `sine_wall_explanation` case remains in the west nook at (1,7). The older `sine_space` field at (9,22) and `dark_sphere` at (9,20) remain in the basin below the bridge. The removed explanation case and colorballs are not current placements.

The museum's current effective route places this third in Wavefunctions, after Pendulum and before Effect Sound. Sequence-source lists contain additional maps; no route reorder is part of this change. The return to physical landscapes across Randomness, Noise and machine learning is a research thread, not a claim that those later receivers have already been tested.

Desktop museum placement, controls and sample/body accounting are checked by `commons/testing/probe_sine_flow_hall.gd`; corridor regression uses `probe_wcn_sine_space.gd` and its generated live port. These distinguish synthetic desktop input from tracked-hand and headset experience, which remain unverified.


## Measured (2026-09-13)

At every setting the panel can reach, the two walls never come closer than 0.725 m. A visitor's body walks the whole passage at that narrowest setting and touches nothing but floor. Dragging the sliders changes the walls you see and leaves no hidden collider behind. PHASE moves only the right wall, because the offset is that wall's alone. Keeping the walls moving costs the computer a noticeable share of each frame, which may matter in a headset and has not yet been tried there.
