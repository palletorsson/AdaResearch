from pathlib import Path
import os

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
MAP = ROOT / 'commons/maps/Random_Definition'

def save(path, text):
    temp = path.with_name(path.name + '.ada-tmp')
    temp.write_text(text.strip() + '\n', encoding='utf-8')
    os.replace(temp, path)

save(MAP / 'final.md', '''
# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back.

<!-- @seed_replay_demo -->

Here, two grids of coloured cubes stand above the controls. Choose a small patch you would not have thought to put together. Find it in the other grid.

Press REPLAY.

The colours stay where they were.

The program has coloured every cube again. The seed sets this generator's starting state; start it there again and make the same requests, and the same values return. Press RANDOM, find something in the arrangement it gives you, and replay that one. RANDOM can choose an earlier seed, including the one already here. A result can surprise us and still know the way back to itself.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. Look at the cube positions too: nothing has moved sideways to make this difference.

Above the grids, two strips turn the first twenty-four draws into bar heights. Switch the extra draw off, then on. The right strip now starts with the second bar on the left. Find the next two matches.

With the extra draw enabled, the right-hand grid makes one request before colouring its first cube:

```gdscript
_rng.randf()  # Request one value without using it for a colour.
```

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

Move the seed slider slowly. The handle travels smoothly; the readout chooses whole numbers. A neighbouring seed can give you a very different palette. The controls offer a thousand seeds, yet every result still arrives as sixty-four cubes with three varying colour channels. Another seed cannot add a cube or let one leave its cell. Those would be other changes to the program. Here, randomness varies what the program has made variable.

<!-- @textile_comparison -->

The three textile panels offer another comparison. Each begins with seed 41. Diagonals, upright and horizontal marks, then blocks: three pairs of signs receive the same draws. Follow one cell across the panels, then step back to see the larger figures those marks make. NEXT SEED changes the draws in all three; RESET returns to 41. These bolts are held still so their marks can be compared. Chance has not chosen what a mark means. The program supplied that vocabulary before drawing.

<!-- @random_number_book_page_1955 -->

Near the far end of the room, a page of five-digit numbers takes its look from a book of random digits published in 1955, a table anyone could open at the same line and read the same digits again.[^rand-1955] This page keeps the look and not the return. About once a second each column takes a new number at the top and lets its lowest one fall away. The page draws from the game's shared generator and keeps no record of a number once it has gone.

<!-- @prng_crank_machine -->

On your way back towards the entrance, stop at the crank. One press of its CRANK button, one state. It gives each request a gesture. We could follow every request at the colour grids too, but one picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

<!-- @ -->

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.

[^rand-1955]: *A Million Random Digits with 100,000 Normal Deviates* (RAND Corporation, 1955). RAND's [introduction](https://www.rand.org/pubs/monograph_reports/MR1418.html) describes a basic table generated by an electronic roulette wheel in 1947, tested and transformed before publication. Choosing a starting place in a fixed table can help us imagine a repeatable beginning. The table retrieves stored digits; a seeded generator calculates its sequence. Repeatability in this room depends on the generator and procedure being kept with the seed.
''')

tutorial = '''
# Make a colour return

In the room, a seed helped us recover a colour arrangement. Here we will make that return ourselves: give one cube a generated colour, repeat it, then change the result without changing the seed.

This builds on `_ready()` from Point Zero, arrays and loops from Array, and material colour from Colour. The new tool is a local `RandomNumberGenerator`. We borrow its internal algorithm, just as we borrow the renderer. What we will control is when it draws and what those draws become. Random Entropy will ask what remains when we count the values instead of keeping their arrangement.

Use the [standalone study](/book-review/doc/book/iterations/2026-09-30-random-definition-making/random-definition-study.zip), with Day Zero's editor and run workflow already in place. Work in `study.gd`; keep `study.tscn` as the main scene. `display.gd` supplies the cubes, one material per cube and a REPLAY button. It does not request random values. Each numbered file in `steps/` is a complete version you can copy into `study.gd` if you lose your place.

## 1. Give one cube three values

The project opens at this first step. Its complete script is:

```gdscript
__FIRST__
```

`$Display.build(1, false)` asks the supplied display for one cube and no second grid. The cube is the first member, `[0]`, of its `left` array. `material` refers to that cube's own material. These are the things already prepared for us; the three calls to `rng.randf()` are our new work.

Each call returns one number between zero and one. `Color(a, b, c)` assigns them to red, green and blue, in that order. Press REPLAY or Space. The helper calls `replay()` again; the generator continues from where the previous calls left it. Repetition is possible, but we have given it no instruction to recover a chosen colour.

## 2. Give the return a beginning

Add this variable beside `rng`:

```gdscript
var seed_value := 42
```

Then make this the first line inside `replay()`:

```gdscript
rng.seed = seed_value
```

Press REPLAY several times. Nothing appears to happen, although the code has requested three values again. Setting the seed puts this generator back at the same beginning. Change `42` to `137` and run again. Keep a colour you like by keeping its seed and this procedure. The complete version is `steps/02-seed.gd`.

## 3. Let the array receive the sequence

Change the display request to `$Display.build(4, false)`. It now gives us a 4 × 4 grid. In `replay()`, keep the seed reset once at the start, then colour each cube:

```gdscript
__GRID__
```

The loop reuses Array's ordered collection. Three draws per cube, sixteen cubes: forty-eight values receive a place. The supplied display orders cubes left to right, bottom row first, as the museum instrument does. REPLAY keeps the arrangement. The complete version is `steps/03-grid.gd`.

Try moving the seed reset inside the loop, just before `var a`. Every cube now starts at the same three values. Move the reset back outside. Its position changes the pattern without changing the seed.

## 4. Put two beginnings beside each other

Use `steps/04-pair.gd`. Its display request is `$Display.build(4, true)`. The same colouring loop is now a function called `colour_grid(cubes)`. `replay()` calls it once with the left array and once with the right:

```gdscript
colour_grid($Display.left)
colour_grid($Display.right)
```

The function resets the generator **before each grid**. Check the same cell on both sides. Press REPLAY and check another. If we reset only once before both grids, the right would continue after the left's forty-eight draws. Equal seeds are useful here because we also keep the requests and their assignment equal.

## 5. Spend one value without colouring anything

Use `steps/05-unused-draw.gd`. A `skip_first` argument tells `colour_grid` whether to make this extra request, after resetting the seed and before entering the cube loop:

```gdscript
if skip_first:
    rng.randf()
```

`replay()` passes `false` for the left grid and `true` for the right. The left uses forty-eight draws; the right consumes forty-nine but still gives forty-eight to its colours. REPLAY now recovers the difference too.

Follow the first cube: the left takes `(a, b, c)`; the right takes `(b, c, d)`. No value has changed its position in the generated stream. A different part of that stream is being assigned to each channel.

## 6. Keep the draws. Change their roles.

Return to the matched pair from step 4, removing the unused draw. This time keep both beginnings equal and swap the right grid's red and blue assignments. `steps/06-channel-roles.gd` is the complete version. Its loop first constructs:

```gdscript
var colour := Color(a, b, c)
```

Then, only for the right grid:

```gdscript
if swap_channels:
    colour = Color(c, b, a)
```

Find a cube with visibly different red and blue amounts. Its green stays the same. Both grids consumed the same forty-eight values. We changed what a value does, without requesting another one.

Choose which comparison you want to keep. Then replace the right-hand assignment with `Color(a, a, a)`: one requested value now supplies all three channels. The other two requests remain in the loop, so later cells still begin at the same place in the stream.

You now have a small construction you can alter: a generator, a repeatable beginning, an ordered array and a choice about what each value becomes. The colour grids are one use of those parts. Their arrangement no longer has to exhaust what the program can do.

## Beside this lesson

The museum has 8 × 8 grids and twenty-four-draw bar strips; this study uses 4 × 4 grids so individual cells stay easy to compare. Both use Godot's generator and the same reset → request → assign order. The bars show a short prefix, not evidence from which to infer the generator's period. Godot documents reproducible seeded sequences but treats the underlying algorithm as an implementation detail: keep the engine version with a study you need to reproduce.

[Technical companion](/book-review/commons/maps/Random_Definition/technical.md): current placement, controls, state restoration and implementation references. [Godot's generator reference](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html).
'''
study = ROOT / 'doc/book/studies/random-definition'
first = (study / 'steps/01-colour.gd').read_text(encoding="utf-8").strip()
grid = (study / 'steps/03-grid.gd').read_text(encoding="utf-8").split('func replay() -> void:\n', 1)[1].rstrip()
grid = '\n'.join(line[1:] if line.startswith('\t') else line for line in grid.splitlines())
tutorial = tutorial.replace('__FIRST__', first).replace('__GRID__', grid)
save(MAP / 'tutorial.md', tutorial)
save(study / 'TUTORIAL.md', tutorial.replace('Use the [standalone study](/book-review/doc/book/iterations/2026-09-30-random-definition-making/random-definition-study.zip)', 'Use this standalone study'))

save(MAP / 'technical.md', '''
# Random Definition — the instrument beside the lesson

The current 13 × 20 source grid places `seed_replay_demo:180#display:wall#comparison:replicas#stand:table#controls:compact#control_front:1.0` at column 6, row 6 (zero-based). Its controls face −Z. Seven placed artifacts remain: the replay instrument, textile comparison, crank, slot machine, TRNG/PRNG comparison, changing number page and catalyst. Map layers and the scene implementation are unchanged by this writing pass.

## Generator and assignment

Source: `algorithms/randomness/seed_replay/seed_replay_demo.gd`. `_regenerate()` resets the local `_rng.seed` before colouring each grid. Each cube takes three successive `randf()` results as RGB. The two 8 × 8 grids therefore assign 192 values each. With `_extra_on`, only the last grid discards `extra_draws` values after seeding and before colour assignment. This placement uses one: 193 requests, 192 assigned values. REPLAY keeps the selected procedure; +1 DRAW toggles it instead of accumulating offsets.

`raw_prefix()` uses a separate generator to inspect the first twenty-four draws without advancing the colour stream. These bars expose the offset, not a measured period. `_pick`, randomized on arrival, is separate again: RANDOM chooses `_pick.randi() % 1000`, so it may choose the current seed. Waiting alone never advances `_rng`.

The handle chooses `roundi(clampf(norm, 0, 1) * 999)`. Its continuous travel selects integers 0–999; adjacent seeds need not produce adjacent-looking palettes. This is a menu of seeds, not a guarantee of one thousand distinct images. `Panel/Param_0` is the current slider path. `_syncing_seed_slider` guards programmatic updates. The previous wrong path and compact-control repair are documented in the archived tutorial, preserved in this review's `before/tutorial.md`.

## A fresh instance and a restored visit

`_ready()` starts a fresh instance at configured `seed_value` (42 here) and its comparison mode. `capture_museum_state()` records the selected seed, extra-draw flag, picker state and last action. `restore_museum_state()` restores these, regenerates the colours and synchronizes the handle. `commons/scenes/em/em_portal_stream.gd` calls these methods when capturing and restoring compatible artifact nodes. A portal return with retained state is therefore different from a fresh load without retained state.

This is visit-state restoration, not an authored save-seed button or a promise of persistence across restarting the application. Current source inspection confirms the caller. The current native run verifies the artifact methods and the actual portal caller’s save/restore methods. During restoration the instrument rebuilds its bar strips; the caller now skips removed nodes before computing their state keys. This is not a physical portal or headset trial.

## Supporting encounters

The textile comparison at (6,11) gives three frozen vocabularies the same seed 41. NEXT SEED advances them together; RESET restores 41. The number page at (9,16) draws from shared game randomness and lets old numbers fall off its display. The crank at (3,4) makes each advance an individual action. These supports change the question about a sequence's use and retention; they are not alternative entrances to the first making exercise.

## The portable construction

`doc/book/studies/random-definition/` isolates the same generator and assignment principle. `study.gd` begins with one cube. Six complete scripts carry it through a seeded colour, a 4 × 4 grid, a matched pair, a one-draw offset and an RGB-role exchange. `display.gd` supplies geometry, individual materials and input; it consumes no random values. No XR setup, slider wiring or museum placement code is introduced in the lesson.

The final assignment exercise starts from the matched pair, with no discarded draw. It changes only the right grid's mapping from `(a,b,c)` to `(c,b,a)`. This comparison belongs to the editable study; the museum has not gained a channel-swap button.

Repeatability is scoped to the generator implementation, engine version and complete procedure. See [Godot's RandomNumberGenerator reference](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html).

## Evidence

The September 12 run's 65 checks describe an older layout and remain historical evidence. Current checks, source snapshots and their exact scope are in [the September 30 review](/book-review/doc/book/iterations/2026-09-30-random-definition-making/index.html). No learner, physical-headset or Quest performance claim is made.
''')
save(MAP / 'summary.md', '''
# A pattern that returns

Two wall-mounted colour grids make a repeatable beginning visible. Find a patch, replay it, then keep the seed while spending one unused draw before colouring the right grid. Values fall into different RGB roles; the cubes keep their positions. A mismatched pair may be the result you want.

The textile comparison changes the marks that receive the draws. The changing number page lets old results disappear. The crank turns a request into an individual action. All seven placements remain in the current 13 × 20 hall; the replay instrument is at column 6, row 6, facing the entrance.

The making lesson begins with one cube and grows into paired 4 × 4 grids. It introduces a local generator, seed, request order and colour assignment, using earlier arrays and loops. Changing the assignment becomes another way to work with the same draws.

Synthesis Lab supplies the preceding question about return; Random Entropy asks what survives when an arrangement becomes counts. Current verification and reading/making pages: `doc/book/iterations/2026-09-30-random-definition-making/`.
''')
save(MAP / 'intent.md', '''
# Random Definition — three connected routes

Question: Can we keep an unfamiliar colour arrangement, and what must remain the same to find it again?

Reading: A patch worth returning to gives seed and replay a purpose. One unused draw changes which values become red, green and blue. Keep the mismatch available as a desirable result. The textile panels, disappearing number page and crank extend the question from recovery to vocabulary, retention and individual requests.

Hall: Seven artifacts in the current 13 × 20 source grid. The primary replay instrument stands at (6,6), facing −Z, with wall display and compact controls. Textile comparison at (6,11); crank (3,4); slot machine (10,4); TRNG/PRNG comparison (3,16); number page (9,16); catalyst (10,8). Proximity alone does not make each support part of the manuscript or first lesson. Preserve the actual encounter before judging explanatory gaps.

Making: One generated cube colour → seeded replay → an array of colours → two equal beginnings → one unused draw → equal draws assigned to different channels. Borrow the generator internals, mesh construction and input. Teach ownership of the seed, request order and mapping. The self-contained study needs no museum or XR dependencies.

Lineage: `_ready()` and functions, arrays and loops, RGB materials are prior tools. A local random generator is new. Synthesis Lab asks what a return keeps; Random Entropy will distinguish an arrangement from its statistical summary. The walk remains a later investigation.

Boundary: A fresh load uses configured state. A portal return may restore retained artifact state. Keep generator/version/procedure with a seed; do not promise cross-version identity. Desktop software verification is not a learner or headset trial.
''')
print('Revised final, tutorial, technical, summary and intent; map and artifact retained.')
