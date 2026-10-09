# Body and Moving Boundary alignment — 2026-09-17

The two halls now describe the encounters their current embedded museum instances make. The source structure arrays are byte-for-value unchanged from the snapshots in `before/`: no pits restored, no bypass blocked, no new hazard consequence introduced.

## Body

The primary order remains `approach_wall → carve_grid → approach_scale`. Captions now request stepping clear before expecting closure. The prose distinguishes crossing a plane from leaving a sensor's reach, and describes the low lattice as an open-topped cut. Its record contains the recognised collision body, bite tolerance and grid resolution; it does not record a whole person. The conclusion asks which body the system can recognise and accommodate.

The live museum test passed **7/7 checks**. The lattice top is 1.335 m above its base. Natural contact from a 0.52 m-wide, 1.7 m-tall capsule removed 12 cells; those cells remained absent after moving away. At the caption beyond the final scale row, the smallest factor was 0.842. Moving to the exit area and waiting returned all factors to 1.0. This verifies the reason for the revised caption rather than presuming closure from having crossed.

## The Moving Boundary (`Trans_Pit`)

The local display title is now **The Moving Boundary**; canonical map ID remains `Trans_Pit`. Final, tutorial, summary, intent and critical text describe optional timed encounters on level ground. The common grower period is a visible repetition study; it is not three independent clocks. The closing question is which body can use a particular clearance, with the available detour treated as a legitimate route.

Three pusher lanes now use:

| Source cell (x,z) | Axis | Travel | Speed | Pause |
|---|---|---|---|---|
| 3,3 | +Z | 2 m | 1.5 m/s | 1.5 s |
| 7,3 | +Z | 2 m | 2 m/s | 1 s |
| 5,5 | −Z | 2 m | 1.8 m/s | 1.2 s |

This keeps endpoints out of transverse walls and separates the former overlapping lanes. Full-volume checks also exposed a second issue: automatic grounding changed the root after the pusher had cached its world-space path, so physics put the moving box halfway into the floor. Explicit local `pusher_block:0:0.49` seats now put its centre half its 0.98 m side above the floor before caching. No shared production script changed.

The live path probe passed **14/14 checks**. It sampled 81 poses along each path with the full 0.98 m box inset by 1 mm per face to avoid counting intentional support contact. No wall or floor collision was returned. An additional 78 poses for a 0.52 m-wide, 1.7 m-tall capsule confirmed the eastern pusher bypass is clear. These are collision-volume probes, not a claim that every player rig or locomotion style has been walked through the hall.

The existing cycle regression was updated for these authored 2 m paths and passed **28/28 checks**. Across 405 physics samples, pushers reached and paused at their endpoints with bottom-height error below 0.00000001 m. Grower floor error and mesh/collision disagreement were both zero; sizes reached 0.30000001 m and 3.5 m. Legacy centre-anchored growers, default 3 m X pushers, and speed-only pusher configuration still passed.

## Spawn and scope

Both source maps use bare `s` with `utility_definitions.s.properties.player_rotation = 180`. The token suffix form is not parsed by the source spawn utility. The parent task verifies the embedded museum's separate arrival handling.

Changed local documents: `map_data.json`, `final.md`, `tutorial.md`, `summary.md`, `intent.md`, `critical.md` for the two maps. Tests: `commons/testing/probe_transformation_alignment_body_pit.gd` and `commons/testing/probe_transformation_pit.gd`. The Body critical text is new. Snapshots preserve the prior files. No global roles, book assembly, museum runtime, registry or sequence JSON edited by this subtask.

## Evidence limits

All three final runs instantiated `endless_museum.tscn` and tested its full-scale embedded GridSystem. No headset was used, and no new screenshot is claimed. The Body test uses actual proximity detection but places the capsule at selected locations; it does not perform a complete human traversal. Logs include pre-existing UID, audio-resource and certificate warnings; the final runs contain no script error. Earlier diagnostic runs found the test-array API error and the half-sunk pusher; only the corrected final logs are copied here.

JSON evidence: `Trans_Body-checks.json`, `Trans_Pit-path-checks.json`, `Trans_Pit-cycle-checks.json`. Runtime logs are adjacent. Commands use Godot 4.6 with `--headless --xr-mode off --audio-driver Dummy`, `--script res://commons/testing/probe_transformation_alignment_body_pit.gd`, and `-- --map=Trans_Body` or `Trans_Pit`; the cycle run uses `probe_transformation_pit.gd`.
