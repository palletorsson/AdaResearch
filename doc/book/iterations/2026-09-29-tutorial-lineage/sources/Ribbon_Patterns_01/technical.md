# A source becomes four layers

The two primary artifacts are `grid_2d_4x4` and `grid_3d_4x4x4`. The latter enables `#lesson:layer_pattern`, pairing with the planar artifact inside the same museum hall. Both sit in the west bay so the central museum route does not divide the comparison.

The fixed source is a 4 by 4 array of palette indices, stored as `SOURCE[z][x]`. The lesson fills `values[y][z][x]`, a 4 by 4 by 4 array. In REPEAT, each height layer reads `SOURCE[z][x]`. In SHIFT, it reads `SOURCE[z][(x+y)%4]`. Integer lookup changes the colours without changing cell positions. The existing CubeBaseMesh nodes display the values; each has its own material. Flat and volume source palettes agree.

Six pointer controls select X, Z and LAYER, switch SLICE/ALL and REPEAT/SHIFT, and UNDO the previous state. Index controls wrap at four. Undo holds up to 32 states. A turquoise frame marks the selected volume cell; the other marks its actual source lookup. The console spells out index order and shows 16 visible/64 stored in SLICE, or 64 visible/64 stored in ALL.

Slice visibility only changes Node3D.visible. It retains all 64 nodes and array values. The study freezes the existing pickup cubes and disables their collection detection in these two instances, so decorative bobbing and collection do not change the addresses being compared. These displays are not a climbable or carveable solid. Other instances retain pickup behaviour.

The 3D artifact rebuild now detaches old generated children synchronously before generating replacements. It also retains configuration received before _ready and applies it after the default build. Previously early and deferred initialization could leave duplicate lattices. The probe counts physical Cube_ children as well as the lesson's references.

Primary/book anchors agree. The other nine artifacts remain secondary; sorting is an optional revisit rather than a required step in this lesson. Headset reach and continuous gestures are deferred. Rendering uses coloured cube meshes, not a newly authored volume shader; the closing shader/fabric studio remains later in the route.
