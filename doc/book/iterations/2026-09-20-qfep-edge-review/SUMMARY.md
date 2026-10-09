# QFEP Edge of Chaos — the image and its calculation

Completed 20 September 2026. This pass develops the experiment already proposed by the manuscript, preserves its investigative voice and retains the surrounding artifact ecology.

## Finding and decision

The external review identified a material problem. The interactive Gray-Scott calculation used a raw four-neighbour Laplacian, dt=1 and concentration clipping. Its diffusion coefficients exceeded the explicit diffusion stability bound. The two endpoint presets used another operator and timestep. Comparisons between them could mistake numerical instability for a model regime. RESEED also always repeated the same seed.

Repair the experiment and let the reader investigate it. Do not cut the chapter's question because its evidence is missing. Keep the opening, model explanation, local feature comparison, coupled-parameter qualification, architectural recommendation discussion and exit to Sandbox.

## What changed

- Every tenure uses neighbour-average-minus-centre diffusion and an explicit step of 0.3. Concentrations are not clipped to the colour range; invalid negative or nonfinite results stop the calculation. The normalized operator divides effective diffusion by four relative to the old interactive model. This is an intentional model change as well as a timestep repair, stated in the technical note.
- This hall enables a pair: dt 0.3 and 0.15, or dt 0.15 and 0.075. Both fields receive the same seed and coefficients and reach the same elapsed model time. Their B-field RMS difference is displayed as one chosen observable.
- RESTART repeats the numbered seed; NEW SEED changes it. DT switches the step pair and restarts. HOLD / RUN pauses both calculations. SIM SPEED requests a rate of model-time advance independently of frame rate, with bounded work per frame; model time can lag under load.
- The paired display faces into an east-side bay. The approach and onward route are level; central authored terraces remain. An explicit north spawn avoids arriving among the secondary objects. The first walking probe found a remaining east-side step, which was cleared before the passing run. Controls were brought closer; all six control origins lie within 0.7m of the selected reach coordinate.
- All six placement families and their roles remain. Five authored works instantiate. The tt entry has no living scene; a separate exit teleporter is refused because the museum is continuous. Authored placements override old stamps. One additional museum-dressed statue remains outside the protected study route; it is not counted as an authored placement.
- The retained secondary turing_pattern had invalid shader hash and fractional-part expressions. A small repair restores rendering. Its noise/trigonometric image is distinct from the main artifact's evolving concentrations. No new coupling to the separate lambda_slider is asserted; that slider still ignores its old locked token.

The main manuscript now offers the experiment instead of promising it for later. Most implementation detail stays in technical.md. Earlier technical and critical proposals are preserved in design-proposals.md. Sequence description, book speech, core encounter hashes, registry description and both museum plans agree with the current main encounter.

## Evidence

- **16 numerical checks pass**, including five lambda settings through 192 model-time units, finite/nonnegative fields, repeat/new seed, pause, a homogeneous fixed point, and identical outcomes over three seconds at 30 versus 120 rendered frames per second when the work budget is sufficient.
- At lambda 0.4, 64×64 cells, the same seed and model time 60, RMS B difference is **0.0003459098** for dt 0.3 versus 0.15, and **0.0001707419** for dt 0.15 versus 0.075. This selected refinement supports closer agreement, not general convergence, biological life or a universal edge of chaos.
- **32 museum interaction/state checks and seven selected CharacterBody walking routes pass**, including actual button/slider callbacks, all five tenure variants, paired durations and independent secondary controls. Rendered Godot exits 0. No script or shader compilation errors remain in the final run.
- **79 content/preservation checks pass**. Other QFEP map files and manuscripts, roles, other plan rows, registry entries and book speech are preserved. All earlier comparison cards remain intact.
- **Six actual museum screenshots inspected**: two resolutions, another seed, controls, the repaired secondary screen and the side bay. Comparison images use the same camera and model duration. They are not fake before/after screenshots; exact before/after manuscript and source differences are provided separately.

Existing engine UID, certificate, legacy UI anchor and renderer warnings remain. The derived museum/necklace refresh still reports six unrelated map-dimension disagreements. No live museum restart, live bake replacement or commit was performed. The controlled walker probe does not establish continuous gameplay, headset comfort, Quest performance or learner understanding.

## Next

Restore QFEP_Sandbox and establish which objects actually receive each control. The QFEP thread remains the one developed in the project documents: who can revise the model, its terms and its measures? Making controls movable does not itself answer that question. Seven of eight declared laboratory maps currently exist; the Sandbox manuscript describes relationships that need an authored encounter.

Evidence beside this file: final.diff, technical.diff, critical.diff, edge_of_chaos_unlocked.diff, turing_pattern.diff, solver-checks.json, QFEP_Edge_Of_Chaos-runtime.json, content-checks.json and current-inputs.json.
