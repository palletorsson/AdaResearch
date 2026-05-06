# Chamber Random

Chaos shots scatter. The octapod cannot predict you. Build the chamber where entropy is the shared condition.

Declare the chaos shooter.

```gdscript
class_name ChaosShot
extends RigidBody3D

@export var base_speed: float = 6.0
@export var spread: float = 0.7
```

A projectile with base speed and scatter. The scatter is how unpredictable each shot is.

Fire with scatter.

```gdscript
func fire(origin: Vector3, dir: Vector3) -> void:
    var scatter := Vector3(
        randf_range(-spread, spread),
        randf_range(-spread * 0.3, spread * 0.3),
        randf_range(-spread, spread)
    )
    linear_velocity = (dir + scatter).normalized() * base_speed
    position = origin
```

Each shot gets its own scatter vector. Two consecutive shots never travel the same path.

Spawn the octapod enemy.

```gdscript
func spawn_octapod() -> void:
    var oct := preload("res://commons/artifacts/randomness/octapod.tscn").instantiate()
    oct.position = Vector3(0, 0.5, -5)
    add_child(oct)
    octapod = oct
```

The octapod sits at the arena's far end. It has its own chaos AI.

Move the octapod by drawing from noise.

```gdscript
func move_octapod(dt: float) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    octapod.position += Vector3(
        noise.get_noise_2d(t, 0.0),
        0.0,
        noise.get_noise_2d(t, 7.3)
    ) * dt * 3.0
```

Noise replaces targeting. The octapod drifts rather than chases. Neither side has a plan.

Detect hits.

```gdscript
func _on_shot_hit(shot: Node3D, target: Node3D) -> void:
    if target == octapod:
        octapod.chaos_health -= 10
        if octapod.chaos_health <= 0:
            octapod.befriend()
```

Hits accumulate. After enough, the octapod flips from adversary to friend. The win condition is persistence with chance.

Befriend the octapod.

```gdscript
func befriend() -> void:
    chaos_health = 0
    modulate = Color(0.7, 0.9, 0.7)
    friendly = true
    emit_signal("befriended")
```

Befriending colours the octapod green. The signal tells the chamber to open the exit.

Dispense the catalyst mode.

```gdscript
func dispense_catalyst() -> void:
    CatalystBracelet.enable_mode("chaos")
    bracelet_label.text = "chaos: accept the spread"
```

The catalyst mode is "chaos." It introduces scatter into every other bracelet interaction going forward.

Open the exit.

```gdscript
func _on_befriended() -> void:
    exit_door.unlock()
    CatalystBracelet.register_friend("octapod")
```

The exit unlocks on befriending. The octapod is recorded for later chambers. Randomness has become a friend.

You have closed the Randomness sequence. The remaining arc asks what randomness enables once it is a tool rather than a surprise.
<<</MAP>>>

Apply chaos scatter to subsequent chambers.

```gdscript
func apply_chaos_elsewhere() -> void:
    CatalystBracelet.set_global_scatter(0.3)
```

The catalyst mode carries scatter forward. Every future shot, placement, or bond will include a small amount of chance.

Chaos as a carried disposition, not as an event. The bracelet remembers.
