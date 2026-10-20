# What keeps a pattern changing? — implementation

## Installed hall

Primary source: `commons/artifacts/turing_pattern_generator/turing_pattern_generator.gd`. It uses two old and two spare arrays, a weighted eight-neighbour Laplacian (axial 0.2, diagonal 0.05, centre −1), Du 0.16, Dv 0.08, explicit dt 1 and a 0–1 clamp. The hall selects resolution 32, centre seeding and pattern_seed 1337. Centre seeding constructs a **6 × 6 square: 36 cells**, not the twelve stated in the earlier prose. The default rates are feed 0.055 and kill 0.062. Preset names are parameter labels, not guaranteed visual outcomes.

The existing hall adapter holds this model: auto_run=false and processing disabled, while its six controls explicitly step and update the texture. STEP, 100 STEPS, REGIME, SEEDING, RESET and RULE were operated through the real desktop pointer. REGIME resets the state with another rate pair; SEEDING selects another initial arrangement. Local artifact sliders have their own existing behaviour and should not be confused with the desk's reset contract.

The desk moves from (15,3) to (8,6), beside the field at (8,9), clearing arrival. A museum-only ReactionWall in soft_workshop.gd adds a 3.7m upright QuadMesh using the **same live ImageTexture** as the table. Its material is unshaded with nearest filtering; it adds no second simulation. A solid frame, uprights, tabletop support and local fill light stage the display. The original field algorithm, other running reaction-diffusion implementation, other five placements and sequence order stay unchanged.

The final native wall image is the installed Stripes preset (feed 0.042, kill 0.059), centre seed, after ten actual 100-step button presses. It is not the startup image, a different model or a generated illustration. Starting state and step count remain available through reset/readout. The second reaction-diffusion exhibit runs on its own clock and is not a paired control.

## Learner lineage

Source: `doc/book/studies/soft-bodies-through-the-hands/ProceduralGeneration_Reaction_Diffusion_Systems/`.

The learner returns to CA_SoftRules' Field and two-table host. The four-neighbour stencil, starting square, old/next update, coefficients and wrapped indices are carried. next_pair now separates conversion, supply and removal by name; local_terms toggles their contribution. Both copies retain exchange. A enables all terms; B initially exchanges only. C changes B's local-term switch and resets both fields; R restores initial arrays without changing that switch. Both advance by equal explicit steps, capped at 2,400. Enter/Space/C/R/V/I are the declared keyboard controls; XRTools/desktop pickup provides planting through the carried point.

The witness W moves from the CA boundary address (12,15) to the uniform interior (15,15). Its first step isolates the local terms: A becomes (0.48725,0.257); B remains (0.5,0.25). At B's boundary, diffusion still changes values. The independent FEED 0.050 edit predicts (0.49375,0.25375) in A and leaves B's local first step unchanged. The learner's feed/kill defaults are 0.037/0.060; these and its stencil differ from the installed artifact. No numerical identity between those implementations is claimed.

The default complete learner matched the earlier CA model exactly at 100 steps (maximum array difference 0.0). PointBody is byte-identical to both that CA lesson and the immediately preceding Affect lesson. The display and seeding host is carried with changed labels, witness and comparison switch. Full source is printed in tutorial.md; no undeclared child reference is required. A temporarily mounted host at map-local (15,0,18), yaw180, demonstrates the actual code in the museum.

## Validation

33 executable code checks passed: analytical local values, indexing/wrapping, uniform fixed point, diffusion, synchronous traversal, prior model parity, exact texture values, input dispatch, replay, synthetic XRTools targeting in a translated/rotated host, shared planting, release, and the independent feed edit. Four executing fault programs were caught: wrong conversion sign, missing supply, in-place updates and a replay that resets only the clock. GPU texture inspection uses native OpenGL; the headless dummy renderer cannot validate texture uploads. The test creates the rotated host before adding rigid bodies, as the museum fixture does.

38 native museum checks passed, including six desk controls and rule-card closure, live wall linkage, ten batches, held idle state, exact learner at 1 and 1,000 steps, identical restored fields, the independent edit and a supported outer route. The route is checked at 345 sample positions, turning toward the centre at z60 and ending inside the exit at z62.5. It does not claim all paths or portal transitions were tested.

Existing UID, material and renderer warnings remain; no script/parse errors in final runs. Physical headset comfort, Quest frame time and an independent human student's understanding remain untested. Assertions validate program claims, not the analogy between chemical persistence and living bodies.

Reproduce with `python tools/test_reaction_lesson.py` and `python tools/run_encounter_probe.py ProceduralGeneration_Reaction_Diffusion_Systems --sequence softbodies --render --no-bridges --output-tag reaction-final --probe tools/probes/reaction_room.gd`. Report: `doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern/`.
