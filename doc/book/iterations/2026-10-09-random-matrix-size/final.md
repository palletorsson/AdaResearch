# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back. Cage had kept a score so that it could be heard again. Here, a number seems to offer another way back.

<!-- @seed_replay_demo -->

Here, two grids of coloured cubes stand above the controls. Choose a small patch you would not have thought to put together. Find it in the other grid.

Press REPLAY.

The colours stay where they were.

The program has coloured every cube again. The seed sets this generator's starting state; start it there again and make the same requests, and the same values return. Press RANDOM, find something in the arrangement it gives you, and replay that one. RANDOM can choose an earlier seed, including the one already here. A result can surprise us and still know the way back to itself.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. Look at the cube positions too: nothing has moved sideways to make this difference.

Above the grids, two strips turn the first twenty-four draws into bar heights. Switch the extra draw off, then on. The right strip now starts with the second bar on the left. Find the next two matches.

With the extra draw enabled, the right-hand grid requests one value before colouring its first cube, then leaves that value unused.

Each call requests a number between zero and one. A cube takes three: red, green, blue. One unused draw shifts where that grouping begins:

```text
Draws:       a  b  c  d  e  f  g ...
Left grid:  (a, b, c)  (d, e, f)
Right grid: (b, c, d)  (e, f, g)
```

Nothing in a draw says that it is red. Red is the use made of its place in these three calls.

Look back at your patch. Perhaps the misplaced beginning gives you a relation you want. There is no need to prefer the matched pair. The line that interrupts a demonstration of sameness can also be used to make another palette.

Press +1 DRAW again. The match returns. The button toggles one discarded draw; it does not keep adding more. REPLAY repeats whichever procedure is selected. We needed more than the seed's number: which generator, which calls, and which use of their results. The picture's name had left out part of its making.

Choose another seed, then wait. The room continues around you. Press REPLAY. The same patch returns; waiting has not spent another draw from this generator. Difficulty guessing from a picture and the ability to repeat its construction are different things we can encounter here.

Move the seed slider slowly. The handle travels smoothly; the readout chooses whole numbers. A neighbouring seed can give you a very different palette. At eight by eight, each grid still holds sixty-four cubes with three varying colour channels. Another seed cannot add a cube or let one leave its cell.

The MATRIX slider can change the count. Pull it toward sixteen: more, smaller cells fill the same panel. The seed stays, but the row ends later, and the familiar stream falls into another arrangement. Return to eight and the earlier picture returns. The two handles make different decisions available. Chance varies the colours; you can change how many places there are for them.

<!-- @textile_comparison -->

The three textile panels offer another comparison. Each begins with seed 41. Diagonals, upright and horizontal marks, then blocks: three pairs of signs receive the same draws. Follow one cell across the panels, then step back to see the larger figures those marks make. NEXT SEED changes the draws in all three; RESET returns to 41. These bolts are held still so their marks can be compared. Chance has not chosen what a mark means. The program supplied that vocabulary before drawing.

<!-- @random_number_book_page_1955 -->

Near the far end of the room, a page of five-digit numbers takes its look from a book of random digits published in 1955, a table anyone could open at the same line and read the same digits again.[^rand-1955] This page keeps the look and not the return. About once a second each column takes a new number at the top and lets its lowest one fall away. The page draws from the game's shared generator and keeps no record of a number once it has gone.

<!-- @prng_crank_machine -->

On your way back towards the entrance, stop at the crank. One press of its CRANK button, one state. It gives each request a gesture. We could follow every request at the colour grids too, but one picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

<!-- @ -->

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.

[^rand-1955]: *A Million Random Digits with 100,000 Normal Deviates* (RAND Corporation, 1955). RAND's [introduction](https://www.rand.org/pubs/monograph_reports/MR1418.html) describes a basic table generated by an electronic roulette wheel in 1947, tested and transformed before publication. Choosing a starting place in a fixed table can help us imagine a repeatable beginning. The table retrieves stored digits; a seeded generator calculates its sequence. Repeatability in this room depends on the generator and procedure being kept with the seed.
