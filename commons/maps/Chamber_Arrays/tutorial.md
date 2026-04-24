# Chamber Arrays

The only chamber without a catalyst. The learner places blocks; the agent adapts.

Set up the chamber grid.

```gdscript
class_name ChamberGrid extends Node3D

const GRID_SIZE := Vector2i(12, 12)
var obstacles: Dictionary = {}  # Vector2i -> bool

func is_blocked(coords: Vector2i) -> bool:
    return obstacles.get(coords, false)

func place_obstacle(coords: Vector2i) -> void:
    obstacles[coords] = true
    emit_signal("obstacles_changed")

func clear_obstacle(coords: Vector2i) -> void:
    obstacles.erase(coords)
    emit_signal("obstacles_changed")
```

A dictionary stores which cells are blocked. A signal lets listeners react to changes.

Let the learner place blocks.

```gdscript
func _on_trigger_pressed() -> void:
    var aim_direction: Vector3 = -controller.global_transform.basis.z
    var hit: Dictionary = raycast_for_cell(controller.global_position, aim_direction)
    if hit.is_empty(): return
    var coords: Vector2i = hit.coords
    if chamber.is_blocked(coords):
        chamber.clear_obstacle(coords)
    else:
        chamber.place_obstacle(coords)
```

Aim at a cell, pull the trigger. Toggle between placed and clear.

Build the grid agent.

```gdscript
class_name GridAgent extends CharacterBody3D

var plan: Array = []  # visit order
var current_cell: Vector2i
var path: Array = []  # current path being walked

func compute_plan() -> void:
    plan.clear()
    for y in chamber.GRID_SIZE.y:
        for x in chamber.GRID_SIZE.x:
            var c := Vector2i(x, y)
            if not chamber.is_blocked(c):
                plan.append(c)
```

Row-major visit order, skipping blocked cells.

Pathfind around obstacles with BFS.

```gdscript
func bfs_path(start: Vector2i, goal: Vector2i) -> Array:
    var came_from := {start: null}
    var queue: Array = [start]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        if current == goal: break
        for neighbour in [current + Vector2i(1, 0), current + Vector2i(-1, 0), current + Vector2i(0, 1), current + Vector2i(0, -1)]:
            if chamber.is_blocked(neighbour): continue
            if neighbour in came_from: continue
            came_from[neighbour] = current
            queue.append(neighbour)
    var result: Array = []
    var c: Vector2i = goal
    while c != null:
        result.push_front(c)
        c = came_from.get(c)
    return result
```

BFS guarantees the shortest path on an unweighted grid. The came_from dictionary lets the path be reconstructed after the search.

Walk the path.

```gdscript
func _process(delta: float) -> void:
    if path.is_empty():
        var next: Vector2i = next_unvisited_cell()
        if next == Vector2i(-1, -1): return
        path = bfs_path(current_cell, next)
    time_since_step += delta
    if time_since_step > 0.2:
        time_since_step = 0.0
        current_cell = path.pop_front()
        global_position = Vector3(current_cell.x, 0.3, current_cell.y)
```

One step every 0.2 seconds. The agent moves deliberately so the learner can watch its path choice.

Respond to obstacle changes.

```gdscript
func _on_obstacles_changed() -> void:
    compute_plan()
    path.clear()  # re-plan from current position
```

Every placement or removal triggers a replan. The agent adapts immediately.

Display the plan on the science screen.

```gdscript
func update_plan_display() -> void:
    var label_text: String = ""
    for i in plan.size():
        var c: Vector2i = plan[i]
        label_text += "(%d,%d) " % [c.x, c.y]
        if i % 6 == 5: label_text += "\n"
    plan_display.text = label_text
```

The plan is a linear list of cell indices. The display wraps every six cells for readability.

You can now build a chamber grid, place and clear obstacles, pathfind around them with BFS, and render the agent's plan as a sequence of indices. The Array Tutorial sequence hands you back to the Lab with array arrangement as a new mode of catalyst practice.
