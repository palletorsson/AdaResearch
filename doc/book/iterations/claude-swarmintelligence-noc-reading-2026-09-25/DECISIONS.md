# swarmintelligence × Nature of Code ch. 5 — applied 25 September 2026

Reading: `doc/book/readings/NOC_swarmintelligence_2026-09-25.md`. Tasks `book_swarmintelligence.018`–`.027`, all applied here and closed. Palle: "commit and apply" (10:35).

One of the ten was a prediction and it was measured first. `probe_boids_tank_divergence.gd` (copied here with its report) builds the tank, switches its own frame loop off and drives `_update_boids(delta)` by hand three times from the same seeded scatter: twice with identical fixed steps of 1/60 s, once with steps jittered by up to a fifth, 1,200 steps each.

| | measured |
|---|---|
| same scatter at build | yes, to the byte |
| two runs with identical steps, after 20 s | identical to the byte (max 0.0000 m) |
| jittered steps against fixed, max separation | 2.4 mm after 1 step · 7 mm after 10 · 16 cm after 1 s · 1.12 m after 5 s · 1.17 m after 20 s, in a tank 0.9 m wide |

The first attempt at this probe (10:39) reported that even identical steps diverged. That was the probe's fault, not the tank's: two real frames ran before the frame loop was switched off, with different real deltas. The second attempt compared three empty arrays and called them equal, because the tank's build had not run yet and nothing checked. The third builds by hand, reads back that the flock moved, and is the one reported. Both mistakes are the memory's: a comparison needs a readback.

| task | hall | what landed |
|---|---|---|
| .018 | FlowFields | the steering formula named: push on the difference; what agent adds to particle |
| .019 | FlowFields | the wander at a zero cell is a new random direction every frame; Reynolds's keeps yesterday's heading |
| .020 | Boids | containment named at the five-metre margin; footnote `[^containment]` |
| .021 | Boids | take out the cooperation (a gas), then the competition (a clot) |
| .022 | Boids | the same scatter is not the same flock, with the measured five seconds; footnote `[^lorenz]` |
| .023 | Boids | the cost of seeing: a hundred boids, ten thousand measurements a tick; the tank's cells; footnote `[^cost]` |
| .024 | Agent_Based_Modeling_ABM | Braitenberg's vehicles at "an adequate model of a person"; footnote `[^braitenberg]` |
| .025 | Swarm_Intelligence_Algorithms | the five inherited numbers; predator and prey run one rule with the sign reversed |
| .026 | PhysarumColony | the two feedbacks named |
| .027 | FlowFields | path finding against field following |

Verification: every footnote reference has a definition; endings preserved; no code changed. Task .021's experiment (ALIGN and COH to nothing, then SEP to nothing) is written from the update rule (`flocking_controls.gd:438-497`) and not measured on the panel; the desktop lane check remains for whoever walks it.

Disclosure: ABM, Particle_Swarm_Optimization and Swarm_Intelligence_Algorithms carried uncommitted hunks from another writer (Codex, idle since this morning; forum 260925-0vmbf); the ABM and Swarm_Intelligence_Algorithms files land here whole. FlowFields, Boids and PhysarumColony were clean.
