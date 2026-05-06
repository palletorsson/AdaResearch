# ML Evolution

A genetic algorithm. Population, selection, mutation.

Define a creature genome.

```gdscript
class_name Genome

var genes: Array = []  # array of floats in [-1, 1]

func random_genome(size: int) -> void:
    genes.clear()
    for _i in size:
        genes.append(randf_range(-1.0, 1.0))
```

An array of real-valued parameters. Each gene influences one behaviour weight.

Build a creature from a genome.

```gdscript
func spawn_creature(genome: Genome) -> CharacterBody3D:
    var creature := CREATURE_SCENE.instantiate()
    creature.set_weights(genome.genes)
    add_child(creature)
    return creature
```

The creature reads the weights and uses them to drive its motion.

Evaluate fitness.

```gdscript
func evaluate_fitness(genome: Genome) -> float:
    var creature := spawn_creature(genome)
    var start := creature.global_position
    await get_tree().create_timer(10.0).timeout
    var distance: float = start.distance_to(creature.global_position)
    creature.queue_free()
    return distance
```

Run the creature for 10 seconds; measure distance travelled. Fitness is the distance.

Tournament selection.

```gdscript
func tournament_select(population: Array, k: int = 3) -> Genome:
    var contestants: Array = []
    for _i in k:
        contestants.append(population[randi() % population.size()])
    contestants.sort_custom(func(a, b): return a.fitness > b.fitness)
    return contestants[0]
```

Pick k random genomes; return the best. Larger k means stronger selection pressure.

Crossover.

```gdscript
func crossover(parent_a: Genome, parent_b: Genome) -> Genome:
    var child := Genome.new()
    for i in parent_a.genes.size():
        child.genes.append(parent_a.genes[i] if randf() < 0.5 else parent_b.genes[i])
    return child
```

Uniform crossover. Each gene comes from one parent at random.

Mutation.

```gdscript
func mutate(genome: Genome, rate: float = 0.1, strength: float = 0.2) -> void:
    for i in genome.genes.size():
        if randf() < rate:
            genome.genes[i] += randfn(0.0, strength)
            genome.genes[i] = clamp(genome.genes[i], -1.0, 1.0)
```

Each gene has a chance of Gaussian perturbation. Rate and strength are tunable.

Run the generation loop.

```gdscript
func run_generation(population: Array, size: int) -> Array:
    for g in population:
        g.fitness = await evaluate_fitness(g)
    var next_gen: Array = []
    population.sort_custom(func(a, b): return a.fitness > b.fitness)
    # Elitism: top 20% carry over
    for i in size / 5:
        next_gen.append(population[i])
    while next_gen.size() < size:
        var parent_a := tournament_select(population)
        var parent_b := tournament_select(population)
        var child := crossover(parent_a, parent_b)
        mutate(child)
        next_gen.append(child)
    return next_gen
```

Elitism preserves the best; the rest are produced by crossover and mutation. Elitism prevents regression.

You can now build a genetic algorithm with genomes, fitness evaluation, tournament selection, crossover, and mutation. ML_Gradient_Landscape extends into calculus-driven optimisation.

Reset a population.

```gdscript
func reset_population(size: int, gene_count: int) -> Array:
    var p: Array = []
    for _i in size:
        var g := Genome.new()
        g.random_genome(gene_count)
        p.append(g)
    return p
```

Start fresh. Used when the current population has collapsed onto a local optimum.
