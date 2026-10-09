# Ant Colony Optimization

Ants find shortest paths. Pheromones mark good routes.

Define a pheromone graph.

```gdscript
class_name ACOGraph

var vertices: Array = []
var distance: Dictionary = {}      # [u, v] -> distance
var pheromone: Dictionary = {}     # [u, v] -> pheromone amount

func add_edge(u, v, d: float) -> void:
    distance[[u, v]] = d
    distance[[v, u]] = d
    pheromone[[u, v]] = 1.0
    pheromone[[v, u]] = 1.0
    if not u in vertices: vertices.append(u)
    if not v in vertices: vertices.append(v)
```

Bidirectional edges with distance and initial pheromone. The pheromone is mutable.

Probability of picking an edge.

```gdscript
@export var alpha: float = 1.0  # pheromone weight
@export var beta: float = 2.0   # distance weight

func edge_probability(u, v, visited: Array) -> float:
    if v in visited: return 0.0
    var tau: float = pheromone.get([u, v], 0.1) ** alpha
    var eta: float = pow(1.0 / distance[[u, v]], beta)
    return tau * eta
```

Higher pheromone + shorter distance → higher probability. Alpha and beta tune the balance.

Choose the next vertex.

```gdscript
func choose_next(current, visited: Array, graph: ACOGraph) -> Variant:
    var probabilities: Dictionary = {}
    var total: float = 0.0
    for v in graph.vertices:
        if v == current or v in visited: continue
        var p: float = graph.edge_probability(current, v, visited)
        probabilities[v] = p
        total += p
    if total == 0.0: return null
    var r: float = randf() * total
    var cumulative: float = 0.0
    for v in probabilities:
        cumulative += probabilities[v]
        if r < cumulative: return v
    return null
```

Roulette-wheel selection. Higher-probability edges are chosen more often.

One ant builds a tour.

```gdscript
func build_tour(start, graph: ACOGraph) -> Array:
    var tour: Array = [start]
    var current = start
    while tour.size() < graph.vertices.size():
        var next = choose_next(current, tour, graph)
        if next == null: break
        tour.append(next)
        current = next
    if tour.size() == graph.vertices.size():
        tour.append(start)  # return home
    return tour
```

Greedy construction guided by probabilities. Ants don't backtrack.

Deposit pheromone.

```gdscript
@export var pheromone_deposit: float = 1.0

func deposit_on_tour(tour: Array, graph: ACOGraph) -> void:
    var total_distance: float = 0.0
    for i in range(tour.size() - 1):
        total_distance += graph.distance[[tour[i], tour[i + 1]]]
    var amount: float = pheromone_deposit / total_distance
    for i in range(tour.size() - 1):
        graph.pheromone[[tour[i], tour[i + 1]]] += amount
        graph.pheromone[[tour[i + 1], tour[i]]] += amount
```

Shorter tours deposit more pheromone. Good paths reinforce themselves.

Evaporate pheromone.

```gdscript
@export var evaporation_rate: float = 0.1

func evaporate(graph: ACOGraph) -> void:
    for edge in graph.pheromone:
        graph.pheromone[edge] *= (1.0 - evaporation_rate)
```

Reduces all pheromones each iteration. Prevents early paths from dominating forever.

Run one iteration.

```gdscript
func iteration(graph: ACOGraph, ant_count: int) -> Array:
    var best_tour: Array = []
    var best_length: float = INF
    for _i in ant_count:
        var tour: Array = build_tour(graph.vertices[0], graph)
        if tour.size() == graph.vertices.size() + 1:
            deposit_on_tour(tour, graph)
            var length: float = tour_length(tour, graph)
            if length < best_length:
                best_length = length; best_tour = tour
    evaporate(graph)
    return best_tour
```

Each iteration: all ants build tours; deposit pheromones; evaporate. Over iterations, the best tour emerges.

You can now build an ACO graph, compute edge probabilities, construct tours, deposit and evaporate pheromones, and iterate the algorithm toward shortest paths. SwarmIntelligence_Particle_Swarm_Optimization extends to continuous optimisation.
