# The colour between the pillars

<!-- @pillarcolorcollection -->

Stand where the colours are pale. Follow one line of pillars farther into the field. The hue stays recognisable while its saturation increases. Now walk across that line. The hue changes too. Two directions, two different ways to change a colour.

There are thirty-five pillars, but the floor does not stop at thirty-five colours. Look between the columns. The smooth field continues where no pillar stands. Each pillar is a sample of that field at a particular position.

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)
```

The address is doing work. One coordinate chooses a place along the hue range; another chooses saturation. Value stays at 0.95. The gaps between columns contain possibilities that the collection has not put into a body.

The field is larger than its former arrangement: five columns by seven rows, with 3.2 metres between samples. Each pillar rises 4.6 metres. Walk close enough to read a sample's address and colour code, then step back until several pillars overlap. The computed values remain fixed. What their company makes visible keeps changing.

<!-- @color_sets_overview -->

Beyond the field, twelve collections hang on a framed wall. Their colours have names, and their groups have names too. These sets were assembled. The field was evaluated. Both are ways of deciding which colours belong together.

Take a swatch if you want to carry that decision into another view. Its label makes it identifiable. It cannot carry every relationship the colour will enter. Compare it with a pillar, with another swatch, with the space around your hand.

The wall does not finish the gradient. It gives you another method of collecting it, with another set of omissions.

<!-- @ -->

On the next floor, follow what happens when a rule assigns colours to grid cells. Keep the spaces between these samples in mind.
