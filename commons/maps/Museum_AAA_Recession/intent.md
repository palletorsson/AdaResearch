Concept: A room for the synthesis `recession_hall`, whose first axis is a DEPTH axis and whose
first axis is therefore the one the capture rig is structurally worst at seeing. The sweep camera
stands at yaw 0.62 / pitch −0.26, and in the hall's own constants the three run directions project
to 1.000000 (`abreast`), 0.966390 (`strata`) and 0.257081 (`nested`) — the property the axis is
NAMED after arrives 3.89x fainter than a sideways row. Wave 22 photographed it and returned
CONDITIONAL at 1.29% of frame, which is a fact about a standpoint rather than about the object. A
visitor is not a standpoint. This room is the experiment that number could not run: it puts seven
configurations where a walking body has to move between them, and it withholds the frontal view —
the sweep's view — at the two places where the frontal view is the one that lies.

Room shape: the plan winds inward and never repeats a move. A vestibule 5 cells wide narrows to a
3-cell corridor 11 long whose flanking walls are 4 m for the first half and 2 m for the second —
the default cell's own ratio, halved, built at body scale in the one leg of the building that is
purely distance. The corridor opens into a chamber closed by a screen wall with a single gap, and
the gap is between the two works, so the only way out of the first room is the standpoint at 90°
to both of them. East of it the enfilade: two IDENTICAL bays, edge to edge, pierced by one aligned
door — succession without containment, which is what `abreast` means, laid out as architecture
rather than described. Then the run laid up: three terraces at heights 1, 2, 3, climbed on two
ramps, with the `strata` work on the top one so a vertical run is met by ascending it. Then the
descent, two steps down and west, into a closed heart no other part of the map can see into,
whose exit is a hole in its floor. The nest runs out of margin and the floor stops.

Technical angle: seven placements, all four values of `recession` and all three of `inheritance`.
Every token carries its own rotation. The hall yaws itself 0.62 rad (35.5227°) inside its scene to
face the sweep camera, and the registry's `footprint_note` says a map must either expect the
opening 35.5° off the grid or pass its own angle; this map passes its own — 144.48 to face −z,
324.48 to face +z, 54.48 to face +x — so every opening squares with the room that holds it and no
work is oblique by accident. Every axis name and value was taken verbatim from
`commons/artifacts/registry/recession_hall.json` `dna.axes` and re-asserted against the finished
map file, against the `.gd` @export_enum hints and against the RECESSIONS / INHERITANCES consts:
a misspelled value is refused in silence by `Object.set()` and would ship as a room of identical
defaults that looks exactly like a room of variants. Both axes are String enums, so
`cabinet_sweep.coerce()`'s numericising trap cannot fire here.

Critical angle: the room refuses to be a specimen row, and it refuses on the artifact's own
grounds. A corridor of four evenly spaced front-facing versions is a taxonomy display, and it is
also, precisely, the sweep — one standpoint, one bearing, everything measured against everything
else from the same place. So no two works here share a standpoint and no two are seen the same
way: two are met head-on down a long approach and then in profile through a gap you cannot avoid,
two are met by walking through equal rooms in series, one by climbing, and two by passing between
them. The building makes the same argument the axis does — recede, then set side by side, then
stack, then collapse — and the visitor performs the argument rather than reading it off a sheet.

THE WALKABLE NULL: `recession_hall#recession:nested#inheritance:equal` at row 8 / col 17 and
`recession_hall#recession:collapsed#inheritance:equal` at row 12 / col 17, the two works in the
heart. They are identical by construction — at ratio 1.0 every level is 0.30, the loss term
`sizes[0] − sizes[k]` is zero for every k, and `nested`'s seat and `collapsed`'s seat reduce to the
same four positions at the same four sizes. On a sheet that is 0.00%, a cell you skip. Here they
stand 4 m apart, symmetrically about the only path to the exit, each 0.765 m off its own wall so
even their setting is mirrored, and both face the door you enter by. To notice, a visitor has to
do the thing this room has already taught them twice: not accept the frontal view. From the
doorway they are two of the same. Walking between them, the flanks are also the same — and the
flank is exactly the view that separated the two works in the first chamber, where `nested` at
0.5 and at 0.85 recede visibly and differently. The gesture that made the difference legible
earlier makes nothing appear here, and that is the finding: a nest with no margin is a collapse.
Containment is not a place, it is a DIFFERENCE. When successive levels stop shrinking there is
nothing for one to be inside, and the axis quietly loses a value — which is the state
`animated_folding_past.gd:196` and `:203` ship at `abreast` and `strata` without saying so.

Key artifacts: recession_hall ×7. Chamber A holds the two parents' own shipped pictures side by
side — `nested`+`halved` is example_8_2_recursion_vr's, `nested`+`eased` is animated_folding_past's,
and the family has no shared default on the second axis, which is why they are two objects and not
one. Bay 1 and bay 2 hold `abreast`+`halved` against `abreast`+`equal`: four squares of 0.30,
0.15, 0.075, 0.0375 against four squares of 0.30 filling the hall edge to edge, both of them
`abreast`, which is the whole finding about a shared vocabulary. The terrace holds
`strata`+`halved`. The heart holds the null.

Gap: not walked. No Godot was run for this map (the wave orchestrator serialises all Godot runs),
so the room is validated by `tools/map_pathfinder.py` and by a re-read of the finished
`map_data.json` against the registry, and not yet by a camera or a headset. Two things want a
first walk: whether the 2.53 m clear opening in chamber A's screen reads as a threshold or as a
squeeze, and whether the two terrace ramps are climbable in VR as comfortably as the pathfinder
says they are. The map is also not yet a member of any sequence — its teleporter is
`next_in_sequence` and currently leads nowhere.
