# Array_Patterns address lesson — 2026-09-10

User authorised the next step in the ground-up progression from arrays and colour to patterns, shaders, space and bodies. Headset and gesture work remain deferred.

Primary tunnel moved from (6,9) to (24,11) in a connected east bay; original grid structure changes only at the three-cell doorway x18,z11-13. All other artifacts retained. pattern_tunnel_machine and pattern_tile_brick remain the two book/primary anchors.

An opt-in address lesson fixes the previous room's initial asymmetric4x4 motif under P1. It provides COL +, ROW +, FACE, CELL SIZE, GRID and UNDO, a sixteen-cell source display and a physical cell indicator. Cell pitches40/60cm map one swatch pixel per cell; the four-cell motif spans1.6/2.4m. Each face has independent UV orientation. The inspector selects complete cells and leaves partial boundary cells visible but unselected.

Six-metre passage,3.6m width,3.2m height, side/ceiling collision and open ends. Printed floor elevated18mm over the grid. Print/backing separation15mm avoids coincident surfaces; shell shadow casting disabled for this fixed comparison. Printed grid visibility never changes collision.

44 desktop museum assertions pass: actual pointer input, source-byte preservation, modulo return, actual quad-UV/marker agreement, spacing, undo, physical passage, side wall collision and bay approach. Captures inspected from bay, console and inside. Earlier captures caught an obsolete console left by deferred rebuild naming; _build now removes old children before adding new names. Added assertion that retired consoles are absent. Also corrected generic group labels to match the engine enum.

The generic world-Z timed reveal remains a known separate issue; this lesson is fully revealed with animation disabled, and the book does not describe a working portable reveal. No headset/performance claim. No commits.

Updated seven room documents and published array-patterns.html plus guide evidence. Snapshots in before/ are excluded from Godot import. Next: Symmetry_Seventeen; later body/garment transfer and shader conclusion remain open.
