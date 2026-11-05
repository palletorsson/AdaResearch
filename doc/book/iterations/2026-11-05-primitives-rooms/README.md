# Four rooms for the Primitives floors (2026-11-05)

Palle, in one message: *"In the primitive profile add a table with cone and column parts that we can stack on to
each other and that snaps so we can make form. Move the point line example to a large box around the shaft with a
floor, fully black inside, the measure text on the wall large, use two with a ball in the middle as balls, it should
be like the point room in the museum but larger. Add in primitives melancolia add a box around the durer painting
sculpture with an open front wall so we can see the work but add a grid in front the setup like in durer grid study
but larger. In point thrace add a 4 meter high and 8 meter long grid standing in a large frame."*

Asked which shaft and which museum room: *"we should just do the add point together as a making the line"*, *"this
should be like the room pairing_point_field"*, and, on finding that shaft A on floor 3 already carries the scaffold
workstation's glass bay: *"turn that box black"*.

Four artifacts, all in `commons/artifacts/primitives_rooms/`, registered in `registry/primitives_rooms.json`, placed
by `tools/place_primitives_rooms.py`, checked in the real tower by `tools/test_primitives_rooms.py`.

## Floor 3, Point_Lines: the point room (`point_line_room`)

The scaffold workstation's glass bay over shaft A — 6.6 m square, 5.4 m tall, a gridded floor over the hole — gets a
**black lining**: floor, back, two sides, ceiling, and a front with a 1.6 m doorway. Inside hang the pairing field's
points at room size: eight large pale balls, lettered A to H, at reach height round the walls, clear of the bay's
middle and of the workstation's visitor start.

Bring two close and let go: they **join in a line** — the snap-point system of `pairing_point_field`, the same
manager and the same points, only larger (snap distance 0.4 m instead of 0.28). Move them apart and the line follows.
The back wall writes what the room measures: the newest line, large — `A - B / 0.25 m` — and the older ones under it.
Before any line it says *A LINE IS TWO POINTS BROUGHT TOGETHER*.

The lining is only seen. It adds no body inside the bay but the front wall beside the doorway (at the bay's edge,
outside the workstation's 6.4 m clear), so BUILD, the drop test and the quarter-size visit find the bay as they did.
The workstation's glass gate, closed by default, is opened, so a visitor walks in at full size. The museum's
`two_points_line` moves into the room.

Palle asked for a box *with a floor*. In the bay the glass base is that floor — but the workstation stands only in
the working tree (Codex's, uncommitted), so on a floor without it the room would be over the open shaft. The room
gives a floor 60 frames to appear under its middle; if none does, its own floor panel becomes solid.

## Floor 4, Point_Trace: the standing grid (`standing_grid`)

Dürer's drawing screen (`dgrid`, a wire net in a frame a metre across) at the size of a wall: a net of strings half a
metre apart, 8 m long and 4 m high, in a heavy timber frame — two posts, a head beam, a sill — standing on two feet
at the hall's west end. The strings are only seen, never touched: a hand passes through, as through a veil. The frame
is solid.

## Floor 12, Primitives_Melencolia: the box, the grid and the sight (`durer_box`)

The sculpture after Melencolia I (the hall's `MelencoliaEngraving` part: figure, dog, sphere, polyhedron, ladder,
scales, the magic square) stands in a **box of three dark walls** to the ceiling, its front open toward shaft A. In the
opening stands a grid at the opening's size — the standing grid again, 7.4 m by 4.6 m, feet off, its posts on the
walls' ends. Across the shaft, on the slab a visitor can stand on, is **Dürer's sight**: a post with a small eye-piece
at 1.6 m and a line on the floor, *PUT YOUR EYE TO THE SIGHT / THE GRID CUTS THE WORK INTO CELLS*. It is the
draughtsman's set-up of the 1525 woodcuts, turned round: the grid is the instrument, the engraving the model.

Three museum works moved out of the walls' way: `eleven_dots` north to (−18, −6.4), `snap_pyramid_puzzle` to
(−12.2, −5.2), and the two `bigframe`s — boxbeam portals 2.3 m across, their width along z — south-west to (−17.5, 4.5)
and (−16, 4.5), 0.43 m off the wall face, their pair and orientation kept.

## Floor 9, Primitives_Columns: the form table (`form_table`)

Palle, after the first placement on Profiles: *"sorry the form table should be in 09 columns"* — the colonnade, where
yesterday's cone assortment stands among the columns; the table's parts are that floor's own forms. The candidates
probe, pointed at the north strip, found the nearest clear spot inside the grove itself: (3.5, −1.5), turned along z,
between the cone columns at x 1.7 and 5 — the table stands among the cones it is made of. The floor-10 entry is removed.

A table set with 16 loose white parts turned from profiles — square bases, drums and tall drums (a
straight profile), cones and a spire (leaning in), funnels (leaning out), capitals (a short flare) — and an example
column of five at one end. Each part is held as a hand holds anything (XR Tools pickable; the desktop grab too).

The snap rules:
- let go with its foot within 8 cm of another part's top centre and within a hand's height of it, the part **snaps**:
  stood upright, centred on that top, and it stays;
- let go over the table, it stands where it is let go;
- let go anywhere else, it falls;
- lifting a part lifts everything stacked on it — a column comes away whole — and setting it down snaps the bottom
  of it, the rest riding along.

## Evidence

`python tools/test_primitives_rooms.py` — the actual Void, windowed, each work photographed. Three runs: **15/17**
(two failures were the probe's own reading errors, below), **16/17** (the repaired clash check caught the two
`bigframe`s in the south wall), **17/17** at 10:24 after they moved, and **17/17** again at 13:41 with the table on
floor 9. No script errors in the last runs.

- Floor 3: the lining's five panels stand, a solid floor is under the room (the bay's), the gate opened; eight points
  hang, none in the bay's middle. Point B let go 0.25 m beside A joins it; the wall reads `A - B / 0.25 m`; moved
  1.55 m apart it reads `1.55 m`. The two-points line stands inside the room.
- Floor 4: a net 8.0 × 4.0 m of 22 strings in a frame — a ray meets a post, a ray through the net meets nothing.
- Floor 9: 21 parts; the example column stands as a stack of five. A drum let go 6 cm over the column's top, tilted,
  snaps onto it: centred to under 2 mm, upright, frozen. Lifting the base lifts the stack of five with it; let go over
  the table they stand again. A cone let go beside the table falls.
- Floor 12: the sculpture stands inside the three walls in plan (it is 5.70 m tall, taller than the 5.55 m walls, and
  the box has no roof); the grid stands in the open front, the sight 6.6 m across the shaft at 1.6 m, on solid slab
  0.4 m past the hole's edge; the route keeps 0.3 m off the walls and no other work stands in them.

Pictures in `ada_run/primitives-rooms-tower/desktop/` (local, not in git): `03_point_room`, `04_standing_grid`,
`09_form_table`, `12_through_the_grid` (from the sight's eye-piece: the engraving in cells), `12_box_and_sight`.

## Traps found on the way

- **rooms.json was rewritten under the tool.** At 10:00 another writer left the shared file with CRLF line endings
  for a few minutes; the placement tool's round-trip guard refused to write, correctly. By 10:09 it was back in its
  own format (LF, UTF-8, indent 2) and the apply went through. The guard is the right behaviour: wait and re-read,
  never reformat someone else's file.
- **The editor nudges positions.** `eleven_dots` stood at (−18.0279, −4.4167), not the (−18.0, −4.4) the plan named,
  so a 1 cm match skipped its move. The tool matches within 20 cm now, and has `--moves-only` so a missed move does
  not cost another probe run.
- **Codex's workstation is not in HEAD.** The room was designed to live in its bay; committed alone it would have had
  no floor over the shaft. Hence the own-floor fallback.
- **`SnapConnectionManager.get_connections_for_point` cannot be called.** It returns an untyped Array where it
  declares `Array[Node3D]`; Godot refuses the return at runtime (a SCRIPT ERROR on every call). The line was drawn,
  but the wall never measured it. The room reads its graph pair by pair through `are_points_connected` instead. The
  manager is a shared file; not touched.
- **`mesh_bounds` answers in the host's frame.** The probe compared hall-local bounds with world walls, so the
  enclosure check failed on a correct box and the clash check passed vacuously. Multiply by the host's
  `global_transform`. (`tools/probes/unit_drones_tower.gd`'s floor-36 clash check has the same flaw — a follow-up.)
- **A declared footprint of 1 × 1 can be 2.3 m wide.** The `bigframe`s' registry footprint is one cell; the portal
  is 2.3 m across and `museum_yaw 90` lays that along z. Moved to z 3.6 by the footprint, they still cut the wall by
  half a metre — caught only once the clash check compared world bounds. The scout's declared-footprint map is for
  finding room, not for proving it; the tower probe's mesh bounds are.
- **The forum ask posted twice** (261105-pfcm1 and vkn2g — server and file fallback both took it). pfcm1 is settled
  as the duplicate; Codex is asked on vkn2g whether the opened gate and the lining change anything for the
  workstation.

## Open

- Codex's `scaffold-workstation` on floor 3 is uncommitted; the point room's bay is theirs.
- Forum 261105-vkn2g awaits Codex.
- Nothing here is committed.
