# A history you can inhabit

<!-- @ca_bridge -->

A gap in the screen lets you see through. The same gap in the floor asks something else of your body.

Stand at the desk before the basin. Its small coloured squares have relatives ahead: tiles laid across the recess, and a lattice standing along its side. Find the gold line in all three places. Press ROW. The line moves into an earlier part of the pattern. Nothing has been recalculated. You are moving your attention through a record.

The room greets you with twelve rows already made. Stay on the museum floor and press REPLAY. The record returns to one occupied square. There is less floor now, and less ornament. This button resets the experiment; the museum's clock continues.

Before STEP, look at the three positions around that square. Which squares will appear in the next row? Press once. A short line arrives on the desk, another row of support appears ahead, and the screen receives a vertical strip. Make one more prediction before asking it to continue.

The rule reads left, centre and right in one row. Their ordered bits select an answer:

```gdscript
var index = (a << 2) | (b << 1) | c
```

Here `a`, `b` and `c` are the three states. The shifts give their positions different weights: four, two, one. `100` and `001` both contain one occupied cell, but ask different questions of the rule. The bridge's `_apply_rule` reads bit `index` from the number 30. Each answer is written into a new row while the old row remains available to its other neighbours.

The study keeps that new row:

```gdscript
var next_row: Array = work._calculate_next_row(history.back())
history.append(next_row)
```

These lines come from `history_study.gd`, which calls the original bridge's solver. The record holds fifteen sites across and at most twenty-four rows. At the edges, left and right wrap. At the end of the record, this instrument stops adding rows. The first boundary belongs to the neighbourhood; the second belongs to our viewing budget.

Follow the gold line onto the tiles. Depth is doing the work of time. In the earlier volume, neighbours surrounded a cell within one three-dimensional state. Here a nearby row is an earlier or later moment. A solid-looking arrangement can hide that difference.

The same record is dressed three ways. On the desk, a one becomes a coloured square. In the basin, it becomes a tile with collision. In the lattice, it becomes coloured infill in a bronze frame. There is one stored history, but its uses have different consequences. The frame stands independently; the pattern does not calculate structural engineering. The basin has a lower collecting floor and end ramps, and the museum passage continues alongside it.

Try SEED, which changes the beginning while keeping Rule 30. Or return to SINGLE and press FLIP X9: one additional site in the starting row changes. STEP through the consequences. Later rows are made again from this beginning; we cannot honestly keep the old descendants and call them the same experiment.

Would you choose the same beginning for a screen and a crossing? You may want the holes in one and resist them in the other. A body we liked as ornament becomes awkward underfoot. This is a way of testing our desire against an implementation: change its use and discover what the beautiful surface had allowed us to overlook.

The next hall holds a two-dimensional present. A pattern will seem to travel while its cell addresses stay still. Keep the distinction between a recorded body and the procedure that continues it.

<!-- @ -->
