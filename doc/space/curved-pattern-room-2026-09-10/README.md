# Curved pattern room — 2026-09-10

User asked for patterns to become a whole curved room, or the space occupied by the player. Built an inhabitable studio bay in Pattern_Foundry's runway annex.

The opt-in room uses an 8 m diameter, 300-degree wall, 3.2 m height, 4 m entrance, outer plaster backing, circular floor and roof with a 3.3 m opening. Eighty collision boxes follow the wall. The print and backing are separate. Shadow casting on the curved shell and roof is disabled so the coarse museum sun-shadow edge does not obscure the pattern. A fixed local fill light supports legibility. The studio moved to (30,11), room centre (30,10); existing runway and original teaching grid remain intact. New floor fills unused northern annex cells, with a three-cell doorway through row 18.

ROOM WALL and ROOM FLOOR register with the existing receiver protocol; ROOM selects both. ALL FIVE and ARCHITECTURE preserve their existing member sets. A 60 cm initial card span makes the print readable at room scale. Source identity, live/hold/return-to-loom and undo work as before. Arc-length wall mapping and planar floor mapping retain metre spacing but do not promise seam alignment. Loom fallback uses bounded 30 pixels/metre for the large surfaces; the studio remains GPU-rendered.

Validation: 86 studio/adapter/room checks and the 99 original Foundry regression checks. Added tests for room placement, scope membership, wall arc/height, collision, wide entrance, route from the catwalk side aisle, independent floor hold, ownership and bounded fallback. The route test uses actual floor height, accounting for the grid's buried origin. Captures inspected from inside and at the entrance. Headset interaction/performance untested.

Updated book discovery passage, technical account and workshop guide. Evidence is in doc/research/possible-bodies; source snapshots are excluded from Godot import. No commits.
