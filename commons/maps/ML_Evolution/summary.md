# ML Evolution — Summary

ML_Evolution opens the Machine Learning sequence. It introduces optimisation the way biology discovered it — before calculus, without gradients, by variation and selection. The space is staged as a small arena where a population of candidate agents attempts a simple task, and the better ones reproduce.

A row of agents faces a short obstacle course. Each agent is a small body with a handful of weighted behaviours; the weights are its genome. The agents run the course in parallel; those that travel furthest are selected to produce offspring with small mutations. A generation counter at the wall ticks up, and the population improves without any single agent knowing what the landscape looks like.

Several controls expose the mechanics. A mutation-rate slider raises or lowers the variability of new offspring. A selection-pressure slider decides how harshly the weakest agents are culled. A reset button scrambles the population back to random weights, so the learner can run the experiment multiple times and watch the evolutionary trajectory vary.

Within the sequence, Evolution is the first answer to the question the rest of the sequence refines. It claims that optimisation can happen without a calculable gradient. ML_Gradient_Landscape will next replace random search with a directed step and ask what is gained by doing so.
