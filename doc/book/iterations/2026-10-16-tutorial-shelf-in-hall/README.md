# One number / four consequences enters the hall

16 October 2026. Palle asks to find yesterday's basic random transform and colour examples and add them to the map.

The existing [learner shelf](../../studies/randomness-shelf/shelf.tscn) was built on 15 October but was never registered or placed. It now has a [museum adapter](../../../../commons/artifacts/randomness_tutorial_shelf/randomness_tutorial_shelf.gd), registered as `randomness_tutorial_shelf`, in Random Definition at source-grid cell **(8, 13)**, centre **(8.5, 13.5)**, facing 180 degrees. It stands beside the colour-grid window. Refresh the web map or reload the desktop hall to see the addition.

One stored value `u` changes X position, uniform scale, cube rotation (`u * TAU`, in radians), and sphere hue (`Color.from_hsv(u, 0.8, 0.9)`) together. The eight draws start at the hall seed, initially 435. Its first value is approximately 0.498111. The window instead consumes three successive draws for an RGB cell; these are different colour assignments.

NEXT advances through the retained values. REPLAY returns to the first. KEEP saves exact values, seed, sample index and X extent. LOAD restores the last kept study, including after a new visit, and restores its seed to the hall. A held instrument blocks a seed-changing load. All record fields are validated before any hall change. The notebook's last-file pointer is separate from its uniquely named records.

The 26-line teaching script is unchanged. The museum adapter handles the shared seed, tabletop collision, bounds and persistent last-file pointer. Tutorial instructions and plan now identify the installed version; the writing wall has a Tutorial-only magnet and a conceptual link to the colour window. The final chapter and selected contour print remain unchanged. The 48-value bench remains the first research pilot.

## Verification

- Existing exact-printed-program verifier: **39 checks pass**.
- Real museum integration: **35 checks pass**, including source placement and floor, four mappings, real button signal connections, shared seed, exact KEEP/LOAD, malformed-record rejection, held-instrument refusal and later-visit recall.
- Web APIs return the shelf in both long museum and writing wall at the saved position; Tutorial tag is retained.
- Map pathfinder: passes; existing teleporter-height warning remains.
- Native renders inspected: [shelf](shelf-in-hall.png), [surroundings](shelf-beside-window.png). Capture uses an isolated museum run; no user control or save pointer is overwritten. The existing museum cleanup reports an ObjectDB leak on exit; no script errors occur in the final run.
- Headset reach and independent learner reconstruction have not been tested by a person.

The first proposed placement at (9, 13) was moved left by the museum's route repair. The authored cell was changed to (8, 13), and the final run confirms the shelf stays there. The museum still performs its existing route adjustment on the neighbouring colour window.

Reproduce the hall check:

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --output-tag tutorial-shelf --probe doc/book/iterations/2026-10-16-tutorial-shelf-in-hall/museum_probe.gd
```

See [native report](museum-report.json), [learner-script report](learner-verification.json) and [web verification](web-verification.json).
