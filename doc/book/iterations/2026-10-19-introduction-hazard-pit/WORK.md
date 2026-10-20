# Introduction / dedicated lethal pit — 2026-10-19

User permits either a floor cut or an opening built from cubes/wp and requires
death on falling into it. Chosen: raised construction pit, preserving tower
shafts for descent and keeping the whole encounter movable in the lab editor.
No tutorial.md or final.md rewrite. No curated-tower changes.

Crossing moved from shaft A to the central bay, rotated 90 degrees. Existing
18 bank cubes and six wp ramps retained; ten unit cubes enclose the sides.
Five captions + ferry anchor + new LethalPit = 41 editable parts. Crossing is
5 x 3 m inside, one metre below the bank tops. Glowing red bottom lies above
the existing slab; this is not a new hole through the concrete floor.
The first placement left the side cubes walkable. The subsequent user request
requires an ordered route; seven editable partitions now block those bypasses.

`commons/void/lethal_pit.gd` owns surface, two bounded shadowless lights and
Area3D. Feet in its local footprint at the surface trigger existing Void health
depletion. No alternate player/death implementation. Visual and contact share
one editor part; copies and rotations stay aligned. Copying only the platform
excludes the hazard. The original platform/carry logic is unchanged this turn.

Production desktop + synthetic XR: 121 assertions passed. Fatal fall from one
metre, red fade, restart on Introduction, repeated death, safe riding, departure,
both clear shafts, editor-copy platform and moved/rotated hazard all checked.
Eleven editor checks passed. Desktop work-light collision caught and placement
corrected before completion. Removed an obsolete under-platform scenario:
the new construction sits on the slab, so there is no standing room beneath it.
Original preceding report retains the shaft version's support checks.

Headless shutdown intermittently reports retained resources. A run with all
gameplay assertions passing still failed the command due to that error;
the following verbose run passed the command, with a RefCounted/ObjectDB warning.
Do not claim that longstanding teardown issue is fixed. Physical headset
comfort/performance and older menu integration caveat remain separate.

61 native-render assertions passed; screenshots and checks are in images/. Final editor model export uses
the same floor recipe and placement. Snapshot before.json protects Pre, roof,
original chapter texts/museum map data and the curated tower. Layout API save
uses revision checks and updates Desktop/Ada Void/trials/transformation/rooms.json.
The previous report remains an historical record of the shaft crossing.

## Steering: force the ordered segments

User asks to go through the different segments, like the original museum.
Read original Trans_Introduction/final.md and map_data.json: travelling cube,
growing cube, then turning plank. Only travelling crossing is built in this
trial. Do not claim the full three-part Introduction has been implemented.

Four 4.2 m unfinished partitions divide north arrival from south departure.
They stop at shaft edges, not across shaft interiors. Three further partitions
block access to A from the arrival side. The crossing is the walkable threshold.
All seven are editable standard rooms.json wall objects. No separate game-state
lock or invisible wall. Native tests attempt walking/jumping across all four
divider sections and the cube rim; verify the exit approach is blocked from
the north; walk the far-side route and land safely below via A.

Source before-route.json preserves the initial open layout from this turn.
Final room save has only the pre-existing Pre access-footprint warning.
