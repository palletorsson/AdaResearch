# Understand the arrangements before combining them

The Three.js comparison now has a spatial study and a shared curation notebook:

http://localhost:3003/lab-editor?mode=void&floor=16&compare=1&grid=historic

This follows the existing historical/current Grid, current Museum and saved Void comparison. It adds a common description of their setups and a way to record which particular qualities to keep, adapt or avoid. It does not automatically choose a winning map or apply a layout.

## Working together

1. Select the map and Grid edition. **Understand setup** compares envelope proportions, measured geometry, recorded routes and missing evidence.
2. Use **Study in plan** to isolate a source and show mesh envelopes. Solid outlines are projected bounds; dashed outlines are a 0.9 m study margin. Grey marks environment pieces. A green circle marks an entry only when a spawn utility/native Museum entry supplies it.
3. Select one artifact, read its source intention and configuration, and inspect its real geometry. An authored yaw does not establish its active front. For Rotation, judge how the player crosses tilted cubes rather than whether the arrangement looks orderly.
4. Record a quality under **Carry forward**, against the whole arrangement or an individual object. Choose path, spacing, staging, interaction, substrate or another quality, and keep/adapt/avoid. Explain the encounter or spatial principle we want to preserve.
5. Discuss those choices before changing the live floor. A route from Grid and a support/enclosure from Museum can inform the Void without copying either whole room.

The notebook survives reloads and is shared through `commons/data/spatial-studies/<main-or-trial>/<map>.json`. Edits to a note retain its original source receipt. Conflicting saves are rejected rather than silently overwriting another change. Hiding the study/full-window inspection retains an unfinished note.

The receipt includes source edition/revision, path, envelope and saved route, plus available object ID, pose, configuration, intention and footprint. Historical Grid choices retain the Git baseline. The UI flags changed source snapshots and distinguishes a choice from the other Grid edition. It does not archive a private copy of every model binary.

**Download study JSON** includes the common source document, analysis and notebook. It waits for notebook loading so that notes cannot silently disappear from the download. These same records are available to an assistant through `/api/map-comparison` and `/api/map-comparison/study`; visual judgement need not be rediscovered from a screenshot every turn.

## What is measured

The server reads actual exported GLB JSON/accessor extents and node transforms, applies the same authored poses and model scales as the viewer, and groups known assembly parts. Missing/unsupported geometry remains unmeasured. A shared-floor controller is a separate dependency, never an invented stand-alone cube.

Construction uses the existing editor renderer's geometry, excluding translucent destination ghosts and guide lines. Furniture/construction are measured as environment pieces and excluded from exhibit-pair/neighbourhood warnings. Current registry/catalogue descriptions and available `@identity` headers are exposed as current intentions. Historical Grid headers remain from the archive; modern headers are never substituted into them. Ambiguous registry scene matches are left unresolved.

Computed results are cached by source and model-file signatures. GLB measurement reads metadata rather than loading all vertex buffers or launching Godot. Three warm local Rotation requests took approximately 221–313 ms during development; this is a local observation, not a general performance guarantee. No new native captures were needed.

## Rotation findings

| Source | Envelope | Measured roots | Distinction |
| --- | --- | --- | --- |
| Before-Museum Grid | 7 × 53 m | 8 plus 1 shared-floor controller | The floor itself carries the axis-banded lesson. |
| Current Museum | 62 × 87 m | 26: 15 exhibits, 11 environment | Compare enclosure, supports and circulation independently from the embedded lesson. |
| Current Void | 42 × 18 m | 148: 13 exhibits, 135 environment | A six-point saved guide totals 44.62 m; nine exhibit envelope pairs warrant inspection. |

The old `rotate_grid_cubes` header describes reading the Grid as a score, with alternating axis/flat row bands. Its small independent-exhibit coverage is **not** evidence of wasted floor: the learning object is largely the substrate. A transfer must preserve that relation before deciding how to compress or fold its path.

Likewise, a close pair is not a defect. Interlocking pieces, shared assemblies and deliberate suspense may be the point. A useful notebook choice explains what the proximity does.

## Limits

- Bounds are projected axis-aligned envelopes, including empty corners and space between assembly parts. Percentages are not solid occupancy, usable floor or a quality score.
- Coverage/spacing use envelopes intersecting a base-floor study band 0.05–2.1 m above the floor. They do not slice the meshes or establish access along raised routes.
- 0.9 m padding and 3 m neighbourhood grouping are explicit study heuristics, not compulsory design standards or inferred conceptual groups.
- Unknown active fronts, reach, sight lines, motion sweeps, collision, interaction and headset experience still require inspection. No route is invented where none is recorded.
- Diagrams/anchor-only sources remain incomplete until an explicit native preparation. Existing historical material/dependency disclosures remain in place.

## Verification and preservation

`node tools/check_spatial_study.cjs` checks independent transformed-mesh/rectangle fixtures, unknown geometry, vertical/environment exclusions, shared-floor dependencies, stable revisions, notebook save/edit/reload/remove, immutable note receipts, conflicting/invalid saves, source-edition recall, JSON download, draft retention, two-map browser operation and one renderer. Test notes are removed; pre-existing notes are preserved.

`node tools/check_spatial_comparison.cjs` retains passing native/current source, camera/material/section, rigid alignment, source configuration, map-switch/disposal and read-only layout checks. A scoped TypeScript check of the eight changed entry modules plus their dependencies and Next environment declarations passes. The broad repository check still contains unrelated pre-existing errors and is not reported as a successful build.

Saved rooms, standard floor dimensions, original map data, Museum plan/overrides and layout ledgers were hashed and remained unchanged. No artifact mechanics, curation, source text rewrite or new Godot/export job was performed.

Implementation: `src/lib/spatial-setup.ts`, `spatial-intent.ts`, `spatial-notebook.ts`, the study API, `SpatialStudy.tsx`, and the existing comparison adapter/types/UI/renderer/styles in the encyclopedia repository. Evidence is in `doc/ports/2026-10-26-spatial-study/`; runtime checks are under `ada_run/spatial-comparison/study-review/`.
