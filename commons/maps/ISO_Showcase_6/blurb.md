# ISO Showcase 6 — Torus + Shapes Gallery

A torus is a surface with no boundary that encloses no volume. The hole defines it more than the skin. Here, marching cubes extracts that paradox into triangles — GPU threads evaluating a distance field, finding where inside becomes outside, stitching vertices along the threshold.

The gallery arranges sculptures side by side. Each one a different implicit function made explicit. Sliders control noise scale, iso level, chunk resolution — drag them and watch geometry dissolve, reform, split into islands. The mesh breathes. Flood-fill traces individual elements: connected components that were one surface a moment ago, now three, now seven.

A torus has genus one. One hole. Topology says the hole is the invariant — deform the surface however you want, the hole persists. Identity defined by what passes through.