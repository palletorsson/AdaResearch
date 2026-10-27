# Grid / Museum / Void comparison

Update: the [full native comparison follow-up](2026-10-26-full-spatial-comparison.md) now replaces the historical Museum diagram with a fresh native build where available, adds full-window/solo/exploration/section views, and prepares additional maps on demand. The sections below describe the first footprint-comparison version.

The Three.js lab editor now has a read-only spatial comparison at:

http://localhost:3003/lab-editor?mode=void&floor=16&compare=1

The live Void editor also has a **Compare Grid · Museum · Void** link for the current floor. The comparison uses a single renderer and a shared camera. It offers side-by-side and overlay views, Plan and 3D orbit, per-source visibility and opacity, structure/artifact/route switches, and rigid alignment by footprint centre, front edge or explicitly selected artifact anchors. X/Z offsets and yaw affect the display only. One unit remains one metre; the source layouts are never resized to fit each other.

## What Rotation actually compares

| Source | Evidence | Extent |
| --- | --- | --- |
| Grid | The actual configured `GridSystem` for `Trans_Rotation`, exported through Godot; 12 original instances, plus structure | 39 × 73 m |
| Endless Museum | Historical built-hall occupancy ledger dated 2026-09-19; no artifact positions in this particular record | 62 × 77 m recorded footprint |
| Void | Current saved floor 16 through the existing live-editor adapter and exported models, including independent parts and construction | 42 × 18 m standard floor |

The Museum view is explicitly a footprint diagram. Its shallow slabs distinguish occupancy without inventing unrecorded wall elevations. It does not substitute a proposed plan or current Grid artifact positions for missing historical evidence.

The inspector exposes original Grid tokens and saved Void configuration. In this example, the Grid rotation array has two columns, while the curated Void version has one. Selecting an artifact highlights matching types across the sources; the UI does not claim that repeated occurrences or edited assemblies are identical. The user chooses the particular anchors to align.

The floor selector reads the saved spine. Other maps currently use source-cell Grid diagrams and labelled position markers until their native snapshots are exported. Recorded Museum artifact markers are shown only where recorded tile cells exist. Evidence and limitations are available in each source card. The first native Grid export in this feature is Rotation.

## Read-only boundary

The comparison has no save controls or authoring calls. The new API implements GET only. Display alignment and selection are temporary view state. Returning to the live editor preserves the selected floor and trial. This view does not simulate Godot physics, certify walkability or certify moving-artifact clearance.

The existing development server had stopped answering dynamic requests. Restarting that server restored port 3003; no saved layouts were changed. The normal browser remains the appropriate renderer when the in-app browser has disabled WebGL.

## Verification

`tools/export_spatial_comparison.py Trans_Rotation` completed under the existing native OS lock, exported 12 real source instances and structure, reported no export failures, and verified unchanged source map bytes. The manifest includes the source map SHA-256; a stale map snapshot falls back to labelled source-cell data.

`node tools/check_spatial_comparison.cjs` passed against port 3003. It checks the real GLB headers, source-cell identities and configuration differences; metre-preserving anchor alignment under a 90-degree rotation; rejected API writes and invalid floors; side-by-side/overlay/opacity/visibility/camera/anchor controls; one browser canvas; no uncaught page errors or authoring POSTs; and unchanged hashes for the Grid source, Void room/frame files and both Museum ledgers/overrides. Additional read-only API checks returned 200 for floors 5, 7, 12 and 59, including explicit non-native Grid fallback notes.

The target page compiled and rendered successfully. The repository-wide TypeScript check still reports pre-existing errors elsewhere; its final log reports no errors in the new comparison modules. No desktop gameplay or headset acceptance is claimed by these browser and snapshot checks.

Evidence: `doc/ports/2026-10-26-spatial-comparison/` contains the native export receipt, native manifest, browser receipt and three actual browser screenshots.

## Implementation

Web repository `../ada_encyclopedia`:

- `src/lib/spatial-comparison.ts`: read adapters for the three coordinate frames and source evidence.
- `src/app/api/map-comparison/route.ts`: GET-only document endpoint.
- `src/components/lab-editor/VoidComparison.tsx`, `comparison-scene.ts`, `comparison-transform.ts`, `comparison-types.ts`, `comparison.module.css`: comparison interface, actual models and rigid display transforms.
- `src/app/lab-editor/page.tsx` and `VoidEditor.tsx`: comparison route and current-floor link.
- `public/spatial-comparison/Trans_Rotation/`: native source snapshots and manifest.

Godot repository:

- `tools/probes/export_spatial_grid.gd`: actual GridSystem snapshot using existing model-export helpers.
- `tools/export_spatial_comparison.py`: serialized native export runner and source fingerprint.
- `tools/check_spatial_comparison.cjs`: browser and source-preservation checks.

