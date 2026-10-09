# Point Zero: run the code printed in the tutorial

From the repository root:

```powershell
python doc/book/iterations/2026-10-05-point-zero-complete-example/run_checks.py
```

Use `--godot <path>` to select a different Godot executable. The default is `C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe`.

The runner extracts the complete `student-code:counter.gd` block from `commons/maps/Point_Zero/tutorial.md` verbatim. It then applies the exact instruction printed inside `student-edit:read-once`: move the frame-reading assignment into `_ready()` immediately after `add_child(label)` and delete the empty `_process()` function. The instruction and source anchors must match uniquely; an absent or changed instruction stops the runner. The once version is constructed from the listing, never imported from a saved solution.

It saves the listing as `counter.gd` and the edited result as `counter_once.gd`, then loads those bytes in a temporary minimal project. Godot creates the `Node3D` instance and invokes its actual `_ready()` and `_process()` callbacks. No museum scripts, autoloads, or XR are present.

`verify.gd` uses native `assert` to check that the script creates and parents its `Label3D`, initializes its display, and either updates the number as engine frames advance or retains the value read once. The frame comparison allows a difference of one because the verifier samples at the `process_frame` signal, which occurs before node `_process()` callbacks.

Two additional runs each remove one line from the repeated example: `label = Label3D.new()` or `add_child(label)`. They must fail the same construction or parenting assertion used by the positive run, print Godot's native assertion failure, and exit nonzero. The verifier schedules exit before a failing native assertion so it cannot leave Godot waiting. The runner exits nonzero if either positive example fails or either deliberate omission is accepted.

`report.json` records individual assertions, real exit codes, executable/version, source and script hashes, and runner/verifier hashes. Its `printed_edit` evidence includes the exact instruction, its hash, the transformation, and the base/result hashes. The logs contain Godot's actual output; the negative logs intentionally contain errors. `tutorial.source.md` records the exact tutorial source used for the run. `before-single-listing/` preserves the previous run against the tutorial that printed both versions in full.

These checks establish runtime behavior in headless Godot. They do not claim to verify camera framing or rendered appearance.
