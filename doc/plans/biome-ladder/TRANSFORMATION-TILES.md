# Transformation → Arrays → Colour — a shot keeps its abilities

Implemented 2026-10-13, following Palle's instruction: shooting a tile scales it by 0.8 and rotates it 22.5 degrees.

Each catalyst hit multiplies the receiving tile's current scale by 0.8 and adds 22.5 degrees around its vertical axis. Two hits give 0.64 scale and 45 degrees. The tile turns about its centre and remains seated on the floor. Both the formed hand sphere and the held catalyst use their real projectile collisions.

The white outlined floor in Transformation, checkerboard in Arrays and disco floor in Colour all have individual tiles. Each has its own matching collider; both turn and shrink together. A continuous dark backing stays solid beneath the tiles, so a revealed gap is walkable. Shooting the backing does not affect the old tile footprint. A cover hit does not affect the floor below it.

REST keeps the arrangement. RESET or a new START restores all tiles. Transformation, Arrays and Colour all retain this response. Arrays keeps its checkerboard; Colour adds recolouring to the same catalyst hit. Colour marks stay attached to the actual tile after it turns or shrinks. Shooting revealed backing does not paint through to the former tile footprint. Skull shots do not transform tiles in this pass.

## Evidence

`tools/probes/biome_transform_tiles.gd` is expanded to exercise Transformation, Arrays and Colour separately, including combined colour and transformation from one hit. **90/90 rendered checks pass, exit 0**, including repeated hits, collider/mesh agreement, player landing, held catalyst, REST/RESET, revealed gaps, source-stage isolation and scoped ability cleanup. Current evidence is in the regenerated report. Tests real mouse firing, repeated hits, held-catalyst firing, matching surface/collider height, solid revealed gaps, the real desktop player landing in a gap, cover rejection, REST/RESET, stage isolation and saved-ability restoration. No direct calls to the reaction handler.

Native before/after captures and logs: `ada_run/biome_transform_tiles/`. Same camera and motion phase. The transformed tiles in the capture were hit by actual projectiles.

Runtime edits: `commons/hazards/biome_ladder/ladder_encounter.gd`, `outlined_floor.gdshader`, new `outlined_tile.gdshader`. No tutorial or final.md changes. Headset movement and feel remain unverified.

Regressions after B13: Transformation cover 82/82, Colour floor 40/40, desktop input 47/47. All three processes exit 0; logs are in `ada_run/biome_transform_tiles/`. Existing ObjectDB cleanup warnings remain.

## B14 — cumulative tile response

Palle confirmed on 2026-10-13: keep tile scaling and rotation in Arrays and Colour, so every sequence adds to the previous one. Runtime now uses the same tile construction and transformation handler from stage 1 onward. Colour adds its own material response. Skull balls retain their existing Colour-only painting. Solid backing, REST/RESET and saved ability scope remain. Native comparison images: `arrays-after.png` and `colour-after.png` in the probe output folder.

B14 regressions: Colour 40/40, cover 82/82 and desktop 47/47 rerun after the cumulative change, all exit 0. Logs: `ada_run/biome_transform_tiles/cumulative-*.log`. Existing cleanup warnings remain.
