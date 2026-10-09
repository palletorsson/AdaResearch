# CA Soft Rules

Stochastic. Rules fire probabilistically rather than deterministically.

Stochastic rule application.

```gdscript
@export var fire_probability: float = 0.8

func stochastic_rule(alive: bool, neighbours: int) -> bool:
    if randf() > fire_probability:
        return alive  # rule didn't fire; state unchanged
    return standard_rule(alive, neighbours)
```

With probability fire_probability, apply the standard rule. Otherwise, keep the current state.

Noise-modulated Rule 30.

```gdscript
func soft_rule_30(left: int, centre: int, right: int) -> int:
    if randf() > 0.8:
        return centre  # no change
    var pattern: int = left * 4 + centre * 2 + right
    return rule_bit(30, pattern)
```

Rule 30 with 20% chance of no-update per cell. The pattern fuzzes but retains Rule 30's characteristic triangles.

Apply gravity bias.

```gdscript
@export var gravity_bias: float = 0.1

func biased_rule(alive: bool, neighbours: int) -> bool:
    var new_state: bool = standard_rule(alive, neighbours)
    if randf() < gravity_bias:
        return true  # biased toward alive
    return new_state
```

Environmental bias pushes the system toward a preferred state. Models thermal or gravitational drift.

Measure rule stability.

```gdscript
func measure_drift(steps: int = 100) -> float:
    var changes: int = 0
    for _i in steps:
        var old_grid: Array = grid.duplicate(true)
        step()
        for y in size.y:
            for x in size.x:
                if old_grid[y][x] != grid[y][x]: changes += 1
    return float(changes) / (steps * size.x * size.y)
```

Fraction of cells that change per step on average. Low for Class I; high for Class III.

Anneal the probability.

```gdscript
var current_probability: float = 0.5

func anneal_step(target: float, rate: float) -> void:
    current_probability = lerp(current_probability, target, rate)
    fire_probability = current_probability
```

Gradually adjust the stochasticity. Simulated annealing — start noisy, end crisp.

Detect steady-state distribution.

```gdscript
func steady_state(history: Array, window: int = 50) -> Dictionary:
    var counts: Dictionary = {}
    for snapshot in history.slice(-window):
        for row in snapshot:
            for cell in row:
                counts[cell] = counts.get(cell, 0) + 1
    var total: int = counts.values().reduce(func(a, b): return a + b, 0)
    var distribution: Dictionary = {}
    for state in counts:
        distribution[state] = float(counts[state]) / total
    return distribution
```

Histogram of states over recent history. Stable if the distribution converges over time.

You can now build stochastic rules, apply noise and gravity biases, measure drift, anneal stochasticity, and detect steady-state distributions. CA_AgentsCircuits extends into Wireworld.

Reset the grid to random.

```gdscript
func reset_random(density: float = 0.3) -> void:
    for y in size.y:
        for x in size.x:
            grid[y][x] = 1 if randf() < density else 0
```

Useful for exploring the rule's behaviour from different starting conditions.
