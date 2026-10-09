"""Author this one Cantor lesson; --write is required to replace manuscript text."""
from pathlib import Path
import argparse, shutil

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT/'doc/book/studies/fractals-through-the-hands/Fractal_CantorSet'

def write():
    shutil.copy2(STUDY.parent/'Fractal_RecursiveTrees/point_body.gd', STUDY/'point_body.gd')
    code = (STUDY/'cantor.gd').read_text(encoding='utf8').rstrip()
    point = (STUDY/'point_body.gd').read_text(encoding='utf8').rstrip()
    text = '''# Cantor Set — keep the two ends

**Learning elements**

- An interval recorded as a start and a length
- Replacing each entry with two entries
- Separate current and next arrays
- Retained length and generation history

Take the rose point above the small bar. Pull its middle towards you, past the rose mark, and release. The large bar becomes two. Repeat: every interval loses its own middle third. Your hand makes one gesture; the rule applies it across the current row.

The small bar is **one interval enlarged**, not the whole row in miniature. Its apparent size stays useful for your hand while the represented length falls. NEXT beside it performs the same cut. BACK and RESET return to earlier states. HISTORY shows the saved rows; GHOST marks removals without giving them collision.

## What continues

Keep the museum workspace and the small `PointBody` from Recursive Trees. There it turned a branch; here it carries the middle third. We already know arrays from Trace and loops from Arrays. Now a loop constructs a new array from an old one.

Save `cantor.gd` beside the unchanged `point_body.gd`. Replace the script on your empty, unit-scale `PointStudy` node with `cantor.gd`; keep the earlier tree script. Place the study where you can stand in front of its positive Z side. The existing museum supplies the camera, light, player and XR pickup functions. The script creates all its own objects and looks up no scene nodes.

This small reconstruction makes the interval rows and the hand control. The production artifact adds the plinth, comparison buttons, ghosts and full-size bars. The pagoda remains a second encounter with the same rule; rebuilding its architecture is not another assignment here.

## A record for one span

`Vector2(0, 6)` stores **start = 0, length = 6 metres** along a local horizontal line. These two numbers are data, not an XY position. The interval ends at `start + length`.

For its first cut, `kept` is 2. The new records are `(0, 2)` and `(4, 2)`. They cover 0–2 and 4–6. We never construct a solid for 2–4. On the next cut, use each record's own start and length.

The new function reads `intervals` and fills a separate `next` array. Only when that loop finishes does `advance()` replace `current`. Appending children to the array we are still reading would mix generations. `original.duplicate()` preserves the starting record; another copy records each completed row in `history`. `Vector2` entries are values, so these array copies are sufficient here.

## cantor.gd

Read `replace_intervals()` first. The rest connects that operation to the point you already hold and gives the numbers a visible form.

<!-- student-code:cantor.gd -->
```gdscript
'''+code+'''
```

The transition from held to released triggers one cut. Crossing the threshold while still holding changes nothing. Return the point before releasing to cancel. `to_local()` measures the withdrawal in the study's frame, even if you turn the whole station. `park()` returns the control after release. Five cuts is our deliberate limit.

`bar()` reuses the box mesh we already know. `VIEW_SCALE` fits six represented metres into a 1.2-metre drawing. The counts and lengths use the interval data, not that display scale. These small bars have no collision: they are a drawing of intervals. The point still has its pickup shape.

The two recursive child calls in Trees and the two appends here share a branching pattern. This script uses a loop to make one complete generation per gesture. It does not call itself; the hand decides when the next generation begins.

## Predict, then cut

After two releases you should have four records, each 2/3 metre long, with 8/3 metres retained in total. After five: 32 pieces, each 6/243 metre, retaining 64/81 metre. More entries, less material.

Enable `show_history` in the Inspector and run again. Make the same cuts. The drawing now includes the old rows, but the latest count and retained length must stay the same. At five cuts there are 63 drawn bars across the history and 32 current intervals. `original` is still `[(0, 6)]`.

For an independent variation, change the call to `replace_intervals(current, 0.25)`. Predict the two records after one cut before running: `(0, 1.5)` and `(4.5, 1.5)`. This keeps the outer quarters and removes the middle half. It is a different rule from the middle-third Cantor construction. The small hand model still depicts thirds; resize its three parts before presenting your variant as a matching exhibit. A legal fraction here is greater than zero and less than one half.

## Bring the question to the pagoda

Walk up the existing ramp and try its broad opening. Two presses of CUT add smaller openings alongside it. The same interval rule has been given height, depth and collision. A positive gap width does not guarantee a passage for the player's collision body.

What travels onward is the replacement function and the distinction between a current result and its record. These arrays live for the study's lifetime; this lesson does not save them across halls. Koch will replace each segment with a detour and increase length instead. Before changing the rule, keep this version so you can compare what each replacement preserves.

## The carried point file

This is the same `point_body.gd` as in Recursive Trees, included so the two-file example is complete. Its XR pickup and desktop hooks are existing knowledge; they are not new steps in the interval algorithm.

<!-- student-code:point_body.gd -->
```gdscript
'''+point+'''
```
'''
    (ROOT/'commons/maps/Fractal_CantorSet/tutorial.md').write_text(text, encoding='utf8')

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--write', action='store_true'); args=parser.parse_args()
    if args.write: write()
