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

Link the wall again, then press UNDO LINK. Its earlier held image returns. Select ALL THREE to see whether they are live, held, or mixed. That name includes exactly these three surfaces. The carpet and the other machines continue their own work. Selecting a receiver changes who can follow; MARK, SAVE and RESTORE still act on the shared source.

<!-- @ -->

A repeated field can be economical, recognisable and pleasurable. It can also make a wanted exception difficult to express. Choose a reason for keeping one copy different: a direction marker, a mistake you want to retain, or a place that should resist the general pattern.

The held curve has made one kind of separation possible: a whole surface keeps an earlier image. Keeping just one mark different would require a finer distinction, an exception within the repeat. Name what should stay shared and what you would let separate. The instrument's smallest editable unit decides how precisely you can answer.

The next station keeps the motif while changing the larger symmetry rule. Carry an asymmetric mark with you in memory; it will help you see which operation has been applied.
