# Array_Patterns — addressed surfaces and physical passage

Arrays supplied row/column addresses and Colour supplied palette indices. Tutorial_Pattern separated source editing from repeating rules. This room holds a fixed asymmetric source and P1 translation while exposing surface addresses, physical cell spacing and face orientation.

## Current encounter

`pattern_tunnel_machine:0:0#lesson:addresses#tunnel_length:6#group_index:0` occupies (24,11), floor offset zero. A new east bay connects through x18, rows11-13. The original tunnel placement at (6,9) is cleared; all other artifact instances remain. The original structure changes only at those three doorway cells. The tunnel extends six metres down its local -Z, is 3.6m wide and 3.2m high. Its console stands to the right of the mouth so the passage stays open.

`tunnel_address_lesson.gd` attaches only to this explicit configuration. It retires the generic console (rebuilds now detach queued children before assigning new node names), fixes the source to the previous room's initial 4x4 motif and sets P1. This is an authored copy, not persistence of a visitor's edits. It holds the four surfaces fully revealed and disables automatic fill. The generic machine's existing reveal and controls remain available in other configurations. Its group-name list was corrected to match the existing engine enum: CM at4, PMM at5, PMG at6, PGG at7.

## Source and sample

The tunnel generates a 32x32 RGBA8 swatch using `WallpaperGroups.get_symmetric_color`. In this lesson the group is P1 and the domain is 4x4, so the source lookup is `[row % 4][column % 4]`. The inspector labels both surface and source addresses and highlights the source cell and its location on the chosen face.

The source swatch is fixed while inspector settings change. Four steps along a surface return to the same source coordinate without returning to the same physical position.

Each mesh uses its own UV coordinates. With surface extent `extent` and cell pitch `pitch`, the lesson sets:

```gdscript
mat.set_shader_parameter("tile_reps", extent / pitch)
mat.set_shader_parameter("pattern_reps", extent / pitch / 32.0)
```

The shader samples the swatch using the second quantity and draws cell divisions using the first. Source pixels, drawn cell joints and collision are different representations.

CELL SIZE selects 0.4m or 0.6m per source-addressed cell. A four-cell motif therefore spans 1.6m or 2.4m. At 0.6m the floor has 6x10 complete cells; a 3.2m-high wall has five complete cell rows plus a 0.2m strip. The inspector cycles over complete cells, leaving cut boundary cells visible but unselected.

## Face coordinates and seams

Floor UV column increases across local x; its row increases from the far end towards the mouth. On the right wall, column increases from far end to mouth and row descends from the ceiling. The indicator is positioned from these same mappings. The desktop probe reconstructs UV coordinates from the actual quad transform and checks that the indicator lands at its named address on both faces.

Each face restarts its own coordinates. Equal pitch does not promise seam continuity. The present lesson exposes this independent mapping rather than offering an unimplemented seamless wrap control.

## Physical support

The existing four quads remain the printed surfaces. Printed faces and their backing do not cast shadows in this fixed comparison; the backing is separated from the print by 15mm to avoid coincident-surface interference. A thin backing with collision bounds both walls and the ceiling. Both ends are open. The floor print sits 18mm above the authored grid; the grid carries the visitor. GRID changes only the drawn joints via an instance-local shader uniform. It never alters the meshes, backing or collision. A translucent marker has no collision. The source is inspected here, not repainted.

The console provides COL +, ROW +, FACE, CELL SIZE, GRID and UNDO. Its 32-entry history restores the complete inspector state. Headset and gesture work remain deferred.

## Verification and limits

50 desktop museum checks pass, including pointer operations, source-byte preservation, modulo recurrence, equal physical scaling, marker-to-quad UV agreement, traversable ends, wall collision and the bay approach. Three captures document the installation and source display. No headset performance claim is made.

The old generic reveal shader measures world-Z, which is unsuitable as a portable tunnel-local reveal coordinate. This lesson is fully revealed and does not exercise that animation. A future timed-reveal pass should fix and test translation/rotation invariance before making claims about its rate. The brick station remains a second primary comparison; it was not rebuilt in this pass.

## Raised platform route

The platform is one metre above the lower floor, authored as structure height2 over x22-26,z5-11. Three wp:180 wedges at x23-25,z12 form the entrance ramp; three wp:0 wedges at z4 form the descent. The wp scene runs two metres along its slope. A flat northern landing connects to the gallery through x18,z1-3; the southern opening remains x18,z11-13. Side wings seal the lateral gaps between tunnel and perimeter at z8, so the crossing between those openings passes through the tunnel. The side console is lowered relative to the raised artifact to remain reachable from the lower approach.

Added desktop checks sample physical floor and wedge heights, verify the metre rise, block both lateral bypasses and check the entrance/exit routes. The platform raises the tunnel through normal grid placement; its source addressing remains unchanged.
