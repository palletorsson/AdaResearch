# Random Pheromone

Each ant walks randomly; the trail it leaves biases the next. Build stigmergy from a floor-grid of pheromone values.

Declare the pheromone grid.

```gdscript
class_name PheromoneGrid
extends Node3D

@export var size: Vector2i = Vector2i(40, 40)
var field: PackedFloat32Array = PackedFloat32Array()
```

A flat grid of floats, one per cell. The values decay over time and grow with deposits.

Deposit pheromone at a position.

```gdscript
func deposit(pos: Vector3, amount: float) -> void:
    var cell := _world_to_cell(pos)
    var idx := cell.y * size.x + cell.x
    if idx >= 0 and idx < field.size():
        field[idx] = min(field[idx] + amount, 1.0)
```

Deposits cap at 1.0. The field stays bounded. Every ant step thickens the floor under it.

Decay the field.

```gdscript
func decay(dt: float, rate: float) -> void:
    for i in field.size():
        field[i] = max(0.0, field[i] - rate * dt)
```

All cells lose a little each frame. Without fresh deposits, trails fade. Memory is finite.

Spawn ants.

```gdscript
func spawn_ants(count: int) -> void:
    for i in count:
        var ant := preload("res://commons/artifacts/randomness/ant.tscn").instantiate()
        ant.position = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
        add_child(ant)
```

Ants start scattered. Each carries its own position and heading.

Bias each step by local pheromone.

```gdscript
func step_ant(ant: Node3D, dt: float) -> void:
    var dir := _pick_direction_with_bias(ant.global_position)
    ant.position += dir * ant_speed * dt
    deposit(ant.global_position, 0.05)
```

Direction is chosen by sampling neighbouring cells and weighting toward higher pheromone. The ant tends to follow a trail without committing to it.

Sample the bias.

```gdscript
func _pick_direction_with_bias(pos: Vector3) -> Vector3:
    var weights := []
    var dirs := [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
    for d in dirs:
        var sample_pos: Vector3 = pos + d * cell_size
        weights.append(field[_index(sample_pos)] + 0.05)
    return dirs[_weighted_pick(weights)]
```

Four cardinal directions sampled. Weights are the local pheromone plus a small constant so ants still explore empty cells.

Render the pheromone as a heatmap.

```gdscript
func update_heatmap(image: Image) -> void:
    for i in field.size():
        var v: float = field[i]
        var x: int = i % size.x
        var y: int = i / size.x
        image.set_pixel(x, y, Color(v, v * 0.3, 0.0))
```

Orange trails glow over a dark floor. The learner watches paths consolidate from noise.

Log the trail shape.

```gdscript
func trail_entropy() -> float:
    var mean: float = 0.0
    for v in field: mean += v
    mean /= field.size()
    return mean
```

A scalar describes how much of the grid is active. As ants converge on a trail, the scalar drops.

You have built emergence from individual chance. The next map, Random Space, saturates space with randomness.
<<</MAP>>>
