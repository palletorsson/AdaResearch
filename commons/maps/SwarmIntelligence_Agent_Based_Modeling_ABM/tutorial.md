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

Reset the simulation.

```gdscript
func reset_swarm(count: int, bounds: Rect2) -> Array:
    return initialise_swarm(count, bounds)
```

Fresh start. Same bounds, new random initial conditions.
