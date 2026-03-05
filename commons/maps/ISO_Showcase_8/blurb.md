# ISO Showcase 8 — Terrain + Rhizome Cave

Marching cubes walks a grid of densities. At each cube, eight corners vote: inside or outside. The algorithm consults its lookup table — 256 possible configurations — and cuts triangles along the threshold. Terrain rises from noise. Caves hollow themselves out.

Two demos. The terrain generator lets you tune noise parameters in real time — watch mountains flatten, valleys deepen, the entire landscape rewrite itself as you drag a slider. The rhizome cave grows differently: no top-down sculpting, but a network that branches, reconnects, burrows through solid volume like mycelium through soil.

One system imposes form from above. The other lets form find itself from within. Both extract surface from the same math — the zero-crossing where density flips sign. The boundary doesn't separate inside from outside. It generates both.