# Rotation: room for a turn

The transport cube carried you without needing to turn. Here, a blade stays attached to its middle while its ends sweep across the gap. Follow one end. The other moves away.

Translation left direction alone: space was the same in every direction and a move was a move. Rotation makes facing matter.

<!-- @rotation_wall_crossings -->

## Staying upright

The level blade turns around the vertical y axis. At ninety degrees it pauses, its length reaching across your route. Walk over while the crossing holds.

At the X-axis blade, one end descends as the other rises. It turns around x, like a paddle wheel. The far landing is three grid cubes higher. During the pause, the blade offers a slope you can climb. Through vertical, your feet lose their agreement with it.

Beside its lower end is a small level platform. Board it and stay through the turn. You rise, move forward, and arrive beside the higher grid. Your head has stayed upright.

The platform follows an arc while keeping its surface level. It is mounted to one side so the blade can pass through vertical without sweeping through your body. Keeping you upright requires a rule alongside the turn.

The X-axis ride's arc, before that sideways offset, is calculated as:

```gdscript
var radial := Vector3(0, -1.5, -3.5)
var orbit := Basis(Vector3.RIGHT, PI * progress) * radial
var endpoint := Vector3(0, 1.5, 0) + orbit
```

`radial` reaches from the centre to the starting point. `Basis` turns that reach around x; `progress` from zero to one supplies half a revolution. Adding the centre gives the new position. The platform carries you until you step off or jump.

The sideways ride's blade turns around z. Board from the left: this ride carries you sideways along x and up. Turning around z cannot advance you along z. The destination is another bank.

Both rides pause for twelve seconds, then take twelve for the half-turn. Staying aboard brings you back along the upper arc. The grid wedges and still aisles offer other returns.

<!-- @ -->

Beyond the blades, the cubes hold their angles. You bring the movement.

<!-- @rotation_array_compare -->

## An angle underfoot

Four bands each contain two columns and six rows of cubes. Begin at zero and walk forward along z.

Eighteen degrees. Thirty-six. Fifty-four.

The centres keep their spacing; each row adds an angle. X makes rises and falls across your route. Z makes ridges along it. Y turns the square footprints while keeping their tops horizontal. The fourth band combines x, then y, then z.

```gdscript
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

The row supplies the angle; the band supplies the axis or combination. Waiting will not change the slope. The still aisles let you inspect a difficult row from beside it.

A stand in the central aisle starts another walk. Narrow capsules, 0.44 metres wide, set off along all four bands. Wider capsules follow from the same places, now 1.20 metres wide. Their height, speed, gravity and forward instruction stay the same. Rings retain their endpoints; the trial repeats, and **REPLAY** starts it again.

Watch the z band. The narrow body catches on a ridge; the wider one can slide sideways and continue. Wider need not mean less room to move. These bodies neither jump nor choose a detour: the collision solver supplies their slides. You can walk through them and try a route they did not take.

<!-- @ -->

The last row reaches ninety degrees. In the Y band, compare it with the first. The cube's outline returns, but the pale L on its top points another way. That flat-looking row still waits beyond all the tilted ones.

Each cube has kept its shape throughout. What changes is how it meets its neighbours and your body.

<!-- @transform_composition_workbench -->

## Two turns

Rotation is the first operation where the order you do things in changes where you end up.

Beyond the combined band, two finned forms stand beside a pale version of their starting shape. The workbench opens on pair four: thirty degrees around X and forty-five around Y. The left form receives X first; the right receives Y first.

Follow the fin through the smaller intermediate forms. In the two results it points different ways. The display separates the forms for us; both calculations use the same origin.

```gdscript
var left_xform: Transform3D = t2 * t1
var right_xform: Transform3D = t1 * t2
```

The operation on the right acts first. In Translation, upward and sideways movements could exchange order and share a destination. These two turns cannot: the second receives the orientation left by the first. Adding never did this.

Move the pair slider to two. A turn and a uniform enlargement now end in the same form whichever comes first. Their intermediate forms still differ. The fin gives you something to follow through both journeys.

In the translation halls a move was reducible to its result: here, then there, and the between did not matter. Rotation ends that. Two turns in one order and two turns in the other are the same two turns and two different outcomes, so the process is now part of the thing. From this hall on, how you got somewhere is a fact about where you are.

<!-- @axial_sweep -->

## What returned?

A small cube turns on a spindle beside the way onward. Follow the pale L on its face. After a quarter-turn, the cube fits the space it occupied before. The marked face has gone around the corner.

What returned depends on what you were following.

Turn a square a quarter of a turn and it is the same square, corner for corner. Turn it an eighth and it is not. The turns that change nothing are a form's symmetry, and they are the part of rotation this chapter cares about most: not where a thing ends up, but which turns bring it home. A square comes home under four. And this is not only a fact about shapes. When physics asks what a particle is, one of the answers is how many turns it takes to come home, and there are particles that need two. How many turns a thing needs is a number physics gives to every particle, and it calls that number spin. It is sameness of form, taken as far as it goes.

![The same cube at zero and ninety degrees, photographed from the same viewpoint. Its outline returns; the marked face moves.](/book-review/doc/book/iterations/2026-09-23-rotation-return-and-sweep/marked-return.png)

*Two paused moments from one place. The mark moves from the left-hand face to the right.*

Press **BOUNDARY**. A cylinder appears around the turn. A corner reaches its round side, then leaves. The contour keeps that place while the corner is elsewhere.

Pause. Part of the cylinder is empty. It describes the outside of all the positions the cube occupies over a full turn. A turn needs room that a single pose leaves empty.

Change **SHAPE** to the triangle. Its upright edge lies on the axle. As the face turns, the wide bottom sweeps a circle and the sloping edge describes a cone. Hide the boundary and follow the sweep with your eyes; bring it back. The outline helps you keep a whole turn in view. It has made no new solid wall.

![The rotating cube inside its cylindrical boundary and the triangular face inside its conical boundary.](/book-review/doc/book/iterations/2026-09-23-rotation-return-and-sweep/spaces-of-a-turn.png)

*In this earlier colour study, the contours describe full turns. Each solid body is paused in one position. The museum now shows these studies in grayscale.*

The triangle from Primitives has acquired another possibility without acquiring another corner.

<!-- @ -->

Walk on into the last court.

<!-- @boolean_tunnel -->

## Inside the turns

Look through the first hollow cube. Four more stand beyond it. Each adds eighteen degrees.

```gdscript
angle_deg = i * rotation_per_segment
```

Subtracting an inner box made each cube hollow. The turns arrange those openings around a continuous floor. Walk inside and follow a corner with your eye.

Five segments occupy fifteen metres. They stand still; your walk unfolds their differences. Turn back and the sequence unwinds.

Which edge did you take for a horizon?

<!-- @carousel_cake -->

Outside the tunnel, the stacks keep turning. Follow a stripe on a low layer, then near the top. Their relations change while you stand still.

The lowest layer turns at half a radian per second; each successive layer turns 1.2 times as fast. In the tunnel, eighteen degrees separated neighbours. Here, speed keeps changing the angle through time.

Eight layers make each of five profiles: a brim, a column, a taper, a pinched spindle, a flare. They share heights and turning speeds. Walk between them and compare the room each leaves around itself.

<!-- @ -->

<!-- study-spine:hinge_release -->

<!-- @hinge_release -->

A small plate waits on a hinge. Turn it; its neighbours travel with it. Release it under KEEP. The pose stays where you left it. Choose RETURN, turn again, then release. The joint moves towards the earlier angle, as if the object had a preferred answer.

The fixed support and stored angles make this an Ada response to Lygia Clark's articulated works. They give us a way to ask what an invitation permits. A joint can be available to your hand while the rule after release quietly takes the last word. Switch on TRACE and watch one corner: two journeys can arrive at the same pose without leaving the same line.

<!-- @ -->

In the next hall, the surroundings change size while your body stays the same. What will fit then?
