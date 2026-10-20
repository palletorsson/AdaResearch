# Noise / Random_Noise_Types as a separate Void trial

Palle approved the scouting proposal on 20 October 2026: build Random_Noise_Types as a
selectable trial floor, use the weather's glazed walls as partitions, keep the sampling
bench central, make everything editable in the lab editor, test it and show real
screenshots. The curated tower, the Transformation trial, the original map, tutorial
and final text are preserved by SHA256 checks against `before.json`.

## Built

- `commons/void/trials/noise/layout.json`: three levels (canopy, encounter, catch floor),
  corner pads B on floor 1 and A on floor 2, catch floor in the abstract style.
- `commons/void/trials/noise/rooms.json`: the six original artifacts with their museum
  configuration (`stand`, `size`, `count`, `seed`), each as its own editable record with
  its own overhead lead. The bench receives an explicit `seed: 31415`. Route captions,
  three work lights, a tarp scaffold, an unfinished stud wall behind the weather
  controls, and two one-metre concrete blocks (`construction` cells) carrying the
  miniature galleries at hand height.
- `commons/void/trials/noise/trial.tscn` and the `noise` entry in
  `commons/void/trials/playable.json` (title, label, notice, retry floors, spawn).
- `commons/void/game.gd`: the trial notice and desktop help read the trial's label and
  notice from playable.json; the Transformation strings are unchanged when no `notice`
  key exists.
- `commons/void/floor_content.gd`: after `add_child`, the mounted scene is renamed back
  to `Artifact` if its own `_ready` renamed it (geometry_noise does). Without this the
  exporter and the residency filter could not find the Uncertain Surface.
- `tools/probes/noise_types_trial_probe.gd`, `tools/test_noise_types_trial.py`,
  `tools/test_noise_types_trial_editor.cjs`.
- Exported geometry: `ada_encyclopedia/public/void-trials/noise/` (manifest + GLBs).

## Arrangement (floor-local metres, floor 1)

Arrival on the shaft B boards (11.7, 1.9), start spawn (13.4, 1.9). East wing: single
point frame (14.0, -1.2) facing west; sampling bench (17.6, -0.3) facing west; the
Uncertain Surface (17.0, -5.3) with its console on the south side; the needle field
(15.5, 5.5) and the five-colour sculpture (19.0, 5.5) on concrete blocks with consoles
facing north. Return along the south strip around B into the central bay. Related
Weather at (-1.0, 0.0): glazed walls at x 2.3, -1.0, -4.3 running eight metres along z,
controls at the north end (-1.0, -5.65), gold line at x -5.8. Leave through A (boards
at -8.3, -1.9 on the catch floor).

Measured bounds came from the probe's `--measure` mode (`measure/measure.json`), not
from registry footprints. Two provisional positions from the scouting report were
moved after measurement: the galleries had been placed where the weather controls now
stand, and a work light sat on the return path.

## Verification

`python tools/validate_void_rooms.py --trial=noise` (strict) and `--editor`: valid, no
warnings. `python tools/void_sequence_trials.py --check`: 25 trials, no problems; the
board now links the noise trial.

`python tools/test_noise_types_trial.py`: native Godot 4.6, desktop walker and synthetic
tracked XR, actual physics. See `tests/checks.json` and `tests/engine.log`.

`python tools/test_noise_types_trial.py --capture`: the same XR pass in the Mobile
renderer with screenshots in `images/`. Those first captures photographed the floor after
the player had descended; the Codex review's `capture_review.py` keeps the player on the
floor and its `review-images/` are the published views.

The 129-check headless record (`tests/checks.json`, 08:57) predates the probe's last edit
(08:59, which moves the photo block before the departure). The capture run at 09:0x ran
the final probe's XR mode in full; the final probe's desktop mode has not been re-run. A
rerun at 09:18 crashed inside Godot's allocator before the first floor was built, with
0.4 GB of physical memory free and two other Godot instances open (`tests/rerun-0918-crash.txt`).
Rerun `python tools/test_noise_types_trial.py` once the machine has memory; it rewrites
`tests/checks.json`.

`python tools/export_void_trial.py noise`: real GLB snapshots for the lab editor.

`node tools/test_noise_types_trial_editor.cjs` (server on 3003): production model code
and the live save API; a real save, reload and restore; isolation hashes.

## Not done or not claimed

No physical headset session. No headset frame-time measurement. The desktop mouse
pointer's click on a rack button was not driven by a synthetic mouse event (headless
Godot cannot capture the mouse); the VR pointer + trigger path and the XR grip were.
The weather's seed (4321) cannot be set from a room record because the artifact has no
configuration method; it is left as shipped, as the brief allows.
