# Point One — Summary

Point_One is the opening map of the Primitives sequence. It isolates the simplest gesture in 3D space: placing a single point. A point is position without extension — no width, no length, no duration. In Godot it is a Vector3, three floating-point numbers bound to a live coordinate system and drawn by a render loop that was already running before you arrived.

The map is arranged on a small grid inside a dark ambient sphere. A continuous platform gives you ground to stand on. One cell away, a static point sits fixed in place as a reference mark. Another cell carries an interactive point you can grab, drag, and release into new coordinates. Same data type, different behaviour: one says where, the other lets you say where.

The infrastructure is made visible rather than assumed. A three-metre coordinate triad names the axes X, Y, Z. A gyroscope gadget reports your orientation against them. A frame counter shows the loop iterating whether you act or not. A small script runner prints the constructor `Vector3(x, y, z)` so the point's definition is not hidden behind the rendered mark.

Within the sequence, Point_One establishes the vocabulary the rest of Primitives extends. Two points will become a line. Three, a triangle. Grids, traces, and meshes all rely on this first commitment to location. The map's task is narrow on purpose: before anything else can be placed, there has to be somewhere to place it, and someone willing to instantiate the first mark.
