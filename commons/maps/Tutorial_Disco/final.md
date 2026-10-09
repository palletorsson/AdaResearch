# A grid with a clock

How can an arrangement that sits still make a rhythm?

In the last two halls, a small change in an instruction could rearrange a field. You could leave it there and look. Here the floor changes while you are still looking. Stand on a square and wait for it to become black, then white, then black again. Nothing has passed beneath your feet.

<!-- @disco_controls -->

At the floor console, press PLAY / HOLD. The checker settles. ONE STEP exchanges its black and white values; a second step brings them back. The whole field changes, although the instruction stays the same:

```gdscript
return (x+z+phase)%2
```

`x` and `z` name a square on this floor. The new input is `phase`, a count that advances with each step. Add one and the remainder changes; add another and it returns. On the tiling desk, we compared instructions at the same addresses. Here we keep an instruction and let another input carry it through time.

Start playback, then change SPEED. The same two arrangements can alternate slowly or quickly. The square you chose keeps its place through both. Cross the floor and let your movement meet the returning pattern.

![The same checker floor before and after one step, seen from a fixed viewpoint.](/book-images/figures/Tutorial_Disco/fixed-addresses-changing-values.png)

*One step apart. Every tile keeps its place; black and white exchange addresses. Another step brings this checker back.*

With the floor held, change PATTERN. ROWS lights one row at a time. DIAGONALS groups the addresses into bands; SNAKE carries a strip along a route that reverses at the end of each row. ONE STEP lets you follow each rule slowly before releasing it to the clock.

After SNAKE comes SUPER TRIANGLE. The diagonal tile from the earlier halls returns. Let it play. Neighbouring triangles turn toward one another; a chevron appears, then a diamond. Later the motif grows across several tiles. Keep your foot in place and follow the shape that now includes it.

Press HOLD during a turn. The floor keeps that unfinished arrangement. ONE STEP takes it to the next pose. The square joints still mark the old addresses, though your eye can join the triangles into another figure. How large is the thing you are following: one tile, four, the floor? The array supplies places to change; it does not tell us where a figure must end.

![Six black and white triangle combinations on the same museum floor.](/book-images/figures/Tutorial_Disco/triangle-combinations.png)

*Six moments in the same movement. The triangles turn and gather into larger figures; the floor beneath the foot stays level.*

The sequencer stands near the entrance, six metres to the right of the console as you enter. Here you can place an event in a returning count. Begin with one cell and listen for the time it becomes audible.

<!-- @step_sequencer -->

Find the sequencer's grid. Each row is a **track**, assigned a sound; each column is a **step**, one place in the repeating count. The moving highlight is the playhead: it reads one column at a time.

The sequencer starts with an empty pattern. Turn on one cell. It sounds immediately as a preview. Let that sound finish, then start playback. Wait for the highlight to reach the cell. The note returns with it, once each time around.

Now give that note company. Add a second cell in the same track. Listen to the interval between them. Move the second event by turning its old cell off and another on. The instrument stays the same; its place in the pattern changes when it sounds.

Switch one cell off again. On the next pass its address is still there, but that visit asks for no new note. The grid keeps your choices; the playhead keeps returning to read them.

Change the tempo without moving either address. The time between visits changes. Stay with the rhythm for a few loops.

<!-- @standalone_disco -->

Leave the floor console on PLAY and stop the sequencer. Let the last sound fade while you watch the floor. The pattern keeps passing beneath you. What seemed to move together has come apart: one clock reads the score; another changes the floor.

Restart the sequencer, then HOLD the floor's pattern. The music continues. Watch for a brief brightening on the otherwise settled floor. A connection in the code sends each sounding step to a floor column. The two clocks are separate, but the sound can still leave a visible response.

Keep the floor held for a few beats. A flash appears against the settled pattern. Release HOLD, and fresh arrangements can overtake it.

There are sixteen steps but twelve floor columns. The bridge uses `step % disco_floor.grid_width`, taking the remainder by this floor’s width: step indices zero and twelve, the first and thirteenth steps, brighten the same column. Try them separately in the second track. The flash returns to the same place underfoot, at another place in the count. The sequencer tells the addresses apart; that flash alone cannot.

Walk with a pulse, then keep your own rhythm across it. Distinguish the score, the floor's independent animation and your movement. Sounding steps can reach the floor, but your footsteps are not written back into the score. Sharing a space with a rhythm is different from being measured by it.

<!-- @ -->

Put a beat somewhere that interrupts the repetition you expected. Does it become a mistake, an accent, or the part you wait for? Keep it for a few loops before deciding. A position that first sounded wrong may become the reason to return.

Let it run while you cross the floor. Your next step need not wait for the next note.

Next, our familiar forms gather in coloured stacks. A stored value can assign a colour to a surface. What happens when that colour meets its neighbours?
