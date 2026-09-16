# One centre, then many centres

Find the middle of each blade. Follow both ends through the turn. Cross the Y blade when it aligns with its level banks. Climb the X blade to the higher grid, then try the Z blade's sideways climb. Which points changed height, and which stayed?

The centre node turns its child panel and matching collision together:

```gdscript
station.pivot.basis = Basis(station.axis,deg_to_rad(degrees*float(station.sign)))
```

The panel's local position is zero. Its ends lie on either side of that centre. The different grid levels show where a rotating surface can take a walker.

Beyond the still landing, choose a column in the 2D array. Walk +z through the increasing angles. Repeat in another axis band. Note the last row you can walk through and inspect that row from the aisle.

```gdscript
var degrees := float(cube.get_meta("row"))*row_angle_step
cube.basis = rotation_for_band(band,degrees)
```

The row supplies the amount of rotation. The band supplies the axis. Each centre stays fixed. Compare transverse rises in X, horizontal footprint changes in Y and longitudinal ridges in Z. Compare the test walker's stopping points in `ada_run/rotation_studies_checks.json` with your own movement.

The gradient reaches ninety degrees. Inspect the final row, where a cube can recover an axis-aligned outline, then look back at the route needed to reach it. An endpoint and a passage are different things.
