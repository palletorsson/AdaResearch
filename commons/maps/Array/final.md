# The same cube, counted

This is the cube we met at the beginning of Transformation. There, one body acquired movement, orientation and scale. Here it has company: four copies, a metre apart, with a number above each one.

<!-- @row_3_x -->

Look for the row with labels hanging above the cubes. A second line across the hall counts another direction, with its numbers on plates at the cubes’ feet.

Approach the cube marked [2]. It disappears on contact, taking its label with it. In the accompanying table, its value changes from one to zero. The cube marked [3] stays where it was. The row has a gap, and the count has not closed around it.

An array keeps values in an indexed sequence. The index names a slot; the value is what we store there. Slot two still exists. Its value is now zero, which this program uses to record that the cube has gone. The remaining entries keep their numbers.

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

The table has recorded your collection as an absence. It keeps no destination for the cube.

<!-- @grid_2d_4x4 -->

In the square grid, each address stands on a small plate at its cube’s feet. Find [1, 2] and approach. The cube disappears, but its plate remains. Its entry in the table is now zero; the floor still names the empty place.

Two indices distinguish positions along two directions. This grid writes them as [x, z] and stores the value as `grid_data[x][z]`: choose one row of values, then one entry inside it. Face the accompanying table. Its X indices run down the rows and its Z indices across the columns. The plate [1, 2] names the second row and third column, because both counts begin at zero. At [2, 1], the same numbers exchanged take you somewhere else.

The grid adds a way of locating values, rather than a new kind of cube. A zero here means absence under this particular rule. In another array it could mean a measured quantity, a silent beat or a colour. The data structure does not supply that meaning on its own.

<!-- @ -->

Turn back to the row. Its missing cube took its label with it. In the grid, the plate still names the slot. The data preserves both addresses. Whether you can find them again also depends on where we put their names.

An empty place might be reserved for someone, left for a rest, or waiting for something to arrive. Here, the zero cannot distinguish those possibilities. The record keeps the address, but none of those reasons. They would need another value or another record.

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
