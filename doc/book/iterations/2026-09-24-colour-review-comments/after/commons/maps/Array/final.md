What remains at an address after its occupant has gone?

This is the cube we met at the beginning of Transformation. There, one body acquired movement, orientation and scale. Here it has company. We have made copies, placed them apart, and given each a number. What can we do with many that we could not do with one?

Keep a position in mind while the thing occupying it disappears. Begin with the row before extending the same question across a grid.

<!-- @row_3_x -->

Find the row of four cubes with labels above them. A second line across the hall counts another direction, with its numbers on plates at the cubes’ feet. Begin with the row whose labels hang above. Choose one cube and read its address before approaching it. Predict which entry in the accompanying table will change when your body collects the cube. Then make contact and compare the table with the space you remember.

The cube disappears. Its entry changes from one to zero, while the other entries keep their values. Point to the former position without relying on the cube to mark it. An empty slot can still have an address.

An array keeps values in an indexed sequence. In this row, the index identifies a slot and the value records whether its cube remains present. The number naming the slot and the number stored there do different jobs. Changing the stored value does not require renumbering every position after it.

The row begins in a loop. These lines from its builder create and place the copies; the surrounding code gives them labels and connects their collection:

```gdscript
array_data = [[1, 1, 1, 1]]
for i in range(4):
    var cube_instance = pickup_cube_scene.instantiate()
    cube_instance.position = Vector3(i * 1.0, 0, 0)
    add_child(cube_instance)
```

`range(4)` supplies 0, 1, 2, 3. The indented instructions run once for each number, with `i` changing each time. Four cubes, but the last address is three. Multiplying `i` by one metre gives each copy its place along X. The same instruction makes the many by changing what it receives.

Look at the double brackets. The inner list holds four values; the outer list holds that one row. This is already an array inside an array. `array_data[0][i]` selects row zero, then entry `i` within it. In a moment, the grid will give us more rows to choose from.

The removal event supplies the update. This is a collection by contact; the exercise does not require carrying the cube somewhere else. The table knows that its occupant has left, without keeping a destination for it.

<!-- @grid_2d_4x4 -->

Now choose a cube in the grid. Its address stands on a small plate at its feet. Give its two indices to a companion, or say them to yourself before moving. Predict both the table entry that will change and what will remain readable after collection. Collect the cube, then locate the empty place again.

Two indices distinguish positions along two directions. This grid writes them as [x, z] and stores the value as `grid_data[x][z]`: choose one row of values, then one entry inside it. Face the accompanying table. Its X indices run down the rows and its Z indices across the columns. The plate [1, 2] names the second row and third column, because both counts begin at zero. Find [2, 1] on the floor and in the table. The same numbers, exchanged, take you somewhere else.

The grid adds a way of locating values, rather than a new kind of cube. A zero here means absence under this particular rule. In another array it could mean a measured quantity, a silent beat or a legitimate category. The data structure does not supply that meaning on its own.

<!-- @ -->

Compare the two empty places. In the row, the cube took its label with it. In the grid, the plate still names the slot. Both tables record absence; the spaces give you different help in locating it. Ask a companion to name an empty slot without pointing, or turn away and find it again yourself. Which arrangement lets the address survive without depending on your memory?

Give an empty slot another meaning: a reserved place, a rest, something waiting to arrive. Does the zero distinguish any of those? The plate preserves where, while the stored value leaves why unresolved. Decide what additional record your chosen meaning would need.

The regular spacing helps you find a slot, but the address and the spacing are different decisions. We could place the same indexed cubes at unequal distances. An array needs a way to distinguish its entries; it does not require them to look alike, stand straight or remain occupied.

<!-- @array_floor_writer -->

A light-blue sphere moves low over the floor. Wait near it and watch the cells beneath it. A copy can rise into your route; a consumed cell leaves a hollow. There is still a surface a metre below. What looked like an address on a diagram has become a place where your body can drop.

The sphere is writing into the hall’s own grid. Its label names the last cell it copied or consumed. The small pickup tables keep their separate records: collecting their cubes and changing this floor are different acts. Here the program changes both what you see and what supports you.

Near the entrance, PAUSE / RESUME holds the floor where it is. Pause after a change and walk around it. The gaps and raised cells remain, while the perimeter, thresholds and the transparent study’s floor pad stay outside the sphere’s reach. RESTORE FLOOR returns the changed cells to their starting arrangement, waiting wherever a body occupies one. The sphere stays paused until you release it again.

An empty slot was something we could point to. Underfoot, absence asks something of our balance. The address remains available to the program even when it no longer offers our feet a place to rest.

![The hall’s floor after cells have been copied and consumed.](/book-review/doc/book/figures/Array/museum-floor-changed.png)

![The same floor after restoration, seen from the same position.](/book-review/doc/book/figures/Array/museum-floor-restored.png)

*The same part of the working museum, seen from standing height before and after RESTORE FLOOR. These views hold a supplied set of copy and consume operations for comparison.*

<!-- @molnar_cube_study -->

We have repeated the cube, but we do not have to repeat its fate. At each address, another decision becomes possible.

The transparent study takes its starting point from Vera Molnár’s *(Des)Ordres*: concentric squares disturbed within a repeated arrangement.[^molnar] Here the squares have become nested cubes. The frames arrive already displaced. Press DEPTH until it reads 1 / 4, then RESET. Face it squarely, then move to one side. The drawing has depth. Lines that seemed to meet separate as you walk.

Turn a little. Translate a little. Change the scale. These are the operations we brought from Transformation, now applied throughout an array. Each nested cube has its own assigned departures; the three controls let you increase or reduce them. Returning a control to the same setting brings back the same arrangement. You can compare a change without losing it to another roll of the dice.

Watch one of the small grey points. Its surrounding frames can drift away, but the point stays at the indexed site. The address gives us somewhere to return and something to disagree with. How far can the frames depart before you lose the place you were following?

![One layer of ordered nested cubes, the same sites with translation, rotation and scale, then all four layers seen at an angle.](/book-review/doc/book/iterations/2026-09-23-array-molnar-volume/array-departures.png)

*The same working Godot artifact supplies these three views. Sixteen visible sites become sixty-four when all four layers are shown; each holds four nested cubes. An Ada Research spatial interpretation after Molnár.*

Add the other layers. Through the transparent faces, nearby edges cross distant ones. A small displacement that was easy to follow alone can disappear among the others. More copies give us more places for difference, and more work to distinguish them. Their transparency lets us see through the structure without promising that we can read it.

The rule has admitted variation, but it has also set its limits: how far to move, how much to turn, which sizes remain possible. We can open those ranges in the program. Each additional site will still ask for storage, and the machine must draw what we ask it to show. The invitation to continue has a material cost.

<!-- @ -->

Carry forward two separate questions: where is the slot, and what can happen at it? We have looked through layers. In the next hall the copies rise above your head, and you can enter their arrangement. To visit those layers, your body will need a permission that the array itself cannot give.

[^molnar]: Vera Molnár, *(Des)Ordres*, 1974. The [Digital Art Museum](https://dam.org/museum/artists_ui/artists/molnar-vera/des-ordres/) describes the disruption of concentric squares within a repeated structure. The cubes, depth and controls here are our interpretation, not a reconstruction of her drawing or algorithm.
