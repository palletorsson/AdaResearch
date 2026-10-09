# Reconstructed student work

reconstructed/ contains nineteen files extracted verbatim from the frozen tutorials. Put each hall's files together and attach its entry script to the supplied PointStudy node, as the manuscript instructs. These files require the existing Endless Museum Godot/XRTools environment.

Entry scripts in order: row.gd, volume.gd, history.gd, life.gd, presence.gd, exchange.gd, comparison.gd, difference.gd. variants/ keeps one actual requested code edit per hall in a separate folder, with local dependencies. Some additional seed changes were made through the test harness using the same public properties; variants.json records source replacements.

recorded_presence.gd is a separate optional composition extending the reconstructed presence study. Attach it in place of presence.gd, call begin_record() after the chosen reset, then use the ordinary STEP actions. The inherited point and display are reused. play_record() replays ordered inputs; play_record(true) reverses them. Begin a new record after resetting, changing the field or schedule, or replaying; do not advance outside the recorder. Records are in memory and replay is immediate, not a paced animation or a saved file. The helper intentionally asserts when its stated recording agreement is broken.

To reproduce the automated trial in the original repository, run python -X utf8 tools/test_ca_ghost_student.py. The runner names this machine's Godot4.6 path; adjust on another machine. verification/ holds copies of the evaluator scripts for inspection. Predictions-before.md records expectations before execution. Code under reconstructed/ was never modified during testing.
