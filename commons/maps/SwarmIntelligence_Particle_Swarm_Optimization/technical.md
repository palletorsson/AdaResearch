# Particles remember their best position and know the swarm's best — from this dual memory, a population finds optima without gradients

Ant colony optimization solved combinatorial problems through environmental memory — pheromone trails on edges, accumulated by the colony, read by individuals. No ant remembered its own history beyond the current tour's visited set. The intelligence was in the trail, not the agent.

Particle swarm optimization inverts this. The intelligence is in the agents. Each particle carries a personal memory — its own best position ever visited. The swarm shares a global memory — the best position any particle has ever found. The environment carries no information. No trail. No pheromone. The fitness landscape is read but never written. Optimization happens through social learning: particles adjust their velocity toward their personal best and toward the global best, with randomness preventing premature convergence.

## The Particle

A PSO particle carries position, velocity, and two memories: personal best and access to global best.

```gdscript
var num_particles: int = 50
var positions: PackedVector3Array
var velocities: PackedVector3Array
var personal_best_positions: PackedVector3Array
var personal_best_fitness: PackedFloat32Array
var global_best_position: Vector3
var global_best_fitness: float = INF

func _ready() -> void:
    positions.resize(num_particles)
    velocities.resize(num_particles)
    personal_best_positions.resize(num_particles)
    personal_best_fitness.resize(num_particles)

    for i in num_particles:
        positions[i] = Vector3(
            randf_range(-search_range, search_range),
            0.0,
            randf_range(-search_range, search_range))
        velocities[i] = Vector3(
            randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))

        personal_best_positions[i] = positions[i]
        var fitness: float = evaluate(positions[i])
        personal_best_fitness[i] = fitness

        if fitness < global_best_fitness:
            global_best_fitness = fitness
            global_best_position = positions[i]
```

Each particle scatters randomly across the search space and evaluates the fitness landscape at its initial position. The initial personal best is the starting position — the particle has visited nowhere else. The initial global best is the best starting position across all particles — a random head start that may be far from the true optimum.

## The Fitness Landscape

The fitness function maps positions to scalar values. The `PSOVisualization` artifact renders this function as terrain — the search space becomes a physical landscape the learner can see from the elevated observation deck.

```gdscript
func evaluate(pos: Vector3) -> float:
    # Rastrigin function: multimodal with many local minima
    var x: float = pos.x
    var z: float = pos.z
    var n: float = 2.0
    return 10.0 * n + (x * x - 10.0 * cos(TAU * x)) + (z * z - 10.0 * cos(TAU * z))

# Or Ackley function for deceptive landscapes:
func evaluate_ackley(pos: Vector3) -> float:
    var x: float = pos.x
    var z: float = pos.z
    return -20.0 * exp(-0.2 * sqrt(0.5 * (x * x + z * z))) - \
           exp(0.5 * (cos(TAU * x) + cos(TAU * z))) + E + 20.0
```

The Rastrigin function produces a landscape of concentric ridges with many local minima and one global minimum at the origin. The Ackley function produces a deceptive landscape with a broad, nearly flat valley surrounding a narrow global minimum. Both are standard test functions for optimization algorithms, chosen because they are difficult — gradient descent gets trapped in local minima, and the global minimum requires global search.

The terrain rendering maps fitness to height: the global minimum is the valley floor, local minima are small depressions in the surrounding hills. Particles are rendered as spheres swooping through this landscape, their vertical position tracking the terrain's elevation at each point.

## The Velocity Update

The core equation governs how each particle adjusts its velocity each frame.

```gdscript
var inertia_weight: float = 0.7
var cognitive_coeff: float = 1.5    # c1: pull toward personal best
var social_coeff: float = 1.5       # c2: pull toward global best

func update_velocity(i: int) -> void:
    var r1: float = randf()
    var r2: float = randf()

    var cognitive_pull: Vector3 = cognitive_coeff * r1 * \
        (personal_best_positions[i] - positions[i])
    var social_pull: Vector3 = social_coeff * r2 * \
        (global_best_position - positions[i])
    var inertia: Vector3 = inertia_weight * velocities[i]

    velocities[i] = inertia + cognitive_pull + social_pull
```

Three terms:

**Inertia** — the particle continues in its current direction, scaled by weight w. High inertia means the particle maintains momentum and explores broadly. Low inertia means the particle responds quickly to cognitive and social signals but searches less.

**Cognitive pull** — the particle moves toward its own best-known position. This is personal memory — the particle trusts its own experience. The random factor r1 prevents deterministic convergence.

**Social pull** — the particle moves toward the global best position. This is social learning — the particle trusts the swarm's collective experience. The random factor r2 introduces variation in how strongly each particle responds.

The balance between cognitive and social coefficients determines whether the swarm is a collection of independent explorers (high c1, low c2) or a socially dominated herd (low c1, high c2). The canonical setting c1 = c2 = 1.5 balances individual and collective knowledge.

## Position Update and Evaluation

After the velocity update, the particle moves and evaluates its new position.

```gdscript
func update_particle(i: int) -> void:
    update_velocity(i)
    positions[i] += velocities[i]

    # Evaluate fitness at new position
    var fitness: float = evaluate(positions[i])

    # Update personal best
    if fitness < personal_best_fitness[i]:
        personal_best_fitness[i] = fitness
        personal_best_positions[i] = positions[i]

    # Update global best
    if fitness < global_best_fitness:
        global_best_fitness = fitness
        global_best_position = positions[i]
```

Memory is one-directional: only improvements are recorded. A particle that wanders into worse territory does not forget its previous best. The personal best is a ratchet — it only moves toward better fitness. The global best is the population-level ratchet — it only improves. The swarm's collective knowledge monotonically increases over time.

## The Simulation Loop

```gdscript
func _process(delta: float) -> void:
    for i in num_particles:
        update_particle(i)

    # Optional: decay inertia over time for convergence
    inertia_weight *= 0.999

    update_display()
```

Inertia decay is a convergence strategy. Early in the search, high inertia encourages exploration — particles sweep across the landscape. As inertia decreases, particles settle — they circle tighter around the global best. The decay rate controls the transition from exploration to exploitation. Too fast and the swarm converges before finding the global minimum. Too slow and the swarm wanders long after finding it.

## Exploration vs. Exploitation

The tension between exploration (searching new regions) and exploitation (refining around the best known) is the central challenge of any optimization algorithm. PSO manages this tension through three mechanisms:

**Random coefficients r1 and r2** inject stochastic variation each frame. Even a particle near the global best will occasionally overshoot or veer sideways.

**Inertia weight** controls the baseline exploration rate. High inertia means particles carry momentum past the global best, potentially discovering better regions.

**Multiple attractors** — personal best and global best are generally different points. The particle is pulled in two directions simultaneously. The tension between these attractors creates oscillatory behavior that scans the region between them.

The particles visible from the observation deck exhibit characteristic behavior: initial scatter across the landscape, rapid convergence toward the first discovered good region, then a tightening spiral as inertia decays. Particles that start near a different local minimum may be pulled toward the global best slowly, crossing ridges in the Rastrigin landscape, demonstrating the algorithm's ability to escape local optima through social information.

## The Observation Deck

The map layout — concentric height rings descending from the rim to a central valley — mirrors the fitness landscape. The elevated deck provides a bird's-eye view of particle trajectories. The learner stands above the optimization process, watching particles converge, overshoot, spiral, and settle. The spatial correspondence between map geometry and fitness landscape makes the optimization tangible: the valley the learner descends to is the minimum the particles seek.

## From ACO to PSO: Two Models of Collective Memory

ACO stores memory in the environment (pheromone on edges). PSO stores memory in the agents (personal best, global best). Both solve optimization problems. Both use populations of simple agents. The mechanism differs fundamentally:

ACO: agents are memoryless; the environment remembers; coordination is stigmergic.
PSO: agents have memory; the environment is passive; coordination is social.

The contrast illuminates two modes of collective intelligence. Stigmergic systems distribute memory across the medium. Social systems concentrate memory in the agents. Neither is universally superior — ACO excels at combinatorial problems on graphs, PSO excels at continuous-domain function optimization. The swarm intelligence sequence presents both, letting the learner see that the same problem (finding optima) can be solved by oppositely structured coordination mechanisms.
