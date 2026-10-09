# A field of colour samples — implementation

The museum placement opts in with `#layout:spatial_gradient`. In `algorithms/color/pillarcolorcollection/pillarcolorcollection.gd`, both the pillar samples and the floor shader evaluate the same HSV field:

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)
```

The floor evaluates between the discrete samples. This is a coordinate field, not additive light mixing. The prefab's 4 m height is multiplied by 1.15. Its material receives the colour sampled at the pillar's local position. Labels identify the grid address and colour code.

`color_sets_overview` uses `#mount:wall` to arrange twelve existing sets in six columns and two rows. Swatches retain the existing grab interaction. The named palette construction remains separate from the spatial HSV field. Other placements retain the default layouts.

The former tutorial is archived under `doc/space/color-recovery-2026-09-09/before/commons/maps/Color_Pillar`.
