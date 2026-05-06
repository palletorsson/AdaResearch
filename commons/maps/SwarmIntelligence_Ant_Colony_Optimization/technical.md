# Pheromone trails accumulate along branching corridors where ants solve optimization problems no individual understands

Boids coordinated through direct perception. Each boid read its neighbors' positions and velocities, computed three steering forces, and adjusted. The communication channel was peer-to-peer — instant, memoryless, erased every frame. No boid left a trace. The flock existed only in the present tense.

Ant colony optimization restores the environment as medium. An ant does not perceive other ants. It perceives pheromone — a chemical substance deposited on the ground by previous walkers. The trail persists after the ant that laid it has moved on. It accumulates when many ants walk the same path.

It evaporates when neglected. The environment carries the message across time. This is stigmergy again, the same principle that drove Physarum, but formalized into an optimization algorithm by Marco Dorigo in 1992. Where boids coordinated in space, ants coordinate through time. Where boids produced flocking, ants produce solutions to combinatorial problems that resist brute-force search.

The branching corridor network in this map is the problem made physical. Corridors are edges. Junctions are nodes. The colony must find the shortest route through a graph — a constrained version of the traveling salesman problem, NP-hard in its general form. No ant solves it. The pheromone gradient solves it, and the ants are the gradient's hands.

## The Graph: Corridors as Edges

Every ACO problem begins with a graph. Nodes represent decision points — places where an ant must choose. Edges represent the paths between them. Each edge carries two quantities: a pheromone intensity and a heuristic desirability.

```gdscript
var num_nodes: int = 12
var edges: Dictionary = {}
var pheromone: Dictionary = {}
var distances: Dictionary = {}

func _ready() -> void:
    for i in num_nodes:
        for j in num_nodes:
            if i == j:
                continue
            if _corridor_exists(i, j):
                var key: String = _edge_key(i, j)
                distances[key] = _measure_corridor_length(i, j)
                pheromone[key] = initial_pheromone

func _edge_key(i: int, j: int) -> String:
    return str(min(i, j)) + "_" + str(max(i, j))
```

The `AntColonyV2` artifact maps the branching corridor network directly onto this graph structure. Each junction in the Y-shaped corridor system becomes a node. Each corridor segment becomes an edge with a measurable length. The distances dictionary stores the physical length of each corridor — the heuristic information that ants use alongside pheromone to make decisions. The edge key is symmetric because pheromone on the corridor from node 3 to node 7 is the same substance as pheromone from 7 to 3. Ants walk in both directions on the same surface.

Initial pheromone is uniform across all edges — a small positive value, never zero. Zero pheromone makes an edge permanently invisible. The uniform starting value ensures every path has a nonzero probability of selection at the start. The colony begins in maximum ignorance, and the pheromone landscape differentiates through experience.

## The Ant: A Stateless Walker

An ant carries a current node, a list of visited nodes, and nothing else. No memory of pheromone concentrations. No model of the graph. No communication with other ants. The ant walks, chooses, deposits, and forgets.

```gdscript
var num_ants: int = 30
var ant_paths: Array = []
var ant_positions: PackedInt32Array
var ant_visited: Array = []

func _initialize_ants() -> void:
    ant_positions.resize(num_ants)
    ant_paths.resize(num_ants)
    ant_visited.resize(num_ants)

    for k in num_ants:
        ant_positions[k] = start_node
        ant_paths[k] = [start_node]
        ant_visited[k] = {}
        ant_visited[k][start_node] = true
```

Thirty ants, all starting from the same node — the nest, the colony origin at the corridor network entrance. Each ant maintains a visited set to prevent cycles. An ant that has already visited node 5 will not return to node 5 on this trip. The path array records the sequence of nodes traversed, which determines the total path length after the ant completes its tour. The ant does not evaluate its path quality while walking. Evaluation happens only at the end, when the full route is known.

The ant count is a design parameter. Too few ants and the pheromone landscape updates slowly — exploration stalls. Too many and the computation per iteration dominates — the simulation crawls. Thirty ants per iteration is a common default for moderate-sized graphs. The number scales with problem complexity, not with the desired solution quality. Quality comes from iterations, not population.

## Edge Selection: The Probabilistic Rule

At each junction, an ant must choose its next corridor. The probability of selecting edge (i, j) depends on two factors: the pheromone intensity on that edge and the heuristic desirability of that edge.

```gdscript
var alpha: float = 1.0  # pheromone weight
var beta: float = 2.0   # heuristic weight

func _select_next_node(ant_idx: int) -> int:
    var current: int = ant_positions[ant_idx]
    var visited: Dictionary = ant_visited[ant_idx]
    var neighbors: PackedInt32Array = _get_unvisited_neighbors(current, visited)

    if neighbors.is_empty():
        return -1

    var probabilities: PackedFloat64Array
    probabilities.resize(neighbors.size())
    var total: float = 0.0

    for n in neighbors.size():
        var j: int = neighbors[n]
        var key: String = _edge_key(current, j)
        var tau: float = pheromone[key]
        var eta: float = 1.0 / distances[key]
        var value: float = pow(tau, alpha) * pow(eta, beta)
        probabilities[n] = value
        total += value

    # Roulette wheel selection
    var roll: float = randf() * total
    var cumulative: float = 0.0
    for n in neighbors.size():
        cumulative += probabilities[n]
        if roll <= cumulative:
            return neighbors[n]

    return neighbors[neighbors.size() - 1]
```

The formula is Dorigo's transition rule. Tau is pheromone intensity — how many ants have reinforced this edge. Eta is heuristic desirability — the inverse of distance, because shorter corridors are more attractive. Alpha controls how strongly pheromone influences the decision. Beta controls how strongly distance influences it. The product `tau^alpha * eta^beta` weights each candidate edge, and roulette-wheel selection picks one stochastically according to those weights.

When alpha dominates (alpha >> beta), ants follow pheromone almost blindly. The colony converges fast but risks locking onto a suboptimal path that happened to get reinforced early. When beta dominates (beta >> alpha), ants prefer short edges regardless of pheromone — they become greedy distance minimizers that ignore collective experience. The balance between alpha and beta is the balance between exploitation and exploration. The colony exploits accumulated knowledge through pheromone. It explores new possibilities through the heuristic and through the stochastic selection itself.

The roulette wheel is not a uniform random choice. An edge with twice the weighted value gets twice the selection probability. But even a weakly pheromoned, long-distance edge retains some probability — it can be chosen. This residual randomness is what prevents premature convergence. The colony always has a nonzero chance of trying something new.

## Pheromone Deposition: Writing to the Environment

After all ants complete their tours, each ant deposits pheromone on every edge in its path. The amount deposited is inversely proportional to the total path length — shorter paths receive more pheromone per edge.

```gdscript
var deposit_factor: float = 100.0

func _deposit_pheromone() -> void:
    for k in num_ants:
        var path: Array = ant_paths[k]
        var path_length: float = _calculate_path_length(path)

        if path_length <= 0.0:
            continue

        var deposit: float = deposit_factor / path_length

        for step in range(path.size() - 1):
            var key: String = _edge_key(path[step], path[step + 1])
            pheromone[key] += deposit

func _calculate_path_length(path: Array) -> float:
    var total: float = 0.0
    for step in range(path.size() - 1):
        var key: String = _edge_key(path[step], path[step + 1])
        total += distances[key]
    return total
```

The deposit rule encodes solution quality into the environment. An ant that found a short path deposits more pheromone per edge than one that wandered a long route. Over many iterations, edges that appear in short paths accumulate disproportionately more pheromone than edges in long paths. The environment becomes a map of solution quality — a chemical gradient that points toward good routes.

This is the optimization mechanism. No ant compares paths. No ant knows whether its route was good or bad. The deposit formula performs the evaluation implicitly: short path means high deposit, long path means low deposit. The environment aggregates these deposits across all ants and all iterations. The pheromone landscape is the colony's distributed memory — external, persistent, accessible to every ant without coordination.

The deposit factor scales the pheromone increment. Too high and pheromone accumulates faster than evaporation can regulate — the system saturates. Too low and trails never differentiate from the uniform background. The factor must be tuned relative to the evaporation rate and the number of ants. In practice, setting it proportional to the number of nodes times the average edge length provides a stable starting point.

## Pheromone Evaporation: Forgetting Bad Paths

After deposition, all pheromone decays. Every edge loses a fixed fraction of its current pheromone intensity, regardless of whether ants walked it this iteration.

```gdscript
var evaporation_rate: float = 0.1

func _evaporate_pheromone() -> void:
    for key in pheromone:
        pheromone[key] *= (1.0 - evaporation_rate)
        pheromone[key] = maxf(pheromone[key], min_pheromone)
```

Evaporation rate rho = 0.1 means each edge retains 90% of its pheromone per iteration. After ten iterations without reinforcement, an edge retains 0.9^10 = 0.35 of its original pheromone. After fifty iterations, 0.9^50 = 0.005 — effectively zero. Evaporation is exponential decay. Unused paths fade. Reinforced paths persist because deposition outpaces decay.

The minimum pheromone floor prevents complete extinction. An edge reduced to zero pheromone has zero selection probability — it becomes permanently invisible, removed from the search space. The floor preserves a whisper of possibility on every edge, maintaining the colony's ability to rediscover abandoned paths if the current solution proves suboptimal.

Evaporation is what makes ACO adaptive. Without it, the first reasonable path found would accumulate pheromone indefinitely, and the colony would lock onto it regardless of quality. Evaporation introduces temporal discounting — recent experience matters more than old experience. If the environment changes (edges are added or removed, distances shift), evaporation allows the pheromone landscape to forget outdated information and reconverge on new solutions. The colony is not just an optimizer. It is an anytime optimizer — one that can track a moving target.

## The Iteration Loop: Colony as Search

One iteration consists of three phases: all ants walk, all ants deposit, all pheromone evaporates. Then the ants reset to the start node and walk again.

```gdscript
var best_path: Array = []
var best_length: float = INF
var iteration: int = 0
var max_iterations: int = 200

func _run_iteration() -> void:
    _initialize_ants()

    # Phase 1: all ants construct solutions
    for step in num_nodes:
        for k in num_ants:
            var next: int = _select_next_node(k)
            if next == -1:
                continue
            ant_positions[k] = next
            ant_paths[k].append(next)
            ant_visited[k][next] = true

    # Phase 2: evaluate and deposit
    for k in num_ants:
        var length: float = _calculate_path_length(ant_paths[k])
        if length < best_length and ant_paths[k].size() > 1:
            best_length = length
            best_path = ant_paths[k].duplicate()

    _deposit_pheromone()

    # Phase 3: evaporate
    _evaporate_pheromone()

    iteration += 1
```

The best path is tracked globally across all iterations. It never participates in pheromone deposition directly — it is an observation, not a force. Some ACO variants (Ant Colony System, MAX-MIN Ant System) allow only the best ant to deposit, or clamp pheromone within bounds. The basic Ant System described here lets all ants deposit, which spreads reinforcement across many edges and slows convergence but improves exploration.

Early iterations produce mediocre paths. The pheromone landscape is nearly uniform, so selection is nearly random — ants wander. As iterations accumulate, edges on good paths gain pheromone and attract more ants, which deposit more pheromone, which attracts more ants. This is positive feedback — the same autocatalytic loop that drives real ant trail formation. The positive feedback amplifies small initial advantages into dominant trails.

The danger of positive feedback is premature convergence. If one path gains an early lead through random chance, it can lock in before the colony has explored alternatives. Evaporation counters this, but not always sufficiently. The alpha-beta balance, the ant count, and the evaporation rate all modulate how quickly the colony commits. Tuning these parameters is the art of ACO — balancing the speed of convergence against the quality of the solution found.

## Visualization: The Pheromone Heatmap

The `AntColonyV2` artifact renders pheromone concentration as a color gradient across the corridor network. High pheromone corridors glow warm — amber and white. Low pheromone corridors dim toward cool blue or gray. The visual is a heatmap overlaid on the physical corridors of the branching network.

```gdscript
func _update_corridor_visuals() -> void:
    for key in pheromone:
        var intensity: float = pheromone[key]
        var normalized: float = clampf(
            (intensity - min_pheromone) / (max_observed_pheromone - min_pheromone),
            0.0, 1.0)

        var color: Color = low_pheromone_color.lerp(high_pheromone_color, normalized)
        var corridor: MeshInstance3D = corridor_meshes[key]
        var mat: StandardMaterial3D = corridor.get_surface_override_material(0)
        mat.albedo_color = color
        mat.emission = color
        mat.emission_energy_multiplier = lerpf(0.2, 2.0, normalized)
```

Normalization maps the raw pheromone range to [0, 1] for color interpolation. The max observed pheromone updates each frame — the scale adapts to the colony's current state rather than being fixed. This prevents the heatmap from saturating early or remaining dim late. As the colony converges, the contrast between reinforced and neglected corridors sharpens. The dominant path burns bright. The alternatives fade.

The emission energy scales with concentration. Bright corridors emit light into the 3D environment, casting subtle colored reflections on the corridor walls. The learner walks through the branching network and sees which paths the colony favors — not as a data readout but as a spatial experience. The solution glows.

## Convergence: From Noise to Signal

In the first few iterations, the heatmap is nearly uniform — all corridors glow faintly. Ants select paths almost randomly. The pheromone landscape is noise.

By iteration twenty, one or two paths begin to differentiate. The Y-junction in the corridor network becomes the critical decision point. If the left branch is shorter, ants that take it deposit more pheromone per edge. The left branch brightens. More ants follow. The right branch dims. The positive feedback loop has engaged.

By iteration one hundred, the dominant path is clearly visible — a bright river of pheromone from nest to goal. The alternative paths are nearly dark, maintained only by the minimum pheromone floor and the occasional stochastic explorer. The colony has converged.

Convergence does not mean the colony stops searching. Even at iteration two hundred, some ants still choose dim corridors. They almost always find longer paths and deposit less pheromone. But occasionally, a stochastic explorer discovers a shortcut that the dominant path missed — an edge combination that no previous ant happened to try. If this new path is short enough, its deposit outpaces evaporation on the dominant path, and the colony begins to shift. This is late-stage rediscovery — rare, slow, but possible because the minimum pheromone floor keeps every edge alive.

The prediction error framework applies directly. Each ant's edge selection implicitly predicts that high-pheromone, short-distance corridors lead to good solutions. The deposit-evaporation cycle updates these predictions across the environment. When the colony converges, the pheromone landscape encodes a stable prediction — "this path is optimal" — that all subsequent ants confirm by walking it and depositing more pheromone. The prediction becomes self-fulfilling, stabilized by the same positive feedback that created it.

## From Stigmergy to Social Learning

ACO and boids represent two poles of swarm coordination. Boids share state through direct perception — instantaneous, symmetric, ephemeral. ACO shares state through the environment — delayed, asymmetric, persistent. The boid sees its neighbor's velocity right now. The ant sees pheromone laid down by an unknown predecessor at an unknown time. Both produce collective intelligence. The mechanisms are complementary.

Particle Swarm Optimization, the next map in this sequence, introduces a third channel: social memory. Each particle remembers its personal best position and knows the swarm's global best. The communication is neither environmental nor perceptual — it is cognitive. The particle carries an internal model updated by experience. Where pheromone is written on the ground and velocity is read from neighbors, the personal best is stored in the agent's own state. The optimization moves inward, from environment to mind.

The progression — stigmergy (Physarum, ACO), perception (boids), social learning (PSO) — traces the evolution of coordination mechanisms in swarm intelligence. Each map in this sequence adds a communication channel. Each channel produces different dynamics, different failure modes, different parameter sensitivities. ACO excels at discrete combinatorial problems because the graph structure and pheromone discretization match the problem structure. PSO excels at continuous function optimization because the particle's position in a continuous space maps directly to a candidate solution. The algorithm must match the problem's topology.

## Possible Artifacts

**pheromone_decay_visualizer** — Displays pheromone concentration as a color gradient across the corridor network with a time-lapse mode that accelerates the evaporation process. Sliders control evaporation rate and deposit factor independently, letting the learner observe how the balance between reinforcement and decay determines convergence speed and solution quality. At high evaporation the colony forgets too fast and wanders indefinitely. At low evaporation it remembers too well and locks onto the first acceptable path. The tension between these extremes is the core dynamic of ACO.

**alpha_beta_explorer** — Exposes the alpha and beta parameters as interactive controls alongside a real-time display of edge selection probabilities at each junction. When alpha is maxed, the probability distribution tracks pheromone intensity almost exactly — the colony becomes a pure follower of historical success. When beta is maxed, the distribution tracks inverse distance — the colony becomes a pure greedy optimizer ignoring collective experience. Intermediate values produce the characteristic ACO blend of exploitation and exploration, visible as a probability landscape that shifts across iterations.

**ant_path_tracer** — Selects a single ant and renders its complete path through the corridor network as a colored trail, updated each iteration. A history panel shows the last ten paths taken by this ant, fading older paths. The learner watches one individual's choices evolve as the pheromone landscape changes — from random wandering in early iterations to near-deterministic path following in late iterations. Demonstrates that the individual ant does not improve. The environment improves, and the ant's behavior changes as a consequence.
