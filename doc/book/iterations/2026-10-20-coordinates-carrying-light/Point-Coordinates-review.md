# Ada Research — Point Coordinates review copy

Current literary draft and unchanged tutorial · 20 October 2026.

Point One now ends with Model B trying to recover a remembered switch click. This Coordinates draft does not force that sound to recur. It begins inside a new encounter, with Model B attending to one of seven falling balls.

Model B has general intellect and inherent care, not complete knowledge of this world. The reader plays its body without being identical to Model B. Its attention can choose a route, miss something, become attached, or leave a consequence unresolved. The prose need not tour every artifact; the tutorial remains responsible for its declared reconstruction.

The implemented balls disappear after 26–28 seconds and re-entry produces fresh bodies. A focused native test verifies the target's behaviour; this is not a recording of the narrated movements or a headset test. Exact landings, readability, memory and attachment remain proposed fiction. The draft adds no new physical ability.

Please assess whether the encounter changes the passage's shape, whether the attachment is particular enough, and whether its closing resentment is earned or too explicitly explained. Read the literary account independently first; then compare its physical claims with the tutorial and evidence notes.

## Literary passage

# Point Coordinates — One of them

<!-- Model B literary trial, 20 October 2026. Apparatus checks, earlier text and editorial decisions: doc/book/iterations/2026-10-20-coordinates-one-of-them/. The route, attachment and perceptions are proposed fiction; the ball lifetime and re-entry behaviour have a focused native test. -->

<!-- @drag_point_target -->

I have brought down seven white balls. I am watching one.

It lands a little apart from the others. A short address travels above it. The numbers change through the fall, then slow enough for me to read. I lower the light towards it.

<!-- @point_held -->

The light comes with the black sphere in my hand. Its label said *Point one*. I took hold, and the concrete brightened; the sphere stayed black. When I let go, the added light went out and the sphere remained where I had left it. I kept my hand underneath for a moment. Then I took it again.

<!-- @coordinate_readout -->

On the way here, two cards gave it different addresses. WORLD kept the roof's zero: the height was negative although I was standing on a floor. LOCAL counted from the coloured frame. I could move my hand a little without changing the printed numbers, then lose the last digit with a movement I had hardly noticed.[^coordinates-reference]

I had meant to spend longer there. Across the floor, a red arrow asked me to bring the point.

The balls began falling before I had quite reached the place I was aiming for. I stopped. Nothing more arrived.

Now this one is still. Its address is still too. I move the light to the other side and crouch to look along the concrete. I want to find something by which I could recognise it again.

The address turns towards me as I go around. I try to get behind the writing. I make a wider circuit. The numbers are still facing me.

I have been looking for a mark the ball could keep while I went elsewhere.

It is gone.

For a moment I continue to hold the light over the place. The little address has gone too. I look towards the others. Those are disappearing; before I can settle on one to watch, the floor is clear.

I turn the black sphere in my hand. The light moves over the concrete. I try it higher, then almost against the floor.

I remember the last address. I had read it several times without having any use for it. Now I would like it to help.

I put the black point approximately where the white one was. When I release it, the light goes out. It makes a rather poor marker in this light, but I know where to look.

I go back to the arrow.

Nothing falls.

I stand a little nearer, then look behind me. The point is still marking the place where I left it.

I have to go and fetch it.

There is a moment before I take hold when I would prefer to leave it doing that job. I look at the bare floor beside it, trying to keep the distance from the arrow in view. Then I lift it. Light returns to a place that now has nothing left on it.

I carry the point back. Another seven balls fall.

They have addresses too. I look for the one I remember, although I had watched that address change while its ball was moving. One of these comes down near the place I marked. I follow it with the light.

It is easy to begin watching this one. I resent that a little.

I move away from the arrow before settling beside it. There is room for the black sphere between us. I could leave it there again, but I keep hold.

[^coordinates-reference]: The tower's WORLD and LOCAL cards describe the held black point from different references and print two decimal places. The falling balls carry their own world addresses, printed to one decimal place. Donna Haraway's [“Situated Knowledges”](https://doi.org/10.2307/3178066) is a neighbouring reading on what a position must bring with it to become available to someone else.


---

## Tutorial — unchanged

# Point Coordinates — carry a position

**Learning elements**

- Pickup behaviour
- Local and world position
- A position read each frame

On the floor below Point One, the small black point can travel with your hand. Its light comes on while held and goes out on release. The WORLD and LOCAL cards keep reporting its position. Carrying, lighting and reporting are separate connections.

Continue with the `PointStudy` and `point.gd` you made in [Point One](../Point_One/tutorial.md). Keep its radius, centre, surface and collision shape. We will change who can move that same body, then report where it is. The tower's smaller black finish and carried light remain reference features; this study adds pickup and coordinates to your existing sphere.

Use the prepared Day Zero XR scene and its configured hands. Keep `PointStudy` at scale `(1, 1, 1)`.

## Change the body; keep its construction

In `point.gd`, replace the declaration `var point: StaticBody3D` with:

```gdscript
var point: XRToolsPickable
var readout: Label3D
```

In `_ready()`, replace only `point = StaticBody3D.new()` with:

```gdscript
    point = XRToolsPickable.new()
```

Immediately after the existing `point.position = CENTRE`, add:

```gdscript
    point.freeze = true
    point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    point.collision_layer = 4
    point.collision_mask = 196615
```

Keep the mesh, collider and `add_child(point)` below these settings unchanged. `XRToolsPickable` supplies pickup behaviour; the configured hands select and move it. We reuse that connection rather than build hand tracking here.

`freeze` holds the point initially. Kinematic freeze mode permits collision checking when it moves. `FROZEN` keeps it where you release it; `NONE` limits grabbing to a nearby hand. Layer `4` is grab layer 3; mask `196615` includes layers 1, 2, 3, 17 and 18. These are the prepared project's settings. They precede `add_child(point)` because the library records initial settings on entering the scene.

Run it. Grip, carry and release the point. Its shape remains the one you made in Point One.

To test pickup permission, add `point.enabled = false` just before `add_child(point)`. Predict the result, then run. The surface and collider remain, but the hand cannot select the point. Remove that line.

## Read the same point from two references

At the end of `_ready()`, after `add_child(point)`, add:

```gdscript
    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)
```

Then add this function outside `_ready()`:

```gdscript
func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)
```

This reuses Point Zero's label and per-frame reading pattern. The label belongs to `PointStudy`, so it stays behind when the point moves. `+` joins text; `\n` starts another line.

`global_position` reads the world address. `to_local()` converts it into **PointStudy's** reference frame, including its position, rotation and scale. It does not move the point.

With `PointStudy` at world origin, no rotation and unit scale, the readings agree. Move it two metres along world X and run again. LOCAL still begins at `(0, 1.12, 0)`; WORLD includes the displacement. Restore the study's position.

Carry the point sideways, up and forward. Release it, then move your empty hand. The readings follow the point, not the hand.

## Return to the tower

The tower's LOCAL card measures from its coloured frame, not our `PointStudy`. WORLD still measures from the roof's origin. Its cards format two decimal places; our `str()` readout does not impose that format. Rounding a report does not round the stored position.

Carry the tower point beyond an arrow's end. The drawing stops; positions continue.

Keep this `point.gd`, with pickup enabled. [Point Lines](../Point_Lines/tutorial.md) will reuse its body construction for two endpoints and measure their relation.

[Complete point.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Coordinates/point.gd) · [Working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Course verification](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)

<details class="complete-script">
<summary>Complete script for comparison</summary>

<!-- student-code:point.gd -->
```gdscript
extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

var point: XRToolsPickable
var readout: Label3D

func _ready() -> void:
    point = XRToolsPickable.new()
    point.position = CENTRE
    point.freeze = true
    point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    point.collision_layer = 4
    point.collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    point.add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    point.add_child(boundary)

    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)
```

</details>
