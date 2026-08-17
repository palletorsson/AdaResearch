# Museum_AAA_Mixing — why the room is this shape

Subject: `mixing_jar` (wave 22 synthesis of `entropy_jar` and `entropy_morphogenesis`),
placed at eleven of its sixteen cells. 15 x 27, four terraces, one teleporter.

## The architecture is the axis

`reduction` is a chain, not a ladder: bodies → cells → figure → form, and every step
throws something away. So the room is four terraces at heights 4, 3, 2 and 1, one per
value, in that order. The grid's own movement rule does the arguing: a drop of one
level is free, a climb of one level needs a `wp` ramp, and this map contains none.
You can go from the bodies to the grown form. Nothing in the room will hand you the
walk back. That is the whole content of the axis, built as floor instead of stated as
a caption.

Within a terrace you can walk freely and compare all you like. Between terraces you
cannot. A coarse-graining is exactly that: free movement inside a cell, no return
across one.

## Terrace 1 — bodies (h4, rows 1–9)

An irregular lobe with no straight wall, because `bodies` is the only step where
*where a thing is* is still information, and a room that sorted its own contents into
a line would be arguing against its own exhibit. The four jars sit at four distances,
four bearings and four facings (180 / 90 / 0 / 270) — one rotation each. In `bodies`
there is no privileged axis, so nothing here shares a front. The `stirred` jar at row
7, column 3 faces away from the approach on purpose: you meet its back and have to
walk around it.

Three cells of height 5 at (5,10), (5,11), (6,11) are a 1 m parapet on a 4 m floor.
The jar's contents sit 0.678–1.078 m above its foot, so the parapet hides what is
*in* the jars without hiding the jars. From no standpoint on this terrace can you
hold `shelled` (row 3, col 11) and `mixed` (row 7, col 12) in one glance. The
comparison has to be carried, not read.

## Terrace 2 — cells (h3, rows 10–17)

Six bays, one per vertical cell of `entropy_jar`'s instrument (`entropy_jar.gd:427`,
six bins, hard-coded). Their widths are `stirred`'s own cell counts —
[9, 9, 18, 18, 9, 9] rendered as 2, 2, 4, 4, 2, 2 — so the corridor bulges in the
middle exactly where that state's bin plan doubles up. **The corridor is the fourth
found_state.** That is why `stirred` is the one value not mounted as an object down
here: you are standing in its picture. You walk the length of the histogram that is
reading you, and the bay records only which bay you are in, never where in it you
stood.

## Terrace 3 — figure (h2, rows 18–19)

A neck three cells wide with a jar on each shoulder and one cell of floor between
them. There is one way through and it is between them. Both read 1.00.

## Terrace 4 — form (h1, rows 20–23)

A chamber with a 3 m blind block at its centre (h4 at rows 21–22, cols 7–8), so the
two grown forms cannot be seen together. `sorted` (S = 0.00) and `shelled` (S = 1.00)
sit in opposite corners; you compare them from memory, which is all a number ever
gives you. This pair is deliberately **live**, not null — it proves the form does
depend on S, which is what makes it damning that it cannot depend on anything S threw
away. `form × mixed` is therefore not built: it would be the same picture as
`form × shelled` and would say nothing the two nulls above have not already said
better.

The teleporter stands on void beyond the last floor row. The final step down is a
fall.

## The designed null, as two placements

**Row 13, column 6 — `mixing_jar:90:0#reduction:cells#found_state:mixed`**
**Row 14, column 9 — `mixing_jar:270:0#reduction:cells#found_state:shelled`**

They face each other across the widest part of the corridor, about three metres apart,
in *different bays* — bay 2 and bay 3 — which is the joke: the instrument's own cells
cannot tell them apart either. In a table this pair is "0.00%". Here it is two objects
a person walks between, sees are identical, and has to reconcile with a memory from
the floor above, where one was a uniform red-and-blue haze and the other a red core
inside a blue shell. `entropy_jar`'s instrument coarse-grains along Y and only along Y;
`shelled` differs from `mixed` only in radius. The number is correct and it is blind,
and blindness is not an error to fix — it is what choosing a grain costs.

**What a visitor has to do to notice.** Nothing forces it. You can walk the corridor
in ten seconds and see three handsome bar charts. To find the null you have to have
looked properly on the terrace above, remember which jar was which, and then notice
that two of the three charts down here are the *same chart*. The one prompt is the
label at row 19 — `SIX CELLS ONLY` — and the second null one terrace lower, at the
neck, where the two jars stand on either side of the only doorway and both print 1.00.
That one is unavoidable: you cannot leave the room without walking between them.

## The seed, and a trap worth writing down

`mixing_jar` has a seed export and it ships **pinned**: `jar_seed: int = 20260817`,
which is exactly `dna.fixture.jar_seed`. Only azimuth and radius come from it — every
body's height is stratified arithmetic — so the six counts, S, the bars and the form
are seed-independent regardless. No token needs to set it, and **no token here does.**

That is not only economy. Writing `#jar_seed:20260817` would be *silently destructive*.
`GridInteractablesComponent._parse_config_token` (:1545–1576) treats a `#key:value`
pair whose value parses as a number, and whose key is not in `CONFIG_PARAM_NAMES`, as
positional-transform shorthand. `jar_seed` is not in that list. The pair would set
`rotation_y_degrees = 20260817.0` and hand the artifact `jar_seed = true`, which
`apply_grid_config` would read as `int(true)` = 1. A pinned jar, spun to a garbage
angle, reseeded to 1, with nothing logged. Verified by reimplementing the parser
against this map's own tokens; the check is in the wave report.

The corollary for the rest of this wave: **a numeric axis value cannot be placed
safely with the `#` syntax at all** unless its key already appears in
`CONFIG_PARAM_NAMES`. Every axis in this room is a String enum, which is why all
eleven tokens land clean.

## Why a room rather than another sheet

Wave 22's critic returned WEAK on this artifact at 4.37% focus, while its own colour
check reported the same pairs at 20.58% and 25.82% in hue. The axis moves colour at
near-constant brightness. Luminance cannot see that; an eye can, instantly. The WEAK
label was never a fact about the axis — it was a fact about the instrument, which is
also, exactly, what this artifact is *about*. The room is where the measuring is done
by a person who can move, and that is the only correction available.

## What this forecloses

- **You cannot re-check the bodies.** Once you have stepped down, the top terrace is
  gone. That is the argument, and it is also a real cost: a visitor who did not look
  carefully on arrival has no remedy but to reload the map. Deliberate, but it is the
  first thing to revisit if the room reads as punitive rather than irreversible.
- **Five of the sixteen cells are absent**, and each absence is an argument, not an
  omission: `cells × stirred` (you are standing in it), `figure × sorted` and
  `figure × stirred` (the neck holds the collision, not the spread), `form × stirred`
  and `form × mixed` (redundant against what is already mounted). A room that showed
  all sixteen would be a catalogue, and this project has enough catalogue.
- **No interaction.** The jar has no moving part and this map adds none. What the
  visitor does is walk and remember. `entropy_jar`'s best idea — shaking eighty rigid
  bodies until the number climbs — is not here and is not recoverable from here.
