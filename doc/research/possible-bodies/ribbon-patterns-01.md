# An address gains depth

**Layout update:** this hall is now 25 x 25 m, with framed gallery walls. [View the compact halls](compact-ribbons.html). Main encounters retain their scale. The encounter images below predate this spatial revision; the linked gallery views show the current walls and arrangement.

[Primary artifacts](/necklace/thread?map=Ribbon_Patterns_01&role=primary) · [Route and evidence](index.html#Ribbon_Patterns_01) · [Workshop](studio-workshop.html)

The next room follows the saved progression from surface to volume. The two existing primary arrays now stand together in one bay: sixteen source cells beside sixty-four volume cells, with a shared plinth console.

![One motif supplies four layers](layer-pattern-all.png)

Choose a volume address and follow the turquoise frame back to its source. REPEAT uses the same source at every height. SHIFT reads one column further along the source for each height layer. The colour lookup changes; the cubes keep their positions.

![Slice view exposes one layer while retaining all values](layer-pattern-slice.png)

SLICE hides three layers and retains all sixty-four values. The display says both what is visible and what is stored. This is an inspection view, not a deletion operation.

![Mounted controls display source and volume addresses](layer-pattern-console.png)

| Control | Action |
|---|---|
| X + / Z + | Select a horizontal address, wrapping at four. |
| LAYER + | Select the height index, wrapping at four. |
| SLICE / ALL | Show one layer or the whole volume. |
| REPEAT / SHIFT | Repeat the source or shift its lookup with height. |
| UNDO | Restore the previous selection, view or recipe; up to 32 states. |

The two studies preserve their addresses: pickup collection and bobbing are suspended in these instances. Other pickup arrays retain their behaviour. Nine supporting exhibits remain, with sorting as an optional revisit.

22 desktop checks pass, including actual pointer events, source lookup, stored values, geometry preservation, undo and console approach. The run also checks default pickup cubes, early configuration and rebuilding without a second lattice. [Verification report](layer-pattern-check.json). Headset and continuous gestures remain deferred.

Next: **Ribbon_Patterns_02**, the receiving material and conditions of viewing. The closing shader and garment studio remains part of the plan.

## The book passage

The mark has acquired an inside. Can you find it?

In the previous room, one source could repeat, reverse and slip across a plane. The corridor wrapped a pattern around several faces. Here, look between the faces. There are addresses behind the ones you can see.

<!-- @grid_2d_4x4 -->

Begin with the low array. Sixteen cubes hold the same arrangement of four colours you have met in the pattern lessons. Find the blue corner, then the bend in red. The pale cells belong to the array too. Pale does not mean absent.

These cubes have bodies, but their addresses use only two indices: a row and a column. Giving a cell a visible thickness has not added a third index to its data. The room has made a two-dimensional arrangement out of three-dimensional objects.

At the console, press **X +** and **Z +**. Follow the turquoise frames. One frame selects a cell in the volume. The other shows the source cell from which it takes its colour. The displayed order is `SOURCE [z][x]` and `VOLUME [y][z][x]`; the same coordinates are placed in the room as `Vector3(x, y, z)`. We have to choose an order for storage as well as directions for space.

<!-- @grid_3d_4x4x4 -->

Press **LAYER +**. Keep x and z where they are. The selected address rises, while the source frame remains on the same cell. Do it again. For now, the four layers repeat the same source. Sixteen values have supplied sixty-four positions, but the added room is not yet being used to vary the pattern with height.

Turn on **SLICE** with **SLICE / ALL**. Three layers disappear from view. Read the counter: sixteen visible, sixty-four stored. Press **LAYER +** to inspect another layer. You are choosing what the display reveals, not cutting data out of the array. The hidden cells have not become empty.

Now press **REPEAT / SHIFT**. Stay with the selected volume address and watch the source frame. At layer one it reads one column further along the source. At layer two it reads two further along. Crossing the fourth column wraps the lookup back to zero.

Move through the slices before turning **ALL** back on. Can you anticipate where the blue will appear above its current position? In the full volume, the layers make a stepped relation that no single slice contains.

The changed rule is small. This is the lookup used to fill the volume:

```gdscript
func sample(x: int, y: int, z: int) -> int:
    var source_x: int = (x + y) % 4 if shifted else x
    return SOURCE[z][source_x]
```

Each result is stored at `values[y][z][x]` and selects a colour for the cube at `Vector3(x, y, z)`. The cubes keep their positions. Height has entered the colour lookup. Changing appearance across layers and moving the layers are different operations, even when both can suggest a slant.

Use **UNDO** to recover a previous rule, slice view or selected address. Find a change you can explain by following the source frame, then one that is difficult to see from where you stand. A stored value may be accessible to the program while another cube hides its visible body from you.

<!-- @ -->

What bodies are possible here? The extra index gives us another direction in which to arrange relationships. This particular rule makes repeated or shifted colour layers. It has not made a solid you can carve, a fabric that bends, or an organism that grows. Those would require further rules about what a value does.

There is already a decision worth returning to: every palette index receives a cube. Zero is a pale body. If zero meant no body, the same arrangement of numbers could admit gaps. If a value controlled density, resistance or affinity, other relations would become possible. We have not implemented those meanings at this station. We have found where they could enter.

For now, a slice lets you see by withholding most of the display. That is a useful reduction, provided we remember the forty-eight cells it leaves out. Turn the full volume back on before leaving. In **Ribbon_Patterns_02**, carry this distinction between stored value and visible appearance into the material and conditions that let a pattern be seen.
