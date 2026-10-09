# Enclosed entrance rooms

The former boundary landing cage is now a plaster entrance room: about 2.2 m wide and 3 m deep, with a solid floor, full-height sides and back, and a ceiling. A 1.12 m clear doorway and covered link lead to the original first floor cell. The existing pink return curtain remains behind the arrival point when a previous hall exists. The hall name is printed over the forward doorway. Materials share the museum wall and deck roles. The ceiling fitting adds no dynamic light or shadow pass.

Boundary `s` entrances now use the same enclosure as boundary `sp` entrances. Point Zero retains its special start. Interior and staged simulation spawn locations keep their existing safe placement; they are not blindly boxed over their exhibits. Existing explicit `portal_entry.cage` configuration still controls enclosure.

Point One already has an approach-triggered sliding door. Arrival validation now permits its moving leaves along the approach path while continuing to validate the exact landing, floor and fixed frame. The door opens naturally on approach; it is not removed or globally made non-colliding. The tests wait for it to open, then verify the actual physical path without the exemption.

## Verification

Three full-rig round trips pass: Point Zero / Point One, Point One / Point Lines, and Polyhedra / Animated Cube. Checks cover the ceiling and closed sides, solid landing, clear link into the first cell, actual door opening, forward and return travel, no bounds reset, and at most one resident hall. Direct Point One launch has an existing museum back wall inside the new room's back envelope; that existing wall closes the room there. A return curtain is only created when there is a previous hall.

`room.png` and `inside.png` are actual Godot renders. For the architectural capture only, the simulated player rig's visuals are hidden; normal in-game rendering is unchanged. Android deployment is recorded separately after installation.

## Quest deployment

Installed on Quest as Ada Research Zero One. Wake the controllers to launch it. Three desktop VR-rig round trips passed; physical headset walking remains to be tried. The APK was checked for the three updated scripts, the audio generator and absence of archived doc UID mappings. See deployment.json.
