# One pattern, three sizes

Optional east court in **Swarm Intelligence → Ant Colony Optimization**. It uses
the original StigmergyGrid and LangtonSwarm state and step methods unchanged.
The original Ant Colony V2 scene runs in a private physics world at its original
50 m size. The existing `ant_colony_walk` remains the primary lesson in the room.

- 45 cm carry tile, 1.8 m table, 8 m walk-in field.
- One selected model supplies all three displays; scale does not resimulate it.
- Trails: 15 agents; original 64×64 grid, fixed 30 updates/s.
- Turmites: 12 agents; original 40×40 grid, five steps per 0.10 s.
  Original 900-step warm start is shown in the room. Seed 7411 makes reset repeatable.
- Ant Colony V2: original 100 ants, 256×256 two-channel grid, food/home Area3D
  detectors and per-physics-tick rules. No warm start or speed multiplier.
- Select any model; the others retain their state while inactive. No automatic reset.
- Take the black PointBody to carry the tile. Trigger pauses/resumes all views.
  After five seconds released, it returns to its dock.
- Five nearby buttons: Trails, Turmites, Ant Colony V2, Pause/Play, Restart
  (selected model only).
  Standard pointer/near-touch controls; desktop right-click carries, left-click acts.

`model.gd` owns two off-tree original engine Nodes; they never run their visual
`_ready()` methods and are freed with the adapter. Fixed-step scheduling retains
elapsed remainder; original per-tick rules and default parameters are retained.
Gold/cyan pheromone mapping and combined ant silhouettes are presentation only.
Each model has a shared field texture; three MultiMeshes render at most 300
visual bodies total. `v2_world.gd` hosts the unchanged V2 scene in a SubViewport
with its own World3D and rendering disabled. It advances only when selected and
playing. The V2 source material is duplicated before entering the tree to avoid
sharing its texture binding with other colonies. The original p_texture feeds
`v2_field.gdshader`: cyan home trail, rose food trail on dark ground. Food/home
markers and pink returning ants make the task visible without terrain glare.
Ant legs are static silhouettes, not a gait or
collision model. The visitor does not affect agent motion by walking on the floor.

Checks: `tools/probes/ant_scale_checks.gd` (rendered backend needed for MultiMesh
readback), `tools/probes/ant_scale_museum.gd`, and the 90-second V2 run in
`tools/probes/ant_v2_museum.gd` in the actual hall. Selection evidence
and native images: `doc/book/iterations/2026-10-11-ants-time-and-scale/`.
No physical headset or Quest performance claim.
