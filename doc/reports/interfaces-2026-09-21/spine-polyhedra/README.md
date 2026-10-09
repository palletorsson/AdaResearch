# Polyhedra: direct manipulation and recovery

[Review with actual Godot images](../../../book/iterations/2026-09-21-interface-spine-polyhedra-review/index.html).

Scope: the supporting `pyramid_edit` and the primary held `grab_trihedron` / `grab_tetrahedron` in `Primitives_Polythedra`. No manuscript or role changes. Prism, wedge, concrete barrier and sign encounters remain in place.

## Changes

- The pyramid uses `pyramid_edit:180:0#plinth:0.65,micropod#workbench:1`, replacing its 1.10 m plinth plus 0.15 m offset. The map and matching museum-plan row are updated together.
- Trihedron and tetrahedron now face 180 degrees toward the open aisle. Their mesh, material and grab code are untouched in this pass.
- Opt-in pyramid grips have 2.8 cm visible radii, with their original 4.55 cm grab colliders. Base grips are cyan; apex is amber. Default placements keep their previous appearance.
- `reset_shape()` restores the current authored home positions and clears velocity, guarded by `any_handle_held()`. Existing constraint modes and size configuration are retained.
- `commons/ui/vertex_recovery_panel.gd` provides a compact native push button, shared rounded casing, flat baked captions and upright support. It is top-level so it cannot affect museum specimen seating. It follows the owner’s position and orthonormalized basis. Its owner contract is `reset_shape()` and `any_handle_held()`; it does not introduce new form-making logic.

## Reproduce

```powershell
python doc/reports/interfaces-2026-09-21/spine-polyhedra/run_tests.py
python doc/reports/interfaces-2026-09-21/spine-polyhedra/run.py pyramid after
python doc/reports/interfaces-2026-09-21/spine-polyhedra/run.py trihedron after
python doc/reports/interfaces-2026-09-21/spine-polyhedra/run.py tetrahedron after
python doc/reports/interfaces-2026-09-21/spine-polyhedra/publish.py
```

Runners use hidden Godot 4.6 processes, dummy audio and private museum-builder/control/output files. Functional checks are headless; captures use mobile rendering. Baseline sources and renders are retained under `before/`. Do not overwrite them using the changed sources.

**88 checks pass:** 46 native input/mesh/constraint/recovery checks; 28 actual pyramid-hall checks; 7 per held solid. The native grab moves the apex through a test grabber and proves the generated mesh changes. Native pointer events cannot reset while it is held; after release they restore the original mesh. Each constraint mode is checked after deformation and reset.

The pyramid's measured base/apex heights are 0.708 / 1.508 m. Each base grip has a supported clear standing pose at 0.461 m horizontal distance; apex at 0.650 m. Reset is at 0.934 m height and 0.586 m horizontal distance. Far corners require the side poses recorded in `grab_poses`; they are approximately a metre away from the front camera, so that camera alone is not a direct-reach proof. The main approach has clear capsule travel and sampled floor support. Trihedron/tetrahedron native grab targets are approximately 1.50 / 1.26 m high and 0.50 m horizontally from the tested stance.

The original pyramid diagnostic pose was obstructed. Final poses use the real floor ray and the smaller support. Cameras and direction differ before/after; images are actual hall evidence, not fixed-camera comparisons.

Existing UID and viewport-texture errors occur in baseline and final hall logs. No script errors remain. This is not a full engine, headset, seated-access or Quest-performance certification.

## Remaining work

- Next active spine hall: **Point_Animatedcube**.
- RockScanner currently creates/moves its scan plane but does not activate its cross-section canvas; its dormant approximation also assumes world-origin coordinates. Treat this as a separate artifact-development task, not evidence that the book must be cut.
- Trihedron's alternate material is unassigned, so its existing A/X material action has no visible effect; the direct held-shape comparison remains valid.
- Continue reviewing the rest of the supporting artifacts. This pass does not certify every interface in the hall.
- Headset test: direct grips, real hand release/reset, reach for shorter/seated visitors, and performance.
