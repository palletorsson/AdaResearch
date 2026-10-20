"""Write one focused lesson from its tested, fully printed source."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HALL = ROOT / 'commons/maps/Randomness_10_PRINT_Algorithm'
STUDY = ROOT / 'doc/book/studies/randomness-lineage'
BEFORE = ROOT / 'doc/book/iterations/2026-10-09-randomness-revision/Randomness_10_PRINT_Algorithm/before/commons/maps/Randomness_10_PRINT_Algorithm'


def main():
    code = (STUDY/'04_two_diagonals.gd').read_text(encoding='utf8').rstrip()
    point = (STUDY/'point_body.gd').read_text(encoding='utf8').rstrip()
    text = '''# Two diagonals, one field

## Learning elements

- Binary choice from a probability threshold.
- One random draw per grid address.
- Reusing a line through rotation and length.
- Seeded replay with a changed rule.
- Observed count versus expected count.

Stand by the printer in the 10 PRINT hall. Each cell receives one of two diagonal marks. A small decision repeats until it becomes a field. In Random Remove, the draw selected an address and took its member away. Here every address stays occupied; the draw chooses what it holds.

We carry forward the grid, a local random-number generator and the familiar pickable point. Lines supplied the endpoints; Transformation supplied rotation. The new operation is a threshold: put the same random number on one side or the other of a probability, then turn the rod accordingly.

## Make a small comparison beside the exhibit

Work in your copy of the prepared Endless Museum. Its player, camera, lights and XR Tools are already running. Add one empty `Node3D` beneath this hall and attach `04_two_diagonals.gd`. Keep `point_body.gd` beside it. No prepared mesh children are needed. A tested temporary bay is hall-local `(3.5, 0, 10)`, with Y rotation **90 degrees**; face its front from the centre of the room. The board and guides are visual geometry, not new walls or a maze with collision.

The complete script builds an eight-by-eight board. Hold the point above a label and press its inherited trigger action:

- **REPLAY:** repeat this seed and probability.
- **BIAS + 0.25:** raise the probability of a pink backslash. After one, return to zero.
- **NEXT SEED:** start another reproducible sequence.

These zones use the point's position **relative to the study**, so they still work when the whole display is turned. This is the same point class and action learned earlier; the lesson adds what that action changes.

<!-- student-code:04_two_diagonals.gd -->
```gdscript
__CODE__
```

## Read the operation

The nested loops build the addresses row by row. `rods[0]` belongs to the top-left cell; `rods[columns]` starts the next row. Each rod is a thin cylinder. A square of side `cell_size` has diagonal length `cell_size * sqrt(2.0)`. Rotating the cylinder by a quarter of a right angle lets its centreline meet the cell's opposite corners. Seen from the board's front, positive `PI / 4` makes a backslash; negative `PI / 4` makes a slash.

`build_pattern()` resets the local generator, then draws once per address. `samples` retains the numbers. `marks` retains their interpretation as `true` or `false`. The chosen rule is `sample < probability`: a threshold of 0.30 assigns roughly thirty percent of future draws to the backslash. Godot's `randf()` can return either endpoint of its interval, so the explicit `probability >= 1.0` case makes probability one mean every mark, including a sample equal to one. Probability zero admits none. [Godot: RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)

`draw_pattern()` only reads that record. It changes the rods' rotation and colour, then counts the backslashes. It makes no random request. A redraw therefore cannot quietly become another pattern.

At probability 0.5, sixty-four draws have an expected mean count of thirty-two backslashes. A particular field need not contain thirty-two, and equal odds do not make its arrangement symmetrical. Read **Actual** beside **expected mean**. The neighbouring four-grid exhibit fixes its counts in advance; our program leaves the count to the draws.

## Change the rule and keep the evidence

Press REPLAY. Every number and every mark should return. Press BIAS once. The seed has not changed: the same numbers now meet a higher threshold. Some slashes can become backslashes; none can change in the opposite direction. At one all are pink; at zero all are dark. Return to 0.5 and the first field returns.

For an independent edit, set `probability` to `0.30`. Predict what the label will call the expected mean, then run: it is **19.20**, not a promise of nineteen marks. Keep the seed while comparing other thresholds. Changing the seed is a separate experiment; it does not guarantee a visibly new field, especially when the threshold allows only one mark.

Next set `columns` to `4` and `rows` to `3`. The program now uses the first twelve draws of the same stream. They wrap four to a row. Change the row width again while keeping twelve cells: the ordered choices stay the same, but different cells become neighbours. Use that distinction to explain why rearranging records can change a pattern without changing their values.

Our small board completes a static field at once. The installed printer also has timing, scrolling, a breathing bias and a link to the floor. Its seeded implementation derives a draw from each address; this example reads a sequential generator. Each can replay itself, but the same seed is **not** a claim that these two implementations print the same picture. We are reconstructing the two-mark operation, not replacing the exhibit's full program.

Nor have we written a maze solver. Diagonals can enclose regions or suggest passages. A navigable world additionally needs a definition of connection, boundaries, collision and the body's width. The reflection follows those differences in the hall; this lesson keeps the smaller operation inspectable.

## The point we already know

Keep your existing `point_body.gd` if it matches this listing. It creates its own sphere and collider and inherits pickup, release and trigger dispatch from the XR Tools supplied on Day Zero. It has no scene-path dependency. This is a dependency of the example, not a second lesson in making a sphere.

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

You leave with a reusable distinction: a draw, a rule for reading it, and a place for its result. Next, two possible marks become six possible die outcomes. Keep the generator and the record; change the available outcomes and ask what ends a run.

The historical starting point is the single-line program discussed in [*10 PRINT*](https://10print.org/). Our rods are a spatial interpretation of its two character choices.
'''.replace('__CODE__',code).replace('__POINT__',point)
    (HALL/'tutorial.md').write_text(text,encoding='utf8')
    final = (BEFORE/'final.md').read_text(encoding='utf8')
    final = final.replace('When do independent marks begin to look like a maze?', 'In the previous hall, a draw removed a member from a set. Here each place receives a mark. When do independent marks begin to look like a maze?')
    final = final.replace('Each new mark can lean either way. Nothing', 'Each new mark can lean either way. Equal odds do not promise equal numbers in the field, or symmetry in their arrangement. Nothing')
    final = final.replace('At 205, every mark is the same diagonal. The maze has become stripes.', 'At 205, the new field fills with the same diagonal. What suggested a maze has become stripes.')
    final = final.replace('A probability and a count are different instruments.', 'A probability and a count are different instruments. The small tutorial board keeps both in view: the odds we set and the count that actually arrived.')
    (HALL/'final.md').write_text(final,encoding='utf8')


if __name__ == '__main__': main()
