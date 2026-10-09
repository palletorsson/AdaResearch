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

## Native comparison and carrying, 23 September 2026

The shared book figure pairs an elevated museum view with the view from the ordinary walker's reached position plus 1.65 metres. Both show the actual placed field. No geometry, controls or placement changed. The floor remains unshaded; columns receive lighting, so equal assigned values do not require equal rendered pixels.

32 focused assertions pass in the isolated production museum: all 35 material samples and labels match the coordinate function, floor UV corners agree with its directions, saturation/hue comparisons hold, twelve named wall sets are present, and a real wall swatch follows the production pickable mechanism through pickup, supplied movement and release. The swatch is returned to its original placement. Its label uses an 8-bit hexadecimal RGB code and the nearest entry in the artifact's small name list, selected by squared RGB distance; it does not establish a culturally universal name or perceptual distance.

Supplied key input drives the ordinary museum controller along a gap between columns, across a gap between rows and back toward the pale edge. These selected paths retain ground support. Figures and the run record are in `doc/book/iterations/2026-09-23-pillar-colour-between/`. No tracked-controller reach, headset comfort, colour calibration, learner or performance claim.
