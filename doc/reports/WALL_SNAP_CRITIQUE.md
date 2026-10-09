# The hang, audited against the halls that were actually built

2026-09-19. Critic pass on THE HANG (`commons/scenes/em/em_detail.gd`, the face collection
`_dressed_faces`, `_wall_stretches`, `_stretch_candidates`, `_add_wall_showings`, `_hang_one`)
against `ada_run/em_layout_walk.json` and `ada_run/em_showing_cards.json`.

Read-only pass. Nothing in this repo was edited except this file.

---

## The verdict in one line

**The rule holds. The hand does not.** Of the 269 showings that can be checked, the ones the
rule placed on its own are on a wall 99% of the time (90 of 91). The ones carrying a hand
ruling from `ada_run/em_overrides.json` are on a wall 46% of the time (82 of 178). Palle's
complaint is real and it is entirely about the override path, not about
`_add_wall_showings`.

---

## Provenance of the numbers, and the trap

Both evidence files are live — other agents are rebuilding them while this runs. Everything
below is measured against snapshots taken at 15:38:

| file | md5 | contents |
|---|---|---|
| `ada_run/em_showing_cards.json` | `ea91113869c9759cb179161860c3dd34` | 616 cards, 37 hall keys |
| `ada_run/em_layout_walk.json` | `fcef85b50d6dab09559b845b914cc1d9` | 37 halls (not 32 — it grew during the session) |

**I verified the indexing trap by hand before computing anything**, on card
`array_tutorial · tutorial tiling floor · 01` (`backing_cell` `[13, 29]`, `normal` `[0, 1]`,
hall `array_tutorial|tutorial tiling floor`, `w` 21, `h` 32, `span` 36, `vestibule` 4,
`cell_x0` -1, grid 36 rows x 34 cols):

```
NAIVE    grid[bz=29][bx=13]       = '.'      <- would be reported "loose"
CORRECT  grid[bz+4=33][bx+1=14]   = '#'      <- it is on a wall

   row 32  ........................##########
   row 33  .##########..#########..##########
   row 34  .##########.....######..##########
                         ^ col 14 — the backing cell
```

and the cell the card faces into, `grid[34][14]`, is `.` — floor, as it must be. The correct
index is `grid[bz + vestibule][bx - cell_x0]`. `vestibule` is 4 and `cell_x0` is -1 in all 37
halls, and both are hardcoded (`VESTIBULE_H := 4` at `endless_museum.gd:268`, `cell_x0` written
as the literal `-1` at lines 5381 and 10197), so the correction is a constant `+4` on the row and
`+1` on the column — but read them off the row anyway, they are recorded per hall for a reason.

### What is checkable, and what is not

Only **271 of 616** cards carry `normal` / `facing_deg` / `backing_cell`; the rest predate
today's code. 269 of those 271 have a walk row (the two missing are `color|color walls`).
The other 345 cards **cannot be checked at all** and no amount of cleverness fixes that: the
sign of the normal is unrecoverable from what is recorded (see "The ledger cannot reproduce
itself" below). Guessing it — asking "is there a wall on any of four sides?" — is the method
that produced the 131/170-loose figures, and it is wrong.

The checkable 269 sit in 17 halls, and **10 of those 17 are `primitives`** (254 of 269 cards).
The corpus is badly skewed toward one chapter, which happens to be the one chapter with a
large body of hand rules. Treat every corpus-wide percentage below as a statement about
`primitives` with five `color` halls and two `array_tutorial` halls attached.

---

## 1. Does every card back onto a wall?

`backing_cell` is the cell behind the **card**, and the card is offset along the wall from the
work by `u_off = mount_w/2 - 0.07` (`em_detail.gd:1347`) — up to 0.59 m for a landscape. So
`backing_cell` alone cannot distinguish "the work is floating" from "the work is fine, the
caption slid off the end of the wall". The mount always straddles two wall cells (its centre
is the average of two consecutive face coordinates, hence always an integer), so I checked
**both** cells: `A` = the recorded `backing_cell`, `B` = one step back along the wall.

| classification | cards | share |
|---|---:|---:|
| **both cells wall** — a clean hang | **172** | 63.9% |
| neither cell is wall — free in the air | 35 | 13.0% |
| on a cell marked `s` — sealed by a body, not a wall | 23 | 8.6% |
| off the recorded grid entirely | 18 | 6.7% |
| card cell not wall, other cell is — the card slid off the end | 17 | 6.3% |
| card cell wall, other half hanging off | 4 | 1.5% |

Raw, for comparison with the figures quoted at me: `A` is `#` 176, `.` 49, `s` 21, off-grid 23.
The 49 matches the stated true figure. The naive index on the same 269 gives `.` 141, `#` 59,
`s` 45, off 24 — so the trap inflates the floor-backed count by 2.9x and, worse, *reclassifies*
clean hangs as broken rather than merely adding noise.

### Why — and this is the whole report

`ada_run/em_overrides.json` holds 27 rules of `kind: "showing"`. Split them:

- **24 carry a free metre `offset`.**
- **0 carry `cell`. 0 carry `dir`.**
- 8 carry `remove: true`.
- **All 27 are keyed by `chapter` alone.** None carries `pearl`, `map` or `segment`.

Cross the rules against the classification (rule index = card index − 1):

| | showings | not cleanly on a wall |
|---|---:|---:|
| carrying a hand `offset` rule | 178 | **96 (54%)** |
| no rule | 91 | **1 (1%)** |

That is the finding. Three separate defects produce it.

**(a) The HANG ruling has never been used.** `_hang_retarget` (`em_detail.gd:934`) is the
function written for Palle's 2026-08-26 instruction; it takes `{index, cell, dir}`, finds the
wall face, and rebuilds the six boxes on it. It is wired up at `em_detail.gd:534` and it has
**zero callers in the live rule store**. Every hand move ever made has gone down the `offset`
branch at `em_detail.gd:537-546`, which is six lines of `Transform3D.translated(off)` with
**no check that the destination is a wall face, or a wall at all**. A work told to move 6 m east
moves 6 m east, through the wall, into the next room, into the void.

**(b) A rule fires in every hall of its chapter.** `_furniture_rules`
(`endless_museum.gd:~19286`) matches on `String(ov.get("chapter","")) == chapter` and nothing
else. `primitives` has 10 halls in this ledger alone (and more in the 196-hall plan). So
`{chapter: primitives, index: 6, offset: [-2, 0, -1]}` — one drag, in one room, by one hand —
fires in `point one`, `point lines`, `point line grid`, `point triangle context`,
`primitives polythedra`, `point animatedcube`, `primitives portals` and `primitives melencolia`
simultaneously, and **all eight of those cards are broken**: four free in the air, one on a
sealed cell, one off-grid, one slid, one free. The hand fixed one wall and vandalised seven.

Same rule, same pattern, `index 7` `offset [6, 0, -5]`: 7 halls, 5 of them **off the grid
entirely** and 4 of those at y = −0.1 m.

**(c) `remove: true` removes nothing you can see.** `_dressing_removed`
(`endless_museum.gd:19280`) is consulted at `endless_museum.gd:9289`, and it frees the node
carrying meta `em_showing` — which `em_detail.gd:605-611` documents as *"an empty Node3D … no
mesh, no collider — a handle, not a body"*. The rule applier at `em_detail.gd:526-546` reads
`cell`, `dir` and `offset` and **never reads `remove`**. So the picture, its frame, its mount,
its field and its card all stay on the wall; only the editor's grab handle disappears.
**116 cards in the ledger sit at an index carrying a `remove` rule.** And because those rules
carry offsets too, the works the hand thought it deleted are still hanging, at whatever
coordinate the drag ended on.

Two further consequences of (c) worth naming separately: the card ledger is written at
`endless_museum.gd:9243-9283` and `_save_showing_cards()` is called **before** the removal loop
at 9289, so even if removal worked the ledger would record the removed showing; and the card
node is a separate child of the segment from the proxy, so freeing the proxy would orphan the
caption regardless.

### The 28 cards that are not at hanging height

Every card should sit at one of three heights — 1.0 (portrait), 1.1 (landscape), 1.2 (square),
from `HANG_Y 1.58 − mount_h/2 − CARD_DROP 0.10`. 28 do not: six at −0.1, three at −0.2, three
at −0.3, two at −0.4 (**below the floor**), four at 1.4, four at 1.5, six at 1.6.

All 28 are in `primitives`, spread 1–4 per hall across all ten. Subtracting the height each
card's own format predicts leaves exactly three residual values: **+0.4 (14 cards) and
−1.4/−1.2 (14 cards)**. There are exactly three showing rules in the store with a non-zero y:
`index 0` `[0, 0.4, 0]`, `index 22` `[1, 0.4, 0]`, `index 18` `[2, −1.4, 2]`. Two rules at
+0.4 firing in ~7 halls each, one at −1.4 firing in 8. 14 and 14. Nothing else is needed to
explain it.

A −1.4 m offset puts the centre of a picture at 0.18 m. That is Palle's *"sometimes in the air
from old walls"* with the sign flipped — they are on the floor, and they are there because one
hand nudged one frame down in one room four weeks ago.

### The one unruled failure

`primitives · point one · 36` — `backing_cell` `[-3, 5]`, `normal` `[1, 0]`, world
`[-2.0, 1.2, 5.2]`. Column `-3 - (-1) = -2`, off the west edge of the recorded grid. This is
the only card in the corpus that is off its wall without a rule to blame. I do not know what
it is and I am not going to guess. **What would settle it:** the walk grid is derived from
`_walk_cells`/`_walk_erased` (`endless_museum.gd:10143-10156`) while em_detail derives its own
`walls`/`floors` from `_map_vestibule` + `_map_tile` (`em_detail.gd:372-376`) — two independent
implementations of one room, the exact hazard the project already has a memory note about.
A single card disagreeing is most likely those two maps disagreeing about the hall's west
edge. Dump em_detail's `walls` dict for that segment and diff it against the walk grid.

**And note what that same argument rules OUT:** if the two derivations disagreed systematically,
the disagreement would hit ruled and unruled showings alike. It hits 54% of one and 1% of the
other. The mechanism is the rules, not the map disagreement.

---

## 2. Do cards collide?

I reconstructed each mount's real footprint — outer frame = format width + 2 x `HANG_FRAME_W`
(0.87 / 1.47 / 0.73 m), 70 mm proud, height = format + 0.15, centred at the y the card implies
— and intersected every pair within a hall in 3D.

**5 overlapping pairs, all 5 in `primitives`, and every one of them has a hand rule on at
least one side:**

| hall | pair | the rules |
|---|---|---|
| `primitives\|point one` | 08 x 18 | `idx 7` `[6,0,−5]` REMOVE **x** `idx 17` `[−8,0,−3]` REMOVE |
| `primitives\|point one` | 11 x 36 | `idx 10` `[0,0,1]` REMOVE **x** no rule |
| `primitives\|point lines` | 12 x 35 | `idx 11` `[2,0,0]` **x** no rule |
| `primitives\|point animatedcube` | 05 x 06 | `idx 4` `[0,0,1]` REMOVE **x** `idx 5` `[1,0,0]` |
| `primitives\|primitives ignorance` | 12 x 24 | `idx 11` `[2,0,0]` **x** `idx 23` `[−1,0,1]` |

Two of those pairs are at **centre-to-centre distance 0.00 m** — one frame exactly on top of
another. `point one` 08 and 18 are two works the hand marked for deletion, dragged from
opposite ends of the room, landing on the same square metre and both still standing there
because `remove` is a no-op. That is Palle's *"sometimes they hang on each other"*, literally,
and it is one bug away from being impossible.

**The two-metre pitch itself never collides.** 58 pairs share a run (same plane, same normal);
their spacing histogram starts at 2 m and the widest outer frame is 1.47 m, leaving 0.53 m of
bare wall. The only same-run pairs that overlap are the three above, all driven off-pitch by
an offset. 6 pairs end up with less than 350 mm of bare wall between frames — the margin the
`_add_wall_showings` docstring claims as its floor — and those 6 are the same population.

---

## 3. Is the two-face pitch right?

**The pitch is almost never what decides.** I replayed `_wall_stretches` /
`_stretch_candidates` over each hall's walk grid and counted candidate positions against
showings actually built:

| hall | wall faces | candidates | built | taken |
|---|---:|---:|---:|---:|
| `primitives\|point lines` | 266 | 107 | 41 | 38% |
| `primitives\|point one` | 227 | 90 | 38 | 42% |
| `primitives\|primitives polythedra` | 239 | 94 | 34 | 36% |
| `primitives\|point line grid` | 152 | 63 | 21 | 33% |
| `primitives\|primitives portals` | 128 | 60 | 19 | 32% |
| `array_tutorial\|tutorial tiling floor` | 100 | 45 | 3 | **7%** |
| `color\|color rainbow` | 81 | 37 | 2 | **5%** |
| `color\|color pillar` | 141 | 66 | 2 | **3%** |
| **total (17 halls)** | 2314 | 983 | 269 | **27%** |

Realised density, in metres of wall run per showing:

- `primitives` halls: **one per 6.0 to 7.2 m** — reads as a museum. A wall you walk past shows
  you a picture every two paces or so. This is right.
- `array_tutorial` halls: one per 33 m.
- `color` halls: **one per 38 to 70 m**. `color|color pillar` has 141 m of dressed wall and
  **two** pictures on it. That does not read as wallpaper; it reads as a room being
  redecorated, or an empty one.
- Corpus: one per 8.6 m, 0.116 showings per metre.

So: `HANG_PITCH_FACES = 2` generates a candidate every 2 m and **73% of those candidates are
thrown away** by `wall_features_max`, which comes from `em_budget.gd` (`CORPUS_WALL_FEATURES`
2.2 per 10 m, capped at `MAX_WALL_FEATURES` 80). The binding constraint on density is the
budget, not the pitch. **A 13x spread between `point lines` and `color pillar` is not a design
decision anyone made** — it is what falls out of two numbers multiplying, and nobody is looking
at the product.

I cannot tell from this data whether the `color` halls are starved by the budget row or by
`bare_below_z` eating most of their run. **What would settle it:** print `wall_features_max`
and `faces.size()` per segment — em_detail already has both at `em_detail.gd:452-460` — and
compare `color` against `primitives`. One boot.

---

## 4. What the rule cannot express

Format is `idx = absi(round(centre*2) + round(fixed*2)) % 3` — the picture's shape is decided
by where it is standing. It is deterministic, which is the property the docstring argues for
and which is genuinely worth keeping (a proof shot is comparable with the proof shot before
it). But it means the rule cannot say:

- **"this wall is the one you see on entering, so put the big landscape there."** The rule
  cannot see a sightline. A 13 m plane facing the door and a 2 m return behind a pier get their
  formats from the same modulo.
- **"this work is a wide thing, give it the landscape."** Format is uncoupled from content.
  Once a showing carries a real work rather than a grey field — which is where `text` rules and
  the "swap for another wall-hanging body" note in the ledger readme are heading — the
  arithmetic will be choosing portrait for landscape pictures a third of the time by
  construction.
- **"three of these belong together, hang them as a group."** The stretch walker emits every
  2 faces at the group centre and has no concept of a set. The 3-format cycle is there so a run
  of six *doesn't* read as wallpaper, which is a real and good reason, but it buys variety by
  refusing rhythm. A salon wall, a pair, a triptych are all unsayable.

**Does it matter?** Right now, no — the fields are blank grey and there is nothing to mismatch.
It matters the moment a work goes into a field, and that is the next thing on this path. The
arithmetic should not be replaced yet; it should be made **overridable** by the same ruling
that moves a work, so that when content arrives a hand can say "landscape here" without a code
change. `_hang_retarget` already recovers the format out of the built box
(`em_detail.gd:945-962`) — the plumbing is half there.

---

## 5. The weakest thing, and what to do

> **A hand ruling on a wall work is a free metre translation with no idea what a wall is, and
> it is keyed by chapter, so one drag in one room silently moves or breaks the same picture in
> every other hall of that chapter — which is where 96 of the 97 off-wall works in the corpus
> came from.**

Three proposals, ranked by what they buy per unit of risk.

### 1. Scope a showing rule to its hall

- **Function:** `_furniture_rules(chapter, kind)`, `endless_museum.gd:~19286`, and the writer
  that mints rules, `_furniture_override`, just below it.
- **New rule:** a rule matches only when its `pearl` matches the hall's pearl. Rules written
  from now on carry `pearl`. Existing rules with no `pearl` keep firing chapter-wide so nothing
  changes under anyone's feet — but the museum prints a one-line warning naming each
  unscoped rule and the number of halls it hit, so the size of the legacy is visible.
- **Visible effect:** 9 of the 10 `primitives` halls stop being collateral damage. On the
  measured population that is the difference between 96 broken and roughly 10 — the ones the
  hand actually touched.
- **Risk:** low, and it is the *right* kind of low: additive, gated by new data, a rule
  without the new key behaves exactly as today. The one real risk is that a hand deliberately
  used chapter scope to dress a whole chapter at once; the warning line will say so within
  one boot.

### 2. Make `remove` remove, and make an offset land on a wall

- **Function:** the rule applier, `em_detail.gd:526-546`.
- **New rule:** two changes in the same block. (a) Read `remove`: drop the showing's mount,
  field, four frames and card rather than translating them. (b) After an `offset`, resolve the
  moved mount back to the nearest dressed face within some tolerance and snap to it — the face
  list is already in scope as `faces` — and if there is no face within tolerance, **refuse the
  move and print the rule**. A work that cannot land on a wall stays where the rule put it.
- **Visible effect:** the 116 ledger rows at `remove` indices stop being pictures. The two
  coincident frames in `point one` disappear. The 28 off-height cards come back to 1.58, or
  are refused and named.
- **Risk:** medium, and it is the one to be careful with. Snapping changes where already-placed
  works stand, so a hall someone was happy with will move. Land it behind a flag, shoot the
  same hall before and after, and put both frames in front of Palle before it becomes the
  default. The `remove` half carries no such risk and could ship on its own today.

### 3. Make the editor write `{cell, dir}` instead of `offset`

- **Function:** whatever writes rules into `ada_run/em_overrides.json` — `_furniture_override`
  in `endless_museum.gd` and the encyclopedia's museum-editor route (both being edited by
  other agents right now, which is why I am not naming line numbers).
- **New rule:** dragging a wall work emits the face it was dropped on — `{index, cell: [x,z],
  dir: [dx,dz]}` — not a metre delta. `_hang_retarget` already consumes exactly this and is
  already wired at `em_detail.gd:534`. Keep `offset` for the sub-metre nudge on top, which is
  what the docstring at 530-531 always intended.
- **Visible effect:** a work dropped on a north wall and dragged to an east wall **turns**,
  which a translation can never do. Off-wall placement becomes unrepresentable rather than
  merely discouraged.
- **Risk:** low in the engine (the consumer is written and unused), real in the editor — the
  editor has to know which face the pointer is over, and the 3 mm that distinguishes the two
  sides of a wall plane is exactly the quantity the ledger currently destroys (see below).
  Do proposal 1 first; this one is worth a session of its own.

---

## Four ledger defects a builder will hit within the hour

- **`world` cannot reproduce `cell`.** `cell` is `floor()` of the *unsnapped* position
  (`endless_museum.gd:9251-9252`) while `world` is `snappedf(..., 0.1)` (line 9248). A card on
  a −z-facing wall sits at `plane − 0.003`; the engine floors that to `plane − 1`, the ledger
  records `plane`. Re-deriving the cell from `world` is off by one for every negative-normal
  card — I hit this and had to back it out. It also means the *sign of the normal* is gone for
  the 345 older rows. Record `proud` or the unsnapped fixed coordinate.
- **30 duplicated rows.** `noise · random noise types · 01`..`28` and two others appear twice,
  byte-identical including `segment`. `_save_showing_cards` appended a hall twice in one run.
  The readme claims "a hall built again replaces its own rows"; for these it did not.
- **`chapter|pearl` is not a unique hall key.** Both ledgers use it. The museum deals 196 halls
  from 24 chapters, so a pearl dealt twice collides — the walk row silently overwrites, the
  card ids collide. Add the segment or the plan index.
- **`color|color walls` has cards and no walk row; `transformation|trans pit` has a walk row
  and no cards.** Neither is wrong on its own — the files are written at different moments —
  but any tool that joins them needs to expect both.

---

## Reproducing this

Scratch scripts are in the session scratchpad (`wallsnap.py`, `q1.py`, `q23.py`) and are not
worth keeping; the whole analysis is four rules:

1. `grid[bz + vestibule][bx - cell_x0]`, never `grid[bz][bx]`.
2. Check **both** of the mount's wall cells — `backing_cell` and one step back along the wall —
   because the card is offset up to 0.59 m from the work.
3. Join every card to `ada_run/em_overrides.json` on `(chapter, index - 1)` before drawing any
   conclusion about the placement rule. Without that join the rule looks 64% correct; with it,
   the rule is 99% correct and the overrides are 46%.
4. Only the 271 cards carrying `normal` are evidence. The other 345 are not, and guessing the
   normal from the neighbours is how the 131-loose and 170-loose figures happened.
