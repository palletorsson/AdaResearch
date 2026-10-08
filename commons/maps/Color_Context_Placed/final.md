# Before we ask what colour is

<!-- @chroma_stack -->

Colour has been here all along. It was in the rooms before we gave it a chapter. Now walk into this long hall and look at what we have brought with us.

A block, a sphere, a wedge: the primitives. Their positions, turns and proportions: transformation. One piece followed by another, each with an address in a list: arrays. The columns gather these earlier lessons into bodies we can walk around. The turns are already over. The movement is yours.

On the disco floor, you held an arrangement before advancing to the next. Here, the choices stand beside one another. One column can remain in view while you look at its neighbour.

![The columns seen from the entrance aisle inside the museum.](/book-review/doc/book/figures/Color_Context_Placed/colour-hall.png)

Begin with the four columns near the entrance. Each has the same five pieces in the same positions. One ochre covers the first from foot to crown. Beside it, the blocks are red and the round forms blue. Follow a block from one column to the other. Does it still belong to the whole in the same way?

Follow the red past the blue sphere to the next block. The sphere keeps those two red parts apart, yet your eye can bring them together. The parts touch in one order; colour lets you gather them in another.

The third column assigns colour by height. A block near the floor and a block near the top receive different colours. Sharing a shape no longer gives them the same colour. In the fourth, each colour is calculated from the one below: the hue moves halfway around the hue circle, then halfway again. Ochre, blue, ochre again. The alternation is held in the column, for your eye to climb. A neighbour has become an input.

![Four native museum views of the same five forms under four colour rules.](/book-review/doc/book/iterations/2026-09-23-colour-gathering/four-colour-rules.png)

*The four columns near the entrance. Their local geometry is the same; each rule gives their pieces a different colour assignment.*

The pieces are stored in an array. The builder begins each turn through it like this:

```gdscript
for i in range(elements.size()):
    var e: Dictionary = elements[i]
```

`i` is the address; `e` is the piece found there. The rest of the loop builds its shape, assigns its colour and places it above the previous piece. An array has an order. The builder makes that order climb. We could read the same list into another arrangement; here, *next* becomes *above*.

Further down, the colour assignment stays while the alphabet changes. Blocks and round forms give way to cylinders, a ring and a cone, then to blocks and wedges. The cone and wedge share yellow. Their grouping is a choice in the code. Nothing in a triangle requires yellow; here, yellow helps us recognise a relation someone has chosen to make.[^bauhaus]

Now find the four columns made from blocks and wedges. One keeps its levels aligned. In the next, each level has been turned another twenty-two and a half degrees. The third narrows successive levels across X and Z. The fourth combines the turns and narrowing. Follow the yellow through the changing silhouette. What remains easy to recognise?

The first four columns kept their geometry while the colour assignment changed. These turned and narrowed stacks keep their colour assignment while the geometry changes. In each case, a material receives its base colour through one small line:

```gdscript
m.albedo_color = c
```

That gives the surface a base colour for the renderer to work with. Illumination, the surrounding scene and the display still participate in its appearance. The assignment is precise; it gives us something we can return to when the appearance raises a question.

Colour is deeply scientific and deeply associative. We can ask how light, surfaces and vision make a colour available to us, and how to measure it under specified conditions. We can also find ourselves remembering a room, wanting a garment, recognising a warning. Both kinds of attention can begin at the same patch of colour. A value in the material gives us a handle on the construction. What the colour calls up may lead elsewhere.

The next four stacks loosen the proportions. A large red sphere meets a small red sphere, with a dark cap between them. The red lets you follow a relation across a difference in size. Beside it, thin discs interrupt heavier forms. A narrow stem carries a broad crown. Your eye may supply a weight that the code has not calculated: these objects are fixed in place, with no simulation of balance.

Further across, slabs turn and pieces leave the centre. It is still a stack, but being above no longer means sharing an axis. In the fourth construction, pink, teal, yellow and blue accompany wedges, discs, a block and round beads. Colour is now chosen piece by piece. What might the same forms become in another palette?

There is no new primitive hidden in these columns. Width, height, position, turn, colour: the things we have learned to name are becoming things we can compose.

The vocabulary is familiar. The combinations are beginning to exceed what we first asked it to do.

<!-- @color_dna_stack -->

Four taller columns carry their names on their plates. Each plate says what its column borrows; the shapes and colours are there to inspect even when the name is new.

Recognition adds another kind of company. A palette can arrive with memories of paintings, furniture, toys or interiors. Those associations may draw your attention to a colour before you begin to measure it. They may also make a combination feel familiar so quickly that you stop looking. Stay with one of the columns a little longer. Find a detail its name did not tell you to expect.

The next pair rises above you: angular and round forms in two blues, then a tall striped shaft under a broad dark cap. Walk around the striped column. Stripes disappear at one edge and enter at the other. The object has not turned.

![Two views around the fixed rainbow column, with its broad cap overhead.](/book-review/doc/book/iterations/2026-09-23-colour-gathering/around-the-rainbow.png)

*The same column seen from two sides. The stripes keep their places while their arrangement in the view changes.*

This column began as a table-sized study, 72 centimetres tall; here it is raised to 6.2 metres. Thirty stripes take their colours from an array of six entries:

```gdscript
var col_idx: int = i % stripe_colors.size()
var col_val = stripe_colors[col_idx]
```

The remainder sends the index back to the start of the palette after every six stripes. The six-colour order repeats five times around the shaft. Arrays and transformations have brought us here again: a list of colours, repeated pieces, positions and turns around a circle.

If a Pride flag, a sweet wrapper or a fairground comes to mind, the array has not stored that memory. The arrangement meets something you bring. Someone else may arrive at another association, or stay with the stripes. Learning the rule gives us more to notice in that meeting.

The broad cap once belonged to a table-sized construction. Now it is overhead. A change in height has changed its relation to your reach. At the end of the hall, that cap carries another stack. The rainbow shaft and eight-piece Bauhaus crown become a 7.2-metre column. Beside it, Memphis blocks, a striped shaft and red beads rise to 7.4 metres. Whole configurations become parts of another body.

The saved description of a stack is what this project calls its DNA. Later we will open the rules that turn such a description into a body; here we can walk among its relatives.

<!-- @ -->

<!-- study-spine:reference_landscape -->

<!-- @reference_landscape -->

A cone returns as a tree. Three cones become its tiers; forty-eight places become a forest. The little pavilion shares their vocabulary. Change the height and the same sites seem to belong to another scale of world.

The supplied Alex McLeod image offered a way into this abundance. Here it takes surprisingly few kinds of part to make somewhere you want to look into. Gold, water and a pastel arch invite a belief that the geometry alone never required. Keep the sites and alter one proportion. Notice when a collection begins to feel like a place.

<!-- @ -->

We have brought primitives, transformations and arrays into composition. They let us specify what is built, keep a choice, vary it and share the construction with someone else. Colour enters that structure and opens further relations: between parts, between a surface and its surroundings, between something seen and something remembered.

We can begin with those relations before we know how to account for them. In the next hall, keep the surface and move the light. What happens to the colour then?

[^bauhaus]: The assignment draws on [Kandinsky’s Bauhaus colour teaching](https://www.bauhaus.de/en/sammlung/highlights/204_unterricht/444): yellow triangle, red square, blue circle. Our five-form stack loosely recalls Alma Siedhoff-Buscher’s building games for the [1923 Haus am Horn](https://www.klassik-stiftung.de/service/presse/pressemitteilung/bauhaus-welt-fuer-kinder/); it does not reproduce their set of pieces.
