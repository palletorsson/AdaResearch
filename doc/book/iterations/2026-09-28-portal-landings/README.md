# Supported portal entrances — 2026-09-28

User request: after removing the lounge, give every next hall a small solid foothold at its entrance.

## Implemented

- The shared portal builder adds a 2.2 m × 3 m, 28 cm thick static landing slab beneath each doorway. Its top aligns with the measured floor. The black surface has a thin pink/violet border.
- Arrival is 1.15 m inside the doorway, outside its trigger. Both the landing position and the walking lane beyond the slab are checked for support and body clearance.
- Newly created collision is flushed through physics before transferring the visitor. Forward and return travel use the actual entrance/exit pad, rather than another independent floor search.
- Direct launches now wait on the existing supported loading floor while the first hall builds. This removes the obsolete four-metre drop at the old lounge coordinates for ordinary halls.
- Point Zero retains its authored opening. XR arrival moves the physics body and tracking origin together. Saved desktop viewpoints are applied after the arrival handoff.
- Only one hall remains resident. Standalone grid navigation is unaffected.

## Verification and limits

See verification.json for current runs. Desktop and real XRTools physics with simulated headset tracking exercise direct launch, forward crossing, return, settled feet under gravity, arrival clearance, and one resident hall. Point Zero's special entry position/height has a separate assertion. An isolated probe drops a capsule on eight locations across both orientations of the slab, with no underlying floor, at a four-metre elevation.

The screenshot is an actual Godot render of Color_Walls. No physical headset test has been performed and not every hall has been traversed. Full-project runs still log unrelated grid/artifact warnings (including GridSystem player lookup and callbacks from freed grids); passing navigation assertions do not mean those logs are clean.

## Files

- commons/scenes/endless_museum.gd — startup handoff
- commons/scenes/em/em_portal_stream.gd — supported arrival locations and validation
- commons/scenes/em/em_portal_frame.gd — physical and visible slab
- tools/probes/hall_portal_navigation.gd — real museum regression
- tools/probes/portal_landing_support.gd — isolated slab physics

Backups of the working files before this fix are in ada_run/portal_landing_repair/. changes.diff records this task alone, without earlier uncommitted museum work.
