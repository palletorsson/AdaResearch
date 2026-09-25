# What the machine-learning chapters can learn from *Nature of Code* ch. 9–11

Read 25 September 2026 against the eight `final.md` of the `machinelearning` sequence (3,608 words: Evolution 421 · Gradient_Landscape 454 · Classification 504 · Neural_Networks 411 · Perception 401 · Sequence_Memory 591 · Generative 413 · Synthesis 413). Sources: https://natureofcode.com/genetic-algorithms/ (ch. 9 "Evolutionary Computing", 17,400 words: the textbook GA, fitness functions and their shape, smart rockets, interactive selection and Karl Sims, the bloops ecosystem), https://natureofcode.com/neural-networks/ (ch. 10, 13,600 words: the perceptron and its learning rule, linear separability and XOR, the seven-step life cycle, classification versus regression, ml5.js) and https://natureofcode.com/neuroevolution/ (ch. 11, 11,100 words: reinforcement learning, NEAT, Flappy Bird, neuroevolutionary steering, sensors, the neuroevolutionary ecosystem). Code read: `non_teleological_evolution.gd`, `evolved_creatures.gd` (+ `creature.gd`), `evolvingflowers.gd`, `neural_network_visualization.gd`, `svm_visualization.gd`, `random_forest_visualization.gd`, `joint_learn_walk.gd`, `pca_visualization.gd`. No agents.

## Where Ada is ahead

NOC's three chapters end in a library call: `ml5.neuralNetwork(options)` builds the network, `train()` trains it, `crossover()` and `mutate()` breed it. Ada's halls keep the operation in the room and separate it from the interpretation, which is the sequence's stated truth ("A change in appearance is not yet evidence of learning"):

- **The bloops are a hall, and a better one.** NOC's ecosystem (health draining, food restoring, clone at a small chance per frame, "survival of the reproducers") is ML_Evolution's non-teleological population, and the chapter says what NOC only gestures at: "Removing an explicit fitness ranking has not removed the conditions under which some lineages continue and others stop."
- **Three meanings of error.** Gradient_Landscape scores one fit under three losses and says an outlier "cannot be answered by the loss function." NOC has one fitness function at a time and a paragraph on its shape.
- **The backward pass, visible.** Neural_Networks: "It does not send a little correct answer backwards through every wire." NOC declines backpropagation ("beyond the scope of this book") and phones ml5.
- **A hand-set memory.** Sequence_Memory's LSTM cell with three spheres you place, and a slab that lands in two places from the same last token. NOC has no recurrence at all.
- **Perception's honesty.** "Those names and percentages are supplied in advance… the link between the two remains to be built." NOC uses pretrained models as given.
- **The caretaker and the objective.** Swarm's POPULATION SUPPORT and PSO's three buttons, carried into this sequence's opening question: who decided what better means.

## What to learn (seven items)

1. **The population with a judge, standing beside the one without.** `evolved_creatures` is placed in ML_Evolution and never mentioned: fitness, tournament selection, crossover seven times in ten, otherwise a clone with mutation, a generation every thirty seconds. That is NOC's textbook GA (Holland 1975; fitness, mating pool, crossover, mutation), the very thing the chapter's non-teleological bodies are the argument against. Two populations, one hall, one named.
2. **Novelty is finite.** `non_teleological_evolution.gd` keeps a 20 × 20 boolean grid over a two-metre world and never clears it; a cell visited once stays visited. The whole world holds 400 cells × 0.8 energy of fresh ground, ever, against a drain of 0.15 a second per body and a reproduction threshold of 3. NOC's bloop world persists because food respawns and the dead become food; this one's economy is a fuse. "Survival without a finish line" has a finish line nobody announced. PREDICTED, to be measured before it is written.
3. **The flowers evolve toward a written taste.** `evolvingflowers`, placed and unmentioned, scores symmetry at 15, a hue near purple-pink at 20, petal length at 10, an angle near thirty degrees at 10; elites survive; a generation every eight seconds. NOC's interactive selection is the museum alternative: Karl Sims's Galapagos (1997) assigned fitness by how long visitors stood in front of a screen. In a museum hall, which judge should this be?
4. **The learning rate is the network's max force.** NOC ties the perceptron's rule (error = desired − guess; Δw = error × input × learning constant) to Reynolds's steering formula and the learning constant to the maximum force: "a high learning constant… risk of overshooting." `neural_network_visualization.gd` names `learning_rate` its critical parameter ("the difference between convergence and oscillation") and the chapter never mentions the step. Third meeting with "push on the difference" (forces, steering, now learning).
5. **The two silent classifiers.** `svm_visualization` (max margin, support vectors, kernels) and `random_forest_visualization` (bootstrap trees voting) stand in ML_Classification unmentioned, and both learn named classes from labelled examples, the very contrast the chapter draws against k-means. NOC's perceptron is the simplest of them: a line learned from labelled points, which cannot separate XOR, which is why kernels and hidden layers exist.
6. **The walker that learns from a reward.** `joint_learn_walk` (tabular Q-learning, reward = distance every tenth of a second, ε decaying from 0.3) stands in ML_Synthesis unmentioned. NOC ch. 11 opens on reinforcement learning, feedback per decision, and chooses neuroevolution, fitness applied once at selection. The sequence has performed four measures of change and can name them: a teacher's answers, geometry alone, a reward per decision, survival.
7. **A loss surface is a fitness landscape upside down.** NOC's paragraph on fitness shape (linear, squared, exponential: the 801st correct character must be worth more than the 800th) is Gradient_Landscape's argument from the other side, and the hall's word is on the door of two other halls: the particle swarm's `fitness_landscape_politics` and Form Finding's decoy basin.

## Not to learn

- ml5.js syntax, the seven-step life cycle, GPU versus CPU, Flappy Bird.
- The mating pool as an array of a hundred copies; the relay race; accept-reject. Randomness has these as instruments already.
- NEAT, sensors as whiskers, the neuroevolutionary ecosystem: the biome's programme, not this book's.

## Hygiene, found on the way

Three ML halls carry uncommitted edits in the working tree (Classification, Gradient_Landscape, Sequence_Memory `final.md`) and an untracked `landscape_research.md` stands in ML_Gradient_Landscape; the fourteen tasks of the 24 Sept reading are still open. Another writer is on these halls. This reading touches only the task file.

## Tasks

Seven tasks appended to `doc/tasks/book_machinelearning.json` (`.015`–`.021`), source "Nature of Code ch. 9–11 reading, 25 Sept", shown on `/book-tasks` under machinelearning. Not applied.
