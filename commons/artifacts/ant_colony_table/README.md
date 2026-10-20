# Ant Colony V2: a trail comparison

A live 1.8 m table for Flow Fields. Hosts the existing Ant Colony V2 scene through `ant_scale_atlas/v2_world.gd`. The original 100 ants, 50 m terrain, pheromone texture and physics callbacks run in a private World3D. Only their camera view is reduced to table size. Pause/play is at the front-right, 1.03 m above the floor; it retains state.

This is a comparison with the hand-written direction table: ants deposit trails; the flow agents read supplied vectors. It adds no new primary tutorial. The original ant scripts, shader and scenes are unchanged.

The explicit occupied-cell method describes physical furniture only. Including the remote simulation's 50 m bounds would incorrectly block the museum's route planner.

Placement: Flow Fields cell (9, 2), yaw 0, no additional plinth. Native scene, motion, pause/resume and standing-access checks: `tools/probes/flow_room_after.gd`. Report: `doc/book/iterations/2026-10-11-flow-room-to-move/index.html`. Headset and Quest performance remain untested.
