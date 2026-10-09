# array_tutorial: the chapters

## Array

*Array*

What remains at an address after its occupant has gone?

This is the cube we met at the beginning of Transformation. There, one body acquired movement, orientation and scale. Here it has company. We have made copies, placed them apart, and given each a number. What can we do with many that we could not do with one?

Keep a position in mind while the thing occupying it disappears. Begin with the row before extending the same question across a grid.


Find the four numbered positions. Choose one cube and read its address before approaching it. Predict which entry in the accompanying table will change when your body collects the cube. Then make contact and compare the table with the space you remember.

The cube disappears. Its entry changes from one to zero, while the other entries keep their values. Point to the former position without relying on the cube to mark it. An empty slot can still have an address.

An array keeps values in an indexed sequence. In this row, the index identifies a slot and the value records whether its cube remains present. The number naming the slot and the number stored there do different jobs. Changing the stored value does not require renumbering every position after it.

The removal event supplies the update. This is a collection by contact; the exercise does not require carrying the cube somewhere else. The table knows that its occupant has left, without keeping a destination for it.


Now choose a cube in the grid. Its address stands on a small plate at its feet. Give its two indices to a companion, or say them to yourself before moving. Predict both the table entry that will change and what will remain readable after collection. Collect the cube, then locate the empty place again.

Two indices distinguish positions along two directions. This grid writes them as [x, z]. In its table, the first index selects a row and the second a column. Exchanging them can name a different slot even though the same two numbers were used. Try choosing an off-diagonal position where that exchange would be visible.

The grid adds a way of locating values, rather than a new kind of cube. A zero here means absence under this particular rule. In another array it could mean a measured quantity, a silent beat or a legitimate category. The data structure does not supply that meaning on its own.


Compare the two empty places. In the row, the cube took its label with it. In the grid, the plate still names the slot. Both tables record absence; the spaces give you different help in locating it. Ask a companion to name an empty slot without pointing, or turn away and find it again yourself. Which arrangement lets the address survive without depending on your memory?

Give an empty slot another meaning: a reserved place, a rest, something waiting to arrive. Does the zero distinguish any of those? The plate preserves where, while the stored value leaves why unresolved. Decide what additional record your chosen meaning would need.

The regular spacing helps you find a slot, but the address and the spacing are different decisions. We could place the same indexed cubes at unequal distances. An array needs a way to distinguish its entries; it does not require them to look alike, stand straight or remain occupied.

Carry forward two separate questions: where is the slot, and what happened to its occupant? In the next hall the copies rise above your head. A third index names a layer. To visit those layers, your body will need a permission that the array itself cannot give.

---

## Tutorial 3D

*Tutorial_3D*

How do you reach an address above your head?

The familiar cubes have risen into a volume. Four across, four upwards, four deep: sixty-four possible encounters. Before entering, follow one vertical line with your eyes. Which part of the address changes as it climbs?


At the console beside the glass enclosure, press Y +. A transparent marker moves up one layer. Press X +, then Z +. Each button changes one index; after three it returns to zero. Read the selected address before looking for its cube. The marker helps you locate the slot, including a slot whose occupant has gone.

Walk through the ground-level opening. Inside this frame you can fly. On desktop, look and use WASD, with Space to rise and Ctrl to descend. In VR, the left stick follows the tilted left controller. Release the controls to hover. The permission belongs to this enclosure; descend to either ground-level doorway to leave it.

Rise beside a column, then move between layers. The cubes are spaced 2.4 metres apart. There is room for a body between neighbouring samples. An indexed volume need not be a solid block.

The placement extends the earlier row's operation along three directions:

```gdscript
cube_instance.position = Vector3(x * spacing, y * spacing, z * spacing)
```

An index becomes a position through this multiplication. Changing the spacing would change the distances you travel without adding an entry. Changing the number of entries would be another operation. The glass frame is another decision again: it supplies the boundary within which this particular body can move vertically.

Choose an address, approach its cube and collect it by contact. Return to the console and select that address. Its value is now zero. The other cubes have not slid into the vacancy. This small record writes collection as an absence:

```gdscript
values[y][z][x] = 0
```

The display names coordinates in x, y, z order; the nested storage selects a y layer, then a z row, then an x entry. Those conventions must be connected explicitly. Neither a list nor a number arrives with a direction built into it.


Hover where a cube used to be. For a moment, your body occupies the neighbourhood of a recorded absence. The table still says zero: it records cubes, not everything that could exist there. What would have to change for it to notice you?

The third index has extended what we can address. Flight has extended what we can reach. Keep those changes separate as you descend. Next, we return to the ground and ask how one small shape can organise a whole surface.

---

## Tutorial Tiling Floor

*Tutorial_Tiling_Floor*

How much floor can one small decision make?

The cubes gave us addresses. Now the addresses receive a motif: a square divided diagonally into black and white. Six fields lie underfoot. Before reading their names, find two that seem related. What has stayed the same between them?


Begin at TRANSLATE. Follow the diagonal through a row. The same square returns at the next address with the same orientation. A single tile has become a field through placement.

At ALTERNATE, neighbouring tiles exchange black and white. At QUARTER TURN, the tile's orientation advances with its address. REFLECT reverses it in alternate columns. SHIFT ROWS displaces every other row by half a tile. Walk between these fields before trying to name the larger shapes you see. A chevron or a band may belong to several tiles together. The unit that you notice need not be the unit stored by the program.

At the entrance console, press TURN MOTIF. The source triangle turns ninety degrees in all six fields. Their arrangement rules remain in place. Compare TRANSLATE with REFLECT again. One changed source can have different consequences under different rules.

This is one of the instructions making those differences:

```gdscript
if rule == 2: rotation += (cx+cy)%4
```

The cell address contributes an orientation. The remainder after division by four gives four returning positions. No tile has to remember the whole field. Its local address and the rule are enough to decide its turn.

Now look at ONE EXCEPTION. Initially it repeats the unexceptional translation field. Press EXCEPTION. One cell turns an extra quarter turn; the other five fields stay as they were. Find the difference from a distance, then approach it. Does it read as a direction, an error, an opening? The code supplies a difference without deciding what it should mean to you.

These are flat images on the floor. Their dark triangles are not holes, and the apparent ridges do not lift your feet. Walk across a boundary while watching it. The picture can divide a space that the collision surface keeps continuous.


Black and white already make figure and ground. We have limited the palette to make the arrangement easier to compare; we have not removed perception from the experiment.

Turn the exception off, then on once more. A common source makes repetition economical. A local exception needs somewhere else to be recorded. This distinction will matter when the pattern reaches a wall, a room and a body. First, let the same six rules stand up.

---

## Tutorial Tiling Walls

*Tutorial_Tiling_Walls*

What changes when a floor stands up?

The same six black and white studies have become walls. Walk along the central aisle. A field that was beneath your feet now faces you; its far edge no longer disappears in quite the same way.


Find TRANSLATE and QUARTER TURN. Approach until one square becomes easy to distinguish, then step back until several squares begin to make another figure. The source has not acquired more detail. Your distance changes which relations are easiest to see.

The six panels use the same image generator as the previous floor. Each is five metres across and five metres high, with a solid backing. TURN MOTIF rotates the source in all six. EXCEPTION changes one cell in the field that carries that name. Repeat one comparison from the previous hall. Which arrangement becomes more insistent when it occupies your forward view?

Behind both versions, the program assigns each pixel one of two values:

```gdscript
image_.set_pixel(x,y,Color.BLACK if black else Color.WHITE)
```

The wall does not introduce another tiling rule. It gives the image another orientation, scale of encounter and physical support. A black triangle on this surface is still a colour value. The backing, with its separate collision, is what stops your body.

Walk beside the reflected field. The diagonals change their apparent angles as you pass. The stored image stays fixed. Perspective is doing some of the work that we might otherwise attribute to the pattern.

At SHIFT ROWS, follow a horizontal joint. The offset asks the next row to begin halfway through the interval you expected. At ONE EXCEPTION, find the isolated turn again. On a whole wall, a single difference can become a landmark. Could you use it to tell someone where to meet you?


We have carried one small motif through several relations, then changed the surface that receives it. The image gives the wall a rhythm; the wall gives that rhythm a place in your walk. Neither account is complete on its own.

The next floor will add a clock. Keep watching the distinction between a value, an address and the act of reading it. Repetition is about to arrive in time as well as space.

---

## Tutorial Disco

*Tutorial_Disco*

How can an arrangement that sits still make a rhythm?

You have seen slots hold values and a motif repeat across floors and walls. Here the floor is black and white again, but its arrangement moves. Begin by stopping one of its clocks.


Press PLAY / HOLD at the floor console. Watch the pattern settle. Press ONE STEP: the next arrangement arrives without waiting for the automatic clock. Change PATTERN while holding. CHECKER alternates the tiles, ROWS visits one row at a time, DIAGONALS sends bands across the addresses, and SNAKE follows a route that reverses direction in every other row.

Start playback, then change SPEED. The same rule can hurry or wait. This small expression supplies the checker:

```gdscript
return (x+z+phase)%2
```

Two spatial indices and a changing phase enter the same remainder operation. The tiles have not moved; the values displayed at their addresses have changed. Stand on one tile and watch what arrives there. Then cross the floor and let your movement meet its movement.

The console controls this visual clock. Beside it, the sequencer has another. Begin with one cell and listen for the time it becomes audible.


Find the sequencer's grid. Select the empty pattern and turn on one cell. Activating it previews its sound immediately. Let that preview finish, then start playback and predict when the moving playhead will reach the chosen column. Compare the returning note with the highlighted column. Let the loop come round before changing anything else.

Turn that cell off and watch the same column on the next pass. Its address remains visible, but it requests no new note. This is the array room's question in another material: the slot remains available when its value changes. Here you can turn the value back on and repeat the comparison without rebuilding the room.

Turn the first cell back on, then add another active cell in the same track. Listen to the distance between the two events. Move the second event by turning its old cell off and another cell on. The instrument can remain the same while the rhythm changes, because a position in the pattern determines when that instrument is asked to sound.

Each row is a track, each column a step. An active cell requests an event when the playhead reaches it. The visible grid is stored state; playback repeatedly reads that state in a particular order. The pattern can wait without making a sound, and the playhead can move past inactive cells without adding a note.

Change the tempo and listen again. The active cells retain their addresses while the time taken to visit them changes. A pattern's arrangement and its rate of playback are separate choices. Return to the earlier tempo before making your next comparison, so you can hear which change belongs to the pattern itself.


Stop the sequencer and predict whether the floor will stop too. Watch before restarting. Its patterns continue while the floor console is set to PLAY; the floor's movement is not all a record of musical events. Conversely, holding the floor's pattern does not stop the sequencer or disable its brief flashes. To inspect a still image, stop both.

Restart with one active cell. The bridge briefly brightens a floor column when that step sounds, adding a response to the continuing animation. The next floor update can obscure the flash, so keep the sequencer's highlighted column as your reference when comparing sound and light.

There are sixteen steps but twelve floor columns. The mapping wraps: the first and thirteenth steps brighten the same column. Try them separately in the second track. A single floor flash cannot distinguish those two addresses, although the sequencer still can. A representation can preserve an event while folding together some of the information about where it came from.

Walk with a pulse, then keep your own rhythm across it. Distinguish the score, the floor's independent animation and your movement. The bridge sends sequencer events to the floor; it does not record your footsteps into the pattern. Sharing a space with a rhythm is different from being measured by it.


Put a beat somewhere that interrupts the repetition you expected. Does it become a mistake, an accent, or the part you wait for? The grid supplies available positions and sounds. It does not decide which of their arrangements you should want.

A gesture falling between steps would need another representation if its timing were to be retained. Imagine what you would add to preserve that chosen difference, then listen to what can already be made within the current grid. Precision and pleasure need not ask the same question.

The colour rooms continue with another arrangement whose parts change how their neighbours are experienced. Carry the distinction between a stored value and the relation through which you encounter it.

---
