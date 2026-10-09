How can an arrangement that sits still make a rhythm?

You have seen slots hold values and a motif repeat across floors and walls. Here the floor is black and white again. Stand still and let the pattern move beneath you. Then stop one of its clocks.

<!-- @disco_controls -->

Press PLAY / HOLD at the floor console. Watch the pattern settle. Press ONE STEP: the next arrangement arrives without waiting for the automatic clock. Change PATTERN while holding. CHECKER alternates the tiles, ROWS visits one row at a time, DIAGONALS sends bands across the addresses, and SNAKE follows a route that reverses direction in every other row.

Start playback, then change SPEED. The same rule can hurry or wait. This small expression supplies the checker:

```gdscript
return (x+z+phase)%2
```

Two spatial indices and a changing phase enter the same remainder operation. The tiles have not moved; the values displayed at their addresses have changed. Stand on one tile and watch what arrives there. Then cross the floor and let your movement meet its movement.

![The same checker floor before and after one step, seen from a fixed viewpoint.](/book-review/doc/book/iterations/2026-09-23-disco-separate-clocks/fixed-addresses-changing-values.png)

*One step apart. Every tile keeps its place; black and white exchange addresses. Another step brings this checker back.*

Change PATTERN once more, past SNAKE, to SUPER TRIANGLE. A diagonal divides each square into black and white. Let it play. Neighbouring triangles turn toward one another; a chevron appears, then a diamond. Later the motif grows across several tiles. Keep your foot in place and follow the shape that now includes it.

Press HOLD during a turn. The floor keeps that unfinished arrangement. ONE STEP takes it to the next pose. The square joints still mark the old addresses, though your eye can join the triangles into another figure. How large is the thing you are following: one tile, four, the floor? The array supplies places to change; it does not tell us where a figure must end.

![Six black and white triangle combinations on the same museum floor.](/book-review/doc/book/iterations/2026-09-23-disco-super-triangle/triangle-combinations.png)

*Six moments in the same movement. The triangles turn and gather into larger figures; the floor beneath the foot stays level.*

The console controls this visual clock. Beside it, the sequencer has another. Begin with one cell and listen for the time it becomes audible.

<!-- @step_sequencer -->

Find the sequencer's grid. Each row is a **track**, assigned a sound; each column is a **step**, one place in the repeating count. The moving highlight is the playhead: it reads one column at a time. Select the empty pattern and turn on one cell. Activating it previews its sound immediately. Let that preview finish, then start playback and predict when the moving playhead will reach the chosen column. Compare the returning note with the highlighted column. Let the loop come round before changing anything else.

Turn that cell off and watch the same column on the next pass. Its address remains visible, but it requests no new note. This is the array room's question in another material: the slot remains available when its value changes. Here you can turn the value back on and repeat the comparison without rebuilding the room.

Turn the first cell back on, then add another active cell in the same track. Listen to the distance between the two events. Move the second event by turning its old cell off and another cell on. The instrument can remain the same while the rhythm changes, because a position in the pattern determines when that instrument is asked to sound.

The visible grid is stored state; playback repeatedly reads that state in a particular order. The pattern can wait without making a sound, and the playhead can move past inactive cells without adding a note.

Change the tempo and listen again. The active cells retain their addresses while the time taken to visit them changes. The same pattern can feel different before a single cell has changed.

<!-- @standalone_disco -->

Leave the floor console on PLAY and stop the sequencer. Let the last sound fade while you watch the floor. The pattern keeps passing beneath you. What seemed to move together has come apart: one clock reads the score; another changes the floor.

Restart the sequencer, then HOLD the floor's pattern. The music continues. Watch for a brief brightening on the otherwise settled floor. A connection in the code sends each sounding step to a floor column. The two clocks are separate, but the sound can still leave a visible response.

Return to one active cell and let both clocks run. Follow its highlighted column on the sequencer, then look for its flash underfoot. A fresh floor arrangement can overtake that response. Holding the floor gives you longer to distinguish the flash from the pattern carrying it.

There are sixteen steps but twelve floor columns. The remainder returns here as `step % 12`: step indices zero and twelve, the first and thirteenth steps, brighten the same column. Try them separately in the second track. A single floor flash cannot distinguish those two addresses, although the sequencer still can. A representation can preserve an event while folding together some of the information about where it came from.

Walk with a pulse, then keep your own rhythm across it. Distinguish the score, the floor's independent animation and your movement. Sounding steps can reach the floor, but your footsteps are not written back into the score. Sharing a space with a rhythm is different from being measured by it.

<!-- @ -->

Put a beat somewhere that interrupts the repetition you expected. Does it become a mistake, an accent, or the part you wait for? Keep it for a few loops before deciding. A position that first sounded wrong may become the reason to return.

A gesture falling between steps would need another representation if its timing were to be retained. Imagine what you would add to preserve that chosen difference, then listen to what can already be made within the current grid. Precision and pleasure need not ask the same question.

Next, our familiar forms gather in coloured stacks. A stored value can assign a colour to a surface. What happens when that colour meets its neighbours?
