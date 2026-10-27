# Point Coordinates — carrying light

20 October 2026. Continue Model B from Point One, preserving the existing writing and the tutorial's same-point construction.

## What changed

The new literary passage follows the small black point through pickup, carried light, coordinate reports and the arrival target. It preserves the original questions about what the label names, apparent stillness belonging to a report, addresses requiring a reference, and a destination becoming an instrument through repeated arrival. The final gesture opens a relation between the held point and another place, preparing for Lines without making Model B announce the next lesson.

The tutorial is an edit route through the existing Point One `point.gd`. It changes the body type and pickup settings, adds a readout, and reuses Point Zero's per-frame reading. The existing mesh and collider remain untouched. A linked full file and folded complete listing allow comparison; the existing student-code marker remains available to the starter builder. The review page omits that repeated full listing when printed.

The earlier Point Zero and Point One texts are unchanged.

## Source-verified tower

- `commons/void/rooms.json`: floor 2 is Point Coordinates, with `point_held`, a frame adopting `point_one_main`, and separate WORLD/LOCAL cards on channel `void_coordinates`. The frame is unconfined and has display scale 1.35.
- No `basin` record is present on this floor. `commons/void/basin.gd` returns without building a basin for an empty specification. The slab remains solid outside the standard shafts. The earlier glass-basin prose is preserved in the previous draft, not presented as installed.
- `the_invisible_point` is not placed on this floor. Its brass-arrow case passage remains in the previous draft for later use.
- `commons/primitives/point/point_condition.gd`: the held branch reuses the original pickable, assigns the stable coordinate ID, uses a 0.07 m sphere radius and dark material. The study deliberately retains the learner's 0.14 m radius.
- `commons/void/floor_content.gd` attaches `carried_point_light.gd` to that actual pickable. Pickup shows a warm OmniLight; drop hides it. The sphere stays black and shiny, with emission disabled.
- The source pickable starts frozen and uses ORIGINAL release behaviour. The explicit FROZEN mode in the learner reconstruction achieves the intended leave-it-in-place behaviour without depending on that inherited initial state.
- `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd` feeds the named point's global position or frame-local `to_local()` result to matching-channel cards. Frame scale participates in this conversion.
- `commons/primitives/point/coordinate_readout.gd` formats two decimal places. The tutorial's unchanged `str(Vector3)` is explicitly distinguished from that formatting.
- The configured `drag_point_target` uses its arrows encounter, seven labelled balls, drop height 3.4 m and rearming. Its default catch radius is 0.45 m. The target scans eligible coordinate points; unlike the cards it does not exclusively select `point_one_main`. Entering the region triggers, remaining inside does not, and departing rearms.

The source `map_data.json` and `technical.md` describe the museum's arrangement, including the old basin. They are collection context, not authority for the current Void placement.

## Interpretation and proposed fiction

Model B's hesitation around objects continues the habit described in Point One. WORLD's negative height connects the descent to the roof reference. The carried light makes another relation perceptible without becoming a lesson in lamp construction.

Exact paths, small movements, illumination patches, readable digits, pauses, settled balls and desires are literary proposals. These source checks do not establish their particular appearance or timing in a headset. No new runtime test was performed for this text revision.

The literary account is not a script the player must obey. The player may pass the point, release it early or ignore the target.

## Verification

`checks.json` records the checks. Applying the tutorial's published edits to the complete Point One student file reconstructs the existing complete Coordinates student file exactly, apart from final whitespace. The full marked code block is unchanged; relative links resolve. Hashes protect the preceding texts, tower layout and complete student script.

No layout, lighting, interaction code or generated starter project was modified. Before/after drafts and line diffs are stored alongside this page.


## Later authorial correction

The current passage includes the [situated-care correction](../2026-10-20-model-b-situated-care/README.md): general intellect allows learning and revision; care, attachment and bias shape attention. The roof-to-floor handoff is now “I jump” / “I land.” Earlier snapshots retain their original wording. No gameplay or tutorial changed in this correction.
