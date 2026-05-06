# Random Gaussian

The bell curve emerges from accumulation. Build the Galton board where balls fall through pegs and settle into a Gaussian.

Declare the board.

```gdscript
class_name GaltonBoard
extends Node3D

@export var rows: int = 12
@export var peg_spacing: float = 0.3
```

Rows stack down; each row has one more peg than the one above. The triangle widens with depth.

Place the pegs.

```gdscript
func place_pegs() -> void:
    for r in rows:
        for p in r + 1:
            var peg := preload("res://commons/artifacts/randomness/peg.tscn").instantiate()
            var x: float = (p - r * 0.5) * peg_spacing
            var y: float = -r * peg_spacing
            peg.position = Vector3(x, y, 0.0)
            add_child(peg)
```

A triangle of pegs. Each ball that lands on a peg has a 50/50 chance of going left or right. Over many balls, positions converge.

Drop a ball.

```gdscript
func drop_ball() -> void:
    var ball := preload("res://commons/artifacts/randomness/ball.tscn").instantiate()
    ball.position = Vector3(0.0, 0.3, 0.0)
    ball.linear_velocity = Vector3(0, -0.5, 0)
    add_child(ball)
    balls.append(ball)
```

The ball starts at the top centre with a small downward push. Physics handles the bouncing. The end position depends on which side of each peg the ball took.

Collect the landing position.

```gdscript
func record_landing(ball: Node3D) -> void:
    var bucket_index: int = int(round(ball.position.x / peg_spacing))
    histogram[bucket_index] = histogram.get(bucket_index, 0) + 1
```

Each landing slot increments a bucket. The histogram updates.

Render the histogram.

```gdscript
func update_histogram_mesh(mesh: ArrayMesh) -> void:
    for key in histogram:
        var bar := get_bar_for(key)
        bar.scale.y = float(histogram[key]) * 0.05
        bar.position.y = bar.scale.y * 0.5
```

Bars rise behind the slots. The curve reveals itself as more balls land. The peak sits at the centre; tails spread outward.

Compare to an analytic bell curve.

```gdscript
func analytic_gaussian(x: float) -> float:
    var sigma: float = sqrt(float(rows) / 4.0)
    return exp(-(x * x) / (2.0 * sigma * sigma))
```

The formula predicts the shape from the row count. The prediction is overlaid on the histogram. The measured bars approach the line.

Drop many balls.

```gdscript
func drop_cohort(count: int) -> void:
    for i in count:
        drop_ball()
        await get_tree().create_timer(0.04).timeout
```

A coroutine drops a ball every 40 milliseconds. A few hundred balls fill the histogram. The Central Limit Theorem becomes a scene.

You have watched the bell curve emerge. The next map, Random Mushrooms, grounds Gaussian sampling in biological form.
<<</MAP>>>
