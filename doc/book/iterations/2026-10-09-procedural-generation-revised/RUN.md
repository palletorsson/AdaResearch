# Re-run the checks

In the prepared AdaResearch project, run `python -X utf8 tools/test_procedural_sequence.py` for all seven printed programs. The latest timestamped run is included in the complete review edition.

For each repaired hall, run:

```text
python -X utf8 tools/run_encounter_probe.py PG_Sculpted_Forms --sequence proceduralgeneration --render --output-tag review-after --probe tools/probes/pg_review_passages.gd --spec doc/book/iterations/2026-10-09-procedural-generation-revised/after-spec.json --no-bridges
```

Replace the hall name with Branching Growth, Percolation Network, Caves/Mazes or Mirrored Patterns' PG folder name as appropriate. This replaces that output tag's receipts; use another tag to preserve this run. The runner expects the existing project, XRTools and local Godot executable. `--no-bridges` isolates the process from live commands and disables NatureRenderer's dynamic environmental controller; it does not change a project setting.

The standalone new prose example uses `tools/probes/pg_review_walkthrough.gd` through Godot's `--headless --path <prepared-project> --script` option. Its receipt is `walkthrough-checks.json`.

The archived before views document the prior layout. Re-running with the current map will not reproduce them. Do not restore the entire old museum plan over concurrent project work.
