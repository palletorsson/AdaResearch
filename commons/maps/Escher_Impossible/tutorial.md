# Escher Impossible

**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed STEP control measures changes between tread centres. FORM compares RETURN SIDE, CLOSING DROP, OPEN RUN, SCAFFOLD and TILTED TREADS. Reconstruct that measurement and its closed-route check. The fragments below omit the corners array and scene setup and do not build an impossible staircase.

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Closed path differences
- Projection
- Local and global claims

Inspect a finite list of heights. Predict the return difference before adding the closing edge.

Declare the staircase graph.

```gdscript
class_name StairGraph
extends Node3D

const SIDES := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]

@export var rise_per_side: float = 1.0
```

SIDES declares four directions, but build_corners below uses only their count. It does not use those directions to make a perimeter.

Place the corners.

```gdscript
func build_corners() -> void:
    var height := 0.0
    for i in SIDES.size():
        var corner := MeshInstance3D.new()
        corner.mesh = BoxMesh.new()
        corner.position = Vector3(i * 2, height, 0.0)
        height += rise_per_side
        add_child(corner)
```

The function places four boxes in a row with three rises between their centres. It does not populate the corners array required by the later fragments.

Connect the last corner back to the first.

```gdscript
func close_loop() -> void:
    var first := corners[0].position
    var last := corners[-1].position
    var line := ImmediateMesh.new()
    line.surface_begin(Mesh.PRIMITIVE_LINES)
    line.surface_add_vertex(last)
    line.surface_add_vertex(first)
    line.surface_end()
    loop_mesh.mesh = line
```

If those four centres are stored, the closing edge descends three rises. That is a possible segment, and exactly the height needed to close the route.

Hide the return seam.

```gdscript
func camouflage_seam(segment: MeshInstance3D, cam: Camera3D) -> void:
    var to_cam := (cam.global_position - segment.global_position).normalized()
    segment.visible = abs(to_cam.dot(Vector3.UP)) < 0.2
```

The dot-product threshold hides a segment over a range of viewing directions. This is an explicit visibility switch, not the installed perspective study.

Simulate a creature walking the loop.

```gdscript
func step_creature(creature: Node3D, t: float) -> void:
    var idx := int(t) % corners.size()
    var next_idx := (idx + 1) % corners.size()
    creature.position = corners[idx].position.lerp(corners[next_idx].position, fmod(t, 1.0))
```

With a populated corners array and advancing t, interpolation traverses each edge and wraps to the first point. The closing leg descends.

Label each edge as locally valid.

```gdscript
func label_edge(label: Label3D, from: Vector3, to: Vector3) -> void:
    label.text = "Δh = %+0.2f" % (to.y - from.y)
    label.position = (from + to) * 0.5 + Vector3.UP * 0.5
```

For the four centres above and a positive rise, three differences are positive and the closing difference is negative. Their signs expose the return directly.

Show the global sum.

```gdscript
func show_global_sum(label: Label3D) -> void:
    var total := 0.0
    for i in corners.size():
        var a := corners[i].position
        var b := corners[(i + 1) % corners.size()].position
        total += b.y - a.y
    label.text = "loop Δh = %+0.2f" % total
```

The cyclic differences telescope to zero, up to floating-point rounding: each height is added once and subtracted once. This is the check to assert in the replacement lesson. It is not an incompleteness result.

The current exhibit moves a marker while the player stays on the museum floor. Brouwer Intuitionism next asks what a construction can witness.
<<</MAP>>>
