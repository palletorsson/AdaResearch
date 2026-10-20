# Fly into the third index

How do you reach an address above your head?

In the last hall, you could walk around the nested cubes. Here the familiar pickup cubes are spaced far enough apart for your body to move between them. Four across, four upwards, four deep: sixty-four possible encounters.

<!-- @array_flight_lab -->

At the console beside the glass enclosure, press Y +. A transparent marker moves up one layer. The X +, Y + and Z + buttons each change one index; after three comes zero again. Set the address to [1, 2, 0], the place shown in the illustration below. Look for its marker among the cubes. It is above the ground layer. You have named a place you cannot yet walk to.

Walk through the ground-level opening. Inside this frame you can fly. Push the left stick forward to travel where the left controller points: aim upwards to climb, downwards to descend, level to cross the enclosure. Push the stick sideways to move across that aim. Release the controls to hover. The permission belongs to this enclosure; descend to either ground-level doorway to leave it.

Rise beside a column, then move between layers. The cubes are spaced 2.4 metres apart. There is room for a body between neighbouring samples. An indexed volume need not be a solid block.

The gap is not an extra entry. You can pass between two named places without arriving at another. The array gives us a way to address its cubes; it does not number every position your body can occupy.

The placement extends the earlier row's operation along three directions:

```gdscript
cube_instance.position = Vector3(x * spacing, y * spacing, z * spacing)
```

An index becomes a position through this multiplication. Changing the spacing would change the distances you travel without adding an entry. Changing the number of entries would be another operation.

Find the cube at the address you selected before entering. Approach and collect it by contact.

Hover where the cube used to be. Its label has gone; the transparent marker remains. Release the controls and stay a moment. Above and below you, the other layers keep their places.

Descend and leave through the ground-level opening. Back at the console, read the same selected address. Its value is now zero. The other cubes have not slid into the vacancy. This small record writes collection as an absence:

```gdscript
values[y][z][x] = 0
```

Zero marks the cube’s departure. It stayed zero while you hovered there: your body could occupy the place without becoming part of this record.

The row inside an array has gained another enclosing list. Read `values[y][z][x]` from left to right: `values[y]` selects one layer containing rows; `[z]` selects a row in that layer; `[x]` selects its entry. The display names coordinates in x, y, z order, while the storage opens them in y, z, x order. Those conventions must be connected explicitly. Neither a list nor a number arrives with a direction built into it.

<!-- @ -->

![The selected cube at address 1,2,0 before collection and the same transparent marker after it has gone, with the console changing from value 1 to value 0.](/book-images/iterations/2026-09-23-array-entered-address/an-address-you-can-enter.png)

*The same address before and after arrival. The cube and its label leave; the selection marker remains. The console inset is a separate view of the readout outside the enclosure; it is read on returning to the doorway.*

<!-- @ -->

<!-- study-spine:open_structures -->

<!-- @open_structures -->

The solid cube has lost its faces. Five open forms stand together, made from connections you can follow with your eye. Across the next arrangement, each place contains one of those forms. A row returns with its beginning moved along.

Change RULE. The places remain; the diagonal succession settles into repeated columns. These are our proposed rules after LeWitt's images. Reading a rule from an image means choosing among constructions that might have made it. The ease of producing another arrangement does not settle which one is worth keeping.

<!-- study-spine:reference_suspension -->

<!-- @reference_suspension -->

Beyond the open frames, rough fragments hang at three heights along a field of slender supports. Look down one row. Through the damaged-looking surfaces, the address remains exact.

Change the roughness. Seventy-five fragments keep their places. This response to Hatoum borrows the tension between an orderly support and something that seems to have survived damage. Our meshes have no weight and no history of demolition. Their easy restoration makes that absence conspicuous. What would the grid have to carry before its promise to hold something became a responsibility?

<!-- @ -->

The third index has extended what we can address. Flight has extended what we can reach. Back on the ground, the next array will lie underfoot. Its entries will receive a small black-and-white shape, repeated across a surface.
