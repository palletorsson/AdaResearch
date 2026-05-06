extends Node

var text = '''[center][font_size=28][b]Genetic Algorithms[/b][/font_size][/center]
[center][i]Evolution, Selection, Mutation[/i][/center]

**Genetic Algorithms (GAs) evolve solutions through selection and variation.**

**Inspired by biological evolution:** selection, crossover, mutation.

[hr]

[b]The Algorithm[/b]

1. **Population** - collection of candidate solutions (genomes)
2. **Fitness** - evaluate each solution's quality
3. **Selection** - choose best individuals to reproduce
4. **Crossover** - combine parent genes to create offspring
5. **Mutation** - random changes to genes
6. **Repeat** - iterate for many generations

[color=yellow][b]Code:[/b][/color]
[code]
class Individual:
    var genome: Array[float]  # Parameters
    var fitness: float = 0.0

func evolve_population(population: Array[Individual]):
    # Evaluate fitness
    for ind in population:
        ind.fitness = evaluate_fitness(ind.genome)

    # Selection (tournament)
    var parents = []
    for i in range(population.size()):
        var a = population[randi() % population.size()]
        var b = population[randi() % population.size()]
        parents.append(a if a.fitness > b.fitness else b)

    # Crossover + Mutation
    var offspring = []
    for i in range(0, parents.size(), 2):
        var child1, child2 = crossover(parents[i], parents[i+1])
        mutate(child1)
        mutate(child2)
        offspring.append(child1)
        offspring.append(child2)

    return offspring

func crossover(parent1: Individual, parent2: Individual):
    var point = randi() % parent1.genome.size()
    var child1_genome = parent1.genome.slice(0, point) + parent2.genome.slice(point)
    var child2_genome = parent2.genome.slice(0, point) + parent1.genome.slice(point)
    return [Individual.new(child1_genome), Individual.new(child2_genome)]

func mutate(individual: Individual):
    for i in range(individual.genome.size()):
        if randf() < mutation_rate:
            individual.genome[i] += randf_range(-0.1, 0.1)
[/code]

**Over generations:** Population improves. **Fitness increases.**

[hr]

[b]Queer Evolution[/b]

**GAs prioritize reproduction** - only fittest reproduce, genes passed to offspring.

**This is heteronormative evolution** - value determined by reproductive fitness.

**Queer evolution resists:**
- **Non-reproductive value** (worker ants, queer uncles, chosen family)
- **Horizontal gene transfer** (learning from non-parents, community knowledge)
- **Mutation as generativity** (variation not from parents but from deviation)

**GAs assume fitness = reproductive success.** **Queerness questions this metric.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Genetic Algorithms: evolve solutions via selection, crossover, mutation. Population, fitness evaluation, tournament selection, gene recombination. Queer critique: reproductive fitness as sole value, ignoring non-reproductive contributions, horizontal transfer, mutation as non-parental generativity.

'''
