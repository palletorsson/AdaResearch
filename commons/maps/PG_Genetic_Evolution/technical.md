# PG Genetic Evolution — Technical

The map runs a genetic programming system on creature body plans. Each creature has a genome encoding limb count, joint positions, and behavioural weights. The fitness function rewards distance travelled in the arena within a time budget. The selection loop produces offspring whose fitness is expected to improve across generations.

```gdscript
class_name GeneticProgrammer extends Node

@export var population_size: int = 32
@export var mutation_rate: float = 0.1
@export var elitism: int = 4

var genomes: Array = []
var fitnesses: Array = []

func _ready() -> void:
    for i in range(population_size):
        genomes.append(random_genome())

func evaluate() -> void:
    fitnesses.clear()
    for g in genomes:
        var creature = spawn_creature(g)
        var start := creature.global_position
        await get_tree().create_timer(trial_duration).timeout
        fitnesses.append(start.distance_to(creature.global_position))
        creature.queue_free()

func next_generation() -> void:
    var sorted := zip(genomes, fitnesses)
    sorted.sort_custom(func(a, b): return a[1] > b[1])
    var new_pop: Array = []
    for i in range(elitism):
        new_pop.append(sorted[i][0])
    while new_pop.size() < population_size:
        var parents := tournament_select(sorted, 3)
        var child := crossover(parents[0], parents[1])
        mutate(child)
        new_pop.append(child)
    genomes = new_pop
```

## Tournament Selection

Tournament selection picks K random genomes and returns the best. Larger tournaments produce stronger selection pressure; smaller tournaments preserve diversity. The map uses K=3, a common default.

```gdscript
func tournament_select(sorted: Array, k: int) -> Array:
    var contestants: Array = []
    for _i in range(k):
        contestants.append(sorted[randi() % sorted.size()])
    contestants.sort_custom(func(a, b): return a[1] > b[1])
    return [contestants[0][0], contestants[1][0]]
```

## Complexity

Each generation requires running the whole population through the arena. Population size P times trial duration T gives O(P·T) physics ticks per generation. For P=32 and T=600 ticks (10 seconds at 60Hz), that is 19,200 ticks per generation — about five seconds at real time, or much faster if the simulation runs headless at accelerated rates.

The map runs in real time for pedagogy: the learner watches the population improve generation by generation. Production applications run the simulation as fast as the CPU allows.

## Convergence and Local Optima

Genetic algorithms can converge prematurely to a local optimum when the population's diversity drops below a critical threshold. Once every genome looks alike, crossover produces offspring that are indistinguishable from their parents, and mutation is the only source of variation. Mutation alone is slow. The remedy is to preserve diversity — via tournament selection with smaller K, higher mutation rates, or explicit diversity bonuses.

Within the sequence, Genetic_Evolution opens Procedural Generation with evolution as the first generative strategy. PG_Space_Colonization will next use spatial hunger as a different generative principle.

## Encoding Strategies

Genome encoding shapes which solutions the evolution can explore. Real-valued encodings work well for continuous parameters such as joint angles; integer encodings suit discrete choices such as limb count; tree encodings (genetic programming proper) support whole program structures as genomes.

```gdscript
class_name Genome

var real_values: Array = []     # for real-valued params
var integer_values: Array = []  # for discrete choices
var behavior_tree: Dictionary = {}  # tree structure for strategy

func decode() -> CreatureSpec:
    return CreatureSpec.new(real_values, integer_values, behavior_tree)

func random_encoding() -> void:
    for i in range(16):
        real_values.append(randf_range(-1.0, 1.0))
        integer_values.append(randi() % 4)
    behavior_tree = random_tree(3)
```

The map uses a flat real-valued encoding for simplicity; production applications often mix encodings within a single genome.

## Novelty Search

Fitness-based selection rewards whatever currently works best. Novelty search rewards whatever is most different from past individuals. It avoids premature convergence by directly optimising for exploration. Kenneth Stanley's NEAT algorithm combines novelty search with structural mutation for neural architecture search.

## Parallel Fitness Evaluation

Evolutionary algorithms are embarrassingly parallel at the population level. Each individual's fitness evaluation is independent, so a population of P individuals evaluates in O(trial_time) wall clock with P cores and O(P · trial_time) with one core. The map runs serial on the game's main thread for pedagogical legibility; a real application would evaluate a population in parallel across CPU cores or GPU workers.

## Evaluation Speed

Running the population serially on the main thread limits generation throughput. Headless evaluation runs the physics simulation without rendering, saving GPU time and allowing much faster iteration. The map preserves rendered evaluation for pedagogy; a production genetic programming system would run headless with worker processes.
