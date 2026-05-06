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
