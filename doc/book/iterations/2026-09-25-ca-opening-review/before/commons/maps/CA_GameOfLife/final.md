# A history you can inhabit

<!-- @ca_bridge -->

A gap in the screen lets you see through. The same gap in the floor asks something else of your body.

Stand at the desk before the basin. Its small coloured bars have relatives ahead: tiles laid across the recess, and a lattice standing along its side. Find the gold line in all three places. Press ROW. The line moves into an earlier part of the pattern. Nothing has been recalculated. You are moving your attention through a record.

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

Leave the desk and walk along the margin beside the basin. The gold line meets your row. It crosses the tiles and climbs the lattice; back on the desk, the same generation is marked. Walk farther, then turn back. An earlier row returns to the gold, but the later rows have not gone away. Your return has undone nothing.

Depth is doing the work of time. In the earlier volume, neighbours surrounded a cell within one three-dimensional state. Here a nearby row is an earlier or later moment. A solid-looking arrangement can hide that difference. None of the four choices has changed in this hall: it is Rule 30 again, three cells in a row, one row at a time. What has changed is where the past is kept.

Stop beside a gap. The line can pass through it; your foot would need support. Beyond the last recorded row, the marker stays behind. Walking cannot supply a generation the machine has not made. If RUN is on, the record can keep growing while you revisit an earlier part. Looking back and running backwards are different acts.

![The walking visitor selects one generation across the floor tiles and wall lattice.](images/walking-history.png)

*The gold line follows a place in the record. The same pattern meets us as an image and as possible support.*

The same record is dressed three ways. On the desk, a one becomes a coloured bar. In the basin, it becomes a tile with collision. In the lattice, it becomes coloured infill in a bronze frame. There is one stored history, but its uses have different consequences. The frame stands independently; the pattern does not calculate structural engineering. The basin has a lower collecting floor and end ramps, and the museum passage continues alongside it.

Try SEED, which changes the beginning while keeping Rule 30. Or return to SINGLE and press FLIP X9: one additional site in the starting row changes. STEP through the consequences. Later rows are made again from this beginning; we cannot honestly keep the old descendants and call them the same experiment.

Would you choose the same beginning for a screen and a crossing? You may want the holes in one and resist them in the other. A body we liked as ornament becomes awkward underfoot. This is a way of testing our desire against an implementation: change its use and discover what the beautiful surface had allowed us to overlook.

The next hall holds a two-dimensional present. A pattern will seem to travel while its cell addresses stay still. Keep the distinction between a recorded body and the procedure that continues it.

<!-- @ -->
