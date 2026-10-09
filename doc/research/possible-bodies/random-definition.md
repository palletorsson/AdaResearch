# A pattern that returns

[Synthesis Lab](synthesis-lab.html) → **Random Definition** → [Random Entropy](random-entropy.html)

[The primary and its book passage](/necklace/thread?map=Random_Definition&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Definition)

Choose a patch of colour you would keep. Find it in the other grid. Press REPLAY and return to those cells before surveying the whole picture. **Can a surprise return exactly?**

![Seed 42, replayed twice at the same table: the two grids match](random-definition-equal.png)

Claude's table stands in the clear east half of the hall, facing west. The cloud remains behind the visitor. All 15 artifacts remain; the book follows `seed_replay_demo` as its one primary. This continuation repairs the seed slider, finishes the panel contrast and lets the existing encounter carry the text.

## Keep the number. Change the beginning.

Press +1 DRAW. The right grid changes. Its seed is still 42, and its cubes are still in their cells. One value was requested before colouring began, then given no colour at all.

![The same camera and same seed after discarding one draw: only the right grid changes its colours](random-definition-offset.png)

Each cell takes three successive values, one for each colour channel:

```gdscript
mat.albedo_color = Color(
    _rng.randf(),
    _rng.randf(),
    _rng.randf()
)
```

Before the right grid asks for its first red, this operation can advance the generator:

```gdscript
if _extra_on and i == _columns.size() - 1:
    for k in range(extra_draws):
        _rng.randf()
```

The grouping shifts. What supplied green supplies red, blue supplies green, and the next cell's red becomes this cell's blue. Sixty-four cells still receive 192 values. The extra draw makes the right grid consume 193. The discarded value changes the assignments without moving a single cube.

REPLAY keeps this difference. +1 DRAW again restores the match. The button toggles one discarded draw; repeated presses do not accumulate more of them.

## Follow one cell into the source values

The small comparison below uses the actual 64 RGB values exported by Godot at seed 42. It does not imitate the random generator. Switch the discarded draw on, then choose a cell and follow its draw numbers. Row zero is at the bottom, as in the artifact.

[Inspect the exported samples](random-definition-samples.json) in the interactive [review](random-definition.html).

The swatches map the exported material values directly to CSS RGB. They help inspect the assignment; they do not reproduce the museum's lighting or tone mapping. The photographs above show the rendered hall.

## A hand can move without choosing another seed

The handle travels continuously, but its receiver rounds the position to an integer from 0 to 999. Move slowly and there are moments when your hand moves while the seed remains. At other moments a small movement selects a very different patchwork.

The earlier receiver looked for a panel name that no longer existed. Its handle could move while every seed stayed the same. The corrected path now reaches the actual slider. The visible seed, handle and grids also synchronize after RANDOM and hall rebuilding.

![The local panel now keeps dark backing, readable pale tags and a larger cased action readout under the room lighting](random-definition-panel.png)

| Control | What it does here |
|---|---|
| SEED slider | Rounds the handle position to an integer from 0 to 999 and repaints the grids. |
| REPLAY | Restores the generator to the current seed for each grid, retaining the chosen extra-draw setting. |
| RANDOM | Chooses a seed using a separate local generator. It may choose the current seed or an earlier one again. |
| +1 DRAW | Switches one discarded draw on or off before colouring the last grid. |

Waiting does not advance the colour generator. The room can continue around a picture that stays still. Rebuilding the hall returns to its configured seed and comparison; the panel does not save a visitor's selection between visits.

## Another palette worth keeping

Keep the unmatched pair for a moment. Perhaps its disagreement gives you a relation you want. An instrument made to demonstrate a match has supplied another palette. That result is available to repeat and use.

This is a specific place for the question “what bodies are possible?” The seeds can change every colour, but the panel cannot add a cell, move it away from the grid or make its sampled value a force. A thousand choices leave other decisions fixed. The source shows where another kind of change would have to begin.

We needed more than the picture's seed: a generator, an order of requests and an assignment of their results. The number was a useful way back only while the rest of that procedure remained.

## Evidence and the next room

**65 independent desktop checks passed, with zero assertion failures and engine exit 0.** The checks include exact colour bytes, independent generator reconstruction, slider endpoints and intermediate seeds, a desktop pointer drag, all three buttons, local random-state isolation, panel contrast, approach, unload and rebuild. The two comparison captures use the same camera pose. Nine production-code excerpts were verified in the final and tutorial.

The engine still reports an ObjectDB leak warning and one resource in use at shutdown. Passing assertions do not resolve that warning. Headset reach and close lettering remain for a later visit; the captures support a desktop visual review.

[Desktop report](random-definition-check.json) · [Run receipt](random-definition-run.json) · [Exported samples](random-definition-samples.json) · [Tutorial](random-definition-tutorial.md) · [Technical notes](random-definition-technical.md) · [Critical text](random-definition-critical.md)

**Next: [Random Entropy](random-entropy.html).** Carry a small patch with you. If its colours are rearranged while their counts remain, what can a histogram tell us—and what part of the encounter has it left behind?

## Book passage

# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back. Here, choose a patch of colour you would not have thought to put together.

<!-- @seed_replay_demo -->

Two grids stand side by side above the table. Find your patch in one of them, then look in the same place in the other. Press REPLAY and return to those cells before surveying the whole picture.

The patch is back. Press RANDOM, choose something in the arrangement it gives you, and replay that one. RANDOM is allowed to choose a seed again, including the one already here. A result can surprise us and still know the way back to itself.

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

Use RANDOM again and wait before replaying. The room continues around you; waiting does not advance the generator that colours these grids. Try to predict one cell from its neighbour. Then use REPLAY to recover it. Difficulty guessing from the picture and the ability to repeat its construction are different things you can encounter here. Neither observation makes the other disappear.

There is no need to prefer the matched pair. Keep the extra draw on and compare the two colourings as possible companions. Perhaps the misplaced beginning gives you a relation you want. The line that interrupts a demonstration of sameness can also be used to make another palette.

Move the seed slider slowly. Your hand travels between positions while the readout counts whole numbers, from 0 to 999. The handle can move a little without choosing another seed. The controls offer many seeds, yet every result still arrives as sixty-four cubes with three colour channels. A wider choice within that arrangement cannot give a cube a fourth channel or let it leave its cell. Those would be other changes to the program. Learning what the slider can vary helps locate the decisions it leaves beyond reach.

<!-- @ -->

The crank across the room makes a generator advance by hand, one state at a time. It gives each request a gesture. We could follow every request here too, but the picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.
