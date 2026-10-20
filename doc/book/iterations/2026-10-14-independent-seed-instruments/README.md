# Independently placed seed instruments

Palle chose independent movement for the time/frame study, MOVE / KEEP recording sphere and source console in Random_Definition. The existing room arrangement is retained. Each instrument now has a saved floor position and rotation; moving the bench or travelling-sphere exhibit leaves these saved poses in place.

In the web editor at `http://localhost:3003/long-museum`, open **Random_Definition** and use **Linked instruments**. Select a numbered marker, then drag it or click a floor cell. The selected instrument also has X, Z and rotation fields. Its position uses the editor's existing automatic/manual save and undo system. The console's buttons, labels and support move together. The travelling sphere itself remains an ordinary map artifact.

## Storage and runtime

The seed bench's existing map cell carries `#part_movement_sampler:x,z,yaw`, `#part_frame_timing:x,z,yaw` and `#part_source_console:x,z,yaw`. X and Z use map cell-edge coordinates; yaw is degrees around Y. These are floor poses, independent of the bench's height and scale. There are no duplicate seed controllers or new random samples when a part moves.

The museum and grid loaders supply an `artifact_map_frame` transform relative to the artifact's parent. This keeps authored coordinates correct after a hall is translated, rotated or loaded with the museum vestibule offset. Instruments remain owned by their original exhibit, with their complete transforms held independently. Visibility envelopes include the moved instruments. Missing or malformed pose values retain the original layout; the editor reports malformed values. Editing one part in a legacy layout also records its siblings' current positions.

The implementation spans this museum repository and the sibling `ada_encyclopedia` repository. `before/` preserves the pre-change files; `web/` preserves the final web files. Neither repository was committed or pushed in this turn.

## Evidence

- `museum.json`: **150/150** native checks, including individual movement, unchanged sibling poses, unchanged seed receipts and route RNG, console grouping, replay controls, and a fresh scene reload under a translated/rotated hall. `museum.log` has no script errors.
- Web tests: **14/14**, including the existing cache checks, editor/native position agreement, independent movement, malformed positions, exact undo, and an actual cell-edit route save in a disposable repository. Stale saves are refused.
- Scoped TypeScript compilation passed for the editor, resolver and registry endpoints.
- Research inventory/comparison receipts refreshed; **61/61** plan checks passed.
- `independent-instruments.png` was visually inspected: the original arrangement and grouped console are intact.

The first native run exposed a missing map-frame handoff on the main artifact loader. Its partial 127-check report is not acceptance evidence. The corrected run is `ada_run/encounter_pilot/Random_Definition/independent-seed-instruments-02`.

Browser drag interaction was not visually exercised: the previous browser reload was blocked by the browser URL policy, and no alternative browser workaround was used. Headset usability, performance and learner understanding were not tested. Floor checks validate the selected anchor cell; they do not guarantee clearance around the entire instrument.

Reproduce the native checks with:

```powershell
python -X utf8 tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-14-independent-seed-instruments/museum_probe.gd --output-tag independent-seed-instruments-new
```

In `ada_encyclopedia`, run `node --test tests/long-museum/linked-parts.test.mjs tests/long-museum/strip.test.mjs`. Set `LINKED_PARTS_REPORT` to a fresh native report to include live API/native agreement.
