# Compare the pre-Museum Grid

The comparison now defaults to the Grid as authored before the Endless Museum:

http://localhost:3003/lab-editor?mode=void&floor=16&compare=1&grid=historic

**Grid edition** switches between **Before Museum** and **Current source**. Museum and Void remain the current reference/target arrangements. The purpose is to recover earlier spatial decisions without confusing later Museum-era edits with the original Grid.

## Historical boundary

The first addition of `commons/scenes/endless_museum.gd` is commit `62e08730f1e4d1db2dd599f1238cf9fb74a26218`, dated 2026-07-31 09:16:47 +02:00. Its parent, `a36f33c996004abcdc67ea2a0ac3fce72eba42fd`, dated 2026-07-31 00:59:50 +02:00, is the selected baseline. This is a repository snapshot date, not a claim that every map was authored that day.

This distinction matters: later history includes the 2026-08-31 commit `d7a9dbd15` (“the ruling becomes the maps — 145 sources rewritten from their halls”) and subsequent Rotation revisions. Current `map_data.json` therefore cannot stand in for the pre-Museum map.

`commons/data/spatial_comparison_sources.json` records the baseline, boundary and scope. Server reads use exact `git show <commit>:<map path>` data, cached by commit/map. Maps absent at the baseline are identified as absent; the current layout is not silently substituted. Their historical preparation action is disabled/rejected, while Current source remains separately available.

## Prepared examples

| Map | Before Museum | Current Grid |
| --- | --- | --- |
| Rotation | 7 × 53 m, nine authored placements | 39 × 73 m, twelve placements |
| Triangle | 7 × 22 m, sixteen authored placements | 13 × 30 m, ten placements |

These are actual historical Grid builds, using the old Grid system, old registries, old artifact scenes/scripts and versioned resources from the selected tree. The isolated source snapshot is stored on D: under the existing generated-storage root. The working checkout is never reset or checked out to the old revision.

Rotation includes eight independently exported mesh models and one controller. `rotate_grid_cubes` deliberately has no separate mesh: its original script transforms the shared `GridMultiMesh` and matching collision cubes in axis-banded rows. Its effect is in the room's floor geometry. The comparison identifies it as a shared-Grid controller, shows a wire authoring marker, frames/highlights the shared structure when selected, and exposes its archived `@identity` header. This preserves the distinction between transferring a stand-alone object and recreating a spatial lesson that depends on its substrate.

The source map title/description, archived scene path, intention header, exact token/configuration and a compact old/current size/type comparison are available for inspection. Token differences are reported literally; renamed concepts are not asserted to be equivalent.

## Appearance and compatibility limits

**Godot reference** shows a real render of the archived Grid scenes. It helps inspect shaders and material details that static GLB export simplifies. It is an inspection camera capture using Godot 4.6, not a replay of an earlier complete game session, player rig, environment or saved settings. The reference can open as a full image and is usable even when WebGL is unavailable. Switching back to Plan/3D/Explore resumes the single comparison renderer.

The historical Git tree omitted the XR framework and some support resources. Installed `godot-xr-tools`, `map_tool_3d`, `element_editor`, `tutorial_text_editor` and the audio bus layout are supplied as disclosed compatibility support. Dependency file counts/hashes are retained in the snapshot receipt. Project name/UID paths and import-time autoload/scan settings are isolated runtime setup; authored map/artifact scene/script bodies are retained from Git. Windows archive line-ending conversion is accounted for: the map is pinned to exact blob bytes, and relevant scene/script contents are verified modulo checkout CRLF/LF conversion.

Triangle additionally referenced four unversioned rack materials (`rack_metal`, `rack_panel`, `rack_panel_dark`, `rack_accent`) that have no Git history. Installed material substitutes are explicitly flagged in its source card, full-window legend, evidence notes and native-reference caption. Triangle's layout/code are historical; its rack palette is not accepted as an exact historical restoration. The first capture with missing materials was rejected rather than published as clean evidence.

A complete import of the isolated resource tree is cached once for later maps. Documentation/tool directories are excluded from that export-only import scan, and autoloads are paused only during resource import then restored for capture. The export adapter reuses current geometry collection helpers without importing modern Void scene dependencies into the old authored project.

## Workflow and preservation

Historical native geometry for another map is prepared with the existing **Prepare full views** action. The selected edition travels through the API/job runner, with separate historical/current status files and the existing shared OS native lock. The completed Triangle historical preparation exercised this generic path after Rotation. Preparation remains one bounded user action; no recurring loop was created.

All comparison alignment, sectioning, selection, camera and edition choices are read-only with respect to maps and saved room arrangements. The new preparation endpoint writes generated models and receipts only. Existing Museum/Current Grid/Void views remain available, and failed exports retain an explicit diagram/error state.

## Verification

`tools/export_historic_grid.py Trans_Rotation` passed native load/export and exact original occurrence checks. Twenty relevant map, Grid and artifact files were checked against the historical blobs. Triangle's successful run checked 36 relevant files and exported its sixteen original placements. Both completed without load/export errors; the historical runtime's shutdown leak warning is recorded separately. No button/grab/mechanics or headset acceptance is claimed.

`node tools/check_historic_comparison.cjs` passes:

- exact parent boundary before the first Museum script;
- nine original Rotation source cells/types versus twelve current instances;
- immutable blob/manifest/source provenance and real GLB/PNG files;
- explicit handling of a current map absent from the old tree;
- historical/current edition switching, overlay and one renderer;
- shared-floor controller role and original intention header;
- native reference display and return to 3D;
- native reference with forced WebGL failure, without an obstructing graphics-error card;
- historical Triangle preparation and prominent material-substitute disclosure;
- no uncaught browser errors, authoring requests or changes to saved rooms/map/Museum plan/overrides.

The existing `tools/check_spatial_comparison.cjs` also passes with `grid=current`, retaining the current native Grid/Museum/Void comparison checks. The target page compiles. The broad repository TypeScript run retains pre-existing errors elsewhere and reports none in the comparison modules or preparation route.

Evidence: `doc/ports/2026-10-26-historic-grid-comparison/` contains browser screenshots, both historical export receipts, preparation status, source manifests and the native reference. Heavy archived sources/import caches remain on D:.

New implementation files: `commons/data/spatial_comparison_sources.json`, `tools/export_historic_grid.py`, `tools/probes/export_historic_grid.gd`, `tools/check_historic_comparison.cjs`. The existing preparation runner, comparison adapter/UI/renderer/types and routes were extended to select and disclose the historical edition.
