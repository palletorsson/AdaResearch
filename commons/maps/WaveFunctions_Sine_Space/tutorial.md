# A rule becomes a surface

**Learning elements**

- Spatial frequency: cycles per metre
- A height function of two coordinates
- Sampling a grid into shared positions
- Joining neighbouring samples with triangles
- Giving a static mesh collision

At the entrance, look across the blue tray. Choose a hollow before pressing RELEASE. Will a sphere pass through it, settle there, or knock another sphere out? The sine rule supplies a landscape. Gravity and contact determine what the bodies do with it.

## What returns

The opening cube repeated a height as **time** advanced. Pendulum kept observations of a moving body. Here a repeating rule takes **position** as its input. The surface stays still.

Bring the addresses from Grid and the face lists from Polyhedra. Bring back the PointBody sphere used in Forces: the same 0.14-metre radius, mesh, boundary and pickup behaviour. We create another instance of that class; we do not rebuild or re-explain its sphere. This is a return to a learned object after using the cube as our clock and pendulum marker.

**Build:** sample a two-metre square, connect the samples, and give its triangles a collision receiver. Drop one PointBody onto it.

**Investigate:** change the height range or spacing while keeping the sphere. Predict a change in the surface before you predict the body's response.

## Inside the museum

Save `03_sine_surface.gd` beside the carried `point_body.gd`. Attach the new script to your `PointStudy` Node3D in Sine Space, at **hall-local `(10.5, 0, 8.5)`**, zero rotation and unit scale. This places your small study across from the existing tray. The museum continues to supply its player, camera, light and XR tools.

Run the study. The sphere drops automatically; you can then pick it up and release it elsewhere using the museum's existing interaction. Restart the study after changing its exported values. Use a positive `cells` value; start with 16. We build a static mesh once in `_ready()`. Changing a variable while it runs does not rebuild the surface.

## Complete new code — 03_sine_surface.gd

<!-- student-code:03_sine_surface.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
@export var cells: int = 16
@export var amplitude: float = 0.18
@export var frequency: float = 1.0 # Cycles per metre, not per second.
var points: Array[Vector3] = []
var faces: Array[Vector3i] = []
var surface := MeshInstance3D.new()
var receiver := StaticBody3D.new()
var boundary := CollisionShape3D.new()
var point: PointBody

func height_at(x: float, z: float) -> float:
    return 0.8 + amplitude * sin(TAU * frequency * x) * sin(TAU * frequency * z)

func _ready() -> void:
    add_child(surface)
    add_child(receiver)
    receiver.add_child(boundary)
    for row in range(cells + 1):
        for column in range(cells + 1):
            var x := -1.0 + 2.0 * column / cells
            var z := -1.0 + 2.0 * row / cells
            points.append(Vector3(x, height_at(x, z), z))
    var stride := cells + 1
    for row in range(cells):
        for column in range(cells):
            var a := row * stride + column
            faces.append(Vector3i(a, a + 1, a + stride))
            faces.append(Vector3i(a + 1, a + stride + 1, a + stride))
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    surface.mesh = builder.commit()
    var blue := StandardMaterial3D.new()
    blue.albedo_color = Color("76b6c9")
    blue.roughness = 0.65
    surface.material_override = blue
    boundary.shape = surface.mesh.create_trimesh_shape()
    var contact := PhysicsMaterial.new()
    contact.friction = 0.45
    contact.bounce = 0.0
    receiver.physics_material_override = contact
    point = PointBody.new()
    point.position = Vector3(0.20, 1.8, 0.20)
    point.mass = 0.1
    point.gravity_scale = 1.0
    point.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
    point.freeze = false
    point.physics_material_override = contact
    var black := StandardMaterial3D.new()
    black.albedo_color = Color("17191c")
    black.roughness = 0.16
    for child in point.get_children():
        if child is MeshInstance3D:
            child.material_override = black
    add_child(point)
```


## Read the height rule

At `(x, z)`, the function returns `0.8 + amplitude * sin(...) * sin(...)`. The 0.8 metres raises the study to table height. With amplitude 0.18, the mathematical rule ranges from 0.62 to 0.98 metres. A particular sampling grid might miss its highest and lowest points.

`frequency` is measured in **cycles per metre**. `TAU * frequency * x` converts a position in metres to an angle in radians. At frequency 1, moving one metre in X repeats the value. There is no elapsed time in this expression and no `_process()` moving the terrain.

Hold Z at 0.25 metres. Predict the heights at X = 0, 0.25 and 0.5: **0.8, 0.98 and 0.8 metres**. At Z = 0, its sine is zero, so the whole row stays at 0.8. The two factors act together: a crest along one direction can be cancelled by the other.

## Addresses become faces again

Sixteen cells need seventeen sample positions along each edge. The nested loops keep `17 × 17 = 289` positions. X and Z run from −1 to 1 in the study's local coordinates. We keep positions row by row, so `row * stride + column` finds a sample in the list.

For each cell, `a` is one corner; `a + 1` is its neighbour along X; `a + stride` is the next row. The fourth corner is `a + stride + 1`. The two `Vector3i` entries refer to these four positions. This is the face-list relationship from Polyhedra, repeated across a grid: **256 cells, 512 triangles**.

The builder emits each triangle's three vertices and generates lighting normals. The order shown gives the triangles upward-facing fronts in Godot. The position list still contains shared samples even though the resulting rendering mesh repeats vertices per face. We leave out the earlier edge cylinders to keep this surface and its contacts readable.

## Seeing and supporting are separate

`surface` makes the triangles visible. `receiver` is a static physics body. Its `boundary` receives a triangle collision shape made from **that same mesh**, so the contact surface matches the drawn facets. The trimesh construction is a supplied engine operation; we are not writing a collision solver here.

The familiar point is unfrozen, has gravity, and keeps its spherical boundary. The physics engine advances it. We do not also assign its position every frame. A grab temporarily controls the body through the existing XR tool; releasing returns it to physics.

The new surface is a finite, thin sheet with no enclosing rails. A sphere can roll off and fall onto the museum floor. It collides with the sampled triangles, not an infinitely smooth mathematical sine. The contact material sets friction to 0.45 and bounce to zero; it does not promise that every hollow will hold the sphere.

## Make another surface without copying the answer

1. Keep frequency 1 and cells 16. Set amplitude to zero and restart. Predict the terrain and the released sphere separately. Then try amplitude 0.30. Which changes are consequences of the height rule, and which depend on contact?
2. Keep amplitude 0.18. Set frequency to 0.5, then 2, restarting each time. Predict how many full cycles fit across the two-metre width. Explain why increasing frequency is different from increasing height.
3. Return to frequency 1 but use only 4 cells. The sample spacing is now half a metre: all sampled sine values are approximately zero. The built surface becomes almost flat even though the unsampled function still has crests. Restore 16 cells. The function and its representation made different promises.

Now make one independent variation: give X and Z separate frequency variables. Aim for one cycle across the width and two along the depth. State your two frequencies in cycles per metre before running it. Keep the same PointBody and explain what you changed without calling it a faster wave.

## Compare with the installed encounters

The museum tray uses a denser, tilted surface and 32 smaller spheres. It rescales its sampled heights into the selected relief range. Our study uses a horizontal surface and a centred height range. Both construct static triangles and matching collision. The tray's SIZE and RELIEF controls reset its trial; its twelve-second counter records a deadline, not proof of permanent trapping. Use its batch for comparison after making the smaller construction.

Further into the hall, the red corridor advances the phase of layered waves. Its walls are visible but noncolliding; its thin floor provides support. Beyond that, the silver sine floor has a matching collider and stays still. Walk across a fold in each and compare what the same word, *surface*, lets your body do.

## Carried code — point_body.gd

This is the unchanged PointBody from Forces, included so the two-file study is complete. Keep it beside the new script. Its superclass, `XRToolsPickable`, is part of the museum's installed XR Tools; running these files in an empty Godot project would require that setup first.

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```


## Take forward

Keep the height function, sample list and face list. You can now make a repeating value occupy a surface and state whether that surface can stop a body. In Unit Circle, we examine where the sine value comes from: a turning point and one of its coordinates.
