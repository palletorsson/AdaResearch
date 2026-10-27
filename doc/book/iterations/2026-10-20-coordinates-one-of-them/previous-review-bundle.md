# Ada Research — Point Coordinates review copy

This file contains the **current Point Coordinates literary passage and tutorial**, followed within the tutorial by its complete working script. It does not contain Point One or earlier drafts.

Prepared 20 October 2026.

## Context for the reviewer

The preceding Point One passage ends with Model B leaving a floor where visually similar spheres differ in collision, lamps can be switched off independently, and a large black sphere attracts its attention through a moving highlight.

Model B already has general intellect and inherent care. It does not know or understand everything about the algorithmic world. It can learn unfamiliar mechanisms, misinterpret relations and revise its understanding. Care, attachment and bias shape what it notices and what it overlooks. Its inquiry concerns the world as well as purpose and desire; it does not need to acquire intelligence or moral competence. The player plays its body but is not Model B; the literary account is one possible situated encounter, not a transcript every player must enact.

The current tower floor has a small grabbable black point that lights its surroundings while held, a coordinate frame with WORLD and LOCAL readouts, and an arrival target that releases falling balls. The old glass-covered basin and invisible-point case are not installed in the current saved layout. The source configurations have been checked; the passage's exact sightlines, illumination and timing have not received a new headset test.

The tutorial continues the point built in Point One and distinguishes that learner reconstruction from the tower's finished apparatus. Its published edits have been checked to reproduce the existing complete Coordinates script.

Please review the literary passage and tutorial together: continuity from Point One, Model B's attention and desire, preservation of the reader's freedom, technical clarity, and whether the two texts support each other without repeating the same work. Treat literary interpretation and verified game behaviour separately.

---

## 1. Literary passage — final.md

# Point Coordinates — Where is the point?

I arrive on the next floor still prepared to go around things.

Here the black sphere is small enough for my hand. There is no pedestal beneath it. The label on the floor says *Point one*, as if the delivery had continued without me.

I take hold.

Light reaches the concrete around my feet. I raise my hand, and the lit area changes with it. The sphere stays black.

Above, the lamps had their rods and a switch. I look for an attachment here, turning my hand a little. The point comes with it. Nothing stretches back to the place where it was waiting.

I release it.

The added light goes out. The sphere remains where I left it, without a surface beneath it to explain the arrangement.

For a moment I keep my hand close. Then I lower it.

So far, it has stayed where I release it. Each time I let go, the light goes out. I try once more, keeping my hand underneath for a moment before taking it away.

I take it again and move towards the coloured frame. The label stays behind. Which part did the name belong to?

Two white cards face the floor. One says *WORLD*, the other *LOCAL*.

Their numbers change as I move the point. I stop walking and move only my hand. They change again.

The WORLD height is negative. The floor is quite firmly beneath me. Zero is still upstairs, at the crossing below the wire cube; I have travelled down from it. The building has not started its measurements over for my arrival.

I bring the point closer to a card. Its light makes another patch to watch beside the numbers. I would like to move slowly enough to catch a digit changing.

Sometimes the sphere moves and the printed number does not. I try a slightly larger movement. Now it changes. The card gives me two decimal places; I can make movements too small for that account. The apparent stillness belongs to the report.

I try to keep the last digit still while shifting the light. It works briefly. Then another component changes.

Pink, grey and black guides divide the movement beside the frame. I follow the pink direction, then let my hand drift across it. Several parts of the drawing answer the one gesture.

LOCAL seems to be giving the frame's account. I move back towards its crossing and watch the components approach zero. WORLD still gives another address. I try the movement again, checking that I have followed the same point in both reports.

A coordinate needs its reference. Reading more digits cannot supply one that has been left unnamed.[^coordinates-haraway]

I move beyond the end of an arrow. The guides continue to follow. It is a relief that the drawing has stopped before my permission to move has.

I leave the point there and take a step away. Its light goes out again. The cards continue to give its position.

Neither has a place to say that I have let go.

Farther across the floor, a red arrow says *DRAG POINT HERE*.

This is a more particular request than *Point one*. I recover the sphere and carry it towards the arrow.

White balls fall into the space ahead. Small addresses move with them.

I stop before I have brought my hand exactly to the place indicated. The arrival has already been accepted. I hold the point there, but no more balls come.

I move away and return. Another fall.

“Here” has room in it. I approach from a different side, slowing as I get close. The installation accepts that arrival too. It has not asked how I meant to arrive.

I begin to leave, then return once more. The pause is longer this time. Some of the earlier balls have settled before the next ones reach them.

Before bringing down any more, I look where the earlier ones have gone. I had been watching their arrival more closely than what happened afterwards.

The destination can become an instrument. I take a detour before returning, giving the fall more time between its beginnings. The point is doing very little by itself. My hand, the accepted region and the falling bodies have acquired a rhythm I can interrupt.

On the next return I stop short. Nothing falls.

I wait there longer than necessary.

The light is still on the concrete. I can move it without satisfying the request.

I would like to leave the sphere at the arrow and carry its light elsewhere. For now, moving one takes the other with it. I draw my hand back, watching the space open between the point and the place it has been asked to reach.

[^coordinates-haraway]: Donna Haraway's [“Situated Knowledges: The Science Question in Feminism and the Privilege of Partial Perspective”](https://doi.org/10.2307/3178066), *Feminist Studies* 14, no. 3 (1988), 575–599, is a neighbour to these two readings: what must accompany an address for another body to understand where it is measured from?

---

## 2. Tutorial — tutorial.md

# Point Coordinates — carry a position

**Learning elements**

- Pickup behaviour
- Local and world position
- A position read each frame

On the floor below Point One, the small black point can travel with your hand. Its light comes on while held and goes out on release. The WORLD and LOCAL cards keep reporting its position. Carrying, lighting and reporting are separate connections.

Continue with the `PointStudy` and `point.gd` you made in [Point One](http://localhost:3003/book-review/commons/maps/Point_One/tutorial.md). Keep its radius, centre, surface and collision shape. We will change who can move that same body, then report where it is. The tower's smaller black finish and carried light remain reference features; this study adds pickup and coordinates to your existing sphere.

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

Keep this `point.gd`, with pickup enabled. [Point Lines](http://localhost:3003/book-review/commons/maps/Point_Lines/tutorial.md) will reuse its body construction for two endpoints and measure their relation.

[Complete point.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Coordinates/point.gd) · [Working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Course verification](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)

## Complete script for comparison

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




---

## About the source links

The localhost links refer to the author's local project and will not open on another computer. The complete Coordinates script is included above, so it is available to the reviewer without those links. No gameplay changes are proposed by this review copy.
