How can an arrangement that sits still make a rhythm?

You have seen slots hold values and a motif repeat across floors and walls. Here the floor is black and white again, but its arrangement moves. Begin by stopping one of its clocks.

<!-- @disco_controls -->

Press PLAY / HOLD at the floor console. Watch the pattern settle. Press ONE STEP: the next arrangement arrives without waiting for the automatic clock. Change PATTERN while holding. CHECKER alternates the tiles, ROWS visits one row at a time, DIAGONALS sends bands across the addresses, and SNAKE follows a route that reverses direction in every other row.

Start playback, then change SPEED. The same rule can hurry or wait. This small expression supplies the checker:

```gdscript
return (x+z+phase)%2
```

Two spatial indices and a changing phase enter the same remainder operation. The tiles have not moved; the values displayed at their addresses have changed. Stand on one tile and watch what arrives there. Then cross the floor and let your movement meet its movement.

The console controls this visual clock. Beside it, the sequencer has another. Begin with one cell and listen for the time it becomes audible.

<!-- @step_sequencer -->

Find the sequencer's grid. Select the empty pattern and turn on one cell. Activating it previews its sound immediately. Let that preview finish, then start playback and predict when the moving playhead will reach the chosen column. Compare the returning note with the highlighted column. Let the loop come round before changing anything else.

Turn that cell off and watch the same column on the next pass. Its address remains visible, but it requests no new note. This is the array room's question in another material: the slot remains available when its value changes. Here you can turn the value back on and repeat the comparison without rebuilding the room.

Turn the first cell back on, then add another active cell in the same track. Listen to the distance between the two events. Move the second event by turning its old cell off and another cell on. The instrument can remain the same while the rhythm changes, because a position in the pattern determines when that instrument is asked to sound.

Each row is a track, each column a step. An active cell requests an event when the playhead reaches it. The visible grid is stored state; playback repeatedly reads that state in a particular order. The pattern can wait without making a sound, and the playhead can move past inactive cells without adding a note.

Change the tempo and listen again. The active cells retain their addresses while the time taken to visit them changes. A pattern's arrangement and its rate of playback are separate choices. Return to the earlier tempo before making your next comparison, so you can hear which change belongs to the pattern itself.

<!-- @standalone_disco -->

Stop the sequencer and predict whether the floor will stop too. Watch before restarting. Its patterns continue while the floor console is set to PLAY; the floor's movement is not all a record of musical events. Conversely, holding the floor's pattern does not stop the sequencer or disable its brief flashes. To inspect a still image, stop both.

Restart with one active cell. The bridge briefly brightens a floor column when that step sounds, adding a response to the continuing animation. The next floor update can obscure the flash, so keep the sequencer's highlighted column as your reference when comparing sound and light.

There are sixteen steps but twelve floor columns. The mapping wraps: the first and thirteenth steps brighten the same column. Try them separately in the second track. A single floor flash cannot distinguish those two addresses, although the sequencer still can. A representation can preserve an event while folding together some of the information about where it came from.

Walk with a pulse, then keep your own rhythm across it. Distinguish the score, the floor's independent animation and your movement. The bridge sends sequencer events to the floor; it does not record your footsteps into the pattern. Sharing a space with a rhythm is different from being measured by it.

<!-- @ -->

Put a beat somewhere that interrupts the repetition you expected. Does it become a mistake, an accent, or the part you wait for? The grid supplies available positions and sounds. It does not decide which of their arrangements you should want.

A gesture falling between steps would need another representation if its timing were to be retained. Imagine what you would add to preserve that chosen difference, then listen to what can already be made within the current grid. Precision and pleasure need not ask the same question.

The colour rooms continue with another arrangement whose parts change how their neighbours are experienced. Carry the distinction between a stored value and the relation through which you encounter it.
