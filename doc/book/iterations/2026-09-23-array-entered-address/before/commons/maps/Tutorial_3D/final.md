How do you reach an address above your head?

The familiar cubes have risen into a volume. Four across, four upwards, four deep: sixty-four possible encounters. Before entering, follow one vertical line with your eyes. Which part of the address changes as it climbs?

<!-- @array_flight_lab -->

At the console beside the glass enclosure, press Y +. A transparent marker moves up one layer. Press X +, then Z +. Each button changes one index; after three it returns to zero. Read the selected address before looking for its cube. The marker helps you locate the slot, including a slot whose occupant has gone.

Walk through the ground-level opening. Inside this frame you can fly. On desktop, look and use WASD, with Space to rise and Ctrl to descend. In VR, the left stick follows the tilted left controller. Release the controls to hover. The permission belongs to this enclosure; descend to either ground-level doorway to leave it.

Rise beside a column, then move between layers. The cubes are spaced 2.4 metres apart. There is room for a body between neighbouring samples. An indexed volume need not be a solid block.

The placement extends the earlier row's operation along three directions:

```gdscript
cube_instance.position = Vector3(x * spacing, y * spacing, z * spacing)
```

An index becomes a position through this multiplication. Changing the spacing would change the distances you travel without adding an entry. Changing the number of entries would be another operation. The glass frame is another decision again: it supplies the boundary within which this particular body can move vertically.

Choose an address, approach its cube and collect it by contact. Return to the console and select that address. Its value is now zero. The other cubes have not slid into the vacancy. This small record writes collection as an absence:

```gdscript
values[y][z][x] = 0
```

The row inside an array has gained another enclosing list. Read `values[y][z][x]` from left to right: `values[y]` selects one layer containing rows; `[z]` selects a row in that layer; `[x]` selects its entry. The display names coordinates in x, y, z order, while the storage opens them in y, z, x order. Those conventions must be connected explicitly. Neither a list nor a number arrives with a direction built into it.

<!-- @ -->

Hover where a cube used to be. For a moment, your body occupies the neighbourhood of a recorded absence. The table still says zero: it records cubes, not everything that could exist there. What would have to change for it to notice you?

The third index has extended what we can address. Flight has extended what we can reach. Keep those changes separate as you descend. Next, we return to the ground and ask how one small shape can organise a whole surface.
