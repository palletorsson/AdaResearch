# Unit Circle — two coordinates from one angle

## Learning elements

- Radians and angular speed.
- Sine and cosine as signed coordinate ratios.
- A circle-position function: centre, radius and angle.
- A path and a graph with different horizontal axes.

In the museum, follow the bright point around the circle. Its vertical rod grows, disappears and grows below the centre. Stop the point with the nearby angle slider. At the top, the vertical offset is one metre and the horizontal offset is zero. Move through another quarter turn: those roles change.

Sine Space used sine to set heights. Here we open that function's geometric relationship: at radius one, cosine gives the horizontal offset and sine the vertical offset. We continue with our PointBody sphere and the thin cylinder from Lines. This sphere is a marker whose position we prescribe; pickup and collision are disabled in this study. The previous physical sphere remains available in its own lesson.

## Place the study in the existing hall

Use the museum and installed XR Tools from Day Zero. Save the three files below together. Attach `04_circle_coordinates.gd` to an empty Node3D in the Unit Circle hall's clear forecourt. The verified placement is hall-local `(11, 0, 10)`, Y rotation `180°`, scale `1`. No child nodes or scene paths are required. The museum supplies the player, camera, light and floor.

The local XY plane holds the circle. Positive X goes right and positive Y goes up when viewed from its positive Z side. The centre starts 1.5 metres above the floor. Angles increase counterclockwise from the rightmost point. `PI` radians is half a turn; `TAU` is a full turn. Angular speed is radians per second, so `PI / 2` makes one turn in four seconds.

The graph beside it shows one complete turn. Its horizontal axis allocates four metres to `TAU` radians. It does **not** show the sphere's horizontal position. Its vertical offset is the same `radius * sin(angle)` used by the sphere. At each full turn, the graph marker returns from the right end to the left.

## The complete study

{CODE}

`circle_position()` returns a position without creating a new body. The centre supplies the location; the radius scales the two ratios. Keeping the centre outside that multiplication lets us move the construction without enlarging its distance from the origin.

The two short coloured rods show signed offsets through their endpoints. A rod has positive physical length even when its coordinate is negative; the readout supplies the sign. The grey connector joins the point to the graph marker at their shared height.

The loop in `_ready()` samples the two outlines once. It reuses the line renderer; it is drawing assistance, not another motion system. `_process()` advances one shared angle with `delta`, then updates both markers. There are no competing clocks. Change the radius or centre before running again so the sampled outlines and the moving markers use the same settings.

## Predict, stop, inspect

Set `running` to `false` and try these starting angles, rerunning after each edit. These are offsets from the centre, not world positions.

| Angle | X offset at radius 1 | Y offset at radius 1 |
| --- | --- | --- |
| `0.0` | +1 m | 0 m |
| `PI / 2.0` | 0 m | +1 m |
| `PI` | −1 m | 0 m |
| `3.0 * PI / 2.0` | 0 m | −1 m |

Restart with `running = true`. Half the angular speed: the same circle takes twice as long. Its radius and the graph's height do not change.

Now work independently: set the radius to `0.5` and the centre to `(0.5, 1.5, 0)`. Predict the top point's local position before running. Explain why the graph becomes half as high while its angle axis stays four metres wide. A successful variation preserves the shared height and the circle's distance from its new centre.

## Carried files

These are the unchanged PointBody from the preceding lessons and LineSkin from Lines. Keep your existing copies if they match. They provide the sphere and cylinder drawing; the new lesson is the coordinate function above.

{POINT_CODE}

{LINE_CODE}

One angular state now produces a visible position and two coordinate readings. In the next hall, many moving bodies will affect one another. A shared trigonometric formula alone does not make that coupling.
