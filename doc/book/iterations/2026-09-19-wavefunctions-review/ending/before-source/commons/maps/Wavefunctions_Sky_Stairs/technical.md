# Wavefunctions Sky Stairs — Technical

The map generates three parallel helical staircases whose step heights follow sin, cos, and a higher-frequency harmonic.

```gdscript
class_name SineStaircase extends Node3D

@export var function_type: String = "sin"  # "sin", "cos", "harmonic"
@export var total_height: float = 30.0
@export var radius: float = 4.0
@export var angular_rate: float = 0.5  # revolutions per unit height
@export var step_count: int = 80

func build() -> void:
    var step_scene: PackedScene = preload("res://commons/interactables/helix_step.tscn")
    for i in range(step_count):
        var height_fraction: float = float(i) / step_count
        var y: float = height_fraction * total_height
        var angle: float = height_fraction * angular_rate * TAU
        var step_height: float = step_height_for(function_type, height_fraction)
        var step := step_scene.instantiate()
        step.position = Vector3(
            cos(angle) * radius,
            y + step_height,
            sin(angle) * radius
        )
        add_child(step)

func step_height_for(type: String, t: float) -> float:
    var amplitude: float = 0.3
    match type:
        "sin": return amplitude * sin(t * TAU * 3)
        "cos": return amplitude * cos(t * TAU * 3)
        "harmonic": return amplitude * sin(t * TAU * 6) * 0.5
    return 0.0
```

## Phase Relationship

Sin and cos staircases are offset by 90° of phase. At a given angle around the helix, the sin staircase and cos staircase have step heights that are 90° out of phase: when sin is at its peak, cos is at zero, and vice versa.

```gdscript
func phase_offset_at(angle: float) -> float:
    var sin_height: float = sin(angle)
    var cos_height: float = cos(angle)
    return sin_height - cos_height  # visible elevation difference
```

## Floating Cube Fields

Fields of small cubes drift at different altitudes around the tower. Their density samples the wave equation at that height.

```gdscript
class_name FloatingField extends Node3D

@export var altitude_range: Vector2 = Vector2(5, 25)
@export var cube_count: int = 200

func spawn_cubes() -> void:
    for i in range(cube_count):
        var altitude: float = randf_range(altitude_range.x, altitude_range.y)
        var density: float = abs(sin(altitude)) * 0.5 + 0.5
        if randf() > density: continue
        var p := random_position_at_altitude(altitude)
        spawn_cube(p)
```

## Height Reference Panel

A reference panel at the landing displays the learner's current altitude as a value of sin(angle), where angle is the distance travelled around the helix.

```gdscript
func update_altitude_readout() -> void:
    var p := learner.global_position
    var angle: float = atan2(p.z, p.x)
    var altitude: float = p.y
    var wave_value: float = sin(altitude / total_height * TAU * 3)
    readout_label.text = "Altitude: %.1f · Wave: %.2f" % [altitude, wave_value]
```

## Complexity

Each staircase is O(step_count) at build time. Total geometry across three staircases is about 240 steps. The floating cube fields are O(cube_count); the map uses 200 cubes per field, rendered via MultiMeshInstance3D for efficiency.

Within the sequence, Sky_Stairs returns oscillation to embodied experience. TrigWalkingPath will next put sin and cos walks next to each other.

## Helical Geometry

A helix is parameterised by its pitch (vertical distance per revolution) and radius. For a helix with pitch P and radius R, arc length per revolution is sqrt((2πR)² + P²). The map's default helix has R=4 and P=20, giving arc length ~28.6 per revolution.

## Step Placement

Each step is placed tangent to the helix, so its front face is perpendicular to the direction of travel. Computing the tangent requires the derivative of the helical parameterisation:

```gdscript
func helix_tangent(t: float, radius: float, pitch: float, angular_rate: float) -> Vector3:
    var dx: float = -angular_rate * TAU * radius * sin(angular_rate * TAU * t)
    var dy: float = pitch
    var dz: float = angular_rate * TAU * radius * cos(angular_rate * TAU * t)
    return Vector3(dx, dy, dz).normalized()
```

The step's orientation basis is built from this tangent plus an up vector (global UP projected onto the plane perpendicular to the tangent).

## Safety Railings

Real staircases need railings; VR staircases need them more because a fall at height is immersion-breaking if handled poorly. The map adds railings whose height is standardised (waist-high from step surface) but whose shape follows the helix.

```gdscript
func add_railing(step_position: Vector3, tangent: Vector3) -> void:
    var railing := RAILING_SCENE.instantiate()
    railing.global_position = step_position + Vector3(0, 1.0, 0)
    railing.look_at(step_position + tangent, Vector3.UP)
    add_child(railing)
```

## Cube Field Density

The floating cube fields' density is sampled from a wave equation: density(altitude) = (sin(altitude * k) + 1) / 2, producing alternating bands of high and low density. At low wavelength, the cubes form thick bands; at high wavelength, finer stratification.

```gdscript
func density_at_altitude(altitude: float, wavelength: float) -> float:
    var k: float = TAU / wavelength
    return (sin(altitude * k) + 1.0) / 2.0
```

Cubes are spawned via rejection sampling: candidate positions are proposed at random altitudes, and each candidate is accepted with probability equal to the density at its altitude.

## Performance

The tower contains about 300 steps across three staircases and 600 cubes across multiple altitude fields. Rendering uses MultiMeshInstance3D for the cubes and instanced meshes for the steps, keeping draw calls below 50.
