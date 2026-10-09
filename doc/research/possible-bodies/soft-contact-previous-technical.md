# Twelve more obstacle tests — an empirical catalog of collision edge cases

Part 1 introduced three collision modes: wrapping, compression, sliding. Part 2 expands the catalog to twelve scenarios, each isolating a different failure mode, geometry class, or behavioral edge case of the spring-mass system. The gallery format treats soft body simulation not as a solved problem but as an empirical investigation requiring systematic observation across conditions.

## The Gallery Architecture

The softbody_gallery_part2 artifact arranges twelve obstacle-soft body pairings across a flat arena. Each pairing is spatially separated, allowing the learner to observe one scenario at a time or compare adjacent ones. The structure is 20x30 grid cells — generous spacing to prevent cross-contamination between test zones.

```gdscript
# Gallery layout: 12 stations arranged in a 4x3 grid
# Each station contains:
#   - One soft body (cube, sphere, capsule, or custom mesh)
#   - One obstacle configuration (static or dynamic)
#   - Initial conditions that trigger the target behavior
var station_spacing := 6.0  # meters between station centers
var grid_cols := 4
var grid_rows := 3
```

## Edge Cases in Collision Response

### Narrow Gap Compression

A soft body forced through a gap narrower than its rest diameter. The gap width determines whether the body can pass at all. Below a critical width (approximately rest_diameter * (1 - 1/k)), the springs cannot compress enough and the body wedges. Above critical width, the body squeezes through, elongating along the gap axis.

```gdscript
# Critical gap width depends on stiffness:
# gap_min ≈ rest_diameter * (1.0 - max_compression_ratio)
# For k = 50: max_compression ≈ 0.3 → gap_min ≈ 0.7 * diameter
# For k = 200: max_compression ≈ 0.1 → gap_min ≈ 0.9 * diameter
# Stiffer bodies need wider gaps — rigidity costs access
```

This is the most directly pedagogical scenario. The learner sees that stiffness determines not just deformation magnitude but navigability — what spaces the body can and cannot access.

### Sharp Edge Contact

A soft body dropped onto a thin edge (a narrow wall or beam). The edge concentrates contact force into a small region, creating extreme local deformation. Vertices near the edge compress deeply while vertices far from the edge barely respond. The force gradient across the body reveals the spring network's propagation speed — how quickly local contact becomes global deformation.

```gdscript
# Sharp edge creates singular contact:
# Contact area ≈ 1-2 vertices
# Local force = body_weight / contact_vertices
# With 8 vertices: F_local ≈ 4x F_distributed
# Risk: vertex tunneling through thin obstacle if delta_t too large
```

The sharp edge also tests collision detection robustness. A vertex moving at high speed can pass through a thin obstacle between frames — the tunneling problem. Continuous collision detection (CCD) or minimum contact thickness prevents this but adds computational cost.

### Multi-Point Contact on Curved Surfaces

A soft body resting on a sphere or cylinder. The contact surface is curved, so the body must conform to a non-planar geometry. Vertices in contact press against different surface normals, receiving push-back in different directions. The body wraps around the curve, each vertex independently resolving its collision against the local normal.

```gdscript
func resolve_sphere_collision_soft(point: MassPoint, sphere_center: Vector3,
                                     sphere_radius: float) -> void:
    var to_point := point.position - sphere_center
    var distance := to_point.length()
    if distance < sphere_radius:
        var normal := to_point.normalized()
        point.position = sphere_center + normal * sphere_radius
        # Reflect implicit velocity
        var vel := point.position - point.old_position
        var normal_vel := normal * vel.dot(normal)
        point.old_position = point.position - (vel - normal_vel * 1.5)
```

The wrap angle depends on the body's weight, the sphere's radius, and the spring stiffness. Heavy, soft bodies wrap further. Light, stiff bodies perch on top. The contact area — the number of vertices touching the sphere — is a direct measure of compliance.

### Soft-on-Soft Collision

Two soft bodies colliding with each other. Neither is rigid. Both deform. The collision response must move vertices of both bodies, with the correction split according to mass ratios:

```gdscript
func resolve_soft_soft_collision(point_a: MassPoint, point_b: MassPoint,
                                  min_distance: float) -> void:
    var delta := point_a.position - point_b.position
    var dist := delta.length()
    if dist < min_distance and dist > 0.0001:
        var overlap := min_distance - dist
        var correction := delta.normalized() * overlap
        var total_mass := point_a.mass + point_b.mass
        point_a.position += correction * (point_b.mass / total_mass)
        point_b.position -= correction * (point_a.mass / total_mass)
```

Mass-weighted correction ensures that lighter bodies move more and heavier bodies move less. Two equal-mass soft bodies deform symmetrically. A heavy body barely deforms while a light body squishes dramatically. This is the first scenario where both collision partners yield.

### Dynamic Obstacle Timing

A soft body on a platform that drops away. The body, suddenly unsupported, falls and must negotiate the landing surface below. The height of the drop determines impact velocity and therefore deformation severity. The gallery includes drops from 1x, 2x, and 3x the body diameter, showing how deformation scales with impact energy.

```gdscript
# Impact velocity from drop height h:
# v = sqrt(2 * g * h)
# Kinetic energy at impact:
# KE = 0.5 * m * v^2 = m * g * h
# Deformation depth ≈ KE / (k_effective * contact_area)
```

### Constrained Passage

A soft body pushed through an L-shaped channel or maze. The body must deform around corners, compress through narrows, and reform in wider sections. This tests the spring network's ability to maintain connectivity through compound deformation — the body changes shape multiple times in sequence without losing structural integrity.

## Configurable Segments and Rounded Geometry

The pick_up_cube and grab_long_stick artifacts in the gallery use configurable geometry — the number of segments, the rounding radius, the mesh resolution can vary between scenarios. Rounded geometry produces smoother collision response because normals vary gradually rather than discontinuously at edges.

```gdscript
# Rounded cube: sphere-swept box
# Corner radius r → collision normals smooth across transitions
# At r = 0: sharp corners, discontinuous normals, noisy collision
# At r = 0.3: smooth corners, continuous normals, stable collision
# At r = 0.5 (half edge length): sphere, maximally smooth
```

The gallery includes both sharp and rounded geometry variants of the same scenario, allowing direct comparison of collision stability. Rounded soft bodies stack more reliably, slide more predictably, and produce fewer jittering artifacts than sharp-edged ones.

## Empirical Investigation as Method

The gallery's pedagogical stance is deliberate: twelve scenarios is an admission that soft body behavior cannot be fully predicted from first principles. The equations are known (Hooke's law, Verlet integration, collision projection), but the emergent behavior of a spring network with hundreds of constraints interacting with complex geometry produces outcomes that must be observed rather than computed by hand.

Each scenario isolates one variable:
1. Gap width (compression limit)
2. Edge sharpness (force concentration)
3. Surface curvature (multi-normal contact)
4. Bilateral symmetry (soft-soft collision)
5. Drop height (impact energy)
6.

Channel geometry (sequential deformation)
7. Rounded vs sharp edges (collision stability)
8. Mass ratio (asymmetric collision)
9. Stiffness mismatch (different materials)
10. Friction coefficient (grip vs slide)
11. Velocity at contact (rotational collision)
12. Constraint count (under-constrained bodies)

The gallery is a controlled experiment. The variable is the obstacle. The constant is the soft body system. The measurement is the visible deformation. The method is observation.
