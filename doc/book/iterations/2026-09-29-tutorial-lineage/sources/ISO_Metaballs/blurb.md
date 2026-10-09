Each metaball is a point radiating influence. A distance field — strongest at center, fading outward. One sphere alone is trivial. But place two near each other and their fields sum. Where combined density crosses the threshold, a surface appears. Not two objects touching. One object, born from proximity.

The marching algorithm traces this threshold — finds the skin where inside becomes outside. Move the sources closer: the surface bulges, stretches, merges. Pull them apart: it pinches, thins, splits. No mesh editing. No vertex welding. The geometry is a consequence of relationship.

Metaballs are the implicit surface at its most liquid. Form without skeleton. Identity without boundary. Two fields overlapping don't collide — they become one body, then separate again, unchanged. Merging is not loss. It's the native state.

---

Two methods. Same phenomenon. Sixty CPU-driven blobs approximate organic form through sphere deformation — Kouhei Nakama's approach, where geometry chases the field. Nine shader-driven balls bypass geometry entirely — SDF raymarching renders the implicit surface directly on the GPU, never extracting a mesh at all.

Metaballs are isosurfaces of summed radial functions. Where influence overlaps, surfaces merge. Separation and fusion governed by a single threshold. The math doesn't distinguish between one blob and two — only whether the field exceeds the boundary.

One method builds triangles to describe the surface. The other evaluates the field per pixel and stops when it hits the edge. Both find the same thing: the contour where inside becomes outside. The surface was always there. The question is whether you extract it or just look until you see it.
