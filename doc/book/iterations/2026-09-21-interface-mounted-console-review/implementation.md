# The work can rise; the controls stay with the visitor

21 September 2026. This pass separates three opted-in physical consoles from their furniture-mounted specimens. It does not change their algorithms, manuscript, map tokens or authored access restrictions.

## Finding and change

`ExhibitFurniture` seats a mounted artifact by raising its entire root. This also raised the artifact's floor stand and controls. On the large platform, Fitness's console centre was 1.07 m above the floor instead of its authored 0.76 m; Edge of Chaos was 1.19 m instead of 0.88 m, with its stand inside the platform footprint. Grammar's low floor pad raised the station 5 cm and left its foot across the marked display area.

The new `commons/ui/exhibit_control_mount.gd` adapter keeps a declared station at its authored working height and unit world scale, in front of the furniture. The exhibit remains on its original surface. Grammar's station moves forward from z=1.70 to 2.04 m; Edge moves from 1.00 to 1.64 m. Fitness already had sufficient forward clearance at z=1.84 m. All distances here use the fixture origin and metre-scale furniture.

The mechanism runs on ancestor transform changes and explicit rebuild refreshes, without an idle `_process` loop. Controls remain children of their artifact, so visibility, culling and unloading follow the original owner. It is not a physics-floor detector: the furniture origin is the floor reference, and the placement must put that origin on the intended floor.

## Opt-in contract for another artifact

1. Put the console and its support under distinct direct-child Node3D roots. Author them at metre scale on a local y=0 floor, with local +Z facing the visitor.
2. Implement `exhibit_control_parts() -> Array[Node3D]`, returning the console first, then its support roots. Return an empty typed array for modes that should retain their original mounting. Do not include the displayed specimen.
3. Preserve external children when rebuilding the artifact. At the end of a synchronous rebuild, call `preload("res://commons/ui/exhibit_control_mount.gd").refresh(self)` so newly created roots get their own authored transform records.
4. Add the artifact to the fixture test and inspect its actual case and foot dimensions. The current 40 cm centre clearance beyond the furniture lip covers the three checked stations; larger consoles may need a different clearance policy.
5. Inspect the resulting placement in its hall. Separating the console enlarges the total footprint; it is not an automatic guarantee of a clear aisle.

The wrapper enables this only for artifacts declaring the contract, on `plinth`, `hollow_plinth`, `platform`, `table_2m` and `floor_work`, with `none`, `label` or `fixture` guards. Hood/cordon/frame and cabinet/panel/pit/vitrine configurations retain their existing treatment. Only platform L and floor_work L are exercised in this pass's mount fixtures; other allowed furniture sizes still need spatial review. `#floor_controls:false` opts out, configured before entry into the scene tree. Like the wrapper's existing kind/size fields, this is not a live furniture-rebuild switch.

## Coverage and evidence

The map-file inventory finds 46 recorded placements of these three artifacts, including 30 mounted ones: Grammar 9, Fitness 7, Edge 14. These include mission and trial maps; this is not a count of active museum-spine placements. No placement file is edited in this pass. Future loads through the opted-in wrapper use the new mechanism.

192 fixture checks pass. They exercise real registry-loaded artifacts on real furniture, XR Tools pickup/driver/release, physical pointer rays and buttons, artifact state changes, casing/foot clearance, unit world scale, authored height, scale changes, yaw rotation, a translated floor reference, rebuilds, clamped/withheld permissions, visibility and destruction. Synthetic uniform scales 0.6 and 1.4, yaws 90 and 270 degrees and a floor reference raised by 35 cm stress the transform boundary. The raised-floor test checks transforms only; it does not construct a walkable elevated hall.

The existing direct-floor suites also pass: Grammar 46, Fitness 45, Edge 81 (172 checks). They include seeded numerical comparisons and the original physical interaction tests. There are no GDScript errors in the successful runs. Existing unresolved UID, certificate-store and shader-cache-write warnings remain in the logs.

The screenshots are controlled desktop Godot fixture renders, not captures of all 30 complete rooms. Before uses the explicit `floor_controls=false` path, reproducing whole-artifact mounting; after uses the new adapter. Overview pairs have identical cameras. Control close-ups use the same standing location and eye height, turning the camera toward the console. Seeded simulation state is held; Fitness particles are explicitly drawn while integration is paused. The original source files are preserved in `before/`.

The furniture is rendered geometry without its own collision in this fixture. Lip clearance is measured from mesh bounds, not inferred from a missing physics hit. This pass does not certify complete hall approaches, seated/short visitors, headset legibility, tracked-hand comfort, arbitrary non-uniform/negative scales or standalone Quest performance.

## Reproduce

From the repository root:

```powershell
python doc/reports/interfaces-2026-09-21/mounted-consoles/inventory.py
python doc/reports/interfaces-2026-09-21/mounted-consoles/run.py
python doc/reports/interfaces-2026-09-21/mounted-consoles/run_regressions.py
python doc/reports/interfaces-2026-09-21/mounted-consoles/publish_review.py
```

Next: use this same placement boundary when migrating the next console family, then inspect the larger footprint in its actual halls. Keep the deliberately absent and clamped controls distinct.
