# Full source views for spatial comparison

Follow-up: [the pre-Museum Grid edition](2026-10-26-historic-grid-comparison.md) now defaults to an explicit Git baseline before the first Endless Museum implementation. Current Grid is a separate selectable edition. This report describes the current-source capture added before that historical correction.

The existing comparison now supports inspecting the actual Museum and Grid spaces, rather than only comparing plan envelopes:

http://localhost:3003/lab-editor?mode=void&floor=16&compare=1

## Use

- Choose **Museum**, **Grid** or **Void** to inspect one source; **All three** restores the comparison.
- **Full window** hides the side panels and expands the view. **Fit all** frames the source without changing its physical scale.
- **Original** materials preserve exported material colours; **Source colours** distinguishes sources in overlays.
- **Museum section** clips the Museum above the selected height. Its default 2.8 m cut reveals the interior. Turn it off to inspect the complete geometry. **Overhead** controls the separate group of horizontal overhead architecture. These are display controls, not source edits.
- **Explore** starts an inspection camera at the source entrance where available. Click the view, use WASD to move, right-drag to look, Q/E for vertical movement, Shift for speed and Escape to release focus. Exploration restores overhead geometry and disables the section cut. It is free inspection without collision or gameplay simulation.
- Select an artifact and use **Look closely** to frame it. Original configurations and chosen-anchor comparisons remain available.
- For an uncached map, **Prepare full views for this map** starts the actual Grid and Museum export tools. The shared OS native lock serializes those jobs. Progress survives page reload through a per-map receipt. Fresh exports are reused; the existing comparison remains available if a build fails.

## Source evidence

Rotation / floor 16 now has the current Museum builder's geometry, not the September occupancy reconstruction. It is a 62 × 87 m current hall containing the original Grid study as a nested installation. The Museum export includes all 12 Grid occurrences, each with its real pose/configuration, plus Museum furniture/staging/other native bodies: 26 independently inspectable objects in total. Grid remains its original 39 × 73 m; Void remains its saved 42 × 18 m standard frame with 148 normalized object/part entries in this receipt.

Triangle / floor 5 was prepared through the new HTTP export endpoint, testing the generic path beyond Rotation. It has ten native Grid instances and 26 native Museum objects. Its Museum staging differs substantially from the reactor-hall treatment of Rotation. Switching to it in the browser loads its actual geometry with one renderer.

Both original sources retain their own positions, scales and heights. Rigid comparison alignment is temporary. Native Godot scenes, the current Museum plan/rulings and existing Void exports supply the geometry; no invented exhibit meshes fill gaps. Shader-driven deformation, shader appearance, screen/video content, illumination and motion are not all reproduced by static GLB snapshots. “Original materials” means exported materials, not pixel-identical Godot rendering. Historical footprint records remain the explicit fallback when a fresh native snapshot is unavailable.

## Isolation and checks

`tools/export_spatial_museum.py` runs a private copy of the current Museum controller with only its output/control/save locations redirected. It reads the current plan and copied current overrides/bake, discovers both Museum records and nested Grid artifacts, awaits native preview hooks and freezes the completed scene before collection. Geometry is split into independently inspectable exhibits, architecture and overhead architecture without modifying authoring. Large architecture MultiMeshes are batched from their real vertices/transforms.

Both accepted Museum captures and the Grid captures finished with no runtime/export errors. Source hashes for map data, Museum code/plan/bake/overrides, live control/ledgers and shared Void rooms are checked against the same run's starting values. The browser test separately confirms unchanged shared room/frame/map/ledger files and no authoring save requests. The new preparation POST writes only generated models and job receipts; the authoring comparison endpoint still rejects POST.

`node tools/check_spatial_comparison.cjs` passes: exact original occurrence counts, real GLB headers, distinct configurations, rigid anchor transforms, solo/full-window views, materials, section/overhead controls, eye-level movement, close framing, floor switching/disposal, rejected invalid export requests and reuse of current models. There is one browser canvas and no uncaught page error. The target page compiles; the broad TypeScript run still has existing errors elsewhere, with no diagnostics in the new comparison/export-route modules.

A preliminary Triangle capture failed on graphics-memory shader compilation and was not published. Its accepted retry completed normally with the Compatibility renderer. The preparation helper includes one bounded rendererless geometry retry for that specific failure; such a snapshot is explicitly labelled because viewport textures may be absent. That fallback was not needed in the accepted captures. No physical-headset or gameplay acceptance is claimed.

Native jobs are finished; no background preparation loop was created. Existing saved arrangements and unrelated work were preserved. The comparison remains a tool for selecting spatial qualities to carry forward; it does not automatically curate or copy a source layout into the Void.

Evidence: `doc/ports/2026-10-26-full-spatial-comparison/` contains browser screenshots and receipts for both native Museum builds and the on-demand preparation.

Implementation adds `tools/probes/export_spatial_museum.gd`, `tools/export_spatial_museum.py`, `tools/prepare_spatial_views.py`, and web `src/app/api/map-comparison/prepare/route.ts`, extending the existing comparison adapter, renderer and interface.
