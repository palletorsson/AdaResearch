# A three-coordinate colour field

Current implementation: 28 September 2026, ceiling revision. `pillarcolorcollection` retains its default named-palette layout; the museum's existing `#layout:spatial_gradient` placement opts into this field. No map geometry or placement was changed.

The 5 × 7 columns retain their 3.2 m spacing and 4.6 m height. Each column receives the hue `clampf(x/12.8,0,1)*0.85` and saturation `lerpf(0.25,1,clampf(z/19.2,0,1))`. Value is evaluated vertically from 0 at field-local y=0.46 to 1 at y=4.6. The coloured mesh has local vertex y=-1.8..1.8 and is scaled by the existing 1.15 prefab transform. The reference column at (-1.8,0,0) uses saturation zero, giving black-to-white independently of hue. It is separate from the thirty-five coloured samples.

`hsv_field.gdshader` draws fixed samples, vertical ranges and a V=1 ceiling using one HSV conversion. All are unshaded. The shader uses encoded RGB directly for Compatibility and decodes sRGB before writing ALBEDO for Mobile/Forward+. These choices preserve the coordinate comparison; they do not claim calibrated display output or uniform perceived lightness. The old floor and columns previously differed in lighting response; that comparison is superseded by the current shared display shader.

`field_sampler.tscn` inherits the existing grab-paper scene and pickup system. Its subclass disables grid snapping, retains XR/direct and ranged pickup, and freezes on release. Horizontal position samples the field directly; hand y=0.65..1.85 maps to V=0..1 and hence field y=0.46..4.6. The marker and FIELD Y readout make the represented coordinate explicit. RGB and HSV are updated from the same sample. Bounds clamp; horizontal clamping displays EDGE. This is a hand-scale controller for the taller field, not a claim that the marker is at the hand's physical height.

The sampler keeps the source H/S coordinates even at V=0. It does not round-trip them from RGB black. The existing wall swatches retain their colour and label when carried, offering the contrasting action of moving a stored value.

The ceiling is a two-sided PlaneMesh, 15.2 × 21.6 m, centred at (6.4,4.6,9.6). Its mesh-space x/z plus the explicit (6.4,9.6) offset recover the same field coordinates as the pillars. Colour clamps beyond the 12.8 × 19.2 m sample span. The overhang therefore covers the outer columns without rescaling their colours. It is a visual canopy with no added overhead collision or light source.

A 16.7 × 21.6 m near-black (#080a0e) plane at y=0.026 replaces the bright floor overlay, extending to include the separate grey reference. Its roughness is 1 and shading is unlit; existing floor collision continues to support walking. No map layout or artifact placement was changed.

Focused native checks cover all 35 ceiling-to-pillar coordinate/colour matches, full height, near-black ground, actual sampler pickup and release, RGB/HSV agreement, named swatches and ordinary-controller walks. The run report and native interior images are in `doc/book/iterations/2026-09-28-pillar-colour-ceiling/`. Compatibility rendering is exercised. Tracked-hand reach, headset comfort, display calibration and other rendering paths remain unverified.

---

## Historical record — the flat samples before this extension

The following record describes the previous fixed-value, lit-column implementation. Its dates and claims remain as historical evidence, not the current vertical encounter.

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
