# Colour rooms from the drawings

6 October 2026. Actual Endless Museum changes and native visitor-height captures.

## 1. Color_Context_Placed

Twenty-three existing stacks now sit on low pale plinths. Their plaques use a quiet stone background. The long room gains wall columns and a neutral floor, so the different arrangements carry the colour.

Checks: 13 passed. [After](after/Color_Context_Placed/room.png) · [Before](before/Color_Context_Placed/room.png).

## 2. Color_Flashlight

The beam experiment gains pale walls and a quieter floor. The four lamps, coarse sphere, white-light room and aperture studies remain. No extra gallery lights were added here: the coloured sources need to remain legible.

Checks: 14 passed. [After](after/Color_Flashlight/room.png) · [Before](before/Color_Flashlight/room.png).

## 3. Color_Nails

A simple pale plinth supports the manicure display. The two selector stands and their labels are quieter. The small and giant hands still receive the same nail-colour changes.

Checks: 14 passed. [After](after/Color_Nails/room.png) · [Before](before/Color_Nails/room.png).

## 4. Color_Rainbow

White wall columns frame the existing arch, low steps, mushrooms, banners and pickup path. The celebratory colour now sits against a calm architectural background.

Checks: 13 passed. [After](after/Color_Rainbow/room.png) · [Before](before/Color_Rainbow/room.png).

## 5. Color_Pillar

The pillar bases are pale and their address labels are smaller. The dark floor, thirty-five samples and matching colour ceiling remain. No fill light was added over the fog-like field.

Checks: 15 passed. [After](after/Color_Pillar/room.png) · [Before](before/Color_Pillar/room.png).

## 6. Color_Grid_Pallet

The editable floor keeps its real per-cell colours, with fine joints in place of the triangular wire overlay. The console gains a pale base. The huge spectrum forest becomes a smaller side study, opening the view across the floor.

Checks: 16 passed. [After](after/Color_Grid_Pallet/room.png) · [Before](before/Color_Grid_Pallet/room.png).

## 7. Color_Paint

A plain white frame and solid pale cabinet gather the canvas and thirty spray cans. The existing wet surface and automatic painter remain active. The photograph catches a real aerosol mark forming on the canvas.

Checks: 14 passed. [After](after/Color_Paint/room.png) · [Before](before/Color_Paint/room.png).

## 8. Color_Walls

Neutral walls and floor let the twelve translucent partitions read more clearly against their surroundings. The furniture, gaps, pane positions and collision remain. The opacity control still changes the panes together.

Checks: 14 passed. [After](after/Color_Walls/room.png) · [Before](before/Color_Walls/room.png).

## Verification

113 native checks passed across eight installed halls: retained grid instances, one-time installation, perimeter placement of architectural collision, supported and unobstructed photograph positions, plus focused checks of the existing colour receivers. These are desktop runtime checks; headset comfort and controller use still need a VR walk.

The images use Godot 4.6 Compatibility on the RTX 3070, at 1.7 m above the floor. They load the actual museum and installed artifacts through an isolated runner. Moon phase is fixed for comparison; the after photographs hide the desktop HUD. Paint’s after camera moves 0.7 m nearer the canvas to clear a wall collider; Walls moves 1 m back from its console. The other viewpoints match. Dynamic marks and animations can differ between photographs. Existing shadow banding remains visible on some surfaces. The renderer does not reproduce the comics’ illustrated lighting exactly.

Existing boot UID, Rainbow viewport-texture and cleanup messages are retained in stdout.log; they also occur before this pass. No new script or shader compilation errors were observed. Tutorial manuscripts and final.md were not edited in this architectural pass.

## Reproduce

`python -X utf8 tools/colour_gallery_review.py after`

`python -X utf8 tools/build_colour_gallery_review.py`

Reload a Colour hall in the museum to see its new finish. The gallery_finish map flag opts in only these eight halls.
