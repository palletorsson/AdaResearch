# Noise Columns — Summary

Noise_Columns is the second map in the Noise sequence. It introduces coherent noise as a tool that operates on geometry rather than as a statistical distribution to be described. The space is a small terrain field. Classical stone columns stand in rows at the edges; between them, the ground rises and falls according to a 2D Perlin field lifted into height.

The terrain is built by sampling the noise function at each grid cell and extruding the sample as the cell's altitude. Low values become valleys, high values become ridges. The result is continuous rather than jagged: each point agrees with its neighbours, because the noise function is smooth. The learner can walk the whole field without stepping over discontinuities.

At the far end, a row of columns stands partly ruined. A slider at the entrance drives a displacement parameter that pushes each column's vertices outward along its normal according to a 3D noise function. Raising the slider melts the columns into drifting stone; lowering it returns them to classical form. The operation is reversible, so the learner sees noise as sculpture rather than damage.

Within the sequence, Columns is the first map where noise leaves the graph and becomes a spatial operator. Noise_One will extend the technique by stacking multiple frequencies into a composite field.

## The trio (2026-09-12)

`MeltingBerniniScene:180#stand:trio#speed:0.9` stands on the hall's east side as three marble columns on one bench: the same height, stone, width and mesh resolution, the same mapped displacement range, in one frame. One is held at a fixed phase, the column you can recognise as a column. One melts on the shipped sine. One melts on a real coherent field seeded by the room. The drivers are dealt to the three places from that seed, and no plate says which is which until REVEAL is pressed.

The instrument between them prints both drivers at the same instant as a phase and as the height the top has lost, in a range they share exactly: `periodic phase 0.926 -> drop 0.65 m`, `field phase 0.391 -> drop 0.27 m`, `same range 0.00-0.70 m`. FREEZE stops the clock, so the shape can be walked around and rebuilt at a named time twice with the same result. SPIN turns the columns without moving a vertex. MARBLE takes the veining off and leaves the same geometry underneath.

The tell is not in any shape. Over forty-eight seconds the periodic column's returns are evenly spaced to a twentieth of a second while the field column's vary by nearly two: a clock returns on time and a field returns whenever. The rebuild is bounded to twelve a second at forty by sixteen segments, about three and a half milliseconds a mesh, and no column or plinth carries a collider - these hold nothing up.

Corrected in the same pass: the room's description claimed 3D Perlin erosion and an undoing of disorder while the melt was a sine with no field in it, and the placed scene carried both a scriptless root (so no map token could configure it) and a camera marked current, which took the view in every hall that placed it.
