# Cloth becomes a garment

Installed in **Tiling → Ribbon Patterns 03**, cell `(6,12)`, beside the fabric studio and mirror. All prior artifacts remain.

1. At the Jacquard studio, weave at least two picks and press **SAVE CLOTH**.
2. At this table, press **LOAD LOOM**. It reads the committed crossing and yarn-colour record, including custom edits. A supplied tartan starts the table when there is no saved cloth.
3. Choose **SUIT**, **A-LINE**, **GOWN** or **PLEATED** from the front row. The fitting figure previews the shape immediately. The same cloth stays loaded. Dresses use four bodice, two sleeve and four skirt panels; the suit uses jacket, sleeve and trouser panels. **CUT** follows their edges. **ASSEMBLE** carries and curves them onto the fitting figure, one at a time. Each operation lasts 20 seconds. Choosing another shape starts a fresh layout.
4. **PAUSE** stops the operation; **RESET** returns the same cloth to the layout. **CLOTH** cycles three supplied samples and starts a fresh layout.
5. After assembly, **WEAR** dresses the active player: in VR, the person wearing the headset. Look down to see the garment; the sleeves follow the hand controllers. The nearby mirror sees this same worn body. The chosen shape and complete weave record are saved independently of subsequent table edits. **TAKE OFF** restores the previous outfit, including its shape and cloth if it was another tailored garment.

## Boundaries

These ten-panel silhouettes are geometric tailoring demonstrations, not production sewing drafts. Flat and curved panels retain their cloth UV addresses; shaping stretches the panels. The surface texture is derived from the recorded 96 warp crossings per pick; it is not a simulation of yarn cutting or sewing. Lapels, shirt insert, belts, stockings and shoes are supplied trim. Sleeves follow tracked hands, with the torso and legs inferred by the existing museum avatar. Body-measurement fitting, cloth drape and seam tension are not implemented.

The familiar shader studio remains a separate source and skirt experiment. Making this suit does not grant progression or replace earned trophies. A failed save is reported; a missing/invalid cloth file leaves the table intact.

## Validation

`python tools/run_garment_tailor_review.py` runs native Godot assertions and captures the installed station in an isolated museum snapshot. Test saves use the report directory, never the visitor's wardrobe or loom save. Checks cover real loom handoff, gating, pause/reset, retained UVs, avatar application, fresh wardrobe restore, separation from later edits and clear standing approaches. Physical-headset comfort remains to be checked.

Report: `doc/book/iterations/2026-10-10-cutting-a-suit/index.html`.

Dress extension: `python tools/run_garment_dresses_review.py`. Its isolated native checks cover all four shapes, cut/fold UVs, real selection-button receivers, wearing, fresh wardrobe restore, undo to a previous dress, legacy suit saves, and approaches in the live hall layout. Current images and evidence: `doc/book/iterations/2026-10-10-dresses-from-the-loom/index.html`.

VR connection: `python tools/run_garment_vr_player_test.py` creates XROrigin3D, XRCamera3D and both XRController3D nodes, activates the production PlayerCustomization wardrobe, and presses the real table receivers. Checks cover selecting the active VR wearer among multiple wardrobes, all dresses, looking-down visibility, headset position, controller sleeves, rig turns, mirror handover and TAKE OFF. Poses are simulated without OpenXR or a physical headset. Report: `doc/book/iterations/2026-10-10-dresses-on-the-vr-player/index.html`.
