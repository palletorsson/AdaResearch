# Noise Perlin Simplex — Summary

Noise_Perlin_Simplex is the eighth map in the Noise sequence. It compares the two noise algorithms at the centre of the sequence, side by side. Two identical volumes sit next to each other on a central table; one is filled with Perlin noise, the other with Simplex noise. The two use the same seed, the same frequency, and the same amplitude, so any visible difference is algorithmic rather than parametric.

Perlin noise, introduced in 1983, interpolates random gradients across a hypercubic grid. Simplex noise, introduced by the same author in 2001, samples across a simplicial grid — triangles in two dimensions, tetrahedra in three. The replacement of cubes by simplices changes the cost of the algorithm and the shape of its artifacts. Perlin's outputs show weak alignment with the coordinate axes; Simplex's outputs do not.

The map annotates both volumes. Crosshairs on each axis highlight where axis-alignment artifacts appear in the Perlin sample. A toggle rotates the Perlin volume through forty-five degrees to demonstrate that the artifacts travel with the grid, not with the geometry. Side panels trace a brief history of each algorithm and list where each is preferred.

Within the sequence, this is the implementation map. The sequence has been teaching how to use noise; this map asks how noise is made.
