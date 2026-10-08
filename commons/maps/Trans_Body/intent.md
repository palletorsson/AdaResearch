Concept: The chapter turned on the visitor. Earlier rooms already invited riding, grabbing and crossing. This room makes proximity itself a continuous input to the surrounding material. This room makes the visitor's approach an input. It compares reversible rotation, irreversible cell deletion and reversible scaling; the carve is a change of occupancy, not an affine transformation. Three throats, each cut to the width of the thing standing in it: a wall of slats that opens where your body is, a lattice that loses every cube you touch, a field of blocks that shrinks as you approach. The room is the operand.

Sequence role: After Trans_Scale and before Trans_Pit. The room asks what the space remembers: the slats close, the cut remains, and the blocks regain their size. Pit then changes the input from proximity to time. Its growers do not sense approach.

Technical angle: All three artifacts answer a BODY, and finding one is most of the work. An Area3D must mask physics layer 20 (the grid and VR player) AND layer 1 (the endless museum's Walker, a bare CharacterBody3D in group em_walker and nothing else) — masking only the player layer does nothing in the museum with no error and no log line. It must then refuse most of what that returns: hazard_creature_base extends CharacterBody3D, so "any CharacterBody3D" hands the room to its own traffic, and each artifact must also refuse its own bodies, because a StaticBody3D defaults to layer 1. The VR body is in no group at all, so it is known by the XROrigin3D above it. Nothing here needs a manager, a provider or map data.

Critical angle: A boundary that is a function of who is standing at it is not the same kind of object as a boundary. Every slat is where it always was and the wall has stopped being an obstacle, which is the chapter's question about invariants asked from the far side. And the lattice keeps the one record the other two do not: the wall and the field return to how they were found, but the open-topped cut remains, so the room afterwards is a discretised record of the collider that crossed its low volume. That is also the room's one authorship problem — the second visitor arrives at the first visitor's corridor.

Key artifacts: approach_wall (five broad boards swinging out of the plane, aperture 1.3 m, reach 2.6 m, guaranteeing a 0.62 m hole); carve_grid (11x4x11 cubes at 0.34 m, bite 0.16 m, regrow 0 so the open-topped cut does not regrow; #leak:keep also restores recorded cells on a return while the session record survives); approach_scale (nine blocks at 1.5 m spacing, 1.15 m each, shrinking to 0.34 of size within 2.2 m); dark_sphere at the far end remains a secondary legacy placement, not an additional book encounter.

Gap: This hall depends on live artifact response, and the pathfinder cannot tell — it reads the structure layer, where all three throats are plain floor, and knows nothing about artifact colliders. commons/testing/probe_trans_body_sealed.gd is what actually gates the room: it sweeps a shoulder-wide sphere across each throat in the live physics world and asserts the widest free run is under 0.52 m (measured 0.20 m at all three), with the open floor before each gate as the negative control (8.45 m). Nobody has walked the room in VR.

## Why the throats are three different widths, 2026-09-08

Each throat is cut to its own artifact rather than to a house measure, because the
seal is the design and it is arithmetic, not intention. approach_wall is 4.40 m
wide, so its throat is five cells (5.00 m) and the side gaps are 0.30 m.
approach_scale is 4.15 m, five cells again, gaps 0.42 m. carve_grid is 3.69 m and
would leave 0.65 m either side in a five-cell throat — walkable — so its throat is
three cells (3.00 m) and the lattice overlaps the walls by 0.35 m on each side.
A shoulder is 0.52 m. Change any of those exports from a map token and the room
can quietly become a corridor with sculpture in it; the probe is the thing that
would notice.

## Alignment review — 2026-09-17

The low four-layer lattice makes a trench for a standing body; it does not surround the shoulders or head. Closure captions now request stepping clear instead of claiming the action has already finished. Their reach matters: after crossing, the last blocks can still respond to the visitor. The closing question is which body the sensing and clearance assumptions accommodate.
