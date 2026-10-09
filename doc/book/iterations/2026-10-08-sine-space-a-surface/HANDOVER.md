# Sine Space — current state

Canonical `commons/maps/WaveFunctions_Sine_Space/tutorial.md` and `final.md` are rewritten for review. The two-file program prints the 61-line `03_sine_surface.gd` and the unchanged Forces `point_body.gd`. It runs inside the existing Endless Museum and installed XR Tools. Grid and face connectivity return; position becomes sine input; a matching trimesh supports the familiar point. Time does not animate the terrain. The independent exercise separates X/Z spatial frequencies.

Exact printed code: 25 native behavioural checks. Three deliberate faults rejected: missing radians conversion, wrong row stride, missing collision. Both collision support and falling through a drawing were tested in Godot/Jolt. These are teacher-authored checks, not an independent ghost-student reconstruction.

The actual 14×40 m hall retains all five authored artifacts. Removed the old eight-metre partitions, turned the corridor along the route, raised the explanation model, moved the spawn away from the tray, and gave the exit a supported approach. The walkable floor has opt-in `#fit:exact`: complete half-waves stretch to the specified footprint, changing metres per cycle slightly on each axis. The mesh and collider receive the same transform. Existing defaults remain unchanged; configuring exact fit after ready is also tested.

62 native museum checks pass. Before/after captures include the tray, corridor, basin and temporarily mounted student examples. The four-cell study misses the sine crests and becomes nearly flat. No headset comfort or human learning claim. An existing unrelated UID warning remains; the final run has no script errors or blocked-passage fallback.

Run:

```text
python -X utf8 tools/publish_wavefunctions_surface.py
python -X utf8 tools/test_wavefunctions_surface.py
python -X utf8 tools/capture_wavefunctions_surface.py
python -X utf8 tools/publish_wavefunctions_surface.py
```

The execution-plan row remains draft, not accepted. First three Wavefunctions lessons are rewritten and tested; next is **WaveFunctions_Unit_Circle**. Preserve the author's cube opening, distinguish tutorial construction from wider museum encounters, and proceed one hall at a time. No commit made.
