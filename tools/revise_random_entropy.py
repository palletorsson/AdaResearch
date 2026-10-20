"""Write a complete categorical-record lesson and lighten the reflective arithmetic."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STUDY=ROOT/'doc/book/studies/randomness-lineage'

INTRO='''# Keep the counts, change the neighbours

**Learning elements**

- Symbol IDs and a palette
- Frequency counts and relative frequency
- Copying a list before sorting it
- Neighbour comparisons
- Marginal Shannon entropy

Choose two neighbouring tiles on the ledger. Press SORT. The tiles regroup while the bars and large number stay. Which part of the arrangement did the measurement keep?

## What you bring

Keep the cube, its own material, the local generator and the held PointBody from Random Definition. Keep Trace's distinction between a record and a drawing of it. The new work is to count a record without losing its original order.

The previous program drew three floating-point values for every RGB colour. Here each draw is **one integer symbol**, from 0 to 3. `palette[symbol]` gives it a colour. We are making a new categorical sample, not silently converting the old colours or importing them through the portal. The same seed with a different kind of request is a different procedure.

**Build:** an original row, a displayed copy and four frequency bars.

**Investigate:** sort only the copy. Compare counts, neighbouring pairs and entropy before and after.

## Work inside the museum

Place the upright, unit-scale `PointStudy` at hall-local `(14.8, 0, 8.0)` metres with Y rotation −90 degrees in Random Entropy. Its front faces into the entrance chamber with the east wall behind it. The existing ledger remains the main encounter. The museum supplies player, light, camera, floor and XR Tools.

Save `02_counts_and_neighbours.gd` beside the unchanged `point_body.gd` and attach it to the study. The complete new file creates every cube, bar and label. Keep the supplied museum environment; there are no prepared mesh children to find.

Hold the black point above a label and press its action trigger. REPLAY reconstructs the sample from the current seed. SORT / DRAWN changes the copy's order. NEXT SEED increments the seed and reconstructs the sample. Sorting stays selected when you replay or change seed. These are the same local-position choices used in the previous lesson, with SORT replacing +1 DRAW.

## Complete code — 02_counts_and_neighbours.gd

Read `new_sample`, `counts_of` and the first three lines of `draw_state` first. They create the record, count it and protect it with a copy. Then read `neighbour_changes` and `entropy_of`. `box_at`, `text_at` and `_ready` reuse familiar construction to make those operations visible.

'''

TEXT='''
## A symbol is an address, not a colour value

`randi_range(0, palette.size() - 1)` includes both ends. With four palette entries, the possible IDs are 0, 1, 2 and 3. A draw of 2 selects `palette[2]`. The number 2 does not mean twice as much colour as 1. It names a category.

`record` keeps those IDs in draw order. `counts_of` creates four zero counters and uses each ID as an index: `counts[symbol] += 1`. The loop visits sixteen entries, so the counts must add to sixteen. An even drawing rule does not promise four occurrences of each symbol in this particular sample.

The bars divide each count by the **total number of draws**. Their full height is always 0.7 metres at 100%; one quarter gives 0.175 metres. Zero has a printed count but no visible bar. This fixed scale differs from the installed ledger, which fits its tallest bar to the available height. Read the labels before comparing displays.

## Keep one list; change another

`shown = record.duplicate()` creates a separate array with the same integers. `shown.sort()` puts only that copy in ascending order. No random request occurs during sorting. The upper row still shows `record`; the lower row shows `shown`. Press SORT / DRAWN again to recover the original arrangement below too.

With `shown = record`, both names would refer to one array. Sorting through either name would lose the original order. The copy matters because it lets the two versions remain available together.

`neighbour_changes` reads pairs instead of individual symbols. It begins at index 1 and compares each entry with the one before it. Sixteen entries have fifteen such pairs. The last entry is not connected back to the first. This is one small measure of order, not a complete account of a pattern or its meaning.

## What the entropy function reads

The function receives **counts**, with no positions or neighbouring pairs. It first adds them to find the sample size. For each positive count, `p` is its share of that sample. `-log(p) / log(2.0)` is the information value associated with that share; multiplying by `p` weights it. Adding those terms gives the empirical marginal Shannon entropy, H, in **bits per symbol**.

Skip zero counts before taking a logarithm. Their contribution is zero; evaluating `log(0)` is not how we obtain it. The program requires a nonempty sample.

For four equally frequent symbols, each share is one quarter. Each contributes half a bit, giving H = 2. With just one symbol occurring, its share is 1 and H = 0. The calculation does not multiply by the record length, predict from the preceding entry or measure physical heat. You can use these two cases to check the function before treating a less familiar number as evidence.

## Predict, then change the copy

Before pressing SORT, write down the four counts and choose a neighbouring pair in the upper row. Predict which readouts can change. Now press it. The lower row regroups; the counts and H remain. The original row and its neighbour count remain too. The copy's number of unlike neighbours may change. If the original happened to be sorted already, the operation would have no visible difference.

Press REPLAY with sorting still selected. The generator reconstructs the same original, and the copy is sorted again. Waiting and moving the point without triggering do not request values. Compare this with Cage: there REPLAY read the stored score; here REPLAY rebuilds the seeded record.

## Give the gauge a perfectly regular pattern

In `new_sample`, replace the append line with `record.append(i % palette.size())`. Keep sixteen entries and the four colours. This cycles through 0, 1, 2, 3 four times; `%` gives the remainder after division. It uses no random draw.

Predict the counts, H and number of unlike neighbours before running. Then compare the original with the sorted copy. The regular cycle has counts `[4, 4, 4, 4]` and H = 2, the largest marginal value for four symbols. It has fifteen unlike neighbouring pairs; the sorted copy has three. The maximum reading did not make the sequence difficult to predict once you knew its cycle.

Make another version with `record.append(0)`. Predict which bars disappear and what the readouts become. Its counts are `[16, 0, 0, 0]`, H = 0, and both neighbour counts are zero. Zero-count categories remain in the declared palette even though this sample does not use them.

Keep one edited version and make a further pattern of your own. Can you change the neighbours while keeping all four counts? Explain why the gauge cannot distinguish those arrangements. Restore the sampled append line before using NEXT SEED to investigate random draws again.

## The carried point — point_body.gd

This file is unchanged from Random Definition and Wavefunctions. It creates the sphere and its collision, and inherits pickup and `action_pressed` from the XR Tools installed on Day Zero. Keep it beside the lesson. Its behaviour is already known; the counting operation is the subject here.

'''

END='''
## Compare with the hall

The installed `shannon_entropy_meter` has 200 draws and ten symbols. Its upper ribbon animates a sort while its front excerpt keeps the beginning in draw order. Our smaller program keeps all sixteen original entries visible and recolours a second row immediately. Both preserve the original sample and measure symbol shares independently of order.

The ledger's CONTRAST action selects another cached sample drawn from unequal source probabilities; it does not sort the first sample into unequal counts. Its maximum is log₂(10), about 3.322 bits per symbol. Our four-symbol ceiling is 2. Those different alphabets must be named with their readings.

The ruin, jar and large black-and-white room offer other encounters with arrangement. Visit them with the reflective text. They are not missing construction steps in this lesson, and their different uses of entropy should not be treated as interchangeable.

## What travels onward

Keep the distinction between an address and a value, between an original and its copy, and between an arrangement and its counts. Random Remove uses a list with another role: it contains the addresses that may still be chosen. Before randomness selects a member, a rule decides who enters that list.
'''

def listing(name):
    return f'<!-- student-code:{name} -->\n\n```gdscript\n'+(STUDY/name).read_text(encoding='utf8').rstrip()+'\n```\n'

def main():
    raise SystemExit('Historical counts-lesson generator: its text is now counts-and-neighbours.md. Edit the current tutorial and final directly; use the entropy-compartments reconstruction check.')
    (ROOT/'commons/maps/Random_Entropy/tutorial.md').write_text(INTRO+listing('02_counts_and_neighbours.gd')+TEXT+listing('point_body.gd')+END,encoding='utf8')
    p=ROOT/'commons/maps/Random_Entropy/final.md'
    text=p.read_text(encoding='utf8')
    if 'What the gauge counts is this:' not in text:
        assert 'The gauge makes one tally per symbol' in text and '```gdscript' not in text
        return
    start=text.index('What the gauge counts is this:')
    end=text.index('Sorting changed the row without changing any tally')
    text=text[:start]+'''The gauge makes one tally per symbol, wherever that symbol stood. It then condenses the shares into an entropy reading. Neither calculation asks which tile was next to which.

For ten equally frequent symbols, its ceiling is about 3.32 bits per symbol. The reading sits just under it: this particular sample from an even source did not divide evenly. The bars keep what happened, rather than the ideal distribution as if it had already happened.

'''+text[end:]
    text=text.replace('''The display gives every bar at least two millimetres:

```gdscript
height = max(0.002, height)
```

A visible mark can stand for zero.''','''The display gives every bar at least two millimetres. A visible mark can stand for zero.''')
    text=text.replace('''The first sample comes from a seeded local generator, giving each symbol the same chance on each call:

```gdscript
\t\tsequence.append(_rng.randi_range(0, num_symbols - 1))
```

The seed lets the gauge recover this sample when it rebuilds.''','''The first sample comes from a seeded local generator, giving each symbol the same chance on each call. The seed lets the gauge recover this sample when it rebuilds.''')
    assert '```gdscript' not in text
    p.write_text(text,encoding='utf8')

if __name__=='__main__':main()
