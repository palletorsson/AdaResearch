# Place the pivot

## Learning elements

- Mass moments
- Solving a constraint
- Assumptions of a model
- Balance versus stability

Follow one arm of the hanging mobile. The heavier side has less distance to the suspension. Its stillness was constructed from an arithmetic relation. The room’s truss and animated triangle offer other appearances of support without a load test.

## What you bring

Use masses from Forces, displacement and distance from Lines, functions and the drawn rods. We only need two familiar point markers to reconstruct one arm of the recursive mobile.

## Build inside the museum

Choose two positive masses and a total span. Calculate both distances from the pivot, then place the points. One nearby button changes the left mass while retaining the span.

Save `04_balance.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(16, 0, 7)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 04_balance.gd

<!-- student-code:04_balance.gd -->

```gdscript
extends "study.gd"
var masses := Vector2(1, 2)
var span := 2.0
var distances := Vector2.ZERO
var points: Array[Node3D] = []
var arm: MeshInstance3D
var wire: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    points = [make_point(Vector3.ZERO, false), make_point(Vector3.ZERO, false)]
    arm = rod()
    wire = rod()
    readout = caption("", Vector3(0, 2.4, 0))
    button("LEFT MASS", Vector3(0, 1, -0.8), change_mass)
    rebuild()

func change_mass() -> void:
    masses.x = 4.0 if masses.x == 1 else 1.0
    rebuild()

func rebuild() -> void:
    assert(masses.x > 0 and masses.y > 0 and span > 0)
    distances = Vector2(span * masses.y, span * masses.x) / (masses.x + masses.y)
    points[0].position = Vector3(-distances.x, 1.5, 0)
    points[1].position = Vector3(distances.y, 1.5, 0)
    join(arm, points[0].position, points[1].position)
    join(wire, Vector3(0, 1.5, 0), Vector3(0, 2.15, 0))
    readout.text = "%.1f kg / %.1f kg | arms %.3f / %.3f m\nmass x arm: %.3f / %.3f kg m\nCalculated pose; massless arm" % [
        masses.x, masses.y, distances.x, distances.y,
        masses.x * distances.x, masses.y * distances.y]
```

## Read the operation

For opposite vertical weights acting on a level, massless arm, equal torque magnitudes require m_left × g × d_left = m_right × g × d_right. The same g cancels. Also, the two arm lengths must add to span. Solving both relations gives d_left = span × m_right / total_mass and the opposite expression for d_right.

With masses 1 and 2 kg over two metres, the arms are 4/3 and 2/3 m. The heavier mass is closer to the pivot. The label shows mass × arm in kg m; multiply by g for torque magnitude in N m. Equal products express the selected static model.

The PointBody instances display the calculated places. The masses are numeric inputs, not a claim that these frozen markers are hanging under simulated forces. No joint, collision or settling solver determines this pose. That distinction also applies to the current mobile.

## Predict, then change

Predict the pivot’s relation to the points when the left mass changes from 1 to 4 kg. Press LEFT MASS and compare both products. Check that the arm lengths still add to two metres. Then give the sides equal mass and predict the midpoint.

## Build another experiment

Build a second two-point arm carrying masses 3 and 7 kg over 1.5 m. Display both distances and the residual m_left × d_left − m_right × d_right. It should be near zero. Construct an intentionally centred pivot as a comparison and show its nonzero residual. Explain why a zero residual in this model does not show that a disturbed physical mobile will return to rest.

## Carry onward

A calculated relation can construct a pose without waiting. In Annealing we return to a search where a useful next step may first make the objective worse.

## Model notes

The museum recurses over many arms and uses nominal disc masses. This lesson isolates one level. It omits rod and wire mass, friction, wind, and dynamic stability. The two points are a diagram of its inputs, not a new physics engine.
