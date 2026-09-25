# A grid with a clock

How can an arrangement that sits still make a rhythm?

You have seen slots hold values and a motif repeat across floors and walls. Here the floor is black and white again. Stand still and let the pattern move beneath you. Then stop one of its clocks.

<!-- @disco_controls -->

Press PLAY / HOLD at the floor console. Watch the pattern settle. Press ONE STEP: the next arrangement arrives without waiting for the automatic clock. Change PATTERN while holding. CHECKER alternates the tiles, ROWS visits one row at a time, DIAGONALS sends bands across the addresses, and SNAKE follows a route that reverses direction in every other row.

Start playback, then change SPEED. The same rule can hurry or wait. This small expression supplies the checker:

```gdscript
return (x+z+phase)%2
```

Two spatial indices and a changing phase enter the same remainder operation. The tiles have not moved; the values displayed at their addresses have changed. Stand on one tile and watch what arrives there. Then cross the floor and let your movement meet its movement.

![The same checker floor before and after one step, seen from a fixed viewpoint.](/book-review/doc/book/figures/Tutorial_Disco/fixed-addresses-changing-values.png)

*One step apart. Every tile keeps its place; black and white exchange addresses. Another step brings this checker back.*

Change PATTERN once more, past SNAKE, to SUPER TRIANGLE. A diagonal divides each square into black and white. Let it play. Neighbouring triangles turn toward one another; a chevron appears, then a diamond. Later the motif grows across several tiles. Keep your foot in place and follow the shape that now includes it.

Press HOLD during a turn. The floor keeps that unfinished arrangement. ONE STEP takes it to the next pose. The square joints still mark the old addresses, though your eye can join the triangles into another figure. How large is the thing you are following: one tile, four, the floor? The array supplies places to change; it does not tell us where a figure must end.

![Six black and white triangle combinations on the same museum floor.](/book-review/doc/book/figures/Tutorial_Disco/triangle-combinations.png)

*Six moments in the same movement. The triangles turn and gather into larger figures; the floor beneath the foot stays level.*

The console controls this visual clock. The sequencer stands near the entrance, six metres to the right of the console as you enter. It has another clock. Begin with one cell and listen for the time it becomes audible.

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
