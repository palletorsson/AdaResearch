What would have to stay the same for this to be the same pattern?

You have followed an address around a corridor. The floor and the wall gave it different directions. Here the surface stays flat, and a small mark returns in ways that do not quite agree.

<!-- @vr_tile_editor -->

Begin at the tilted console in the side bay. Its sixteen buttons hold an asymmetric mark: a bent line, a second colour near a corner, a third near the bend. The left panel holds a sample. The right panel and the carpet follow the current source and rule.

Choose **PM**. Keep your eyes on the corner colour. Find it in the next block. Has the mark travelled, or has it also reversed? Compare it with the held **P1** sample. You have changed no source address.

Now choose **PG**. The reversal remains, but the colour no longer arrives opposite its neighbour. Follow it along the other direction. The rule has slipped the reflected copy by half the source height. With four source rows, that is two rows.

Try to describe the difference before pressing **HOLD**. This saves the current image on the left. It gives your next change somewhere to return to.

The three buttons select translation, reflection and glide reflection. In the editor's integer lookup, the last two differ by one line. This is the PG branch of `WallpaperGroups.get_symmetric_color`, with its local source coordinates:

```gdscript
var tile_x = px / tile_size
tx = px % tile_size
ty = py % tile_size
if tile_x % 2 == 1:
    tx = tile_size - 1 - tx
    ty = (ty + tile_size / 2) % tile_size
```

An odd block reverses the source column. Then the row shifts halfway round the source and wraps. The array stays where it was; the lookup changes which of its addresses is read. The panel shows eight source blocks across and eight down. A source block is not necessarily a full translation period: reversal makes you wait for another block before its orientation returns.

Select a colour, then press one of the sixteen source cells. The live panel and floor change together; the held image keeps its pixels. **UNDO** can recover a paint edit, a rule choice or the previous held sample. **RESET** restores the initial mark and P1 while leaving the held comparison available.

Now make the source less distinctive. Remove the corner colour, or make both sides alike. Does the difference between rules remain easy to see? A rule can still execute while your chosen mark conceals what it does. The selected button names a construction; it does not prove that the finished image has exactly that symmetry group. An unusually symmetric source can introduce more symmetry.

<!-- @wallpaper_cage -->

Return to the cage. It marks rotational orders one, two, three, four and six, and crosses five and seven. Its subject is rotation compatible with a periodic planar lattice. It is a diagram of that restriction, not an experiment that tries every arrangement until one fails.

The larger classification concerns ideal patterns repeating in two independent directions on the Euclidean plane. Under those conditions there are seventeen plane-group types; the [IUCr tables](https://it.iucr.org/Ab/) list their operations and generators. The three comparisons at the console are an entrance into that subject, not a demonstration of the completeness of the list.

A fivefold-looking flower can sit inside a repeating cell. That does not give the entire field fivefold rotational symmetry. The flower and the field ask the question at different scales. Look for the boundary of what is being counted.

<!-- @ -->

The catalogue closes under its assumptions. This finite carpet still ends. Its colours have been sampled into pixels, its material meets the light, and your body stands at an angle to it. Those differences have not disappeared because the symmetry has a name.

What could this classification tell you about a garment? What would it leave unasked about its cut, its wearer, or the way a seam interrupts the repeat? Carry the small mark forward. In **Ribbon_Patterns_01**, the next question is what happens when the source gains another index and supplies a volume.
