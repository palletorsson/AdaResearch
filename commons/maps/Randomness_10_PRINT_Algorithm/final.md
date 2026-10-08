# A maze made of marks

When do independent marks begin to look like a maze?

Diagonals rise above the walls on three sides of the hall. Below them, a cluster of solid slabs leaves narrow openings between its edges. The same two marks recur on a screen at the far end. Something that fits inside one character has acquired room for a body.

<!-- @ten_print -->

The screen prints left to right, row under row. Beside it, the console carries one line of Commodore 64 BASIC:

```basic
10 PRINT CHR$(205.5+RND(1)); : GOTO 10
```

One line, famous enough to have a book named after it.[^10print] Read it from the middle outward. `RND(1)` gives a number from zero up to, but not including, one. Added to 205.5, it lands between 205.5 and 206.5. `CHR$` keeps the whole part: character 205 or 206, one diagonal or the other. `GOTO 10` returns to the beginning.

The constant 205.5 puts the two choices in balance. Each new mark can lean either way. Nothing in that choice asks whether a passage is needed beside it.

Yet the field on this screen seems to breathe. Bands favour one diagonal, then the other. The small print admits why: “bias breathing.” A sine wave changes the odds while the line above still displays 205.5. What looks like a texture of chance also carries a rhythm someone chose. The familiar line does not account for everything this installation does.

Press **BIAS +**. The breathing stops and the constant begins to change: 205.4, then 205.3. The next marks increasingly favour one direction. At 205, every mark is the same diagonal. The maze has become stripes. Use **BIAS −** to bring the constant back to 205.5; the odds are now fixed and even.

There is another small decision in the line. Press **SEMICOLON** and the trailing `;` disappears. Every mark now begins a row of its own. The field becomes a single column.

The semicolon tells `PRINT` to stay on the same line. Without it, each character is followed by a line break. This control starts the seeded stream again, so the column and the plane can receive the same choices. What differs is where a choice goes.

Down the column, marks can still meet at corners and zigzag. They cannot close around a room. Four marks in a two-by-two block can: their diagonals make a diamond. The grid gives neighbouring marks shared endpoints; the line break decides whether they have neighbours in a second direction.

Press **SEMICOLON** again. The plane returns. One tiny character has given the other characters another way to meet.

Even those meetings have been interpreted. The red and blue bars slowly lengthen and shorten, touching at a corner and parting again. Nothing in the BASIC line asks them to do that. A display can loosen a connection the grid appeared to guarantee.

<!-- @ -->

<!-- @composition_stochastique -->

Beside the printer, four square grids offer another use of the same diagonals. One direction fills each grid; the other occupies exactly one, five, thirty or fifty of its hundred cells. The plate names François and Vera Molnar, 1959.

Step along them. Where does a field of parallel lines become something else? There is no example between five and thirty. Your eye has to cross that interval.

**RESEED** changes the arrangement while keeping every count. The four grids come from one shuffled deal: the single turned cell in the first is turned in the other three too. Chance decides which cells turn. Their number was settled beforehand.

The printer leaves that number open. Giving a diagonal a thirty-percent chance does not reserve exactly thirty of a hundred cells for it. A probability and a count are different instruments. Here they stand close enough to compare.

<!-- @ -->

<!-- @ten_print_structure -->

Look down. The newest seven rows of the screen are also under your feet. Each cell is enlarged to half a metre, each diagonal laid down as a low ridge. A bright tile waits where the next mark will land. When a row fills, the ridges shift towards the far wall and the oldest row leaves the floor.

**RUN** holds the printing; **STEP** adds one mark. The pause gives your eye time to follow a character from the screen to its place on the ground. Taking away the semicolon collapses this floor into a single file too. A change in the line reaches the room.

These ridges offer no resistance. You can stand among them and pass through their edges. They give the eye a contour without giving the body a boundary.

Now return to the taller slabs near the entrance.

They retain the first twelve characters printed when the hall was built, before any adjustment of the odds. Here the characters are wrapped four to a row and stood two metres forty high. The console leaves this arrangement alone. Where two slabs run parallel, the gap is about seventy centimetres wide.

Walk in. The mark you followed on the screen has become the face of a wall. Your route occupies the space beside it.

Four slabs meet corner to corner around a small room with no entrance. Joining the marks has closed the passage. The same connection that completes a figure can keep a body outside it.

Elsewhere the gaps lead back out. Some are shallow bays; one passage crosses the block. None forks. Between these diagonals, each small triangle of floor opens on two sides, so a corridor may turn but offers no branching choice. What looked like a maze from above becomes a different proposition at the width of your shoulders.

The way through also depends on the crop. These twelve characters leave it when wrapped four to a row. Wrapped three to a row, they would leave neither a crossing nor a closed room. One more row of this stream would close the crossing too. The rule did not choose where the block ends. Whoever placed it did.

Each cell was decided alone. Whether you can cross depends on their arrangement together. A body meets a consequence that no single draw contains.

<!-- @ -->

<!-- @ten_print_maze_3d -->

Look up again at the three fields towering above the hall. Their lines can be crossed by your body, but they provide no surface to carry you upwards. Height in the image has not become a climb.

A red ball stands for an ant in each field. It receives a different map: even parallel diagonals are treated as touching, so a channel you could walk between the slabs is closed to it. The ant stays around a corner until a cell turns and another move becomes possible. Every turn clears its record of where it has been.

Watch a diagonal change near it. One replacement can join a long contour or break it apart. The slabs held still long enough for you to learn a passage. Here the ground of the ant's small knowledge keeps changing.

<!-- @ -->

Two marks have supplied a printed field, a floor to stand among, walls that admit or refuse a body, and a changing world for an ant. The marks alone cannot tell us which world we have made. Their arrangement, their material and the body given to them all matter.

The printed floor lets its oldest row go. In the next room a die's record gathers outcomes instead, keeping how often each face appears while forgetting where it landed. After a passage made from independent choices, we meet a throw made by a hand.

[^10print]: Nick Montfort, Patsy Baudoin, John Bell, Ian Bogost, Jeremy Douglass, Mark C. Marino, Michael Mateas, Casey Reas, Mark Sample and Noah Vawter, *10 PRINT CHR$(205.5+RND(1)); : GOTO 10* (MIT Press, 2012). The whole book is freely available at [10print.org](https://10print.org/) under a Creative Commons BY-NC-SA 3.0 licence. Its chapters are numbered like program lines — 10, 20, 30 — with remarks between them, and its long argument concerns the interplay of randomness and regularity that this room lets you pull apart.
