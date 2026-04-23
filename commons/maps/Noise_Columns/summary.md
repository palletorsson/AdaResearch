# Noise Columns — Summary

Noise_Columns is the second map in the Noise sequence. It introduces coherent noise as a tool that operates on geometry rather than as a statistical distribution to be described. The space is a small terrain field. Classical stone columns stand in rows at the edges; between them, the ground rises and falls according to a 2D Perlin field lifted into height.

The terrain is built by sampling the noise function at each grid cell and extruding the sample as the cell's altitude. Low values become valleys, high values become ridges. The result is continuous rather than jagged: each point agrees with its neighbours, because the noise function is smooth. The learner can walk the whole field without stepping over discontinuities.

At the far end, a row of columns stands partly ruined. A slider at the entrance drives a displacement parameter that pushes each column's vertices outward along its normal according to a 3D noise function. Raising the slider melts the columns into drifting stone; lowering it returns them to classical form. The operation is reversible, so the learner sees noise as sculpture rather than damage.

Within the sequence, Columns is the first map where noise leaves the graph and becomes a spatial operator. Noise_One will extend the technique by stacking multiple frequencies into a composite field.
