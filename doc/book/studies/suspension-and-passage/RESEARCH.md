# From a suspended grid to a route

## Anchor and departure

Mona Hatoum's **Remains to be Seen (2019)** is the central work. The supplied earlier photograph shows the same kind of concrete-and-rebar suspension. [White Cube](https://www.whitecube.com/gallery-exhibitions/remains-to-be-seen) documents a cubic grid of steel reinforcement and concrete-like flooring fragments, making the absent whole of a building imaginable. [PODO Museum](https://en.podomuseum.com/mona-hatoum) lists concrete and steel reinforcement bars and dimensions of 528 × 530 × 530 cm. The gallery account is our primary reading; the exact source of the user's particular photograph has not been established.

The previous project companion varied the shapes of 75 generated fragments at fixed positions. It had no fragment collision. Repetition was visible, but the claim about bodily access was not yet something that scene could test.

The new study takes one relation further: preserve horizontal sites and the inventory of heights, but change how the raised places connect. Forty-nine individually seeded fragments occupy a 7 × 7 field. Each address keeps its mesh. Seven centres sit at 3.10 m; forty-two sit at 1.15 m. Horizontal spacing is 0.84 m. The hand-made irregularity suggested by the reference is represented by an explicit seeded corner variation, not a fracture history.

The learner edits the selection in `score.gd`. One rule raises column three in every row. Another raises column `(2*z) % 7`. Both retain one raised fragment per row. No random draw is involved in that comparison.

## What the test found

The 0.56 m wide, 1.75 m tall walking capsule crosses the first arrangement. The same straight movement meets an actual collider in the second. A separate sampled search finds a north-to-south crossing in the first field and none in the second, within a declared 5.88 m square at 14 cm sampling. Every accepted search edge is swept against the real physics shapes. This is a finite test with stated bounds, not a proof about every continuous route.

Keeping the first arrangement and changing the capsule width to 1.32 m also stops the direct crossing; the sampled search finds no crossing for that body. The wider capsule is a probe, not an accessibility standard or a substitute for bodies with differing posture, movement or assistance. The perimeter of the sculpture remains passable. The room has not become a compulsory trap.

**Equal counts and an identical height inventory do not determine access.** Arrangement matters; the chosen visitor matters too. The array preserves an address, while the physical test asks whether one opening actually continues into the next.

## What the translation cannot carry by itself

The computer fragments have no former building, location or violence in their material history. Their procedural seed is provenance for a mesh, not provenance for rubble. A convincing concrete shader does not close that distance. The source work's material and historical associations must remain named alongside our narrower experiment.

The queer question here is about a presumed fit: the scene's default body is a design decision. “Open” is tested against that decision. Changing the declared body does not make the second body wrong; it changes what the room must allow. This is our interpretation of the experiment, not an attributed statement by Hatoum.

The reference also troubles the easy promise that repetition makes order stable. Here the array is exact and the fragments do not fall. That stability is supplied by our engine arrangement. No simulation has demonstrated a safe real suspension.

## Apparatus and inherited choices

- The fragment generator and fabrication helpers are reused from `reference_studies`; those shared files are unchanged. The new study uses greater corner variation and a quieter procedural stone shader. No texture or model was downloaded.
- Fragments are `StaticBody3D` obstacles with convex hulls derived from their displayed vertices. The hull can fill small nonconvex recesses. The short rebar has a cylindrical collider; fine ribs and thin cables are visual only. This is a declared contact approximation.
- Suspension lengths adjust when a preset changes. There is no weight, swinging, breaking, tension solver or gravity settling. The switch replaces an arrangement immediately.
- The body is an upright capsule with gravity and an ordinary sliding movement controller. There is no jumping or crouching. State edits leave walking mode before relocating the obstacles, avoiding an overlap with the current visitor position.
- The studio shell receives directional light without casting its own shadows. Sculpture shadows remain enabled. The camera and lighting are shared between each visual comparison.
- The seven raised cells may be exchanged in the viewer. This preserves the height count but does not enforce a connected route. A visitor can author an arrangement that does not admit them.

## Evidence and next question

The report contains **27 passing native Godot 4.6 desktop checks**, six captures, the two full height states and the bounded route results. Tests cover retained geometry and sites, equal height inventories, actual movement and floor support, the perimeter route, width-dependent blocking, real GUI input, exchange/reset and leaving walking before edits. The final native run reports no errors.

No installed-museum, headset, performance-budget or learner trial is claimed. The next useful test is whether someone can predict and then author a passage from the seven selected addresses without being shown its solution. That would test the teaching claim. Adding more fragments would not.
