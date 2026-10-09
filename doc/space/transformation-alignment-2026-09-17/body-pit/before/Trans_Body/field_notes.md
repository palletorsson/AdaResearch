# Trans_Body — field notes

## The ruling

Palle, 2026-09-08, first: *"In the transformation sequence. Three new artifacts"*,
then, unprompted, the three: *"Collider movement space. A cube grid and when we
walk it space is created by removing what our collider touches. On the same theme
a wall mech that is closed but open when we approach. The same with scaling scale
down around us so we can walk."*

The three were built first and placed at the far end of Trans_Rotation, which was
the only clear band in the chapter big enough to hold them. That was a compromise
of fit, not of meaning, and it was put to Palle as one: *"they're together because
that's where they fit, not because Trans_Rotation is where they belong."* He chose
the hall. The three tokens came back out of Trans_Rotation, which is byte-identical
to where it stood before.

## What the sequence file said, which decided it

`Trans_Rotation`'s artifact group declares `"size_budget": "compact_only"`. All
three of these register as `large`. So the placement and the chapter's own
declaration contradicted each other and one of them had to be wrong. That is not a
tie-break invented after the fact; it was found while opening the file to add them
to it.

(`Trans_Pit` is in `maps` with no artifact_groups entry and no `content` line at
all. Still true, still not this room's business.)

## The throats are three different widths, and that is the design

The seal is the room. If a visitor can walk round an artifact, the artifact becomes
sculpture and the hall becomes a corridor. So each throat is cut to its own
artifact rather than to a house measure:

| artifact | width | throat | side gaps |
|---|---|---|---|
| approach_wall | 4.40 m | 5 cells (5.00 m) | 0.30 m |
| carve_grid | 3.69 m | **3 cells** (3.00 m) | overlaps the walls by 0.35 m |
| approach_scale | 4.15 m | 5 cells (5.00 m) | 0.42 m |

A shoulder is 0.52 m. carve_grid is the odd one: in a five-cell throat it would
leave 0.65 m either side, which is walkable, so its throat is three cells and the
lattice is deliberately wider than the gap it stands in.

## Learned after the build

**The pathfinder cannot gate this room.** It reads the structure layer, where all
three throats are plain floor, and it knows nothing about artifact colliders — so
it returns OK whether or not a single artifact stands. A green pathfinder run is
not evidence about Trans_Body. `commons/testing/probe_trans_body_sealed.gd` is,
and it asks the live physics world rather than the arithmetic: a shoulder-wide
sphere stepped across each throat at chest height, every position of which must hit
something. Measured 0.20 m widest free run at all three gates. It runs the same
sweep one row earlier, over open floor, and requires 8.45 m free — without that
control, a query with a wrong mask or a bad shape would report a beautifully
sealed room.

**The teleport cell wanted height 0.** Rule 5 warned "Teleport at (5,23) has height
1, should be 0 (void)". Trans_Pre carries the same warning and nobody has minded,
but it costs one cell to be right.

**The capture's iso framing puts the camera inside the hall.** `iso_perfect.png`
came back as a wall of wireframe from within the geometry; `top.png` is the one
that reads. Not chased — it is the capture pipeline's framing on a long thin room,
not the room.

## The wall could not be walked through, and openness never said so

2026-09-08, Palle, in the headset: *"In the approach_wall rotation the element
has to be bigger for me to pass. I guess at least 0.5 m width."*

He was being generous. Measured with a sphere swept along the wall's own plane,
the hole was **0.00 m at every distance**, while `openness()` read 0.884 and the
seal probe, the behaviour probe and the museum boot were all green. Every number
this artifact reported about itself was unit-less, and a unit-less 0.884 sounds
like a wall that is most of the way open.

The geometry was innocent: each slat is hinged on its inner edge, so a slat at
full swing does vacate its own width. The arithmetic was the fault. A slat leaves
its own THICKNESS standing at the hinge, so the widest hole one slat can ever make
is `slat_w - thickness_m` — at fifteen slats across 4.4 m that is
0.293 - 0.12 = **0.17 m**, and no angle, easing or falloff can improve it. It was
not shut and it was not open. It was louvres.

Two changes. The slat count is now bounded by the width it must clear
(`floor(width_m / (min_clear_m + thickness_m))`, so 4.4 m gives five boards of
0.88 m, and a map asking for more gets a push_warning saying so), and the slats
nearest a visitor are driven fully open rather than left to the distance falloff.
`pass_width_m` is gone: `min_clear_m` is one number that both drives the opening
and is what `is_passable()` is asked about, so the two cannot disagree.
Measured after: **0.82 m**, a body fits, 0.00 m again once you walk away.

**And the ruler was half the confusion.** A sweep of spheres of radius r reports
the run of free CENTRES, which is the gap less 2r — so the first probe printed
0.00 m for every hole narrower than 0.52 m and 0.30 m for a 0.82 m one. I read
0.00 as "the wall does not open" and went looking for a geometry fault. The probe
now sweeps a needle to measure the hole and a shoulder to ask whether a body fits,
and prints both.

## Rejected

**Trans_Pit.** Thematically the closest existing hall — "a room where the center
grows and pushes you out" is the same argument — and already in the sequence, so it
would have cost no new registration. Its floor is too narrow: the three would have
had to be shrunk by config below the sizes they were designed at, and the seal
arithmetic above is exactly what would have been lost.

**Making a throat load-bearing for the pathfinder.** Teaching `map_pathfinder.py`
that these three are passable, the way the rethink taught it `tc` and `rc`, would
make the room honest to the tools. Not done: the pathfinder's notion of passable is
static, and these three are passable only while somebody is standing in them, which
is a different predicate and probably wants its own name.

## Open

- The museum plan HAS been re-applied (`tools/em_map_halls.py --apply`,
  2026-09-08): the transformation chapter is nine rows and `trans body` is dealt a
  hall at tile 13x25, 4 verbatim of 4, 0 plinths. The museum reports all three
  artifacts as severing the route, which is the 2026-09-08 placement ruling working
  — but it is a new KIND of severance, one that un-severs for a body, and anyone
  reading `em_built.json`'s `severed` array will read three entries here as a
  broken hall.
- No book pearl, and no page in the encyclopedia's tutorial skeleton — both are
  hand-splices, and Trans_Pre's own additions on 2026-09-05 left the same two open.
- carve_grid is 3.69 m of lattice to melt through at roughly one 0.34 m shell per
  press. That may be a good minute of pressing. `#cells_z` or `#bite_m` on the map
  token is the dial if it reads as tedious rather than as effort.
