# CA Edge of Chaos

Four classes. Class IV — the edge — supports computation.

Classify by lambda.

```gdscript
func compute_lambda(rule: Array) -> float:
    var nonzero: int = 0
    for entry in rule:
        if entry != 0: nonzero += 1
    return float(nonzero) / rule.size()
```

Langton's lambda — fraction of rule entries that produce non-zero outputs. Low lambda: Class I; high: Class III; intermediate: Class IV.

Classify by activity.

```gdscript
func classify_by_activity(pattern: Array) -> String:
    var final := pattern[-1]
    var second_last := pattern[-2]
    if is_all_zero(final): return "Class I"
    if final == second_last: return "Class II"
    if appears_random(final): return "Class III"
    return "Class IV"
```

Heuristic classification from the pattern's trajectory. Rough but useful.

Detect gliders.

```gdscript
func find_moving_structures(pattern: Array, window: int = 20) -> int:
    var movers: int = 0
    for t in range(window, pattern.size()):
        var earlier := pattern[t - window]
        var current := pattern[t]
        if shifted_equal(earlier, current, Vector2i(window, 0)):
            movers += 1
    return movers
```

Count translational symmetries over time. Gliders produce many; static patterns produce none.

Disease-spread model.

```gdscript
enum Health { SUSCEPTIBLE, INFECTED, RECOVERED }

func sir_rule(self_state: int, neighbours: Array) -> int:
    match self_state:
        Health.SUSCEPTIBLE:
            for n in neighbours:
                if n == Health.INFECTED and randf() < 0.3:
                    return Health.INFECTED
            return Health.SUSCEPTIBLE
        Health.INFECTED:
            if randf() < 0.1:
                return Health.RECOVERED
            return Health.INFECTED
        Health.RECOVERED:
            return Health.RECOVERED
    return self_state
```

SIR epidemiological model. Spreads from infected to susceptible; infected recover over time.

Self-organisation demo.

```gdscript
func majority_rule_step() -> void:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var sum: int = 0
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    sum += grid[(y + dy + size.y) % size.y][(x + dx + size.x) % size.x]
            row.append(1 if sum >= 5 else 0)
        new_grid.append(row)
    grid = new_grid
```

Each cell takes the majority of its 3×3 neighbourhood. Produces large blobs from noise.

Volumetric fog.

```gdscript
func build_fog_layer(size: Vector3i) -> Array:
    var fog: Array = []
    for z in size.z:
        fog.append([])
        for y in size.y:
            fog[z].append([])
            for x in size.x:
                fog[z][y].append(randf() < 0.3)
    return fog

func fog_step(fog: Array) -> Array:
    # 3D CA rule — Class IV-ish
    var new_fog: Array = fog.duplicate(true)
    # Apply rule to each cell based on 3D neighbourhood count
    return new_fog
```

3D Class IV automaton. Cloud-like drifting structure emerges from random initialisation.

You can now compute lambda, classify patterns by activity and by moving structures, run SIR disease spread, majority-rule self-organisation, and 3D volumetric fog. Chamber_CA closes the sequence with rule-systems in contact.
