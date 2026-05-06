extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Particle Swarm Optimization[/b][/font_size][/center]
[center][i]Social Learning, Collective Search, Balancing Self and Swarm[/i][/center]

**Particle Swarm Optimization (PSO) searches for optimal solutions through social learning.**

**Each particle has:**
- **Personal memory** (where I found my best)
- **Social awareness** (where the swarm found its best)
- **Velocity** (momentum carrying me through space)

**Particles balance:**
- **Cognitive component** - trust my own experience
- **Social component** - trust the swarm's knowledge
- **Inertia** - keep moving in current direction

**PSO is collective search** - exploring fitness landscapes together, learning from each other, converging on optima.

[hr]

[b]The Particle: Agent with Memory and Velocity[/b]

**Unlike ACO ants, PSO particles have:**
1. **Position** in search space
2. **Velocity** (direction and speed of movement)
3. **Personal best** memory (best position I've found)
4. **Awareness of global best** (best position anyone has found)

[color=yellow][b]Code: Particle Class[/b][/color]
[code]
class Particle:
    var position: Vector2  # Current position
    var velocity: Vector2  # Current velocity
    var personal_best_position: Vector2  # My best position
    var personal_best_fitness: float = -INF  # Fitness at my best

    func _init(start_pos: Vector2):
        position = start_pos
        velocity = Vector2(randf() * 2 - 1, randf() * 2 - 1)  # Random initial velocity
        personal_best_position = start_pos
        personal_best_fitness = -INF

# Global best (shared by all particles)
var global_best_position: Vector2 = Vector2.ZERO
var global_best_fitness: float = -INF

# Create swarm
var particles: Array[Particle] = []
for i in range(25):
    var start_pos = Vector2(randf() * 16 - 8, randf() * 16 - 8)
    particles.append(Particle.new(start_pos))
[/code]

**Each particle remembers its personal history** (not just current state).

**All particles share knowledge of global best** (collective memory).

[hr]

[b]The Fitness Landscape: What Are We Optimizing?[/b]

**PSO searches a fitness landscape** - a function that assigns a score to each position.

**Goal:** Find position with **maximum fitness** (or minimum, depending on problem).

[color=yellow][b]Code: Fitness Function[/b][/color]
[code]
func fitness_function(pos: Vector2) -> float:
    var x = pos.x
    var y = pos.y

    # Example: Multi-modal landscape (multiple peaks)
    var peak1 = 3.0 * exp(-(x*x + y*y) / 8.0)  # Central peak
    var peak2 = 2.0 * exp(-((x-3)*(x-3) + (y-2)*(y-2)) / 4.0)  # Secondary peak
    var peak3 = 1.5 * exp(-((x+2)*(x+2) + (y+3)*(y+3)) / 6.0)  # Tertiary peak

    return peak1 + peak2 + peak3

# Fitness at a particle's position
var fitness = fitness_function(particle.position)
[/code]

**The landscape has:**
- **Local optima** (peaks that aren't the highest)
- **Global optimum** (highest peak)
- **Valleys** (low fitness regions)

**Particles explore this landscape together**, searching for the global optimum.

[hr]

[b]PSO Velocity Update: The Core Formula[/b]

**Every iteration, each particle updates its velocity based on three components:**

**v_new = w × v_old + c₁ × r₁ × (p_best - p_current) + c₂ × r₂ × (g_best - p_current)**

Where:
- **w** = inertia weight (momentum - keep moving in current direction)
- **c₁** = cognitive coefficient (trust personal experience)
- **c₂** = social coefficient (trust swarm knowledge)
- **r₁, r₂** = random values [0, 1] (stochastic exploration)
- **p_best** = particle's personal best position
- **g_best** = global best position (swarm's best)
- **p_current** = particle's current position

[color=yellow][b]Code: Velocity Update[/b][/color]
[code]
var inertia_weight = 0.7  # w
var cognitive_coefficient = 1.5  # c1
var social_coefficient = 1.5  # c2

func update_particle_velocity(particle: Particle):
    # Random factors
    var r1 = randf()
    var r2 = randf()

    # Cognitive component (personal experience)
    var cognitive = (particle.personal_best_position - particle.position) * cognitive_coefficient * r1

    # Social component (swarm knowledge)
    var social = (global_best_position - particle.position) * social_coefficient * r2

    # New velocity = inertia + cognitive + social
    particle.velocity = particle.velocity * inertia_weight + cognitive + social

    # Limit velocity (prevent explosion)
    var max_velocity = 2.0
    if particle.velocity.length() > max_velocity:
        particle.velocity = particle.velocity.normalized() * max_velocity
[/code]

**Three forces pull the particle:**
1. **Inertia** - keep going where I was going
2. **Cognitive** - go toward where I found my best
3. **Social** - go toward where the swarm found its best

[hr]

[b]Position Update: Move Through Space[/b]

**After updating velocity, update position:**

**p_new = p_old + v_new × Δt**

[color=yellow][b]Code: Position Update[/b][/color]
[code]
func update_particle_position(particle: Particle, delta: float):
    # Move particle according to velocity
    particle.position += particle.velocity * delta

    # Keep within bounds (optional)
    var bounds = 8.0
    particle.position.x = clamp(particle.position.x, -bounds, bounds)
    particle.position.y = clamp(particle.position.y, -bounds, bounds)

    # Evaluate fitness at new position
    var current_fitness = fitness_function(particle.position)

    # Update personal best if improved
    if current_fitness > particle.personal_best_fitness:
        particle.personal_best_fitness = current_fitness
        particle.personal_best_position = particle.position

    # Update global best if this is the best anyone's found
    if current_fitness > global_best_fitness:
        global_best_fitness = current_fitness
        global_best_position = particle.position
[/code]

**Each particle:**
1. **Moves** according to velocity
2. **Evaluates** fitness at new position
3. **Updates personal best** if improved
4. **Updates global best** if this is the swarm's best

[hr]

[b]The PSO Update Loop[/b]

**Every frame:**
1. For each particle:
   - Update velocity (inertia + cognitive + social)
   - Update position (move according to velocity)
   - Evaluate fitness
   - Update personal best
   - Update global best
2. Repeat until convergence (or max iterations)

[color=yellow][b]Code: Main Loop[/b][/color]
[code]
func _process(delta):
    for particle in particles:
        # Update velocity
        update_particle_velocity(particle)

        # Update position
        update_particle_position(particle, delta)

    # Optional: decrease inertia over time (exploration → exploitation)
    inertia_weight = max(0.4, inertia_weight - 0.001)
[/code]

**Early iterations:** High exploration (particles spread out)
**Later iterations:** High exploitation (particles converge on best regions)

[hr]

[b]Convergence: The Swarm Gathers[/b]

**PSO converges when:**
- **Particles cluster around global best** (social attraction dominates)
- **Velocities approach zero** (no more movement)
- **Fitness improvements plateau** (no better positions found)

**Typical convergence:**
1. **Exploration phase** - particles spread across landscape
2. **Regions of interest identified** - some particles find good fitness
3. **Social attraction** - other particles move toward good regions
4. **Convergence** - swarm clusters around global best

**The swarm self-organizes** - no central control, just local rules + social awareness.

[hr]

[b]Parameters and Behavior[/b]

**Inertia weight (w):**
- **High (0.9)** - more exploration (particles keep momentum, spread out)
- **Low (0.4)** - more exploitation (particles slow down, converge)
- **Adaptive** - start high, decrease over time (explore → exploit)

**Cognitive coefficient (c₁):**
- **High** - trust personal experience (individualistic)
- **Low** - ignore personal history (social conformity)

**Social coefficient (c₂):**
- **High** - trust swarm knowledge (collectivist)
- **Low** - ignore global best (independent exploration)

**Typical values:**
- w = 0.7 (or decreasing 0.9 → 0.4)
- c₁ = c₂ = 1.5 (balanced cognitive + social)

**Trade-offs:**
- **c₁ > c₂** - individualistic swarm (trust self over group)
- **c₂ > c₁** - collectivist swarm (trust group over self)
- **c₁ = c₂** - balanced (personal + social equally weighted)

[hr]

[b]Topology: Who Influences Whom?[/b]

**Standard PSO:** All particles aware of global best (fully connected).

**Variants use different topologies:**

**Global topology (gbest):**
- All particles know global best
- Fast convergence, risk of premature convergence

**Local topology (lbest):**
- Each particle only knows neighbors' best
- Slower convergence, better exploration

**Ring topology:**
[code]
# Each particle knows left and right neighbors
func get_neighborhood_best(particle_index: int) -> Vector2:
    var left = particles[(particle_index - 1) % particles.size()]
    var right = particles[(particle_index + 1) % particles.size()]
    var self = particles[particle_index]

    var best_pos = self.personal_best_position
    var best_fitness = self.personal_best_fitness

    if left.personal_best_fitness > best_fitness:
        best_fitness = left.personal_best_fitness
        best_pos = left.personal_best_position

    if right.personal_best_fitness > best_fitness:
        best_fitness = right.personal_best_fitness
        best_pos = right.personal_best_position

    return best_pos
[/code]

**Star topology:**
- One central "informer" particle
- Others know only their own best + informer's best

**Topology affects:**
- **Convergence speed** (more connections = faster)
- **Diversity** (fewer connections = more exploration)
- **Robustness** (local topologies avoid premature convergence)

[hr]

[b]Applications: Where PSO is Used[/b]

**1. Function Optimization**
- Find minimum/maximum of mathematical functions
- Benchmark: Rastrigin, Rosenbrock, Ackley functions

**2. Neural Network Training**
- Optimize network weights
- Alternative to gradient descent (gradient-free)

**3. Engineering Design**
- Antenna design (optimize shape for signal)
- Structure optimization (minimize weight, maximize strength)

**4. Scheduling and Planning**
- Resource allocation
- Job shop scheduling

**5. Image Processing**
- Image segmentation (find optimal thresholds)
- Feature selection

**6. Game AI**
- Evolve agent behaviors
- Optimize game parameters

[hr]

[b]PSO vs Other Optimization[/b]

**PSO vs Gradient Descent:**
- **Gradient descent:** Uses derivatives (local info), fast, finds local optimum
- **PSO:** Gradient-free (global search), slower, can escape local optima

**PSO vs Genetic Algorithms:**
- **GA:** Selection, crossover, mutation (evolution metaphor)
- **PSO:** Velocity updates, social learning (swarm metaphor)
- **PSO:** Often faster convergence, simpler implementation

**PSO vs ACO:**
- **ACO:** Stigmergy (environmental communication), discrete paths
- **PSO:** Direct social communication, continuous spaces

[hr]

[b]Variants: PSO Flavors[/b]

**Constriction PSO:**
[code]
# Add constriction factor χ to prevent explosion
var chi = 0.7298  # Constriction coefficient
particle.velocity = chi * (particle.velocity * w + cognitive + social)
[/code]

**Binary PSO:**
[code]
# For discrete optimization (0/1 decisions)
func sigmoid(x: float) -> float:
    return 1.0 / (1.0 + exp(-x))

# Position is probability, threshold to get binary value
if randf() < sigmoid(particle.velocity.x):
    particle.position.x = 1
else:
    particle.position.x = 0
[/code]

**Multi-Objective PSO:**
- Optimize multiple conflicting objectives
- Pareto front (trade-off curves)

**Adaptive PSO:**
- Parameters (w, c₁, c₂) change dynamically based on swarm state
- Increase exploration when stuck, increase exploitation when improving

[hr]

[b]Queer Particle Swarm: Balancing Self and Collective[/b]

Here is where queerness enters:

**1. Cognitive vs Social: Individual History vs Collective Knowledge**

**The PSO formula explicitly balances:**
- **c₁** (cognitive) - trust MY experience
- **c₂** (social) - trust SWARM'S experience

**This is the queer negotiation:**
- **Personal history** (my own path, my own discoveries)
- **Community knowledge** (what others have learned, collective wisdom)

**Queerness requires both:**
- **Ignore personal experience → assimilation** (erase individual difference for group conformity)
- **Ignore social knowledge → isolation** (refuse community, reinvent every wheel alone)

**PSO models the balance:** c₁ = c₂ (neither dominates).

**Queer identity is PSO velocity** - pulled by personal best (who I've been) and global best (who the community suggests I could be).

**2. Inertia: Momentum and Change**

**Inertia (w) is resistance to change** - particles keep moving in current direction.

**High inertia → exploration** (hard to deflect, keep searching)
**Low inertia → exploitation** (easy to redirect toward known good positions)

**Queerness requires adaptive inertia:**
- **Coming out:** Low inertia (rapid change, new trajectory)
- **Established identity:** High inertia (momentum, continuity)
- **Community pressure:** Decreasing inertia (slowly converging toward norms)

**PSO often decreases inertia over time** (0.9 → 0.4) - early freedom to explore, later pressure to converge.

**This is queer life:** Early exploration, later pressure toward stable identity (respectability, legibility).

**3. Topology as Social Network**

**Who influences you?**
- **Global topology:** Everyone knows everyone's best (panopticon, total visibility)
- **Local topology:** Only neighbors influence (intimate networks, local knowledge)

**Queerness in local topologies:**
- We are influenced by **nearby** queers (geographic, social, cultural proximity)
- Not by abstract "global queer community" (which doesn't exist as singular entity)

**Local topology resists premature convergence** - allows diverse sub-communities to explore different regions.

**Global topology enforces conformity** - all particles pulled toward single global best.

**Queer communities need local topology** - neighborhood clusters, not totalizing consensus.

**4. Personal Best: Non-Linear Time**

**Particles remember their personal best** - not just current state, but **history**.

**This is queer temporality** - we are shaped by where we've been, not just where we are.

**The cognitive component pulls us BACKWARD** - toward our own past (personal_best_position).

**This is not regressive** - it is **memory as resource**.

**Queerness remembers its history** (Stonewall, ACT UP, ballroom culture) and uses it to navigate present.

**Personal best is the archive** - collective and individual history as guide.

**5. Convergence as Assimilation Pressure**

**PSO converges** - particles cluster around global best.

**This is the pressure of normalization:**
- **Early:** High diversity (particles spread across landscape)
- **Later:** Low diversity (all particles near same position)

**Convergence is efficient** (finds optimum) but **erases diversity** (all particles end up at same place).

**Queer communities resist convergence:**
- **Assimilation:** All queers converge toward homonormativity (marriage, monogamy, respectability)
- **Radicality:** Maintain diversity (polyamory, gender non-conformity, anti-assimilationism)

**PSO with high inertia or local topology resists premature convergence** - maintains exploration.

**Queerness needs sustained inertia** - resist the pull toward single "best" way to be queer.

**6. Fitness Landscape: Who Defines "Best"?**

**PSO searches for global best on fitness landscape.**

**But who defined the landscape?**

**Fitness is not objective** - it is **constructed** (by programmer, by society, by norms).

**Queerness asks:** What if the "fitness function" is heteronormative?

**Example fitness function:** Maximize social acceptance + legal recognition + economic stability

**This function's global optimum:** Homonormative gay marriage.

**But what if we change the function?**

**Queer fitness function:** Maximize freedom + community support + pleasure + resistance to capitalism

**Different landscape → different optimum.**

**PSO optimizes whatever landscape you give it** - it cannot question whether the landscape is just.

**Queerness must question the fitness function itself.**

[hr]

[b]What PSO Cannot Do[/b]

PSO is powerful but limited:

**1. No gradient information**
Doesn't use derivatives - slower than gradient descent for smooth functions.

**2. Parameter sensitivity**
Performance depends on w, c₁, c₂ - requires tuning.

**3. Premature convergence**
Can get stuck in local optima, especially with global topology.

**4. High-dimensional spaces**
Performance degrades in very high dimensions (curse of dimensionality).

**5. Discrete optimization**
Designed for continuous spaces - adaptations for discrete/binary needed.

[hr]

[b]What PSO Reveals[/b]

PSO shows us:

1. **Social learning** (particles influenced by swarm knowledge)
2. **Velocity updates** (v = w×v + c₁×r₁×(p_best - p) + c₂×r₂×(g_best - p))
3. **Cognitive component** (trust personal experience)
4. **Social component** (trust swarm's best)
5. **Inertia** (momentum, resistance to change)
6. **Convergence** (swarm clusters around optimum)
7. **Topology** (global vs local influence networks)
8. **Parameters** (w, c₁, c₂ tune exploration/exploitation)
9. **Applications** (optimization, neural nets, engineering design)
10. **Variants** (constriction, binary, multi-objective, adaptive)

**PSO is the algorithm of collective search** - social learning, velocity, balance.

**It is also the algorithm of queer identity negotiation:**
- **Cognitive vs social** (personal history vs collective knowledge)
- **Inertia as momentum** (resistance to change, need for adaptive identity)
- **Topology as network** (local communities vs global panopticon)
- **Personal best as archive** (memory as resource, non-linear time)
- **Convergence as assimilation** (pressure toward single norm)
- **Fitness landscape as constructed** (who defines "best"?)

**PSO proves:** **Identity is velocity - shaped by personal history (cognitive) and social influence (social), moving through landscapes we did not choose, balancing exploration and convergence, questioning what counts as optimal.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Particle Swarm Optimization searches fitness landscapes through social learning. Velocity update: v = w×v + c₁×r₁×(p_best - p) + c₂×r₂×(g_best - p). Three components: inertia (momentum), cognitive (personal experience), social (swarm knowledge). Particles remember personal best, aware of global best. Convergence: swarm clusters around optimum. Parameters: w (inertia), c₁ (cognitive), c₂ (social). Topology: global (all aware) vs local (neighbors only). Applications: function optimization, neural nets, engineering. Queer PSO: cognitive/social balance (personal vs collective), inertia as momentum (adaptive identity), topology as network (local communities), personal best as archive, convergence as assimilation pressure, fitness landscape as constructed (who defines "best"?). Identity is velocity through contested terrain.

'''
