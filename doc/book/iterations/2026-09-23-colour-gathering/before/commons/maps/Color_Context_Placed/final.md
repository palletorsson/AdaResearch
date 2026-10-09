# Before we ask what colour is

<!-- @chroma_stack -->

Colour has been here all along. It was in the rooms before we gave it a chapter. Now walk into this long hall and look at what we have brought with us.

A block, a sphere, a wedge: the primitives. Their positions, turns and proportions: transformation. One piece followed by another, each with an address in a list: arrays. The columns gather these earlier lessons into bodies we can walk around. The turns are already over. The movement is yours.

This is our way into colour. We have learned enough to build something, repeat a choice, change it and look again.

Begin with the four columns near the entrance. Each has the same five pieces in the same positions. One ochre covers the first from foot to crown. Beside it, the blocks are red and the round forms blue. Follow a block from one column to the other. Does it still belong to the whole in the same way?

The geometry has stayed still. Colour gives you another way to gather it, or take it apart.

The third column assigns colour by height. Two blocks can now disagree. In the fourth, each colour is calculated from the one below: the hue moves halfway around the hue circle, then halfway again. Two colours alternate up the stack. A neighbour has become an input.

The pieces are stored in an array. The builder begins each turn through it like this:

```gdscript
for i in range(elements.size()):
    var e: Dictionary = elements[i]
```

`i` is the address; `e` is the piece found there. The rest of the loop builds its shape, assigns its colour and places it above the previous piece. An array has an order. The builder makes that order climb. We could read the same list into another arrangement; here, *next* becomes *above*.

Further down, the colour assignment stays while the alphabet changes. Blocks and round forms give way to cylinders, a ring and a cone, then to blocks and wedges. The cone and wedge share yellow. Their grouping is a choice in the code. Nothing in a triangle requires yellow; here, yellow helps us recognise a relation someone has chosen to make.

Now find the four columns made from blocks and wedges. One keeps its levels aligned. In the next, each level has been turned another twenty-two and a half degrees. The third narrows successive levels across X and Z. The fourth combines the turns and narrowing. Follow the yellow through the changing silhouette. What remains easy to recognise?

These are the conditions we can hold and vary. We can keep the geometry and change its material, or keep the colour assignment and change the geometry. The material receives a value through one small line:

```gdscript
m.albedo_color = c
```

That gives the surface a base colour for the renderer to work with. Illumination, the surrounding scene and the display still participate in its appearance. The assignment is precise; it gives us something we can return to when the appearance raises a question.

Colour is deeply scientific and deeply associative. We can ask how light, surfaces and vision make a colour available to us, and how to measure it under specified conditions. We can also find ourselves remembering a room, wanting a garment, recognising a warning. Both kinds of attention can begin at the same patch of colour. A value in the material gives us a handle on the construction. What the colour calls up may lead elsewhere.

The next four stacks loosen the proportions. A large red sphere meets a small red sphere, with a dark cap between them. The red lets you follow a relation across a difference in size. Beside it, thin discs interrupt heavier forms. A narrow stem carries a broad crown. Your eye may supply a weight that the code has not calculated: these objects are fixed in place, with no simulation of balance.

Further across, slabs turn and pieces leave the centre. It is still a stack, but being above no longer means sharing an axis. In the fourth construction, pink, teal, yellow and blue accompany wedges, discs, a block and round beads. Colour is now chosen piece by piece. What might the same forms become in another palette?

The vocabulary is familiar. The combinations are beginning to exceed what we first asked it to do.

<!-- @color_dna_stack -->

The columns grow taller. White, red, blue and yellow blocks separated by thin dark levels carry the gallery's reference to Mondrian. Four diminishing blocks in warm colours come from its Albers study. Pink and teal enter the Memphis stack; eight pieces gather into the taller Bauhaus study. These are composed adaptations of references. You can inspect their proportions and colour choices even if the names are new to you.

Recognition adds another kind of company. A palette can arrive with memories of paintings, furniture, toys or interiors. Those associations may draw your attention to a colour before you begin to measure it. They may also make a combination feel familiar so quickly that you stop looking. Stay with one of the columns a little longer. Find a detail its name did not tell you to expect.

The next pair rises above you: angular and round forms in two blues, then a tall striped shaft under a broad dark cap. Walk around the striped column. New colours come into view. The object has not turned.

This is the gallery's `ps07_kras_rainbow`, with the whole capped column raised to 6.2 metres. Thirty stripes take their colours from an array of six entries:

```gdscript
var col_idx: int = i % stripe_colors.size()
var col_val = stripe_colors[col_idx]
```

The remainder sends the index back to the start of the palette after every six stripes. The six-colour order repeats five times around the shaft. Arrays and transformations have brought us here again: a list of colours, repeated pieces, positions and turns around a circle.

If a Pride flag, a sweet wrapper or a fairground comes to mind, the array has not stored that memory. The arrangement meets something you bring. Someone else may arrive at another association, or stay with the stripes. Learning the rule gives us more to notice in that meeting.

The broad cap once belonged to a table-sized construction. Now it is overhead. A change in height has changed its relation to your reach. At the end of the hall, that cap carries another stack. The rainbow shaft and eight-piece Bauhaus crown become a 7.2-metre column. Beside it, Memphis blocks, a striped shaft and red beads rise to 7.4 metres. Whole configurations become parts of another body.

<!-- @ -->

We have brought primitives, transformations and arrays into composition. They let us specify what is built, keep a choice, vary it and share the construction with someone else. Colour enters that structure and opens further relations: between parts, between a surface and its surroundings, between something seen and something remembered.

We can begin with those relations before we know how to account for them. In the next hall, keep the surface and move the light. What happens to the colour then?
