# Point Trace: a grain to draw with

Four local edits complete this close reading of Point Trace. The chapter's structure and its strongest actions remain intact.

## Decisions

1. Repair the cumbersome sentence introduced in the preceding pass. Use a plain account of waiting for at least five millimetres of movement before considering another position. Keep the relation between a still drawing, continuing time and the absence of pause duration from the position list. The exact comparison-reference update remains in technical.md; the text does not claim that path length accumulates or that the reference is always the last saved point.
2. Give the rounding code one coordinate to act on. For blue, 80 mm is 0.08 m; an X reading of 0.05 rounds to 0.08. Y and Z follow the same operation. Explain duplicate rejection as why passing the movement test need not add a corner.
3. Stay with the possibilities of the gridded drawing. Stored positions lie on the grid while joining segments can run diagonally. Replace the repeated reminder that all sampling is partial with a distinction a visitor can look for in the shape.
4. Recover “Looking at the line need not spend another place in it” from the earlier draft. Keep finite retention explicit, without making filling a 4096-position list a required task. This also reflects the author's request to preserve pleasure and usefulness alongside limits.

## Kept

The opening loop, pause and release; the list explanation and eleven-point display example from the prior pass; the four resolution settings; the wrist negotiating with spacing; the invitation to make a corner one can return to; the drawing stick and whiteboard; the transfer into Grid; all code, footnotes and artifact markers. Point One and Point Lines are unchanged.

The existing stick and board passages already contain particular bodily investigations and do not need equivalent edits merely for consistency. A final reading of the complete chapter supports continuing to Grid.

## Source correspondence

Current Point_Trace placements set dot resolutions to none, 10, 40 and 80 mm. The shared recorder converts millimetres to metres, applies snappedf independently to X/Y/Z in free space, rejects a shaped position that approximately matches the last retained one, and draws a LINE_STRIP between retained points. Spatial rounding does not require axis-aligned segments.

The five-millimetre comparison is against the last movement-gate-passing position. Passing advances that reference before shaping. The source and technical companion retain this precise account; the main prose names the operation at the pace of the encounter.

The scene capacity is 4096. Appending beyond capacity removes the oldest entry. Fading is disabled. Looking at a released drawing adds no points to it. The retained development opportunity for a short capacity experiment is preserved in the purpose notes; no new control is promised here.

## Checks and next step

Text, purpose snapshot and core manuscript hash synchronized. Existing code and footnotes preserved. No script, map, scene or role changes; no new Godot, headset or learner run. Full-book and audiobook captures remain frozen.

Next: Point_Line_Grid. Its opening already receives the released drawing and explains a metre coordinate and an integer index as two names for a place. Follow that encounter rather than repeating Trace's explanation of rounding.

See changes.json, Point_Trace.diff and checks.json for paragraph purposes, exact edits and preservation checks.

## Shared snapshot reconciliation

The shared purpose build encountered an independent Animated Cube edit from side instrument to front instrument, a plinth-height token change, and three shifted evidence line ranges. Its manuscript, map and script were preserved. The existing paragraph purpose and evidence references were reconciled to those current files so the ten-hall view could validate. See shared-snapshot-reconciliation.json. This adds no editorial change to that hall.
