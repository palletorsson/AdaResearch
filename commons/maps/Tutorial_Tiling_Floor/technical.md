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


## A local rule and its larger consequence — 28 September 2026

The placed tiling_principles artifact now constructs tiling_rule_study.gd at its entrance. The raster function is shared in tiling_pattern.gd. Original comparison fields remain 8x8, 32 pixels per tile, with the same phase and exception controls. A regression probe compares all six rules, four phases and both exception states with the previous implementation: 48 byte-identical images.

The study retains an unchanged 4x4 reference. NEXT RULE cycles six candidate instructions; APPLY / UNDO enables or removes the selected addition. NEXT TILE visits all sixteen image addresses and displays the evaluated local instruction. Controls on this desk affect its own comparison, not the six fixed reference fields. TURN MOTIF on the original console changes the shared source phase and also refreshes the study. The one-tile exception in this study is independent of the original EXCEPTION switch. Tile boundaries and the selected-address outline are overlays, not pattern pixels.

The six study instructions are: add one quarter-turn everywhere; invert black/white where (x+y) is odd; add (x+y) modulo four quarter-turns; reflect odd columns; shift odd rows left half a tile; add a quarter-turn only at [3,3]. Each is compared against repeated source tiles. These are direct rules evaluated at each address, not a neighbour-to-neighbour propagation simulation. Odd shifted rows show partial tiles at the crop edges.

The 4x4 result is the exact top-left 128x128-pixel crop of a 512x512-pixel, 16x16 result. The latter occupies a 4.3 m floor quad. An orange boundary locates that window without changing its pixels or adding a collider. The single-cell exception remains at [3,3] in the full field; it is not repeated every four tiles. The existing museum floor provides support.

Evidence: doc/book/iterations/2026-09-28-tiling-rule-study/floor-report.json and its native screenshots. Supplied pointer events test the real controls. Camera positions are staged at eye height. This does not establish headset reach comfort or learner comprehension.
