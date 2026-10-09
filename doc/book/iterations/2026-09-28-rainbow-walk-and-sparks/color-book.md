# color: the chapters

## Color Context Placed

*Color_Context_Placed*

### Before we ask what colour is


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

Further down, the colour assignment stays while the alphabet changes. Blocks and round forms give way to cylinders, a ring and a cone, then to blocks and wedges. The cone and wedge share yellow. Their grouping is a choice in the code. Nothing in a triangle requires yellow; here, yellow helps us recognise a relation someone has chosen to make.[^Color_Context_Placed--bauhaus]

Now find the four columns made from blocks and wedges. One keeps its levels aligned. In the next, each level has been turned another twenty-two and a half degrees. The third narrows successive levels across X and Z. The fourth combines the turns and narrowing. Follow the yellow through the changing silhouette. What remains easy to recognise?

The first four columns kept their geometry while the colour assignment changed. These turned and narrowed stacks keep their colour assignment while the geometry changes. In each case, a material receives its base colour through one small line:

```gdscript
m.albedo_color = c
```

That gives the surface a base colour for the renderer to work with. Illumination, the surrounding scene and the display still participate in its appearance. The assignment is precise; it gives us something we can return to when the appearance raises a question.

Colour is deeply scientific and deeply associative. We can ask how light, surfaces and vision make a colour available to us, and how to measure it under specified conditions. We can also find ourselves remembering a room, wanting a garment, recognising a warning. Both kinds of attention can begin at the same patch of colour. A value in the material gives us a handle on the construction. What the colour calls up may lead elsewhere.

The next four stacks loosen the proportions. A large red sphere meets a small red sphere, with a dark cap between them. The red lets you follow a relation across a difference in size. Beside it, thin discs interrupt heavier forms. A narrow stem carries a broad crown. Your eye may supply a weight that the code has not calculated: these objects are fixed in place, with no simulation of balance.

Further across, slabs turn and pieces leave the centre. It is still a stack, but being above no longer means sharing an axis. In the fourth construction, pink, teal, yellow and blue accompany wedges, discs, a block and round beads. Colour is now chosen piece by piece. What might the same forms become in another palette?

The vocabulary is familiar. The combinations are beginning to exceed what we first asked it to do.


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


We have brought primitives, transformations and arrays into composition. They let us specify what is built, keep a choice, vary it and share the construction with someone else. Colour enters that structure and opens further relations: between parts, between a surface and its surroundings, between something seen and something remembered.

We can begin with those relations before we know how to account for them. In the next hall, keep the surface and move the light. What happens to the colour then?

[^Color_Context_Placed--bauhaus]: The assignment draws on [Kandinsky’s Bauhaus colour teaching](https://www.bauhaus.de/en/sammlung/highlights/204_unterricht/444): yellow triangle, red square, blue circle. Our five-form stack loosely recalls Alma Siedhoff-Buscher’s building games for the [1923 Haus am Horn](https://www.klassik-stiftung.de/service/presse/pressemitteilung/bauhaus-welt-fuer-kinder/); it does not reproduce their set of pieces.

---

## Color Flashlight

*Color_Flashlight*

### What reaches the surface


Several pools of colour meet on a pale board. Their edges are easier to follow than their crowded middle. Pick one edge. Which lamp is responsible for it?

Take the red lamp and turn it aside. Follow what leaves the surface. Bring it back slowly, across the other pools. There is a place where its red becomes difficult to name on its own. Move through that place again. Nothing has been painted over, yet something has appeared that neither lamp makes alone.

Leave the red lamp aimed at the surface. It stays where you release it. Take the green one and move its pool across the red. Separate them, then let their edges meet. Try the blue. The white lamp begins aimed aside; bring it into the comparison when you want to see what another contribution does. If the middle grows too pale to distinguish, separate the pools again. Their edges give you somewhere to begin.

In the previous room, colour was assigned to forms and positions. Here you can move one of the conditions of its appearance with your hand. What, exactly, have you changed?

The receiving surface keeps the same material throughout. Its stored base colour, its *albedo*, is a near-white value. Each lamp carries a `SpotLight3D`: a light with a position, a direction and a cone. Turning the handle turns the cone. The surface receives a different contribution because you have changed where that cone falls.

Aim a beam off the board and onto the floor or the cube standing to its side. The cone can cross the boundary of its intended exhibit. Does the colour still read the same way? Follow a shadow or an edge before giving the result a name. The lamp carries a value, but it cannot carry a complete account of what you will see wherever you point it.

Beside the board stands a coarse, pale sphere. Carry the red beam across it. One face brightens while its neighbour stays dull. Move the lamp to the other side and watch the difference change places. No face has been repainted.

We met these flat faces among the primitives, where they interrupted the promise of a smooth sphere. Here they give the light different directions to meet. Each face has a direction, called its *normal*, which the renderer uses along with the light and material to calculate its appearance. What looked like one pale body begins to answer face by face. Bring a second colour across the first. The construction you could barely see now divides their meeting.

![The same pale sphere under a red lamp held on either side. The camera, mesh and material stay fixed.](/book-review/doc/book/iterations/2026-09-23-flashlight-faceted-sphere/same-sphere-moving-light.png)

The red lamp has crossed from board to sphere without changing its assigned colour. Inside each lamp, `flashlight_color.gd` finds the light and gives it its colour:

```gdscript
var spot = _find_spot_light(target_root)
if spot:
    spot.light_color = light_color
```

Four copies of the same scene receive four values. The red instance is given `Color(1, 0, 0, 1)`; the green instance `Color(0, 1, 0, 1)`. The first three numbers address red, green and blue channels, each from zero to one. Zero contributes none of that channel; one gives its full value. The fourth number, alpha, stays at one here.

The assignment happens when the scene starts. While you move the lamp, its colour value stays fixed. You have changed where its light meets the room.

There is a useful limit here. These lamps offer RGB values to a renderer. They do not calculate a spectrum of wavelengths. The room also has other illumination: turning the lamps away does not promise darkness. Even the pale surface we have kept fixed is a chosen condition of this experiment. We have made a comparison manageable by leaving much of the world in place.

Perhaps the surprising body here is the patch of colour. You cannot pick it up separately from the meeting that produces it. Move one participant and its boundary moves; withdraw another and it changes again. The code gives us a way to repeat that meeting. There is still more to ask of it.


Carry the distinction with you: changing the light that reaches a surface and changing the surface's own material can both change its appearance. In the next room, the receiving surface begins to resemble part of the body you act through. What happens when the colour is something you choose to wear?

---

## Color Nails

*Color_Nails*

### The choosing hand

What changes when a colour becomes part of the body you act through?

The lamps changed what reached a surface. Here a hand has outgrown the furniture. A small manicure table stands before it, complete with bottles, stools and another hand small enough to rest between the tools. Which of these bodies are you about to dress?


Find the movable point in the RGB box on its open plinth beside the manicure table. Take it along one axis, then bring it back. A colour you left can be found again at the same place.

Look up at the giant nails, then down at the petite hand on the table. Both answer the same choice. A movement small enough for your hand to make crosses two very different scales. Does the colour feel equally delicate on both?

![The giant hand and the petite hand on the manicure table, seen from inside the museum salon.](/book-review/doc/book/figures/Color_Nails/salon-red.png)

Raise the hand you are choosing with and turn its nails toward you. Compare them with the petite hand, the giant nails and the swatch. The colour has reached the hand you use to choose it. What seemed like dressing an object now includes the body doing the dressing.

The nail material adds its own response to light. A colour selected in the box can look different on a small glossy surface from the way it appears on the flat preview.

The point's three coordinates are constrained to the box and converted into red, green and blue channel values, each between zero and one. Moving along one axis changes one channel. Moving diagonally can change several at once. The box turns a colour choice into a position that your hand can revisit.

This is a three-channel description of colour. It does not divide every difference you can perceive into three equally noticeable kinds. Equal distances in the box need not feel like equal changes in the preview.


At the controller for the hand surface, leave the nails at the colour you chose and move the point for the skin. Look again at the nails against this new background. Their assigned colour has stayed fixed. Do they still look the same?

The two stations use the same position-to-colour mechanism but target different surfaces. The salon hands are two copies of the same source mesh. Their nail materials receive the nail-colour signal; their skin materials receive the hand-colour signal. Each receiving material is assigned the selected value:

```gdscript
material.albedo_color = colour
```

The scale difference lives in the geometry's transform. It does not require a second colour recipe. A nail can become monumental while its material still receives the same three channels as the small one on the cushion.

The two points move with the same ease. Changing polish and changing skin can feel like neighbouring choices. Yet changing a rendered skin colour does not give us another person's lived history, or undo the racism through which skin is read. Polish is read through the body too: a colour may be called elegant, excessive or defiant according to whose hand wears it.

Audre Lorde asks us to recognise difference while confronting the power that turns it into inferiority.[^Color_Nails--color-nails-lorde] Look again at the hand you have chosen. Which colours feel available to you? Which seem to require an explanation, and to whom?

The bottles never need opening. No brush crosses these nails, and no polish has to dry. The room keeps the cushion, the stools, the promise of a hand being attended to. The application has become an assignment. What remains of the manicure in the pleasure of choosing?

The colour leaves with you. Your hands carry it into the halls ahead.


Choose a colour because you want it, without requiring a naturalistic match. Try a nail or hand that interrupts the palette you expected from this body. Reach for the point again. The hand making the next choice is already wearing the last one.

You have chosen their colour. The fingers have kept their length. What else might you want to change?

Carry one of those chosen colours toward the rainbow. Where would you put it among the bands? The next room gives colour a familiar order; look for the decisions that hold that order in place.

[^Color_Nails--color-nails-lorde]: Audre Lorde, [“Age, Race, Class, and Sex: Women Redefining Difference”](https://www.ualberta.ca/en/institute-intersectionality-studies/media-library/intersectionality-readings/lorde-age-race-class-and-sex.pdf), in *Sister Outsider* (Crossing Press, 1984), pp. 114–123, especially 115–116 and 120–121. Lorde examines the unequal power attached to difference and refuses to let one aspect of a person stand for their whole life. The comparison between this salon's skin and nail controls is the book's application of her argument.

---

## Color Rainbow

*Color_Rainbow*

### More colour, another rainbow


Two offers wait by the entrance: a crystal in a wire case and a cube to collect. Neither is required to join the celebration.

The mushrooms are dressed for it. Pearl collars beneath candy-coloured caps; stars beyond the arch; a small staircase that seems to have wandered in from a platform game. There is also a level path. You can join the celebration without taking the steps.

Enter along the coloured centre path. Confetti opens above it. You have not solved a puzzle yet. Stay a moment with the possibility that the room is pleased you arrived.

The little wire cubes have returned, spaced along the middle of the walk. Walk into one. Its outline disappears and sparks rise from its place, drawing long coloured tails through the air. Keep walking. Another cube, another burst. For a moment, the celebration marks where you have been.

Find a boundary between two colours in the rainbow. Follow it far enough to see its curve. At the control plinth, press RE-DIVIDE. Find that boundary again. Has it moved, disappeared, acquired a neighbour? Has the opening beneath the arch become any smaller?

Try the button again before deciding what kind of rainbow this is. The steps keep their height. The path remains where it was. Yet the colours have another arrangement, and the familiar outline is being asked to hold it. CELEBRATE gives you another burst whenever you want one. There is no correct partition to earn first.

In the salon, one selected colour reached the same hand at two scales. Here a list of colours reaches a series of curved strips. Each strip is made from vertices: points placed along an inner and an outer half-circle, joined into triangles. Its position in the list gives it a colour.

The button moves through four authored choices: six bands, seven, forty-eight, then two. The generator keeps their combined width fixed:

```gdscript
return (RAINBOW_THICKNESS * 7.0) / float(maxi(1, rainbow_colors.size()))
```

The code keeps a total band thickness of `7 × 0.8`, shared out again whenever the list changes. The arch is scaled down to fit this hall. More strips each receive less of the fixed total; fewer strips receive more. The familiar arch can survive a change in how we divide its colour.

![Six, seven, forty-eight and two bands on the same museum arch.](/book-review/doc/book/iterations/2026-09-23-rainbow-room-for-another/four-arrangements.png)

*Four arrangements, seen from the same place. The coloured steps change with the arch; their height and the opening beneath it remain.*

Look for the seams in the forty-eight-band version. The option is called `continuous`, but each strip still has its own colour.

For each strip, the code computes a hue. **HSV** names hue, saturation and value: a place around a colour circle, how far the colour is from grey at that value, and a level that reaches black at zero. Here saturation and value both stay at one. Only hue travels:

```gdscript
var t: float = float(i) / float(count - 1)
out.append(Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0))
```

`t` runs from zero at the first strip to one at the last. A hue value of one would complete a turn around the circle; multiplying by `0.78` takes this sweep partway around instead.

A name can promise continuity while an implementation offers enough small divisions for some seams to become difficult to see. These are HSV values converted into RGB colours on a mesh. No droplets, sunlight or wavelength calculation produce this particular rainbow. Even its opaque appearance does not make the bands a climbing surface. The low steps have collision; the arch is a display.

Look for a colour you chose in the salon, first in the arch and then among the striped banners and mushrooms. There are pinks, pale blues, whites and dark colours that this sweep through saturated hues does not offer. They already share the room, even when the arch has no place for them. What would you have to change in the list, or in the rule that builds it, to give another colour a place in the arch?[^Color_Rainbow--colour-boundaries]

After the fourth arrangement, RE-DIVIDE returns to the first. You can stay with a version you like. Or you might want a fifth: a pale band, a colour given more room, a border that wanders away from the curve. The next change would reach beyond this button, into the list or the rule that makes it.

Before leaving, choose the version you want to stand beneath. Let the confetti return. At the far end of the walk, two slender poles hold a rainbow banner above your head. You can pass beneath it whether you collected every cube or left them all. The same programmed event can be a reward for obedience or an invitation that asks nothing of you; here you can repeat the confetti without passing a test.


Carry the distinction between a colour rule and the places where it is sampled. In the next room, pillars stand at particular addresses in a colour field. What is between them, where the field has a value but no pillar has been given a body?

[^Color_Rainbow--colour-boundaries]: A question for later: queer has no compulsory colour. A flag, a garment and a pastel wall do different work. We cannot assume that conservatives share a fear of pastels; we can ask when a colour becomes a threat to an order that wants its distinctions kept. In *Powers of Horror* (1982), Julia Kristeva connects abjection with disturbances of identity, system and order ([opening chapter, pp. 1–4](https://ieas-szeged.hu/downtherabbithole/wp-content/uploads/2018/02/Kristeva_Abjection.pdf)). This offers a way to question the policing of a boundary, without calling queer bodies abject. A future encounter could let us soften the bands or mix their colours towards white. These are different operations. A continuous control would still have limits; smoothness alone would not make it free.

---

## Color Pillar

*Color_Pillar*

### The colour between the pillars


Stand where the colours are pale. Follow one line of pillars farther into the field. The hue stays recognisable while its saturation increases. Now walk across that line. The hue changes too. Two directions, two different ways to change a colour.

There are thirty-five pillars, but the floor does not stop at thirty-five colours. Look between the columns. The smooth field continues where no pillar stands. Each pillar is a sample of that field at a particular position.

![Thirty-five columns above a continuous colour field, and the same installation seen from within.](/book-review/doc/book/iterations/2026-09-23-pillar-colour-between/field-and-passage.png)

*The same field, seen from above and from between the columns. A colour continues across the ground where no pillar stands.*

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)
```

`p` is a position measured from the field's first sample. Dividing by 12.8 and 19.2 turns the distances across its two spans into fractions: `u` and `v`. `clampf` keeps each fraction between zero and one.

Stay in one column of samples and follow it from the pale end to the far end. Its `u`, and therefore its hue, stays fixed. At the first row, `v` is zero and saturation is 0.25; at the last, `v` is one and saturation is 1.0. `lerpf` supplies the values between them. On the way back, the same hue grows pale again.

Value stays at 0.95 throughout the field. You have varied one part of HSV while keeping two still. The gaps between columns contain possibilities that the collection has not put into a body. They are also where you can walk.

Five columns by seven rows, with 3.2 metres between samples: the field gives the rule room to be walked. Each pillar rises 4.6 metres. Walk close enough to read a sample's address and colour code, then step back until several pillars overlap. The computed values remain fixed. What their company makes visible keeps changing.


Beyond the field, twelve collections hang on a framed wall. Their colours have names, and their groups have names too. These sets were assembled. The field was evaluated. Both are ways of deciding which colours belong together.

Take a swatch if you want to carry that decision into another view. Its label pairs a hexadecimal RGB code with the nearest colour name from a small list. The code travels with it; its neighbours stay on the wall. Compare it with a pillar, with another swatch, with the space around your hand.

The wall does not finish the gradient. It gives you another method of collecting it, with another set of omissions.


On the next floor, follow what happens when a rule assigns colours to grid cells. Keep the spaces between these samples in mind.

---

## Color Grid Pallet

*Color_Grid_Pallet*

### Find the colour again


Choose a square before you choose a colour. The white outline marks one piece of the floor. On the console, two numbers give its address. Press X +. The outline moves across. Press Z +. It moves along the other direction. The floor stays where it was.

At the pillars, a position supplied a sample. Here you can write something back.

Press COLOUR. One cell receives pink. Press again and it receives another of the four available inks. Find a colour you want to leave there. Move the outline away. Keep going until the address returns: each direction cycles through five positions. The colour is still waiting at the address you left.

The white outline has travelled. Your exception has not followed it.

![A pink edit stays at address (10,10) through selection changes and is replaced when RULE runs.](/book-review/doc/book/iterations/2026-09-23-grid-colour-kept/an-address-keeps-colour.png)

*Write, leave, return, rewrite. The pink square keeps its colour while the white outline moves. RULE replaces that value; the same cube still supports you.*

```gdscript
colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
```

One line writes to one instance. `selected` holds the two coordinates you chose; `cells` connects that address to a cube in the room's drawing buffer. Moving the selection changes what the console reads. It does not carry the stored colour from cube to cube.

Look from the small swatch beside the controls to the floor. Both receive the stored value. Their size, angle, light and neighbours differ. A matching number does not settle how the colour will meet you. The room where colour needed company has followed us here.

Now press RULE.

Your exception gives way to the floor's repeating assignment. The address remains. Walk toward the place you changed: the cube still supports your body. There has been no new geometry, no hole, no repair of the route. What changed was which colour that position received.

```gdscript
var colour_index: int = (address.x + address.y) % palette.size()
colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
```

In this two-coordinate address, `address.y` names the room's z direction. Add the coordinates. `%` keeps the remainder after division by the number of colours in the palette. Another cell can have the same remainder and receive the same colour. Compare addresses (8, 9) and (9, 8) after applying the rule: both sums are seventeen. The diagonal relationships were already inside that addition.

Try PALETTE. The collection changes; the assignment keeps its form. The floor finds another appearance without learning another way to stand.

We could mistake this regularity for a requirement of the grid. Yet you have just made an exception. The cube held it perfectly well. The rule did not return because the exception was impossible. It returned because you pressed a button that wrote across the floor again.

The console lets you select twenty-five positions and write one of four inks. RULE reaches beyond that region, across the interior floor. You can stand on a square whose colour the program can change and whose address the console will not let you choose. Why should its reach exceed yours?

Each address keeps only its current colour. An edit remains while you look elsewhere, but RULE replaces it and reloading the room starts again. To remember more would require another place to keep what has been overwritten.


Ahead, a coloured ball is already moving across a canvas. We leave the address with its current value and approach a surface on which marks accumulate. What will that surface keep of a movement after the body has passed?

---

## Color Paint

*Color_Paint*

### Before the hand


A coloured ball is already moving across the canvas. Wait before taking anything. The line changes direction, and the pigment changes colour as it travels. A painting is underway without your hand.

At the grid, a colour waited at an address until another write replaced it. Here, look back at a place the ball has left. Something of its passage remains. Something is already changing.

Thirty pigment balls wait on the low tray. Pick one up and aim it at the canvas. Move across the automatic line. Your gesture reaches a surface that has other business; it does not wait for you to finish. Release the ball. It returns to its place, and your marks stop arriving. The other painter continues.

Which part of the image can you still call yours?

![The same museum canvas before pickup, during a second gesture, after release and a little later.](/book-review/doc/book/iterations/2026-09-23-paint-shared-memory/the-surface-keeps-working.png)

*A pigment ball is held and moved across the automatic line, then released. The ball returns to the tray while the painting continues to change.*

The canvas has its own addresses. `u` and `v` measure position across the surface, each from zero at one edge to one at the other. The automatic painter supplies both coordinates:

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
```

Two oscillations give the automatic brush its position. Their rates differ. Follow one turn of the line and then another: neither coordinate alone describes the gesture you see. Its hue changes with elapsed time too. The moving ball is the visible companion of this calculation; no collision is needed for its paint to arrive.

Your ball takes another route. A ray finds the canvas you are aiming at. The hit becomes a position on that surface, then a pair of coordinates between zero and one. The canvas is four metres wide and two and a half high. Those proportions matter: assuming a square would quietly move your mark away from where you aimed.

Both routes reach the same drawing operation.

```gdscript
surface.draw_line(previous,uv,color,12,256)
```

That is the automatic caller: brush radius twelve pixels, positions snapped to 256 divisions along each axis. The manual balls carry their own brush sizes and snap resolutions. Try another ball. Colour changes, but it is not the only difference in your hand. The apparently continuous movement passes through a finite choice of positions, as the drawn line did in Trace.

The wet canvas keeps working between these calls. Its shader samples the preceding image and neighbouring pixels, shifts the sampling position, and fades the result toward white. The surface remembers by becoming another image. It does not preserve a list of gestures that can be retrieved intact.

```glsl
vec4 color = mix(vec4(1.0), prev_color, dissipation);
```

White enters the work again. It is the direction of forgetting in this particular simulation. We could ask for another ground, another rate of fading, another way for two colours to meet. None is the natural behaviour of code. Here we can point to the line that makes the decision.

The automatic brush advances by elapsed time. The wet surface updates with rendered frames. Even their clocks differ. A slower rendering pace can change how much the image has faded during the same time on your watch. The computer's ability to keep up participates in what the painting becomes.


Turn from that accumulating surface to the studies after Josef Albers’s *Homage to the Square*.[^Color_Paint--albers] Let one coloured area hold your attention, then include its surround. At the painting, a neighbour may arrive while you look. Here an arrangement holds the comparison available for longer.

Return to the canvas. Some of what happened while you looked away is still visible. Some has flowed into something else. The shared surface has made room for two ways of moving without keeping them separate for you.


Ahead, colour becomes a partition you can walk beside and look through. What happens to this question of neighbours when the coloured surface helps organise the room itself?

[^Color_Paint--albers]: Albers began [*Homage to the Square*](https://www.moma.org/collection/works/79438) in 1950. His [*Interaction of Color*](https://www.albersfoundation.org/alberses/teaching/interaction-of-color), published in 1963, develops exercises in how surrounding colours affect what we see. Our invitation to attend to a colour and its surround draws on that inquiry; the procedural gallery is our interpretation.

---

## Color Walls

*Color_Walls*

### The view has partitions


Someone has prepared a place for you. A desk, a monitor, a chair. Seven more places repeat along the aisle. The glass has colour; the office has an order.

Choose a cubicle. Before entering, look toward its desk through a pane. There is almost nothing between you and the chair. Almost. Walk toward the opening instead. Your view took a route your body could not.

At the entrance console, press **GLASS / OPAQUE**. Return to the same cubicle. The chair has disappeared behind a coloured wall. Find the opening again. Has the route become longer, or has finding it become a different task?

Press once more. The furniture returns to view. No doorway has opened.

![The same furnished cubicle viewed through glass and opaque partitions.](/book-review/doc/book/iterations/2026-09-23-walls-view-and-passage/same-opening.png)

*The view changes; the opening stays. Both states send the body through the same doorway.*

The switch changes two material properties on each of forty panes:

```gdscript
mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if glass_visible else BaseMaterial3D.TRANSPARENCY_DISABLED
mat.albedo_color.a = 0.26 if glass_visible else 1.0
```

The collision bodies remain where they were. Each cubicle still has its 1.2-metre entrance; the walls still meet at right angles. A change to visibility can alter how you approach a place without changing the geometry that admits you.

In Paint, two gestures entered one image. Here the image and the body encounter different accounts of the same wall. Through the glass, you can see the desk from the aisle and the aisle from the desk. Opacity interrupts that view in both directions. The cubicle offers another degree of privacy without another way out.

Move until several panes overlap. Their colours enter the renderer's transparency calculation. This glass does not calculate the wavelengths a real pane would absorb. Its clearness is a setting. Even the apparently empty space between you and the desk has been made by a procedure.


Leave the cubicle through its opening. At the smaller models, look for red, first in the cube and then in the cylinder. Where could you go from it?

You have been walking through an arrangement of coloured space. These models arrange colour values in space. In the cube, increasing the red channel moves a sample along one axis. Green and blue have their own directions. A colour has become an address again, but the address now comes from the colour itself.

![The museum’s RGB cube and HSV cylinder, each displaying five hundred colour samples.](/book-review/doc/book/iterations/2026-09-23-walls-view-and-passage/colour-coordinates.png)

*RGB channels become three straight directions. In HSV, hue goes around, saturation moves outward and value changes height.*

The RGB model assigns a sample's position and colour together. In this shortened version of the construction:

```gdscript
position = (Vector3(r, g, b) - Vector3.ONE * 0.5) * cube_size
colour = Color(r, g, b)
```

Look across to the HSV cylinder. Hue turns around its axis, saturation moves outward, and value changes height. Going around has replaced one of the cube's straight directions. The two models offer different ways to organise colour values.

Neither contains every colour as a visible point: each holds five hundred samples. The gaps belong to the display we have built. Even the black corner has been brightened slightly so that you can find it. To show a value, the exhibit has already made an accommodation. What would disappear if it refused?


The next bench starts with red at one end and blue at the other. Sixteen small cubes run from one to the other. Follow them with your eyes, then press **RGB / HSV**. Leave the endpoints alone.

The middle changes. The agreement about where to begin and end did not decide how to travel.

![The same sixteen gradient cubes between red and blue in RGB and HSV modes.](/book-review/doc/book/iterations/2026-09-23-walls-view-and-passage/same-endpoints.png)

*The endpoints remain red and blue. Changing the interpolation changes the colours encountered between them.*

In RGB mode, the calculation is:

```gdscript
col = ca.lerp(cb, t)
```

Here `t` runs from zero to one across the sixteen samples. Red decreases as blue increases. In HSV mode, the program instead chooses the shorter arc around hue, while interpolating saturation and value. For these endpoints that keeps a bright passage through magenta, where the RGB passage was darker. Try **COLOUR A** and **COLOUR B** to choose another pair from eight presets. Does the distinction remain as conspicuous?

The path was chosen in code. The number of places along it was chosen too. Sixteen cubes let us inspect a transition without pretending we have occupied every value between its ends.


A view through glass, a position in a colour model, a calculated passage: similar appearances can conceal different operations. Ahead, the disco floor returns in colour. Keep its arrangement and change its palette. Does the same pattern still invite the same movement?

---
