How many places can one small decision change?

The colour rooms separated a chosen value from the rule that relates it to other values. Here a small arrangement supplies a much larger field. Make one decision where you can see exactly where it began.

<!-- @pattern_tile_4x4 -->

Take a coloured cube from the palette and release it over an off-centre cell in the small tile. Watch the repeated preview. Find several places where your mark appears, then locate the one source cell you changed.

Add a second mark beside the first. Predict the repeated pair before looking across the whole field. The size of the result can make the action seem more complicated than it was. Many visible changes have followed one local edit.

The tile stores a finite array of colour choices. To draw the larger field, the repetition rule maps each preview position back to a position in that array. Copies share a source. They do not each contain a separately authored decision.

<!-- @pattern_tile_mirror -->

Make a recognisably asymmetric mark at the mirror station. A mark away from the centre, with a differently coloured neighbour on one side, makes reversal easier to notice than a centred dot would. Follow the pair through the preview and compare the directions in which it faces.

The simple repetition keeps the tile's orientation. The mirror rule reverses selected copies along its directions. The source motif and the transformation applied to its copies do different work: changing either can change the field.

Now try to make the mark appear only once while the rest of the field stays unchanged. Editing the shared source makes it recur. The difficulty is evidence about the way this instrument stores authorship, rather than a failure to choose the right colour.

<!-- @pattern_machine_a -->

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


Take the passage into the runway annex, then follow its side aisle into the curved room. The studio stands inside it. A small source has become something you can stand within. On its smaller surface console, choose WALL and press APPLY LIVE. Edit a cell in the studio. The wall follows it now; the loom's other surfaces continue their own account. Nothing in the wall's geometry had to move for this allegiance to change.

Press HOLD, then edit again. The wall keeps its image. UNDO LINK restores the preceding connection, including whose pattern it followed. LOOM explicitly returns the selected surface to the loom. A surface can share a source, keep a memory of it, or begin following another one. Watch the owner named on the display: the same instruction to change a cell now has different consequences depending on who is listening.

Choose ROOM and press APPLY LIVE. The same decision reaches the curved wall and the floor beneath you. Turn your head, walk towards a mark, then step back. The pattern changes its appearance across your view while the stored cells stay put.

Choose ROOM FLOOR and press HOLD. Change a source cell. The wall follows; the ground keeps its earlier image. The room has separated into two different moments. Its curvature has not changed, and the opening still admits your body. What changed in your sense of the space, even though its supports stayed where they were?

<!-- @ -->

A repeated field can be economical, recognisable and pleasurable. It can also make a wanted exception difficult to express. Choose a reason for keeping one copy different: a direction marker, a mistake you want to retain, or a place that should resist the general pattern.

The held curve has made one kind of separation possible: a whole surface keeps an earlier image. Keeping just one mark different would require a finer distinction, an exception within the repeat. Name what should stay shared and what you would let separate. The instrument's smallest editable unit decides how precisely you can answer.

The next station keeps the motif while changing the larger symmetry rule. Carry an asymmetric mark with you in memory; it will help you see which operation has been applied.
