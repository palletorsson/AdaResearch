# The colour between the pillars

<!-- @pillarcolorcollection -->

Stand where the colours are pale. Follow one line of pillars farther into the field. The hue stays recognisable while its saturation increases. Now walk across that line. The hue changes too. Two directions, two different ways to change a colour.

There are thirty-five pillars, but the floor does not stop at thirty-five colours. Look between the columns. The smooth field continues where no pillar stands. Each pillar is a sample of that field at a particular position.

![Thirty-five columns above a continuous colour field, and the same installation seen from within.](/book-review/doc/book/iterations/2026-09-23-pillar-colour-between/field-and-passage.png)

*The same field, seen from above and from between the columns. A colour continues across the ground where no pillar stands.*

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)
```

`p` is a position measured from the field's first sample. Dividing by 12.8 and 19.2 turns the distances across its two spans into fractions: `u` and `v`. `clampf` keeps each fraction between zero and one.

Stay in one column of samples and follow it from the pale end to the far end. Its `u`, and therefore its hue, stays fixed. At the first row, `v` is zero and saturation is 0.25; at the last, `v` is one and saturation is 1.0. `lerpf` supplies the values between them. On the way back, the same hue grows pale again.

Value stays at 0.95 throughout the field. You have varied one part of HSV while keeping two still. The gaps between columns contain possibilities that the collection has not put into a body. They are also where you can walk.

Five columns by seven rows, with 3.2 metres between samples: the field gives the rule room to be walked. Each pillar rises 4.6 metres. Walk close enough to read a sample's address and colour code, then step back until several pillars overlap. The computed values remain fixed. What their company makes visible keeps changing.

<!-- @color_sets_overview -->

Beyond the field, twelve collections hang on a framed wall. Their colours have names, and their groups have names too. These sets were assembled. The field was evaluated. Both are ways of deciding which colours belong together.

Take a swatch if you want to carry that decision into another view. Its label pairs a hexadecimal RGB code with the nearest colour name from a small list. The code travels with it; its neighbours stay on the wall. Compare it with a pillar, with another swatch, with the space around your hand.

The wall does not finish the gradient. It gives you another method of collecting it, with another set of omissions.

<!-- @ -->

On the next floor, follow what happens when a rule assigns colours to grid cells. Keep the spaces between these samples in mind.
