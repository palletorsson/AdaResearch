# A rule underfoot

How much floor can one small decision make?

The cubes gave us addresses and room to move between them. Back on the ground, the addresses receive a motif: a square divided diagonally into black and white. Six fields lie underfoot. Before reading their names, find two that seem related. Keep that resemblance in mind as you walk between them.

<!-- @tiling_principles -->

At the entrance, two four-by-four samples sit beside a short instruction. For now, both repeat the same tile. Press APPLY / UNDO. The left sample holds still; on the right, each address receives an extra turn. A figure crosses the joints. No larger tile has been added.

The larger field beside the desk changes with it. An orange outline marks the same sixteen addresses inside a field of 256. The instruction has not grown longer. It is being asked again at more places.

NEXT TILE moves a small outline through the samples. Beside it, the rule works out what happens at that address. At [1, 0], the added turn is one quarter-turn; at [2, 0], it is two. Undo the instruction and those differences disappear together. NEXT RULE offers another small alteration: exchange black and white, reflect a column, shift a row. ONE EXCEPTION lets the change stay at one address. A local edit and a rule repeated everywhere need not have the same reach.

![The four-by-four rule study inside the museum, with unchanged and changed samples beside the instruction.](/book-images/iterations/2026-09-28-tiling-rule-study/floor-rule-after.png)

*The same tile before and after adding an address-dependent quarter-turn. The marked address can be followed through all sixteen places. The larger floor field uses the same calculation.*

Carry one of these changes into the six comparison fields. Begin at TRANSLATE. Follow the diagonal through a row. The same square returns at the next address with the same orientation. A single tile has become a field through placement.

At ALTERNATE, neighbouring tiles exchange black and white. At QUARTER TURN, the tile's orientation advances with its address. REFLECT reverses it in alternate columns. SHIFT ROWS displaces every other row by half a tile. Walk between these fields before trying to name the larger shapes you see. A chevron or a band may belong to several tiles together. The unit that you notice need not be the unit stored by the program.

At the console for the six fields, press TURN MOTIF. The source triangle turns ninety degrees in all six fields. Their arrangement rules remain in place. Return to the two fields you first compared. Does the resemblance survive? One changed source can have different consequences under different rules.

This is one of the instructions making those differences:

```gdscript
if rule == 2: rotation += (cx+cy)%4
```

Here `cx` and `cy` count columns and rows in the tile image. They name directions across that image, which can lie on a floor or stand on a wall; `cy` does not mean height in the room.

The `%` sign gives the remainder after division. As these non-negative counts increase, `%4` returns 0, 1, 2, 3, then 0 again. You met that return at the flight console: after index three, the selection came back to zero. Here the remainder chooses a quarter-turn. No tile has to remember the whole field. Its local address and the rule are enough to decide its turn. Keep this way of returning in mind when repetition begins to sound.

Now look at ONE EXCEPTION. Initially it repeats the translation field. Press EXCEPTION. One cell turns an extra quarter turn; the other five fields stay as they were. From a distance it might look like a direction, an error, an opening. Come closer. The same square is still here, turned once more than its neighbours.

![Six black and white fields generated from one diagonal tile: translation, alternation, quarter turns, reflection, shifted rows and one exception.](/book-images/iterations/2026-09-23-tiling-underfoot/one-motif-six-relations.png)

*The six images used by the floor artifact, shown face-on for comparison. The source orientation is the same in all six; EXCEPTION is switched on in the last field. The little square at the top is their source motif.*

These are flat images on the floor. Their dark triangles are not holes, and the apparent ridges do not lift your feet. Walk across a boundary while watching it. The picture can divide a space that the collision surface keeps continuous. Your eye can find a ridge where your foot finds no step.

<!-- @ -->

Black and white already make figure and ground. We have limited the palette to make the arrangement easier to compare; we have not removed perception from the experiment.

Turn the exception off, then on once more. It returns at the same address. A common source makes repetition economical; here, a separate switch gives one copy an extra turn. The motif has stayed the same. What differs is the instruction attached to that place. First, let the same six rules stand up.
