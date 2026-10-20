# Leave a direction

Optional hand interaction in `SwarmIntelligence_FlowFields`. This extends the existing `flow_museum` host, with its unchanged FlowFieldMain, FlowGrid and 200 FlowAgent bodies. The existing walk-in crowd remains in the east court. No canonical tutorial or reflective text changes.

Take the black PointBody at the front-right dock. Hold its action and move it 8–65 cm above the small surface. Movement writes normalized directions into the existing field. Cyan arrows retain the starting direction; gold arrows identify edited cells. Release action to stop writing. Drop returns the point after three seconds and keeps the field. Desktop uses the existing carry/drop and action controls.

Pause/play, reset directions and tour/draw buttons are to the left. Reset restores a constant rightward field without resetting or respawning bodies. Tour returns to the original six scenarios, ending in animated noise. Returning to Draw clears edits. The small surface and original 2.8 m table share one ViewportTexture and simulation. All its physics and visuals stay in the original private World3D.

Input uses the original 46 m camera extent over the 40 × 40 field. The unrepresented outer border is excluded. A 1.2 cm movement threshold defines direction; a stationary held point writes nothing. Samples at most every 50 ms paint an interpolated, radius-two-cell circular brush. Leaving the surface ends a segment, so re-entry cannot join an unseen gap. The original agent steering, speed, collisions and radial boundary response remain unchanged. Agents read this field without depositing or fading it. This is the distinction from the previous Physarum encounter.

Only the old table token changes to `flow_direction_table`, at the same cell with yaw zero and no plinth. Nearby automatic sculpture placement is excluded by a map rectangle. The existing ramp is retained; buttons and point have separate clear approaches. The older Change artifact `flow_field_painter` is a different artifact and must not be overwritten.

Production checks: `tools/probes/flow_painter_checks.gd`. Native museum checks: `python tools/run_encounter_probe.py SwarmIntelligence_FlowFields --sequence swarmintelligence --render --no-bridges --output-tag flow-direction-final --probe tools/probes/flow_painter_museum.gd`. Publish: `python tools/publish_flow_direction_table.py`.

The tests inject desktop pickup/action into the real point and verify the resulting field and motion. They do not establish physical headset comfort, Quest performance or whole-hall traversal. Older AntColonyV2 footprint and portal fallback warnings remain in the report.
