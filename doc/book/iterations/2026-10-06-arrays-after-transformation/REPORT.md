# Arrays after Primitives and Transformation

6 October 2026 · Reading and lesson proposal · Five halls, existing order.

**The sequence belongs here. Its illustrations and reflective texts already carry a strong progression; its tutorial companions need rebuilding to meet the standard of the first two sequences.**

Primitives gave us ways to construct a body and keep a trace. Transformation gave us ways to place, turn, resize and collect a body. Arrays now asks: **how do we give many bodies distinct places, change one, and use a small rule across them?** The familiar cube continues as a `BoxMesh` instance. We do not need to return to constructing its faces.

The five plates show selected reflective encounters with imagined staging and schematic overlays. They help judge the narrative; they are not screenshots or proof that a learner program works. All five were inspected alongside the current manuscripts and selected implementation sources.

## What the student brings

| Earlier work | Its new use here |
| --- | --- |
| Trace: arrays, indices, append, a condition and a neighbour loop | Store and visit entries whose addresses must remain stable after collection. Lists are familiar; this use of them is new. |
| Grid: a saved trace and a separate rounded representation | Keep stored information distinct from the way we place or display it. Generating positions from addresses does not recover a lost original trace. |
| Primitives: functions, repeated construction and separate instances | Make another cube with its own transform. A second reference to one cube does not make a second cube. |
| Transformation: position, rotation, scale and collection by overlap | Place copies from indices; collect one copy; apply a known turn at every tile address. |
| Transformation: elapsed time and arrays of door-part references | Revisit stored entries through a clock, while keeping the record separate from playback. |

This is a proposal based on what the chapters expose and practise, not evidence of a student's mastery. Transformation remains a review draft. No additional preliminary programming chapter is needed before drafting Arrays.

## Array — the same cube, an address kept

Return to the cube collected in Trans_Pre and make four independent copies, at positions calculated from their indices. Keep cube references separate from a four-entry occupancy record. Walking into cube 2 removes that cube and writes zero in slot 2; cube 3 keeps its index and position. Then extend the same construction to a four-by-four plane stored as `grid_data[x][z]`. Change spacing and turn one selected cube without changing its address. The new work is the relation between an address, a value and the body it describes. Check that collection changes exactly one entry and that editing one instance leaves its neighbours alone. Carry the record and the construction into the next hall.

**Focus:** independent instances; indexed writes; retained slots; nested traversal; address versus position.

The row and plane are two beats within this hall. Reuse the overlap detection from Pre, but make its callback remove the collected instance rather than the whole study. For the first beat, a plain list is sufficient; explain that the installed row wraps its list in an outer display row, `array_data[0][i]`. Keep the changing museum floor and Molnár study as wider encounters. Deterministic variation of one familiar transform is enough for an optional return; random generation is not required here.

## Tutorial_3D — another index, the same relation

Extend the cube arrangement upwards. Keep the same cube and collection operation; add layers to the occupancy record. Connect the displayed address `[x,y,z]` explicitly to the museum's storage convention `values[y][z][x]`: `[1,2,0]` reads `values[2][0][1]`. The previous plane used `[x][z]`, so copying it into a layer requires a declared conversion, not just another pair of brackets. Change and read one unequal-index address, then change the spacing without changing its stored value. Flight and the selection marker are supplied museum facilities. Check that the chosen cell changes, its neighbours do not, and separate rows do not share mutable storage. Carry a volume that can be addressed reliably.

**Focus:** nested layers; storage order; bounds; address-to-position mapping.

This is the largest conceptual step. Use a small table and one selected cell before displaying all 64. Open structures and suspended fragments can return in the reflective track without becoming extra required constructions.

## Tutorial_Tiling_Floor — let the address choose a turn

Return to a plane and replace its cube occupant with the familiar black-and-white diagonal motif. Use the four-by-four comparison to predict a quarter-turn count at each address, then generate the field with a function such as `(column + row) % 4`. Rotation is already known; the new use is letting an address choose it. Change one term and compare the global pattern, then add one exception at a named cell. Enlarge the field using the same rule. Here zero means no added turn, not an empty slot. Supply and declare the small image renderer, since the museum's patterns are images on continuous support. Check the turn values and that an exception changes only one cell. Keep the rule and its result for Walls.

**Focus:** address-to-turn function; remainder; local exception; local rule producing a global pattern.

This is the sequence's strongest bridge from Transformation. The renderer must be printed or supplied as an exact named dependency when the full lesson is written; calling an unexplained helper would not meet our tutorial rules. We need one understandable rule before explaining the other museum patterns.

## Tutorial_Tiling_Walls — give the result another surface

Use the image made in Floor on an upright panel in the museum. Keep its rule and exception, and compare what can be read face-on, at an angle and from farther away. Turn one motif within the image, then compare that with rotating the panel and its collision: one changes the picture; the other can open a passage. Reuse the known transform and the distinction between visible mesh and solid boundary. The installed eye chart, guarded hinge and landing provide the larger encounter. Check that changing the picture leaves the panel's pose and collision unchanged. Carry the pattern as something that can be placed and viewed in different ways. This hall consolidates previous work and needs no compulsory new syntax.

**Focus:** reuse; image versus receiver; local surface axes; appearance versus access.

The full lesson must name how the learner's image is retained and assigned in this hall. The installed rooms sharing a generator does not mean they already transport the student's output. Use a saved result or an explicitly carried study; decide and test that connection when writing the lesson.

## Tutorial_Disco — read an arrangement through time

Bring back the clock and the addressed plane. First single-step a black-and-white pattern while every tile keeps its place; the rule now receives a changing phase. Then make a short Boolean score, initially one track, and let a separate playhead read its entries in a repeating count. Reuse remainder to wrap the index. Change one event at fixed tempo, then change tempo while keeping the score. Supply the sound receiver and use the museum's four-track, sixteen-step instrument as the fuller encounter. Check event order, wrapping and retained elapsed time, with an explicit policy for a long frame. Stop the score while the floor continues. Carry a stored arrangement and a timed reader that can vary independently.

**Focus:** Boolean events; cyclic reads; playhead; tempo versus stored pattern.

Keep this in two beats: the floor's changing phase, then the score's returning reader. The clocks remain separate. Mapping sixteen steps onto twelve floor columns is a later comparison, not a prerequisite. Footsteps are not recorded into this score. Sound synthesis and rebuilding every dance-floor mode are outside the required lesson.

## How the two texts can work together

The tutorial makes an address usable: select, read, change, display. The reflection asks what the record leaves out: why a place is empty, whose body can reach it, why a flat pattern looks raised, what makes a wall a boundary, or whether moving with music means being measured. These questions are already present in the five finals.

Preserve the order. Give the first hall two short steps, teach the storage convention carefully in 3D, let Floor show a small rule's large consequence, allow Walls to be a quieter reuse chapter, and give Disco its two distinct readers. Keep the required studies black and white or grayscale before Colour. Existing accent colours in the museum and illustrations are not a new colour-programming lesson.

## Current gaps and the next executable step

| Hall | Current tutorial companion | Work required |
| --- | --- | --- |
| Array | `tutorial.md` is absent | Write a complete row → plane lesson from the known BoxMesh and overlap construction. |
| Tutorial_3D | Encounter notes and two source-edit fragments | Write the storage conversion, complete reduced program and assertions. |
| Floor | Focus labels and a short encounter note | Provide the rule, declared renderer and independently testable comparison. |
| Walls | Operating notes | Specify the learner image handoff and a small reuse lesson. |
| Disco | Older 17×17 footstep-recording example with unresolved dependencies | Replace it with the current separate floor/score model and complete executable code. |

**Write Array first.** Test the exact printed program in native Godot: four instances; collecting slot 2 leaves slots 0, 1 and 3 intact; the record keeps its length; one transform edit is local to its instance; spacing changes positions, not addresses; the plane has independent rows. Include a second collection attempt and boundary cases. Require a student variation beyond copying: choose a different slot and predict the result before running it.

Then test the 3D continuation against that output, the pattern rule at known addresses, the actual Floor → Walls transfer, and Disco's score/timing distinction. These are proposed acceptance checks, **not tests executed in this review**. Complete code and its dependencies must appear in the tutorial; the existing museum supplies room, light, player and declared interaction infrastructure.

## Source trail and scope

Read: the live `array_tutorial` sequence; all five `final.md` texts and four available `tutorial.md` companions; current execution-plan records; the 4 October Arrays review and guide; current Transformation Pre and Pit drafts; all five selected Array illustration plates.

Selected source checks: `algorithms/arrays/row_3_x.gd`, `grid_2d_4x4.gd`; `commons/artifacts/regularity/array_flight_lab.gd`, `tiling_pattern.gd`, `disco_controls.gd`; `commons/audio/sequencer/step_sequencer.gd`, `sequencer_ui.gd`. These confirm the different storage conventions, generated pattern image, four-by-sixteen score and separate clock connection. No museum runtime or headset session was run.

This report adds a proposal only. It does not replace tutorials, edit finals, change museum code or change plan acceptance. The source manifest records the files checked so the next pass can detect drift.

**Compact AI brief:** Existing museum. Known BoxMesh + Pre overlap → four slots → XZ plane → explicit YZX volume → address-to-turn rule → same image upright → phase and score readers. Retain indices after collection. Separate references, occupancy, orientation and events. Molnár/floor writer/flight/hinge/synthesis not required rebuilds. Walls is reuse. Disco has two clocks. Full printed minimal programs; exact dependencies; native assertions; independent variation. Draft Array first.
