# PG Caves Mazes — Technical

The map stages two subtractive strategies side by side. A cellular automaton carves caves; a spanning-tree algorithm builds mazes. Both hollow space from a solid block, but the character of each is opposite.

```gdscript
class_name CaveGenerator extends Node3D

@export var size: Vector2i = Vector2i(64, 64)
@export var fill_probability: float = 0.45
@export var smooth_iterations: int = 5

var cells: Array = []  # true = wall, false = floor

func generate() -> void:
    cells = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append(randf() < fill_probability)
        cells.append(row)
    for _i in range(smooth_iterations):
        smooth_step()

func smooth_step() -> void:
    var new_cells: Array = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            var neighbours := count_wall_neighbours(x, y)
            if neighbours >= 5:
                row.append(true)
            elif neighbours <= 3:
                row.append(false)
            else:
                row.append(cells[y][x])
        new_cells.append(row)
    cells = new_cells
```

## The Cellular Automaton Rule

The "5-4 rule" — become a wall if 5 or more neighbours are walls, become floor if 4 or fewer — is a common choice for cave generation. It produces organic-looking cavities with connected passages. Different rules produce different cave characters: the "4-5 rule" makes more open spaces; the "6-3 rule" produces claustrophobic tunnels.

## Maze Generation

Mazes use a different approach: partition the space into a grid, then carve walls to form a spanning tree. Recursive backtracking is the simplest algorithm.

```gdscript
class_name RecursiveBacktracker extends Node

var visited: Dictionary = {}
var walls_carved: Array = []

func generate(start: Vector2i) -> void:
    var stack: Array = [start]
    visited[start] = true
    while not stack.is_empty():
        var current = stack[-1]
        var unvisited_neighbours := get_unvisited_neighbours(current)
        if unvisited_neighbours.is_empty():
            stack.pop_back()
        else:
            var next = unvisited_neighbours[randi() % unvisited_neighbours.size()]
            walls_carved.append([current, next])
            visited[next] = true
            stack.append(next)
```

The output is always a connected maze with exactly one path between any two cells, because a spanning tree has this property by definition.

## Kruskal's Maze

Kruskal's algorithm produces different maze textures — more uniform, less snake-like. It shuffles all walls, then removes walls whose two sides belong to different connected components, merging the components in the process. The algorithm is O((WH) · α(WH)) where α is the inverse Ackermann function (effectively constant).

## Comparison

Caves feel natural because the generator has no plan — the walker staggers and the cave forms around the walker's path. Mazes feel engineered because the generator has exactly one plan — connect everything once and no more. The map displays both outcomes on either side of a central wall and lets the learner walk through each to feel the difference.

Within the sequence, Caves_Mazes is the subtractive chapter. PG_Sculpted_Forms will next return to additive strategies through stacking rather than branching.

## CA Rule Exploration

The cellular automaton cave generator is parameterised by two numbers: the birth threshold (how many neighbours cause an empty cell to become wall) and the survival threshold (how many neighbours keep a wall cell as wall). Different thresholds produce different cave characters.

```gdscript
class_name CAParameters extends Resource

@export var birth_threshold: int = 5
@export var survival_threshold: int = 4
@export var initial_fill: float = 0.45
@export var iterations: int = 5

func rule_name() -> String:
    return "B%d/S%d" % [birth_threshold, survival_threshold]
```

The rule "B5/S4" (born at 5+, survives at 4+) is the map's default. "B678/S345678" produces more spherical caves; "B5678/S45678" is another common choice.

## Maze Algorithm Variants

Beyond recursive backtracking and Kruskal's, several other maze algorithms produce distinct textures.

```gdscript
# Prim's-based maze: grows from a single seed
func prims_maze(start: Vector2i) -> void:
    var frontier: Array = [start]
    visited[start] = true
    while not frontier.is_empty():
        var cell = frontier[randi() % frontier.size()]
        frontier.erase(cell)
        var unvisited_neighbours = get_unvisited_neighbours(cell)
        if unvisited_neighbours.is_empty():
            continue
        var next = unvisited_neighbours[randi() % unvisited_neighbours.size()]
        carve_wall_between(cell, next)
        visited[next] = true
        frontier.append(next)
```

Prim's produces mazes with many short passages. Wilson's algorithm produces uniformly random spanning trees — mazes that look more random than recursive backtracking's characteristic zigzag. Eller's algorithm generates mazes row by row in O(W) space, useful for very large mazes where the full grid cannot fit in memory.

## Postprocessing

Raw CA caves often have small disconnected regions. A post-processing pass finds the largest connected region and fills in the others, guaranteeing a navigable space. Mazes often benefit from "braiding" — removing some dead ends to create loops, making the maze feel less punitive to navigate.

```gdscript
func braid(maze: Array, loop_probability: float = 0.3) -> Array:
    var dead_ends := find_dead_ends(maze)
    for cell in dead_ends:
        if randf() < loop_probability:
            var wall_to_remove := random_wall_around(cell)
            if wall_to_remove:
                maze[wall_to_remove.y][wall_to_remove.x] = false
    return maze
```

## Hybrid Approaches

Combining strategies produces interesting hybrid spaces. A CA cave with a maze embedded in one region combines organic and engineered aesthetics. The map's two sides share a central wall to stage the contrast cleanly, but production applications often blend them spatially.
