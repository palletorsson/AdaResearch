# Vector Applied — Technical

Three stations apply vector operations to concrete tasks. A turret aims at a drone; a weather system superposes vector fields; a field visualiser renders vector fields as arrow glyphs.

## Turret Aiming

The turret computes a firing direction by subtracting its position from the target position, normalising, and comparing against its current barrel direction with a dot product.

```gdscript
class_name Turret extends Node3D

@export var fire_dot_threshold: float = 0.98
@export var turn_speed: float = 2.0  # radians per second

var target: Node3D

func _physics_process(delta: float) -> void:
    if target == null: return
    var to_target: Vector3 = target.global_position - global_position
    var desired_dir: Vector3 = to_target.normalized()
    var current_dir: Vector3 = -global_transform.basis.z  # barrel forward
    var alignment: float = current_dir.dot(desired_dir)
    if alignment > fire_dot_threshold:
        fire()
    else:
        rotate_toward(desired_dir, delta)

func rotate_toward(target_dir: Vector3, delta: float) -> void:
    var axis: Vector3 = -global_transform.basis.z.cross(target_dir)
    if axis.length() < 0.001:
        return
    var angle: float = asin(min(axis.length(), 1.0))
    rotate(axis.normalized(), min(angle, turn_speed * delta))
```

## Weather System

Three vector fields (gravity, wind, turbulence) are superposed. Test particles sample the combined field and integrate their positions forward.

```gdscript
class_name WeatherField extends Node3D

@export var gravity_strength: float = 1.0
@export var wind_vector: Vector3 = Vector3(1, 0, 0)
@export var turbulence_strength: float = 0.5

var noise := FastNoiseLite.new()

func field_at(p: Vector3) -> Vector3:
    var g := Vector3.DOWN * gravity_strength
    var w := wind_vector
    var turb := Vector3(
        noise.get_noise_3dv(p),
        noise.get_noise_3dv(p + Vector3(100, 0, 0)),
        noise.get_noise_3dv(p + Vector3(0, 100, 0))
    ) * turbulence_strength
    return g + w + turb
```

## Field Visualiser

A cubic grid of arrow glyphs fills a volume. Each glyph's length and direction reflect the field at its position.

```gdscript
func populate_grid(field_func: Callable, resolution: int = 8) -> void:
    for ix in range(resolution):
        for iy in range(resolution):
            for iz in range(resolution):
                var p := Vector3(ix, iy, iz) / resolution * grid_extent
                var v: Vector3 = field_func.call(p)
                spawn_glyph(p, v)
```

## Complexity

The turret is O(1) per frame. The weather system is O(N) for N particles. The field visualiser is O(R³) for resolution R — at R=16, that is 4096 glyphs, which is at the edge of comfortable real-time rendering.

Within the sequence, Applied converts the operations into practical machinery. VectorAdvanced will next extend the machinery into embodied action.

## Turret Refinements

Real aiming is harder than the map's simplified version. A moving target requires leading — firing at where the target will be rather than where it is. Lead time depends on projectile speed and target velocity.

```gdscript
func lead_target(target_pos: Vector3, target_vel: Vector3, projectile_speed: float) -> Vector3:
    # Solve quadratic for intercept time
    var to_target: Vector3 = target_pos - global_position
    var a: float = target_vel.dot(target_vel) - projectile_speed * projectile_speed
    var b: float = 2.0 * target_vel.dot(to_target)
    var c: float = to_target.dot(to_target)
    var discriminant: float = b * b - 4 * a * c
    if discriminant < 0.0: return to_target.normalized()
    var t: float = (-b - sqrt(discriminant)) / (2 * a)
    return (target_pos + target_vel * t - global_position).normalized()
```

The quadratic can have zero solutions (the target moves faster than the projectile and cannot be intercepted), one solution (tangent), or two (the earlier intercept is usually desired).

## Field Composition

Superposing multiple vector fields is associative and commutative — the result does not depend on the order of addition. Scalar-valued fields (temperature, pressure) and vector-valued fields (velocity, force) compose identically under linear superposition.

## Turbulence Generation

Production-quality turbulence uses layered noise at multiple frequencies. The map's turbulence is single-frequency for simplicity, which produces uniform-sized eddies. Layered (fractal) noise produces eddies at all scales — the signature of real turbulent flow.

```gdscript
func fractal_turbulence(p: Vector3, octaves: int = 4) -> Vector3:
    var result := Vector3.ZERO
    var amplitude: float = 1.0
    var frequency: float = 1.0
    for i in range(octaves):
        var noise_sample := sample_noise_vector(p * frequency) * amplitude
        result += noise_sample
        amplitude *= 0.5
        frequency *= 2.0
    return result
```

## GPU Field Storage

Large field grids are best stored as 3D textures on the GPU. Trilinear interpolation is hardware-accelerated — a single texture lookup returns the interpolated field value. The CPU-side field grid the map uses trades some interpolation cost for debugging clarity.

## Field Divergence

A vector field's divergence measures how much it pushes material outward from each point. Positive divergence is a source; negative divergence is a sink. The divergence theorem relates volume integrals of divergence to surface integrals of the field, which is the core of fluid simulation and electromagnetic theory.
