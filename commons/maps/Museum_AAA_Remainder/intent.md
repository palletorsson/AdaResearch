# Intent — Museum_AAA_Remainder

Concept: one artifact, `remainder_box`, hung eight times at eight different cells of
its own 4x4 sheet, in a room whose plan is the argument the `remainder` axis makes.
15 x 16 cells. No other artifact is placed and there is no wall text.

## Why this room exists at all

Across 2,419 maps there are 9,664 placements of artifacts that declare `dna.axes`,
and 27 of them set a value. Everything else in the museum is a default. The whole
DNA programme has been photography: one camera, one standpoint, sixteen tiles on a
web page. A room is the other instrument. It has no fixed standpoint, and it has a
body in it that moves.

## The shape, and what it argues

The room closes as the reading seals. That is the whole plan, and it runs north to
south in the order the visitor walks it.

| chamber | rows | value | what the space does |
|---|---|---|---|
| the open field | 1-5, cols 1-13 | `haze` | no interior walls at all; two benches standing apart in it, the leftover already out in the room |
| the cut | 6 | `seam` | one gap, one cell wide, the only way through; the two halves of the wall stand beside it as the two benches |
| the crossing | 7-8 | — | where the three onward choices are offered at once |
| two severed lanes | 9-14, cols 3-4 and 10-11 | `twin` | dead ends, wall between, no path from one to the other |
| the sealed cell | 10-13, cols 6-8 | `core` | one door, walls a metre taller than anything else, exit at the back |

Wall heights escalate with the enclosure: shell 2, the cut wall and the inner block
3, the sealed cell 4. The visitor's own freedom of movement shrinks in step with the
artifact's answer about where the leftover goes, and by the end they are standing
inside the sealed body, which is where the thing in `schrodinger_box` has been the
whole time.

Each value gets a different *spatial relation*, not a different plinth in a line:

- `haze` is scattered — two benches with nothing between them, at (col 5, row 2) and
  (col 10, row 3). You cannot see both faces at once and you have to circle the
  second one to read it, because it is turned into the field.
- `seam` is flanking — you pass between the two, one cell apart, forced.
- `twin` is severed — the two are 20 cells apart by the only available path,
  measured with `map_pathfinder.bfs_path`, though they sit 8 cells apart on the plan.
- `core` is flanking again, and that repetition is the instrument (below).

## The placements

```
(col 5,  row 2)   remainder_box:180:0#remainder:haze#keeping:none
(col 10, row 3)   remainder_box:270:0#remainder:haze#keeping:room
(col 6,  row 6)   remainder_box:90:0#remainder:seam#keeping:vault
(col 8,  row 6)   remainder_box:180:0#remainder:seam#keeping:dial
(col 3,  row 12)  remainder_box:90:0#remainder:twin#keeping:none
(col 11, row 12)  remainder_box:180:0#remainder:twin#keeping:dial
(col 6,  row 11)  remainder_box:90:0#remainder:core#keeping:vault
(col 8,  row 11)  remainder_box:180:0#remainder:core#keeping:dial
```

All four values of both axes appear. Every word is taken verbatim from
`commons/artifacts/registry/remainder_box.json` `dna.axes` and checked back out of
the finished `map_data.json` against that file; both axes are word enums with String
defaults, so the numeric-shorthand trap in `GridInteractablesComponent`
(`key:<number>` is eaten as a rotation) cannot fire here, and that was asserted
rather than assumed.

## The walkable null

**`remainder:core#keeping:vault` at (col 6, row 11) and `remainder:core#keeping:dial`
at (col 8, row 11)** — the two benches in the sealed cell, flanking the aisle.

They are identical, and not approximately. At `core` the bench builds one opaque
body spanning |x| <= 0.192, y 0.030 to 0.362, z -0.019 to 0.116. The instrument bay,
which is the only place `keeping` draws anything for these two values, lives at
|x| <= 0.096, y 0.044 to 0.116, z <= 0.014 — entirely inside that volume, on every
axis. Neither value draws flecks; both take the flat branch of the screen. So the
two are the same object in the room, from every standpoint in it. This is stronger
than the null on the sheet: the sheet's null is one camera at yaw 0.62 reporting
0.000%, and the standard rescue for a dead reading in this programme is to walk
round and look from somewhere else. Here that move is available, free, and useless.

**How a visitor could notice.** Only by having walked. The room makes them walk the
same figure twice. At the cut, two benches one cell apart with a one-cell gap
between them, `vault` on the left at rotation 90 and `dial` on the right at rotation
180. In the cell, seven rows later, two benches one cell apart with a one-cell aisle
between them, `vault` on the left at rotation 90 and `dial` on the right at rotation
180. Same spacing, same handedness, same two rotations, same body movement. At the
cut the left one wears a gold seal across a closed face and the right one shows two
lamps, one lit blue and one dark. In the cell, at the same left and the same right,
there is nothing. The difference is in there; the reading has made itself unable to
show it. A visitor who never crossed the cut has no way in at all, which is why the
cut is the only door.

There is a second, near-null to find: `twin` `none` at (col 3, row 12) against
`twin` `dial` at (col 11, row 12). Those two differ by exactly two lamps, 42.521
cm2, the registry's own predicted floor of 0.2541% — and to compare them you walk
twenty cells back out through the corridor, because the lanes do not connect. That
is the wall down the spine of the case, at body scale.

## What the room is for, stated as geometry

`schrodinger_box` ships `core` as its default. At that value it builds an opaque
0.4 x 0.3 x 0.3 box at the origin with a 0.12 m glow sphere at the same origin —
interior half-extents 0.20/0.15/0.15 against 0.12, so the superposition is entirely
enclosed — and `_process()` animates the alpha and emission of a mesh no camera can
reach. The artifact's whole subject is invisible in the value every map shows.
`remainder_box` keeps that meaning of the word on purpose.

This room is where a visitor can find that out, because it puts the sealed reading
and three open ones inside one walk. The sealed one is not hidden away as an error;
it is given the best room in the plan and the exit is behind it. That is the honest
version of the claim: the classical-ignorance reading is not stupid, it is
unarguable-with from outside, and standing in a small tall room with two objects you
cannot tell apart is what unarguable feels like.

Follow `dial` for the other thread. It appears three times — at the cut, in lane B,
in the cell — the record always open and always readable, and it never once changes
what the screen above says. At the cut the screen is flat and so is `vault`'s. In
the lane the screen was already flat because of the wall. In the cell you cannot see
the instrument at all. A record kills interference by existing, not by being read,
and the room says it three times in three different rooms.

## Decisions and their costs

- **No wall text, and the absence is load-bearing.** A label on the two core benches
  would tell you they differ, which is the one thing that reading cannot tell you.
  The museum would be doing what the artifact says is impossible. Cost: a visitor
  who does not walk the cut carefully gets much less, and there is no recovery.
- **The lanes are dead ends.** Cost: they can be skipped entirely, since the cell
  door at (col 7, row 9) is straight ahead from the cut. Kept, because a lane you
  can pass through is not a branch.
- **The exit is inside the sealed cell**, on void at (col 7, row 13). You leave the
  museum through the reading that shows you nothing.
- **The bench carries its own 0.62 rad yaw** (35.5 degrees, `FACE_YAW`), built so
  its front face squares to the capture rig. In a room that means every bench stands
  35.5 degrees off the grid and none of them is square to any wall. Not corrected:
  rotations here are cardinal, so each face addresses its approach to within a
  quarter turn and the visitor has to move to read it square. The artifact refuses
  to be lined up, which is convenient for a room that was never going to be a
  specimen row, but it is the capture rig's fingerprint on a piece of architecture
  and worth naming.
- **Only 8 of the 16 cells are hung.** The other eight are not here. A room is not a
  sheet and should not try to be one; the sheet already exists.
- **Not run:** no Godot, so nothing here has been seen. Every geometric claim above
  is read out of `remainder_box.gd` constants and the registry, and every
  reachability claim out of `tools/map_pathfinder.py`. The room has been validated,
  not walked.

## Sequence role

Not curriculum content yet — a wave 23 hanging, not a lesson slot. `remainder_box`
declares `map_sequences: [foundationscrisis]`, and this room would sit alongside
that sequence's quantum material rather than inside its teaching order.
