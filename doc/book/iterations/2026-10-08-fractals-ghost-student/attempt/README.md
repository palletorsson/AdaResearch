# Fractals: frozen-first-submission candidate

The sixteen required code blocks are reproduced verbatim in `reconstructed/<hall>/`. `extraction-manifest.json` records their SHA-256 hashes and original packet locations. Only the block contents were copied; fences and markers were omitted. UTF-8 is used throughout.

No Godot script has been executed for this submission. Text equality of the sixteen extracted files was checked against the packet. The two edited studies, probe and runtime behavior are unverified. Preserve this directory before executing; later fixes and the observation-led composition revision should be recorded separately.

Use the existing prepared Godot 4.6 Endless Museum project with XRTools and its player, camera and lighting. Attach one entry script to an empty, unit-scale Node3D placed on the floor. Local +Z is the study's front where specified. Keep each script with its companion files. These are study nodes, not full application entry scenes. `entrypoints.json` supplies paths and properties for an evaluator.

| Hall | Entry script | Adjustable values | Input / reset |
| --- | --- | --- | --- |
| Recursion | `reconstructed/Fractal_Recursion/frames.gd` | Inspector `depth = 3` (0–7), `ratio = 0.65` (0.25–0.85) | Construct on start; `rebuild()` after property changes. |
| Recursive Trees | `reconstructed/Fractal_RecursiveTrees/tree.gd` | Inspector `generations = 3` (1–4), `ratio = 0.7` (0.4–0.8) | Construct on start; two grips turn first forks; rerun to reconstruct. |
| Cantor | `reconstructed/Fractal_CantorSet/cantor.gd` | Inspector `show_history = false`; fraction is an argument in the source, not an export | Pull middle toward local +Z by at least 0.30 m then release; five cuts maximum; rerun to reset. `advance()` can be invoked while not held. |
| Koch / Sierpinski | `reconstructed/Fractal_KochSierpinski/koch.gd` | No exported properties; `original` seed and replacement `side` are code changes | Held trigger or Enter advances; four steps maximum; rerun to reset. Student builds the open Koch path only. |
| Menger | `reconstructed/Fractal_MengerSponge/menger.gd` | No exported properties; selection is the `keep_cell()` predicate | Held trigger or Enter advances; two cuts maximum; point reads first-level cells; rerun to reset. |
| Golden Spiral | `reconstructed/Fractal_GoldenSpiral/sum_points.gd` | No exported properties; `values` seeds are changed in code | Contact, held trigger or Enter requests; release both grips between held requests; ten entries maximum; rerun to reset. |
| Synthesis | `reconstructed/Fractal_Synthesis/recipe.gd` | No exported properties; initial `recipe` is three-cut thirds | Point X selects fraction; held trigger or Enter keeps; evaluator may call `choose`, `advance`, `restore`, `reset_live`; no nearby buttons created by the study. |
| Required variation | `variations/Fractal_Synthesis_FourCuts/recipe_four_cuts.gd` | Initial recipe is four-cut thirds; only this declaration differs | Same interface as Synthesis. RESET still returns LIVE to three cuts. |
| My optional composition | `composition/wave_fork/tree_wave.gd` | `generations`, `ratio`, `amplitude_degrees = 12`, `cycles_per_level = 0.25`, `phase = PI / 2` | Construct once with static samples; first-fork grips still operate; rerun after changing settings. |

For the optional comparison, place the original tree and wave tree beside each other, with their stations separated by about three metres along X at unit scale. Compare from the front and another position. The degree amplitude is clamped to 0–15; frequency is clamped to 0–1 cycles per level. Phase is in radians. These are construction settings, not animation controls. Both members of a fork receive the same offset, so their difference remains 70 degrees. Samples at parent depths 0, 1 and 2 are +12, 0 and -12 degrees in the default recipe. The other subtree should remain still when one grip is used.

`predictions-before.md` records the inputs, receivers, predicted changes and invariants before implementation. `review-before.md` assesses all seven halls. `reading-log.md` identifies every source read and the prior knowledge supplied.

`prediction_probe.gd` is an optional student-authored native SceneTree runner. An evaluator can invoke it with Godot's `--headless --path <prepared-project> --script <path-to-this-probe>` after freezing. It depends on the XRTools class from that project; it is not a replacement environment. The probe asserts the four-cut arithmetic/copy behavior and the wave composition's structural predictions, including zero influence, repeatability and cancellation of terminal-direction offsets. It has not been parsed or run. Assertions about geometry cannot establish that the labels, grips or comparisons are comfortable to use.

The original composition is this first `tree_wave.gd` and its default recipe. No revised version is claimed yet: runtime output and visual observations must precede the requested revision.
