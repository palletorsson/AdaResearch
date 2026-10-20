# Particle Swarm — a memory in hand

Permanent full-size lesson in `SwarmIntelligence_Particle_Swarm_Optimization`.
`study.gd`, `swarm.gd` and `point_body.gd` remain byte-identical to the printed
student files under `doc/book/studies/swarm-through-the-hands/`.
Runtime dependencies stay under `commons`; the export excludes `doc`.

The museum wrapper adds `pso_hand_control.gd`: the familiar small PointBody
grip carries a score panel beside the entrance bank. Take it into the field.
The grip is not a twenty-fifth candidate and does not pause the search by
being held. Its trigger toggles the existing Run/Pause command. Six buttons
call the original Run, Step, Restart, Center, Edge and Ridge methods.

Hold a large sphere and press its trigger to select it. The panel displays
that candidate's current coordinate/score, remembered best coordinate/score
in blue, and the shared best in gold. Coordinates are the model's 2D search
coordinates, not the panel's location or world height. Values round to two
decimals. Rings and connecting cylinders remain the existing display of
recorded positions; they are not previews of the random next displacement.

Holding a candidate pauses the model and blocks Step, Restart and objective
changes. Release it before stepping. Changing the score keeps positions and
velocities but resets memories under the new criterion. Restart keeps the
selected criterion and replays the seeded scatter. The pad reads records
without drawing random numbers or writing memory. Dropped controls dock
after five seconds; regrabbing cancels the timer. Both original banks remain.

Validate with `tools/test_swarm_pso.py` (exact printed code),
`tools/probes/pso_hand_museum.gd` (installed controls, layout and photographs)
and `tools/probes/pso_hand_portals.gd` (forward/back portal coordinator).
Use `tools/run_encounter_probe.py` to isolate museum evidence.
Report builder: `tools/publish_pso_hand.py`.

Old `write_swarm_pso.py` / `place_swarm_pso.py` predate this wrapper.
Do not rerun them without reviewing their overwrites.
