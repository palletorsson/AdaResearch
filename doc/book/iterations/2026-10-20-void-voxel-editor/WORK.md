# Void voxel editor — Translation

Completed 2026-10-20. No tutorial.md or final.md changes.

## User-facing result

Open `/voxel-editor?mode=void&trial=transformation&floor=3`.
Paint cube (1m), slab (0.25m), original wp wedge (1m rise, 2m run) and suspended platforms. Height is cell base except platform deck top. Sparse cells preserve air underneath. Paint/erase uses the selected height; selection supports copy, move, rotate and removal. Platform travel is local to facing, speed in m/s, pauses in seconds (return wait is one second longer).

Original Translation crossing migrated from the assembly into eight static cells and one platform. Two slabs at Y=.75 were stamped through the live UI. Temporary brush-test cubes removed. Other floors unchanged. Reopen trial after autosave; no live Godot hot reload.

## Implementation

Web sibling ada_encyclopedia:
- src/app/voxel-editor/page.tsx: Void route mode, normal voxel mode preserved.
- src/components/lab-editor/VoidEditor.tsx: paint tools, height, precise stamps, platform inspector; existing autosave/history reused.
- src/components/lab-editor/void-model.ts: shared construction entries and transformations.
- src/components/lab-editor/void-scene.ts: continuous plane painting and shared construction preview.
- src/components/voxel-editor/void-construction.ts: sparse brush operations.
- src/components/voxel-editor/void-construction-view.ts: Three geometry, deck destination preview.

Godot:
- commons/void/construction_grid.gd: original meshes batched in MultiMesh; retained collision shapes; real moving bodies.
- commons/void/floor_content.gd: loads construction from floor records.
- commons/void/trials/transformation/suspended_carrier.gd: configurable travel speed and pause.
- commons/void/rooms.schema.json and tools/validate_void_rooms.py: construction validation.
- commons/void/trials/transformation/rooms.json: floor 3's editable crossing.

## Verification

`node tools/test_void_voxel_editor.cjs` — 9 checks.
`python -X utf8 tools/test_void_voxel.py` — 78 desktop / synthetic XR checks.
`python -X utf8 tools/test_void_voxel.py --capture` — three Godot Mobile screenshots.
Live CUA browser: continuous five-cell stroke, erase, UI slab stamps, reload, platform controls, shared Lab listing. See browser-checks.json.

Headset not physically tested. Native probes explicitly stop sound and allow the real-time mixer to release streams before scene teardown (fixed-FPS tests otherwise outrun audio cleanup). No audio behaviour changed.
Whole-web TypeScript checking has pre-existing failures outside changed Void files. Editor materials/lighting are approximate; geometry and native collision are tested. Grid painting is a layer brush; it does not infer the top of the object under the cursor. Wedges occupy two metres, so paint appropriate spacing. Per-cell Undo currently records each cell in a drag stroke separately.

## Evidence

before-rooms.json preserves the previous assembly layout. save-receipt.json is the initial migration receipt; later slab stamps were saved by browser autosave. images/provenance.json records native camera capture conditions. Six existing save warnings refer to other floors.
