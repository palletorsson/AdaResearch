<<<ADA_BUNDLE>>>
sequence: randomness
file: tutorial.md
maps: 14
skipped_passing: 0
created: 2026-04-24T09:49:33
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Random_Definition>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Defines randomness as the absence of pattern — not chaos, but the irreducibility of a sequence to a shorter description. Distinguishes pseudo-random number generation (algorithmic, deterministic, reproducible) from true randomness (physical, entropic, irreproducible). | Sequence role: Opens the Randomness sequence (E_entropy phase, 7th spine sequence). No predecessor within the sequence. Establishes the conceptual vocabulary — PRNG vs TRNG, seed, entropy source, uniform distribution — that every subsequent map assumes. The 12x12 grid format grounds randomness in the same spatial infrast | [... truncated ...]
# BLURB: Order flickers, entropy whispers. This is where the algorithm cannot predict, cannot index, cannot control — the computational equivalent of wilderness, where randomness resists the cadastral grid.  The `prng_crank_machi…
[empty — to generate]

<<<MAP: Random_Remove>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Randomness as subtraction — removing elements from a grid by stochastic selection (range, column, row, or all-at-once) reveals that randomness is not only generative but destructive, and that deletion patterns expose the distribution that produced them. | Sequence role: Second map in Randomness sequence. Follows Random_Definition, which established what randomness is; this map shows what randomness does to existing structure. Precedes Randomness_10_PRINT_Algorithm, where randomness becomes generative. The remove_random artifact reappears in map 3, linking destruction here to constructio | [... truncated ...]
# BLURB: A 12×12 grid. An 8×8 region inside it. Cubes appear, stack, walk, vanish. The arena runs randomness as demolition — `RemoveRandom` picks cubes by range, column, row, or all-at-once and deletes them. Gaussian distribution…
[empty — to generate]

<<<MAP: Randomness_10_PRINT_Algorithm>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The 10 PRINT algorithm — a single line of code that randomly selects between two characters (/ and \) to generate an infinite maze — demonstrates that minimal randomness plus minimal rules produce emergent complexity. One coin flip per cell, infinite visual structure. | Sequence role: Third map in Randomness sequence. Follows Random_Remove (randomness as destruction) and pivots to randomness as construction. The remove_random artifact carries forward from map 2, bridging subtraction and generation. Precedes Random_Cubes, where randomness shapes individual objects rather than grid patter | [... truncated ...]
# BLURB: One line of code. Two characters. Infinite complexity. The 10 PRINT maze emerges from the simplest possible random choice — flip a coin, draw a slash — and fills the world with labyrinthine possibility.  The `ten_print_m…
[empty — to generate]

<<<MAP: Random_Cubes>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Randomness applied to individual object geometry — each cube's edge profile is determined by coin flips, making every instance unique. The cube becomes a frozen record of its random generation history, where form encodes chance. | Sequence role: Fourth map in Randomness sequence. Follows Randomness_10_PRINT_Algorithm (randomness generating grid patterns) and shifts scale from grid to object. Precedes Random_Rotate_Random_XYZ, where randomness moves from shaping form to controlling transformation. The coin_toss and dice_throw artifacts make the generation mechanism tangible before random | [... truncated ...]
# BLURB: An arena of randomized edges — cubes with profiles shaped by chance. The grid imposes order; randomness fractures it. Walk among forms that could have been otherwise, each edge a frozen coin flip.  The `random_edge_profi…
[empty — to generate]

<<<MAP: Random_Rotate_Random_XYZ>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Three-dimensional randomness is not one roll but three — independent random rotations around X, Y, and Z axes compose into orientations that are unintuitive and irreducible to any single axis. Randomness in 3D is qualitatively different from randomness in 1D. | Sequence role: Fifth map in Randomness sequence. Follows Random_Cubes (randomness shaping form) and extends to randomness controlling transformation. Precedes Random_Walk, where random transformation becomes sequential and temporal. The hardware_entropy_decay artifact introduces physical entropy sources, connecting algorithmic ra | [... truncated ...]
# BLURB: Rotation untethered from purpose. Each axis receives its own chaos — independent random values for X, Y, Z — demonstrating that 3D randomness is not one roll of the dice but three.  The `Random_Rotate_Random_XYZ` artifac…
[empty — to generate]

<<<MAP: Random_Walk>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The random walk — each step chosen independently with no memory of the path — is the fundamental model of stochastic processes. No destination, no plan, only the next step. From Brownian motion to stock prices to diffusion, the random walk is how randomness moves through space and time. | Sequence role: Sixth map in Randomness sequence. Follows Random_Rotate_Random_XYZ (randomness in orientation) and introduces randomness as temporal process — a sequence of decisions unfolding in time rather than a static configuration. Precedes Random_Gaussian, where accumulated random steps produce th | [... truncated ...]
# BLURB: No destination, no plan — only the next step. The random walker drifts through possibility space, accumulating history without purpose, tracing paths that look intentional but aren't. Brownian motion made visible.  The `…
[empty — to generate]

<<<MAP: Random_Gaussian>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The Gaussian distribution — the bell curve — emerges not from a single random event but from the accumulation of many. The Central Limit Theorem proves that sums of independent random variables converge to the normal distribution regardless of their individual distributions. Order from chaos through aggregation. | Sequence role: Seventh map in Randomness sequence, the conceptual center. Follows Random_Walk, where accumulated random steps implied a distribution; this map names and formalizes that distribution. Precedes Random_Mushrooms, where Gaussian-distributed growth produces organic  | [... truncated ...]
# BLURB: Not all random is equal. The bell curve emerges from chaos through accumulation — the Central Limit Theorem made visible, the reason why so many things cluster around the mean.  The `galton_board` is the canonical physic…
[empty — to generate]

<<<MAP: Random_Mushrooms>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Fungi grow where conditions permit — substrate chemistry, moisture, temperature — and the placement of each fruiting body is a sample from an environmental probability distribution. The map connects biological randomness to the RAND Corporation's 1955 random number tables, framing both as attempts to harvest usable randomness from complex systems. | Sequence role: Eighth map in Randomness sequence. Follows Random_Gaussian (the bell curve as statistical attractor) and grounds distribution theory in biological form — mushroom placement as spatial sampling. Precedes Random_Space_Geometry,  | [... truncated ...]
# BLURB: Fungi grow where conditions permit — random spore distribution meeting environmental constraint. RAND Corporation's 1955 random number tables make an appearance: before computers generated chaos, we published it in books…
[empty — to generate]

<<<MAP: Random_Space_Geometry>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Randomness applied to spatial structure itself — not objects placed randomly in space, but space whose geometry is stochastically determined. Random transformations sculpt volumes, surfaces, and voids, making entropy a formal operation on space rather than a property of objects within it. | Sequence role: Ninth map in Randomness sequence. Follows Random_Mushrooms (biological randomness in space) and abstracts from organisms to pure spatial form. Precedes Randomness_Examples_of_Randomness, which surveys randomness across art and nature. The shift from random objects to random space marks | [... truncated ...]
# BLURB: Geometry meets entropy. Two chambers — north and south — connected by a narrow spine. Random geometry sculpts space itself, turning the grid into an arena of unpredictable forms.  The `random_transformations_geometric` d…
[empty — to generate]

<<<MAP: Randomness_Examples_of_Randomness>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: A gallery survey of randomness across domains — Pollock's drip paintings as action painting, pipe dreams as combinatorial play, butterfly flight as biological stochasticity, and extreme randomness as the tail of probability distributions. Randomness is not one phenomenon but a family of phenomena unified by irreducibility. | Sequence role: Tenth map in Randomness sequence and the only gallery-format map in the sequence. Follows Random_Space_Geometry (randomness as spatial principle) and pauses the progressive technical build to survey the concept across culture, nature, and mathematics. | [... truncated ...]
# BLURB: A gallery of creative chaos — Pollock's drip paintings, pipe dreams, butterflies in flight, extreme randomness pushed to visual limits. Art where the algorithm becomes the artist.  `pollock_painting_in_3d` translates act…
[empty — to generate]

<<<MAP: Random_Pheromone>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Pheromone systems demonstrate stigmergy — indirect coordination through environmental modification — where individually random agents produce collectively ordered behavior. Each ant walks randomly, but the pheromone trail it deposits biases subsequent walkers, converting individual chaos into colony-level intelligence. | Sequence role: Eleventh map in Randomness sequence. Follows Randomness_Examples_of_Randomness (randomness surveyed across domains) and introduces emergence — the sequence's late-stage thesis that randomness at one scale produces order at another. Precedes Random_Space,  | [... truncated ...]
# BLURB: Randomness with memory, trails that decay. Pheromone systems bridge individual chaos and collective order — each agent random, the swarm intelligent. Here randomness becomes stigmergy: communication through environment. …
[empty — to generate]

<<<MAP: Random_Space>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The sequence finale — randomness fills space itself. Where Random_Space_Geometry randomized spatial transformations and Random_Pheromone showed emergence from random agents, this map treats space as the substrate that randomness saturates, completing the arc from random number to random world. | Sequence role: Twelfth map in Randomness sequence, the narrative conclusion before the game map. Follows Random_Pheromone (emergence from collective randomness) and brings the sequence to its spatial terminus: randomness is no longer something that happens in space but something space is made of | [... truncated ...]
# BLURB: The sequence finale — randomness fills space itself. Gaussian distributions, fluttering butterflies, Pollock paintings converge in a contained arena. All the threads of the sequence woven into a final meditation on chaos…
[empty — to generate]

<<<MAP: Random_Game>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Randomness as gameplay — an 8x8 field of falling cubes creates a probabilistic hazard space where the floor itself is uncertain and origami-inspired enemies move with stochastic behaviors. The game tests whether the learner can act within randomness rather than merely observe it. | Sequence role: Thirteenth and final map in Randomness sequence, the game map that closes the E_entropy phase. Follows Random_Space (randomness as world-fabric) and converts every concept from the sequence into player-facing consequence: random projectile timing, probabilistic floor integrity, enemy movement p | [... truncated ...]
# BLURB: An 8x8 field of falling cubes. Each one sinks and rises on its own random timer — no pattern, no warning, no rhythm to learn. Cross the grid or get hit. The floor itself is probabilistic.  Origami enemies fold through th…
[empty — to generate]

<<<MAP: Chamber_Random>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Unpredictability as equality — neither player nor creature controls the outcome, because both sides draw their next action from noise drawn against the same distribution. No strategy dominates, because strategy itself is random. | Sequence role: Catalyst chamber for the Randomness sequence, the last map before returning to the Lab. After the sequence walked the learner from independent coin flips through distributions, removal, and the stochastic game arena, this chamber closes Randomness by making entropy the shared condition of an encounter. | Technical angle: Catalyst mode chaos, firin | [... truncated ...]
# BLURB: Chaos shots scatter unpredictably. The octapod cannot predict you. Randomness levels the field.  This is the catalyst chamber for the Randomness sequence — where entropy becomes encounter. You project chaos; the `octapod…
[empty — to generate]
