# A mark acquires an inside

The mark has acquired an inside. Can you find it?

In Pattern Temple, a copied recipe reached the floor, walls, columns and dome. The surfaces could agree and then become different again. Here, look between the faces. There are addresses behind the ones you can see.

<!-- @grid_2d_4x4 -->

The two grids near the entrance begin this study. The bars, shelves and sorting race further along the hall offer other ways to revisit arrays; start here with the low array. Sixteen cubes hold the same arrangement of four colours you have met in the pattern lessons. Find the blue corner, then the bend in red. The pale cells belong to the array too. Pale does not mean absent.

These cubes have bodies, but their addresses use only two indices: a row and a column. Giving a cell a visible thickness has not added a third index to its data. The room has made a two-dimensional arrangement out of three-dimensional objects.

At the console, press **X +** and **Z +**. Follow the turquoise frames. One frame selects a cell in the volume. The other shows the source cell from which it takes its colour. The displayed order is `SOURCE [z][x]` and `VOLUME [y][z][x]`; the same coordinates are placed in the room as `Vector3(x, y, z)`. We have to choose an order for storage as well as directions for space.

<!-- @grid_3d_4x4x4 -->

Press **LAYER +**. Keep x and z where they are. The selected address rises, while the source frame remains on the same cell. Do it again. For now, the four layers repeat the same source. Sixteen values have supplied sixty-four positions, but the added room is not yet being used to vary the pattern with height.

Turn on **SLICE** with **SLICE / ALL**. Three layers disappear from view. Read the counter: sixteen visible, sixty-four stored. Press **LAYER +** to inspect another layer. You are choosing what the display reveals, not cutting data out of the array. The hidden cells have not become empty.

Now press **REPEAT / SHIFT**. Stay with the selected volume address and watch the source frame. At layer one it reads one column further along the source. At layer two it reads two further along. Crossing the fourth column wraps the lookup back to zero.

Move through the slices before turning **ALL** back on. Can you anticipate where the blue will appear above its current position? In the full volume, the layers make a stepped relation that no single slice contains.

The changed rule is small: height advances the column read from the source. When that reading reaches the edge, it returns to the beginning.

Each result is stored at `values[y][z][x]` and selects a colour for the cube at `Vector3(x, y, z)`. The cubes keep their positions. Height has entered the colour lookup. Changing appearance across layers and moving the layers are different operations, even when both can suggest a slant.

Use **UNDO** to recover a previous rule, slice view or selected address. Find a change you can explain by following the source frame, then one that is difficult to see from where you stand. A stored value may be accessible to the program while another cube hides its visible body from you.

<!-- @ -->

What bodies are possible here? The extra index gives us another direction in which to arrange relationships. This particular rule makes repeated or shifted colour layers. It has not made a solid you can carve, a fabric that bends, or an organism that grows. Those would require further rules about what a value does.

There is already a decision worth returning to: every palette index receives a cube. Zero is a pale body. If zero meant no body, the same arrangement of numbers could admit gaps. If a value controlled density, resistance or affinity, other relations would become possible. We have not implemented those meanings at this station. We have found where they could enter.

For now, a slice lets you see by withholding most of the display. That is a useful reduction, provided we remember the forty-eight cells it leaves out. Turn the full volume back on before leaving. In **Ribbon_Patterns_02**, carry this distinction between stored value and visible appearance into the material and conditions that let a pattern be seen.
