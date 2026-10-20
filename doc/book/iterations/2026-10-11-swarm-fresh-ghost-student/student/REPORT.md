# Fresh ghost student: Swarm reconstruction and transfer

**I reconstructed and executed all seven printed studies, then built and tested an independent Flow Fields variation.** The seven original models and full display/interaction hosts ran without changing their printed code. The independent prediction was supported, with a later return to the strip that limits what “escape” means.

I am an experienced coding AI, not a novice human. This assessment supports reconstructability and some independent reasoning from the lesson; it does not establish novice learning, headset comfort, or transfer by human students.

## Evidence and boundaries

- Read every supplied tutorial/final pair in sequence and viewed all seven installed-encounter images. No earlier tests, authored study implementations, prior verdicts, handoffs or ghost results were read. Optional RIDGE brief and linked results were not opened.
- Extracted **22 named GDScript files** from the printed code fences; wrote **7 minimal Node3D scenes** independently. `provenance.json` records source and output SHA256 hashes. Fenced code is exact, with LF line endings and a terminal newline. This tests reconstruction from complete listings, not invention of all that code unaided.
- `PREDICTIONS.md` was fixed before execution: SHA256 `df4fe3313a46bc0ac3b8be1ad512c05b169158d5b7447341d4d3cdb76849b066`. The original reconstructions and predictions remained unchanged after testing.
- Godot 4.6 ran `probe.gd` through the supplied prepared project, with XR off and bridges disabled. The single run produced **120 passing checks, zero failures**. Some checks establish loading or button existence; these are not 120 independent demonstrations of understanding.
- All seven full hosts entered the scene tree and constructed their points, meshes, labels and controls. Synthetic grab callbacks, reparented held points under a transformed host, action signals, button signals and key events exercised interaction wiring. Both independent variant hosts also ran and matched their models.

## What I reconstructed and carried forward

| Hall | What I could explain and test | What carries onward |
|---|---|---|
| Physarum | The field remembers outside the mover. A stronger left mark turns; equal side samples retain heading. The empty first tick deposits six units. Tick-40 field totals were 59.9736778 at retention .92 and 13.3333330 at .55. Held movement alone does not paint. | Addresses, local coordinates, shared records and separate read/write phases. |
| Flow Fields | A cell requests a velocity; bounded correction preserves motion history. Moving agents never write the vectors. Zero direction actively brakes. Hand edits persist for another reader. | Desired-minus-current steering, while its information source can change. |
| Boids | Neighbour membership precedes the three requests. An isolated point coasts; stationary average velocity requests braking. The wrap seam is not a periodic neighbourhood. Reversing storage order preserved the physical one-step result. | Snapshot discipline, plus explicit inclusion and boundary rules. ABM then sets flocking aside. |
| ABM | Cargo is individual state; trace is shared state. Exactly one cell from food is outside contact. Moving inside is noticed next tick. Home counts once. Replace preserves shared history while Clear removes it. | A state can select a different information source without changing the body. |
| Ant Colony | Searching reads food and writes home; carrying reverses that relation. Contact reverses velocity and renews energy. An isolated first search deposit was .49875. Zero agent deposits still leave the two source cells at eight each. | Distinguish who reads, who writes, which channel and when; PSO replaces these channels with scored memories. |
| Particle Swarm | Best position and score form a pair under one rule. Objective changes invalidate old evaluations while retaining motion. Hand placement waits for a step to be evaluated. Two equally scoring EDGE corners selected opposite shared references when their storage order reversed. | A remembered “best” is conditional, and tie policy can choose among equal records. Population accounting asks a different question. |
| Population Support | Birth, loss and supply have different meanings. Copied event dictionaries protect history. Real mating produced a recorded birth in a controlled eligibility setup. After restarting, both actual populations reconciled after every one of 1800 updates. | Counts require a baseline and stated event categories; zero discrepancy is consistency, not a complete explanation. |

The natural 30-second ecosystem run ended with **11 prey and 0 predators**: 50 initial prey + 0 born − 49 lost + 10 supplied. Omitting supply gave a gap of 10. Ten living bodies had supplied origins. There were 78 recorded events including support records. Natural births did not happen in that run; the separate controlled real-mating check establishes the observer's birth path. Inventing one birth and one loss left the account balanced, demonstrating why balance alone cannot certify the event history.

## My independent variation: a braking strip and integration rate

I copied Flow's complete files into `variants/coarse` and `variants/fine`. Both use an all-height zero-direction strip at x in [7,9), with point 0 starting at (7.6,1.5), velocity (3,0). Response stays .5 s, acceleration cap 6, and the external field stays east. Only DT differs. The six points do not interact. I ran ten seconds of model time in each model and each full host.

Before execution, I derived the discrete stopping distances: **1.35 cells** at DT=.05 and **1.425 cells** at DT=.025. With only 1.4 cells to the strip boundary, I predicted the coarse point would remain inside while the fine point would first cross at step 79.

| Measurement | DT .05 | DT .025 |
|---|---:|---:|
| Steps in ten seconds | 200 | 400 |
| First strip exit | None | Step 79, 1.975 s |
| x at first exit | — | 9.0002260208 |
| x after ten seconds | 8.9499988556 | 8.4710922241 |
| x velocity after ten seconds | 0.0000000021165 | 0.0082285795 |
| Largest pre-exit position error versus geometric prediction | 0.0000035683 | 0.0000021706 |

The hypothesis was supported. Fine-step velocity rose from .0521538 on exit to .1995461 on the next tick, when east became the sampled request. **It did not escape forever:** it wrapped at step 191 (4.775 s) and entered the same strip again at step 285 (7.125 s). The final position alone would obscure that earlier escape. The trace shows why a first-exit measurement and equal elapsed model time mattered.

This transfers Flow's braking rule into an independently chosen numerical question: near a boundary, integration rate can change a categorical outcome. It also uses the sequence's insistence on separating model updates, movement history and boundary policy. No new randomness, pathfinder or scoring objective was needed.

## Friction, assumptions and limitations

I found **no blocking missing code** in these seven reconstructions under the declared prepared project. The carried point was present in every lesson; named controls and ecosystem dependencies were explicit. Reset semantics differ across halls and had to be read carefully: Physarum retains RUN on reset, Flow/Boids reset pause, and later hosts guard resets while held. The text generally states these distinctions.

The listings alone do not provide the Day Zero player/environment, cached XRTools classes or global class registration. I read only the permitted project configuration and the three explicitly supplied ecosystem dependency files. That last hall reconstructs an account/observer around an existing model; it does not teach me to derive that model's entire ecology. Large-room portable panels shown in the images are supplied equipment; the printed hosts deliberately reconstruct original control banks instead. This is declared scope, not a missing implementation I repaired.

There were **no failed study assertions**. The Python wrapper initially failed to display the saved log because cp1252 could not encode an autoload checkmark; Godot had already completed and returned zero. I repaired only the wrapper's output encoding. The saved log also contains the project's unresolved audio UID, a missing-player notice and Jolt's warning about a supplied shape solver bias. No editor/import or source repair was needed. These are environment/harness issues, distinct from tutorial gaps.

Synthetic callback/signal tests do not certify the physical pickup system, physical button travel, desktop pointer routing, rendering, readability or XR comfort. The input pictures show installed encounters; I did not claim them as screenshots of my reconstructed scenes. Passing checks alone are not learning; the precommitted derivation, changed program, matching outcomes and qualified interpretation provide the transfer evidence here.

## Reproduce and inspect

Run from the repository root: `python doc/book/iterations/2026-10-11-swarm-fresh-ghost-student/student/run_probe.py`. It runs the existing Godot binary with CREATE_NO_WINDOW, writes timestamped logs, and executes only the newly written SceneTree probe. It requires the same prepared project/dependencies.

`results.json` contains all checks and both full numerical traces; `population_trace.json` contains both populations' reconciliation after every update; `population_events.json` retains the event history. `logs/20261011T183427Z.log` is the original engine output. `READING_AND_ASSISTANCE.md`, `provenance.json`, `prediction_freeze.json`, and `variants/manifest.json` document sources and assistance. `reconstructed/` contains unchanged originals; `variants/` contains the independent copies. Canonical tutorials, maps and production lesson files were not edited.
