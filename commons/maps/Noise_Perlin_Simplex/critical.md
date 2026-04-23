# Two algorithms, one problem — Perlin 1983 versus Simplex 2001 and the politics of refinement

Perlin noise and Simplex noise solve the same problem: produce smooth, pseudo-random values that vary continuously across space. Both were invented by Ken Perlin, eighteen years apart. The first uses random gradients on a hypercubic grid; the second uses a simplicial grid — triangles in two dimensions, tetrahedra in three. The difference looks cosmetic; the consequences for artifact quality and computational cost are substantial.

Thomas Kuhn's work on scientific revolutions argued that technical refinement is not always continuous. Sometimes a later algorithm subsumes an earlier one; sometimes they coexist as alternatives with different affordances. Perlin and Simplex are not a succession; they are a choice. The 1983 algorithm is still in use, and the 2001 algorithm did not displace it. Refinement produced an alternative rather than a replacement.

Two identical volumes sit next to each other on a central table. One is filled with Perlin noise, the other with Simplex noise. Same seed, same frequency, same amplitude. Any visible difference is algorithmic rather than parametric. Perlin's outputs show weak alignment with the coordinate axes — faint rectangular biases that the hypercubic grid leaves as a signature. Simplex's outputs do not; the simplicial grid has no axis-aligned preferred directions.

The map annotates both volumes. Crosshairs on each axis highlight where axis-alignment artifacts appear in the Perlin sample. A toggle rotates the Perlin volume through forty-five degrees to demonstrate that the artifacts travel with the grid, not with the geometry. Side panels trace a brief history of each algorithm and list where each is preferred: Perlin for 2D textures where the bias is imperceptible, Simplex for higher-dimensional applications where the bias compounds.

Kuhn would note the politics of the coexistence. A replacement algorithm is easy to narrate as progress; a coexisting alternative is harder. The map refuses the progress narrative. Perlin is not wrong; it is specific, and its specificity is useful. Simplex is not better; it is different, and its differences are useful in different places. The politics of refinement are in acknowledging the specificity rather than flattening it into a progress story.

The map's side panel on computational cost matters here. Perlin's cost grows exponentially with dimensions because the hypercubic grid has 2^n corners in n dimensions. Simplex's cost grows polynomially because the simplicial grid has n+1 corners per simplex. At two dimensions the difference is trivial; at four or more dimensions it is decisive. The choice between the algorithms is partly about artifact quality and partly about computational tractability, and the trade-off is structural.

Within the sequence, Perlin_Simplex is the implementation map. The sequence has been teaching how to use noise; this map asks how noise is made, and it insists that the answer is not singular. Two algorithms, one problem, and the politics of refinement is the space between them.

The learner leaves with both algorithms in their toolkit and with the understanding that choosing between them is a domain-specific decision rather than a ranking.
