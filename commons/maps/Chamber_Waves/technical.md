# Chamber Waves — Technical

The chamber contains a helix_catalyst that fires spiralling projectiles at a chosen frequency, and a waterbomb creature that bounces at its own frequency. The science screen plots both frequencies and draws their product.

```gdscript
class_name HelixCatalyst extends Node3D

@export var frequency: float = 2.0   # Hz
@export var helix_radius: float = 0.3
@export var projectile_speed: float = 8.0

func fire(direction: Vector3) -> void:
    var projectile := HELIX_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.direction = direction
    projectile.frequency = frequency
    get_tree().root.add_child(projectile)

class_name HelixProjectile extends Node3D

var direction: Vector3
var frequency: float
var age: float = 0.0
var speed: float = 8.0

func _process(delta: float) -> void:
    age += delta
    var forward_distance: float = speed * age
    var helix_offset: Vector3 = Vector3(
        cos(frequency * age * TAU) * 0.3,
        sin(frequency * age * TAU) * 0.3,
        0
    )
    global_position = start_position + direction * forward_distance + helix_offset
```

## Waterbomb Creature

The waterbomb bounces around the chamber at a fixed frequency; its motion follows a damped harmonic oscillator.

```gdscript
class_name WaterbombCreature extends RigidBody3D

@export var bounce_frequency: float = 2.0  # Hz
@export var bounce_amplitude: float = 2.0

var phase: float = 0.0

func _physics_process(delta: float) -> void:
    phase += delta * bounce_frequency * TAU
    # Vertical oscillation driven directly
    var target_y: float = rest_position.y + bounce_amplitude * abs(sin(phase))
    var displacement: float = target_y - global_position.y
    linear_velocity.y += displacement * 5.0 * delta
```

## Resonance Detection

The science screen compares the catalyst's frequency with the waterbomb's, computing their product as a live waveform.

```gdscript
class_name ResonanceScreen extends Node3D

func update_display(catalyst_freq: float, creature_freq: float) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    var catalyst_wave: float = sin(catalyst_freq * t * TAU)
    var creature_wave: float = sin(creature_freq * t * TAU)
    var product: float = catalyst_wave * creature_wave
    var frequency_diff: float = abs(catalyst_freq - creature_freq)
    var alignment: float = 1.0 / (1.0 + frequency_diff)
    update_plot(catalyst_wave, creature_wave, product)
    update_alignment_indicator(alignment)
```

When catalyst_freq matches creature_freq, the product becomes sin²(θ) — always positive, pulsing at twice the base frequency. When they are far apart, the product produces a beating pattern.

## Befriending

Sustained resonance over several seconds causes the waterbomb to transition to a befriended state.

```gdscript
var sustained_resonance: float = 0.0
@export var befriend_threshold: float = 3.0  # seconds

func _process(delta: float) -> void:
    if compute_alignment() > 0.9:
        sustained_resonance += delta
    else:
        sustained_resonance = max(0.0, sustained_resonance - delta)
    if sustained_resonance > befriend_threshold:
        befriend()
```

## Complexity

Projectile updates are O(active projectiles) per frame. The science screen's FFT-like analysis is O(1) with precomputed wave values. The chamber runs well within budget at any reasonable projectile count.

Within the sequence, Chamber_Waves closes Wavefunctions with resonance as mutual attention. The chamber hands the learner back to the Lab with the waveform catalyst in their kit.

## Helix Projectile Geometry

The helix projectile's position at time t is: base_position + forward_direction * speed * t + (cos(f*t*TAU) * radius) * right + (sin(f*t*TAU) * radius) * up. The right and up vectors are derived from the forward direction and a reference up vector using cross products.

```gdscript
func helix_position(start: Vector3, forward: Vector3, speed: float, radius: float, frequency: float, age: float) -> Vector3:
    var right := forward.cross(Vector3.UP).normalized()
    var up := right.cross(forward).normalized()
    var helix_angle: float = frequency * age * TAU
    return start + forward * speed * age + right * cos(helix_angle) * radius + up * sin(helix_angle) * radius
```

## Waterbomb Bounce Physics

The waterbomb uses a simplified bounce that treats collision as an elastic rebound with gravity between bounces. The bounce frequency is set to match the catalyst's tuning target.

```gdscript
func _physics_process(delta: float) -> void:
    linear_velocity.y += -9.81 * delta
    global_position += linear_velocity * delta
    if global_position.y < floor_y:
        global_position.y = floor_y
        linear_velocity.y = abs(linear_velocity.y) * restitution
        # Correct velocity magnitude to maintain frequency
        var period: float = 1.0 / bounce_frequency
        var required_vy: float = 9.81 * period / 4.0  # from kinematic analysis
        linear_velocity.y = max(linear_velocity.y, required_vy)
```

Direct velocity correction is pedagogically motivated — it keeps the creature's frequency constant so the learner can focus on tuning the catalyst.

## Resonance Condition

Perfect resonance requires frequency match and phase alignment. The chamber tests both: frequency match is computed from the difference of the two frequencies, and phase alignment is computed from the instantaneous dot product of the two waveforms.

```gdscript
func resonance_score(catalyst_freq: float, creature_freq: float, time: float) -> float:
    var freq_diff: float = abs(catalyst_freq - creature_freq)
    var freq_score: float = 1.0 / (1.0 + freq_diff * freq_diff)
    var catalyst_wave: float = sin(catalyst_freq * time * TAU)
    var creature_wave: float = sin(creature_freq * time * TAU)
    var phase_score: float = (catalyst_wave * creature_wave + 1.0) / 2.0
    return freq_score * phase_score
```

## Beat Frequency

When frequencies differ slightly, the combined signal produces beats at the difference frequency. Two tones at 440 Hz and 442 Hz produce a 2 Hz beating envelope. The chamber's science screen visualises this directly: the product waveform oscillates at the sum frequency inside an envelope at the difference frequency.

## Befriending Persistence

Once befriended, the waterbomb follows the learner to subsequent chambers. The befriending state is saved in the global game state and recovered across sessions.

```gdscript
func save_befriending_state() -> void:
    var save := get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature("waterbomb")
```

## Science Screen Log

Every resonance event (frequency match sustained for more than one second) is logged to the science screen. The log accumulates across chamber visits and becomes part of the learner's historical record.
