"""One editorial pilot; retain the executable code and map encounter anchors."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
before = (HERE/'before/commons/maps/Random_Definition/tutorial.md').read_text(encoding='utf-8')
blocks = dict(re.findall(r'<!-- student-code:([^\s]+) -->\s*```gdscript\n(.*?)\n```', before, re.S))

def listing(name):
    return '<!-- student-code:'+name+' -->\n\n```gdscript\n'+blocks[name]+'\n```'

tutorial = '''# A seed needs a procedure

**Learning elements**

- Pseudorandom numbers: a changing state produces a sequence.
- Seed: choose a repeatable starting state.
- Draw order: each request advances the generator.
- Interpretation: use three successive values as one RGB colour.
- Replay: repeat the requests and their assignment.

Find the paired colour grids in Random Definition. Choose a patch you would keep. Press REPLAY, then +1 DRAW. Only the right grid changes. The seed stays. We will build the small program that makes this difference.

## Bring the objects; add a generator

The cube, grid loops, arrays and individual materials come from Transformation, Arrays and Colour. We use them again. The black point keeps its pickup and trigger behaviour.

Carried unchanged from [Wavefunctions — Synthesis Lab](../WaveFunctions_Synthesis_Lab/tutorial.md): `point_body.gd`.

In [Cage](../WaveFunctions_John_Cage/tutorial.md), we sampled a score once, kept its events and replayed that record. Here we ask a generator to produce its sequence again. This lets us recover an arrangement without storing every colour, provided we keep the procedure that made it.

A **pseudorandom generator** follows a deterministic rule. It has an internal state; each request uses and advances that state to produce a value. The sequence is designed to serve as random samples, even though repeating its starting conditions repeats its results. We can be surprised by an arrangement whose construction is reproducible.

The **seed** is an integer used to initialise that state. The current **state** is where the generator has reached after our requests. Setting the seed again starts its sequence again. It does not remember which picture we liked. Our code must still say what to do with the values.

## Build beside the museum's instrument

Keep the inherited file beside two new files: `01_seed_picture.gd` and `matrix_slider.gd`, printed below. Attach the first to an empty, upright `PointStudy` Node3D at unit scale. The established bay is hall-local `(10.5, 0, 18.5)`, Y rotation −90 degrees, facing into the room. The museum supplies the player, floor, camera, light and XR Tools. The script creates the study's nodes.

We make two 8 × 8 grids. Each cube owns a material. Before colouring either grid, we reset the same local generator to the same seed. The right grid can discard its first draw. The MATRIX slider changes the size of both grids; its construction is a support file after the lesson, so you can follow the randomness operation first.

Read `colour_grid()` and `replay()` first. `build_grids()` repeats the familiar cube-and-material construction. `activate()` gives the carried point three actions.

## The new program — `01_seed_picture.gd`

'''+listing('01_seed_picture.gd')+'''

Run it. Two matching grids appear. Hold the black point above a label and press its action trigger: left replays, middle toggles +1 DRAW, right increments the seed. The museum's desktop pickup/action controls operate the same point. The choice uses local X; moving the point alone requests no random values.

## Follow one colour through the code

`RandomNumberGenerator.new()` gives the study a generator of its own. Other museum artifacts cannot consume its next value. In `colour_grid`, `rng.seed = seed_value` resets it **once before the cube loop**. Resetting inside that loop would give every cube the same first colour.

Each `randf()` returns a floating-point value from zero to one. Three successive calls become red, green and blue in `Color(a, b, c)`. The draw does not arrive labelled “red”; that meaning comes from its position in our code.

Use these invented values to trace the assignment; they are not promised outputs of seed 42:

| Request | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Value | 0.2 | 0.8 | 0.4 | 0.9 | 0.1 | 0.6 | 0.3 |

The left grid's first cube receives `(0.2, 0.8, 0.4)`; the second receives `(0.9, 0.1, 0.6)`. With one discarded request, the right grid's first cube receives `(0.8, 0.4, 0.9)`. Its red came from the left cube's green; its blue came from the next cube's red. We shifted the grouping without moving a cube.

At eight by eight, each grid needs `64 × 3 = 192` displayed values. The shifted procedure consumes 193. `samples[0]` and `samples[1]` retain the assigned colours for inspection. They are records in this study's memory; nothing here saves them to disk or carries them through a portal.

## Predict, change, recover

Leave +1 DRAW off, replay and wait. The panels match. Waiting spends no draws because this program never requests them in a frame callback. Switch +1 DRAW on and check the channel relationship above. REPLAY must reproduce that mismatch. Switch +1 DRAW off to recover the match.

Now change only `Color(a, b, c)` to `Color(c, b, a)`. Predict which channel survives unchanged. Run it: red and blue exchange jobs, green stays, and the generator makes exactly the same requests. Restore the original assignment. Explain why matching seeds were insufficient to preserve the picture after that edit.

Drag MATRIX from eight to sixteen, then back. Both grids keep their panel area, seed and discard setting. More cells require more requests: 768 per grid, or 769 with the discard. The colour list keeps its earlier prefix, but a longer row places some entries at different spatial addresses. Returning to eight restores the earlier arrangement. Size changes the layout rule; it is not a zoom.

NEXT SEED adds one to the seed integer and replays. Count, positions and the colour-assignment rule stay. A neighbouring seed does not promise a neighbouring-looking picture. Keep the Godot version with any recipe you want to reproduce; its [generator implementation](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) is not a permanent file format.

## What we keep

We now have three things we can vary separately: the starting state, the requests, and the use of their results. Keep the local generator and both sampled lists. The installed instrument adds a seed slider, RANDOM and draw strips; our point-operated version reconstructs its paired-grid comparison.

In [Random Entropy](../Random_Entropy/tutorial.md), we will request integer symbol IDs and assign colours through a four-entry palette. We can then count each symbol and sort a copy without changing those counts. This RGB record does not silently turn into that new categorical sample.

## Support file — `matrix_slider.gd`

Save this complete new helper beside the study. It builds a constrained XR grab handle and emits `side_changed` when the chosen size changes. The study connects that signal to `set_side()`, rebuilds the grids and replays. The slider itself requests no random values. Fourteen intervals provide the fifteen integer sizes from 2 to 16.

'''+listing('matrix_slider.gd')+'''

'''

final = '''# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back. Cage had kept a score so that it could be heard again. Here, a number seems to offer another way back.

<!-- @seed_replay_demo -->

Two grids of coloured cubes stand above the controls. Choose a small patch you would not have thought to put together. Find it in the other grid.

Press REPLAY.

The colours stay where they were. The program has made the picture again.

RANDOM offers another arrangement. Perhaps this one is ugly. Perhaps an orange beside a violet is enough to make you keep looking. Replay it. An accidental pleasure has become something you can ask for again. Repetition is useful when chance gives us something we would like to work on.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. No cube has moved. Above the grids, the right strip of draw heights now begins with the second bar on the left. One value was requested and left unused before the colouring began. Every following group of three starts one place later.

Nothing in a draw says that it is red. Red is the use made of its place in those three requests.

Look back at your patch. Perhaps the misplaced beginning gives you a relation you want. There is no need to prefer the matched pair. The line that interrupts a demonstration of sameness can also be used to make another palette.

The two handles let us change different things. The seed changes the colour stream. MATRIX changes how many cells receive it and where a row ends. A larger matrix redistributes the familiar beginning across new addresses. Here, randomness varies what the program has made variable. Another seed cannot persuade a cube to leave its cell.

That suggests a different experiment: give a few draws the job of choosing which cubes may leave the panel. The orderly instrument might shed a corner or trail a sleeve across the floor. We have not built that behaviour here. Imagining it helps us locate the decision: someone would have to give a number that new job. The invitation to misbehave would itself become part of the program.

<!-- @textile_comparison -->

The three textile panels make this question visible without freeing a single cube. Diagonals, upright and horizontal marks, then blocks: three pairs of signs receive the same draws. Follow one cell across the panels, then step back. The same choices have become different figures. Chance has not chosen what a mark means. The program supplied that vocabulary before drawing.

<!-- @random_number_book_page_1955 -->

Further along stands a page recalling RAND's *A Million Random Digits with 100,000 Normal Deviates*, published in 1955. A book you could open twice at the same line and encounter the same chance again. The digits began with an electronic roulette wheel in 1947; its output was tested, corrected and prepared for use in experiments.[^rand-1955]

The tables were intended for punched-card machines. After the loom, that is a peculiar return: holes could carry a weaving instruction, or a supply of numbers used to sample possibilities. At RAND, tables helped researchers perform Monte Carlo calculations when working through every case was impractical. Chance required machinery, tests and patient preparation before anyone could put it to work.

Our museum page lets numbers fall away as fresh ones enter. It keeps the book's appearance while abandoning the fixed page's way of returning. Try to remember a number as it disappears. The seed bench can reconstruct its picture; this page keeps no archive for us to reopen.

<!-- @prng_crank_machine -->

On the way back, stop at the crank. One press, one new state. The request gets a gesture. The colour grids have already made 192 requests for one picture; here a single step asks for your hand.

<!-- @ -->

Calling a picture random describes something different from showing how this generator can reproduce it. We can enjoy the surprise and learn its conditions. The next room gathers a sequence into counts and an entropy reading. Carry the patch you chose: what will that measurement remember of the relation that made you stop?

[^rand-1955]: RAND's [introduction and production account](https://www.rand.org/pubs/monograph_reports/MR1418.html) explains the demand for sampling tables, their punched-card use, and the tests and transformations applied to the roulette-wheel output. A fixed table retrieves retained digits; our seeded generator calculates its sequence. Both require a procedure for choosing and using what comes next.
'''

for name, text in [('tutorial',tutorial),('final',final)]:
    (ROOT/'commons/maps/Random_Definition'/f'{name}.md').write_text(text.rstrip()+"\n",encoding='utf-8')
print('Revised Random Definition only.')
