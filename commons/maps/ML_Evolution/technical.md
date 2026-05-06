# ML Evolution — Technical

The map runs a small genetic algorithm on a population of candidate agents. Each agent has a body plan (limb count, joint positions, weighted behaviours) encoded as a genome — a flat array of floats. The arena is a short obstacle course. Each agent runs the course once, and the distance it travels from spawn is its fitness.

The evolution loop is classical. After each generation, the top-performing agents are selected. Pairs are drawn from the selected set, and each pair produces offspring by crossover (mixing parameter values) plus mutation (adding small Gaussian noise to each parameter). The offspring replace the bottom performers, and the next generation runs.

```gdscript
class_name EvolutionController extends Node

@export var population_size: int = 32
@export var mutation_rate: float = 0.1
@export var selection_pressure: float = 0.3

var genomes: Array = []
var generation: int = 0

func _ready() -> void:
    for i in range(population_size):
        genomes.append(random_genome())

func next_generation(fitnesses: Array) -> void:
    var sorted: Array = zip(genomes, fitnesses)
    sorted.sort_custom(func(a, b): return a[1] > b[1])
    var survivors: int = int(population_size * selection_pressure)
    var new_pop: Array = []
    for i in range(survivors):
        new_pop.append(sorted[i][0])
    while new_pop.size() < population_size:
        var parent_a: Array = sorted[randi() % survivors][0]
        var parent_b: Array = sorted[randi() % survivors][0]
        var child: Array = crossover(parent_a, parent_b)
        mutate(child)
        new_pop.append(child)
    genomes = new_pop
    generation += 1

func mutate(g: Array) -> void:
    for i in range(g.size()):
        if randf() < mutation_rate:
            g[i] += randfn(0.0, 0.1)  # Gaussian
```

## Fitness Evaluation

Each generation requires running the entire population through the obstacle course, which is O(P·T) where P is population size and T is simulation steps per trial. For population 32 and 120 trial steps, that is ~3840 physics ticks per generation. At 60 Hz, a generation takes about one second of wall-clock time.

Fitness shaping matters. A naive fitness — distance travelled — rewards agents that fall forward, not agents that walk. Shaped fitnesses reward time-upright, step-count, and distance separately, then combine them with weights. The map exposes the weights as sliders so the learner can see different fitness landscapes produce different evolved behaviours.

## Exploration vs Exploitation

Selection pressure controls the exploration-exploitation tradeoff. Low pressure keeps diverse genomes alive, favouring exploration; high pressure culls aggressively, favouring exploitation of whatever worked last generation. Extreme pressure collapses the population onto a local optimum and prevents the algorithm from escaping. The map's default (0.3) balances the two.

Mutation rate is the other control. High mutation disrupts good solutions as much as bad ones; low mutation prevents the population from escaping local optima. Adaptive mutation — lowering the rate as fitness improves — is a common refinement the map does not implement but notes on a side panel.

Within the sequence, Evolution introduces optimisation without gradient. ML_Gradient_Landscape will replace the blind search with calculus-driven descent and ask what is gained by doing so.

## Crossover Variants

Several crossover strategies produce different exploration profiles. One-point crossover splits each parent at a random index and recombines the pieces. Uniform crossover picks each gene independently from one parent or the other. Arithmetic crossover takes a weighted average of the two parents. The map uses uniform crossover by default because it produces the most diverse offspring, which matters when the population is small.

```gdscript
func crossover_uniform(a: Array, b: Array) -> Array:
    var child: Array = []
    for i in range(a.size()):
        child.append(a[i] if randf() < 0.5 else b[i])
    return child

func crossover_arithmetic(a: Array, b: Array) -> Array:
    var alpha: float = randf()
    var child: Array = []
    for i in range(a.size()):
        child.append(alpha * a[i] + (1.0 - alpha) * b[i])
    return child
```

## Comparison With Gradient Descent

The evolutionary approach has two advantages over gradient descent. First, it handles non-differentiable fitness functions; the fitness only needs to be computable, not smooth. Second, it explores the landscape in parallel through the population, which reduces the risk of getting stuck in a single local minimum. The disadvantage is sample efficiency: evolution needs many fitness evaluations, while gradient descent needs one forward pass per step. Modern hybrid approaches (neuroevolution, evolutionary strategies) combine the two.

## Seeding the Population

Random genomes work for small search spaces but fail for large ones: the initial population is so bad that no recombination produces anything useful, and the algorithm never finds a gradient of fitness to climb. The map's obstacle course is calibrated so that random genomes produce some variation in fitness — a few agents happen to move forward, most fall over — and the variation is enough to drive the first generation's selection.
