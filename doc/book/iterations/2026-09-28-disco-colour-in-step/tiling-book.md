# tiling: the chapters

## Pattern Disco

*Pattern_Disco*

### The same floor, another palette

Do you recognise the floor in its new colours?

The checker is navy and pink now. Its twelve-by-twelve squares return in the same arrangement. Step onto one and wait for its colour to change. It keeps supporting you. After the coloured rooms, this familiar floor gives us somewhere to try what we have learned.


Hold the floor and stop the sequencer. Choose CHECKER, then press COLOUR. Keep your eye on one square as the palette changes. Its neighbours change with it. Which colour seems to come forward? Does your chosen square still seem to belong to the same figure?

Nothing has moved, and the square's calculated value is still the same zero or one. Press ONE STEP. Now those values exchange places across the checker, while the palette stays fixed. Return to the previous arrangement with another step, then change COLOUR again. You have two ways to change what you see.

The separation is small enough to find in the code:

```gdscript
PALETTES[palette][value_at(x,z,floor_node.grid_width,floor_node.grid_depth)]
```

For the square-cell patterns, `value_at` returns zero or one for the address `x,z`. The first pair of brackets selects a palette; the second selects one of its two colours. A square can keep its value and receive another colour because we have changed the pair it draws from.

![Two palettes on the same held checker, seen from the same place on the museum floor.](/book-review/doc/book/iterations/2026-09-28-disco-colour-in-step/checker-pair.png)

In the earlier palette grid, you could leave one square changed. Here one choice reaches every square carrying the same value. The four pairs are prepared for us, including black and white. We can choose among them, but this console does not let us give a single square a colour of its own. The reach of a choice belongs to the way the tool has been made.

Leave the palette alone and change PATTERN. ROWS, DIAGONALS and SNAKE return from the earlier floor. A new pattern begins at step zero. COLOUR keeps the current step; SPEED changes how long a step takes. Try following one band through a slower and a faster passage.

After SNAKE comes SUPER TRIANGLE. The two colours can now meet inside a square. Hold it during a turn, when the diagonals have not yet settled into chevrons or diamonds. Change COLOUR there. The unfinished turn stays unfinished. Does the same edge still draw your attention?

A shader draws these divisions across the existing floor. Its palette supplies the two colours, while its movement changes how they meet. The square joints remain beneath the larger figures your eye can follow.


Start the floor and walk towards an approaching band. Let it pass underneath you. Its passage does not push your body. Walk with it for a moment, then across it. Can an invitation to move be felt without a force being applied?

Return to black and white while it runs. The paired values are familiar again. Notice whether you follow the same parts of the pattern. Changing back cannot undo the coloured versions you have just seen beside it.


Bring in one repeating note, then another. Watch a chosen column brighten briefly when a sounding step reaches it. Hold the floor's pattern and listen: the notes continue, and their flashes can still appear. Stop the sequencer too when you want both instruments to settle.

The score has its own clock; the moving pattern has another. Matching their tempos does not guarantee that they reach their beginnings together. Let them run for a while. Look away from the floor and keep moving. When you look back, where do you find the beat?

Your footsteps are not written into the score. You can move with a pulse, miss it, or keep another rhythm across it. The room can repeat its invitation without knowing what you make of it.


We have been choosing among patterns and palettes already offered. In the Foundry ahead, we can change the source that the copies draw from. What would you put there for the room to repeat?

---

## Pattern Foundry

*Pattern_Foundry*

### One decision, many surfaces

How many places can one small decision change?

The returning disco let us separate a pattern, its palette and its clock. Here a small arrangement supplies a much larger field. Make one decision where you can see exactly where it began, then let it reach the architecture around you.

Take this room in three passes. First follow a source decision into its copies. Then let one receiving surface keep an earlier image. Finally, visit the studio in the annex and let it take over a wall and the room around you. The source memory, spacing, offset and group experiments can wait for a return visit.


At DRESS THE ARCHITECTURE, choose a SOURCE. The loom, kaleidoscope, stamp press and pattern mill can each supply their actual output to the hall. Walk away from the controller and look for the repeated image along the walls and underfoot. Then return and choose another machine. One room has acquired another account of itself.

TARGET selects ROOM, WALLS or FLOOR. REPEAT SIZE changes how much surface one complete output image occupies: two, four or eight metres. TINT multiplies the colours of that output by a pale colour or white. It does not rewrite the machine's own palette. To change the source design, use that machine's controls, then look back at the architectural surfaces receiving it.

The loom's carpet includes a short history of bands. When that carpet becomes the source, its history is what repeats across the room. The source named on the controller matters: a live connection can carry the current state of a record as well as a single current motif.

Press LIVE / HOLD. Both architectural receivers keep an independent image of what they were carrying. The machines continue their work. RESET reconnects the whole room to the loom, with white tint and a four-metre repeat. The smaller specimen controls beside the machines remain available for more precise comparisons; this console addresses the architectural skin.

These images add no collision. A patterned wall stays solid, and a dark floor tile stays supported. Before calling a visual difference a new passage, try to account for what your body can actually do there. Then go to the small tile where a source decision can be made one cell at a time.


Take a coloured cube from the palette and release it over an off-centre cell in the small tile. Watch the repeated preview. Find several places where your mark appears, then locate the one source cell you changed.

Add a second mark beside the first. Predict the repeated pair before looking across the whole field. The size of the result can make the action seem more complicated than it was. Many visible changes have followed one local edit.

The tile stores a finite array of colour choices. To draw the larger field, the repetition rule maps each preview position back to a position in that array. Copies share a source. They do not each contain a separately authored decision.


Make a recognisably asymmetric mark at the mirror station. A mark away from the centre, with a differently coloured neighbour on one side, makes reversal easier to notice than a centred dot would. Follow the pair through the preview and compare the directions in which it faces.

The simple repetition keeps the tile's orientation. The mirror rule reverses selected copies along its directions. The source motif and the transformation applied to its copies do different work: changing either can change the field.

Now try to make the mark appear only once while the rest of the field stays unchanged. Editing the shared source makes it recur. The difficulty is evidence about the way this instrument stores authorship, rather than a failure to choose the right colour.


At the loom, two upright samples wait beside the carpet. One is flat. The other bends towards you. Press MARK on their console, then look for the changed cell on both surfaces. Walk a little to one side. The mark narrows around the curve; has the machine given it less room?

The samples have the same surface height and width: 1.2 metres high, 1.2 metres across the sheet. Across the curved one means following its arc. Its width seen head-on is smaller. Both receive the same colour image, with the same addresses in the same order. Bending the sheet changes where those addresses meet your view.

The loom begins here with translation: a five-by-five card repeated four times in each direction on each sample. MARK changes one card cell. Touching the loom's pegs lets you choose other cells; its GROUP control changes the repetition rule. Try a mark away from the centre before changing that rule. A centred mark can hide what the operation has done.

The current specimen is assembled one pixel at a time. This is the address at which the repetition rule enters:

```gdscript
var index:int=WallpaperGroups.get_symmetric_color(source_x,source_y,n,live.card,group_id)
var c:Array=live.palette[index]
img.set_pixel(x,y,Color(c[0],c[1],c[2],c[3]))
```

The rule returns a colour index. The palette supplies its colour. The receiving sheet supplies its shape. They meet in the visible pattern, but you can change them separately.

With CURVE selected on the display, press LINK / HOLD. Now press MARK again. The flat sample follows; the curve keeps what it had. There is a difference between them, and the loom has continued running. Holding this sample means declining the next image. It does not stop time or let you edit just one of its repeated marks.

For a first visit, link the curve again and continue to the studio in the runway annex, where the third pass begins.

Take the passage into the runway annex, then follow its side aisle into the curved room. The studio stands inside it. A small source has become something you can stand within. On its smaller surface console, choose WALL and press APPLY LIVE. Edit a cell in the studio. The wall follows it now; the loom's other surfaces continue their own account. Nothing in the wall's geometry had to move for this allegiance to change.

Press HOLD, then edit again. The wall keeps its image. UNDO LINK restores the preceding connection, including whose pattern it followed. LOOM explicitly returns the selected surface to the loom. A surface can share a source, keep a memory of it, or begin following another one. Watch the owner named on the display: the same instruction to change a cell now has different consequences depending on who is listening.

Choose ROOM and press APPLY LIVE. The same decision reaches the curved wall and the floor beneath you. Turn your head, walk towards a mark, then step back. The pattern changes its appearance across your view while the stored cells stay put.

Choose ROOM FLOOR and press HOLD. Change a source cell. The wall follows; the ground keeps its earlier image. The room has separated into two different moments. Its curvature has not changed, and the opening still admits your body. What changed in your sense of the space, even though its supports stayed where they were?

#### On a return visit

The loom has more to show. The following experiments ask what a saved source remembers, and which receivers accept a change in spacing or position.

Link them again. Press SAVE, change a peg or the group, then RESTORE. The saved card and palette return, along with the carpet's short history of bands and its saved animation phase. The carpet moves on from there. The two upright samples show only the current rule; the carpet carries earlier decisions as well. Saving the source does not save the curve's temporary held image.

Turn towards the low wall behind you. The pattern has arrived there too. Follow a pair of marks along it: the wall has more repetitions, rather than a larger version of the image. Under the starting translation rule, one card occupies thirty centimetres on every surface. The wall remains solid. Its new appearance has supplied no new passage.

Press TARGET until the display names WALL. Its mounted label picks up the selection. Hold it, then change the source again. The two samples move on; this piece of the room keeps what it had. It was easy to treat the wall as background while looking at the machine. Now the background participates in the same decision.

Keep the wall held and press REPEAT SIZE. The source advances from thirty to sixty centimetres. Look for the same pair of marks on a sample: each now occupies more room, and fewer copies fit. The wall keeps its earlier spacing. Both labels say what each surface is carrying.

Press again for fifteen centimetres, then once more to return to thirty. Nothing has been added to the card. The sheet has not grown. The address calculation now reaches the next source cell sooner or later as it moves across the same physical surface. In the starting translation rule, the 1.2 metre sheet holds eight, four or two card periods. Its edge may cut through a repeat; the surface does not stretch to finish the motif.

SAVE remembers the source spacing too. Set the source to sixty centimetres and save it. Change spacing, then restore while the wall is held at thirty: the linked samples recover the saved scale, and the wall continues to keep its difference. The carpet remains a separate view of the loom's band history at its original spacing.

Link the wall again, then press UNDO LINK. Its earlier held image returns. The carpet and the other machines continue their own work. Selecting a receiver changes who can follow; MARK, SAVE and RESTORE still act on the shared source.

Leave one surface held. With the repeat size at thirty centimetres and the offset at U00, press OFFSET +5CM. Follow a pair of marks on a live sample. They have changed position without growing. The image on the held surface stays where it was.

The offset advances the address sampled at each point on the sheet. U names that sheet's horizontal texture coordinate; it is not a shared compass direction through the museum. The curve carries the displacement around its bend. Neither surface moves, and the motif still has the same cells.

Press five more times to reach U30. Under the starting translation rule, the image returns to its U00 appearance. The stored offset differs by one full repeat. Returning to an appearance need not undo the process that brought you there. One more press returns the control to zero. SAVE and RESTORE remember the source offset; a held surface keeps its own accepted offset until you link it again.

Walk towards the wall beyond the loom, then around the grid block to its shorter east face. NORTH and EAST have received the pattern too. Their widths differ, but a card occupies the same number of centimetres. At sixty centimetres, the height of these low faces ends halfway through a repeat. The rule has continued further than the surface can show.

Select ARCHITECTURE. This names three wall faces, leaving the two specimens outside the selection. If their states are mixed, press LINK / HOLD to bring the walls live; press again to hold them together. Change the repeat size. The samples change while their surroundings keep an earlier scale. Try the reverse: hold a specimen and let the walls follow.

EAST can also be selected alone. Hold it, then return to ARCHITECTURE: the display now reports MIXED. One part of the background has separated from the others. ALL FIVE includes the three wall faces and both specimens. Neither name includes the whole museum. These names describe memberships we have made, and can revise.



A repeated field can be economical, recognisable and pleasurable. It can also make a wanted exception difficult to express. Choose a reason for keeping one copy different: a direction marker, a mistake you want to retain, or a place that should resist the general pattern.

The held curve has made one kind of separation possible: a whole surface keeps an earlier image. Keeping just one mark different would require a finer distinction, an exception within the repeat. Name what should stay shared and what you would let separate. The instrument's smallest editable unit decides how precisely you can answer.

The next station keeps the motif while changing the larger symmetry rule. Carry an asymmetric mark with you in memory; it will help you see which operation has been applied.

---

## Tutorial Pattern

*Tutorial_Pattern*

### The mark and its return

What can change when you keep the painted cells exactly as they are?

In the foundry, a small source reached the walls around you. Here, pass the patterned plates in the main room and take the opening in the east wall into the side bay. Two framed fields flank an editor. Both contain the same red bend, the blue corner and the small ochre interruption. Follow the red bend across each field. Does it always face the same way?


The sixteen buttons on the console show the source. Read them from the top row down. Find the red bend there, then find it again on the left panel. Move one tile to the right. Something has travelled without turning.

On the other panel, the next bend faces back. The painted source still has only sixteen cells. Nothing in that little grid has turned over. Where did the other facing come from?

Press PM. Look at the floor, then back at the source buttons. Press P1 and return. The floor changes its arrangement; the two wall panels keep their respective rules. They let you compare what the floor has just left with what it has become.

The names can wait until you have found the difference. P1 repeats by translation. In this station's PM rule, alternate columns sample the source in reverse across x. The shader begins by separating a position into the tile it belongs to and its position within that tile:

```glsl
vec2 st = uv * tile_scale;
int tile_x = int(floor(st.x));
vec2 local = fract(st);
```

The whole part counts tiles. The fractional part returns to a place inside one tile. For translation, that local address is enough. For the reflected field, one additional condition changes where the lookup goes:

```glsl
if (imod(tile_x, 2) == 1) {
    local.x = 1.0 - local.x;
}
```

These lines run in the wallpaper shader used by the station. They change an address before it reads the source texture. They do not repaint the stored cells. The alternating facing belongs to the relation between copies.

Now press FLIP X. Watch the source this time. Its blue corner crosses to the other side. Both wall fields respond, although their rules remain P1 and PM. Here the operation really does rewrite the array:

```gdscript
row.append(_grid_data[y][tile_size - 1 - x])
```

The line takes a cell from the opposite end of its row. Press FLIP X again. The second reversal brings every cell back. Try ROTATE, then follow the corner through four presses. UNDO takes you back one editing operation; RESET restores the starting mark and the translating floor. Reset can itself be undone.

Choose a paint colour and press a source cell. Put a solitary mark where the motif was quiet. Both fields receive it. Step back. Your interruption has become regular too.

A repeating system can make room for an unexpected mark while giving that mark a schedule. What would it take to let one copy depart without sending the departure everywhere? In the foundry you could hold a receiving surface apart from its source. Here the source is shared deliberately, so an edit travels through every copy. Neither arrangement answers every desire.

The panels and floor give each tile forty centimetres. The floor has more copies because it extends further. On the reflected panel, facing alternates across tile columns: the two-column cycle is wider than the individual tile. A boundary around one copy does not necessarily enclose the whole repeating relation.


The mark is made of cells, but the apparent continuity between copies is another decision. This lesson uses nearest-cell sampling, so a colour holds its square until another cell begins. A softer-looking edge would need a different account of how those stored values become visible. Sixteen cells have never been the whole surface, however completely they seem to occupy it.

For a moment, a field may look unchanged even after an operation. A very symmetrical source can conceal a reversal. Add a difference and try again. The useful mark may be the one that refuses to look the same from every direction.

In Array_Patterns, the repeated field extends along an environment. Keep these two questions available as you enter: what rule relates the copies, and what surface gives those relations a place to appear?

---

## Array Patterns

*Array_Patterns*

### An address needs a surface

When does repetition become an environment rather than a picture?

The red bend returns, with its blue corner and ochre interruption. It is the same starting arrangement you met in Tutorial_Pattern, entered here as a fixed source. Your edits from the previous room have not secretly travelled with you. This time the question is what gives the mark a place to appear.


Take the opening into the side bay. A six-metre passage stands on a raised platform; its console is beside the ramp on the lower floor. Three wedges make a broad ascent. Side walls close the routes around the tunnel, so crossing this bay takes you through it and down the ramp at the far end. The source has sixteen cells. There are considerably more squares inside the tunnel. Find the pale yellow indicator on the floor and compare its position with the console's two addresses.

Press COL +. The surface address advances. Press it again, watching the smaller source address. After four steps, one number has returned while the other has moved on.

```gdscript
column % 4
row % 4
```

These are the wrapping expressions used by the inspector. It displays addresses as `[row, column]`, then the palette index stored there. Surface `[10,1]` returns to source `[2,1]`. Another place can consult the same memory.

The tunnel's renderer first computes a small swatch from the source and its translation rule. The shader samples that swatch across each face. The inspector follows the same cell coordinates back to the four-by-four source. You can move the indicator without changing a single stored colour.

Now press FACE. The indicator moves to the right wall. The panel still speaks in rows and columns, but those directions occupy another plane. On the floor, one direction runs across the passage and the other along it. On the right wall, columns run along the passage and rows descend from the ceiling. The address needs a surface to acquire a direction in the room.

Walk inside. Follow a line to the corner between floor and wall. Each face begins its own grid. A shared motif does not promise that its edges will join there. The corner exposes a decision that was harder to notice on a single flat panel: where should counting begin, and which way should it proceed?

Return to CELL SIZE. A cell now occupies sixty centimetres instead of forty. The source still has four cells across. Its whole motif therefore spans 2.4 metres instead of 1.6. In the previous room, forty centimetres described an entire motif; here the mark has been enlarged so you can inspect its individual addresses. The same number needs its unit and its referent.

The passage has not grown. Its width remains 3.6 metres and its height 3.2. Some divisions fit exactly; others leave a cut cell at an edge. A room does not owe the pattern an integer number of repeats. The inspector selects complete cells; the remaining strip is still there to look at.

Press GRID. The dark joints disappear. Keep walking. No wall has opened and no floor tile has fallen away. Those divisions were drawn in a shader on four large surfaces. The supports that stop your body are separate. UNDO restores the last inspector setting, including cell size and grid visibility.


Back among the earlier stations, look at the brick preview. Follow a seam through two neighbouring rows. The boundary steps sideways. Compare that stagger with the tunnel's straight cell divisions and the corner where two faces restart their counting.

A stagger changes how rows relate within a field. A corner changes how a field is carried into space. They can resemble one another as disruptions, but they ask for different changes to the implementation. Keep the motif, the lookup and the carrier available as separate things to question.


An orderly image can conceal a complicated support. A conspicuous seam can reveal the rule more clearly than a perfect join. Neither smoothness nor interruption is automatically the more interesting result. What becomes available to a body that can read the difference?

This passage holds its pattern fully visible. The earlier automatic reveal remains another performance to revisit when we study change over time. Here there is time to compare addresses, then move on. Symmetry_Seventeen will ask what can be classified about an ideal repeating field. Bring the finite edge of this room with you.

---

## Symmetry Seventeen

*Symmetry_Seventeen*

### What counts as the same?

What would have to stay the same for this to be the same pattern?

You have followed an address around a corridor. The floor and the wall gave it different directions. Here the surface stays flat, and a small mark returns in ways that do not quite agree.


Begin at the tilted console in the side bay. Its sixteen buttons hold an asymmetric mark: a bent line, a second colour near a corner, a third near the bend. The left panel holds a sample. The right panel and the carpet follow the current source and rule.

Choose **PM**. Keep your eyes on the corner colour. Find it in the next block. Has the mark travelled, or has it also reversed? Compare it with the held **P1** sample. You have changed no source address.

Now choose **PG**. The reversal remains, but the colour no longer arrives opposite its neighbour. Follow it along the other direction. The rule has slipped the reflected copy by half the source height. With four source rows, that is two rows.

Try to describe the difference before pressing **HOLD**. This saves the current image on the left. It gives your next change somewhere to return to.

![Held P1 and live PG in the museum side bay](/book-review/doc/book/figures/tiling/symmetry-p1-pg-museum.png)

*One source, two returns. The left panel keeps P1; on the right, PG reflects alternate blocks and slips the source lookup by two rows.*

The three buttons select translation, reflection and glide reflection. In the editor's integer lookup, the last two differ by one line. This is the PG branch of `WallpaperGroups.get_symmetric_color`, with its local source coordinates:

```gdscript
var tile_x = px / tile_size
tx = px % tile_size
ty = py % tile_size
if tile_x % 2 == 1:
    tx = tile_size - 1 - tx
    ty = (ty + tile_size / 2) % tile_size
```

An odd block reverses the source column. Then the row shifts halfway round the source and wraps. The array stays where it was; the lookup changes which of its addresses is read. The panel shows eight source blocks across and eight down. A source block is not necessarily a full translation period: reversal makes you wait for another block before its orientation returns.

Select a colour, then press one of the sixteen source cells. The live panel and floor change together; the held image keeps its pixels. **UNDO** can recover a paint edit, a rule choice or the previous held sample. **RESET** restores the initial mark and P1 while leaving the held comparison available.

Now make the source less distinctive. Remove the corner colour, or make both sides alike. Does the difference between rules remain easy to see? A rule can still execute while your chosen mark conceals what it does. The selected button names a construction; it does not prove that the finished image has exactly that symmetry group. An unusually symmetric source can introduce more symmetry.


Return to the cage. It marks rotational orders one, two, three, four and six, and crosses five and seven. Its subject is rotation compatible with a periodic planar lattice. It is a diagram of that restriction, not an experiment that tries every arrangement until one fails.

The larger classification concerns ideal patterns repeating in two independent directions on the Euclidean plane. Under those conditions there are seventeen plane-group types; the [IUCr tables](https://it.iucr.org/Ab/) list their operations and generators. The three comparisons at the console are an entrance into that subject, not a demonstration of the completeness of the list.

The other machines give these names somewhere else to work. Compare a loom or mill with the framed samples: can you find a repeated turn or reversal before reading its group label? The patterned wall gallery carries selected rules across the architecture. Its changing colours and motifs can make the operation harder to recognise than our small, deliberately awkward mark.

At the atlas plates, read the makers’ names as well as the patterns. A symmetry group can describe a relation between marks without describing the work, place or history that brought them together. Carry both kinds of attention through the gallery.

A fivefold-looking flower can sit inside a repeating cell. That does not give the entire field fivefold rotational symmetry. The flower and the field ask the question at different scales. Look for the boundary of what is being counted.


The catalogue closes under its assumptions. This finite carpet still ends. Its colours have been sampled into pixels, its material meets the light, and your body stands at an angle to it. Those differences have not disappeared because the symmetry has a name.

What could this classification tell you about a garment? What would it leave unasked about its cut, its wearer, or the way a seam interrupts the repeat? Carry the small mark forward. In the next hall, the question is what happens when the source gains another index and supplies a volume.

---

## Ribbon Patterns 01

*Ribbon_Patterns_01*

### A mark acquires an inside

The mark has acquired an inside. Can you find it?

In the previous room, one source could repeat, reverse and slip across a plane. The corridor wrapped a pattern around several faces. Here, look between the faces. There are addresses behind the ones you can see.


The two grids near the entrance begin this study. The bars, shelves and sorting race further along the hall offer other ways to revisit arrays; start here with the low array. Sixteen cubes hold the same arrangement of four colours you have met in the pattern lessons. Find the blue corner, then the bend in red. The pale cells belong to the array too. Pale does not mean absent.

These cubes have bodies, but their addresses use only two indices: a row and a column. Giving a cell a visible thickness has not added a third index to its data. The room has made a two-dimensional arrangement out of three-dimensional objects.

At the console, press **X +** and **Z +**. Follow the turquoise frames. One frame selects a cell in the volume. The other shows the source cell from which it takes its colour. The displayed order is `SOURCE [z][x]` and `VOLUME [y][z][x]`; the same coordinates are placed in the room as `Vector3(x, y, z)`. We have to choose an order for storage as well as directions for space.


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


What bodies are possible here? The extra index gives us another direction in which to arrange relationships. This particular rule makes repeated or shifted colour layers. It has not made a solid you can carve, a fabric that bends, or an organism that grows. Those would require further rules about what a value does.

There is already a decision worth returning to: every palette index receives a cube. Zero is a pale body. If zero meant no body, the same arrangement of numbers could admit gaps. If a value controlled density, resistance or affinity, other relations would become possible. We have not implemented those meanings at this station. We have found where they could enter.

For now, a slice lets you see by withholding most of the display. That is a useful reduction, provided we remember the forty-eight cells it leaves out. Turn the full volume back on before leaving. In **Ribbon_Patterns_02**, carry this distinction between stored value and visible appearance into the material and conditions that let a pattern be seen.

---

## Ribbon Patterns 02

*Ribbon_Patterns_02*

### The carrier participates

The value has stayed. Has the colour?

The previous room let you hide forty-eight cells without erasing them. Here the question turns towards the visible ones. A value has reached a surface. What else has arrived with it?


Begin with the two grey squares. One has dark neighbours, the other light. Look before touching the controls. Do they appear alike to you? There is no required answer to report; make a comparison you can return to.

Press **SWAP**. The backgrounds exchange places. The targets keep their numerical values. Does your judgement follow the square, its surroundings, or neither?

Press **SURROUNDS** to give both targets the same grey background. Seen straight on, their faces almost disappear into the grey. The raised edges may still give them away. The contrast has gone; the little bodies remain. Return to the unequal backgrounds and press **CONNECT**. A narrow bar joins the targets using their colour. Notice what becomes easier to compare, and what remains uncertain. **UNDO** returns to your previous arrangement; **RESET** restores the start.

The two targets and the connector are assigned `Color(0.5, 0.5, 0.5)`. This comparison draws them without lighting-dependent shading. The controls change the backgrounds and whether the connector is shown. Numerical equality is something we can inspect in the program. It does not oblige every viewer, display or viewing situation to produce the same experience.

![Equal target values against dark and light surrounds inside the museum](/book-review/doc/book/figures/tiling/contrast-neighbours-museum.png)

*One grey value, two different surrounds.*

![The same comparison after making both surrounds grey](/book-review/doc/book/figures/tiling/contrast-equal-museum.png)

*The surrounds now match the targets. Their faces nearly disappear; the raised squares remain.*


At the other station, the familiar bent mark covers a plane and a curved wall. Find its blue corner on both. The plane is four metres wide; the half-cylinder is four metres along its arc. Each begins with four horizontal repeats and two vertical repeats. Walk a little sideways. Equal distances along the surfaces need not occupy equal widths in your view.

Press **GRID** to mark the repeat boundaries. Follow one around the curve. Its width along the surface stays fixed while its visible width changes with your position. The two ends of this half-cylinder are edges, not a welded seam; this station has not tested a pattern closing around an entire body.

Turn the grid off and press **FLAT / SHADED**. Keep watching one pale part of the mark. Now press **LIGHT SIDE**. Where does it darken? Compare the plane with the curve before reading the explanation.

Both surfaces read one texture. Their difference enters through their normals: directions describing which way the surface faces. The plane keeps one direction across its face; the curve turns. This small shader multiplies the sampled colour by a directional factor:

```glsl
float gain = shaded
    ? 0.18 + 0.82 * max(dot(normalize(specimen_normal),
                            normalize(light_direction)), 0.0)
    : 1.0;
ALBEDO = ink * gain;
```

The dot product compares the two directions. The added 0.18 keeps the model's darker side from becoming completely black. These are choices in the experiment. **LIGHT SIDE** changes a direction inside this shader; it does not move the museum's sun. The calculation does not model cloth fibres, gloss or wavelengths. Keeping the model small lets us follow exactly where the difference enters.

Try **REPEAT SIZE**. It changes the horizontal repeat from one metre to fifty centimetres on both carriers. The vertical repeat remains one metre. Neither the source pixels nor the meshes change. **UNDO** recovers the earlier setting; **RESET** returns to flat colour and the initial spacing.


Imagine carrying this mark onto a sleeve. Which part would you call the pattern: the source array, its spacing along the cloth, or the appearance that reaches someone across the room? Keeping one of those fixed does not keep all of them fixed.

This is where dressing becomes a question for the program. A carrier contributes shape; a material contributes rules for appearance. Neither is a neutral delivery system for an untouched original. Yet their contributions can be separated enough to investigate: keep the recipe, change one condition, return, compare.

In **Ribbon_Patterns_03**, we follow these operations into the shader and fabric studio: what gets sampled, where an edge is drawn, how a surface responds, and what can be carried onto a body. The mark will travel again. We now have more than one place to look when it changes.

---

## Ribbon Patterns 03

*Ribbon_Patterns_03*

### What can you take with you?

Look down before choosing another appearance. In the museum, your garment grows as you enter new sequences. Returning to one does not add another layer. If you chose a nail colour in the salon, your virtual hands have already carried one decision here. A dress can carry part of the walk too.

The mark has crossed a floor, reflected, slipped along a row and acquired depth. In the previous room its values stayed fixed while the surface changed how they appeared. Here the surface is waiting beside a body. Find the bent red mark on both. What would have to stay the same for you to call this the same fabric?


Choose one of the four paint colours, then touch a square in the small source array. Watch the wall and the skirt together. One address changes; many places answer. **UNDO** brings the earlier source back. We still have the array we learned to read. We have given it somewhere else to arrive.

![The fabric studio and preview dress inside the museum](/book-review/doc/book/figures/tiling/fabric-studio-museum.png)

*The small source reaches a flat wall and a skirt. The crown and sleeves keep the look’s own materials.*

Press **UV / FABRIC**. The familiar mark disappears into a coloured field. Walk around the preview skirt. Where does the colour return to its beginning? This view draws the surface's own two coordinates as red and green. A curved body can carry a flat address system. It also has to decide where that system joins, ends or starts again.

Return to the fabric and press **OFFSET**, then **REPEAT**. Which operation moves the mark? Which makes more copies fit? The wall and skirt both begin with four horizontal repeats and two vertical repeats in their own UV coordinates. Their physical widths differ. The wall is three metres wide: four copies sit 0.75 metres apart. Four copies around this skirt do not promise that same spacing.

```glsl
vec2 address = UV * vec2(repeats, 2.0) + vec2(phase, 0.0);
ALBEDO = texture(motif, address).rgb;
```

The source texture is four by four pixels, read with nearest filtering. `UV` supplies an address from the mesh; multiplication repeats it, addition shifts it, and the texture wraps. A small statement keeps finding new places to speak. The skirt's side and caps bring their own UV layout. We have not made a tailor's continuous cutting pattern, or promised that every seam will match.

Try **CUT OUT**. Narrow strips disappear from the wall and skirt. Look through a strip, then try to move through the sample wall. The view opens. The collision still refuses you.

```glsl
if (cut_out && fract(address.x) > 0.8) discard;
```

Here `discard` stops drawing a fragment. It does not cut a passage into the collision shape. There are already two accounts of the wall: one receives your gaze, another receives your attempt to cross. Finding their disagreement gives us somewhere precise to work. A visible opening has made a promise that the movement system does not keep.

Turn the cut-outs off. Press **FINISH** and compare a pale patch on the plane with one turning around the skirt. This control changes roughness and metallic response in the engine's material model. It leaves the source alone. Now try **VERTICES** and look along an edge.

```glsl
VERTEX += NORMAL * amplitude *
    sin(UV.y * 18.849556 + UV.x * 6.283185);
```

The shader moves rendered vertices along their normals, by at most 0.04 local units. The wall's subdivisions provide vertices to move. The garment has its own mesh and scale, so its result differs. Collision stays at the old shape; this deformation does not simulate cloth, gravity or a moving hem. Even the shading normals retain the original mesh directions. An edge has changed, but several systems still remember the earlier body.


Use **LOOK** to choose a silhouette for the preview. When you want to carry the current recipe, press **SAVE**, then **WEAR SAVED**. You take on the preview's silhouette as well as its saved fabric. The fabric goes onto your skirt; your bodice, crown and sleeves keep the chosen look's own materials. Walk to the mirror.

This looking glass sees the body you are wearing in the shared scene. Turn slightly. Find the altered source cell again. It belongs to the recipe, but the shape and viewpoint have given it another appearance. What seemed like a surface sample is now part of how you meet yourself.

The chosen look keeps the growth your walk has already given it. As new sequences arrive, the hem can descend and spread without adding another copy of the painted mark. The same number of repeats has more cloth to occupy. The source stays small; its reach changes with the body. Which part of this dress would you call the same?

Use **NEXT** or **PREVIOUS** at the mirror to change your look. The new skirt receives the saved recipe. **WALK DRESS** returns to your walking costume; the recipe waits in the wardrobe until you choose a skirted look again. The permission to travel was quite specific: the program looks for a mesh named `Skirt`. Other parts of the outfit have not been invited into this exchange. There is room for another garment adapter here, and for a question about who gets to define the parts of a body.

Return to the studio and edit a cell. Your worn skirt keeps the saved version. **SAVE** replaces the stored recipe; **WEAR SAVED** chooses to wear it again. **UNDO** can restore the outfit and fabric from before a wear action. It follows the studio's recent actions and does not erase or rewind the saved recipe file.


Press **RUNWAY SAVED**, then join the four performers. Find the same mark moving towards you and away. Their skirts receive the stored recipe; their other materials and their walking route remain their own. **SWAP LOOKS** changes their silhouettes while keeping the fabric. The studio's **UNDO** can restore each performer's previous fabric.

These walkers follow a programmed route. Their steps and poses do not prove that the garment can balance, bend or bear weight. Yet they make another comparison available: a recipe shared across bodies, encountered at different moments. Repetition can make a group legible without making its members look identical.


Colour supplied values. Arrays gave them addresses. Patterns gave us rules for returning to those addresses, and shaders let the receiving surface take part. We can now carry a small source into a room, a garment and a procession. Each carries something of it; each leaves something unresolved.

We have followed one mark as its address, surroundings and carrier changed. In **Change_Intro**, a curve waits for us. Read its height at two places and join them with a line. The line can slope down while the curve beside your first reading rises. How far should we look before saying which way something is changing?

---
