# A mark left behind

An optional encounter in `SwarmIntelligence_PhysarumColony`. One original `physarum_museum` scene feeds its 2.8 m table, a 6 m wall and a 1.2 m drawing surface. Its 300 agents still run in the existing private 50 m physics world. The scene's agent, grid, shader and anchor-carousel sources are unchanged.

Take the same PointBody used elsewhere in Swarm. Hold its action while its centre is 8–70 cm above the drawing surface. The cyan cursor shows the mapped position. Release action to stop depositing; drop the point and it returns after three seconds. Desktop uses the existing right-click pickup/drop and left-click action. Pause/play and restart are beside the surface. Pausing stops the colony, but the hand can still write.

The hand is an explicit additional writer to the original 256-square field. A radius-three-cell circular brush adds 2 per cell, capped at the original maximum 10. Samples are taken at most once per 50 ms; interpolation fills gaps between samples. Leaving the surface ends a stroke. The original camera spans 54 m, so the outer display margin is excluded from drawing. Projection is tested in all quadrants under a translated and rotated host.

The original 20-simulation-second anchor carousel continues. There is no hidden warmup or automatic reset. Resume allows the original sensors, agents, diffusion and decay to work on the modified field. Three views share one ViewportTexture and material; they are not independent simulations. This is a Physarum-inspired simulation, not an ant or biological validation.

The east court extends the hall from 13 × 11 to 28 × 11 cells. A three-cell opening connects it to the original room. The old table token moves into this host rather than leaving a duplicate running. Other saved artifacts and utilities remain. Only this hall's museum-plan row changes. Canonical tutorial and reflective texts remain unchanged; this encounter does not replace the primary lesson.

Validation: `tools/probes/physarum_trace_checks.gd` exercises the production scene; `tools/probes/physarum_trace_museum.gd` loads the actual museum and checks floor support, standing access, drawing and release. Run the latter through `tools/run_encounter_probe.py SwarmIntelligence_PhysarumColony --sequence swarmintelligence --render --no-bridges --output-tag physarum-trace-final --probe tools/probes/physarum_trace_museum.gd`. Publish with `tools/publish_physarum_trace_gallery.py`.

Author-operated desktop checks and native captures do not establish physical headset comfort or Quest performance. The existing south-exit fallback warning is recorded in the report; portal traversal is outside this encounter test.
