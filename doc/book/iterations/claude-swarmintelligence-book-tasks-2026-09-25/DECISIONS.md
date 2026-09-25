# swarmintelligence — the 24 Sept book tasks applied, 25 September 2026

Tasks `book_swarmintelligence.001`–`.017` (the 24 Sept tasks; .018–.027 were the Nature of Code series, closed earlier today; .003, .007, .014 were closed by another writer): thirteen applied and closed, one left open with a note. Walking the spine from its far end (forum 260925-tvljg).

| task | hall | what landed |
|---|---|---|
| .001 | Particle_Swarm | "four questions"; the labels now include Meritocratic; a RIDGE paragraph after the archive passage (score = distance from the diagonal, `-abs(x - z)·√½`, a band about half a metre wide); the closing line names RIDGE beside SPREAD. The task's "one a hand's width off it scores as badly as one at the corner" is not what the code does (the score is graded by distance), so the chapter says what it does: scored by how far off the line, never by where along it |
| .002 | Agent_Based_Modeling | **map edit**: `catalyst_foe` → `catalyst_foe:0:0#initial_state:curious`. The key is read by catalyst_foe.gd's apply_grid_config (:1929-1936); curious sets `_can_chase = false`, `_can_damage = false`, `contact_damage = 0` and orbits (hazard_creature_base.gd:544-550). The vent and prompter box stay. The chapter is unchanged: the hall's standing-and-watching protocol is no longer interrupted |
| .004 | PhysarumColony | Physarum polycephalum named in the mechanism paragraph; the caveat stands |
| .005 | FlowFields | the sentence no longer defers: the piece can be placed with its arrows hidden and one scene held (`scenario`, `field_display: hidden`), that placement is the test, this hall shows the arrows so the cause stays visible, and the version without them is one token away and not yet placed |
| .006 | Agent_Based_Modeling | the three MODE behaviours named in one sentence each |
| .008 | Particle_Swarm | after a switch, what carries over is the motion and a shared best just re-chosen; every particle's own memory is reset to where it stands (`_switch_landscape` → `_reset_memories`) |
| .009 | FlowFields | the zero-direction sentences (and the wander / Reynolds sentences that depend on them) moved from the wind paragraph to the end of the cost-map paragraph, and say where zero occurs: at the target, inside a wall, in a sealed region |
| .010 | FlowFields | one sentence before the handover: the ant sand and the ecosystem box belong to later rooms; neither has arrows |
| .011 | Particle_Swarm | the plate at the back served in one paragraph before the handover: press its button once for the field of spins (the default mode is stigmergy), NOISE as the temperature, the capstone's question a room early |
| .012 | PhysarumColony | the pickup from Boolean Works: one hollow cut for one body there; nothing cut here, five hundred agents rewriting the ground |
| .013 | Ant_Colony | the deferral cut; the foraging-simulation caveat moved above the two-directions paragraph so the chapter ends on "A route's visibility depends partly on its history of use." Physarum keeps the movable-anchor proposal for both colonies |
| .015 | Boids | option (a), the refusal kept: the two identity lines in `boid_manager.gd` (triggers, needs) now say the controller NodePaths are never set in the scene and no hand is found. Comments only; compile-checked. The chapter is unchanged |
| .017 | Boids | **map edit**: the `boid_flocking` cell at (2,2) emptied. It resolved to `boids_explained.tscn`, whose root is a CanvasLayer: a screen-space UI a headset cannot show and that covers the desktop view. The same panel stands in 3D as `boids_2d_in_3d` at (2,8) |

Left open:

- .016 (Boids): keep the open flock dealt through the walls as the honest encounter (the chapter is written to it) is my recommendation; the registry blurb line the task asks for is Palle's call, and a `#fit` box would mean rewriting the chapter's first paragraph.

Both map edits were committed as one-line changes against HEAD: the working copies of the two map files carry another writer's uncommitted hunks (the ABM map a whole-file reindent from 20 September, 565 lines; the Boids map one structure cell filled on 14 September), so the token change was applied to the working tree AND to HEAD's copy, and HEAD's copy with the change was staged as a blob (`git hash-object -w` + `git update-index --cacheinfo`). The foreign hunks stay in the tree, uncommitted, as found. Pathfinder run on both maps from the working tree after the edit (result in the run log).

Verification: every replacement matched exactly once; footnotes defined; fences balanced; endings preserved (ABM, Particle_Swarm and Swarm_Algorithms CRLF, the rest LF; no mixed files); both map files still parse as JSON, in the tree and in the staged copy; boid_manager.gd compiles.

Disclosure: chapters that carried uncommitted hunks from another writer and land here whole: SwarmIntelligence_Particle_Swarm_Optimization (10 lines). `before/` is the tree as found, so the diffs beside it are this pass alone.
