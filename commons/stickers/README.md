# Stickers in VR (the Godot side)

Palle asked (2026-11-13) for a sticker app that works in SVG, in three.js and in VR. This folder is the VR part. The
encyclopedia's `/stickers` page is the other two (Design and Board in SVG, 3D in three.js). All three draw the same
stickers from the same files and change them through the same ops.

## One truth, three media

| file (game repo) | what it holds | who writes it |
|---|---|---|
| `commons/data/stickers/designs.json` | what a sticker looks like: a vector model of layers plus the SVG string derived from it | the encyclopedia (`POST /api/stickers` with `doc: designs`) |
| `commons/data/stickers/boards.json` | the flat boards every medium draws (`visitors` 1.6 x 1.0 m; `research` and `readings`, 2.4 x 1.36 m) | the encyclopedia (`doc: boards`) |
| `commons/data/stickers/placements.json` | where every sticker is, its state and who stuck it, plus the op ids already applied | the encyclopedia only, through ops (`POST /api/stickers/ops`) |
| `commons/data/stickers/readings.json` | AUTHORED: the paradoxes and punctums read out of the texts, each with its verbatim quote, file and lettering | by hand; `tools/stickers_seed.ts` checks every quote is still in its text |

The starter designs are DERIVED, never typed into designs.json: `tools/stickers_seed.ts` (run with the encyclopedia's
`node_modules/.bin/tsx`) builds them by `sticker-starter.ts` from the project's own files - the transition cards from
`commons/modular/terms.json`, one RESEARCH badge per spine sequence from `curriculum_spine.json` and the sequence files,
and the PARADOX and PUNCTUM readings from `readings.json` - and `--check` exits 1 when designs.json is not what the
rules derive. A reading whose quote has left its text (in order, each piece inside one paragraph), whose lettering says
more than its quote, or that cannot be drawn stops the seed before it writes anything; a starter design that a sticker
still uses is kept, marked `retired`, never dropped. `--research-board` and `--readings-board` lay those sets on their
boards once, each new sticker in the grid's first free slot.

The rules live in `ada_encyclopedia/src/lib/stickers.ts`. `sticker_data.gd` ports the parts the game needs: `basis`,
`drawBox` / `extent`, the turns (`refUp`, `turnOf`, `upAtTurn`, `allowedTurn`, `allowedUp`, `boardTurn`, `upForTurn`),
`settle`, `RESIDUE`, `hostKey` and `applyOps`. Change one, change both. The game never writes the truth. It reads it,
applies its own ops over it the same way the server does, and posts those ops.

The ports that decide what is stored (the turns, `settle`, `apply_ops`) work in double precision on `[x, y, z]`
Arrays, never in `Vector3`, whose components are 32-bit. They also do the arithmetic in the server's order: `Math.hypot`
and `Math.round` as V8 computes them, and degrees as `(rad * 180) / PI`. A turn that lies exactly between two quarter
turns therefore snaps here the way it snaps on the server. `basis()` and `extent()` on `Vector3` are for drawing.

Every medium draws the SVG string stored in the design. Its viewBox is the DRAWN box: the design box grown by the
die-cut margin, so the white border is part of the picture. Godot rasterises it with ThorVG
(`Image.load_svg_from_string`) at 256 px on the long side, mipmapped, once per design. ThorVG draws no `<text>`, so
lettering is always paths (`sticker-alphabet.ts`). Whether the browser and ThorVG draw the same picture is a separate
check, `tools/sticker_parity.py` (headless Chrome against headless Godot, every design, with a negative control).

## Frames: where a sticker is

A placement is a projector record in a HOST frame: `at` (a point), `n` (out of the surface), `up` (on the surface),
`size` (the long side, in the host frame's units) and `z` (stack order). `right = up x n`. The sticker spans
`extent(design, size) = [w, h]` along right and up. That is the drawn box with `size` on its long side, so a stuck
sticker is the size of the printed one, border included.

| host | frame | in Godot |
|---|---|---|
| `{kind: board, id}` | the middle of the board's face, x right, y up, z out. A sticker on a board lies on the face: `n = +Z`, `at.z = 0` | the `Face` StaticBody3D of `sticker_board` |
| `{kind: primitive, id: box\|sphere\|cylinder\|slab}` | that primitive's centre on the bench (BENCH in stickers.ts) | each primitive's StaticBody3D in `sticker_bench` |
| `{kind: void_work, floor, work, body?}` | the frame of the work's exported GLB | `Artifact.global_transform * Transform3D(Basis(UP, deg_to_rad(-museum_yaw)))`, `museum_yaw` from the rooms.json row's config, 0 when absent |
| `{kind: void_floor, floor}` | the `Floor<i>` node | `Building/Floor<i>` |
| `{kind: artifact, token}` | a registry artifact | three.js only |

Void hosts are keyed by NAME: `floor` is the floor's map name and `work` is the rooms.json id. They are never keyed by
floor index, because indices shift when a floor is inserted (one was inserted at 18 on 11-09). Sizes are in the
frame's units, so a sticker on a work scaled 1.5 grows with it, as paper on it would.

## One meaning of a turn

A turn is in degrees, counter-clockwise seen from in front of the surface. A turn of 0 has its up along the host's
`+Y` laid onto the surface (`refUp`). On a surface that faces up or down by more than 45 degrees (`|n.y| > POLE`), the
reference is the host's `-Z` laid onto it: on a table top, away from the bench's front. `turnOf(n, up)` reads a turn
and `upAtTurn(n, deg)` writes one. On a board (`n = +Z`) these are `boardTurn` and `upForTurn`.

A design with `turn: snap90` (the pink triangle) keeps only quarter turns of this frame, and a `fixed` design keeps a
turn of 0 (`allowedUp`). Every medium snaps against the ROUNDED normal it stores, and the server snaps again in
`settle()`. A record therefore reads as the same quarter turn on the SVG board, in three.js and here. Godot rounds the
way V8's `Math.round` does, so -45 degrees snaps to 0 here as it does on the server, and 45 snaps to 90.

## Ops, and what they promise

`add`, `move`, `peel`, `restore`, `note` and `front` are the only ways a placement changes. Each op has an `op_id` that
is applied once: a replayed outbox or a retried POST is skipped, never doubled. An op on a sticker that does not exist,
or a move of a peeled sticker, fails alone. Every `add` and `move` is settled (`settle`): on a board it is put on the
face, and a design that may not turn freely is snapped.

- **A peel is an event.** The sticker stays, with `state: peeled` and `peel: {by, t}`. It is drawn as RESIDUE (stickers.ts
  `RESIDUE`): its silhouette, which is the art's alpha including the border, in one flat colour `#c4bba6` at 0.42 of that
  alpha. It is always drawn beneath the stickers that are on, and it is never deleted. Godot takes the colour as a
  `source_color` uniform, so it is converted from sRGB. The first residue wrote a raw `ALBEDO`, which Godot reads as
  linear, and measured -0.5 grey levels against the board's paper: a peel looked like a deletion. The probe now
  measures the residue 20 grey levels darker than the paper (check D).
- **Every sticker records who stuck it** (`by`). From Godot that is `vr:` plus a short device name: the headset's model
  on Android (for example `vr:quest_3`), the system's name elsewhere (`vr:windows`). Host names are deliberately not
  used.
- **Nothing is counted.** There are no likes, tallies or leaderboards.

## The outbox (`sticker_data.gd`)

```
user://stickers/outbox.json   {version, device, pending: [{by, t, op}], sent: [...], refused: [{by, t, op, error}]}
```

1. A sticker stuck here is written as the server will store it (`server_pose`): cleanOp's rounding, then `settle`,
   repeated until nothing moves. It is applied at once by the shared rules, so it is drawn straight away, and what is
   drawn before the answer is what the truth holds after it. The op is written to `pending` (tmp + rename) and posted.
2. **POST** `{by, ops}` to `VOID_EDITOR_URL`, or `http://127.0.0.1:3003` when that is unset, at
   `/api/stickers/ops`. At most 200 ops go in one POST, all with one `by`. If it fails, the ops stay and the retry waits
   5 s, doubling to 60 s.
3. When the server answers **ok** or **skipped**, the op moves to `sent`. It stays there, still drawn, until the truth
   read here lists its op id in `applied`. On a desktop the server has written the repo file before it answers, and an
   answer carrying a newer revision makes this node read the file again at once. On a Quest it waits for a newer
   truth. So a sticker stuck in the headset never vanishes after its op is posted.
4. When the server **refuses** an op, it moves to `refused` with the reason. It is no longer drawn and never retried.

The files are watched once a second. A document is read again when its mtime changes, and for two more ticks after
that, because mtime counts whole seconds. It is applied when its text changed. `reload()` (group `sticker_data`) reads
everything at once, so a bridge that has just written a newer copy can call it.

**The headset copy.** On Android `user://stickers/<doc>.json` is read too, but only when its integer revision is
HIGHER than the shipped one. A stale copy can therefore never hide a newer truth. Nothing writes that copy yet (see
below).

**Tests.** `configure({data_dir, outbox, post, copy_dir, by, url, sandbox})` points the node elsewhere, and it fails
closed. A node pointed at a COPY (any `data_dir` that is not the truth once both are globalized and simplified - the
truth's folder spelled another way is the truth) stops posting and keeps its outbox beside the copy. It posts again
only with an explicit `post` true (the bool or the text `"true"`) AND a `sandbox`: a test's copy of the truth under the
encyclopedia's `ada_run/stickers/sandbox/<id>/`, named on every POST as `?sandbox=<id>` so the route writes that copy.
A blank or malformed sandbox turns posting off; only a node on a copy may name one; an outbox may never live in the
truth's folder; and the outbox remembers its sandbox, so an outbox written for another sandbox is not loaded and a
test's ops can never reach the truth in a later session (`pull_vr_stickers.py` skips such an outbox too). A test must
never post to the real route or write the real truth, not even to "restore" it afterwards. Nothing here ever writes the
truth.

## Drawing (`sticker_layer.gd`)

A StickerLayer draws the stickers of ONE host, under that host's node, and its own transform IS the host frame.

A sticker is a PROJECTOR, as three.js's decal is (`sticker-decal.ts`): a box `extent(design, size) = [w, h]` along right
and up, and `DEPTH_RATIO` (0.5) times the long side along `n`, centred on `at`. It prints the picture by an orthographic
projection along `-n` on the host's surface inside that box that faces `n` by at least `MIN_FACING` (0.2). Where the
layer knows the host's body it prints exactly that. The body is the layer's `surface`, which the bench sets for its
sphere and cylinder; for a board or a bench primitive without one, it is the box of the body's own collider (the
board's Face, the bench's box and slab).

- **Curved** (the sphere, the cylinder's side): one ArrayMesh per design (`Curved_<design>`), each sticker a GRID over
  its layout. Each grid point `(u, v)` is carried along `-n` onto the body, where the projector puts it. Cells past the
  projector's depth or facing `n` by less than `MIN_FACING` are cut away at that boundary, which is found on each cell's
  edges, and the cylinder's side ends at its rims. Every vertex is then lifted along the body's normal there, which
  also lights it. The grid has enough cells that none spans more than about 0.07 rad where the print is steepest (8 to
  32 a side), so a chord sags under 0.4 mm. Held against three.js's own decal on the bench's `SphereGeometry(0.3, 96, 64)`
  and `CylinderGeometry(0.22, 0.22, 0.6, 96, 4)`, matched by the picture's UV, the same point of the picture lands at
  most 0.33 mm apart (0.18, 0.25 and 0.4 m, on the front and 50 degrees up the sphere, on the cylinder's side and by its
  rim), and the two agree on which corners and edge middles are printed: at 0.4 m on the sphere neither prints the
  corners, which lie past the depth. Until 2026-11-13 the grid was laid along the body's normals instead: the same
  points were up to 11.1 mm apart at 0.18 m, 29.4 mm at 0.25 m and 54 to 64 mm at 0.4 m, and Godot drew corners
  three.js does not print (check U2; `tools/probes/stickers_fix2_parity.gd` dumps the grids for such a comparison).
- **Planar** (a box's six faces, the board's face, the cylinder's two caps as a 96-gon, as three.js's bench cuts them):
  the face clipped by the projector's box (DecalGeometry's six planes), so a sticker ends at the edge of its face. A
  sticker that lies whole inside one face is the plain quad below, which is most of them. One cut at an edge is a mesh
  (`Clipped_<design>`). A 0.25 m sticker by the edge of the bench box's top or the cylinder's cap used to be a flat quad
  standing 7.5 and 8.2 cm out in the air past the body (check U3).
- **Flat** (Void works and floors, whose bodies the layer does not know, and a sticker the body takes no ink from, which
  three.js shows as unseated): one MultiMeshInstance3D per design (`Stickers_<design>`). Each is a shared 1 x 1 QuadMesh
  scaled per instance to the drawn box. The basis columns are `right * w`, `up * h` and `n`, and the origin is
  `at + n * lift`.
- **The stack.** A sticker stuck later (higher `z`) lies over every earlier one it overlaps. Its lift is 2 mm, or one
  step over the highest of the earlier live stickers whose drawn footprint overlaps its own; footprints are boxes in
  each sticker's own right, up and n, tested by separating axes. A step is 0.1 mm between flat prints and 0.5 mm where
  either is a grid, which is more than any grid's sag (at 0.1 mm an earlier sticker showed through a later one on the
  sphere). A pile climbs at most 6 mm, so the cap is met only by a chain of 60 overlapping flat stickers or 12 curved
  ones; past it they share the cap's lift, as every sticker past the cap did before. Stickers that do not overlap all
  lie at 2 mm. Until 2026-11-13 a sticker's place was its index among all the live
  stickers of its host: from the 61st on a board and the 13th on the sphere every sticker shared the cap's lift, and two
  overlapping ones there were drawn at one depth. On the sphere they pierced each other; on a board the earlier one
  covered the later (checks X and X2). three.js orders its decals by rank, with no cap. The test is quadratic in a
  host's stickers.
- Each design has one StandardMaterial3D, shared by every layer: the design's texture, alpha scissor 0.5 with alpha to
  coverage, back faces culled, lit by the room.
- Peeled stickers go in `Residue_<design>` (or `CurvedResidue_<design>`, `ClippedResidue_<design>`), drawn with the
  residue shader at 1.2 mm.
- A board sticker is drawn on the face whatever an older record says. One written on the back before the server settled
  ops (`n = -Z`, `at.z = -0.03`) shows on the face, where `settle()` would store it (check Q2). three.js does not do
  this: its board host is the face plane only, so such a record gets no decal there, and its 3D view lists it as
  unseated and draws it as a translucent quad at its own back pose. The truth holds no such record: every board record
  has `n = [0, 0, 1]`.
- The layer has no `_process`. It redraws on `placements_changed` / `designs_changed`, and only when its own stickers
  changed. A floor's residency pauses and hides it with its floor at no cost.

## The pad (`sticker_pad.gd`, worn)

The pad follows the tape roll's WORN contract exactly (`wear`, `put_away`, `fire_worn`, `release_worn`, `apply_config`,
`apply_grid_config`, `worn_on`, `worn_active`), so the inventory's wand forwards the trigger with no change to the wand.
In VR that is the right controller's trigger. On a desktop it is the left mouse button or F, through the camera.

- **Aim:** along `worn_on`'s -Z, up to 4 m. The ray skips the UI (layer 23), held things (17), the hands (18) and the
  body (20). The pad draws its own ghost and its own aim line, because the wand draws neither for a worn item. The ghost
  is the selected sticker, translucent, where it would go, as the server will store it, red when refused with the reason
  in words under it (on a body the layer knows it is printed like the sticker: Ghost, below). The words are 2 cm letters
  at arm's length and grow with the distance from the eye. They once kept the 0.4 scale the pad is worn at and were
  drawn at 0.4 of that size (check Z).
- **Tap** (< 0.3 s) on a surface: **stick**. This is an `add` op. The host is the first that applies: a node with meta
  `sticker_host` (the board, the bench), then a Void work (its mount), then a Void floor (its slab, walls and props),
  else the tap is refused. A board takes a sticker on its face only. The `Face` body's box collider also answers a ray
  from behind, and that hit is refused with "THE BACK OF THE BOARD" (check Q). An accepted one is sent with `n = +Z`
  and `at.z = 0`.
- **Hold** (>= 0.3 s) on a sticker: **peel** it (the top sticker under the aim; on a body the layer knows, the one
  whose print covers the aim point: inside its projector's box, on a surface facing it).
- **Tap at nothing:** the next design of the sheet.
- **Turn:** in VR the right wrist's twist (twice the roll, in 15 degree steps, as the prism turns a prefab). On a
  desktop Q / E, with Shift for a quarter turn. The turn counts from the contract's zero (`refUp`, above), against the
  rounded normal the op carries, as three.js's `newPose` counts it: on a wall the host's `+Y` (world up for an upright
  host), on a floor or a top (`|n.y| > POLE`) the host's `-Z`. A design that may not turn freely keeps only the quarter
  turns of that frame. So a first stick reads the same turn in every medium: aimed at turn 0, the free heart and the
  pink triangle read turn 0 on the bench box's top from two places whose readers' zeros are 73 degrees apart (check
  S), and on a sideways slope 53 degrees from vertical, `n = (0.6, 0.8, 0)` (check S2). Until 2026-11-13 the pad started
  from a reader's up instead: world up laid on anything steeper than `|n.y| < 0.9`, away from the eye on a floor or a
  top. The pink triangle then landed at turn 90 or 0 on the box's top depending on where the person stood, and at 90 on
  that slope, where three.js starts it at 0.
- **Ghost:** on a body the layer knows it is printed like the sticker (laid on the sphere and cylinder, cut at a box
  face's or a cap's edge); elsewhere it is the quad.
- **Config:** `sheet` (a sheet id of designs.json; `""` means every design), `sticker` (the design to start from),
  `size` (`design` or 0 means the design's own `size_m`; otherwise metres) and `reach`.
- The pad also builds a small sheet of stickers (the next design, large, and the two after it). The inventory shows it
  as the hand's miniature, and the association plinth holds it as its example.

## In the Void (`sticker_world.gd`)

One node, made by one gated line in `game.gd` (see "Switched on from outside this folder"), hosts the `void_work` and
`void_floor` stickers:

- **A work's layer** is a child of the work's MOUNT (`Building/FloorContent/Content<f>/<work id>`) with
  `transform = Artifact.transform * R_y(-museum_yaw)`. It is never a child of current_scene, and never of the Artifact,
  since a procedural work frees its own children. Residency then hides, pauses and wakes it with the work.
- **A floor's layer** is a child of `Content<f>` in the `Floor<f>` frame, so a sticker on a wall or a prop hides with
  the floor's content.
- **Hosting and re-hosting** happen on `artifact_built` and `floor_changed` from floor_content.gd. That covers
  `reset_floor`, a trial reset and a live-update rebuild, which all come back through those signals. It also happens on
  any change of the placements. A layer added to a floor that is not live is handed to that floor's residency
  (`floor_stream.records[f].adopt(layer)`). Emitting `floor_changed` instead would re-walk the whole floor.
- **Naming a work for the pad** (it asks every physics frame while it aims at one). The key `<floor>/<mount name>` comes
  first, because a mount is named by its id. Next is a cache by the mount's instance id, checked against
  `floor_content.exhibits`. A scan of every exhibit runs only when both miss: an id holding a character a node name
  cannot, such as `.`. The scan's answer is then cached. With 2001 exhibits held a call costs the same as with two (13.7
  against 13.8 us; it was 287 against 11 us when it always scanned). `StickerWorld.lookups` counts each road (check T).
- A host that is gone (a work removed) keeps its stickers in the truth, and they are drawn again when it comes back.
- Without a StickerWorld (the hook not in), the pad refuses Void surfaces with "THE VOID'S STICKERS ARE NOT ON HERE",
  so nothing is stuck that nothing would draw.

## The board and the bench (artifacts)

- `sticker_board` (config `board`, default `visitors`) is the board's w x h in its paper colour, with a thin timber
  frame, a stand and its title. The `Face` StaticBody3D is the board's frame. Its box collider's front is exactly the
  paper (z = 0, not proud of it). It carries meta `sticker_host` and the StickerLayer. The frame and the stand are
  bodies without a host. The timber laps 3 mm over the paper's edge: flush, the paper's sides and the timber's inner
  faces were the same planes and fought. The origin is on the floor under the middle, facing +Z, with the face centre at
  1.35 m.
- `sticker_bench` is the table and four primitives at the numbers of stickers.ts `BENCH` (copied, with a comment saying
  so). Each primitive is its own host and frame. The sphere and the cylinder carry their analytic body (meta
  `sticker_surface` `{shape, r[, h]}`, the same as their layer's `surface`), so their stickers are laid on the curve and
  the pad picks them there. The box and the slab carry none: their layers, like the board's, take the box of the body's
  own collider, so a sticker there ends at the edge of its face.

Both are in `commons/artifacts/registry/stickers.json`, with the pad's token `sticker_pad`.

## Checks

- **Compile:** `godot --headless --path . --xr-mode off --script res://commons/testing/check_compile.gd -- --files=...`.
  The non-console exe prints nothing to a pipe, so add `--log-file <path>` to read the verdicts.
- **The probe** (windowed, because headless draws no frames and reads MultiMesh data back as identity; `--no-bridges`
  keeps NatureRenderer from painting fog over the pictures):
  `python tools/godot_watchdog.py --expect=ada_run/stickers/probe/probe_result.json --grace=120 --stall=60 -- <godot> --path . --xr-mode off --resolution 1280x800 --position 3200,3200 res://commons/testing/probe_stickers.tscn -- --no-bridges`.
  It works on a COPY of the truth in `user://stickers_probe/` (or `--probe-dir=user://<folder>`, one per run) with
  posting off, and it checks at the end that the real
  files and the real outbox are untouched. It covers the board, the drawn box, the bench, tap, hold and peel, the residue
  seen in pixels, the back of the board, an older back-face record, the turn on a board, the first turn from the
  contract's zero on the box's top and on a sideways slope, the curve (sphere, cylinder, ghost), the watch, the headset
  copy rule, `reload()`, the worn contract, refusals, `configure()`
  failing closed, naming a work, and the ghost's words. It also stands a miniature Void: a work that is turned and scaled
  with a museum_yaw, a floor, a rebuild on a sleeping floor, and the outbox's reply rule against a fake answer. On
  hosts of its own, made from the layer under test, it checks the stack past its old cap on a board and on the sphere
  in pixels (X, X2), the print on a curve against the projector (U2) and a flat print cut at its face (U3, in pixels
  too). 34 checks on 2026-11-13, all passing. Pictures go to `ada_run/stickers/probe/` (or `--out=<folder>`). So does
  `pad_ops.json`: every op the pad made, with the sticker as this device drew it. `--layer-script=<path>` and
  `--pad-script=<path>` run the same checks on a scratch copy of an older `sticker_layer.gd` or `sticker_pad.gd`, to
  show which checks bite: on the code before 2026-11-13's second round the old layer failed X, X2, U2 and U3 and the old
  pad failed S and S2, and nothing else.
- **The print against three.js:** `tools/probes/stickers_fix2_parity.gd` (headless, `--script`, `-- --out=<json>
  [--layer=<path>]`) dumps the layer's curved print (`curved_mesh` at lift 0) for fourteen records on the bench's sphere
  and cylinder. A node runner from the encyclopedia puts the same records through `sticker-decal.ts` `stickerDecal` on
  the bench's geometries and matches the two by the picture's UV (the numbers are under Drawing).
- **The rules against the server's:** `tools/probes/stickers_apply_ops.gd` runs `StickerData.apply_ops` on a base and an
  op list (headless, `--script`, args `<base.json> <ops.json> <designs.json> <out.json>`). The same files through
  stickers.ts `applyOps` (the 10-line runner below, from the encyclopedia: `npx tsx <runner> <same args>`) must give the
  same document, number for number. On 2026-11-13 that held for 30 ops, 0 differences. They covered a board back-face
  add, snap90 on a box top including an exact 45 degree tie, snap90 under the box, a slanted normal at the pole, a
  `fixed` design on a top, a board and a sphere, and moves onto and off the board. The pad's own ops in `pad_ops.json`,
  put through the server's `cleanOp` then `applyOps`, came out unchanged by cleaning and stored exactly as Godot drew
  them (8 adds, 0 disagreements).

  ```ts
  import fs from 'node:fs';
  import {applyOps, cleanDesignsDoc, cleanPlacementsDoc, type Op} from './src/lib/stickers';
  const [basePath, opsPath, designsPath, outPath] = process.argv.slice(2), now = '2026-11-13T12:00:00Z';
  const base = cleanPlacementsDoc(JSON.parse(fs.readFileSync(basePath, 'utf8')), now).doc!;
  const designs = new Map(cleanDesignsDoc(JSON.parse(fs.readFileSync(designsPath, 'utf8'))).doc!.designs.map(d => [d.id, d]));
  fs.writeFileSync(outPath, JSON.stringify(applyOps(base, JSON.parse(fs.readFileSync(opsPath, 'utf8')) as Op[], 'vr:parity', now, designs)));
  ```
- **The round trip:** `python tools/stickers_roundtrip.py` (needs the encyclopedia's dev server on :3003) copies the
  truth into a sandbox, posts an add the way the page does, lets the game (`tools/probes/stickers_roundtrip.gd`) see it
  by its own file watch, then has the game stick one and post it, and reads it back from `GET /api/stickers?sandbox=`.
  Both halves refuse to run unless the server refuses an unknown sandbox with 422 in its own words (a server that
  ignored `?sandbox=` would write the truth); the truth is only read, its md5 the same before and after. 2026-11-14:
  web to game 0.6 s, game to web 0.1 s.
- **A headset's outbox:** `python tools/pull_vr_stickers.py` reads `files/stickers/outbox.json` over
  `adb shell run-as`, which needs a debuggable export, and posts its ops. Ops are idempotent by op id, so a pull after
  a live session doubles nothing. `--dry-run` says what it would post, and `--from-file <outbox.json>` reads a local
  copy instead of a device. The server settles what it is given, so an op from an older build that stuck on a board's
  back is stored on the face.

## Switched on from outside this folder

Three shared files do it. None is edited from here (forum thread 261113-pcs7b):

- `commons/data/inventory/items.json`: the item `stickers` (mount `worn`, token `sticker_pad`, knobs `sheet` - starter,
  research, paradox, punctum and the card families - and `size`). It has no `collect`, so it is unlocked at once and can
  be chosen on the prism's items face in VR or through the web page's hand (hand.json). The belt (left stick click in
  VR, Tab on a desktop) holds only collected items.
- `commons/void/rooms.json`: on floor 199 (`QFEP_Phi_Term`), the board (`stickers-board`), the research board
  (`stickers-research`, board `research`), the bench (`stickers-bench`), a caption, and the pad as a work
  (`stickers-pad`) on an association plinth beside the board
  (`stickers-pad-plinth`, config `item: stickers`, `holds: stickers-pad`). Picking the pad up from the plinth collects
  the item, which puts it on the belt, so a desktop player reaches it with Tab as a VR player does. The rows are read
  here, not walked: the probe stands the board and the bench but not the plinth.
- `commons/void/game.gd`: one line after the floor stream is configured. It makes the StickerWorld only in the main
  tower and only when `res://commons/data/stickers/placements.json` exists. It uses `load()`, not `preload()`, so a
  broken sticker script cannot stop the Void from compiling.

## Not done yet

- **The Quest's live leg.** On a standalone Quest, `res://` is the read-only pck, and `127.0.0.1:3003` is not tunnelled
  (`adb reverse` covers 8771 and 8772 only). The headset therefore sees the stickers it shipped with plus its own, and
  its ops wait in the outbox. The proposal (forum 261113-pcs7b) is a `stickers` branch in `live_update.gd` that writes
  `user://stickers/<doc>.json` and calls `call_group("sticker_data", "reload")`; this node already reads that copy
  when it is newer. It also proposes a `{k: sticker}` uplink in `vr_link.py`. Until then, `pull_vr_stickers.py` is
  the wire.
- **Only stick and peel in VR.** Move, restore, note and front exist as ops (and in the web views) but have no gesture
  here yet.
- **A busy curved host still breaks the stack (a re-check of 2026-11-14).** The lift is counted along chains of
  overlapping stickers and capped (60 steps flat, 12 curved). Flat hosts are fine at 200 stickers, but on the bench's
  sphere a chain of 13 forms after 30 to 40 random stickers on its front, and later ones then share the cap and pierce
  earlier ones (three.js orders by rank, with no cap). The fix the re-check proposes: order live stickers by rank as
  three.js does (one small fixed lift, no depth writes among stickers, drawn in z order), and a probe check of 60 random
  stickers on the sphere's front.
- **Redraw is slow on a busy host.** The overlap test is pairwise and `shape_of` is recomputed for every sticker on
  every change: 75 ms per stick on a board with 200, about 330 ms on the sphere with 140 (4 to 11 times the earlier
  layer); steady frames are unchanged. Cache per record, test a whole quad against its face before clipping, and bucket
  the footprints.
- **Curved Void works are flat.** Only the bench's sphere and cylinder are known analytically. A sticker on a curved
  Void work is a tangent quad whose edges stand off the work.
- Stickers are not in the inventory's budget (`InventoryHand.spent()` counts only the tape's strips). The cost is one
  draw per design per host.
- Designs are rasterised on the main thread, once each, the first time they are drawn (not timed). A worker thread or
  an atlas would remove that hitch.
- `ceiling_interface_style` works' exports carry an extra offset, so stickers on those are not yet placed alike in
  three.js and Godot (stickers.ts says so too).
- Not yet walked in a headset. The running tower was checked once on 2026-11-13 by a scripted run at floor 199 with no
  input: it made the StickerWorld, drew the board and the bench, and hosted a work sticker and a floor sticker. The
  probe also stands in a miniature Void with the real node names and metas.
