# Primitives Portals - Technical Tutorial

## Portal as Transition System

Portals are **spatial teleportation** - instant movement between locations:

```gdscript
# Basic portal implementation
class_name Portal extends Area3D

@export var destination: Portal  # Connected portal

func _on_body_entered(body):
    if body is CharacterBody3D and destination:
        teleport_to_destination(body)

func teleport_to_destination(body):
    body.global_position = destination.global_position
    # Preserve velocity/momentum if needed
```

Portals create **non-Euclidean space** - adjacent in experience, distant in coordinates.

## Approximating Circles with Polygons

From map description's reference to "increasing rings approaching π":

```gdscript
# Circle approximation through regular polygons
func approximate_circle(sides: int, radius: float) -> PackedVector3Array:
    var points = PackedVector3Array()

    for i in range(sides):
        var angle = (i / float(sides)) * TAU  # TAU = 2π
        var x = cos(angle) * radius
        var z = sin(angle) * radius
        points.append(Vector3(x, 0, z))

    return points

# As sides increase, polygon approaches circle
var triangle = approximate_circle(3, 1.0)    # Very angular
var hexagon = approximate_circle(6, 1.0)     # Less angular
var polygon_64 = approximate_circle(64, 1.0) # Nearly smooth

# But never truly circular - always has corners
```

This demonstrates **asymptotic approximation** - approaching limit without reaching it.

## Archimedes' Method: Bounding π Through Polygons

Archimedes (c. 250 BCE) approximated π by inscribing and circumscribing regular polygons around a circle, creating upper and lower bounds that tighten as sides increase.

```gdscript
# Archimedes' method: π ≈ perimeter / (2 * radius)
func estimate_pi(sides: int) -> float:
    var radius = 1.0
    var angle_step = TAU / sides
    var perimeter = 0.0

    for i in range(sides):
        var angle1 = i * angle_step
        var angle2 = (i + 1) * angle_step

        var p1 = Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
        var p2 = Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)

        perimeter += p1.distance_to(p2)

    return perimeter / (2.0 * radius)

# Archimedes' actual progression (using inscribed polygons):
print(estimate_pi(6))    # ~3.0 (hexagon) - very rough
print(estimate_pi(12))   # ~3.106 (dodecagon) - getting closer
print(estimate_pi(24))   # ~3.133 (24-gon)
print(estimate_pi(48))   # ~3.1395 (48-gon)
print(estimate_pi(96))   # ~3.14103 (96-gon) - Archimedes stopped here
print(estimate_pi(192))  # ~3.14145
print(estimate_pi(1000)) # ~3.14159... (very close to π)
```

**Archimedes' achievement**: Using only geometry and logic (no trigonometry, no calculus), he proved:
**3 + 10/71 < π < 3 + 1/7** (approximately 3.1408 < π < 3.1429)

**The endlessness**: More sides = better approximation, but **never exact** with any finite polygon. The circle remains infinitely beyond reach. You can always double the sides, halve the error, but π itself is **irrational** - it cannot be captured by any finite process.

## Key Takeaway

The map stages **Archimedes' infinite approximation** - the method of approaching π by increasing polygon sides. This reveals the fundamental truth of discrete geometry:

**The circle is endless** - it can be approached through finite polygons (hexagon → 12-gon → 24-gon → 96-gon → ...) but never reached. Each doubling of sides gets closer, but π remains infinitely distant.

Portals represent **transitions** between discrete and continuous. The 40-row corridor embodies the long walk of approximation - approaching but not arriving until you arbitrarily stop.

**Archimedes discovered**: You can endlessly refine your approximation of the circle, but the circle itself (requiring π, requiring infinity) lies forever beyond discrete geometry's reach.
