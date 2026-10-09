tiling_principles uses the same binary diagonal tile across six five-metre floor fields. TURN MOTIF changes the source orientation. EXCEPTION changes one designated cell in one field. This introduces arrangement before the Color chapter.

Implementation: commons/artifacts/regularity/. Current authored placement: map_data.json. Read final.md for the supported controls and sequence bridge.


## From indexed places to a surface — 23 September 2026

Builds on Array and Tutorial_3D: the indices now choose a relation among repeated motifs. Prepares Tutorial_Tiling_Walls, which uses the same image generator with a different orientation and backing.

texture_for(rule) produces a 256×256 RGB image. Dividing pixel coordinates by 32 locates a tile; the remainders locate a pixel inside it. The common motif is the test u > v. Six rules translate that motif, invert it in alternating cells, add quarter turns based on the address, reflect alternate columns, offset alternate rows, or turn one designated cell when exception is enabled. The array is eight tile widths across; shifted rows show partial tiles at the edges. The six images are displayed on 5 m square floor quads at local y=0.025, using nearest texture filtering.

TURN MOTIF advances phase modulo four and regenerates all six images. EXCEPTION toggles one boolean; rule 5 uses it at image cell (3,3). There is no randomly selected cell and no per-cell editing interface. The picture supplies no collision shapes: the existing museum floor supports the body. Changing pixels does not excavate a black region or raise a white one.

### Shared book illustration

The six panels of one-motif-six-relations.png come directly from the textures attached to the production artifact in the isolated museum. They are enlarged with nearest-neighbour sampling and labelled for the book; no substitute pattern generator was used. The source square is the upper-left 32×32 tile cropped from rule 0. Common phase is zero; the last field has its local exception on. Original texture PNGs and actual museum views are retained in doc/book/iterations/2026-09-23-tiling-underfoot.

### Evidence

42 focused checks pass. Supplied pointer events exercise both shared buttons. One source turn changes all six images; four turns recover the original bytes. The exception affects only the designated 32×32 cell in the sixth image, with the other five unchanged; turning it off restores the initial field. Floor transforms and sampled collision contacts remain unchanged.

Supplied W input drives the actual museum controller/capsule across TRANSLATE, across the hall and across ONE EXCEPTION, including their outer image boundaries. The recorded feet remain on level ground. Camera views are separately staged. This establishes the particular image/support distinction, not a worn-headset comfort check or a claim that a viewer perceives an illusion of depth.

No production artifact, geometry, controls, map or sequence changed in this pass. Current source hashes, runtime report and publication checks accompany the review. The existing startup unrecognized-UID message remains a separate issue; no GDScript runtime error occurred in this focused run.
