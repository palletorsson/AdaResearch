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
