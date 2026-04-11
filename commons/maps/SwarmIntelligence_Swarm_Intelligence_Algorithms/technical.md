# Nature solved optimization before we did — a gallery of swarm algorithms side by side, each a different answer to the same question

Six maps. Six mechanisms. Physarum's stigmergic trail networks. Flow fields' pre-built vector navigation. Boids' three-rule flocking. ABM's general agent framework. Ant colony's pheromone-guided graph optimization. Particle swarm's socially-informed landscape search. Each map demonstrated one approach to the same problem: how do simple agents produce intelligent collective behavior without centralized control?

This gallery places them side by side. The `SwarmShowcase` artifact implements multiple swarm algorithms within a unified visualization framework, allowing direct comparison. Each algorithm runs in its own alcove, but the spatial proximity makes the family resemblance visible: all are populations of simple agents, all rely on local interactions, all produce emergent global behavior. The differences lie in the coordination mechanism.

## Unified Agent Architecture

The gallery's technical achievement is a common agent interface that different swarm algorithms instantiate differently.

```gdscript
class SwarmAlgorithm:
    var agents: Array[Dictionary] = []
    var environment: Dictionary = {}
    var parameters: Dictionary = {}

    func initialize(num_agents: int, params: Dictionary) -> void:
        parameters = params
        for i in num_agents:
            agents.append(_create_agent(i))

    func step(delta: float) -> void:
        for i in agents.size():
            var perception: Dictionary = _perceive(i)
            var action: Dictionary = _decide(i, perception)
            _act(i, action, delta)
        _update_environment(delta)

    func _create_agent(i: int) -> Dictionary:
        return {}  # Override per algorithm
    func _perceive(i: int) -> Dictionary:
        return {}  # Override per algorithm
    func _decide(i: int, perception: Dictionary) -> Dictionary:
        return {}  # Override per algorithm
    func _act(i: int, action: Dictionary, delta: float) -> void:
        pass  # Override per algorithm
    func _update_environment(delta: float) -> void:
        pass  # Override per algorithm
```

The base class defines the perceive-decide-act loop. Each algorithm overrides the four methods with its specific logic. The interface is consistent: `initialize` sets up agents and environment, `step` runs one frame. The gallery can run all algorithms simultaneously, call `step` on each, and render their states side by side.

## Physarum Implementation

```gdscript
class PhysarumSwarm extends SwarmAlgorithm:
    var trail_map: PackedFloat32Array

    func _create_agent(i: int) -> Dictionary:
        return {
            "x": randf() * trail_width,
            "y": randf() * trail_height,
            "angle": randf() * TAU
        }

    func _perceive(i: int) -> Dictionary:
        var a: Dictionary = agents[i]
        return {
            "left": sample_trail(a, -sensor_angle),
            "center": sample_trail(a, 0.0),
            "right": sample_trail(a, sensor_angle)
        }

    func _decide(i: int, perception: Dictionary) -> Dictionary:
        var turn: float = 0.0
        if perception["center"] > perception["left"] and perception["center"] > perception["right"]:
            turn = 0.0
        elif perception["left"] > perception["right"]:
            turn = -turn_angle
        else:
            turn = turn_angle
        return {"turn": turn}

    func _act(i: int, action: Dictionary, delta: float) -> void:
        agents[i]["angle"] += action["turn"]
        agents[i]["x"] += cos(agents[i]["angle"]) * move_speed
        agents[i]["y"] += sin(agents[i]["angle"]) * move_speed
        deposit_trail(agents[i]["x"], agents[i]["y"])

    func _update_environment(delta: float) -> void:
        diffuse_trail()
        decay_trail()
```

The Physarum implementation maps directly to the PhysarumColony artifact's logic: sense three directions, turn toward strongest trail, deposit at current position, diffuse and decay the trail map.

## Boids Implementation

```gdscript
class BoidsSwarm extends SwarmAlgorithm:
    func _create_agent(i: int) -> Dictionary:
        return {
            "position": Vector3(randf_range(-10, 10), randf_range(2, 8), randf_range(-10, 10)),
            "velocity": Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
        }

    func _perceive(i: int) -> Dictionary:
        var neighbors: Array = []
        for j in agents.size():
            if j == i: continue
            var dist: float = agents[i]["position"].distance_to(agents[j]["position"])
            if dist < perception_radius:
                neighbors.append(j)
        return {"neighbors": neighbors}

    func _decide(i: int, perception: Dictionary) -> Dictionary:
        var sep := compute_separation(i, perception["neighbors"])
        var ali := compute_alignment(i, perception["neighbors"])
        var coh := compute_cohesion(i, perception["neighbors"])
        return {"force": sep * w_sep + ali * w_ali + coh * w_coh}

    func _act(i: int, action: Dictionary, delta: float) -> void:
        agents[i]["velocity"] += action["force"] * delta
        agents[i]["velocity"] = agents[i]["velocity"].limit_length(max_speed)
        agents[i]["position"] += agents[i]["velocity"] * delta
```

Three steering forces, no environment modification. The contrast with Physarum is stark: boids leave no trace, coordinate instantaneously, and forget every frame.

## ACO Implementation

```gdscript
class ACOSwarm extends SwarmAlgorithm:
    var pheromone: Dictionary = {}
    var graph: Dictionary = {}

    func _decide(i: int, perception: Dictionary) -> Dictionary:
        var current_node: int = agents[i]["current_node"]
        var visited: Dictionary = agents[i]["visited"]
        var options: Array = get_unvisited_neighbors(current_node, visited)

        if options.is_empty():
            return {"action": "backtrack"}

        var probabilities: Array = []
        var total: float = 0.0
        for node in options:
            var key: String = edge_key(current_node, node)
            var tau: float = pow(pheromone[key], alpha)
            var eta: float = pow(1.0 / distances[key], beta)
            var weight: float = tau * eta
            probabilities.append(weight)
            total += weight

        var chosen: int = _roulette_select(options, probabilities, total)
        return {"action": "move", "target": chosen}
```

Graph-based navigation with probabilistic edge selection. The pheromone dictionary is the shared environment. Alpha controls pheromone influence. Beta controls distance-heuristic influence.

## PSO Implementation

```gdscript
class PSOSwarm extends SwarmAlgorithm:
    var global_best_pos: Vector3
    var global_best_fitness: float = INF

    func _decide(i: int, perception: Dictionary) -> Dictionary:
        var r1: float = randf()
        var r2: float = randf()
        var cognitive: Vector3 = c1 * r1 * (agents[i]["personal_best"] - agents[i]["position"])
        var social: Vector3 = c2 * r2 * (global_best_pos - agents[i]["position"])
        var inertia: Vector3 = w * agents[i]["velocity"]
        return {"velocity": inertia + cognitive + social}

    func _act(i: int, action: Dictionary, delta: float) -> void:
        agents[i]["velocity"] = action["velocity"]
        agents[i]["position"] += agents[i]["velocity"] * delta
        var fitness: float = evaluate(agents[i]["position"])
        if fitness < agents[i]["personal_best_fitness"]:
            agents[i]["personal_best"] = agents[i]["position"]
            agents[i]["personal_best_fitness"] = fitness
        if fitness < global_best_fitness:
            global_best_fitness = fitness
            global_best_pos = agents[i]["position"]
```

Agent memory replaces environmental memory. No trail, no pheromone. The environment is read-only.

## The Comparison Matrix

The gallery enables direct comparison along several axes:

**Coordination mechanism:**
- Stigmergic (Physarum, ACO): environment carries messages between agents
- Social (Boids, PSO): agents read each other directly
- Field-based (Flow fields): pre-built environment guides agents
- General (ABM): any combination

**Memory location:**
- Environmental (Physarum trail, ACO pheromone): shared, decaying, spatial
- Agent-internal (PSO personal best, ABM state): private, persistent, non-spatial
- None (Boids, flow field particles): stateless, instantaneous

**Problem type:**
- Network formation (Physarum): connect points with efficient paths
- Navigation (Flow fields): traverse a vector field
- Coordination (Boids): maintain group coherence
- General simulation (ABM): any agent interaction
- Combinatorial optimization (ACO): find shortest route on a graph
- Continuous optimization (PSO): find function minimum in real-valued space

## The Multi-Level Ecosystem Layout

The 10x10 map uses three platform heights (2, 3, 4) representing canopy, understory, and ground layers — an ecological stratification that metaphorically mirrors the layered nature of swarm intelligence. Different algorithms occupy different ecological niches. Ground-level alcoves host algorithms that operate on 2D surfaces (Physarum, flow fields). Mid-level platforms host algorithms with 3D spatial extent (boids). Upper platforms host algorithms that operate on abstract graphs or fitness landscapes (ACO, PSO).

The ground floor connects everything. Walking between alcoves is walking between paradigms of collective intelligence — from biological stigmergy to mathematical optimization, from specific organisms to general frameworks. The gallery is both a museum and a laboratory, displaying finished algorithms and inviting the learner to see them as variations on a theme.

## The Swarm Intelligence Thesis

The sequence's thesis, demonstrated across seven maps and crystallized in this gallery: intelligence does not require centralized control. It requires a population of simple agents, a coordination mechanism (environmental, social, or field-based), and time. The specific mechanism determines what kind of intelligence emerges — network formation, flocking, optimization, navigation — but the structural pattern is invariant. Local rules. Global behavior. No leader. No plan. The gallery makes this invariance visible by showing that six radically different algorithms share the same architecture: agents that perceive, decide, and act in a shared world, producing collective behavior that no individual computed.
