# Triangle consoles along the spine — 21 September 2026

Review: [Triangle, within reach](../../../book/iterations/2026-09-21-interface-spine-triangle-review/index.html).

Scope: `Point_Triangle_Context`, `triangle_line_puzzle` and `draw_triangle_faces`. Preserve the two encounters, their primary roles, source geometry, sequence and manuscript. This pass addresses physical controls, flat text, mounting and access in the actual hall.

## Implementation

- `commons/ui/triangle_experiment_panel.gd`: shared DataInstrumentSurface, 76 × 42 cm screen, physical button backplate, flat captions and corner annotations, selected/unavailable states, live tip coordinates.
- All three drawing buttons share the console. The existing New Outline button is reparented without changing its signals. Non-discovery placements retain the legacy button setup.
- Authored mounts in the two artifact scripts are lowered and inclined 30 degrees. The top-level console follows its subject's position and orthonormalized basis, retaining unit control scale. It is excluded from museum seating bounds; its support stays upright and reaches the hall floor.
- Drawing Fill is unavailable without completed faces. Shift Start retains held-pen, held-corner and partial-outline guards. The actual fan triangulation is preserved, including its demonstrable failure for some concave outlines.

## Reproduce

From the repository root:

```powershell
python doc/reports/interfaces-2026-09-21/spine-triangle/run_tests.py
python doc/reports/interfaces-2026-09-21/spine-triangle/run.py drawing after
python doc/reports/interfaces-2026-09-21/spine-triangle/run.py puzzle after
python doc/reports/interfaces-2026-09-21/spine-triangle/publish.py
```

Runners use the local Godot 4.6 executable with hidden windows, desktop rendering and dummy audio. Hall tests use private copies of the museum builder and its control files, avoiding live runtime-control writes. Baseline sources and images are retained under `before/`; do not overwrite them with current-source captures.

Results: **89 checks, no failures**: 28 triangle interactions, 33 console behaviors/mounts, 10 puzzle hall checks, 18 drawing hall checks. The L-shaped fan test compares generated mesh area after Shift Start, proves unchanged boundary coordinates, and confirms restoration after six shifts.

Hall screen centres: puzzle 1.20 m; drawing 1.165 m. Button heights: 0.98 and 0.945 m. Horizontal distances: 0.39–0.47 m from the tested pose. The drawing station has supported, clear side approaches; a straight final metre from the front starts inside a column. Final wide cameras use a verified approach. Before/after reading cameras follow the station and use 0.70/0.55 m operating offsets respectively.

No script errors were observed. Existing unrecognized UID, unknown audio preset and shutdown ObjectDB warnings remain; this is not a sound or engine-cleanliness certification. Headset reading, real hand input, seated reach and Quest performance still need human testing.

Next: Primitives_Polythedra along the spine. The separate snap-sphere display in Grid remains an earlier open item.
