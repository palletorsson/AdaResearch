# Finite Element Method

Cut a body into pieces. Solve each piece. Stitch the answers back together. The Finite Element Method divides continuous matter into discrete elements — tetrahedra, hexahedra — each obeying its own local law of deformation. Stress and strain computed per element. A global stiffness matrix assembled from local contributions. Then the linear system is solved, and the whole structure responds.

Poke the mesh. Watch stress propagate. Pin the edges and load the center — the beam bends, sags, yields. Each element knows only its neighbors, yet the bridge knows it is failing. Engineering simulation made tangible: not prediction from first principles, but approximation from finite basis functions projected onto infinite-dimensional truth.

The continuous is unknowable. The discrete is computable. FEM is the bargain — trade perfect knowledge for solvable systems, and discover that the approximation, at sufficient resolution, becomes indistinguishable from the real.