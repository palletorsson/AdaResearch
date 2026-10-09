# A pattern that returns

Choose a patch of colour you would not have thought to put together.

<!-- @seed_replay_demo -->

Two grids stand side by side above the table. Find your patch in one of them, then look in the same place in the other. Press REPLAY and return to those cells before surveying the whole picture.

The patch is back. Press RANDOM, choose something in the new arrangement, and replay that one. A result can surprise us and still know the way back to itself.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. Look at the cube positions too: nothing has moved sideways to make this difference. One value was requested before the colouring began and was given no colour at all.

This is the extra operation, applied to the last grid:

```gdscript
if _extra_on and i == _columns.size() - 1:
	for k in range(extra_draws):
		_rng.randf()
```

The generator has advanced by one draw. The next values still arrive in the same order, but a different one is waiting when the first cube asks for red.

Colour takes three calls:

```gdscript
mat.albedo_color = Color(
	_rng.randf(),
	_rng.randf(),
	_rng.randf()
)
```

Red, green, blue. Then red, green, blue again. Sixty-four cubes use 192 draws. With one value discarded at the start, what would have supplied green now supplies red, blue becomes green, and the next cube's red enters this cube's blue. The old boundaries between colours were made by counting in threes. Shift where that counting begins and the same stream dresses the grid differently.

Press +1 DRAW again. The match returns. REPLAY reconstructs each grid by restoring the generator to its seed and repeating the chosen procedure. We needed more than the seed's number: which generator, which calls, and which use of their results. The picture's name had left out part of its making.

Use RANDOM again and wait before replaying. Try to predict one cell from its neighbour. Then use REPLAY to recover it. Difficulty guessing from the picture and the ability to repeat its construction are different things you can encounter here. Neither observation makes the other disappear.

There is no need to prefer the matched pair. Keep the extra draw on and compare the two colourings as possible companions. Perhaps the misplaced beginning gives you a relation you want. The line that interrupts a demonstration of sameness can also be used to make another palette.

The controls offer many seeds, yet every result still arrives as sixty-four cubes with three colour channels. A wider choice within that arrangement cannot give a cube a fourth channel or let it leave its cell. Those would be other changes to the program. Learning what the slider can vary helps locate the decisions it leaves beyond reach.

<!-- @ -->

The crank across the room makes a generator advance by hand, one state at a time. It gives each request a gesture. We could follow every request here too, but the picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.
