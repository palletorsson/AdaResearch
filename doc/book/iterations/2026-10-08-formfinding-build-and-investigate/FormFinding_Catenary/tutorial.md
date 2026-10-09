# Draw between the points

## Learning elements

- Curve3D
- Endpoints and handles
- Sampling a curve
- Parameters versus simulated forces

Move a point on the cable builder. The hanging line follows immediately. Its shape is drafted by handles; it does not wait for gravity to settle a chain. Walk on to the formula-built catenoid and laundry curves before deciding what their resemblance establishes.

## What you bring

Bring the two held points from Lines and Coordinates, local/world conversion, and the loop that joined neighbouring positions in Trace. Here those familiar points become endpoints of a curved span.

## Build inside the museum

Make one span using the same handle rule as the existing cable builder. Keep two PointBody instances and 24 thin cylinders. The hand supplies endpoints; the script resamples the span as they move.

Save `02_curve.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(16, 0, 7)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 02_curve.gd

<!-- student-code:02_curve.gd -->

```gdscript
extends "study.gd"
var sag := 0.5
var ends: Array[Node3D] = []
var segments: Array[MeshInstance3D] = []
var curve := Curve3D.new()
var readout: Label3D

func _ready() -> void:
    ends = [make_point(Vector3(-1, 1.6, 0)), make_point(Vector3(1, 1.6, 0))]
    for i in 24:
        segments.append(rod())
    readout = caption("", Vector3(0, 2.15, 0))
    button("SAG", Vector3(0, 1, -0.8), change_sag)
    rebuild()

func change_sag() -> void:
    sag = 0.8 if sag < 0.8 else 0.0
    rebuild()

func _process(_delta: float) -> void:
    rebuild()

func rebuild() -> void:
    var a := to_local(ends[0].global_position)
    var b := to_local(ends[1].global_position)
    var span := a.distance_to(b)
    var drop := Vector3.DOWN * sag * span * 0.5
    curve.clear_points()
    curve.add_point(a, Vector3.ZERO, (b - a) * 0.3 + drop)
    curve.add_point(b, (a - b) * 0.3 + drop, Vector3.ZERO)
    for i in segments.size():
        var t := float(i) / segments.size()
        var next_t := float(i + 1) / segments.size()
        join(segments[i], curve.sample(0, t), curve.sample(0, next_t))
    readout.text = "DRAWN SAG %.2f | span %.2f m\nMove either point" % [sag, span]
```

## Read the operation

Curve3D stores endpoints with incoming and outgoing handles. A handle is an offset from its endpoint. The outgoing handle follows 30% of the displacement to the other point; the incoming handle points 30% back. Both also move down by sag × span × 0.5. This is the production artifact’s chosen Bézier construction.

curve.sample(0, t) evaluates the first span at a parameter between 0 and 1. The loop joins neighbouring evaluations. Equal parameter intervals need not have equal spatial length. to_local converts each held point’s world position into the study’s frame before constructing the curve. Local DOWN remains the study’s down; keep the study upright at unit scale.

Sag is a dimensionless control of handle depth. It is not the midpoint’s drop and not the cable’s weight. With level endpoints two metres apart and sag 0.5, both handles drop 0.5 m and the midpoint drops 0.375 m. Zero sag gives a straight span. The script evaluates a shape every frame; it does not integrate velocity or conserve cable length.

## Predict, then change

Before pressing SAG, predict which points will stay fixed. The button alternates 0.8 and 0 after the initial 0.5 setting. At sag 0, move an endpoint in height and depth: the line should still join both points. Bring the endpoints together; the zero-length drawing should disappear without an invalid direction.

## Build another experiment

Build two neighbouring spans from three held points. The middle point is shared: moving it must change both spans without creating two copies of the joint. Retain the same per-span handle rule. Compare the two sag depths when the spans have different lengths. You will need another set of rods, a loop over adjacent endpoint pairs, and the correct Curve3D span index for each sample.

## Carry onward

A shape can be determined directly from controls. In Relaxation, keep endpoints but replace the drafted interior with positions that repeatedly correct their relationships.

## Model notes

The museum cable has four control points and a swept tube. The study uses two and thin cylinders. Neither is a physical catenary solver. The evaluated cosh curves and surfaces elsewhere in the hall are separate constructions.
