# Line and trace: a monitor prototype

The user authorised trying the proposed camera-to-monitor illustration. The earlier summaries-only restriction still applies to the tutorial project. This prototype adds a separate artifact; it does not revise the storyboards, tutorials, manuscript, existing line/trace code, or authored map placements.

## Encounter

Two endpoints remain 4 metres apart. A point travels between them along one of three authored routes. Thirty-three ordered positions are retained; adjacent samples are joined. Pause, replay, step one sample or change route. The straight segment describes the relation between endpoints. The trace preserves an ordered, sampled journey. Its displayed length is the sum of sampled segment lengths, not an exact continuous arc length.

## Mechanism

The existing `commons/monitor/cctv.tscn` establishes the private-viewport pattern. The new monitor uses a separate `World3D`, a camera, physical 3D spheres and rods, a backdrop, and screen annotations. Its texture is displayed on a 2.56 by 1.44 metre screen. The stand and case have colliders. Four buttons reuse the existing XR Tools touch and ray-pointer component.

The `concept_scene` PackedScene supplies the illustration. The current stage protocol is `advance(delta)`, `toggle_pause()`, `replay()`, `step_sample()` and `next_route()`, with a `running` property. This is one tested example of the pattern, not a general authoring framework for arbitrary lessons.

Animation updates are limited to 30 calls per second. Rendering uses a 1024×576 viewport and is suspended when the screen is not visible or the active camera is more than 14 metres away. Rendering can still occur at the main frame rate while visible; this is not a measured Quest performance budget.

## Placement and review

The screenshot is from a temporary placement in a private test instance of the real Point_Trace hall. No production map placement was changed. The artifact is registered as `line_trace_monitor` for later placement. The independent F6 scene is `commons/artifacts/concept_monitor/preview.tscn`.

The HTML player shows frames captured from Godot, not a JavaScript reimplementation of the geometric operation. `illustration.png` is the same feed saved as a book image. The monitor has no link to `TraceData`; linking a visitor's drawing requires a separately considered handoff.

## Verification

`report.json` records runtime checks: separate rendering/physics worlds, fixed endpoints on all routes, trace lengths, elapsed-time sampling, reachable control rays, synthetic pointer events, pause/replay/step/route, bounded geometry over repeated journeys, museum rendering and distance suspension. `protected-sources.json` hashes existing map and artifact files before and after the test.

No tracked-headset or Quest performance acceptance was performed. The museum launch reports pre-existing project warnings (including an audio bus UID and an entrance fallback); this prototype does not repair those systems.

Reproduce the museum capture with `python tools/run_line_trace_monitor.py`. It writes into its own `ada_run/line_trace_monitor` folder and this review directory.
