# Void mode in Lab Editor

Delivered: http://localhost:3003/lab-editor?mode=void&floor=3

User intent: edit Point Lines in Three.js using real artifact models; fixed floor/pillars/open shafts, no automatic room walls or ceiling; full browser width; save the same layout used in VR.

Implemented in sibling `ada_encyclopedia`: `VoidEditor.tsx`, `void-scene.ts`, `void-model.ts`, `void-editor.module.css` in `src/components/lab-editor/`. `/lab-editor` selects the Void mode through the query string. Legacy lab remains available. VoidEditor is statically imported so its CSS survives development reloads.

The source of truth remains `commons/void/rooms.json`; structural dimensions remain `commons/void/layout.json`. Existing `/api/void-layout` handles validation, revision conflicts, backup and atomic writes. Added validation-only requests. Whole work areas and named Point Lines children map to the existing `config.parts` overrides. No game interaction scripts, tutorial or final text changed for this task.

Browser: select/drag, grid snap, R/90-degree rotation, arrow nudges, numerical XYZ, original-placement reset for parts, undo/redo, orbit/plan/free-fly walk, optional partitions and existing construction props, encounter route overlay. Hide panels expands the canvas. Floor selector also shows the roof, Point One and Coordinates. Authored partitions are editable objects, not generated boundaries. Walk is a layout preview without game physics.

Real model pipeline: `tools/export_void_editor.py` uses the existing isolated Void test project and `tools/probes/export_void_editor.gd` to snapshot built scene meshes to `ada_encyclopedia/public/void-models`. 89 GLB files, about 1.7 MB; source hashes and per-part transforms in manifest. Label3D text is recreated as browser canvas labels; animation, physics and scripts remain in Godot. Export again after changing artifact geometry. Current exporter depends on the staged project named by `ada_run/void-game-test/latest.txt`; set GODOT_EXE to override the local engine path. No shader fallbacks were needed for this export. Geometry exports are previews, not replacement game assets.

Verified this task:
- 7 editor/model/transform contracts in `ada_encyclopedia/scripts/test-void-editor.cjs`.
- Browser changed PoliceBarricade position and rotation, saved through the shared API. `tools/probes/void_web_editor_probe.gd` loaded actual `void.tscn`: 7 assertions passed, including original script, collision, checkpoint and pose.
- 4 save checks: validation-only doesn't write; stale revision rejected; prop in shaft rejected; browser undo/save restores complete original document.
- Changed web files and dependency closure: TypeScript zero diagnostics.
- Browser drag, add/undo crate, floor selection, top view and full-width controls checked.

Evidence: `doc/book/iterations/2026-10-18-void-lab-editor/`. Production rooms and layout restored byte-for-byte after tests; screenshot is the original arrangement. No physical headset playtest. Save to VR, then restart The Void to load changes. Do not restart the user's open Godot editor automatically.

Next: user curates the encounter path using this editor. Keep one shared placement layer. Don't bake edits into artifact scripts or turn every object into an independent scene rewrite. Individual part placements still require a Godot walkthrough for reachability and safe travel.

## Copy / paste follow-up

Added toolbar Copy, Paste and Duplicate, with Ctrl/Cmd+C/V/D outside form fields and walk mode. Editor-local clipboard stores a deep snapshot, supports pasting across floors, and offsets each paste by at least 0.5m. Unique IDs, undo/redo and removal supported. Test copies were undone; production rooms were never saved during this follow-up.

Props/partitions use their existing lists. Pasted artifacts live in optional floor `copies` (up to 64), sharing existing supply stations while leaving the four primary assemblies intact. Each copy retains its source artifact key/config and `config.editor_source` for the exported preview. Single-part copies use `config.only_parts`; the original factory builds a fresh instance, removes unwanted children and prunes reset arrays before applying the copied pose. No duplicate of an already-running/generated node. `floor_content.gd` loads copies through the same artifact placement path. Coordinate-system point origins now initialize per instance on any floor. Native editor document/canvas also display and edit copied entries.

Verification: `ada_encyclopedia/scripts/test-void-copy.cjs` (8 contracts), `tools/test_void_copy.py` (8 save checks + 13 Godot/native-editor assertions), existing 7 web model contracts, native editor import/runtime regression and scoped TypeScript (zero diagnostics). Runtime tests use the shared writer to a test file and the game's `--void-draft` option. Evidence in `ada_run/void-copy-test/`. Browser toolbar copy/paste, duplicate, validation, remove and undo were exercised. Browser automation intercepts system clipboard key chords; physical Ctrl+C/V was not independently tested. Physical headset still not tested.
