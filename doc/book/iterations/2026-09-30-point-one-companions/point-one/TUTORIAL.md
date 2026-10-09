# Point One — give the point a body

Point Zero gave us an instruction that runs when the scene is ready. Here we will use that moment to place a marker. The supplied scene already gives us a floor, a light and a view. We will keep those while changing what appears in front of us.

Open [the Point One study project](README.md), then `study.tscn`. Its root is `PointStudy`. The three station nodes, `Position`, `Visible` and `Solid`, have `position.gd`, `visible.gd` and `solid.gd` attached. These are the three scripts we will change. Each station has its own “Point one” label.

Run the study. Above the first label there is nothing; above the next two are white spheres. Three small pink feelers move from left to right. Two cross their stations; the third stops at the solid sphere. The sweep repeats. Space pauses or resumes it; R starts the sweep again. `contact_probe.gd` supplies this contact test. Its movement is borrowed equipment, like the camera. We will change what it can cross.

## At the first label, nothing appears

Open `position.gd`. This is the whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

We know `_ready()` from Point Zero; `-> void` says the function returns no value. Here we define a `Vector3`, a value containing three numbers, and name it `point_position`. For now, this is the supplied position at our station. Point Coordinates will make its three components the subject of a lesson.

Change `1.12` to `1.7` and run. Nothing appears at this station. We have changed a value without attaching a visible body to it. The editor's unused-variable warning describes that condition. The pink feeler still crosses the empty place. It belongs to the supplied test, not to the position we have just defined. Restore `1.12`.

## Give the position a surface

Open `visible.gd`. Its complete construction runs in the same familiar function:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)

    var radius := 0.14
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0

    var marker := MeshInstance3D.new()
    marker.mesh = sphere
    marker.position = point_position
    add_child(marker)
```

`point_position` is the location. `sphere` describes a spherical surface; `marker` is the node that displays it. `.new()` creates each part. Assigning `marker.mesh` gives that node its surface; assigning `marker.position` places it. `add_child(marker)` joins it to the station. A position and the object placed there are different things.

Change `1.12` to `1.7` in this script. Now the white sphere rises. Restore the height, then change `radius` from `0.14` to `0.3`. The sphere grows around the same centre. Its height follows because the script makes it twice the radius.

Watch the feeler cross the larger sphere. A visible surface has still given it nothing to collide with. We can change how much the sphere hides without changing what can pass through it. Restore the radius to `0.14`.

## Give the body a boundary

The third station looks the same. Its feeler stops. Open `solid.gd`:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)

    var radius := 0.14
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0

    var marker := MeshInstance3D.new()
    marker.mesh = sphere
    marker.position = point_position
    add_child(marker)

    var solid := StaticBody3D.new()
    solid.position = point_position

    var sphere_shape := SphereShape3D.new()
    sphere_shape.radius = radius
    var collider := CollisionShape3D.new()
    collider.shape = sphere_shape

    solid.add_child(collider)
    add_child(solid)
```

The first part constructs the same marker. The added `StaticBody3D` participates in collision. `SphereShape3D` describes its boundary, and `CollisionShape3D` attaches that shape to the physics body. The visible marker and this body are both placed at `point_position`.

Find `sphere_shape.radius = radius`. Change only that line to:

```gdscript
    sphere_shape.radius = 0.35
```

Run again. The white sphere stays small, but the feeler stops earlier, leaving a visible gap. The empty space resists it. **Debug → Visible Collision Shapes** can also reveal the larger boundary; the contact test works without that overlay.

We have chosen whether the surface we see and the boundary we encounter coincide. In the museum, it is your movement that meets this difference. The fixed-camera study supplies another moving body so we can test the same relation. Restore `sphere_shape.radius = radius`.

Try a different disagreement: in `solid.gd`, set the visible `radius` to `0.3` and `sphere_shape.radius` to `0.07`. The feeler disappears into the white surface before the contact label reports “stopped”. The boundary is now inside the body we see. Return both to the matching `0.14` when you finish.

## Remove the light, keep the body

In the museum, use the wall switch. The long shadows disappear while a dim fill leaves the spheres visible. The collision boundary stays where it was.

The decision in the switch is one line:

```gdscript
sun.visible = false
```

Here `sun` is the museum's directional light. This is a reading of that source, not a line to paste into `visible.gd`, which has no variable named `sun`. The portable study keeps its supplied light. Building the switch and its lighting rig is outside this lesson.

## What we can carry forward

We can now place a marker, change its surface around the same centre and give it a different physical boundary. The large sphere at the end of the museum corridor asks us to return to those choices: it still says “Point one”. Knowing its construction gives us another way to change the encounter.

Point Coordinates (the next study, supplied separately) begins with a supplied point we can hold, then reads its movement. It will prepare two positions for the line. The [construction reference](CONSTRUCTION.md) keeps the roles of the supplied parts available without adding another required exercise.
