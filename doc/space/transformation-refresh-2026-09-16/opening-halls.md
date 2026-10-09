# Transformation opening halls — 2026-09-16

## Changes

- Trans_Pre: the first, still pickup uses `hold:collect`. The next three remain demonstrations. The four platform pickups remain collectible. The first cube can now be collected by walking into it, the established mechanic of this artifact; it has not become a hand-grabbable prop.
- Trans_Introduction: both scale and rotation crossings use `seat:deck` with an additional Y offset of zero. The old -0.5/-0.55 offsets moved them again after geometry-based seating.
- The opt-in rotation `bridge` profile is now 3.6 × 0.2 × 1.0 metres. The only map using this profile is Trans_Introduction. Wall profiles remain unchanged. Crosswise it leaves gaps along the route; after a quarter-turn its ends overlap the banks by 0.3 metres.
- Local book/tutorial text reflects collection, the actual two-metre transport journey, current VR carry helper, and the narrow rotating plank. The Intro tutorial's old fictional instant-teleport examples have been replaced with excerpts from the live implementations.

## Evidence

`commons/testing/probe_transformation_opening.gd` boots the actual `endless_museum.tscn` with an isolated control file and opens the requested map. It inspects the museum's embedded SimGrid, rather than reconstructing a proxy scene.

- Trans_Pre: 8/8 checks passed. An actual XRToolsPlayerBody on collision layer 20 walks into the first still pickup through physics. The Area collects it and the score increases by exactly one. No manual call to `collect()` or the overlap handler.
- Trans_Introduction: 15/15 checks passed. Ray-cast floor is Y=0; the scale cube at maximum and the rotating plank have mesh/collider tops at exactly Y=0. Crosswise and aligned spans are checked. Capsules under gravity cross both held openings and arrive on the far bank without falling.
- These are real physics checks with XR disabled, not a headset comfort test. The capsule crossing pauses the two artifacts at their walkable states; it does not establish that every visitor can cross within the authored four-second window.

Run separately:

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --xr-mode off --audio-driver Dummy --path . --script res://commons/testing/probe_transformation_opening.gd -- --map=Trans_Pre
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --xr-mode off --audio-driver Dummy --path . --script res://commons/testing/probe_transformation_opening.gd -- --map=Trans_Introduction
```

Before snapshots are in `before/Trans_Pre` and `before/Trans_Introduction`. Machine-readable evidence is in `Trans_Pre-checks.json` and `Trans_Introduction-checks.json` beside this report.
