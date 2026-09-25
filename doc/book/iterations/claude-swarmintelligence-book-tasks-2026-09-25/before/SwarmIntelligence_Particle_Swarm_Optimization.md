# Better according to which score?

When a swarm improves, who decided what better means?

<!-- @fitness_landscape_politics -->

Watch the population under CONVERGE, then choose SPREAD. The button changes the score while the particles keep their positions and motion. Keep INERTIA steady and watch the turn. For a comparison from the same beginning, use RESET after selecting each objective: it restores the same scatter and velocities. Next try NOVELTY. Before reading these as success and failure, describe what each setting seems to reward.

CONVERGE rewards movement towards the centre. SPREAD rewards distance from it; two particles can score equally well while crowding the same edge. NOVELTY rewards distance from positions retained in an archive. These are three different questions put to the same moving bodies. The labels Corporate, Ecological and Artistic are invitations to argue about those questions, not properties proved by the equations.

Keep your attention on one region when you exchange CONVERGE for SPREAD. The region has not moved, but its value under the new objective has changed. Describe the difference as a change of reward before describing any particle as more capable. This also helps with a slow response: the visible position belongs to the current moment, while continuing velocity and remembered positions can still influence where the next update carries the particle.

Each particle remembers a position that scored well for it. The swarm also retains a shared best position. A velocity update combines continuing motion with pulls towards those personal and shared memories, using varying random contributions. INERTIA changes how strongly the existing movement carries into the next update.

“Best” is a relation between a position and an objective. It is not a property the particle discovers independently of the scoring rule. A position can be excellent under one button and poor under another. The ant colony’s traces remembered visits; these particles explicitly remember evaluations.

Spend longer with NOVELTY. At its beginning the archive remembers the current positions. Its count grows as more visits are kept, and the bright regions on the plate change with that record. Follow a place that was bright. Does it remain promising once the swarm has been there?

A remembered position must be scored again when the archive changes. Yesterday's high score cannot simply win against today's distances: the question has changed under it. The particle retains a place, but its claim to be best has to be renewed. Here forgetting and revaluation are part of the mechanism that lets movement continue.

The archive holds at most two hundred positions, sampled one at a time rather than recording every visit. When it fills, new entries replace the oldest. An apparently unexplored place can be unfamiliar to this record without being unfamiliar to the world. New relative to whom, and to how much of their past?

Now change INERTIA within one objective. Ask whether overshooting is always wasteful. Motion that delays settling can also carry a particle beyond a region it would otherwise keep revisiting. The consequences depend on the landscape and on what the score values.

An optimiser cannot settle a disagreement about what should be optimised. Rewarding dispersion here may be a productive alternative to rewarding concentration; it does not automatically make dispersion good in every social setting. A future comparison could display two conflicting scores together, keeping the compromise visible instead of hiding it inside one number.

<!-- @ -->

The capstone turns from declared objectives to quieter rules that keep an apparently self-organising system alive.
