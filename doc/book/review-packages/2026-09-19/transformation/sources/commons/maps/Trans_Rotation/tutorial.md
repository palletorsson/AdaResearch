# One centre, many centres, an enclosure

1. Find the fixed middle of each 8.4 m blade. Y offers a level crossing; X and Z retain held climbing slopes. Then board their small level end-platforms: X travels forward along z and up3m, Z travels sideways along x and up3m. Each platform follows a180-degree upper arc while remaining upright, with12-second docking pauses and a12-second turn. It reverses along the upper arc for the return. Compare the blade's changing orientation with the platform's fixed upright basis; remaining on a bare blade through vertical cannot be a standing ride. Grid wedges and still aisles provide returns.
2. Walk forward through each two-column, six-row array. The angles are 0, 18, 36, 54, 72 and 90 degrees. Compare X, Y, Z and fixed X-then-Y-then-Z order without changing cube size or centre spacing. Then compare the cyan 0.44 m and pink 1.20 m test bodies: the same 1.6 m height, 2 m/s forward input, gravity, 45-degree slope limit and 0.15 m floor snap. Rings retain endpoints; readouts include sideways displacement. REPLAY starts both passes again. A wider body need not stop sooner: Z can carry it sideways into a continuing route. These are collision trials, not a proof that another body or movement cannot pass. Inspect a stopped route from an aisle. Ninety degrees can restore a flat-looking endpoint without making the intervening passage easy.
3. Walk through five hollow tunnel segments with the same eighteen-degree spatial increment. Then observe the five carousel profiles: their layers use angular speeds of `0.5 * pow(1.2, i)` radians per second. Separate an angle assigned by position from an angle accumulating with time.

```gdscript
station.pivot.basis = Basis(station.axis, deg_to_rad(degrees * float(station.sign)))
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

A rigid rotation preserves a solid's internal distances and topology. Passage also depends on its neighbours, pivot, collision and the moving body. The tunnel's subtraction supplies its hole; rotation arranges the holes. Compare the room left around the five carousel profiles. Carry the relation between an object's dimensions and your body into Scale, where the surroundings grow while the visitor keeps the same size.

The compact arrangement retains full-size crossing blades and array cubes. It reduces repetition counts and removes one duplicate cake; the five distinct cake profiles remain available together. Headset traversal and comfort still require a human review.

## Standing through the turn

`wall_crossings.gd` now advances on physics ticks at priority−110. `rotation_rider_deck.gd` detects actual supported feet and applies each platform displacement to the rider. For XR it uses the same incremental body/origin movement as the transport cube and rebases only its own moving-ground contact, preventing double carry. A jump or step off releases the rider. The player's pitch, roll and room-scale camera offset are preserved.

The deck's top follows `(0,1.5,0) + R(axis, angle) * radial + side_offset`. X uses radial `(0,-1.5,-3.5)` and side offset `(-2.2,0,0)`; Z uses radial `(-3.5,-1.5,0)` and side offset `(0,0,-2.2)`, turning in the opposite sense so both trips use the upper arc. The platform's basis stays upright. Its fixed bracket height compensates for the original blade's thickness-adjusted axle. Both endpoint tops meet grid heights0m and3m.

Tests must cover the moving ride, natural boarding, departure and the full body volume around the arc. A static ramp crossing test alone did not cover the failure reported in VR.
