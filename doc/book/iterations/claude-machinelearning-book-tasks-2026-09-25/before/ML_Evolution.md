# Survival without a finish line

If no judge ranks these bodies, does that mean nothing selects between them?

<!-- @non_teleological_evolution -->

Choose a moving body and watch where it travels. Compare a body covering fresh territory with one remaining near places already visited. Stay long enough to notice a new body appear or an existing one disappear, then compare that event with the population’s continuing motion.

The simulation lets bodies gain energy by visiting new cells. Energy also drains with time. A body with enough energy can reproduce, dividing its available energy and giving its offspring slightly altered traits such as size, speed and colour. There is no final shape on a pedestal that every descendant is trying to become.

Beside these bodies stands a population that does have a judge. Every thirty seconds a score is taken, the higher scorers are picked in small tournaments, and their numbers are crossed to make children, seven times in ten, or copied with a small change the rest of the time. In the time you stand here about ten generations pass. Watch what each population loses: one its unlucky, the other its unscored.[^holland]

Look for continuity as well as difference around a reproduction event. A new body can resemble its parent while beginning a different route, and a visible difference need not immediately alter survival. What matters is how a trait enters the subsequent encounters with the grid and its energy rewards. Keep the description in that order: inherited variation, changed behaviour if you can observe it, then a consequence for continued movement or reproduction.

The changes nevertheless have consequences. A trait that alters movement can alter access to the rewarded cells, and that can affect the opportunity to reproduce. The environment supplies a preference even without a separate leaderboard. Removing an explicit fitness ranking has not removed the conditions under which some lineages continue and others stop.

Follow the child as a new trajectory rather than as an improved copy. Mutation introduces variation; it does not know which variation will help. Nor does a crowded population establish that each surviving body is closer to a universal ideal. It tells you that these bodies have continued under this particular energy economy.

The ecosystem in the previous room combined local behaviour with balancing interventions. Here the lesson is to look carefully at the apparently ordinary rule that pays for survival. Rewarding visits to new cells makes movement into unfamiliar territory consequential before anyone announces an objective called exploration.

The fresh ground is finite. Four hundred cells, and the ground forgets only one of them every two seconds. Watched at the shipped start, the population fills its ceiling of a hundred and twenty within three seconds, the last fresh cell is crossed by ten, and from then on every lineage drains at the same rate: the hall is empty at thirty-six.[^novelty] There is a finish line after all. Nobody announced it, and no body can see it coming.

Imagine changing that rule so that revisiting a dependable place also provides energy. Which traits might become useful? That is a proposed comparison, not a control offered by the present encounter. It would test how much of the population’s story belongs to its environment.

The flowers in this hall have a judge too, and the judge is a sentence: symmetry, long petals, a hue near purple, an angle near thirty degrees, each worth so many points. They evolve toward a taste someone wrote down. In 1997 Karl Sims let a museum's visitors be the judge, the fitness of an image being how long people stood in front of it. Ask which of the two this hall should run, and what each would breed out.[^sims]

<!-- @ -->

The gradient landscape next puts an objective in full view. Instead of inheriting a reward through survival, a moving point will be told exactly how its position is scored.

[^novelty]: Measured with `commons/testing/probe_novelty_finite.gd`, the artifact's own frame loop at a fixed sixty frames a second: thirty bodies at the start, a hundred and twenty at 2.4 seconds, the visited fraction at one by ten seconds, seventy-six bodies at twenty, eight at thirty, none at 35.8. The rule that forgets clears one random cell every 120 drawn frames (`non_teleological_evolution.gd`), too slowly for anyone to live on. A visitor who arrives a minute after the hall was built meets the plane and no bodies.

[^holland]: John Holland, *Adaptation in Natural and Artificial Systems* (1975), the genetic algorithm as a procedure: a fitness function, a mating pool, crossover, mutation. The judged population here is evolved_creatures; its steps are those, at thirty-second generations.

[^sims]: Karl Sims, *Galapagos* (NTT InterCommunication Center, Tokyo, 1997): twelve screens of evolving images, and a floor sensor before each that made looking the fitness function. The flowers here are evolvingflowers; their taste is the artifact's calculate_fitness, a generation every eight seconds.
