The transport cube carried you without needing to turn. Here, a surface stays attached to its middle. Follow one end. Where does the other end go?

<!-- @rotation_wall_crossings -->

The green blade turns around y. Its centre stays over the gap while its ends sweep towards the grid on either side. At ninety degrees it pauses. Walk across the length that has arrived in your direction of travel.

The orange blade turns around x. Look at its middle before watching the edges. It has no hinge at the bank. One end descends as the other rises, like the blade of a large paddle wheel.

The far landing is three grid cubes higher. Wait for the blade to lie between the two levels, then climb it during the pause. Look back from above. The middle did not travel up with you.

At the blue blade, z is the axis. The same long surface tips sideways. Approach the lower grid bank beside it; the higher bank is across the blade, not straight ahead through the hall. Cross when it settles into its slope.

These blades are 8.4 metres long and 2.4 metres wide. Their middle is the origin of the turn. The x and z axles sit between the two landing heights; the upper surface meets the grid at about twenty-three degrees. The grid supplies the banks. There is no additional platform hiding how the crossing meets them.

```gdscript
station.pivot.basis = Basis(
	station.axis,
	deg_to_rad(degrees * float(station.sign))
)
```

The panel sits at zero under this pivot. Turning the pivot moves both ends around their shared middle. Its collision body turns with the visible surface.

Y leaves the green blade's height unchanged. X and z change the height of points away from the axle. The banks are arranged to receive those different movements. An axis, a centre, a length and a landing participate in the passage together.

The blades hold their crossing poses for twelve seconds, then continue in the reversed direction: the raised end of each climbing blade begins to descend. A half-turn brings this rectangular surface back to the same crossing geometry. Its other face can carry you now.

<!-- @ -->

Reach the still grid beyond the blades. The next experiment holds the orientations in place so that you can walk into their differences.

<!-- @rotation_array_compare -->

Four bands each contain four columns and ten rows of cubes. Begin at the row marked zero. Choose a column and walk forward along z.

Ten degrees. Twenty. Thirty.

The centres keep the same spacing. The angle increases with each row. Follow an outlined edge when a surface begins to look continuous: it still belongs to one cube.

Try the same forward movement in another band. Where do you climb, where do you descend, where does a face interrupt the route? If you stop, find the row number beside you. Try approaching that row from the still aisle and inspect what your feet were meeting.

In the x band the tilts make rises and falls across your direction of travel. In the z band they make ridges running along it. The y band turns the square footprints while keeping the tops horizontal. In the fourth band each cube receives x, then y, then z. Follow an edge there: its tilt no longer belongs to one plane. The same sequence of angle values produces different ground under a forward-moving body.

The angle keeps increasing through the difficult rows, towards ninety. If you cannot walk straight through, inspect what stopped you. A jump, a different column or a different body may expose another route; a tested limit belongs to a particular way of walking.

The rule fits in two lines:

```gdscript
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

Every cube turns around its own fixed centre. The row supplies how much; the band supplies the axis or the combination. The combined band applies a fixed order:

```gdscript
return Basis(Vector3.BACK, radians) * Basis(Vector3.UP, radians) * Basis(Vector3.RIGHT, -radians)
```

The rightmost matrix acts first: x, then y, then z. Time is not increasing these angles while you walk. Your movement through the array brings you to the next value.

At zero, all four bands are flat. Rotation has changed how their faces meet a body and one another. The cubes themselves have not been cut, joined or replaced.

<!-- @ -->

A surface can become a climb. Repeated surfaces can become a difficulty. Neither result lives in the angle alone.

The final row reaches ninety degrees. A cube can recover an axis-aligned outline there. The route to that flat-looking end still passes through everything before it. More rotation does not promise more obstruction. Carry the row where you stopped, and the possibility of another route, into the next hall.
