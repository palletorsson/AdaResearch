# Melencolia — arrange what you can make

We can place points, connect faces and generate a form. Portals gave us a way to check one requirement. Now make an arrangement with the constructions we know.

Open `primitive_composition.tscn` in the [Ada student starter](../../README.md). Three identical pyramids stand on the floor. The middle one is farther away. Walk to the side and compare their outlines.

## 1. Place the same form three times

Open `studies/primitive_composition/arrangement.gd`:

```gdscript
var positions: Array[Vector3] = [
    Vector3(-1.15, 0, 0),
    Vector3(0, 0, -0.8),
    Vector3(1.15, 0, 0),
]
```

These are positions for whole bodies. They are measured from the study's origin, which the scene places 0.7 metres behind the room's centre. Each pyramid's local origin is at the centre of its base. Keeping Y at zero leaves its base on the floor.

The familiar list and loop now arrange objects:

```gdscript
func _ready():
    for at in positions:
        var body := Pyramid.new()
        body.position = at
        add_child(body)
        bodies.append(body)
```

`Pyramid` is the supplied script in `pyramid.gd`. Each call to `Pyramid.new()` creates a mesh instance and builds its geometry in code. It uses five positions and a face list, as in Polyhedra. Its square base uses two triangles, as in Cube.

The six render triangles make five geometric faces. Every copy has the same dimensions and material. The loop gives each copy a different position and keeps its reference in `bodies`.

## 2. Bring the centre forward

Change the middle entry's Z value from `-0.8` to `0.8` and run again. From the entrance, the middle pyramid is now closer than its neighbours.

Its vertex positions inside the mesh have not changed. Its size on the screen has. Walk around it: which overlaps belong to this viewpoint?

Moving a body places its local construction elsewhere. In Cube, moving a corner changed the construction itself. Those operations can look related while changing different data.

## 3. Change the distance between neighbours

Keep the centre forward. Change the outer X values from `-1.15` and `1.15` to `-0.55` and `0.55`. Run again.

The arrangement becomes tighter. From some positions the outlines overlap; from others they separate. No pyramid has gained a vertex, and no face has been removed. The gaps and the view have changed.

These surfaces have no colliders. The gaps are visual and spatial relationships, not a tested walking clearance. The museum's raised court and solid obstacles are separate constructions.

## 4. Make one arrangement to keep

Restore the outer X values to `-1.15` and `1.15`. Place the middle pyramid somewhere else on the floor. Keep its Y value at zero and its X and Z values between `-2` and `2` for this room.

Look from the entrance, then from one side. Keep an arrangement that gives you something different from both positions. Save the script: restarting rebuilds the positions you wrote. Walking changes your view, not the saved arrangement.

This is a reduced study of the museum's geometric court. It does not reconstruct Dürer's engraving. The court, the tableau and the magic square have different tasks; the [museum source notes](tutorial-museum.md) keep those distinctions available.

We have made something exact enough to inspect and open enough to compose. Nothing in the pyramid's face list decided where it should stand. The critical text follows the desire invested in such forms. Here we have a small means of acting on it.

Transformation begins with these bodies. Next, their positions can change while the program runs.
