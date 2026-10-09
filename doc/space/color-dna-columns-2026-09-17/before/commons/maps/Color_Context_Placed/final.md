# Colour joins the primitives

<!-- @chroma_stack -->

You know these shapes. A block, a sphere, a wedge. You have moved them, turned them, changed their proportions. Here they stand in columns along a long hall. Nothing is moving. You can take your time with what a transformation has left behind.

Begin with the four columns near the entrance. Each has the same five pieces in the same positions. One ochre covers the first from foot to crown. Beside it, the blocks are red and the round forms blue. Follow one piece across the comparison. Has it become easier to find? Has the column become several things?

The geometry has stayed still. Colour gives you another way to gather it, or take it apart.

The third column gives each level a colour according to its height. Two blocks can now disagree. In the fourth, each colour is the complement of the one below it. The base starts the exchange; the colours above alternate. These are four assignments made with the same forms. Keep them in view before deciding what a colour belongs to.

Further down, the assignment stays and the shapes change. One column uses blocks and round forms; another brings in cylinders, a ring and a cone; a third is assembled from blocks and wedges. The ring stands on edge. The wedge makes a direction where the block held a corner. These are combinations of the vocabulary you brought into the hall.

The colour rule names kinds: round blue, square red, triangular yellow. The cone and wedge share yellow. The ring belongs to another group and stays grey-green. The assignment can bring unlike bodies together. It can also give them a difference their geometry did not ask for.

Now find the four columns made from blocks and wedges. The first keeps its levels aligned. In the next, each level has been turned another twenty-two and a half degrees. Walk round it. The turn is already over; the changing view is yours.

The third narrows each successive level across X and Z while keeping its height. The fourth combines that narrowing with the turns. Its colour assignment stays the same. Follow the yellow wedges through the four versions. What can you still recognise when the silhouette changes?

The assignments to a piece are small:

```gdscript
mi.rotation.y = yaw
mi.scale = Vector3(width_scale, 1.0, width_scale * depth_ratio)
```

Here those values are set when the column is built. They give it an orientation and proportions; they do not give it a speed. The result waits for a body to move around it.

The next four columns stop giving every piece the same share of the height. A large red sphere meets a small red sphere, with a dark cap between them. The red lets you follow a relation across a difference in size. A disc is almost a line from here. Walk sideways and its width returns.

Beside it, thin discs interrupt heavier forms. A narrow stem carries a broad crown. Your eye supplies a weight that the code has not calculated. These objects are fixed in place; nothing here is testing whether that balance would hold.

Further across, the pieces leave the centre. A slab reaches out, a cylinder shifts back, the next slab turns. Follow the assembly upward. It is still a stack, but being above no longer means sharing the same axis.

The fourth gathers wedges, discs, a turned block and round beads into a brighter construction. Pink, teal, yellow and blue no longer obey the earlier rule that gave each kind its colour. Someone has chosen where each goes. You can recognise the pieces and still find a body you did not expect from them.

There is no new primitive hidden in these columns. Width, height, position, turn, colour: the things we have learned to name are becoming things we can compose.

<!-- @chroma_translation -->

At the end, return to the simpler five-piece column. It has been moved, and each position has been left standing. A rail along the floor shows the direction. Four copies keep their shapes and their assigned colours. The blue form returns at another address.

Across the aisle, the geometry repeats in the same way, but each copy carries a different hue. The colour is calculated from how far the copy has been displaced from its starting place. It now groups the whole column rather than naming the pieces inside it.

A translation preserves a shape, its size and its colour. It preserves the colour only if the colour was a property of the shape. Where the colour was a property of the place, moving the shape changes it. The room asks which of the two you are looking at.

<!-- @ -->

We have added colour to what we could already build. It can hold a column together, name its parts, mark a place or draw a relation between unlike sizes. The same primitives have more ways to meet.

In the next hall, keep the surface and move the light. What happens to the colour then?
