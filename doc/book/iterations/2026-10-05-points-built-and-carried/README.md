# A point, then a point you can hold

5 October 2026. Current Point One and Point Coordinates tutorials now print their complete small student programs. Point One creates its point from scratch. Coordinates continues the same authored construction and adds pickup plus local/world readings. Each lesson prints `_ready()` once.

The prepared Day Zero environment supplies the room, camera, light, player and XR Tools library. It does not fill in missing point or label construction. The museum code and both `final.md` files were preserved; their hashes are recorded in `before/unchanged.json`.

## Evidence

- Point One: 60 passing native checks across the base program and four printed experiments.
- Coordinates: 46 passing native checks, including real XR Tools overlap, pickup, movement, release, local/world conversion and the disabled-pickup experiment.
- Two intentional faults fail the ordinary checks: a missing mesh assignment and a local position incorrectly reported as world position.
- The exact declared continuation edits produce the printed Coordinates program byte-for-byte from the printed Point One program.
- Five complete experiment scripts are retained under the two `states/*/variants/` directories, with hashes matching the tested copies.

The isolated test project supplies an empty parent and synthetic controllers. Godot executes the actual scripts and the repository's unmodified XR Tools. Hardware input, rendered appearance, headset comfort and student understanding are outside this test.

## Reproduce

From the AdaResearch root:

```powershell
python doc/book/iterations/2026-10-05-points-built-and-carried/run_checks.py
python doc/book/iterations/2026-10-05-points-built-and-carried/build_review.py
```

The runner uses Godot 4.6 at the path specified near its top, or `GODOT_EXE`. It extracts the canonical tutorial listings, checks continuation, copies the XR library into a private temporary project, imports it, runs the normal and deliberately broken cases, and writes source-bound reports. A mismatch or unexpected failure returns a nonzero exit code.

[Read the evidence](index.html) · [Full results](report-runtime.json) · [Native verifier](verify.gd)

Lines retains its older code and historical evidence. Its metadata now explicitly requires revision against this new predecessor. No later lesson is claimed to pass from the new starting state.
