# A maze made of marks

When do independent marks begin to look like a maze?

Two fields of diagonals ten metres high flank the hall, never still, and a third closes its far end. They are easier to read at the end. Below them, past the solid block beside the door, a cluster of slabs taller than you stands to your left, every one of them set on a diagonal. Leave it for now too. It will make more sense once you have seen where it comes from.

<!-- @ten_print -->

At the far end of the hall a screen is printing diagonals, one after another, left to right and row under row. The one-line program it is staging is written on the console beside it:

```basic
10 PRINT CHR$(205.5+RND(1)); : GOTO 10
```

One line of Commodore 64 BASIC, famous enough to have a book named after it.[^10print] Read it from the middle outward. `RND(1)` gives a number from zero up to, but not including, one. Added to 205.5, it lands somewhere between 205.5 and 206.5. `CHR$` keeps only the whole part, so what gets printed is character 205 or character 206: one diagonal or the other. `GOTO 10` goes back and does it again, for as long as the machine runs.

On the Commodore, each diagonal is equally likely, because 205.5 sits exactly halfway between them. The famous constant is where the coin balances.

Before you press anything, look at the screen as a whole. Some bands of rows are heavy with one diagonal and some with the other, and the border between them climbs as the screen scrolls. The coin in this room is not even. It was set up to breathe: across every 540 characters its odds swing from four to one in favour of one diagonal, through even, to four to one for the other, and the screen holds about three-quarters of that cycle at once. The line on the console still reads 205.5. Only the words "bias breathing" in the small print under it admit that the coin is moving. What reads as the texture of chance is partly a sine wave that someone chose.

The last room's draw was even among the cubes a rule had admitted. Here two diagonals were admitted to the line, and how often each comes up was a second decision, made where you could not see it.

Now press **BIAS +** and watch the line. 205.5 becomes 205.4, then 205.3. From the first press the breathing stops, the coin is a fixed number, and the number on the console is true. Nothing restarts: the next characters are drawn against the new number, and the field begins to lean while you watch. At 205.1 about nine characters in ten fall the same way. Keep pressing and the constant reaches 205, where every character is the same diagonal. The maze has become stripes. Nothing is left to choose. Nothing on the panel brings the breathing back, but **BIAS −** returns the line to 205.5. Do that before you go on.

Now find one of the smallest characters in the program. Press **SEMICOLON** and it leaves the line on the console, and the maze goes with it. The screen clears and prints again, and every diagonal now starts a row of its own: a single column down the left edge. A trailing semicolon tells `PRINT` to stay on the same line. Without it, each character is followed by a line break.

The draws are not new ones. SEMICOLON starts the same seeded stream again from its first character, as RESET did on the last room's board, and weighs each draw against the constant the line now shows. Between this column and the plane that comes back, only the line break changes.

What changed is how many directions a mark has neighbours in. Down the column a mark still meets the one above or below it at a corner, often enough to zigzag. But a strip one cell wide can never close around anything. The smallest enclosure this rule can draw takes four marks in a two-by-two block, a diamond. Neighbouring marks meet because the grid puts their ends in shared places; the semicolon decides whether the grid has a second direction to share them in.

So the look of a maze needs two things, and this one line keeps them in two different places: a choice that is actually open, and a grid with room for one choice to meet the next in both directions. Take away the first and you get stripes. Take away the second and you get a column: zigzags, but no room. Press **SEMICOLON** again and the plane comes back.

Once it has, look closely. On this screen the characters are drawn as thin bars, corner to corner of their cells, red leaning one way and blue the other. Each bar grows and shrinks a little in a slow wave that runs through the field. Where two bars meet at a corner they touch and part again about every two seconds. Nothing in the line asks for that. The meeting the maze depends on is being given and taken away by the display.

<!-- @ -->

<!-- @composition_stochastique -->

Beside the printer stand four square grids of the same two diagonals. In each, one diagonal fills the grid and the other turns up in exactly one, five, thirty or fifty of its hundred cells. The plate names François and Vera Molnar, 1959.

Step along them and decide where a grid stops reading as parallel lines. The board has no grid between five and thirty, so the threshold you find is your own. Press **RESEED** on the board: the hundred cells are shuffled and dealt again, the pattern changes, and every count holds. The four grids are cut from one deal, so the single turned cell in the first is turned in the other three as well.

These grids are dealt, not flipped. As on the last room's board, what chance may touch was settled before it ran: here, how many cells turn. Chance chooses only which. The printer's coin decides both. At a BIAS of 0.3, the arithmetic says a hundred characters come out exactly thirty and seventy only about one time in twelve. A probability and a count are different instruments, and from here you can see both at once.

<!-- @ -->

<!-- @ten_print_structure -->

Look down. You have been standing on the screen since you reached the console. The ridged band across the width of the hall is its bottom seven rows, each cell enlarged to half a metre and laid face up: the screen's top toward the far wall, its left on your left, the row it is printing now along the edge nearest the door. Every character printed into those rows comes down here as a low ridge in the same cell, leaning the same way. Seen from the near edge, the floor draws the same glyph the screen draws in that cell.

A bright tile marks the cell where the next character will land. It runs along the near row several cells a second, and for about ten seconds in every half-minute it crosses the row in a blur. Each time it finishes a row the screen scrolls, every ridge steps half a metre toward the far wall, and the oldest row drops off the far edge. The floor keeps only the newest seven rows. To hold the tile still, press **RUN** at the console. The printing stops with the tile waiting where the next character will land, and each press of **STEP** lays one ridge and moves it on one cell.

You may already have seen the floor change. When you pressed SEMICOLON, the ridges round your feet vanished too. Take the semicolon away again and look to your left: what is left is a single file of seven ridges at the far end of the band, about nine metres away. It is the same experiment as on the screen, laid across the room.

The ridges will not stop you. They are a quarter of a metre high, and nothing in them resists a body; you step over and among them and read them standing. The last room asked when a contour becomes a passage. Not here: the floor gives you a contour to stand in, not walls to be kept out by.

Now go back to the slabs you passed on the way in.

They are the same structure again, stood up to the height of a body: slabs two metres forty high, and solid. Where two run parallel, the channel between them is about seventy centimetres wide. The pattern is the first twelve characters the printer drew when the hall was built, before anyone touched BIAS or RESEED: the same seed and the same breathing coin, laid out four to a row. The slabs do not follow the console. They are a still, cut from the start of the stream.

Walk in. The line you could trace on the screen is, here, the face of a wall, and the route is the gap beside it. Where neighbouring slabs are parallel, a channel runs straight on along the diagonal; where two meet, it turns. Twelve coin flips, laid four to a row, have divided this ground into eight regions. Seven open onto the outside. One is closed on every side: a small room made by the rule, that nobody can ever stand in.

Look at what closes it: four slabs, each touching the next at a corner, all the way round. The drawn segments are joined, and that is exactly what cuts the passage off. A connection between drawn segments and a connection between passages are different observations, and here they point opposite ways.

Notice, too, what this maze does not have. There are no forks. Every triangle of floor between the slabs opens on two sides only, so each of the seven open regions is a single corridor with two mouths, and once you are in one there is nothing to decide. Most of them are shallow. Four are bays: two slabs meet in a V about a metre in, and you come out beside where you went in. Two are not bays at all, only corners of the block cut off by a single slab. The branching you saw on the screen belonged to the lines. The passages between them never branch.

The seventh is a way through, from the side that faces the printed floor to the side that faces the way you came in. It exists because these twelve characters, wrapped four to a row, happened to leave one. On the screen, twenty to a row, the same twelve were printed along a single line, and left it at the first scroll. Wrapped three to a row they would leave no way through and no closed room. It also exists because of where the block stops: one row deeper, and the next four characters would have closed it. The rule did not choose where to stop. Whoever placed the block did.

Each cell was decided alone. Whether you can cross was decided by all twelve together, and you find out with your body. On the last room's board the same draws landed on different cubes when the rule changed. Here the same draws, laid out differently, make different ground.

<!-- @ -->

<!-- @ten_print_maze_3d -->

Now the three large fields. They stand upright on three sides of the hall, each ten metres on a side and taller than the wall behind it, the far one meeting the other two at right angles in both far corners. They are only lines. Nothing in them stops a body, and beside the printer your head can pass through the lowest row of one. You can look up at them and walk through them, but you cannot travel along them.

On each, a red ball stands for an ant. The ant can go in, but not by your rules. It is a separate procedure with a map of its own, on which two parallel diagonals touch, so even the kind of channel you just walked between parallel slabs is shut to it. On that map the ant is held in the few cells around a single corner. It moves on only when the cell it stands in turns, and then one corner at a time. Your walls held still long enough to be learned. Each of these fields turns about twelve cells a second, and every turn wipes the ant's memory of where it has been.

Watch a diagonal change near it. One local replacement can alter a much longer-looking contour, joining two lines or cutting one in two a metre away.

<!-- @ -->

You have now had both readings from one coin: the floor gave you a textile to stand in, the slabs a passage system that could refuse you. Neither reading changes the original two-choice rule, but they ask different things of its result. The useful question is which relationships are supplied by the rule and which promises your interpretation adds.

The floor never kept more than the newest seven rows: each full row pushed the oldest off its far edge, and SEMICOLON wiped it and began again. In the next room the record works the other way round. The die's record forgets where and in what order each throw landed, and keeps how often each face came up. That coin has six faces, and nobody has printed its odds where you can change them. You will compare single results with a growing record, asking what repeated observations can establish that one throw cannot.

[^10print]: Nick Montfort, Patsy Baudoin, John Bell, Ian Bogost, Jeremy Douglass, Mark C. Marino, Michael Mateas, Casey Reas, Mark Sample and Noah Vawter, *10 PRINT CHR$(205.5+RND(1)); : GOTO 10* (MIT Press, 2012). The whole book is freely available at [10print.org](https://10print.org/) under a Creative Commons BY-NC-SA 3.0 licence. Its chapters are numbered like program lines — 10, 20, 30 — with remarks between them, and its long argument concerns the interplay of randomness and regularity that this room lets you pull apart.
