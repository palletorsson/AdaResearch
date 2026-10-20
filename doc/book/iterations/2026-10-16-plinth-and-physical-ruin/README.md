# Larger jars and a physical ruin

Requested 16 October: larger, nicer jars on a plinth; remove and drop a ruin stone so the others fall; investigate the strange column faces.

## Result

Four glass bodies now have radius 0.52 m and height 2.30 m, starting at y0.46 over a shared 5.8 m plinth. Their shoulders are rounded, with clear single outward-facing skins, ceramic-coloured lids, metal collars and larger round beads. Labels sit on the plinth. Source coordinates, seeds and 0.48-second step interval are unchanged; the earlier three-minute coordinates match exactly. The view scales the same paths. The bank moved from the current centre placement (8,2) to clear floor at (4,2); the map-derived museum row is synchronized. The hand-sized shakeable jar remains separate.

The fluted drum triangles were inward: native normal/radial dot −0.816. Reversed winding and flat flute/cap normals repair the mesh. The glass shell also passes winding/normal agreement checks.

The installed ruin scene now loads entropy_ruin_physics.gd. It reuses the architectural builder but creates 116 XRTools rigid bodies, including 32 fixed foundation stones and 84 loose stones. Convex drum hulls and box masonry use friction 0.72, zero bounce, gravity and contact. ONE STONE draws a support out over 0.9 s, then releases it; automatic selection waits 4.5 s between completed extractions. Pausing selection does not freeze bodies. VR and desktop pickup share ownership signals and block reset while held. Static reset avoids imparting kinematic teleport velocities. RESTORE repeats the start and selection seed, not a saved physical trajectory. No persistent save/replay is added.

The separate em_weathering_wall.gd still inherits the authored top-course model. Its legacy regression is retained under probe_entropy_weathering_base.gd. That wall does not silently acquire the new contact model.

## Evidence

33 apparatus checks, 28 installed-room checks, and 458 retained staged-model checks pass. In the isolated physical trial, the unselected next drum descends from about 1.38 m to 0.34 m after its support is removed. Installed ONE STONE/RESTORE, supplied XRTools hand, desktop carry, all four jar approaches, and native captures are checked. Map pathfinding passes with the existing end-teleport-height warning. The museum also logs its pre-existing blocked authored entry/fallback warning from the neighbouring point enclosure, present before this revision. The relocated jar approaches are clear. Headset comfort, device performance and human interpretation remain untested.

Run `python doc/book/iterations/2026-10-16-plinth-and-physical-ruin/run.py`, then `python tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag plinth-physical-ruin --probe doc/book/iterations/2026-10-16-plinth-and-physical-ruin/museum_probe.gd`, then publish.py. The standalone physical regression is commons/testing/probe_entropy_ruin.gd. Legacy model check: Godot --headless --script res://commons/testing/probe_entropy_weathering_base.gd -- --no-bridges.

Current final, tutorial, plan, registry and writing-wall notes follow these changes. The 48-value bench remains the first research pilot. No commit or push is part of this request.
