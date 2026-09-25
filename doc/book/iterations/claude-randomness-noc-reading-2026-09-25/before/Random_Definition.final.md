# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back. Here, choose a patch of colour you would not have thought to put together.

<!-- @seed_replay_demo -->

Two large grids stand side by side above the controls. Find your patch in one of them, then look in the same place in the other. Press REPLAY and return to those cells before surveying the whole picture.

The patch is still there. REPLAY recoloured every cube from the seed and got the same colours, so nothing on the grid moved. Press RANDOM, choose something in the arrangement it gives you, and replay that one. RANDOM is allowed to choose a seed again, including the one already here. A result can surprise us and still know the way back to itself.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. Look at the cube positions too: nothing has moved sideways to make this difference. One value was requested before the colouring began and was given no colour at all.

Above the grids, two strips show the first twenty-four draws as bar heights. Before the extra draw, their contours match. Switch it on: the right strip begins at draw two. Find its first bar in the second position on the left. The colours changed because the same stream was grouped differently, three numbers per cell. The strips expose a repeatable sequence, not a claim that these few numbers reveal a period or hidden geometric order.

This is the extra operation, applied to the last grid:

```gdscript
if _extra_on and i == _columns.size() - 1:
	for k in range(extra_draws):
		_rng.randf()
```

The underlying sequence has not been rearranged. The generator has moved one position farther into it before the first cube asks for red.

A call to `_rng.randf()` requests one number between zero and one. Colour takes three calls:

```gdscript
mat.albedo_color = Color(
	_rng.randf(),
	_rng.randf(),
	_rng.randf()
)
```

Red, green, blue. Then red, green, blue again. Sixty-four cubes use 192 draws. With one value discarded at the start, what would have supplied green now supplies red, blue becomes green, and the next cube's red enters this cube's blue. Nothing in a draw says that it is red. Red is the use made of its place in these three calls. The old boundaries between colours were made by counting in threes. Shift where that counting begins and the same stream dresses the grid differently.

Press +1 DRAW again to switch the extra draw off. The match returns. This button toggles one discarded draw; repeated presses do not keep adding more. REPLAY reconstructs each grid by restoring the generator to its seed and repeating the chosen procedure. We needed more than the seed's number: which generator, which calls, and which use of their results. The picture's name had left out part of its making.

Use RANDOM again and wait before replaying. The room continues around you; waiting does not advance the generator that colours these grids. Try to predict one cell from its neighbour. Then press REPLAY: it recolours that cell from the seed, and the cell keeps the colour it had. Difficulty guessing from the picture and the ability to repeat its construction are different things you can encounter here. Neither observation makes the other disappear.

There is no need to prefer the matched pair. Keep the extra draw on and compare the two colourings as possible companions. Perhaps the misplaced beginning gives you a relation you want. The line that interrupts a demonstration of sameness can also be used to make another palette.

Move the seed slider slowly. Your hand travels between positions while the readout counts whole numbers, from 0 to 999. The handle moves smoothly, but each seed holds for less than a quarter of a millimetre of its travel, so almost any movement you can feel picks another seed. The controls offer many seeds, yet every result still arrives as sixty-four cubes with three varying colour channels. Another seed cannot add a cube or let one leave its cell. Those would be other changes to the program. Here, randomness varies what the program has made variable.

<!-- @textile_comparison -->

The three textile panels offer another comparison. Each begins with seed 41. Diagonals, upright and horizontal marks, then blocks: three pairs of signs receive the same draws. Choose a cell and follow its colour across the panels. NEXT SEED changes the draws in all three; RESET returns to 41. These bolts are held still so their marks can be compared. Chance has not chosen what a mark means. The program supplied that vocabulary before drawing.

<!-- @random_number_book_page_1955 -->

Near the far end of the room, a page of five-digit numbers takes its look from a book of random digits printed in 1955, a table anyone could open at the same line and read the same digits again. This page keeps the look and not the return. About once a second each column takes a new number at the top and lets its lowest one fall away; the numbers come from the game's shared generator, with no seed set for them in this room, and the page keeps no record of a number once it has gone.

<!-- @prng_crank_machine -->

The crank machine near the entrance, a few steps to one side of the replay console, makes a generator advance by hand: one press of its CRANK button, one state. It gives each request a gesture. We could follow every request here too, but the picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

<!-- @ -->

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.
