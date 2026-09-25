How do you reach an address above your head?

In the last hall, you could walk around the nested cubes. Here the familiar pickup cubes are spaced far enough apart for your body to move between them. Four across, four upwards, four deep: sixty-four possible encounters. Before entering, follow one vertical line with your eyes. Which part of the address changes as it climbs?

<!-- @array_flight_lab -->

At the console beside the glass enclosure, press Y +. A transparent marker moves up one layer. Press X +, then Z +. Each button changes one index; after three it returns to zero. Read the selected address before looking for its cube. The marker helps you locate the slot, including a slot whose occupant has gone.

Walk through the ground-level opening. Inside this frame you can fly. Push the left stick forward to travel where the left controller points: aim upwards to climb, downwards to descend, level to cross the enclosure. Push the stick sideways to move across that aim. Release the controls to hover. The permission belongs to this enclosure; descend to either ground-level doorway to leave it.

Rise beside a column, then move between layers. The cubes are spaced 2.4 metres apart. There is room for a body between neighbouring samples. An indexed volume need not be a solid block.

The gap is not an extra entry. You can pass between two named places without arriving at another. The array gives us a way to address its cubes; it does not number every position your body can occupy.

The placement extends the earlier row's operation along three directions:

```gdscript
cube_instance.position = Vector3(x * spacing, y * spacing, z * spacing)
```

An index becomes a position through this multiplication. Changing the spacing would change the distances you travel without adding an entry. Changing the number of entries would be another operation. The glass frame is another decision again: it supplies the boundary within which this particular body can move vertically.

Find the cube at the address you selected before entering. Approach and collect it by contact.

Hover where the cube used to be. For a moment, your body occupies the neighbourhood of a recorded absence. The array records cubes, not everything that could exist there. What would have to change for it to notice you?

Descend and leave through the ground-level opening. Back at the console, read the same selected address. Its value is now zero. The other cubes have not slid into the vacancy. This small record writes collection as an absence:

```gdscript
values[y][z][x] = 0
```

The row inside an array has gained another enclosing list. Read `values[y][z][x]` from left to right: `values[y]` selects one layer containing rows; `[z]` selects a row in that layer; `[x]` selects its entry. The display names coordinates in x, y, z order, while the storage opens them in y, z, x order. Those conventions must be connected explicitly. Neither a list nor a number arrives with a direction built into it.

<!-- @ -->

![The selected cube at address 1,2,0 before collection and the same transparent marker after it has gone, with the console changing from value 1 to value 0.](/book-review/doc/book/iterations/2026-09-23-array-entered-address/an-address-you-can-enter.png)

*The same address before and after arrival. The cube and its label leave; the selection marker remains. The console inset is a separate view of the readout outside the enclosure; it is read on returning to the doorway.*

The third index has extended what we can address. Flight has extended what we can reach. Keep those changes separate as you leave. Next, we return to the ground and ask how one small shape can organise a whole surface.
