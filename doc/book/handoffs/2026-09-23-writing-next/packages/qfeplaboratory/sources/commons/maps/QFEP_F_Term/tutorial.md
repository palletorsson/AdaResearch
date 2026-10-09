# F Term

F is free energy — the prediction error that every adaptive system tries to minimize. Build a room where minimizing F is both the task and the trap.

Declare the F meter.

```gdscript
class_name FMeter
extends Node3D

@export var prediction: float = 0.0
@export var observation: float = 0.0

func f_value() -> float:
    return abs(prediction - observation)
```

F is the distance between prediction and observation. The meter reads the absolute difference. Other formulations add log terms; this one is the floor model.

Crystallize particles to minimize F.

```gdscript
func settle_toward(target: Vector3) -> void:
    for particle in particles:
        var d := target - particle.position
        particle.linear_velocity += d * settle_strength
```

Particles drift toward a lattice point. The lattice is the prediction; the particle position is the observation. Over time, the cluster becomes a crystal.

Update F from the cluster state.

```gdscript
func update_f() -> void:
    var total := 0.0
    for particle in particles:
        total += particle.position.distance_to(target_for(particle))
    prediction = 0.0
    observation = total / particles.size()
```

Average distance from lattice gives the observation. Prediction is zero — the lattice is the expectation. F falls as the crystal forms.

Show the dark room.

```gdscript
func enter_dark_room() -> void:
    particles.clear()
    environment.ambient_light_energy = 0.0
    status_label.text = "F = 0.000  (nothing moves)"
```

A sealed room with no particles. F is zero.

Nothing surprises the system because nothing happens. Perfect prediction, no life.

Gate progress on F curiosity.

```gdscript
func _on_dark_room_timer_timeout() -> void:
    if time_in_dark > 3.0:
        prompt.text = "F = 0 is also a grave."
        door.unlock()
```

The door only opens after the learner has stood in the zero-F room long enough to feel it. The prompt writes the lesson. F-minimization without entropy is closure.

Solve the snap puzzle to reduce F.

```gdscript
func _on_piece_snapped(piece: Node3D) -> void:
    score += 1
    prediction = float(score) / float(total_pieces)
    observation = 1.0
    meter.update_visual(f_value())
```

Each snapped piece reduces the gap between prediction and observation. The meter visibly drops. The learner's body performs the gradient descent.

Celebrate minimization and warn against it.

```gdscript
func on_puzzle_solved() -> void:
    play_chime()
    warning.text = "Beautiful. Now notice: nothing new can happen here."
```

The chime is the reward; the warning is the lesson. Closed puzzles are local optima. The F room tells the truth about both.

You have built the F side of the dialectic. The next map, E Term, introduces the counterweight: entropy as possibility.
<<</MAP>>>

Throttle the settle strength.

```gdscript
func throttle_settle(meter: float) -> void:
    settle_strength = lerp(0.2, 1.5, clamp(meter, 0.0, 1.0))
```

Faster settle means sharper crystallization. A slower one lets the learner watch F fall gradually toward zero.

Record the descent curve.

```gdscript
func log_f_descent(sample_rate: float) -> void:
    if Time.get_ticks_msec() - last_log < sample_rate: return
    f_history.append(f_value())
    last_log = Time.get_ticks_msec()
```

Every sample stores a data point. The history line shows the gradient. F-minimization becomes a trace on a chart.
