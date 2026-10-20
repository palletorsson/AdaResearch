# Re-running the current learner checks

Use the prepared AdaResearch project with its existing XRTools installation and Godot 4.6. This package is review material, not a complete project.

The repository command is `python -X utf8 tools/test_procedural_sequence.py`. It creates a new timestamped runtime folder instead of replacing earlier hall receipts. Its individual harnesses compare marked tutorial code with the study sources before execution. The current harnesses use the author's local Godot executable path; set that path for another machine before running them.

For the exact supplied native probes, copy this complete-readings folder into `doc/book/iterations/2026-10-09-procedural-generation-complete-readings` within the prepared project, preserving runtime subpaths. For each hall, run the command below with its runtime path. The probe loads the supplied printed, variation and deliberately faulty versions. It replaces that run's checks.json; retain the original archive if you need to compare receipts.

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://doc/book/iterations/2026-10-09-procedural-generation-complete-readings/RUNTIME_PATH/run.gd
```

Use a nonzero exit, SCRIPT ERROR, Parse Error or a false assertion as a failure. Headless execution does not test visual presentation or physical controllers. The copied run.py files record the original invocation and contain machine-specific paths; run.gd and its adjacent source folders are the portable native test inputs within the prepared project.

Runtime paths for this publication:

- `runtime/20261009T133642411192Z/PG_Genetic_Evolution`
- `runtime/20261009T133642411192Z/PG_Space_Colonization`
- `runtime/20261009T133642411192Z/PG_Branching_Growth`
- `runtime/20261009T133642411192Z/PG_Percolation_Network`
- `runtime/20261009T133642411192Z/PG_Caves_Mazes`
- `runtime/20261009T133642411192Z/PG_Sculpted_Forms`
- `runtime/20261009T133642411192Z/PG_Mirrored_Patterns`
