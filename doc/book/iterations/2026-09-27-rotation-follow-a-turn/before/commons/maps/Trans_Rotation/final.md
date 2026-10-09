# Rotation: crossings, arrays and inhabited repetition

The transport cube carried you without needing to turn. Here, a surface stays attached to its middle. Follow one end. Where does the other end go?

<!-- @rotation_wall_crossings -->

## A turn that carries you

The green blade turns around y. Its centre stays over the gap while its ends sweep towards the grid. At ninety degrees it pauses. Walk across the length that has arrived in your direction of travel.

The orange blade turns around x. Look at its middle. It has no hinge at the bank. One end descends as the other rises, like a large paddle wheel.

The far landing is three grid cubes higher. During the pause, the blade makes a slope you can climb. But a slope that keeps turning does not keep offering itself as a floor. Through vertical, your feet lose their agreement with it.

Step onto the small level platform beside the orange blade's lower end. Stay there as the turn begins.

You rise, move forward, and arrive beside the higher grid. The blade's centre has stayed where it was. Your head has stayed upright. Which part turned, and which part was kept from turning?

The platform follows an arc while its surface stays level. Its sideways mounting lets the blade pass through vertical without sweeping through your body. Keeping you upright requires a rule alongside the turn.

For the orange ride, the position calculation can be written:

```gdscript
var radial := Vector3(0, -1.5, -3.5)
var orbit := Basis(Vector3.RIGHT, PI * progress) * radial
var endpoint := Vector3(0, 1.5, 0) + orbit
```

`progress` runs from zero to one: half a revolution. The point goes from the lower near bank to the higher far bank; its x coordinate stays fixed. The platform carries you along with it until you step off or jump.

At the blue blade, z is the axis. Board from the left. This platform carries you sideways along x and up. Look down the hall while it moves. Rotation around z has no displacement along z to give you. The passage asks you to face another bank.

Both rides pause for twelve seconds, then take twelve for the half-turn. After the high pause they retrace the upper arc. Staying aboard brings you back above the basin. The grid wedges and still aisles offer other returns.

Look back at the bank where your ride began.

<!-- @ -->

Beyond the blades, the orientations stay still. Your movement will bring you into their differences.

<!-- @rotation_array_compare -->

## An angle underfoot

Four bands each contain two columns and six rows of cubes. Begin at zero. Choose a column and walk forward along z.

Eighteen degrees. Thirty-six. Fifty-four.

The centres keep the same spacing; the angle increases with each row. Follow an outlined edge when surfaces seem continuous. It still belongs to one cube.

Try another band. Where do you climb, descend, stop? Find the row beside you, then inspect it from the still aisle.

X makes rises and falls across your route. Z makes ridges along it. Y turns square footprints while keeping their tops horizontal. The fourth band combines x, then y, then z. At intermediate rows, its edges leave the planes of the grid.

```gdscript
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

The row supplies the angle; the band supplies the axis or combination. For XYZ:

```gdscript
return Basis(Vector3.BACK, radians) * Basis(Vector3.UP, radians) * Basis(Vector3.RIGHT, -radians)
```

The rightmost matrix acts first: x, then y, then z. This band keeps that order. The angles belong to the rows; waiting does not change them.

The cubes have not been cut or joined. Their internal distances survive the turn; the connections available to your walk need not.

At the near end of the bands, a small stand occupies the still central aisle. Watch the cyan bodies set off along all four bands at once: each is 0.44 metres wide. Pink bodies follow from the same places, now 1.20 metres wide. The study repeats on its own; REPLAY on the stand begins it again. Their height, speed, gravity and forward instruction stay the same. Rings keep the first endpoints so you can compare where they arrive.

You might expect wider to mean worse. Watch z before deciding. Here the narrow body catches on a ridge; the wider one can slide sideways and continue. Its changed route matters as much as its arrival.

The capsules neither jump nor choose a detour; the collision solver supplies their slides. You can walk through them without pushing them. Try a route they did not take.

<!-- @ -->

The final row reaches ninety degrees. Compare it with the first in the Y band. The cube's outline returns. Find the pale L on the top face: the top stays level, but the mark points another way.

That flat-looking end still waits beyond the tilted rows. More rotation does not promise more obstruction.

The array holds these orientations still. The blades let you encounter the journey between them. A shape can return without giving back the time it took, or undoing where it carried you.

<!-- @transform_composition_workbench -->

## Which turn comes first?

Beyond the combined band, two finned forms stand beside a pale version of their starting shape. The workbench opens on pair four: thirty degrees around X and forty-five around Y. The blue form receives X first; the red form receives Y first. Both use the same angles and axes.

Follow the fin through the smaller intermediate forms. Then compare where it points in the two results. The columns separate the pictures for us; the calculation uses the same origin for both.

```gdscript
var left_xform: Transform3D = t2 * t1
var right_xform: Transform3D = t1 * t2
```

The operation on the right acts first. These two orders leave the fin facing different ways. The upward and sideways translations in the previous hall could exchange order and share a destination. Follow the fin to see where the comparison parts company.

Move the pair slider to two. A turn and a uniform enlargement now end in the same form whichever comes first. Their intermediate forms still differ. Return to four and follow the fin again.

<!-- @axial_sweep -->

## Room for a turn

A small cube turns on a spindle beside the way onward. Walk up to it and follow the pale L on its face. After a quarter-turn, the cube fits the space it occupied before. The marked face has gone around the corner. What returned depends on what you were following.

![The same cube at zero and ninety degrees, photographed from the same viewpoint. Its outline returns; the marked face moves.](/book-review/doc/book/iterations/2026-09-23-rotation-return-and-sweep/marked-return.png)

*Two paused moments, seen from one place. Follow the mark from the left-hand face to the right.*

Press **BOUNDARY**. A cylinder appears around the turn. Look for the corner that reaches its round side. Then watch that corner leave: the contour keeps the place even when the corner is elsewhere.

Pause the motion. The cube stops inside the cylinder, leaving part of it empty. The contour describes the outside of all the positions the cube occupies over a full turn. A turn needs room that a single pose leaves empty.

Change **SHAPE** to the triangle. Its upright edge lies on the axle. As the face turns, the wide bottom sweeps a circle and the sloping edge describes a cone. Hide the boundary and try following that form with your eyes. Bring it back. The outline helps you keep a whole turn in view, but it has made no new solid wall.

![The rotating cube inside its cylindrical boundary and the triangular face inside its conical boundary.](/book-review/doc/book/iterations/2026-09-23-rotation-return-and-sweep/spaces-of-a-turn.png)

*The cyan lines describe a full turn. Each amber body is paused in one position; the outline is no new solid. Both views use the same camera.*

The same operation can describe different spaces because the body brought to it differs. The triangle from Primitives has acquired another possibility without acquiring another corner.

<!-- @ -->

Walk on into the last court. Let the repeated turns surround you.

<!-- @boolean_tunnel -->

## Inside the turns

Look through the first hollow cube. Four more stand beyond it. Walk inside and follow a corner with your eye.

Each segment adds eighteen degrees.

```gdscript
angle_deg = i * rotation_per_segment
```

Five segments occupy fifteen metres. They stand still; your walk unfolds their differences. Turn back and the sequence unwinds.

Subtracting an inner box made each cube hollow. The turns arrange those openings around a continuous floor.

Which edge did you take for a horizon?

<!-- @carousel_cake -->

## A rate instead of an angle

Step out beside the turning stacks. Follow a stripe on a low layer, then near the top. Stand still. Their relations keep changing.

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
var angle: float = _rotation_angle * layer_speed
```

The lowest layer turns at half a radian per second; each successive layer turns 1.2 times as fast. In the tunnel, eighteen degrees separated neighbours. Here a rate changes the angle through time.

Eight layers make each of the five profiles: a brim, a column, a taper, a pinched spindle, a flare. They share heights and speeds. Walk between them and compare the room each leaves around itself.

Your body has supplied a measure throughout this hall: what could carry it, obstruct it, surround it. The next hall changes the size of the surroundings while your body stays the same. What will fit then?
