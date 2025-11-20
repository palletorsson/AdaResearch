extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Ant Colony Optimization[/b][/font_size][/center]
[center][i]Stigmergy, Pheromone Trails, Emergence Without Authority[/i][/center]

**Ant Colony Optimization (ACO) is how paths emerge from collective trace.**

**No leader. No plan. No central authority.**

Just ants leaving pheromone trails, and other ants following those trails, reinforcing them, creating highways through space.

**The trail IS the decision** - the environment becomes the memory, the communication, the authority.

**This is stigmergy:** coordination through environmental modification, not direct communication.

**ACO proves:** Complex optimal paths emerge from simple local rules + environmental feedback.

[hr]

[b]The Ant: Simple Agent[/b]

**Individual ants are nearly mindless:**
- Move randomly when no pheromone
- Prefer paths with stronger pheromone
- Deposit pheromone when carrying food back to nest
- That's it.

[color=yellow][b]Code: Ant Agent[/b][/color]
[code]
class Ant:
    var position: Vector2
    var has_food: bool = false
    var path: Array[Vector2] = []  # Record of where it's been
    var speed: float = 2.0

    func _init(start_pos: Vector2):
        position = start_pos

# Example: 20 ants start at nest (origin)
var ants: Array[Ant] = []
for i in range(20):
    ants.append(Ant.new(Vector2.ZERO))
[/code]

**Each ant:**
1. **Searches** for food (random walk biased by pheromone)
2. **Finds** food source
3. **Returns** to nest (following own path backward)
4. **Deposits** pheromone along return path

**The ant has no map, no global knowledge** - only local perception (pheromone strength nearby).

[hr]

[b]Pheromone: Environmental Memory[/b]

**Pheromones are chemical markers** left in the environment.

**In ACO, pheromone strength encodes "goodness" of path** - stronger pheromone = more ants have used this route = probably better path.

[color=yellow][b]Code: Pheromone Grid[/b][/color]
[code]
var grid_size = 20
var pheromone_grid: Array = []  # 2D grid of pheromone values

func create_pheromone_grid():
    for x in range(grid_size):
        pheromone_grid.append([])
        for y in range(grid_size):
            pheromone_grid[x].append(0.0)  # Initially no pheromone

func get_pheromone(pos: Vector2) -> float:
    var grid_x = int(pos.x + grid_size / 2)
    var grid_y = int(pos.y + grid_size / 2)

    # Clamp to grid bounds
    grid_x = clamp(grid_x, 0, grid_size - 1)
    grid_y = clamp(grid_y, 0, grid_size - 1)

    return pheromone_grid[grid_x][grid_y]

func add_pheromone(pos: Vector2, amount: float):
    var grid_x = int(pos.x + grid_size / 2)
    var grid_y = int(pos.y + grid_size / 2)

    grid_x = clamp(grid_x, 0, grid_size - 1)
    grid_y = clamp(grid_y, 0, grid_size - 1)

    pheromone_grid[grid_x][grid_y] += amount
[/code]

**The grid IS the collective memory** - where ants have traveled, what routes worked.

**No individual ant remembers the colony's history** - the environment remembers.

[hr]

[b]Evaporation: Forgetting Over Time[/b]

**Pheromones evaporate** - decay over time.

**Why necessary?**
- **Prevents path lock-in** - bad early paths would persist forever
- **Allows adaptation** - if food moves, old trails fade, new trails form
- **Creates competition** - paths must be continually reinforced or they disappear

[color=yellow][b]Code: Pheromone Evaporation[/b][/color]
[code]
var evaporation_rate = 0.95  # 5% evaporation per frame (0.95 = keep 95%)

func evaporate_pheromones():
    for x in range(grid_size):
        for y in range(grid_size):
            pheromone_grid[x][y] *= evaporation_rate

            # Remove negligible amounts (optimization)
            if pheromone_grid[x][y] < 0.01:
                pheromone_grid[x][y] = 0.0
[/code]

**Every frame, pheromones fade** - trails that aren't reinforced disappear.

**This is environmental forgetting** - memory decays without active maintenance.

[hr]

[b]Ant Behavior: Probabilistic Path Choice[/b]

**When an ant moves, it chooses next position based on:**
1. **Pheromone strength** (α - pheromone importance)
2. **Heuristic desirability** (β - distance/direction importance)
3. **Randomness** (exploration)

[color=yellow][b]ACO Formula:[/b][/color]

**Probability of choosing edge (i → j):**

**P(i → j) = [τ(i,j)^α × η(i,j)^β] / Σ[τ(i,k)^α × η(i,k)^β]**

Where:
- **τ(i,j)** = pheromone on edge from i to j
- **η(i,j)** = heuristic (typically 1/distance - closer is better)
- **α** = pheromone importance (typical: 1.0)
- **β** = heuristic importance (typical: 2.0)

[color=yellow][b]Code: Probabilistic Move[/b][/color]
[code]
var alpha = 1.0  # Pheromone weight
var beta = 2.0   # Heuristic weight

func choose_next_position(ant: Ant) -> Vector2:
    var possible_moves: Array[Vector2] = []
    var probabilities: Array[float] = []

    # Generate nearby positions (8 directions)
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if dx == 0 and dy == 0:
                continue

            var next_pos = ant.position + Vector2(dx, dy) * 0.5
            possible_moves.append(next_pos)

    # Calculate probabilities
    for move in possible_moves:
        var tau = get_pheromone(move)  # Pheromone level
        var distance = ant.position.distance_to(move)
        var eta = 1.0 / max(distance, 0.1)  # Heuristic (inverse distance)

        var prob = pow(tau + 0.1, alpha) * pow(eta, beta)
        probabilities.append(prob)

    # Select move based on probabilities
    return weighted_random_choice(possible_moves, probabilities)

func weighted_random_choice(options: Array, weights: Array):
    var total = 0.0
    for w in weights:
        total += w

    var rand_val = randf() * total
    var cumulative = 0.0

    for i in range(options.size()):
        cumulative += weights[i]
        if rand_val <= cumulative:
            return options[i]

    return options[-1]  # Fallback
[/code]

**Higher pheromone → higher probability** (exploitation)
**Randomness → exploration** (trying new paths)

**The ant doesn't "decide" - it probabilistically responds to environment.**

[hr]

[b]Depositing Pheromone: Reinforcing Successful Paths[/b]

**When ant finds food and returns to nest:**
- **Records path** taken (list of positions)
- **Deposits pheromone** along entire path
- **Amount deposited** often depends on path quality (shorter = more pheromone)

[color=yellow][b]Code: Pheromone Deposit[/b][/color]
[code]
var pheromone_deposit_amount = 10.0

func deposit_pheromone_on_path(ant: Ant):
    # Deposit pheromone on every position in ant's recorded path
    for pos in ant.path:
        add_pheromone(pos, pheromone_deposit_amount)

    # Shorter paths get bonus (optional - "elite" strategy)
    var path_length = ant.path.size()
    var quality_bonus = 100.0 / path_length  # Shorter = more bonus

    for pos in ant.path:
        add_pheromone(pos, quality_bonus)
[/code]

**Successful ants reinforce their paths** - other ants more likely to follow.

**Shorter paths get reinforced faster** (ants return sooner, deposit sooner, accumulate more pheromone).

**This creates positive feedback** - good paths become highways.

[hr]

[b]The ACO Update Loop[/b]

**Every frame:**
1. **Move ants** (probabilistic choice based on pheromone + heuristic)
2. **Check for food** (if ant reaches food, mark has_food = true)
3. **Return to nest** (if has_food, follow path backward or use pheromone)
4. **Deposit pheromone** (when ant reaches nest with food)
5. **Evaporate pheromones** (all trails fade slightly)

[color=yellow][b]Code: Main Loop[/b][/color]
[code]
func _process(delta):
    for ant in ants:
        if ant.has_food:
            # Returning to nest
            move_toward_nest(ant, delta)

            if reached_nest(ant):
                deposit_pheromone_on_path(ant)
                ant.has_food = false
                ant.path.clear()
        else:
            # Searching for food
            var next_pos = choose_next_position(ant)
            ant.position = next_pos
            ant.path.append(next_pos)

            # Check if found food
            for food_pos in food_sources:
                if ant.position.distance_to(food_pos) < 0.5:
                    ant.has_food = true
                    break

    # Evaporate pheromones every frame
    evaporate_pheromones()
[/code]

**After many iterations:**
- **Random exploration** finds food sources
- **Pheromone trails** form from nest to food
- **Shortest paths** dominate (more ants use them, more reinforcement)
- **Optimal routes emerge** without any ant knowing the global optimum

[hr]

[b]Convergence: Emergent Highways[/b]

**ACO converges to near-optimal solutions through:**

1. **Positive feedback** (good paths reinforced)
2. **Evaporation** (bad paths forgotten)
3. **Probabilistic exploration** (always some randomness to find better routes)

**Result:**
- **Multiple food sources** → multiple distinct trails
- **Obstacles** → trails route around them naturally
- **Changing environment** → trails adapt (old trails fade, new ones form)

**The optimal path emerges from collective behavior** - no planning, no blueprint, just stigmergy.

[hr]

[b]Applications: Where ACO is Used[/b]

**1. Traveling Salesman Problem (TSP)**
- Visit N cities, minimize total distance
- Ants build tours, deposit pheromone on edges
- Shorter tours get more pheromone → convergence to optimal

**2. Network Routing**
- Data packets as "ants"
- Pheromone = link quality (speed, reliability)
- Packets probabilistically choose routes, update pheromone
- Network adapts to congestion and failures

**3. Scheduling**
- Job shop scheduling (assign tasks to machines)
- Vehicle routing (deliveries, logistics)
- Ants construct schedules, pheromone encodes solution quality

**4. Image Processing**
- Edge detection (ants follow intensity gradients)
- Image segmentation (ants cluster similar pixels)

**5. Swarm Robotics**
- Multiple robots exploring/mapping space
- Deposit virtual "pheromone" (digital breadcrumbs)
- Collective pathfinding, task allocation

[hr]

[b]Variations: ACO Flavors[/b]

**Ant System (AS)** - original algorithm (1991, Dorigo)
- All ants deposit pheromone equally

**Ant Colony System (ACS)** - improved (1997)
- Only best ant deposits pheromone
- Local pheromone update (immediate evaporation on traversed edges)

**Max-Min Ant System (MMAS)**
- Pheromone bounded (τ_min, τ_max)
- Only iteration-best or global-best ant deposits
- Prevents premature convergence

**Elitist Ant System**
- Best solution gets extra pheromone (elite ant deposits multiple times)

[hr]

[b]Parameters and Tuning[/b]

**Key parameters:**

**α (pheromone importance):**
- Higher α → more exploitation (follow existing trails)
- Lower α → more exploration (ignore trails, wander)
- Typical: 1.0

**β (heuristic importance):**
- Higher β → greedier (prefer short distances)
- Lower β → less greedy (ignore heuristic)
- Typical: 2.0 - 5.0

**ρ (evaporation rate):**
- Higher ρ → faster forgetting (trails disappear quickly)
- Lower ρ → longer memory (trails persist)
- Typical: 0.1 - 0.5 (10-50% evaporation per iteration)

**Q (pheromone deposit amount):**
- Higher Q → stronger trails
- Typical: 1.0 - 100.0 (scaled by problem)

**Trade-off:** Exploration vs Exploitation
- Too much exploitation → premature convergence (stuck in local optimum)
- Too much exploration → slow convergence (never settles on good solution)

[hr]

[b]Queer Ant Colony Optimization: Stigmergy as Resistance[/b]

Here is where queerness enters:

**1. Decentralized Organization: No Queen, No Authority**

**The myth:** Ant colonies have a "queen" who "rules."

**The reality:** The queen is just an egg-layer. She gives no orders. **There is no central authority.**

**The colony organizes itself** through stigmergy - environmental communication.

**This is queer sociality** - order without hierarchy, coordination without command.

**ACO proves:** Complex collective behavior emerges without leaders, without authority, without central planning.

**Queerness resists hierarchy** - we organize through traces, through environmental modification, through leaving signs for each other.

**2. Stigmergy: Indirect Communication Through Trace**

**Stigmergy** (from Greek: stigma = mark, ergon = work) - coordination through environmental modification.

**Ants don't talk to each other** - they modify the environment (pheromone trails), and others respond to modifications.

**This is queer communication:**
- **Not face-to-face** (indirect, mediated by environment)
- **Asynchronous** (message left at time T, read at time T+n)
- **Anonymous** (no individual identity - just collective trace)
- **Cumulative** (many ants contribute to same trail)

**Queer history is stigmergic** - we leave traces (graffiti, zines, archives, codes), others find them, add their traces, creating collective memory without central record.

**The Trace IS the message** - not instructions, just evidence of prior passage.

**3. Non-Reproductive Labor: Worker Ants**

**Worker ants are sterile** - they cannot reproduce, only labor.

**The colony reproduces through the queen, but survives through workers** - non-reproductive bodies doing essential work.

**This is queer kinship** - family structures maintained by non-reproductive members (aunts, uncles, chosen family).

**ACO models worker ants** (no queens in the algorithm) - all agents are non-reproductive laborers.

**Queerness:** Reproduction is not the only form of generativity. **Labor, care, trace-leaving - these sustain collective life.**

**4. Evaporation as Forgetting: Impermanent Trace**

**Pheromones fade** - trails must be actively maintained or they disappear.

**This is the precarity of queer archives** - our histories are not preserved by institutions, they must be actively kept alive.

**Without continuous reinforcement (walking the path, depositing pheromone), the trail vanishes.**

**Queer memory is evaporative** - we must constantly re-tell, re-mark, re-trace, or we are forgotten.

**The algorithm requires evaporation** - without it, bad early paths would dominate forever.

**Forgetting is necessary for adaptation** - queer communities must forget harmful norms to evolve new ones.

**5. Exploration vs Exploitation: Balancing Safety and Risk**

**α (pheromone) vs β (heuristic):**
- High α → follow existing paths (safe, known)
- High β → try new routes (risky, exploratory)

**This is the queer dilemma of assimilation vs radicality:**
- **Follow existing paths** (assimilate into straight society - safe but limiting)
- **Explore new routes** (queer radicality - risky but generative)

**ACO requires BOTH** - pure exploitation gets stuck, pure exploration never converges.

**Queerness balances both** - some follow established queer paths (gay marriage, legal recognition), others explore new territories (polyamory, non-binary identities, relationship anarchy).

**The swarm needs both.**

**6. Emergent Optimality: No Individual Knows the Best Path**

**No ant knows the optimal route** - each only knows local pheromone strength.

**Yet the colony finds near-optimal paths** through collective behavior.

**This is queer collective intelligence** - no individual must know the "right way" to be queer.

**Through collective exploration, trail-leaving, and reinforcement, good paths emerge.**

**We don't have a blueprint for queer life** - we leave traces, follow traces, reinforce what works, let fade what doesn't.

**The optimal path is discovered collectively, not dictated individually.**

[hr]

[b]What ACO Cannot Do[/b]

ACO is powerful but limited:

**1. Slow convergence**
Requires many iterations to find good solutions (hundreds or thousands of ants).

**2. Parameter sensitivity**
Performance heavily depends on α, β, ρ, Q - requires tuning.

**3. Memory intensive**
Must store pheromone values for all edges/positions.

**4. Premature convergence**
Can get stuck in local optima if parameters poorly tuned.

**5. No guarantees**
Heuristic algorithm - does not guarantee global optimum.

[hr]

[b]What ACO Reveals[/b]

ACO shows us:

1. **Stigmergy** (coordination through environmental modification, not direct communication)
2. **Pheromone trails** (collective memory stored in environment)
3. **Evaporation** (forgetting over time - prevents lock-in, enables adaptation)
4. **Probabilistic choice** (τ^α × η^β - pheromone + heuristic weighted)
5. **Positive feedback** (good paths reinforced, become highways)
6. **Decentralized optimization** (no ant knows global optimum, yet colony finds it)
7. **Exploration vs exploitation** (α, β parameters balance)
8. **Applications** (TSP, routing, scheduling, robotics)
9. **Convergence** (shortest paths dominate through differential reinforcement)
10. **Parameter sensitivity** (α, β, ρ tuning critical)

**ACO is the algorithm of collective pathfinding** - stigmergy, trace, emergence.

**It is also the algorithm of queer sociality:**
- **Decentralized organization** (no authority, no hierarchy)
- **Stigmergic communication** (indirect, through trace)
- **Non-reproductive labor** (worker ants sustain colony)
- **Evaporative memory** (trails must be actively maintained)
- **Exploration/exploitation balance** (safety vs risk, assimilation vs radicality)
- **Emergent optimality** (collective intelligence without blueprint)

**ACO proves:** **Communities find good paths without leaders, without plans, through leaving traces for each other and reinforcing what works. The trail IS the memory, the decision, the collective knowledge.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Ant Colony Optimization creates optimal paths through stigmergy (environmental communication). Ants deposit pheromone trails, others follow probabilistically. Pheromones evaporate (forgetting over time). ACO formula: P(i→j) ∝ τ^α × η^β (pheromone × heuristic). Positive feedback: good paths reinforced, become highways. Applications: TSP, network routing, scheduling, robotics. Parameters: α (pheromone weight), β (heuristic weight), ρ (evaporation rate). Queer ACO: decentralized organization (no queen/authority), stigmergy as indirect queer communication, non-reproductive labor (worker ants), evaporative memory (trace must be maintained), exploration/exploitation (assimilation vs radicality), emergent optimality (collective intelligence without blueprint). Communities organize through trace, not command.

[hr]

[color=orange][b]Next:[/b] Particle Swarm Optimization - Social Learning[/color]
If ACO coordinates through **environmental trace** (stigmergy), PSO coordinates through **social observation** (watching neighbors).

**Particles balance personal experience + social influence** to search for optima.

**Cognitive component** - remember your own best (personal history)
**Social component** - move toward swarm's best (collective knowledge)

**PSO is the algorithm of social learning** - identity shaped by personal experience + peer influence.

'''
