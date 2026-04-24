# Chamber ML

The gradient_hunter learns your patterns. Move unpredictably.

Build the hunter.

```gdscript
class_name GradientHunter extends CharacterBody3D

var sample_buffer: Array = []  # ring buffer of (position, velocity)
@export var buffer_size: int = 32
```

The hunter remembers the last 32 observations. A small sliding window.

Record a sample.

```gdscript
func observe(learner: Node3D, delta: float) -> void:
    var current_pos: Vector3 = learner.global_position
    var current_vel: Vector3 = (current_pos - last_learner_pos) / delta
    sample_buffer.append({"pos": current_pos, "vel": current_vel})
    if sample_buffer.size() > buffer_size:
        sample_buffer.pop_front()
    last_learner_pos = current_pos
```

Each frame, record position and velocity. Older samples fall out of the buffer.

Fit a linear predictor.

```gdscript
func fit_predictor() -> float:
    if sample_buffer.size() < 2: return 0.0
    var num: float = 0.0
    var den: float = 0.0
    for i in range(sample_buffer.size() - 1):
        var delta: Vector3 = sample_buffer[i + 1].pos - sample_buffer[i].pos
        var vel: Vector3 = sample_buffer[i].vel
        num += delta.dot(vel)
        den += vel.length_squared()
    return num / den if den > 0.0001 else 0.0
```

Least-squares fit. Coefficient gives the best-fit relationship between velocity and position change.

Predict the next position.

```gdscript
func predict_next(learner: Node3D, coefficient: float) -> Vector3:
    return learner.global_position + learner.velocity * coefficient
```

Current position plus velocity times coefficient. The predictor's output moves as the learner moves.

Track loss over time.

```gdscript
var loss_history: Array = []

func update_loss(predicted: Vector3, actual: Vector3) -> void:
    var loss: float = predicted.distance_squared_to(actual)
    loss_history.append(loss)
    if loss_history.size() > 100: loss_history.pop_front()
```

Squared error between prediction and truth. Lower means the hunter is learning.

Pursue the predicted position.

```gdscript
func _physics_process(delta: float) -> void:
    var coefficient := fit_predictor()
    var predicted: Vector3 = predict_next(learner, coefficient)
    var direction: Vector3 = (predicted - global_position).normalized()
    velocity = direction * max_speed
    move_and_slide()
```

Move toward the predicted position rather than the current one. Anticipates the learner's movement.

Detect befriending via time in chamber.

```gdscript
var time_in_chamber: float = 0.0
@export var befriend_threshold: float = 45.0

func _process(delta: float) -> void:
    time_in_chamber += delta
    if time_in_chamber > befriend_threshold and not befriended:
        befriend()
        emit_signal("befriended")
```

After 45 seconds of engagement, the hunter befriends. Unlike other chambers, befriending here isn't about defeating the predictor — it's about enduring long enough.

You can now build the gradient_hunter, observe the learner, fit a predictor, pursue the predicted position, and track loss over time. The Machine Learning sequence closes with the chamber's argument that learning is relational rather than solitary.

Reset a population.

```gdscript
func reset_population(size: int, gene_count: int) -> Array:
    var p: Array = []
    for _i in size:
        var g := Genome.new()
        g.random_genome(gene_count)
        p.append(g)
    return p
```

Start fresh. Used when the current population has collapsed onto a local optimum.
