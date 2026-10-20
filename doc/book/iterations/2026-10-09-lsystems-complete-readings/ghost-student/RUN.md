# Repeat the ghost-student checks

Use the prepared AdaResearch project with Godot 4.6 and its existing XRTools installation. This evidence folder is not a standalone Godot project.

The full-sequence runner is `tools/test_lsystems_ghost_student.py` in the repository. It extracts the current canonical tutorials, snapshots both texts, creates a new run directory, and executes the established assertion suites without overwriting prior receipts. It requires the original `tools/test_*` and `tools/probes/*` files named by its manifest. Then run `tools/test_lsystems_ghost_variation.py` for the unprescribed edit. The copied runners in this folder's tools directory are records; restore them to the repository tools directory if needed.

To re-execute one preserved native reconstruction, retain this folder at `doc/book/iterations/2026-10-09-lsystems-ghost-student` within that prepared project. For example:

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://doc/book/iterations/2026-10-09-lsystems-ghost-student/runs/20261009T123500404411Z/LSystems_Growth/run.gd
```

For the transfer exercise, use its `run.gd` and pass its directory as a user argument:

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://doc/book/iterations/2026-10-09-lsystems-ghost-student/runs/20261009T123500404411Z/transfer-exercise/run.gd -- res://doc/book/iterations/2026-10-09-lsystems-ghost-student/runs/20261009T123500404411Z/transfer-exercise/
```

These direct invocations replace the copied receipt in their directory; keep the original archive as evidence. A nonzero exit, SCRIPT ERROR, Parse Error, missing receipt or failed assertion is a failure. The full runner creates a fresh timestamped run instead.

Fresh museum captures used `tools/run_encounter_probe.py LSystems_Competition --sequence lsystems --render --output-tag ghost-student-20261009 --probe tools/probes/lsystems_ghost_museum.gd`. The probe obtains the programs from latest-run.json. Use a new output tag to retain existing evidence. It temporarily hides the installed forest and places both reconstructions at its transform; it does not persist that scene change.

All runs are author-led native tests. The headless suites supply controller poses to the existing XRTools API; they are not physical-headset sessions. The rendered follow-up covers one museum hall, not a fresh traversal of the entire sequence.
