How much floor can one small decision make?

The cubes gave us addresses and room to move between them. Back on the ground, the addresses receive a motif: a square divided diagonally into black and white. Six fields lie underfoot. Before reading their names, find two that seem related. What has stayed the same between them?

<!-- @tiling_principles -->

Begin at TRANSLATE. Follow the diagonal through a row. The same square returns at the next address with the same orientation. A single tile has become a field through placement.

At ALTERNATE, neighbouring tiles exchange black and white. At QUARTER TURN, the tile's orientation advances with its address. REFLECT reverses it in alternate columns. SHIFT ROWS displaces every other row by half a tile. Walk between these fields before trying to name the larger shapes you see. A chevron or a band may belong to several tiles together. The unit that you notice need not be the unit stored by the program.

At the entrance console, press TURN MOTIF. The source triangle turns ninety degrees in all six fields. Their arrangement rules remain in place. Compare TRANSLATE with REFLECT again. One changed source can have different consequences under different rules.

This is one of the instructions making those differences:

```gdscript
if rule == 2: rotation += (cx+cy)%4
```

Here `cx` and `cy` count columns and rows in the tile image. They name directions across that image, which can lie on a floor or stand on a wall; `cy` does not mean height in the room.

The `%` sign gives the remainder after division. As these non-negative counts increase, `%4` returns 0, 1, 2, 3, then 0 again. You met that return at the flight console: after index three, the selection came back to zero. Here the remainder chooses a quarter-turn. No tile has to remember the whole field. Its local address and the rule are enough to decide its turn. Keep this way of returning in mind when repetition begins to sound.

Now look at ONE EXCEPTION. Initially it repeats the unexceptional translation field. Press EXCEPTION. One cell turns an extra quarter turn; the other five fields stay as they were. Find the difference from a distance, then approach it. Does it read as a direction, an error, an opening? Choose one reading. What would you have to add to make that reading available to someone else?

![Six black and white fields generated from one diagonal tile: translation, alternation, quarter turns, reflection, shifted rows and one exception.](/book-review/doc/book/iterations/2026-09-23-tiling-underfoot/one-motif-six-relations.png)

*The six images used by the floor artifact, shown face-on for comparison. The source orientation is the same in all six; EXCEPTION is switched on in the last field. The little square at the top is their source motif.*

These are flat images on the floor. Their dark triangles are not holes, and the apparent ridges do not lift your feet. Walk across a boundary while watching it. The picture can divide a space that the collision surface keeps continuous. Your eye can find a ridge where your foot finds no step.

<!-- @ -->

Black and white already make figure and ground. We have limited the palette to make the arrangement easier to compare; we have not removed perception from the experiment.

Turn the exception off, then on once more. A common source makes repetition economical. A local exception needs somewhere else to be recorded. This distinction will matter when the pattern reaches a wall, a room and a body. First, let the same six rules stand up.
