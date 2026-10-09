# A pattern that returns

Can a surprise return exactly?

<!-- @seed_replay_demo -->

Two grids of coloured cubes stand side by side on the panel, sixty-four cells each. Before you touch anything, find a patch you could not have predicted: a bright corner, or two neighbours whose colours seem to have nothing to do with each other. Now decide whether that patch could ever come back.

Press REPLAY. Look at the same patch, in both grids, before you look anywhere else.

The two grids match, cell for cell, and they matched before you pressed anything. Press RANDOM and both change together into a new arrangement that is just as hard to predict; press REPLAY and that one comes back too. The slider chooses the seed by hand. Nearby seeds do not give nearby pictures.

Under the headline the panel says what a grid costs: 192 draws, three per cell, row by row. That sentence is the whole procedure. A generator is put into the state the seed names, and then asked for a number, and another, and another, and each three become one cube's red, green and blue:

```gdscript
_rng.seed = s
for mi in cubes:
	mat.albedo_color = Color(
		_rng.randf(),
		_rng.randf(),
		_rng.randf()
	)
```

The picture is difficult to predict by looking at it and easy to reconstruct by repeating its construction. Those are two different facts. Calling the grid random because you cannot see a pattern is a report about your reading; rebuilding it from the same seed is a report about this generator.

Now press +1 DRAW. The right-hand grid changes completely; the left does not. Its seed is the same. Its cells are the same. What changed is one line that runs before the colouring starts:

```gdscript
if _extra_on and i == _columns.size() - 1:
	for k in range(extra_draws):
		_rng.randf()
```

One value is asked for and thrown away. Every colour after that is the value the other grid receives one draw later, so the whole grid shifts by a third of a cell and nothing lines up. Press +1 DRAW again and the match is mended. The seed was never the name of the picture. The name is the seed together with the order in which the values are used, and with the generator that supplies them.

Try to defeat the match. Choose the least predictable patch you can find, replay it, and check it cell by cell rather than looking for something that resembles it somewhere else. Ask another visitor to choose theirs. A surprising result can have a repeatable cause, and their first impression is not made foolish by that; it answered a different question.

<!-- @ -->

The crank machine across the room turns the same kind of generator by hand, one state at a time, and the comparison of true and pseudo sources beside it asks where a value comes from when there is no seed to return to. The catalyst on the platform is labelled for this sequence, not for chaos: nothing in this room is chaotic, and the word would promise a disorder the procedure does not have.

The gauge in the next room asks what one number can retain from a sequence. Keep the three things apart as you go: how the grid looks, how it was made, and what a measurement of it can say. A reproduced field can still have a varied histogram.
