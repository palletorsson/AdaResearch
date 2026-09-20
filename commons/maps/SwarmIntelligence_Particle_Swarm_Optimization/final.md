# Better according to which score?

When a swarm improves, who decided what better means?

<!-- @fitness_landscape_politics -->

Watch the population under CONVERGE, then choose SPREAD. Keep INERTIA unchanged while you compare the movement. Next try NOVELTY. Before reading these as success and failure, describe what each setting seems to reward.

CONVERGE rewards movement towards the centre. SPREAD rewards distance from it. NOVELTY rewards distance from positions retained in an archive. The same family of moving particles can therefore gather, disperse or seek unfamiliar territory because the scoring rule has changed.

Keep your attention on one region when you exchange CONVERGE for SPREAD. The region has not moved, but its value under the new objective has changed. Describe the difference as a change of reward before describing any particle as more capable. This also helps with a slow response: the visible position belongs to the current moment, while continuing velocity and remembered positions can still influence where the next update carries the particle.

Each particle remembers a position that scored well for it. The swarm also retains a shared best position. A velocity update combines continuing motion with pulls towards those personal and shared memories, using varying random contributions. INERTIA changes how strongly the existing movement carries into the next update.

“Best” is a relation between a position and an objective. It is not a property the particle discovers independently of the scoring rule. A position can be excellent under one button and poor under another. The ant colony’s traces remembered visits; these particles explicitly remember evaluations.

Spend longer with NOVELTY. Newness depends on what has been remembered, and this archive has a finite capacity. An apparently unexplored place can be unfamiliar to the stored record without being unfamiliar to the world. Every novelty measure needs an answer to the question “new relative to what?”

Now change INERTIA within one objective. Ask whether overshooting is always wasteful. Motion that delays settling can also carry a particle beyond a region it would otherwise keep revisiting. The consequences depend on the landscape and on what the score values.

An optimiser cannot settle a disagreement about what should be optimised. Rewarding dispersion here may be a productive alternative to rewarding concentration; it does not automatically make dispersion good in every social setting. A future comparison could display two conflicting scores together, keeping the compromise visible instead of hiding it inside one number.

<!-- @ -->

The capstone turns from declared objectives to quieter rules that keep an apparently self-organising system alive.
