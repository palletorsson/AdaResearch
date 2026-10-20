# Randomness: begin the writing pilot in the main spine

Palle, 13 October: start at Randomness, rather than the later L-systems example.

| Decision | First hall: Random Definition |
| --- | --- |
| Subject | How a seeded pseudorandom generator makes a recoverable colour arrangement. |
| Inheritance | Cube, arrays/grid loops and per-cube materials; exact PointBody from Wavefunctions Synthesis; Cage's earlier distinction between an event record and replay. |
| New capacity | Reset a local generator, trace requests, interpret successive values, reproduce a result and explain a changed result under the same seed. |
| Tutorial example | Existing paired 8 × 8 RGB cube grids, one optional discarded draw, the carried point and the existing size slider. |
| Reflection | The pleasure of recovering a chance discovery; who assigns numbers their jobs; RAND's prepared chance and its punched-card connection to the loom. |
| Boundary | No new pickup lesson, no new museum geometry, no survey of distributions or entropy formula. The next hall explicitly introduces integer symbols and counts. |

The writing formula is being tested here, not imposed on all fourteen halls. Give the new concept an explanation and a worked trace; refer precisely to inherited code; retain complete executable new files. Let the reflection pursue an encounter, a historical connection and a possible misuse without pretending that an imagined experiment is installed.

The MATRIX helper remains complete but follows the teaching and handoff. It is substantial support code, not a second learning objective. A future shared-controls lesson could let later halls inherit it too; this pilot does not silently invent that prerequisite.

## What changed and why

- Explain pseudorandom generation, seed and state before asking the student to read calls to an unfamiliar API.
- Work through one RGB assignment with explicitly invented numbers; prevent confusion with actual seed-42 output.
- Link the earlier PointBody instead of printing it again. Resolve that dependency from its tutorial in the test and ghost-student workflows; no fallback to a hidden companion implementation.
- Preserve both new code files byte for byte. All three assembled files match the pre-edit runnable study.
- Consolidate repeated controls and comparison prose. Keep one main code variation with a prediction and restoration step.
- Correct the outgoing tutorial's vague reference to ten categories: the next student lesson uses four; the larger installed instrument is a separate representation.
- Move the reflection's detailed RGB trace into the tutorial. Develop pleasure, interpretation and the punched-card history in the reflection. The imagined escaping cubes are explicitly a possible future experiment.

## Current-map receipts

- `commons/maps/curriculum_spine.json`: Wavefunctions order 9, Randomness 10; the chapter runs from Random Definition to Random Game. Entropy follows Definition.
- `commons/maps/Random_Definition/map_data.json`: `seed_replay_demo:180#display:wall#comparison:replicas#stand:table#controls:compact#control_front:1.0`, textile comparison, crank and number-book page are placed.
- `commons/data/museum/em_plan.json`, plan 65: the same hall and configured encounters are installed. Museum metadata includes the earlier Biome Cage interlude, not an extra tutorial chapter.
- Registry `randomness.json` resolves the seed display to `algorithms/randomness/seed_replay/seed_replay_demo.tscn`. Its script resets before each column, consumes three values per cell and optionally discards before the last grid. MATRIX uses the existing 2–16 bounds.
- Textile scene uses `commons/artifacts/randomness_space/dna_comparison.gd`, `textile = true`: three alphabets, same seed 41, weaving stopped. `ten_print_textile.gd` supplies the marks.
- Number-book scene resolves to the historically named `random_number_book_page_1995.gd`. Flowing values leave with `pop_back`; touched cells can be frozen, but there is no archive of departed values.
- Crank scene uses its own LCG and stores its history. The reflection does not claim it uses the seed display's RNG algorithm.

## Sources

[Godot RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html): seed, state, returned range and implementation limits.

[RAND introduction](https://www.rand.org/pubs/monograph_reports/MR1418.html): 1955 book, 1947 electronic-wheel output, testing and transformation, punched-card use and Monte Carlo demand. The connection to our loom and the aesthetic reading are this chapter's interpretation.

## Validation

See `tests/tests.json` and its retained Godot logs. Fresh reconstruction uses the two current printed files plus PointBody resolved from the linked earlier tutorial. Baseline and the two colour-assignment variations pass; both deliberately broken procedures are rejected. These are author-informed checks of execution and transfer, not evidence of a human student's understanding or a fresh headset walk.

The current pair is available in `parallel.html` and the book's `10_randomness/01_Random_Definition.pdf`. Source snapshots and the exact text diff are retained here. The rest of the chapter has not been rewritten by this pilot.
