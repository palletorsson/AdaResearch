# machinelearning × Nature of Code ch. 9–11 — applied 25 September 2026

Reading: `doc/book/readings/NOC_machinelearning_2026-09-25.md`. Tasks `book_machinelearning.015`–`.021`, all applied here and closed. Palle: "commit and apply" (10:35).

## The prediction (.016), and what it took to measure it

Predicted: the energy economy of `non_teleological_evolution` pays only for unvisited cells of a grid that is never cleared, so fresh ground is finite and the population drains to zero once it is used up.

The code does clear cells: one random cell every 120 drawn frames (`Engine.get_frames_drawn() % 120 == 0`). The first probe drove the artifact's `_process` by hand, headless. Headless draws no frames, so `frames_drawn` stayed at zero and the clearing rule fired on every call, sixty cells a second instead of one every two; the population sat at its ceiling for fifteen simulated minutes and the probe reported "prediction FAILS: the ground forgets". That was another game. The second probe (`probe_novelty_finite.gd` as committed, report `probe_novelty_finite.json`) runs the artifact's own frame loop in a window under `--fixed-fps 60`, so frames are drawn and counted:

| simulated time | population | visited fraction |
|---|---|---|
| 0 s | 30 | 0.07 |
| 2.4 s | 120 (the ceiling) | |
| 5 s | 120 | 0.96 |
| 10 s | 120 | 1.00 |
| 20 s | 76 | 1.00 |
| 30 s | 8 | 0.99 |
| 35.8 s | 0 | 0.99 |

The ground clears 0.50 cells a second at that rate and creeps back toward fresh with nobody alive to use it (0.92 at 96 s). The prediction held in substance and failed in one detail: the ground does forget, too slowly to matter. The sentence went in with the measured numbers and footnote `[^novelty]`.

**For Palle:** this is also a hall bug. A visitor who reaches ML_Evolution more than about forty seconds after its segment was built meets an empty plane; the museum builds segments ahead of the walk. The chapter now says so. Whether the clearing rate, the ceiling or a respawn should change is a design decision and is not made here.

| task | hall | what landed |
|---|---|---|
| .015 | ML_Evolution | the judged population beside the unjudged one; ten generations in a visit; footnote `[^holland]` |
| .016 | ML_Evolution | novelty is finite, measured; footnote `[^novelty]` |
| .017 | ML_Evolution | the flowers' written taste against Sims's visitors; footnote `[^sims]` |
| .018 | ML_Neural_Networks | the learning rate as the network's max force |
| .019 | ML_Classification | the two silent classifiers named; footnote `[^perceptron]` |
| .020 | ML_Synthesis | the walker learning from a reward, and the four measures |
| .021 | ML_Gradient_Landscape | a loss surface is a fitness landscape upside down; footnote `[^fitness-landscape]` |

Verification: every footnote reference has a definition; endings preserved; no code changed.

Disclosure: ML_Classification and ML_Gradient_Landscape carried uncommitted hunks from another writer (Codex, idle since this morning; forum 260925-0vmbf) and land here whole; ML_Sequence_Memory carries such hunks and is not in this pass. Evolution, Neural_Networks and Synthesis were clean.
