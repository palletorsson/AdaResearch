"""Write the third Randomness lesson from its complete, testable listing."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT / 'commons/maps/Random_Remove'
STUDIES = ROOT / 'doc/book/studies/randomness-lineage'


def main():
    code = (STUDIES / '03_eligible_addresses.gd').read_text(encoding='utf8').rstrip()
    point = (STUDIES / 'point_body.gd').read_text(encoding='utf8').rstrip()
    tutorial = '''# The set before the choice

## Learning elements

- Eligibility: a condition defines the possible choices.
- Candidate lists: a list offset refers to a stored grid address.
- Sampling without replacement: remove the chosen address from the list.
- Empty-set guard: stop before requesting an invalid draw.
- Replay: restore both the candidates and the generator.

## Start in the museum

Find the eight-by-eight removal board. Sixteen cubes are amber and forty-eight are grey. Before pressing REMOVE ONE, point to a cube that cannot be chosen. Then empty the amber square. Its final outline was fixed before the first draw; the order was not visible yet.

We return to the cube grid from Random Definition and the array work from Random Entropy. There, sorting preserved every member. Here, a choice changes what can be chosen next. The PointBody is the same class used in those lessons. We reuse its construction and trigger action; we do not import the previous hall's sample or pretend that a new node is the object carried through a portal.

The student study is one small board. The hoppers and walkable removal floor remain other encounters in this hall. They do not require two more implementations in this lesson.

## Make the small version

Use your prepared Endless Museum project with XR Tools installed. Save `03_eligible_addresses.gd` beside the existing `point_body.gd`. Add an empty Node3D named `RemovalStudy` under the Random Remove hall and attach the first script. Use hall-local position `(13.2, 0, 8)` and Y rotation `-90` degrees. The museum supplies the floor, player, camera and light. The script builds every cube, slot, label and the familiar point; no prepared mesh children are needed.

This study hides display cubes immediately. Its visual plinth has no collider; the museum floor still supports the player. The installed board has a brief red warning, while the arena also removes collision. Those are additional behaviours, not hidden parts of this listing. Keep this reconstruction separate from the existing exhibits.

The board stays eight by eight here so the new subject is eligibility. Random Definition's resolution slider is not needed to explain removal. Hold the point above a label and press the trigger: left resets, middle removes one, right increments the seed and resets. The positions are local to the study, so turning the whole board does not exchange its controls. Only the point's local x position chooses the action.

### `03_eligible_addresses.gd`

<!-- student-code:03_eligible_addresses.gd -->
```gdscript
CODE
```

### `point_body.gd` — unchanged

Keep your existing file if you have it. This is the complete dependency for a reader joining here; its geometry and pickup behaviour are not another task to rebuild.

<!-- student-code:point_body.gd -->
```gdscript
POINT
```

## Follow one removal

`eligible()` is a question with a Boolean answer. It admits columns 2–5 and rows 2–5, including both ends. This is where you decide the set. Moving the pedestal does not change the column and row stored for a cube.

The nested construction loops store the cubes row by row. A cell's address is `row * side + column`. With eight columns, column 2 in row 2 has address 18. `address % side` recovers its column; division rounded down recovers its row. This is the grid addressing learned earlier, now used to keep track of an absence.

`reset_run()` visits all 64 addresses and collects the sixteen allowed ones. The candidate list begins `[18, 19, 20, 21, 26, …]`. **Offset 0 in that list means address 18 in the cube array.** These are two different indices. After a removal, list offsets shift; grid addresses keep their meanings.

`remove_one()` first checks whether the list is empty. If so, it returns `-1` without requesting randomness. Otherwise it draws an offset into the current list, looks up the address, hides that cube, and removes the offset from the candidate list. The return value is the removed address; `-1` means that no removal happened.

We leave `cubes` and `slots` intact. Hiding a cube changes its visibility, not its array address, and the slot remains visible underneath. `history` appends the removed addresses in order. Removing from `candidates` is what makes this sampling **without replacement**. Merely hiding a cube would still allow it to be chosen again.

The next draw is uniform over the remaining candidate offsets. No grey cube can be drawn. The condition governs eligibility; the random request chooses within it. In the previous hall a measurement ignored the arrangement. Here, counting sixteen candidates alone does not tell us which sixteen positions they occupy.

## Predict, change, check

First predict the original version: sixteen successful removals, no repeated address, forty-eight grey cubes still visible. A seventeenth press must do nothing. Save the first few addresses on paper, reset, and compare them. The same seed, candidate order and requests reproduce the order; waiting between presses makes no requests.

Now change only the return line in `eligible()` to `return (column + row) % 2 == 0`. Predict the count before running: half of an eight-by-eight board, thirty-two cubes. Remove them all. Every removed address must belong to that checkerboard, and no excluded cube should disappear. This changes the eligible shape without changing the selection algorithm.

Next use `return row == 3`, then `return column == 3`. Each offers eight choices. Keep the same seed and compare the complete orders. A draw at column 5, row 3 in the first becomes column 3, row 5 in the second: equal list lengths and ordering give corresponding offsets. The spatial meanings differ.

Finally use `return false`. The board must open with no eligible cubes, show that it is empty, and accept repeated trigger presses without an error. RESET should preserve that empty rule. An empty selection is a valid outcome; it is not permission to select from all cubes instead.

Restore the range rule when finished. Change `seed_value` or use NEXT SEED to compare orders, but do not require two seeds to produce different results. Replay is a claim you can test; guaranteed novelty is not.

## What travels onward

Keep the grid, the local generator and the distinction between a rule and a draw. The next hall, 10 PRINT, gives each cell two possible diagonals. Here a draw withdrew a member; there it will assign a mark whose neighbours help make a pattern.
'''.replace('CODE\n', code + '\n').replace('POINT\n', point + '\n')
    (MAP / 'tutorial.md').write_text(tutorial, encoding='utf8')

    final = '''# The set before the choice

In the last room, sorting changed the neighbours while the count stayed. Here, find a cube the process cannot choose.

A board of sixty-four small cubes stands on a pedestal a few steps inside the entrance, on the hall's centre line, numbered along two edges. Its controls sit together on the console in front; a cased account of the set stands to the left. Sixteen of the cubes are amber; the other forty-eight are grey.

<!-- @remove_random -->

Before pressing anything, count the amber ones. Four rows by four columns, from column 2 to column 5 and row 2 to row 5: sixteen possible first choices. The grey cubes are present, numbered, and out of the question. The plate beside the board names the range, a seed, and the numbers eligible, remaining and removed.

Press REMOVE ONE. One amber cube turns red for a moment and is gone; its slot plate stays, so the address survives the cube. The line names it: last removed, column such, row such. Remaining: fifteen. While a cube is still red, the same line says *Choosing*, with the address already filled in: the draw is made before the deletion. Press again. Does the new gap touch the first? Either answer is possible. Watch the amber set rather than expecting the gaps to spread like a stain.

Now point to a cube you know cannot disappear, and press until the amber is gone. Sixteen completed removals. The final shape was never in doubt: the square you counted at the start, emptied. What the initial picture did not tell you was the order, and the plate under each gap keeps only the fact of absence, not the turn it was taken on.

The rule asks about each cube's position on its own board. Column 3 remains column 3 wherever the pedestal stands. The admitted addresses form a list, and only then does chance enter. It chooses a place in that remaining list. The draw never encounters a grey cube; there is no probability, however small, of its being chosen in this run.

Removal is a further decision. The model stops drawing one cube but retains how to put it back. Its entry leaves the candidate list, which only shrinks until a new run. Look into the gap. The small slot plate is still there. At this board, the surface your feet stand on belongs to the museum; these small disappearances make no holes in it.

Filter, draw, delete: three decisions that are easy to fold into one word, *random*, and only the middle one is.

Press RESET. All sixty-four cubes return, sixteen amber again, and the line shows the same seed. Watch the first few removals twice. Resetting has restored both the set and the generator. Waiting before your next press does not advance this order. The room goes on around the board; the next choice waits for the button. A press during the red highlight is ignored while the removal is busy.

Press NEW SEED and try again. The button selects a five-digit seed and restores the set. It may select one you have already used, and a different seed does not guarantee a different removal order. Compare the histories you get rather than requiring difference as proof of randomness.

Then keep a seed and change the rule. ROW admits eight cubes along row 3; COLUMN admits eight along column 3. Follow the first few removals in each. The same changing counts offer the generator corresponding places in the two lists, but those places point elsewhere on the board. Where ROW removes column 5, row 3, COLUMN removes column 3, row 5. The common cube at column 3, row 3 disappears on the same turn in both complete runs.

ALL admits sixty-four. The draw's bounds have changed too; retaining a seed alone no longer means retaining the same list positions. Equal counts can leave a spatial difference undescribed. A rule can offer the same number of choices while making different places available, and the seed cannot tell.

Stop before the set is empty. Keep this interrupted pattern for a moment. Perhaps the openings make an arrangement you want. Nothing requires another press. The final empty range would erase the distinction between the orders you have been comparing; halfway through, their different choices can still be seen. A slot remembers an absence. The visible account remembers the last removal. The program retains the full order until the next reset, but this plate does not show it. The comparison between your runs is kept only by you.

<!-- @sampling_hoppers -->

Beside the board, two glass cases hold the same eight numbered blocks. Each has a handle. Pull the one on the left. A block comes forward, leaves a small copy in the row below, and travels back into its place. Pull the one on the right. Its block stays out. Behind it, the numbered slot is empty.

Try to get the same number again. On the left you can wait for it; nothing promises how long. On the right, the number you have just drawn is no longer available. An absence has become part of the next choice. After seven completed pulls the right-hand case has one answer left, and the left still has eight. Can you name that last answer before pulling? Which number survives still depends on the earlier choices.

Here code chooses the member. The movement lets you follow what happens to it afterward. Both machines begin with the same seed, so their first choices match. Then their available sets part company. The left-hand row can contain repetitions and keeps its latest twelve draws, though its count continues. The right-hand row can fill with every number once, then stops.

REPLAY BOTH restores the blocks and begins the two orders again. Watch the returning block rejoin its neighbours. Giving it back is an instruction too. What looked like another chance depended on making it available again.

<!-- @random_removal_arena -->

Behind the board, the set becomes a floor. Ninety-nine cubes span a basin inside a glass frame. Pause on the dark edge before entering. That edge is permanent. The amber cells are not.

Entry asks for one removal. As you walk, accumulated horizontal movement asks for another after sixty centimetres, provided the pending removal has finished. One cell turns red for eight-tenths of a second. Then its mesh disappears and its collider is disabled. The gap is now something your body can fall through. Fire burns at the base of the basin.

The draw chooses from the remaining cells, not from the cube nearest your foot. Walking makes a choice happen; it does not tell the choice where to land. Try the permanent apron and look back. A disappearance becomes a fall only because the code also withdraws support.

REPLAY restores the cells and their colliders, and starts the same seeded order again. NEW SEED starts another run. The floor begins with a fixed seed when the hall is built. Different walking paths can bring on the same removals at different times; the order alone does not describe the encounter. Unlike the small board, the floor does not name its seed. After NEW SEED, the order cannot be identified from its plate.

<!-- @ -->

Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change. The seed that makes a run repeatable has no say in that exclusion.

In the next room, the available choice narrows to two diagonal marks. Follow what their neighbours make of them: when does a choice become a contour, and when can that contour become a passage?
'''
    (MAP / 'final.md').write_text(final, encoding='utf8')


if __name__ == '__main__':
    main()
