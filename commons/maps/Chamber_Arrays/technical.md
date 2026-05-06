# Chamber Arrays — Technical

The chamber has no catalyst mode. The learner places obstacle blocks on a grid floor; a grid agent adapts its traversal path to avoid the obstacles.

```gdscript
class_name ChamberGrid extends Node3D

@export var size: Vector2i = Vector2i(12, 12)
@export var cell_size: float = 1.0

var obstacles: Dictionary = {}  # Vector2i -> bool

func place_obstacle(coords: Vector2i) -> void:
    obstacles[coords] = true
    emit_signal("obstacles_changed")

func clear_obstacle(coords: Vector2i) -> void:
    obstacles.erase(coords)
    emit_signal("obstacles_changed")

func is_blocked(coords: Vector2i) -> bool:
    return obstacles.get(coords, false)
```

## Grid Agent

The agent performs row-major scanning with detours around obstacles. When a blocked cell is encountered, the agent executes a breadth-first search to find the nearest reachable unvisited cell.

```gdscript
class_name GridAgent extends CharacterBody3D

var visit_order: Array = []
var visited: Dictionary = {}
var current_target: Vector2i

func compute_plan() -> void:
    visit_order.clear()
    for y in range(chamber.size.y):
        for x in range(chamber.size.x):
            var c := Vector2i(x, y)
            if not chamber.is_blocked(c):
                visit_order.append(c)

func next_target() -> Vector2i:
    for c in visit_order:
        if not c in visited and not chamber.is_blocked(c):
            return c
    return Vector2i(-1, -1)

func step_along_path() -> void:
    if path.is_empty():
        var target := next_target()
        path = bfs_path(current_cell, target)
    if path.is_empty(): return
    current_cell = path.pop_front()
    visited[current_cell] = true
    global_position = Vector3(current_cell.x, 0, current_cell.y) * chamber.cell_size
```

## BFS Pathfinding

The agent's pathfinding uses breadth-first search on the unblocked cells.

```gdscript
func bfs_path(start: Vector2i, goal: Vector2i) -> Array:
    var came_from := {start: null}
    var queue := [start]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        if current == goal: break
        for neighbour in neighbours(current):
            if chamber.is_blocked(neighbour): continue
            if neighbour in came_from: continue
            came_from[neighbour] = current
            queue.append(neighbour)
    # Reconstruct path
    if not goal in came_from: return []
    var path: Array = []
    var c: Vector2i = goal
    while c != null:
        path.push_front(c)
        c = came_from[c]
    path.pop_front()  # remove start
    return path
```

## Science Screen

The wall display renders the agent's current plan as a sequence of cell indices. When obstacles are added or removed, the plan updates and the affected indices are highlighted.

```gdscript
class_name PlanDisplay extends Node3D

@export var agent: GridAgent

var last_plan: Array = []

func _process(_delta: float) -> void:
    var plan := agent.visit_order
    var diff_indices := compute_diff(last_plan, plan)
    render_plan(plan, diff_indices)
    last_plan = plan.duplicate()

func compute_diff(old_plan: Array, new_plan: Array) -> Array:
    var diffs: Array = []
    for i in range(min(old_plan.size(), new_plan.size())):
        if old_plan[i] != new_plan[i]:
            diffs.append(i)
    return diffs
```

## Step Counter

A second display tracks how many extra steps each new obstacle costs. The baseline is the step count for an unobstructed plan; each obstacle adds the detour length.

```gdscript
func extra_steps_from_obstacle(obstacle: Vector2i) -> int:
    var original_distance: int = chebyshev_distance_through_grid(start, goal)
    var detoured_distance: int = bfs_path(start, goal).size()
    return detoured_distance - original_distance
```

## Complexity

BFS is O(V + E) = O(W·H) for the chamber's grid. Plan recomputation happens on every obstacle change — in the worst case several times per second of the learner's placement rate. The plan display update is O(plan size) per frame; the plan holds at most W·H cells.

Within the sequence, Chamber_Arrays closes Array Tutorial with arrangement-as-catalyst. The chamber hands the learner back to the Lab with a body-level sense that arrays hold state and state responds to what is placed in it.

## Obstacle Placement Interaction

The learner carries a small block in their non-dominant hand. Clicking the trigger places the block on the nearest grid cell; clicking again removes it. The placement is discrete — the block snaps to the cell's centre.

```gdscript
class_name ObstaclePlacer extends Node3D

@export var chamber: ChamberGrid
var preview_block: Node3D

func _physics_process(_delta: float) -> void:
    var controller := get_parent() as XRController3D
    var hit_cell := raycast_to_cell(controller)
    if hit_cell != null:
        preview_block.global_position = hit_cell.global_position
        preview_block.visible = true
    else:
        preview_block.visible = false

func _on_trigger_pressed() -> void:
    var hit_cell := raycast_to_cell(self)
    if hit_cell == null: return
    var coords: Vector2i = hit_cell.coordinates
    if chamber.is_blocked(coords):
        chamber.clear_obstacle(coords)
    else:
        chamber.place_obstacle(coords)
```

## Agent Replanning

Each obstacle change triggers the agent to recompute its plan. Replanning is cheap because the grid is small; even at 12×12 = 144 cells, the BFS completes in microseconds.

```gdscript
func _on_obstacles_changed() -> void:
    compute_plan()
    reset_progress()

func reset_progress() -> void:
    visited.clear()
    current_index = 0
    current_cell = starting_cell
```

## Pathfinding Alternatives

BFS is the simplest choice; A* would be faster for larger grids. On a small grid the difference is negligible, and BFS's simpler code is better for the chamber's pedagogical aim.

```gdscript
func astar_path(start: Vector2i, goal: Vector2i) -> Array:
    var open := PriorityQueue.new()
    open.push(start, 0.0)
    var came_from := {start: null}
    var g_score := {start: 0.0}
    while not open.is_empty():
        var current: Vector2i = open.pop()
        if current == goal: return reconstruct_path(came_from, current)
        for nbr in neighbours(current):
            if chamber.is_blocked(nbr): continue
            var tentative: float = g_score[current] + 1.0
            if tentative < g_score.get(nbr, INF):
                g_score[nbr] = tentative
                came_from[nbr] = current
                var f: float = tentative + manhattan_distance(nbr, goal)
                open.push(nbr, f)
    return []
```

## Unreachable Cells

If the learner encloses a region of the grid so the agent cannot reach some unvisited cells, the agent will report the unreachable cells separately on the science screen. The report is pedagogical — it shows the consequence of the placement rather than hiding it.

## Step Cost Readout

The second display tracks the incremental step cost of each new obstacle. This is computed by comparing the path length before and after the placement.

```gdscript
func record_step_cost(obstacle: Vector2i) -> void:
    var before_path := shortest_unobstructed_tour()
    chamber.place_obstacle(obstacle)
    var after_path := shortest_unobstructed_tour_excluding(obstacle)
    var extra_steps: int = after_path.size() - before_path.size()
    step_cost_display.log_obstacle(obstacle, extra_steps)
    chamber.clear_obstacle(obstacle)  # placement happens via interaction, not this function
```

## Complexity

Pathfinding is O(V + E) = O(W·H) per replan. Replanning happens on every obstacle change, typically a few per second during active placement. The total cost is well within the map's budget.
