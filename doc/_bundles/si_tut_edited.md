<<<ADA_BUNDLE>>>
sequence: swarmintelligence
file: tutorial.md
maps: 8
skipped_passing: 0
created: 2026-04-24T05:05:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: SwarmIntelligence_PhysarumColony>>>
# Physarum Colony

Slime mould finds shortest paths. Deposits chemical trails.

Build a scalar trail field.

```gdscript
@export var grid_size: Vector2i = Vector2i(256, 256)
var trail: Array = []

func initialise_trail() -> void:
    trail.clear()
    for y in grid_size.y:
        var row: Array = []
        for x in grid_size.x:
            row.append(0.0)
        trail.append(row)
```

A 2D scalar field. Each cell stores the local trail intensity.

Spawn physarum agents.

```gdscript
class_name PhysarumAgent

var position: Vector2
var direction: float  # radians

func random_agent(bounds: Vector2) -> PhysarumAgent:
    var a := PhysarumAgent.new()
    a.position = Vector2(randf() * bounds.x, randf() * bounds.y)
    a.direction = randf() * TAU
    return a
```

Each agent has position and heading. Thousands cover the grid.

Sense the trail ahead.

```gdscript
@export var sensor_angle: float = 0.5  # radians
@export var sensor_distance: float = 5.0

func sense(agent: PhysarumAgent) -> float:
    var sensor_pos := agent.position + Vector2(cos(agent.direction), sin(agent.direction)) * sensor_distance
    var x: int = clamp(int(sensor_pos.x), 0, grid_size.x - 1)
    var y: int = clamp(int(sensor_pos.y), 0, grid_size.y - 1)
    return trail[y][x]
```

Sample the trail at a point ahead of the agent. Three sensors (left, centre, right) let the agent turn toward the strongest trail.

Move toward the strongest sensor.

```gdscript
func turn_toward_trail(agent: PhysarumAgent) -> void:
    var forward := sense(agent)
    var left := sense_with_offset(agent, -sensor_angle)
    var right := sense_with_offset(agent, sensor_angle)
    if left > forward and left > right:
        agent.direction -= sensor_angle * 0.5
    elif right > forward and right > left:
        agent.direction += sensor_angle * 0.5
```

Three sensors; turn toward the strongest. Stays straight when forward is strongest.

Deposit trail.

```gdscript
@export var deposit_amount: float = 0.1

func deposit(agent: PhysarumAgent) -> void:
    var x: int = clamp(int(agent.position.x), 0, grid_size.x - 1)
    var y: int = clamp(int(agent.position.y), 0, grid_size.y - 1)
    trail[y][x] += deposit_amount
```

Every step adds to the trail. Repeated visits reinforce the path.

Diffuse the trail.

```gdscript
@export var diffusion_rate: float = 0.1
@export var decay_rate: float = 0.02

func diffuse_trail() -> void:
    var new_trail: Array = []
    for y in grid_size.y:
        var row: Array = []
        for x in grid_size.x:
            var sum: float = 0.0
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    sum += trail[(y + dy + grid_size.y) % grid_size.y][(x + dx + grid_size.x) % grid_size.x]
            var avg: float = sum / 9.0
            var blended: float = trail[y][x] * (1 - diffusion_rate) + avg * diffusion_rate
            row.append(blended * (1 - decay_rate))
        new_trail.append(row)
    trail = new_trail
```

Gaussian-like blur followed by exponential decay. Diffusion spreads the trail; decay erases it.

Full simulation loop.

```gdscript
func _physics_process(_delta: float) -> void:
    for agent in agents:
        turn_toward_trail(agent)
        agent.position += Vector2(cos(agent.direction), sin(agent.direction)) * 1.0
        deposit(agent)
    diffuse_trail()
```

Turn, move, deposit, diffuse. Over many frames, stable paths emerge between food sources.

You can now build a physarum colony with sensory agents, a scalar trail field, and diffusion-decay dynamics. SwarmIntelligence_FlowFields extends into pre-computed navigation fields.

<<<MAP: SwarmIntelligence_FlowFields>>>
# Flow Fields

Precompute directions across a grid. Agents follow the field.

Build a 2D vector field.

```gdscript
@export var grid_size: Vector2i = Vector2i(32, 32)
var field: Array = []  # 2D array of Vector2

func initialise_field() -> void:
    for y in grid_size.y:
        field.append([])
        for x in grid_size.x:
            field[y].append(Vector2.ZERO)
```

Each cell stores a direction. Agents sample the field at their position.

Compute a radial field.

```gdscript
func compute_radial_field(centre: Vector2i) -> void:
    for y in grid_size.y:
        for x in grid_size.x:
            var direction: Vector2 = Vector2(centre.x - x, centre.y - y)
            if direction.length() > 0:
                field[y][x] = direction.normalized()
```

Every cell points toward the centre. Agents released into this field converge.

Compute a Dijkstra field.

```gdscript
func compute_dijkstra_field(goal: Vector2i, is_passable: Callable) -> void:
    var distance: Array = []
    for y in grid_size.y:
        distance.append([])
        for x in grid_size.x:
            distance[y].append(INF)
    distance[goal.y][goal.x] = 0
    var queue: Array = [goal]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        for neighbour in get_neighbours(current):
            if not is_passable.call(neighbour): continue
            var new_dist: float = distance[current.y][current.x] + 1
            if new_dist < distance[neighbour.y][neighbour.x]:
                distance[neighbour.y][neighbour.x] = new_dist
                queue.push_back(neighbour)
    for y in grid_size.y:
        for x in grid_size.x:
            field[y][x] = steepest_descent(x, y, distance)
```

BFS-based. The field points agents toward the nearest goal along the shortest walkable path.

Find steepest descent.

```gdscript
func steepest_descent(x: int, y: int, distance: Array) -> Vector2:
    var best := Vector2.ZERO
    var best_dist: float = distance[y][x]
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dx == 0 and dy == 0: continue
            var nx: int = x + dx; var ny: int = y + dy
            if nx < 0 or nx >= grid_size.x or ny < 0 or ny >= grid_size.y: continue
            if distance[ny][nx] < best_dist:
                best_dist = distance[ny][nx]; best = Vector2(dx, dy)
    return best.normalized()
```

Search neighbours for the cell with lowest distance. Field direction points there.

Sample the field for an agent.

```gdscript
func sample_field(position: Vector2) -> Vector2:
    var x: int = clamp(int(position.x), 0, grid_size.x - 1)
    var y: int = clamp(int(position.y), 0, grid_size.y - 1)
    return field[y][x]
```

Direct cell lookup. For smoother motion, bilinear interpolation between four corners.

Agents follow the field.

```gdscript
func _physics_process(delta: float) -> void:
    for agent in agents:
        var force: Vector2 = sample_field(agent.position) * 2.0
        agent.velocity += force * delta
        agent.velocity = agent.velocity.limit_length(3.0)
        agent.position += agent.velocity * delta
```

Apply field force; cap velocity; move. The agent traces a path along the field.

You can now build a 2D flow field, compute radial and Dijkstra variants, and steer agents through it. SwarmIntelligence_Boids_Algorithm extends into reynolds flocking.

<<<MAP: SwarmIntelligence_Boids_Algorithm>>>
# Boids Algorithm

Reynolds' three rules. Separation, alignment, cohesion.

Define a boid.

```gdscript
class_name Boid

var position: Vector3
var velocity: Vector3

func random_boid(bounds: AABB, max_speed: float) -> Boid:
    var b := Boid.new()
    b.position = Vector3(
        randf_range(bounds.position.x, bounds.end.x),
        randf_range(bounds.position.y, bounds.end.y),
        randf_range(bounds.position.z, bounds.end.z)
    )
    b.velocity = Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized() * max_speed
    return b
```

Position and velocity. No acceleration — the steering forces drive the velocity directly.

Compute separation.

```gdscript
@export var separation_radius: float = 1.0

func separation(self_boid: Boid, flock: Array) -> Vector3:
    var steer := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        var distance: float = self_boid.position.distance_to(other.position)
        if distance < separation_radius and distance > 0:
            var away: Vector3 = (self_boid.position - other.position).normalized() / distance
            steer += away
            count += 1
    if count > 0: steer /= count
    return steer
```

Push away from close neighbours. Weighted by inverse distance — closer neighbours repel harder.

Compute alignment.

```gdscript
@export var perception_radius: float = 3.0

func alignment(self_boid: Boid, flock: Array) -> Vector3:
    var avg_velocity := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        if self_boid.position.distance_to(other.position) < perception_radius:
            avg_velocity += other.velocity
            count += 1
    if count == 0: return Vector3.ZERO
    return (avg_velocity / count - self_boid.velocity).normalized()
```

Match the average velocity of nearby boids. The boid turns toward the flock's shared direction.

Compute cohesion.

```gdscript
func cohesion(self_boid: Boid, flock: Array) -> Vector3:
    var centre := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        if self_boid.position.distance_to(other.position) < perception_radius:
            centre += other.position
            count += 1
    if count == 0: return Vector3.ZERO
    return ((centre / count) - self_boid.position).normalized()
```

Move toward the centre of nearby boids. The flock stays together.

Combine the three forces.

```gdscript
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0

func compute_steering(self_boid: Boid, flock: Array) -> Vector3:
    return (
        separation(self_boid, flock) * separation_weight +
        alignment(self_boid, flock) * alignment_weight +
        cohesion(self_boid, flock) * cohesion_weight
    )
```

Three rules, three weights. Tuning the weights changes the flock's character.

Update all boids.

```gdscript
@export var max_speed: float = 4.0

func _physics_process(delta: float) -> void:
    for boid in flock:
        var steering: Vector3 = compute_steering(boid, flock)
        boid.velocity += steering * delta
        boid.velocity = boid.velocity.limit_length(max_speed)
        boid.position += boid.velocity * delta
```

Each boid computes its steering independently. O(N²) for a naive implementation; spatial partitioning reduces this.

You can now build boids, compute Reynolds' three rules, combine them with weights, and update the flock. SwarmIntelligence_Agent_Based_Modeling_ABM extends into stateful agents.

<<<MAP: SwarmIntelligence_Agent_Based_Modeling_ABM>>>
# Agent Based Modeling

Stateful agents with perception radius. Each acts on local information.

Define a stateful agent.

```gdscript
class_name ABMAgent extends CharacterBody3D

@export var perception_radius: float = 3.0
@export var max_speed: float = 2.0

enum State { FORAGING, FOLLOWING, RESTING }
var current_state: int = State.FORAGING
```

State machine. The state determines behaviour; transitions happen based on perception.

Perceive neighbours.

```gdscript
func perceive() -> Array:
    var neighbours: Array = []
    for other in get_tree().get_nodes_in_group("abm_agents"):
        if other == self: continue
        if global_position.distance_to(other.global_position) < perception_radius:
            neighbours.append(other)
    return neighbours
```

Local view. Agents don't know about other agents outside the radius.

State transitions.

```gdscript
func update_state(neighbours: Array) -> void:
    var nearby_states: Dictionary = {}
    for n in neighbours:
        nearby_states[n.current_state] = nearby_states.get(n.current_state, 0) + 1
    var dominant: int = dominant_state(nearby_states)
    if nearby_states.get(dominant, 0) > 3:
        current_state = dominant  # copy the local majority
```

Copy the majority. Social conformity at the local scale; polarisation at the global scale.

Behaviour by state.

```gdscript
func _physics_process(delta: float) -> void:
    var neighbours := perceive()
    update_state(neighbours)
    match current_state:
        State.FORAGING: forage(delta)
        State.FOLLOWING: follow(neighbours, delta)
        State.RESTING: rest(delta)
    move_and_slide()
```

Different behaviours per state. The state machine drives the agent's action.

Foraging: random walk.

```gdscript
func forage(delta: float) -> void:
    if randf() < 0.1:
        var new_direction := Vector3(randfn(0, 1), 0, randfn(0, 1)).normalized()
        velocity = new_direction * max_speed
```

Random direction changes every few frames. The agent wanders.

Following: move toward neighbours' centroid.

```gdscript
func follow(neighbours: Array, delta: float) -> void:
    if neighbours.is_empty(): return
    var centroid := Vector3.ZERO
    for n in neighbours:
        centroid += n.global_position
    centroid /= neighbours.size()
    var direction: Vector3 = (centroid - global_position).normalized()
    velocity = direction * max_speed
```

Head toward where the crowd is. Produces clumping.

Resting: stay still.

```gdscript
func rest(delta: float) -> void:
    velocity = Vector3.ZERO
    if randf() < 0.005:  # occasionally wake up
        current_state = State.FORAGING
```

Zero velocity. Low wake probability means rest is the default stable state once entered.

Count agents by state.

```gdscript
func population_by_state() -> Dictionary:
    var counts: Dictionary = {}
    for agent in get_tree().get_nodes_in_group("abm_agents"):
        counts[agent.current_state] = counts.get(agent.current_state, 0) + 1
    return counts
```

Global statistics. Tracks the population's state distribution over time.

You can now build stateful ABM agents with perception, majority-based state transitions, per-state behaviours, and global state statistics. SwarmIntelligence_Ant_Colony_Optimization extends into path-finding via pheromones.

<<<MAP: SwarmIntelligence_Ant_Colony_Optimization>>>
# Ant Colony Optimization

Ants find shortest paths. Pheromones mark good routes.

Define a pheromone graph.

```gdscript
class_name ACOGraph

var vertices: Array = []
var distance: Dictionary = {}      # [u, v] -> distance
var pheromone: Dictionary = {}     # [u, v] -> pheromone amount

func add_edge(u, v, d: float) -> void:
    distance[[u, v]] = d
    distance[[v, u]] = d
    pheromone[[u, v]] = 1.0
    pheromone[[v, u]] = 1.0
    if not u in vertices: vertices.append(u)
    if not v in vertices: vertices.append(v)
```

Bidirectional edges with distance and initial pheromone. The pheromone is mutable.

Probability of picking an edge.

```gdscript
@export var alpha: float = 1.0  # pheromone weight
@export var beta: float = 2.0   # distance weight

func edge_probability(u, v, visited: Array) -> float:
    if v in visited: return 0.0
    var tau: float = pheromone.get([u, v], 0.1) ** alpha
    var eta: float = pow(1.0 / distance[[u, v]], beta)
    return tau * eta
```

Higher pheromone + shorter distance → higher probability. Alpha and beta tune the balance.

Choose the next vertex.

```gdscript
func choose_next(current, visited: Array, graph: ACOGraph) -> Variant:
    var probabilities: Dictionary = {}
    var total: float = 0.0
    for v in graph.vertices:
        if v == current or v in visited: continue
        var p: float = graph.edge_probability(current, v, visited)
        probabilities[v] = p
        total += p
    if total == 0.0: return null
    var r: float = randf() * total
    var cumulative: float = 0.0
    for v in probabilities:
        cumulative += probabilities[v]
        if r < cumulative: return v
    return null
```

Roulette-wheel selection. Higher-probability edges are chosen more often.

One ant builds a tour.

```gdscript
func build_tour(start, graph: ACOGraph) -> Array:
    var tour: Array = [start]
    var current = start
    while tour.size() < graph.vertices.size():
        var next = choose_next(current, tour, graph)
        if next == null: break
        tour.append(next)
        current = next
    if tour.size() == graph.vertices.size():
        tour.append(start)  # return home
    return tour
```

Greedy construction guided by probabilities. Ants don't backtrack.

Deposit pheromone.

```gdscript
@export var pheromone_deposit: float = 1.0

func deposit_on_tour(tour: Array, graph: ACOGraph) -> void:
    var total_distance: float = 0.0
    for i in range(tour.size() - 1):
        total_distance += graph.distance[[tour[i], tour[i + 1]]]
    var amount: float = pheromone_deposit / total_distance
    for i in range(tour.size() - 1):
        graph.pheromone[[tour[i], tour[i + 1]]] += amount
        graph.pheromone[[tour[i + 1], tour[i]]] += amount
```

Shorter tours deposit more pheromone. Good paths reinforce themselves.

Evaporate pheromone.

```gdscript
@export var evaporation_rate: float = 0.1

func evaporate(graph: ACOGraph) -> void:
    for edge in graph.pheromone:
        graph.pheromone[edge] *= (1.0 - evaporation_rate)
```

Reduces all pheromones each iteration. Prevents early paths from dominating forever.

Run one iteration.

```gdscript
func iteration(graph: ACOGraph, ant_count: int) -> Array:
    var best_tour: Array = []
    var best_length: float = INF
    for _i in ant_count:
        var tour: Array = build_tour(graph.vertices[0], graph)
        if tour.size() == graph.vertices.size() + 1:
            deposit_on_tour(tour, graph)
            var length: float = tour_length(tour, graph)
            if length < best_length:
                best_length = length; best_tour = tour
    evaporate(graph)
    return best_tour
```

Each iteration: all ants build tours; deposit pheromones; evaporate. Over iterations, the best tour emerges.

You can now build an ACO graph, compute edge probabilities, construct tours, deposit and evaporate pheromones, and iterate the algorithm toward shortest paths. SwarmIntelligence_Particle_Swarm_Optimization extends to continuous optimisation.

<<<MAP: SwarmIntelligence_Particle_Swarm_Optimization>>>
# Particle Swarm Optimization

Particles search the space. Each remembers its best; all share the global best.

Define a particle.

```gdscript
class_name PSOParticle

var position: Vector2
var velocity: Vector2
var personal_best_position: Vector2
var personal_best_score: float = INF
```

Position, velocity, and personal best tracked. Each particle is self-contained.

Initialise a swarm.

```gdscript
func initialise_swarm(count: int, bounds: Rect2) -> Array:
    var swarm: Array = []
    for _i in count:
        var p := PSOParticle.new()
        p.position = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
        p.velocity = Vector2(randfn(0, 1), randfn(0, 1))
        p.personal_best_position = p.position
        swarm.append(p)
    return swarm
```

Random initial positions and velocities. Covers the search space broadly.

Evaluate the fitness function.

```gdscript
func rastrigin(p: Vector2) -> float:
    var A: float = 10.0
    var n: int = 2
    return A * n + (p.x * p.x - A * cos(2.0 * PI * p.x)) + (p.y * p.y - A * cos(2.0 * PI * p.y))
```

Rastrigin has many local minima and one global minimum at the origin. Standard test function.

Update velocity.

```gdscript
@export var inertia: float = 0.7
@export var cognitive: float = 1.5
@export var social: float = 1.5

func update_velocity(particle: PSOParticle, global_best: Vector2) -> void:
    var r1: float = randf()
    var r2: float = randf()
    particle.velocity = (
        particle.velocity * inertia +
        (particle.personal_best_position - particle.position) * cognitive * r1 +
        (global_best - particle.position) * social * r2
    )
    particle.velocity = particle.velocity.limit_length(5.0)
```

Three contributions: inertia (keep going), cognitive (toward personal best), social (toward global best). Random factors add exploration.

Update position.

```gdscript
func update_position(particle: PSOParticle) -> void:
    particle.position += particle.velocity
```

Simple Euler step. The particle moves according to its new velocity.

Update bests.

```gdscript
var global_best_position: Vector2
var global_best_score: float = INF

func update_bests(particle: PSOParticle) -> void:
    var score: float = rastrigin(particle.position)
    if score < particle.personal_best_score:
        particle.personal_best_score = score
        particle.personal_best_position = particle.position
    if score < global_best_score:
        global_best_score = score
        global_best_position = particle.position
```

Check current position against personal and global bests. Update if improved.

Run one iteration.

```gdscript
func iteration(swarm: Array) -> void:
    for particle in swarm:
        update_velocity(particle, global_best_position)
        update_position(particle)
        update_bests(particle)
```

One update per particle. Over many iterations, the swarm converges on the global minimum.

You can now initialise a swarm, evaluate fitness via Rastrigin, update velocities with inertia/cognitive/social terms, and track personal and global bests. SwarmIntelligence_Swarm_Intelligence_Algorithms extends into a gallery of algorithms.

<<<MAP: SwarmIntelligence_Swarm_Intelligence_Algorithms>>>
# Swarm Intelligence Algorithms

A gallery of swarm methods. Common agent interface.

Define the common interface.

```gdscript
class_name SwarmAlgorithm

func initialize(agent) -> void: pass
func perceive(agent, environment) -> Dictionary: return {}
func decide(agent, perceptions: Dictionary) -> Dictionary: return {}
func act(agent, decision: Dictionary) -> void: pass
func update_environment(environment, agent, action) -> void: pass
```

Five-phase agent loop. Each algorithm overrides these hooks.

Physarum algorithm.

```gdscript
class_name PhysarumAlgorithm extends SwarmAlgorithm

func perceive(agent, env) -> Dictionary:
    return {
        "trail_forward": env.sample_trail(agent.position + agent.forward()),
        "trail_left": env.sample_trail(agent.position + agent.left()),
        "trail_right": env.sample_trail(agent.position + agent.right()),
    }

func decide(agent, perceptions: Dictionary) -> Dictionary:
    if perceptions.trail_left > perceptions.trail_forward:
        return {"turn": -1}
    elif perceptions.trail_right > perceptions.trail_forward:
        return {"turn": 1}
    return {"turn": 0}

func act(agent, decision: Dictionary) -> void:
    agent.rotate(decision.turn * 0.1)
    agent.move_forward(1.0)

func update_environment(env, agent, action) -> void:
    env.deposit_trail_at(agent.position, 0.1)
```

Trail sensing and deposition. The agent navigates by gradients in the environment.

Boids algorithm.

```gdscript
class_name BoidsAlgorithm extends SwarmAlgorithm

func perceive(agent, env) -> Dictionary:
    return {"neighbours": env.neighbours_of(agent, 3.0)}

func decide(agent, perceptions: Dictionary) -> Dictionary:
    var sep := separation(agent, perceptions.neighbours)
    var ali := alignment(agent, perceptions.neighbours)
    var coh := cohesion(agent, perceptions.neighbours)
    return {"steering": sep * 1.5 + ali + coh}
```

Perception is local neighbours; decision is Reynolds' three rules combined.

Stack algorithms.

```gdscript
class_name LayeredSwarm

var algorithms: Array = []

func run_frame(agents: Array, environment):
    for agent in agents:
        for algo in algorithms:
            algo.initialize(agent)
            var perceptions: Dictionary = algo.perceive(agent, environment)
            var decision: Dictionary = algo.decide(agent, perceptions)
            algo.act(agent, decision)
            algo.update_environment(environment, agent, decision)
```

Multiple algorithms applied in sequence. Each layer adds behaviour.

Compare algorithms.

```gdscript
func run_comparison(algorithms: Array, env, duration: float) -> Dictionary:
    var results: Dictionary = {}
    for algo in algorithms:
        var agents := spawn_agents(30)
        for algo_instance in algorithms:
            pass  # setup
        await get_tree().create_timer(duration).timeout
        results[algo.get_name()] = measure_performance(agents, env)
    return results
```

Run each algorithm on the same environment. Compare metrics like coverage, convergence, trail density.

Visualise the gallery.

```gdscript
func populate_gallery(algorithms: Array) -> void:
    for i in algorithms.size():
        var position := Vector3(i * 4, 0, 0)
        var ghost_env := create_gallery_zone(position)
        var ghost_agents := spawn_agents_in(ghost_env, 20)
        ghost_env.run_algorithm(algorithms[i])
```

Each algorithm gets its own zone in the gallery. Visitors see them side by side.

You can now define a common agent interface, implement physarum and boids variants, stack algorithm layers, compare performance, and populate a gallery. Chamber_Swarm closes the sequence with swarm-on-swarm encounter.

<<<MAP: Chamber_Swarm>>>
# Chamber Swarm

Two flocks in one volume. Reynolds rules on both sides.

Build the swarm catalyst.

```gdscript
class_name SwarmCatalyst extends Node3D

@export var boid_count: int = 8

func fire(aim: Vector3) -> Array:
    var boids: Array = []
    for _i in boid_count:
        var boid := BoidProjectile.new()
        boid.global_position = global_position + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
        boid.velocity = aim * 8.0 + Vector3(randfn(0, 0.5), randfn(0, 0.5), randfn(0, 0.5))
        get_tree().root.add_child(boid)
        boids.append(boid)
    return boids
```

Each catalyst shot spawns eight boids. They follow each other via local Reynolds rules.

Build the swarm hive creature.

```gdscript
class_name SwarmHive extends CharacterBody3D

@export var hive_size: int = 20
var hive_boids: Array = []

func _ready() -> void:
    for _i in hive_size:
        var boid := BoidHiveMember.new()
        boid.global_position = global_position + Vector3(randfn(0, 0.5), randfn(0, 0.5), randfn(0, 0.5))
        boid.velocity = Vector3.ZERO
        add_child(boid)
        hive_boids.append(boid)
```

Twenty boids around the hive. Their collective centroid is the hive's body.

Run Reynolds rules for both flocks.

```gdscript
func _physics_process(delta: float) -> void:
    for boid in get_tree().get_nodes_in_group("boid_projectile"):
        apply_reynolds(boid, get_nearby_boids(boid, 2.0))
    for boid in hive_boids:
        apply_reynolds(boid, get_nearby_boids(boid, 2.0))
```

Both flocks use the same physics. Different parameter sets give each its character.

Detect flock interaction.

```gdscript
func get_nearby_boids(self_boid: Node3D, radius: float) -> Array:
    var nearby: Array = []
    for other in get_tree().get_nodes_in_group("all_boids"):
        if other == self_boid: continue
        if self_boid.global_position.distance_to(other.global_position) < radius:
            nearby.append(other)
    return nearby
```

Cross-flock awareness. Each boid sees any boid within radius, regardless of flock.

Apply Reynolds.

```gdscript
func apply_reynolds(boid: Node3D, neighbours: Array) -> void:
    if neighbours.is_empty(): return
    var sep := compute_separation(boid, neighbours)
    var ali := compute_alignment(boid, neighbours)
    var coh := compute_cohesion(boid, neighbours)
    boid.velocity += (sep * 1.5 + ali + coh) * 0.1
    boid.velocity = boid.velocity.limit_length(5.0)
```

Standard Reynolds' three rules. Weights tuned for visible behaviour.

Log alignment.

```gdscript
func alignment_score() -> float:
    var alignment_vector := Vector3.ZERO
    for boid in get_tree().get_nodes_in_group("all_boids"):
        alignment_vector += boid.velocity.normalized()
    var total_count: int = get_tree().get_nodes_in_group("all_boids").size()
    return alignment_vector.length() / total_count
```

Sum of unit velocity vectors. Near 1.0 means everyone's aligned; near 0.0 means random directions.

Detect a witness miura.

```gdscript
func spawn_miura_witness() -> void:
    var miura := preload("res://commons/transformation/miura_crawler.tscn").instantiate()
    miura.position = Vector3(3, 0, -4)
    miura.set_curious_posture(true)
    add_child(miura)
```

The befriended miura from an earlier chamber appears. It watches the two flocks without joining either.

You can now build the swarm catalyst, spawn a swarm hive, run Reynolds rules across both flocks, detect cross-flock neighbours, log alignment, and spawn a miura witness. The Swarm Intelligence sequence closes with two self-organising systems in contact.
