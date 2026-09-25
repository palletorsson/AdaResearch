# What did the sample keep?

<!-- @cube_mound_scene -->

Press DROP and watch twelve cubes fall. They turn, strike the ground and meet one another. Do not press the next button immediately. Choose the moment you want the next construction to inherit.

SAMPLE freezes the cubes at that moment and builds a surface from their centres. It can record a settled pile or an unfinished fall. The word sample matters: the new mesh is not the physical event preserved in full.

The positions must first belong to the model's local frame:

```gdscript
positions.append(to_local(cube.global_position))
```

Without that conversion, a mesh attached beneath the translated artifact could receive its museum displacement twice. Coordinate systems are part of the construction, even when an object makes us forget that it has a parent.

Each centre is mapped to a voxel address. The implementation then marks an axis-aligned neighbourhood around that address and emits faces where occupied cells meet empty ones. The extent is deliberately described here as the program computes it: `ceil(cube_size / voxel_size)` cells in each direction. It is an enlarged centre-based approximation. The cubes' rotations and exact contact surfaces are not copied.

Press ORIGINAL to alternate the frozen bodies with the sampled surface. They share the recorded centres but need not share their silhouette, openings or contact shapes. The sampled collider stays active during this visual comparison. ORIGINAL does not secretly restore the earlier physics experiment.

VOXEL rebuilds from those same frozen positions at a different cell size. Look for an opening that becomes filled or a boundary that moves. A change of resolution can change the opportunities offered by a surface, not merely its smoothness. More detail has a cost, but less detail also makes decisions. Neither setting is innocent by virtue of being easy to compute.

DROP begins another physical run. The previous generated collider is removed when its mesh is replaced, so an invisible old sample does not remain as an extra law inside the new one.

<!-- @ -->

<!-- @dome -->

Turn to the dome. Here the empty region has not come from a wandering point or a fallen cube. A geometric operand has cut it from a stock volume.

CUT cycles through the cast, the uncut blank, the cutting cores and a section. The cores show the shapes that made the absence. A hole can carry as much authorship as the material around it.

```gdscript
cut.operation = CSGShape3D.OPERATION_SUBTRACTION
```

Return to the cast after seeing its operands. The result may now look less self-evident. It was one possible agreement between volumes and operations. Moving a cutter would make another agreement; it could admit a body, divide an interior or close an opening we had begun to rely upon.

The layered membrane remains nearby. Its repaired scene makes a further contrast available: nested displaced surfaces can suggest thickness without being one filled solid. Look between them. Do not assume that a convincing skin carries the collision or interior its appearance promises.

These works give us different ways to materialize a decision: sample an event, subtract a volume, arrange surfaces. Next we will compose operations we already know, while keeping two questions distinct: how is an image copied, and how are places connected?

<!-- @ -->
