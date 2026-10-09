# Choose a useful limit

## Learning elements

- A closed neighbour loop
- Error in a stated unit
- A while loop with a stopping rule
- A finite work budget

## In the museum

A circle's perimeter offers a question that a finite polygon can answer approximately. How many sides are enough for a chosen measurement? The hall's encounters with limits give that question a wider setting; our program makes one bounded decision visible.

Reuse Circle.make from Columns and LineSkin from Lines. There is no new shape factory. Add the lengths between neighbouring samples, including the last sample back to the first.

## Make this study

Attach lesson.gd to a unit-scale Node3D named LimitStudy in this museum hall. The polygon is drawn horizontally at hand height. TOLERANCE is an absolute perimeter error in metres; BUDGET is the maximum number of sides this run may use.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Circle = preload("circle_samples.gd")
const LineSkin = preload("line_skin.gd")
const RADIUS := 0.7
const TOLERANCE := 0.01
const BUDGET := 96
var sides := 3
var points: Array[Vector3] = []
var error := 0.0
var met := false
var message := Label3D.new()

func _ready() -> void:
    choose_resolution(TOLERANCE, BUDGET)
    for i in range(points.size()):
        var a := points[i] + Vector3(0, 1.1, 0)
        var b := points[(i + 1) % points.size()] + Vector3(0, 1.1, 0)
        var line := LineSkin.new()
        add_child(line)
        line.show_segment(a, b - a, a.distance_to(b))
    add_child(message)
    message.position = Vector3(0, 1.8, 0)
    message.pixel_size = 0.002
    message.text = "%d sides; error %.5f m; met: %s" % [sides, error, str(met)]

func perimeter(record: Array[Vector3]) -> float:
    var total := 0.0
    for i in range(record.size()):
        total += record[i].distance_to(record[(i + 1) % record.size()])
    return total

func choose_resolution(tolerance: float, budget: int) -> void:
    assert(tolerance > 0.0 and budget >= 3)
    sides = 3
    while true:
        points = Circle.make(sides, RADIUS)
        error = absf(TAU * RADIUS - perimeter(points))
        met = error <= tolerance
        if met or sides == budget:
            break
        sides = mini(sides * 2, budget)
```

### Dependency: circle_samples.gd

<!-- student-code:circle_samples.gd -->
```gdscript
extends RefCounted
# Supplied circle sampler. Angles return in the Waves sequence.
static func make(sides: int, radius: float) -> Array[Vector3]:
    assert(sides >= 3 and radius > 0.0)
    var points: Array[Vector3] = []
    for side in range(sides):
        var angle := TAU * side / sides
        points.append(Vector3(cos(angle), 0, sin(angle)) * radius)
    return points
```

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Read the construction

`(i + 1) % record.size()` wraps the last index to zero. Without that closing edge, the sum would measure an open path. `perimeter` returns one number rather than creating geometry.

The program compares that sum with `TAU * RADIUS`, the floating-point circle circumference used as its numerical reference. Starting with three sides, it doubles the side count, stopping at the budget if a doubling would exceed it. After each new polygon it recomputes error.

There are two honest endings: the requested tolerance is met, or the available work is spent. `met` records which happened. A very small tolerance and a small budget should report false, not run forever or silently claim success. The budget counts samples, not elapsed GPU time.

This does not calculate every digit of pi or prove a limit. Both the circle reference and the sampled coordinates use finite precision. It makes the choice of an adequate approximation inspectable.

The circle sampler returns from Columns. Its sine and cosine calls are printed support; deriving them is a later investigation. Here, use the sampled positions to choose and test a stopping rule. You can understand the condition for stopping before explaining every operation that supplied the points.

## Make it your own

Compare tolerances 0.05 and 0.005 with the same radius and budget. Then request 0.000001 with a budget of twelve. Predict which run will exhaust its budget. Explain what “enough” means in each case and why the last case must still stop.

Carry the ability to name a criterion and a limit. The final Primitives hall gives you room to decide what to make with the constructions already available.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.


[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Portals/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
