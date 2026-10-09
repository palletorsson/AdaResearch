# Give agents rules, let them interact, watch what emerges — the ABM framework generalizes every swarm before it

Physarum was specific: sense trail, deposit trail, turn toward concentration. Boids were specific: separate, align, cohere. Each algorithm solved a particular coordination problem with a particular mechanism. Agent-based modeling abstracts the pattern. An ABM is not a specific algorithm. It is a framework: any number of agents, each carrying its own state and rules, interacting through a shared environment, producing system-level behavior that is whatever emerges.

The prior swarm maps were all ABMs without naming themselves as such. Physarum agents with position, heading, and a sense-turn-deposit loop — that is an ABM. Boids with position, velocity, and three steering forces — that is an ABM. The flow field particles, stripped to position alone, following a pre-built field — even that is a minimal ABM. This map names the pattern and generalizes it.

## The Agent Architecture

An ABM agent has four components: state, perception, decision, and action.

```gdscript
var agents: Array[Dictionary] = []

func _ready() -> void:
    for i in num_agents:
        agents.append({
            "position": Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)),
            "velocity": Vector3.ZERO,
            "state": "exploring",     # finite state machine
            "energy": 100.0,
            "carrying": false,
            "memory": []              # recent observations
        })
```

State goes beyond position and velocity. An ABM agent can carry internal variables — energy, mood, inventory, memory. The `state` field is a finite state machine label: "exploring," "gathering," "fleeing," "resting." Different states activate different decision rules. The agent's behavior is not a fixed formula applied every frame. It is a conditional program that branches on internal state and sensory input.

## Perception

Each agent perceives its environment within a limited radius. The perception model defines what the agent can sense.

```gdscript
func perceive(agent: Dictionary, all_agents: Array, environment: Dictionary) -> Dictionary:
    var nearby_agents: Array = []
    var nearby_resources: Array = []
    var pos: Vector3 = agent["position"]

    for other in all_agents:
        if other == agent:
            continue
        var dist: float = pos.distance_to(other["position"])
        if dist < perception_radius:
            nearby_agents.append({"agent": other, "distance": dist})

    for resource in environment["resources"]:
        var dist: float = pos.distance_to(resource["position"])
        if dist < perception_radius:
            nearby_resources.append({"resource": resource, "distance": dist})

    return {
        "neighbors": nearby_agents,
        "resources": nearby_resources,
        "local_density": nearby_agents.size()
    }
```

The agent senses neighbors and resources within its radius. Perception is the bottleneck — what the agent cannot sense, it cannot respond to. The perception radius is the first constraint on intelligence. A large radius approximates omniscience. A small radius forces local decision-making. The interesting behavior emerges from intermediate radii, where agents know enough to coordinate but not enough to optimize globally.

## Decision Rules

The decision function maps perception to action. In a finite state machine model, the current state and the sensory input determine the next state and the next action.

```gdscript
func decide(agent: Dictionary, perception: Dictionary) -> Dictionary:
    var action := {"type": "move", "direction": Vector3.ZERO, "speed": 1.0}

    match agent["state"]:
        "exploring":
            action["direction"] = _random_walk_direction()
            if perception["resources"].size() > 0:
                agent["state"] = "gathering"
                action["direction"] = _toward_nearest(
                    agent, perception["resources"])

        "gathering":
            if agent["carrying"]:
                agent["state"] = "returning"
                action["direction"] = _toward_base(agent)
            elif perception["resources"].size() > 0:
                action["direction"] = _toward_nearest(
                    agent, perception["resources"])
            else:
                agent["state"] = "exploring"

        "fleeing":
            if perception["local_density"] < crowd_threshold:
                agent["state"] = "exploring"
            else:
                action["direction"] = _away_from_crowd(agent, perception)
                action["speed"] = 2.0

        "returning":
            action["direction"] = _toward_base(agent)
            if _at_base(agent):
                agent["carrying"] = false
                agent["state"] = "exploring"

    return action
```

Four states, four behavioral modes. The transitions are condition-gated: finding a resource triggers "gathering," picking it up triggers "returning," crowding triggers "fleeing." The agent's behavior over time traces a path through state space — exploring, finding, gathering, returning, exploring again. The macro pattern (agents distributing resources, avoiding crowds, covering territory) emerges from these micro-level state transitions.

## Environment Interaction

The shared environment is the coordination medium. Agents modify it — consuming resources, depositing markers, altering terrain — and sense the modifications made by others.

```gdscript
func act(agent: Dictionary, action: Dictionary, environment: Dictionary) -> void:
    agent["velocity"] = action["direction"].normalized() * action["speed"]
    agent["position"] += agent["velocity"] * delta_time

    # Clamp to map bounds
    agent["position"].x = clampf(agent["position"].x, -bounds, bounds)
    agent["position"].z = clampf(agent["position"].z, -bounds, bounds)

    # Energy cost of movement
    agent["energy"] -= action["speed"] * energy_cost_per_meter * delta_time

    # Resource pickup
    if agent["state"] == "gathering":
        for resource in environment["resources"]:
            if agent["position"].distance_to(resource["position"]) < pickup_radius:
                agent["carrying"] = true
                resource["amount"] -= 1
                if resource["amount"] <= 0:
                    environment["resources"].erase(resource)
                break
```

Movement costs energy. Resources are finite and depletable. An agent that moves fast burns energy quickly. An agent that gathers resources restores its capacity. The energy budget creates a constraint that shapes macro behavior: agents cannot explore forever. They must find resources or die. The population stabilizes when the rate of resource consumption matches the rate of resource regeneration.

## The Simulation Loop

The full loop runs perceive-decide-act for every agent, then updates the environment.

```gdscript
func _process(delta: float) -> void:
    for agent in agents:
        var perception: Dictionary = perceive(agent, agents, environment)
        var action: Dictionary = decide(agent, perception)
        act(agent, action, environment)

    # Environment updates: resource respawn, pheromone decay
    _update_environment(delta)

    # Remove dead agents, spawn new ones at base
    _population_dynamics()

    update_display()
```

The order of operations matters. All agents perceive the same environment state (no double-buffering of agent positions in the naive loop). Each agent acts on its perception of the world before the next agent perceives. This is sequential update — different from Physarum's effectively parallel agent loop. The ordering creates subtle asymmetries: early agents in the loop array see the pre-action state; late agents see modifications from earlier agents. For small populations this matters little. For large ones, it can create spatial biases.

## The Map as Petri Dish

The 8x8 grid of corridors and pillars creates a structured environment that constrains agent movement. Pillars block sight lines. Corridors channel flow. Intersections force decisions. The regularity mirrors the grid-based ABM tradition — NetLogo, Sugarscape, Schelling — where agents move on discrete lattices.

The `ABMSimulation` artifact uses this corridor structure as the interaction arena. Agents navigate intersections, choose corridors, encounter each other at junctions. The architectural constraint transforms abstract agent dynamics into spatial navigation. The learner watches agents make corridor choices, cluster at resource-rich junctions, flee from overcrowded intersections, and trace out territorial patterns that reflect the grid's topology.

## From Specific to General

Boids had three rules. Physarum had one loop. ABM has arbitrary rules — any finite state machine, any perception model, any action set. This generality is the point. Every swarm intelligence algorithm is a special case of ABM. The sequence moves from specific to general: Physarum (stigmergy), flow fields (field following), boids (peer interaction), and now ABM (any combination). The next maps — ant colony optimization and particle swarm optimization — are specific ABMs applied to optimization problems, re-specializing the general framework for particular tasks.
