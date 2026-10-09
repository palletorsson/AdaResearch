# Color: the chapters

Working drafts as they stand on 2026-09-17, in sequence order. Artifact tags removed; text otherwise verbatim.

## Color Context Placed

*Color_Context_Placed*

# A colour with company

Find the warm Albers study among the recovered compositions. Stay with a small area of colour long enough to notice what surrounds it. Then let your gaze include the neighbouring work. Has the colour changed, or has the comparison?

The arrangement holds several ways of giving colour company: a stack, a frame, furniture, repeated forms. Some make relationships easy to name. Others put more into the view than a name can hold. Begin with one work, then widen the view.

The warm study is a made configuration. Its proportions, colours and neighbours have been chosen. The room does not offer a neutral sample against which every other arrangement must be measured. It offers something specific that another arrangement can contest.

Five shapes stand in a column, taller than you. Walk the row of them. The shapes do not change from one column to the next; the rule that gives them colour does. In the first, one ochre covers everything, and the paint knows nothing about the form. In the second, the colour names the kind: circle blue, square red, triangle yellow, as Kandinsky's Bauhaus questionnaire of 1923 proposed. In the third, the colour reads the height, so two cubes at different levels no longer match. In the fourth, each colour is the complement of the one below it. Nothing in that column has a colour of its own. Each has the colour its neighbour leaves it.

The second row keeps the naming rule and changes the alphabet. Turned shapes and cut shapes take the same assignment. A cone counts as a triangle and turns yellow. A torus has no name in the questionnaire and stays grey.

In the corner two white walls meet, and three tall panes cross in front of them. Stand in a wedge and look through. Through one pane the wall is that pane's colour. Through two it is what the two have left: the printer's three leave blue, green and red. Through three, almost nothing. The colour you see is not on the pane. It is what the panes between you and the white have taken away, and how many stand between you and the white is decided by where you stand. Move one wedge over and the darkest place moves with you. The table this was taken from mixed its panes by averaging and called the result subtractive; averaging is what your eye does further down the hall, and it is another thing. In the far corner the panes carry the totem's red, yellow and blue. Crossed as filters, the primaries go dark. A primary is a claim about a medium. The white here is the corner's own; the light that reaches it is still the hall's.

Further on, a column has been moved, and each position has been left standing, with a rail along the floor to show the direction. In the first row the direction changes: along the hall, upward, where one move is all the ceiling allows, into the depth, and diagonally. In the second row the direction is fixed and the colour rule changes. Moved with the colours kept, the copies cannot be told from the original: translation does nothing to colour. Coloured by distance, each copy is a different hue, because the colour was reading its position all along. Coloured by step, the copies count: first, second, third.

A translation preserves a shape, its size and its colour. It preserves the colour only if the colour was a property of the shape. Where the colour was a property of the place, moving the shape changes it. The room asks which of the two you are looking at.

Between the rows two drums stand taller than you, striped blue and yellow. Walk round the first. Its stripes are fins, blue on one face and yellow on the other, so from wherever you stand the drum is half blue and half yellow, split on the fin that faces you, and the split walks round with you. No fin has a colour. Every fin has two. Then go to the far end of the hall and look back at the second drum. Its stripes are painted on, but they are narrower there than the headset can hold apart, and blue and yellow become one grey: not the green of the paint pot, not the dark green the filters leave, a third answer from the same two colours. Which of the three you get depends on the company. A pane, a distance, a pot.

In the bay between the moved columns, columns stand on a dark board that nobody arranged. Five cells, the ones Conway called R, were set down and a rule was run: a cell with two or three neighbours lives, an empty cell with three neighbours is born, and everything else dies. What stands is the eighth generation. Each column is as tall as the crowd around it, so you read the count with your body: two neighbours at your eye, three over your head. The paint is the rule's own record. Blue was born this generation. Orange has stood since the seed. Walk the streets the rule emptied and check the colour against the height. Earlier in the room the neighbour was one shape below. Here it is everyone around, and the colour remembers how long they have been there.

Carry the comparison into the next room. There, you can move a lamp and change what reaches the surface you are looking at.

---

## Color Flashlight

*Color_Flashlight*

# What reaches the surface

The colour is already there when you arrive. Several pools meet on a pale surface. Their edges are easier to follow than their crowded middle. Pick one edge. Which lamp is responsible for it?

Take the red lamp and turn it aside. Follow what leaves the surface. Bring it back slowly, across the other pools. There is a place where its red becomes difficult to name on its own. Move through that place again. Nothing has been painted over, yet something has appeared that neither lamp makes alone.

Leave the red lamp aimed at the surface. It stays where you release it. Take the green one and move its pool across the red. Separate them, then let their edges meet. Try the blue. The white lamp begins aimed aside; bring it into the comparison when you want to see what another contribution does. If the middle grows too pale to distinguish, separate the pools again. Their edges give you somewhere to begin.

In the previous room, a colour had neighbours. Here you can move one of the conditions of its appearance with your hand. What, exactly, have you changed?

The receiving surface keeps the same material throughout. Its stored base colour, its *albedo*, is a near-white value. Each lamp carries a `SpotLight3D`: a light with a position, a direction and a cone. Turning the handle turns the cone. The surface receives a different contribution because you have changed where that cone falls.

Inside each lamp, `flashlight_color.gd` finds the light and gives it its colour:

```gdscript
var spot = _find_spot_light(target_root)
if spot:
    spot.light_color = light_color
```

Four copies of the same scene receive four values. The red instance is given `Color(1, 0, 0, 1)`; the green instance `Color(0, 1, 0, 1)`. The first three numbers address red, green and blue channels. The last is alpha. The assignment happens when the scene starts. Your hand supplies the subsequent movement; the lamp does not need to change its colour value to make the surface look different.

Aim a beam off the board and onto the floor or the cube standing to its side. The cone can cross the boundary of its intended exhibit. Does the colour still read the same way? Follow a shadow or an edge before giving the result a name. The lamp carries a value, but it cannot carry a complete account of what you will see wherever you point it.

There is a useful limit here. These lamps offer RGB values to a renderer. They do not calculate a spectrum of wavelengths. The room also has other illumination: turning the lamps away does not promise darkness. Even the pale surface we have kept fixed is a chosen condition of this experiment. We have made a comparison manageable by leaving much of the world in place.

Perhaps the surprising body here is the patch of colour. You cannot pick it up separately from the meeting that produces it. Move one participant and its boundary moves; withdraw another and it changes again. The code gives us a way to repeat that meeting. There is still more to ask of it.

Carry the distinction with you: changing the light that reaches a surface and changing the surface's own material can both change its appearance. In the next room, the receiving surface begins to resemble part of the body you act through. What happens when the colour is something you choose to wear?

---

## Color Nails

*Color_Nails*

What changes when a colour becomes part of the body you act through?

The lamps changed what reached a surface. Here a hand has outgrown the furniture. A small manicure table stands before it, complete with bottles, stools and another hand small enough to rest between the tools. Which of these bodies are you about to dress?

Find the movable point in the RGB box on its own plinth beside the manicure table. The space above and in front of the plinth is open for your hand. Take hold of the point and move mainly along one axis. Watch the preview swatch before moving along another. Predict which part of the colour will change on the next movement, then test that prediction with a short return journey.

Look up at the giant nails, then down at the petite hand on the table. Both answer the same choice. A movement small enough for your hand to make crosses two very different scales. Does the colour feel equally delicate on both? Return to a colour you have already tried and compare again.

The point's three coordinates are constrained to the box and converted into red, green and blue channel values. Moving along one axis changes one channel. Moving diagonally can change several at once. The box turns a colour choice into a position that your hand can revisit.

This is a three-channel description of colour. It does not divide every difference you can perceive into three equally noticeable kinds. Equal distances in the box need not feel like equal changes in the preview.

When tracked hands are available and connected, compare the nail surface with the swatch. The nail material adds its own response to light. A colour selected in the box can look different on a small glossy surface from the way it appears on the flat preview.

Repeat the comparison at the controller for the hand surface. Keep the coordinate gesture simple enough to recognise. Which difference seems to belong to your chosen channels, and which to the surface receiving them?

The two stations use the same position-to-colour mechanism but target different surfaces. The salon hands are two copies of the same source mesh. Their nail materials receive the nail-colour signal; their skin materials receive the hand-colour signal. Each receiving material is assigned the selected value:

```gdscript
material.albedo_color = colour
```

The scale difference lives in the geometry's transform. It does not require a second colour recipe. A nail can become monumental while its material still receives the same three channels as the small one on the cushion.

These two display hands remain available without tracked hands. They let you see a material change beyond the swatch; they do not establish that the player's own hand has been connected. Compare the surfaces that are actually present in your encounter.

Choose a colour because you want it, without requiring a naturalistic match. Try a nail or hand that interrupts the palette you expected from this body. What does that choice make possible for your sense of the figure you act through?

The editable channels are a material choice, not a complete description of identity. A system can make a surface adjustable while leaving many other bodily possibilities fixed. Name one choice the box gives you and another it does not.

Carry one of those chosen colours toward the rainbow. Where would you put it among the bands? The next room gives colour a familiar order; look for the decisions that hold that order in place.

---

## Color Rainbow

*Color_Rainbow*

# More colour, another rainbow

The mushrooms are dressed for it. Pearl collars beneath candy-coloured caps; stars beyond the arch; a small staircase that seems to have wandered in from a platform game. There is also a level path. You can join the celebration without taking the steps.

Enter along the coloured centre path. Confetti opens above it. You have not solved a puzzle yet. Stay a moment with the possibility that the room is pleased you arrived.

Find a boundary between two colours in the rainbow. Follow it far enough to see its curve. At the control plinth, press RE-DIVIDE. Find that boundary again. Has it moved, disappeared, acquired a neighbour? Has the opening beneath the arch become any smaller?

Try the button again before deciding what kind of rainbow this is. The steps keep their height. The path remains where it was. Yet the colours have another arrangement, and the familiar outline is being asked to hold it. CELEBRATE gives you another burst whenever you want one. There is no correct partition to earn first.

In the salon, one selected colour reached the same hand at two scales. Here a list of colours reaches a series of curved strips. Each strip is made from vertices: points placed along an inner and an outer half-circle, joined into triangles. Its position in the list gives it a colour.

The button moves through four authored choices: six bands, seven, forty-eight, then two. The generator keeps their combined width fixed:

```gdscript
return (RAINBOW_THICKNESS * 7.0) / float(maxi(1, rainbow_colors.size()))
```

The old width was seven strips of thickness `0.8`. That width remains the budget. More strips each receive less of it; fewer strips receive more. The familiar arch can survive a change in how we divide its colour.

The option called `continuous` still makes forty-eight strips. For each one, the code computes a hue:

```gdscript
var t: float = float(i) / float(count - 1)
out.append(Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0))
```

Look for its seams. A name can promise continuity while an implementation offers enough small divisions for some seams to become difficult to see. These are HSV values converted into RGB colours on a mesh. No droplets, sunlight or wavelength calculation produce this particular rainbow. Even its opaque appearance does not make the bands a climbing surface. The low steps have collision; the arch is a display.

Look away from it, toward the striped banners and the mushrooms. There are pinks, pale blues, whites and dark colours that this sweep through saturated hues does not offer. They are already welcome in the room. What would you have to change in the list, or in the rule that builds it, to give another colour a place in the arch?

The answer is not that every difference is already included. This control gives four choices, made in advance. It lets you discover that the arrangement can be otherwise, and also where its available otherwise stops. You might want a fifth choice. You might want a colour to take more space, or a border to refuse its neat curve.

Before leaving, choose the version you want to stand beneath. Let the confetti return. The same programmed event can be a reward for obedience or an invitation that asks nothing of you; here you can repeat it without passing a test.

Carry the distinction between a colour rule and the places where it is sampled. In the next room, pillars stand at particular addresses in a colour field. What is between them, where the field has a value but no pillar has been given a body?

---

## Color Pillar

*Color_Pillar*

# The colour between the pillars

Stand where the colours are pale. Follow one line of pillars farther into the field. The hue stays recognisable while its saturation increases. Now walk across that line. The hue changes too. Two directions, two different ways to change a colour.

There are thirty-five pillars, but the floor does not stop at thirty-five colours. Look between the columns. The smooth field continues where no pillar stands. Each pillar is a sample of that field at a particular position.

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)
```

The address is doing work. One coordinate chooses a place along the hue range; another chooses saturation. Value stays at 0.95. The gaps between columns contain possibilities that the collection has not put into a body.

The field is larger than its former arrangement: five columns by seven rows, with 3.2 metres between samples. Each pillar rises 4.6 metres. Walk close enough to read a sample's address and colour code, then step back until several pillars overlap. The computed values remain fixed. What their company makes visible keeps changing.

Beyond the field, twelve collections hang on a framed wall. Their colours have names, and their groups have names too. These sets were assembled. The field was evaluated. Both are ways of deciding which colours belong together.

Take a swatch if you want to carry that decision into another view. Its label makes it identifiable. It cannot carry every relationship the colour will enter. Compare it with a pillar, with another swatch, with the space around your hand.

The wall does not finish the gradient. It gives you another method of collecting it, with another set of omissions.

On the next floor, follow what happens when a rule assigns colours to grid cells. Keep the spaces between these samples in mind.

---

## Color Grid Pallet

*Color_Grid_Pallet*

# Find the colour again

Choose a square before you choose a colour. The white outline marks one piece of the floor. On the console, two numbers give its address. Press X +. The outline moves across. Press Z +. It moves along the other direction. The floor stays where it was.

At the pillars, a position supplied a sample. Here you can write something back.

Press COLOUR. One cell receives pink. Press again and it receives another of the four available inks. Find a colour you want to leave there. Move the outline away. Keep going until the address returns: each direction cycles through five positions. The colour is still waiting at the address you left.

The white outline has travelled. Your exception has not followed it.

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

In this two-coordinate address, `address.y` names the room's z direction. Add the coordinates. `%` keeps the remainder after division by the number of colours in the palette. Another cell can have the same remainder and receive the same colour. The diagonal relationships were already inside that addition.

Try PALETTE. The collection changes; the assignment keeps its form. The floor finds another appearance without learning another way to stand.

We could mistake this regularity for a requirement of the grid. Yet you have just made an exception. The cube held it perfectly well. The rule did not return because the exception was impossible. It returned because you pressed a button that wrote across the floor again.

The apparatus has its own narrow permissions. Five positions in each direction can be selected here. Four inks can be assigned. The rule reaches farther, across the interior floor. Why should its reach exceed yours? These limits are choices in this lesson's code; the experiment makes them available to question. A later version could let an exception travel, protect it from a rewrite, or change the rule itself. None of those possibilities happens merely because we can name it.

There is no history stack behind this console. An edit remains while you look elsewhere, but RULE replaces it and reloading the room starts again. To remember more would require another place to keep what has been overwritten.

Ahead, a coloured ball is already moving across a canvas. We leave the address with its current value and approach a surface on which marks accumulate. What will that surface keep of a movement after the body has passed?

---

## Color Paint

*Color_Paint*

# Before the hand

A coloured ball is already moving across the canvas. Wait before taking anything. The line changes direction, and the pigment changes colour as it travels. A painting is underway without your hand.

At the grid, a colour waited at an address until another write replaced it. Here, look back at a place the ball has left. Something of its passage remains. Something is already changing.

Thirty pigment balls wait on the low tray. Pick one up and aim it at the canvas. Move across the automatic line. Your gesture reaches a surface that has other business; it does not wait for you to finish. Release the ball. It returns to its place, and your marks stop arriving. The other painter continues.

Which part of the image can you still call yours?

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
```

Two oscillations give the automatic brush its position. Their rates differ. Follow one turn of the line and then another: neither coordinate alone describes the gesture you see. Its hue changes with elapsed time too. The moving ball is the visible companion of this calculation; no collision is needed for its paint to arrive.

Your ball takes another route. A ray finds the canvas you are aiming at. The hit becomes a position on that surface, then a pair of coordinates between zero and one. The canvas is four metres wide and two and a half high. Those proportions matter: assuming a square would quietly move your mark away from where you aimed.

Both routes reach the same drawing operation.

```gdscript
surface.draw_line(previous,uv,color,12,256)
```

That is the automatic caller: brush radius twelve pixels, positions snapped to 256 divisions along each axis. The manual balls carry their own brush sizes and snap resolutions. Try another ball. Colour changes, but it is not the only difference in your hand. As in Trace, the apparently continuous movement passes through a finite choice of positions.

The wet canvas keeps working between these calls. Its shader samples the preceding image and neighbouring pixels, shifts the sampling position, and fades the result toward white. The surface remembers by becoming another image. It does not preserve a list of gestures that can be retrieved intact.

```glsl
vec4 color = mix(vec4(1.0), prev_color, dissipation);
```

White enters the work again. It is the direction of forgetting in this particular simulation. We could ask for another ground, another rate of fading, another way for two colours to meet. None is the natural behaviour of code. Here we can point to the line that makes the decision.

The automatic brush advances by elapsed time. The wet surface updates with rendered frames. Even their clocks differ. A slower rendering pace can change how much the image has faded during the same time on your watch. The computer's ability to keep up participates in what the painting becomes.

Turn from that accumulating surface to the Albers studies. Let one coloured area hold your attention, then include its surround. At the painting, a neighbour may arrive while you look. Here an arrangement holds the comparison available for longer.

Return to the canvas. Some of what happened while you looked away is still visible. Some has flowed into something else. The shared surface has made room for two ways of moving without keeping them separate for you.

Ahead, colour becomes a partition you can walk beside and look through. What happens to this question of neighbours when the coloured surface helps organise the room itself?

---

## Color Walls

*Color_Walls*

# The view has partitions

Someone has prepared a place for you. A desk, a monitor, a chair. Seven more places repeat along the aisle. The glass has colour; the office has an order.

Choose a cubicle. Before entering, look toward its desk through a pane. There is almost nothing between you and the chair. Almost. Walk toward the opening instead. Your view took a route your body could not.

At the entrance console, press **GLASS / OPAQUE**. Return to the same cubicle. The chair has disappeared behind a coloured wall. Find the opening again. Has the route become longer, or has finding it become a different task?

Press once more. The furniture returns to view. No doorway has opened.

The switch changes two material properties on each of forty panes:

```gdscript
mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if glass_visible else BaseMaterial3D.TRANSPARENCY_DISABLED
mat.albedo_color.a = 0.26 if glass_visible else 1.0
```

The collision bodies remain where they were. Each cubicle still has its 1.2-metre entrance; the walls still meet at right angles. A change to visibility can alter how you approach a place without changing the geometry that admits you.

In Paint, two gestures entered one image. Here the image and the body encounter different accounts of the same wall. Let that disagreement stay visible. An invitation to look is not yet an invitation to enter. Perhaps the useful discovery is the doorway; perhaps it is the distinction that lets you ask for another kind of doorway.

Move until several panes overlap. Their colours enter the renderer's transparency calculation. This glass does not calculate the wavelengths a real pane would absorb. Its clearness is a setting. Even the apparently empty space between you and the desk has been made by a procedure.

At the smaller models, look for red. In the cube, increasing the red channel moves a sample along one axis. Green and blue have their own directions. A colour has become an address again, but the address now comes from the colour itself.

The RGB model assigns a sample's position and colour together. In this shortened version of the construction:

```gdscript
position = (Vector3(r, g, b) - Vector3.ONE * 0.5) * cube_size
colour = Color(r, g, b)
```

Look across to the HSV cylinder. Hue turns around its axis, saturation moves outward, and value changes height. Going around has replaced one of the cube's straight directions. The two models offer different ways to organise colour values.

Neither contains every colour as a visible point: each holds five hundred samples. The gaps belong to the display we have built. Even the black corner has been brightened slightly so that you can find it. To show a value, the exhibit has already made an accommodation. What would disappear if it refused?

The next bench starts with red at one end and blue at the other. Sixteen small cubes hold the intervening values. Follow them with your eyes, then press **RGB / HSV**. Leave the endpoints alone.

The middle changes. The agreement about where to begin and end did not decide how to travel.

In RGB mode, the calculation is:

```gdscript
col = ca.lerp(cb, t)
```

Here `t` runs from zero to one across the sixteen samples. Red decreases as blue increases. In HSV mode, the program instead chooses the shorter arc around hue, while interpolating saturation and value. For these endpoints that keeps a bright passage through magenta, where the RGB passage was darker. Try **COLOUR A** and **COLOUR B** to choose another pair from eight presets. Does the distinction remain as conspicuous?

The path was chosen in code. The number of places along it was chosen too. Sixteen cubes let us inspect a transition without pretending we have occupied every value between its ends.

A view through glass, a position in a colour model, a calculated passage: similar appearances can conceal different operations. Carry that habit of asking how into the chamber ahead. When colour and shape both change, which operation did your gesture actually set in motion?

---

## Chamber Color

*Chamber_Color*

# The colour lands

A small instrument faces a crate in a frame. The aim is already chosen. What remains for you to choose is when.

Press **FIRE COLOUR** once. Follow the bright sphere, then look at the crate. Stay with the place where it landed a little longer. Has only the crate changed?

Around its feet, some grid cubes have taken colour too. Their edges no longer quite agree with the grid. Small cubes spring away and disappear. Wait until the flash has passed before deciding what the shot left behind.

The instrument uses the catalyst's chromatic mode. Each launch chooses a hue:

```gdscript
var hue := randf()
proj.color_primary = Color.from_hsv(hue, 0.85, 1.0)
```

You did not select a pigment from the tray this time. The machine chose from an interval. During flight, its glow cycles through further hues, while the stored colour travels unchanged. The appearance that caught your eye on the way need not be the value delivered at the end.

The target receives that stored value and uses it to tint its materials. Nearby grid cubes receive another calculation. Their distance from the impact shifts the hue:

```gdscript
var hue_shift := dist * 0.15
var paint_color := Color.from_hsv(
    fmod(color_primary.h + hue_shift, 1.0), 0.8, 0.95
)
mm.set_instance_color(i, paint_color)
```

Only cube centres within 1.5 metres participate. This is a neighbourhood chosen by a distance test, not wet paint spreading over a surface. A cube just outside the radius stays as it was. Look for that boundary. The splash can look generous while its admission rule is exact.

Press again. The chosen hue changes; the aim stays fixed. The code also shrinks, turns and slightly displaces the affected grid visuals. Colour did not cause those changes by itself. The programmer put several operations behind one contact. We can separate them in the source even when the eye receives them together.

Approach the changed floor. Those smaller, tilted cubes still have their original collision bodies. The visual gaps have not all become gaps your feet can enter. Walls let a view pass through a body-blocking pane. Here the disagreement has moved underfoot: the image changes shape, while another account of the floor continues to hold you.

This is a remainder we can work with. We might choose to rebuild the collision and discover a new walk. We might preserve the disagreement and ask how you learn to trust a floor. The present implementation has made the second condition available; it has not completed the first.

On the third hit, the crate disappears. The frame stays. Wait. After four seconds the target begins to return, and you can start another three-hit cycle. Its counter starts again; the nearby grid has not been restored with it. A return can reset one part of an encounter while leaving another part altered.

The bench gives the visitor a mounted operation. It does not put a bracelet on your wrist or promise that these edits will survive reloading the hall. That larger question of what can travel with a body remains open.

Across Colour, a value has needed a lamp, a nail, a neighbour, an address, a surface, a view. Now it arrives as a message, and the receiver decides what to do with it. What bodies are possible depends on those receiving rules as much as on the value we send.

Carry the coloured cube forward in thought. In Patterns, we will give a repeated element an arrangement. What can repetition make possible that one changed cube could not?
