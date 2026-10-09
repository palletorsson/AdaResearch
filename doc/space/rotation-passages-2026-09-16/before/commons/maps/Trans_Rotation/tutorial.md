# One centre, many centres, an enclosure

1. Find the fixed middle of each 8.4 m blade. Compare Y's level crossing with X's forward climb and Z's sideways climb. Cross at the held alignment; return down the grid wedges or use the still aisle. All static banks come from the grid.
2. Walk forward through each two-column, six-row array. The angles are 0, 18, 36, 54, 72 and 90 degrees. Compare X, Y, Z and fixed X-then-Y-then-Z order without changing cube size or centre spacing. Then compare the cyan 0.44 m and pink 1.20 m test bodies: the same 1.6 m height, 2 m/s forward input, gravity, 45-degree slope limit and 0.15 m floor snap. Rings retain endpoints; readouts include sideways displacement. REPLAY starts both passes again. A wider body need not stop sooner: Z can carry it sideways into a continuing route. These are collision trials, not a proof that another body or movement cannot pass. Inspect a stopped route from an aisle. Ninety degrees can restore a flat-looking endpoint without making the intervening passage easy.
3. Walk through five hollow tunnel segments with the same eighteen-degree spatial increment. Then observe the five carousel profiles: their layers use angular speeds of `0.5 * pow(1.2, i)` radians per second. Separate an angle assigned by position from an angle accumulating with time.

```gdscript
station.pivot.basis = Basis(station.axis, deg_to_rad(degrees * float(station.sign)))
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

A rigid rotation preserves a solid's internal distances and topology. Passage also depends on its neighbours, pivot, collision and the moving body. The tunnel's subtraction supplies its hole; rotation arranges the holes. The carousel's radius supplies a bridge to scale: equal angular speeds need not imply equal rim speeds.

The compact arrangement retains full-size crossing blades and array cubes. It reduces repetition counts and removes one duplicate cake; the five distinct cake profiles remain available together. Headset traversal and comfort still require a human review.
