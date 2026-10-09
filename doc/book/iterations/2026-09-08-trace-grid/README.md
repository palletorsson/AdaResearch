# Trace and Grid: choosing what counts

The existing primary encounters remain: Trace's four configurations of `draw_dot`, and Grid's `grab_sphere_point_snap` followed by `player_trace`. Supporting artifacts and placements are retained.

Trace's table previously printed centimetres despite accepting movement at 5 mm. It now reports world metres with at least three decimal places, adapting for finer settings. The table remains visible after release and clears with the record. The old length field was removed: its accumulator counts displacements on admitted samples, which is not the length of the retained polyline after rounding and eviction. Unlock accounting is unchanged.

Grid previously sampled the XR rig origin. A physical step inside the play area can move the headset while that origin stays still. The recorder now uses headset world X/Z at rig-origin world Y in VR, and the active-camera museum walker on desktop. Switching sources clears previous paths and statistics. This is a shared component correction, including other maps using `player_trace`; it does not establish their spatial usability. Explicit plain-node tracking targets retain their position contract.

The book lets observations precede explanations: a pause without a new sample; two retained positions formerly hidden by decimal rounding; movement within a coarse address; a lean that becomes travel. Each chapter also asks for a deliberate use of the approximation. Selected claims in the technical and critical sources were reconciled: the pen does not retain every frame, guarantee 90 Hz or encode a pause's duration with the current scene settings.

## Evidence

- `discovery.json`: 28 actual-scene checks with supplied hand, camera and body transforms. Includes dot/stick precision and release, coarse duplicates, clear behavior, desktop/staging selection, physical movement within a fixed XR origin, height projection, metre boundary crossing and camera switching.
- `snap-and-pen.json`: all 76 existing regression checks pass, including the timer-driven pen's different recording contract.
- `trace-speed.json`: elapsed-speed regression passes for supplied 1 m/s movements across time and distance gates, pause, clear and bounded retention.

The verified logs have no GDScript errors. Startup still reports an unresolved UID, certificate-store access and DebugLogger output access errors outside these checks. These tests do not establish headset input, reading distance, whole-room access or learner understanding. No learner baseline is marked accepted.

## Next encounter

In Trace, release a pen and read the last two rows; compare a small loop with holding one coarse address steady. In Grid, compare a planted-foot lean with a step, then a larger crossing of the one-metre boundary. Verify both paths are visible from the place of action. Test the desktop walk separately.

Follow the pilots at `/museum-progress?sequence=primitives&room=Point_Trace&action=trace-recording-contract` and `/museum-progress?sequence=primitives&room=Point_Line_Grid&action=grid-whose-position`.
