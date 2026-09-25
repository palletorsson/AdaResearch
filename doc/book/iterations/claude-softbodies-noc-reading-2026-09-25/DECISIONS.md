# softbodies (+ formfinding) × Nature of Code ch. 6 — applied 25 September 2026

Reading: `doc/book/readings/NOC_softbodies_2026-09-25.md`. Tasks `book_softbodies.015`–`.022` and `book_formfinding.019`–`.020`, all applied here and closed. Palle: "commit and apply" (10:35).

| task | hall | what landed |
|---|---|---|
| .015 | Soft_Body_Deformation | STIFFNESS as a fraction between nought and one, the solver's five passes a tick, the bench in Form Finding; footnote `[^stiffness]` |
| .016 | Soft_Body_Deformation | what holds the cube together: the skin's edges, and pressure in place of internal struts; PRESSURE to nothing drapes it like cloth |
| .017 | Soft_Body_Deformation | the hand is the one body the solver cannot argue with; the cube meets it as a collider, the rounded body as a push |
| .018 | Carusell | the joints named as hinges; the hub as the body the solver may not push |
| .019 | Cloth_Physics | what ties the 112 points: across, down and one diagonal |
| .020 | Playground_of_Joy | the vessel returns from Form Finding |
| .021 | Affect_Theory_Visualization | put a hand to a spike: a drawing and a physics can disagree without anyone being told |
| .022 | Obsticals_Part2 | the solver's finite effort has a number; footnote `[^effort]` |
| form .019 | FormFinding_Relaxation | Jakobsen (2001) added to the Verlet footnote |
| form .020 | FormFinding_Catenary | the bench next door could hang the chain the cable only draws |

Verification: every footnote reference has a definition; endings preserved; no code changed. The claims about the engine come from the artifacts' own settings (`jelly_cube.gd:186-201`, `cloth_straps.gd:351-360`, `breathing_room.gd:81-85`, `revolving_joy_ride.gd:99-103, 140-153, 291-293`, `rounded_softbody.gd:136-141`) and Godot's SoftBody3D reference (`linear_stiffness` 0..1, `simulation_precision` default 5). Task .021's gesture rests on `radiolaria.gd` building no collider and the museum treating a body without one as a venue; a walk into a radiolarian in the desktop lane remains for whoever walks it.

Disclosure: all eight files carried uncommitted hunks from another writer (Codex's applications, last touched 08:31–08:37 today, idle since; forum 260925-0vmbf). `before/` is the tree as found; the commit lands the files whole.
