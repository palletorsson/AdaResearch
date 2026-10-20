# Cloth becomes a suit

Installed in **Tiling → Ribbon Patterns 03**, cell `(6,12)`, beside the fabric studio and mirror. All prior artifacts remain.

1. At the Jacquard studio, weave at least two picks and press **SAVE CLOTH**.
2. At this table, press **LOAD LOOM**. It reads the committed crossing and yarn-colour record, including custom edits. A supplied tartan starts the table when there is no saved cloth.
3. Inspect the ten labelled jacket, sleeve and trouser panels. **CUT** follows their edges. **ASSEMBLE** carries and curves them onto the fitting figure, one at a time. Each operation lasts 20 seconds.
4. **PAUSE** stops the operation; **RESET** returns the same cloth to the layout. **CLOTH** cycles three supplied samples and starts a fresh layout.
5. **WEAR** uses the actual player wardrobe. The complete weave record is saved with the suit, independent of subsequent table edits. **TAKE OFF** returns to the previous outfit. The existing mirror also reflects this worn geometry.

## Boundaries

The ten-panel silhouette is a geometric tailoring demonstration, not a production sewing draft. Flat and curved panels retain their cloth UV addresses. The surface texture is derived from the recorded 96 warp crossings per pick; it is not a simulation of yarn cutting or sewing. Lapels, shirt insert and shoes are supplied trim. Sleeves follow tracked hands, with the torso and legs inferred by the existing museum avatar. Body-measurement fitting, cloth drape and seam tension are not implemented.

The familiar shader studio remains a separate source and skirt experiment. Making this suit does not grant progression or replace earned trophies. A failed save is reported; a missing/invalid cloth file leaves the table intact.

## Validation

`python tools/run_garment_tailor_review.py` runs native Godot assertions and captures the installed station in an isolated museum snapshot. Test saves use the report directory, never the visitor's wardrobe or loom save. Checks cover real loom handoff, gating, pause/reset, retained UVs, avatar application, fresh wardrobe restore, separation from later edits and clear standing approaches. Physical-headset comfort remains to be checked.

Report: `doc/book/iterations/2026-10-10-cutting-a-suit/index.html`.
