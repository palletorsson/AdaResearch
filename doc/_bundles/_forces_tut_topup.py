import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {
'VectorFoundations': """

Scale a vector.

```gdscript
func scale_vector(v: Vector3, s: float) -> Vector3:
    return v * s
```

Positive scale preserves direction, negative reverses it. Scale of zero collapses the vector to the origin.

Normalise any vector to unit length.

```gdscript
func safe_normalise(v: Vector3) -> Vector3:
    if v.length() < 0.0001: return Vector3.ZERO
    return v.normalized()
```

Guard against zero-length inputs to avoid NaN. The result is either a unit vector or the zero vector.
""",
'VectorOperations': """

Compute the angle between two vectors in degrees.

```gdscript
func angle_degrees(a: Vector3, b: Vector3) -> float:
    var cos_theta: float = clamp(a.dot(b) / (a.length() * b.length()), -1.0, 1.0)
    return rad_to_deg(acos(cos_theta))
```

Clamp the cosine to [-1, 1] before acos to avoid NaN from floating-point error. The result is in degrees.

Test perpendicularity.

```gdscript
func are_perpendicular(a: Vector3, b: Vector3, tolerance: float = 0.001) -> bool:
    return abs(a.dot(b)) < tolerance
```

Dot product is zero iff the vectors are perpendicular. Use tolerance for floating-point comparison.
""",
'VectorAdvanced': """

Wrap a small orbit around an attractor.

```gdscript
func wrap_orbit(satellite: RigidBody3D, attractor: Vector3, orbital_speed: float) -> void:
    var radial: Vector3 = (satellite.global_position - attractor).normalized()
    var tangent: Vector3 = radial.cross(Vector3.UP).normalized()
    satellite.linear_velocity = tangent * orbital_speed
```

The tangent is perpendicular to the radial direction. Setting velocity along the tangent produces circular motion.

Check whether a throw will clear a target.

```gdscript
func will_throw_reach(start: Vector3, target: Vector3, throw_speed: float) -> bool:
    var horizontal: Vector3 = Vector3(target.x - start.x, 0, target.z - start.z)
    var vertical: float = target.y - start.y
    var range_max: float = throw_speed * throw_speed / 9.81
    return horizontal.length() <= range_max
```

Maximum range is v²/g at 45°. Any target within the range can be reached with some launch angle.
""",
'ForcesFoundations': """

Compute projectile range at 45°.

```gdscript
func max_range(muzzle_velocity: float, gravity: float = 9.81) -> float:
    return muzzle_velocity * muzzle_velocity / gravity
```

The closed-form range formula for 45° launch angle. Higher or lower angles reduce range.
""",
'ForcesComposition': """

Check that net force is zero (equilibrium).

```gdscript
func is_in_equilibrium(forces: Array, tolerance: float = 0.01) -> bool:
    var net: Vector3 = Vector3.ZERO
    for f in forces: net += f
    return net.length() < tolerance
```

The body is at rest (or moving at constant velocity) iff the net force is zero. Static structures rely on this balance.
""",
'ForcesArena': """

Track score across arenas.

```gdscript
var arena_scores: Dictionary = {}  # arena_id -> score

func submit_score(arena_id: String, score: int) -> void:
    arena_scores[arena_id] = max(arena_scores.get(arena_id, 0), score)

func total_score() -> int:
    return arena_scores.values().reduce(func(a, b): return a + b, 0)
```

Highest score per arena is kept. The total across three arenas becomes the learner's sequence-level score.
""",
}

for m, a in adds.items():
    p = Path('commons/maps/' + m + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
