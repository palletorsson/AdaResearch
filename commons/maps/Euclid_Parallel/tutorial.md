# Euclid Parallel

**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed hall uses one postulates plaque with lesson controls, parallel lines and a triangle comparison. Reconstruct a declaration and a separately measured example; the five-plinth layout and timed door below are an earlier proposal.

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Geometric assumptions
- Constructed examples
- Measurement and proof

Inspect this earlier display sketch. A postulate rendered as text is a declaration; a constructed example needs a separate measurement.

Declare the five postulates as data.

```gdscript
const POSTULATES := [
    "Any two points can be joined by a straight line.",
    "Any finite line can be extended indefinitely.",
    "Any line segment and radius define a circle.",
    "All right angles are equal.",
    "Through a point not on a line, exactly one parallel can be drawn.",
]
```

Text, not logic. The postulates live as strings in a constant array so the room can render them on five plinths without a parser.

Lay the plinths in a horseshoe.

```gdscript
func place_plinths(parent: Node3D) -> void:
    var count := POSTULATES.size()
    for i in count:
        var angle := PI * (i + 1) / (count + 1)
        var p := preload("res://commons/maps/elements/text_plinth.tscn").instantiate()
        p.position = Vector3(cos(angle) * 4.0, 0.0, -sin(angle) * 4.0)
        p.text = POSTULATES[i]
        parent.add_child(p)
```

The horseshoe lets the learner read the sequence by walking it. Four feel like description; the fifth feels like an extra step.

Mark the fifth plinth.

```gdscript
func emphasize_fifth(plinth: Node3D) -> void:
    var label: Label3D = plinth.get_node("Label3D")
    label.modulate = Color(0.9, 0.7, 0.3)
    plinth.scale = Vector3.ONE * 1.2
```

Gold tint and a slightly larger scale. The fifth is set apart before any argument is made. The architecture performs the claim.

Draw five static parallel segments.

```gdscript
func draw_parallels(mesh: ImmediateMesh) -> void:
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for i in 5:
        var y := -2.0 + i * 1.0
        mesh.surface_add_vertex(Vector3(-5, y, 0))
        mesh.surface_add_vertex(Vector3(5, y, 0))
    mesh.surface_end()
```

Five lines, all parallel, all horizontal. The demonstration is quiet. Euclid's claim looks like a property of the world.

Toggle the fifth postulate.

```gdscript
func toggle_fifth() -> void:
    fifth_active = not fifth_active
    if fifth_active:
        parallel_preview.visible = true
    else:
        parallel_preview.visible = false
        chaos_preview.visible = true
```

This function switches preview visibility. It supplies no alternative metric or line construction, so it cannot demonstrate the independence of a postulate. The active branch also leaves the other preview’s visibility unchanged.

Record the 2300-year history on a scroll.

```gdscript
func populate_history(scroll: Label3D) -> void:
    scroll.text = "300 BCE Euclid\n1733 Saccheri\n1829 Lobachevsky\n1832 Bolyai\n1854 Riemann"
```

These names belong to different contributions to geometry; the list does not establish that they all attempted the same proof.

Open the door once the learner reads the scroll.

```gdscript
func _on_scroll_read(duration_ms: int) -> void:
    if duration_ms > 2000:
        door.unlock()
```

This proposed handler needs a reading event and a door object. Neither is supplied here or promised by the installed hall.

Next, NonEuclidean Spaces compares explicit distance models. Hiding a preview does not change the geometry of the museum.
<<</MAP>>>
