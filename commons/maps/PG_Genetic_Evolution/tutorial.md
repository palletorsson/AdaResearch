# PG Genetic Evolution

Creatures evolve by selection. Body plans as genomes.

Encode a body plan.

```gdscript
class_name BodyPlan

var limb_count: int = 4
var limb_positions: Array = []  # Vector3 per limb
var behavior_weights: Array = []  # float per behaviour
```

The plan is the genome. Its fields determine the creature's morphology and behaviour.

Random body plan.

```gdscript
func random_body() -> BodyPlan:
    var body := BodyPlan.new()
    body.limb_count = randi_range(2, 6)
    for _i in body.limb_count:
        body.limb_positions.append(Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)))
    for _i in 8:
        body.behavior_weights.append(randf_range(-1, 1))
    return body
```

Random within bounds. The population starts with diverse configurations.

Spawn the creature.

```gdscript
func spawn_creature(body: BodyPlan) -> CharacterBody3D:
    var creature := CREATURE_SCENE.instantiate()
    for pos in body.limb_positions:
        var limb := LIMB_SCENE.instantiate()
        limb.position = pos
        creature.add_child(limb)
    creature.set_behavior_weights(body.behavior_weights)
    add_child(creature)
    return creature
```

Assemble the creature from its body plan. Each limb is a child; the weights drive the behaviour script.

Evaluate fitness.

```gdscript
func evaluate(body: BodyPlan) -> float:
    var creature := spawn_creature(body)
    var start := creature.global_position
    await get_tree().create_timer(10.0).timeout
    var fitness: float = start.distance_to(creature.global_position)
    creature.queue_free()
    return fitness
```

Run for 10 seconds. Fitness is total distance from starting position.

Tournament selection.

```gdscript
func tournament(population: Array, k: int = 3) -> BodyPlan:
    var contestants: Array = []
    for _i in k:
        contestants.append(population[randi() % population.size()])
    contestants.sort_custom(func(a, b): return a.fitness > b.fitness)
    return contestants[0]
```

K random candidates; best wins. Returns the plan, not its fitness.

Crossover two body plans.

```gdscript
func crossover(a: BodyPlan, b: BodyPlan) -> BodyPlan:
    var child := BodyPlan.new()
    child.limb_count = a.limb_count if randf() < 0.5 else b.limb_count
    for i in child.limb_count:
        var parent := a if randf() < 0.5 else b
        child.limb_positions.append(parent.limb_positions[i % parent.limb_positions.size()])
    for i in a.behavior_weights.size():
        child.behavior_weights.append(a.behavior_weights[i] if randf() < 0.5 else b.behavior_weights[i])
    return child
```

Mix-and-match fields between parents. The child inherits a combination.

Mutate a body plan.

```gdscript
func mutate(body: BodyPlan, rate: float = 0.15) -> void:
    for i in body.limb_positions.size():
        if randf() < rate:
            body.limb_positions[i] += Vector3(randfn(0, 0.1), randfn(0, 0.1), randfn(0, 0.1))
    for i in body.behavior_weights.size():
        if randf() < rate:
            body.behavior_weights[i] += randfn(0, 0.1)
            body.behavior_weights[i] = clamp(body.behavior_weights[i], -1, 1)
```

Each field may mutate by Gaussian noise. Rate controls how many mutations per offspring.

You can now encode body plans as genomes, spawn creatures, evaluate fitness, and run a selection-crossover-mutation loop. PG_Space_Colonization extends into tree growth toward attractors.
