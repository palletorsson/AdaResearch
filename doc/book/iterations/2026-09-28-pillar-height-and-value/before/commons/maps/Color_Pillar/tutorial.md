# A field, thirty-five samples, twelve collections

Begin at the pale edge of `pillarcolorcollection`. Follow one line of columns into the field, then cross that line. Ask which colour property each direction changes before introducing its name.

There are five columns by seven rows, 3.2 metres apart. The continuous floor and the pillar materials use the same position-based HSV rule. X changes hue; Z changes saturation. Value remains 0.95. Each 4.6-metre pillar puts one sample of that field into a body.

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25, 1.0, v), 0.95)
```

Read a pillar's address and hex code. Compare it with the floor around its foot, then look between the pillars. The field has values in places where the collection has no column. The floor is unshaded while the columns receive lighting, so a shared computed colour need not produce an identical visible patch.

The museum token selects `#layout:spatial_gradient`. This installation has no palette-cycling control: it holds the field still so the visitor can move through its samples. The artifact's other, named-palette layout remains available elsewhere.

Next approach `color_sets_overview`. Twelve named collections hang on the framed wall. Take a labelled swatch and compare it with a pillar or another swatch. These collections read authored lists of colours; they do not derive their membership from the floor's coordinate rule. A name makes the swatch identifiable without fixing every relationship it can enter. Its label stays the same after it leaves the collection. Compare whether it still looks at home beside a pillar or a swatch from another set. The collection titles are authored associations; they do not define the complete colours of the artists or movements they name.

Keep the other colour artifacts available as comparisons. `visual_color_mixing`, `grab_rainbow_stick`, `SpectrumVisualizer` and `dark_sphere` do not replace this first route through field, sample and collection. They can become further encounters when their particular action helps the inquiry.

The next hall, `Color_Grid_Pallet`, returns to an address and lets the visitor write a colour there. Ask what must be stored for an exception to remain after the selection moves away.
