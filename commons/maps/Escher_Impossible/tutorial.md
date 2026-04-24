# Escher Impossible

Local truth, global impossibility. Build a staircase where every step is correct and the whole cannot exist.

Declare the staircase graph.

```gdscript
class_name StairGraph
extends Node3D

const SIDES := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]

@export var rise_per_side: float = 1.0
```

Four sides, each rising by the same amount. The graph is a perimeter loop with monotonic height. Locally consistent by construction.

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

Four corners, each raised by rise_per_side above the previous. Every edge feels like a normal staircase.

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

The edge from the last corner back to the first is the impossibility. Height has risen four times; the return edge must descend all four rises in one step or the loop does not close.

Hide the return seam.

```gdscript
func camouflage_seam(segment: MeshInstance3D, cam: Camera3D) -> void:
    var to_cam := (cam.global_position - segment.global_position).normalized()
    segment.visible = abs(to_cam.dot(Vector3.UP)) < 0.2
```

The seam only disappears from one viewing angle. The illusion depends on perspective. Move your head and the trick shows.

Simulate a creature walking the loop.

```gdscript
func step_creature(creature: Node3D, t: float) -> void:
    var idx := int(t) % corners.size()
    var next_idx := (idx + 1) % corners.size()
    creature.position = corners[idx].position.lerp(corners[next_idx].position, fmod(t, 1.0))
```

The creature walks forever. Each step is valid locally. The loop never ends because height climbs every leg.

Label each edge as locally valid.

```gdscript
func label_edge(label: Label3D, from: Vector3, to: Vector3) -> void:
    label.text = "Δh = %+0.2f" % (to.y - from.y)
    label.position = (from + to) * 0.5 + Vector3.UP * 0.5
```

Each edge reports its height change. All four read positive. The contradiction is global only; no edge is lying.

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

The sum around the loop must be zero for the staircase to close. The plaque shows it is not. Gödel's result, rendered as a floor plan.

You have walked a local truth with a global impossibility. The next map, Brouwer Intuitionism, responds by restricting logic to what can be built.
<<</MAP>>>
