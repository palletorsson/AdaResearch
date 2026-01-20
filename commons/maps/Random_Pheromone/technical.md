# Random_Pheromone - Technical Documentation

## Core Concept in Code

### Basic Pheromone Grid

```gdscript
extends Node3D

@export var grid_size := 50
@export var evaporation_rate := 0.02
@export var deposit_amount := 1.0

var pheromone_grid := []

func _ready():
    initialize_grid()

func initialize_grid():
    pheromone_grid.resize(grid_size)
    for i in range(grid_size):
        pheromone_grid[i] = []
        pheromone_grid[i].resize(grid_size)
        pheromone_grid[i].fill(0.0)

func _process(delta):
    evaporate(delta)
    update_visualization()

func evaporate(delta):
    for x in range(grid_size):
        for y in range(grid_size):
            pheromone_grid[x][y] *= (1.0 - evaporation_rate * delta)

func deposit(x: int, y: int, amount: float):
    if x >= 0 and x < grid_size and y >= 0 and y < grid_size:
        pheromone_grid[x][y] += amount

func get_pheromone(x: int, y: int) -> float:
    if x >= 0 and x < grid_size and y >= 0 and y < grid_size:
        return pheromone_grid[x][y]
    return 0.0
```

### Ant Agent with Pheromone Following

```gdscript
class_name PheromoneAnt
extends Node3D

var pheromone_system: Node3D  # Reference to grid
var position_grid := Vector2i.ZERO
var has_food := false
var home_position := Vector2i.ZERO
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()

func _process(delta):
    if has_food:
        return_home()
    else:
        search_for_food()

func search_for_food():
    # Random walk biased by pheromone
    var neighbors = get_neighbors()
    var chosen = weighted_random_choice(neighbors)
    move_to(chosen)

func get_neighbors() -> Array[Vector2i]:
    var neighbors: Array[Vector2i] = []
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if dx == 0 and dy == 0:
                continue
            neighbors.append(position_grid + Vector2i(dx, dy))
    return neighbors

func weighted_random_choice(neighbors: Array[Vector2i]) -> Vector2i:
    var weights := []
    var total_weight := 0.0

    for pos in neighbors:
        var pheromone = pheromone_system.get_pheromone(pos.x, pos.y)
        var weight = 1.0 + pheromone * 2.0  # Base weight + pheromone bonus
        weights.append(weight)
        total_weight += weight

    var roll = rng.randf() * total_weight
    var cumulative := 0.0
    for i in range(neighbors.size()):
        cumulative += weights[i]
        if roll < cumulative:
            return neighbors[i]

    return neighbors[0]

func return_home():
    # Leave pheromone trail while returning
    pheromone_system.deposit(position_grid.x, position_grid.y, 1.0)
    # Move toward home (simplified)
    var direction = (home_position - position_grid).sign()
    position_grid += direction
```

## Implementation Details

### Pheromone Visualization

```gdscript
extends Node3D

var mesh_instances := []
var pheromone_material: StandardMaterial3D

func create_visualization():
    pheromone_material = StandardMaterial3D.new()
    pheromone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

    for x in range(grid_size):
        mesh_instances.append([])
        for y in range(grid_size):
            var instance = create_tile(x, y)
            mesh_instances[x].append(instance)
            add_child(instance)

func create_tile(x: int, y: int) -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var plane = PlaneMesh.new()
    plane.size = Vector2(0.9, 0.9)
    mesh.mesh = plane
    mesh.position = Vector3(x, 0, y)
    mesh.material_override = pheromone_material.duplicate()
    return mesh

func update_visualization():
    for x in range(grid_size):
        for y in range(grid_size):
            var intensity = clampf(pheromone_grid[x][y] / 10.0, 0.0, 1.0)
            var color = Color(0.2, intensity, 0.2)  # Green intensity
            mesh_instances[x][y].material_override.albedo_color = color
```

### Multiple Pheromone Types

Real ant colonies use multiple pheromones (food, danger, nest):

```gdscript
enum PheromoneType { FOOD, DANGER, NEST }

var pheromone_grids := {
    PheromoneType.FOOD: [],
    PheromoneType.DANGER: [],
    PheromoneType.NEST: []
}

var evaporation_rates := {
    PheromoneType.FOOD: 0.02,
    PheromoneType.DANGER: 0.1,   # Danger fades fast
    PheromoneType.NEST: 0.005   # Nest trails persist
}
```

## Map-Specific Configuration

### Structure Analysis
- 13×14 grid, almost entirely flat (height 0)
- Single elevated tile at (7,7) with height 1
- Creates minimal visual interference with pheromone display

### Dual Clipboard System
The presence of both `clipboard#pheromone_axioms` and `clipboard#queer_energy` explicitly connects biological emergence to QFEP theory.

## Key Takeaways

1. **Random + Memory = Intelligence** - Individual randomness plus environmental memory yields collective optimization
2. **Evaporation is essential** - Without forgetting, systems can't adapt
3. **Probability, not determination** - Ants don't follow trails perfectly; they're biased toward them
4. **Stigmergy** - Communication through environment modification

## Related Systems
- Swarm intelligence algorithms (Boids, PSO)
- Cellular automata (local rules → global patterns)
- Reinforcement learning (reward signals shape behavior)
