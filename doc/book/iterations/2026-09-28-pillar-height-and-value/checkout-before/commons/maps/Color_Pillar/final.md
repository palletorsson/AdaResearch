# The colour between the pillars

<!-- @pillarcolorcollection -->

Stand where the floor's colours are pale. Follow one line of pillars farther into the field. The hue stays recognisable while its saturation increases. Now walk across that line. The hue changes too. Two directions, two different ways to change a colour.

Look up a pillar. Near its base, the colour disappears into black. Higher up, it becomes brighter. Height has become a third colour coordinate: **value**. Each pillar keeps one hue and saturation while showing the values between black and its brightest colour.

The grey column beside the field reaches white at the top. The coloured columns do not. Raising value brightens their colours; reaching white also requires saturation to be zero. Even at the same value, a yellow and a blue need not appear equally bright.[^value]

![The pillars rise from black towards colour; a grey reference stands beside the field.](/book-review/doc/book/iterations/2026-09-28-pillar-height-and-value/value-columns.png)

*Hue across, saturation along, value up. The bright floor shows a fixed-value slice laid beneath the columns.*

The floor keeps value at 0.95. It lets you follow hue and saturation without making the whole walk black at the columns' feet. It is a reference slice brought down to the ground, rather than the bottom of the colour volume. The floor and the coloured faces are drawn without the room's lighting changing them; this darkening is assigned by the colour rule.

Pick up the small sampling card. Raise it while keeping its place over the floor as steady as you can. Its colour brightens. A dot climbs the thin upright beside it, showing where that sample belongs in the full height of the field. Your hand moves through a shorter distance: the nearby scale maps that movement onto the whole column. The card names the represented height as FIELD Y.

Read the two lines on the card. **HSV** gives hue, saturation and value. **RGB** gives red, green and blue channel values. These are two descriptions of the same sampled colour. As you raise value while keeping hue and saturation fixed, the RGB channels increase together in the same proportions. Move across or along the field and the other coordinates change too.

The rule now uses all three coordinates of the represented point:

```gdscript
var hue := clampf(p.x / 12.8, 0.0, 1.0) * 0.85
var saturation := lerpf(0.25, 1.0, clampf(p.z / 19.2, 0.0, 1.0))
var value := clampf((p.y - VALUE_BOTTOM) / (VALUE_TOP - VALUE_BOTTOM), 0.0, 1.0)
return Vector3(hue, saturation, value)
```

`p` is the dot's position in the field. The horizontal divisions turn metres into fractions of the field's width and length. The vertical fraction runs from zero at the coloured column's bottom, 0.46 metres above the floor, to one at its top, 4.6 metres. `clampf` keeps the fractions within their ranges. `Color.from_hsv` converts the result into the RGB colour shown by the card.

Lower it again. At value zero, different addresses arrive at the same black. The hue and saturation coordinates remain on the card, but the colour alone can no longer tell you which address it came from.

Five columns by seven rows, with 3.2 metres between samples. The gaps contain colours the collection has not raised into pillars. They are also where you can walk. Adding a column in one of these gaps would give another colour a body and take away somewhere you could stand.

Release the card to leave a sample in place, then step back until several pillars overlap. Their values remain fixed. What their company makes visible keeps changing.

<!-- @color_sets_overview -->

Beyond the field, twelve collections hang on a framed wall. Their colours have names, and their groups have names too: Bauhaus School Colors, Frida Kahlo's Palette, Harlem Renaissance Jazz. Someone has chosen which colours will stand here under those titles. The names suggest histories that these small lists cannot contain. These sets were assembled. The field was evaluated. Both are ways of deciding which colours belong together.

Take a swatch if you want to carry that decision into another view. Its label pairs a hexadecimal RGB code with the nearest colour name from a small list. The code travels with it; its neighbours stay on the wall. Compare it with a pillar, with another swatch, with the space around your hand. The label stays the same in this new company. Does the colour still look as though it belongs where you found it?

The wall does not finish the gradient. It gives you another method of collecting it, with another set of omissions.

<!-- @ -->

On the next floor, follow what happens when a rule assigns colours to grid cells. Keep the spaces between these samples in mind.

[^value]: HSV value is the largest of the RGB channel values; it is not a measurement of perceived lightness. The field uses Godot's [HSV-to-RGB colour conversion](https://docs.godotengine.org/en/4.6/classes/class_color.html#class-color-method-from-hsv). Stanford's [colour lecture](https://web.stanford.edu/class/archive/cs/cs448b/cs448b.1166/cgi-bin/wiki/images/4/4e/Lec448B-20160427.pdf) explains why HSV does not provide perceptually uniform brightness. The sampler's hue and saturation are retained as coordinates even when its RGB result is black; recovering them from black alone would not be possible.
