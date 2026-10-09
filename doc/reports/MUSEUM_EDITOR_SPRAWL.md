# The museum editor sprawl — what is alive, what re-derives, what survives

Measured 2026-09-19, 14:40–15:05 CEDT, on branch `palm-scanner-door-entry`
(AdaResearch_46) and `spatial-iterations-gallery` (ada_encyclopedia).

Two files moved under me while I read them — another session is repairing
`/museum-editor` right now. Everything I say about those two is pinned to a hash:

| file | md5 when read | at |
|---|---|---|
| `ada_encyclopedia/src/app/museum-editor/page.tsx` | `ce6244bf1c8b78f2788e466a83408c9f` | 14:58 |
| `ada_encyclopedia/src/app/api/museum-editor/route.ts` | `1e4f4d0a11c80e28b3826a7fee9da311` | 14:58 |

Everything else was stable for the duration.

---

## 0. The finding that reorders the whole question

**Every one of the 172 rows in `ada_run/em_plan.json` carries `authored: "map"`.**

```
$ python - <<'PY'
import json,io,collections
plan=json.load(io.open('ada_run/em_plan.json',encoding='utf-8'))
print(collections.Counter(p.get('authored','') for p in plan['plans']))
PY
Counter({'map': 172})
```

`commons/scenes/endless_museum.gd:7965` then does this, before anything is built:

```gdscript
if String(peek.get("authored", "")) == "map" and String(peek.get("map", "")) != "":
    var derived := _derive_map_row(String(peek["map"]))
    peek["tile"] = derived["tile"]
    peek["artifacts"] = derived["artifacts"]
```

— *"a map-authored hall builds FROM ITS MAP, read fresh at every build — the plan
row is a POINTER (pearl, museum key)."* And at `endless_museum.gd:11786`, inside
`_deal_from_plan`:

```gdscript
var found: Dictionary = {} if String(entry.get("authored", "")) == "map" \
    else _ruling_for(tok, String(entry.get("sequence", "")), tx, tz, bool(row.get("hand", false)))
```

`_ruling_for` is the *only* lookup that applies a kind-less (artifact) override.
It has three call sites: `:10324` (vestibule bodies), `:10378` (forecourt bodies),
and `:11786` (interior bodies — guarded off above).

All 1357 bodies in the plan are `venue: "interior"`. Zero porch, zero outside.

**So: the artifact rulings `/museum-editor` writes apply to 0 of 1357 bodies.**
Not "sometimes idle" — never reached, and not even counted in the idle report
(`_ruling_stats["idle_far"]`), because the lookup that counts is skipped.

The same guard bites `/hall-editor`. At `endless_museum.gd:8172`:

```gdscript
if hall_is_authored and ccz >= 0 and (passage_start < 0 or ccz < passage_start):
    continue
```

Its `kind: "cell"` wall/passage rulings survive **only** on negative z (the
vestibule / enter room) and on rows at or past `passage_start`. Every cell inside
the hall proper is refused, silently.

And `/museum-plan-editor` writes `em_plan.json`'s `artifacts` array — which
`_derive_map_row` overwrites at every build, for all 172 rows. Consistent with
what the file shows: **0 of 1357 plan artifacts carry `hand: true`.** Either it has
never been saved from, or a regeneration ate it; either way nothing in the plan is
hand-held today.

What still round-trips on an authored hall: `kind` = `gate`, `prop`, `furniture`,
`showing`, `plinth`, vestibule/annex cells, passage cells — i.e. the dressing, not
the art. Plus `map_data.json` itself, which is the one truth.

The premise I was handed — *"the override system keyed to the plan is the only
editing mechanism that currently round-trips to Godot"* — is exactly backwards for
artifacts. It is the one that **does not**. `map_data.json` is the one that does.

---

## 1. What each surface actually is

Line counts are `page.tsx` only. "writes" is what a POST on its own API touches.

### Editors (something changes on disk)

| route | lines | shows | geometry from | writes | verdict |
|---|---|---|---|---|---|
| **`/long-museum`** + `components/long-museum/HallEditor.tsx` | 1281 + 3301-line sibling family | whole spine as one scrolling strip; click a hall → 3-layer cell editor to the right | `commons/data/long_museum.json`, built by `tools/long_museum.py` from **`ada_run/em_layout_walk.json`** with a declared `layout: "derived"` fallback | **`commons/maps/<Map>/map_data.json`** via `POST /api/maps/cell-edit` (sha256 compare-and-swap, backups, pending-ops batch) | **ALIVE, and the only one whose edits the museum obeys.** Strip data last built 2026-09-17 16:24 — two days stale |
| `/museum-editor` | 418 | one chapter as a Three.js scene; orbit / iso / walk; bodies as GLTF or measured box; wall cards as coloured plates | `/api/museum-plan-view` → `template_patterns.json` in plan mode; `ada_run/em_layout_walk.json` in engine mode (added today) | `ada_run/em_overrides.json`, artifact rows only, `by: "web"` | **ALIVE but its writes are inert** (§0). Geometry being repaired right now |
| `/museum-plan-editor` | 264 | one pearl's floor plan in 2D; drag, rotate, scale, offset, per-artifact DNA config dropdowns; bake status + re-bake button | `row.tile` from the plan (correct) but `w: pat?.w ?? 0` from the template (wrong) | **`ada_run/em_plan.json`** rows, stamped `hand: true` + `ruled: {at, by}`; then spawns `tools/em_ship.py` | **Richest inspector in the family; its writes are overwritten** by `_derive_map_row` |
| `/hall-editor` | 228 | one chapter's halls as a clickable grid; toggle wall ↔ passage; slide the gate | `r.tile` from the plan row (correct) | `ada_run/em_overrides.json` `kind: "cell"` / `kind: "gate"`; runs `tools/em_ship.py` so the Quest export agrees | Half-alive: gate + vestibule + passage rulings apply, interior cells are refused |
| `/halls` | 388 | every hall in walk order, one plan under the next; drag a numbered dot to lock a body; docked book inspector | `/api/trunk` (plan + bake + books) | **the BOOKS** (`commons/data/book/*.json`), then compiles dirty chapters | Alive, different job — it edits *what a hall says and which bodies it deals*, not where they stand |

### Read-only, live

| route | lines | what | source |
|---|---|---|---|
| `/museum-plan-view` | 229 | the drawn floor plan `/museum-editor` is built on | `em_plan.json` + `template_patterns.json` + `em_overrides.json` |
| `/museum-pipeline` | 167 | seven stages, file mtimes, freshness warnings, token trace | `em_plan.json`, `gates.json`, others |
| `/museum-editors` | 230 | **the index of all of the above** — stage, where it lives, what it writes, live iframe | hardcoded, hand-maintained |
| `/museum-50` | 319 | 50 museums × where a footprint could stand | `tools/museum_50.py` output |
| `/museum-belt` | 469 | assemble a building from bays along the walk | `/api/template-maps` |
| `/museum-match` | 185 | 24 chapters × extracted buildings, scored | `/api/museum-match` |
| `/museum-wizard` | 760 | the spatial chain as a walkable wizard, four steps change the world | `tools/museum_wizard.py` |
| `/museum-progress` | 600 | room outlines and progress | `tools/museum_progress.py --json` |
| `/museum-readiness` | 224 | prop-band decisions on one pilot map | `Museum_AAA_Uffizi_Prop_Pilot` + `/api/audit/validate` |
| `/hall-verdicts` | 406 | steer a live Godot window from the web; rule on benches | `/api/hall-verdicts`, `/api/map-simulator/control` |
| `/museum-wall-kit` | 17 | a `GalleryView` wrapper over the wall-piece atlas | gallery captures |

### Frozen snapshots — not pages, exhibits

| route | lines | data file | file date |
|---|---|---|---|
| `/museum-aaa-pass` | 866 | `public/museum-aaa-pass/*.json` (3 files) | 2026-08-10 |
| `/museum-contract-pilot` | 304 | `public/museum-contract-pilot/report.json` | 2026-08-10 |
| `/museum-phi` | 331 | `public/museum-phi/phi.json` | 2026-08-10 |
| `/museum-stage-12` | 568 | `public/museum-stage-12/stage.json` | 2026-08-10 |
| `/museum-staging` | 316 | `public/museum-staging/stage.json` | 2026-08-10 |

All five read a static JSON committed once and never regenerated. They cannot go
stale because nothing updates them; they also cannot tell you anything about the
museum as it stands. 2,385 lines of TSX describing 2026-08-10.

Six of these pages are **untracked in git** — `museum-aaa-pass`,
`museum-contract-pilot`, `museum-progress`, `museum-readiness`, `museum-wall-kit`,
`museum-wizard`, plus `api/museum-progress`, `api/museum-readiness`,
`api/museum-wizard`. They exist only in the working tree on this machine.

---

## 2. Which surfaces re-derive the layout

### 2a. `/api/museum-plan-view/route.ts:48-51` — the worst of the three answers

```ts
const pat = pats[row.museum] ?? null;
const tile: string[][] = pat?.tile ?? [];
const w = pat?.w ?? (tile[0]?.length ?? 0);
const h = pat?.h ?? tile.length;
```

It reads the **template** (`commons/data/template_patterns.json`, 182 patterns,
last written 2026-08-07) and ignores `row.tile`, which is in the same object it
already holds. Three sources disagree for `primitives|point one`:

| source | dims |
|---|---|
| `template_patterns.json["sainsbury-false-perspective-enfilade"]` | **15 × 30** |
| `em_plan.json` row `tile` / `room` | **19 × 20** |
| `em_layout_walk.json["primitives|point one"]` (the engine) | w 19, h 29, span 33, `cells` 33 × 32, `cell_x0` −1 |

This is not one hall. Measured across the whole plan:

```
plan rows where TEMPLATE w/h != row.tile dims:  171   equal: 1   no template: 0
bodies outside the TEMPLATE box: 264 of 1357  (19.5%) across 64 of 172 plan rows
bodies outside the ROW TILE box: 0
```

**171 of 172 halls are drawn as the wrong room, and one body in five is drawn
outside the room it is drawn in.** Against the plan's own tile, not one body
falls outside. `/museum-editor` inherits all of this, because its route calls
`/api/museum-plan-view` for the base.

`/api/museum-plan-editor/route.ts` is half-fixed: `h: (row.tile?.length ?? …)` and
`tile: row.tile ?? pat?.tile` are right, but `w: pat?.w ?? 0` is still the
template's — so its inspector reports width 15 for a 19-wide hall.

`/api/museum-halls/route.ts` (behind `/hall-editor`) is **correct**: it takes
`tile` from `r.tile` and `w` from `tile[0].length`.

### 2b. Hardcoded engine constants, in three places

`/api/museum-plan-view/route.ts:63` re-implements `endless_museum.gd`'s side rooms:

```ts
const ROOM_W = 5, ROOM_D = 7, ROOM_GAP = 2, ROOM_Z0 = 4;
```

`/museum-editor/page.tsx:28` re-implements the segment:

```ts
const VEST = 4, PORCH = 3, WALL_H = 4.5, ROOM_W = 5, ROOM_D = 7;
```

`/museum-plan-view/page.tsx:15-16` has its own `CELL = 22, VEST = 4, PORCH = 3`.

None of these knows the word **passage**. The engine's record for `point one` says
`passage: 9` — nine rows appended past the map's last row, which is why engine
`h = 29` where the map is 20 deep. This is the identical fault `tools/long_museum.py`
made (*"it gave every hall h20 where the engine builds h23"*), one rung worse:
long_museum was 3 rows out, plan-view is 9 rows and 4 columns out and starts at the
wrong origin.

### 2c. The wall-card mount verdict was reading the wrong cells

`endless_museum.gd:10131` writes the grid as
`for z in range(zbase, z1)` × `for x in range(-1, w + …)` — **row 0 is the first
vestibule row, column 0 is world x = −1** (`cell_x0 = -1`, written at `:5381` and
`:10183`). `endless_museum.gd:9267` writes a card's `backing_cell` as
`[floor(world.x) − normal.x, floor(world.z) − zbase − VESTIBULE_H − normal.y]`:
absolute x, **tile-relative** z.

So the conversion is `grid[bz + vestibule][bx − cell_x0]`. The route as first
written indexed `grid[bz][bx]`. Measured over the 259 recorded cards in the 12
halls that have both a card record and a walk row:

| indexing | mounted | on_air | off_grid |
|---|---|---|---|
| `grid[bz][bx]` (as written at 14:45) | 106 | **130** | 23 |
| `grid[bz+vest][bx+1]` (correct) | **187** | 50 | 22 |

The page was about to paint 80 correctly-mounted wall cards orange with a dropped
plumb-line to the floor, captioned "hanging off nothing".

**By 14:58 the other session had fixed this**, independently deriving the same two
offsets and writing them into the page header, with a `geo.engine` flag, a
`cardDisagree` counter and a red badge when a hall falls back to plan arithmetic.
My numbers corroborate their fix. What remains unfixed is §2a — the fallback path
still draws the template, and the fallback is the common case (§3).

### 2d. `em_layout_walk.json` covers 32 halls of 172, and is gitignored

```
$ git check-ignore -v ada_run/em_layout_walk.json
.gitignore:43:/ada_run/em_layout_walk.json
```

32 halls, all built 2026-09-17 → 2026-09-19. `vr_link_viewer.gd:13` still says
*"198 rows"*. A hall nobody has walked on **this machine since the file was last
cleared** has no row. So "read the engine's record" is available for 19% of the
museum and cannot be the sole rule. `long_museum.json` shows the honest shape of
this: of 334 segments, 119 `layout: "engine"`, 48 `layout: "derived"`, 167 with no
layout key at all.

---

## 3. Which one should survive

**`/long-museum` + its `HallEditor`, extended with a 3D/isometric view.**

Not because it is the prettiest — `/museum-editor` is — but because it is the only
surface writing to the file the museum actually reads. Everything in §0 reduces to
one sentence: *on a map-authored hall, the map is the placement authority, and all
172 halls are map-authored.* An editor that does not write `map_data.json` is
editing a file the museum throws away before it builds.

The supporting facts:

- `POST /api/maps/cell-edit` is 3,242 lines across 8 files: sha256 compare-and-swap,
  timestamped backups, span-preserving JSON splice (so a save does **not** reindent
  the file), batch operations, a resize path, template stamping, and a walk
  validator. It is the most defended writer in the encyclopedia.
- `HallEditor.tsx` already moves the **raw cell string**, deliberately: its header
  records that 361 of 1,745 hall placements (20.7%) carry a `#config` tail or a
  y-offset that `tools/long_museum.py:parse_cell` drops, so rebuilding a cell from
  the strip would silently turn `pickup_gate#pickups:6` into `pickup_gate`.
  Any new editor has to relearn that; this one knows it.
- `/long-museum`'s geometry already reads `em_layout_walk.json` through
  `src/lib/ada-repo/strip.ts:82` and already **labels** a hall it had to derive.
  That is the discipline the whole family needs and only this one has.
- It is the only museum surface that edits all three layers (structure, utilities
  read-only, interactables) in one place.

**Against "build a new one":** a new page starts from zero on the cell-string
grammar, the backup policy, the concurrent-write guard, the 182-template stamp
vocabulary and the walk validator — and the twenty-second museum page is not the
cost that matters here. The cost that matters is that there are already six
surfaces claiming to edit this museum and five of them write somewhere the museum
ignores. A seventh is not a fix.

**The one thing `/museum-editor` has that nothing else does** is a Three.js scene
with GLTF bodies, an isometric orthographic camera with rotation disabled, wall
cards placed by recorded cell and facing, and — as of today — an engine-mode
geometry path. That is real work and it should not be thrown away. It should be
**repointed**: keep the scene, change what it writes.

---

## 4. What the survivor is missing, ranked

### 1. It writes the right file but the wrong page draws the 3D. Merge the two.

`/long-museum`'s hall editor is 2D cells; `/museum-editor` is the 3D scene. Neither
alone is what Palle asked for.

- **Cheapest useful move (~60 lines):** point `/museum-editor`'s POST at
  `/api/maps/cell-edit` instead of `/api/museum-editor`. A body drag becomes two
  cell operations on the `interactables` layer — clear the old cell, write
  `token:rot:y_off#config` into the new one — against the hall's `map` name, which
  is already in the plan row (`row.map`, e.g. `Point_One`). Files:
  `src/app/museum-editor/page.tsx` (`save()`), `src/app/api/museum-editor/route.ts`
  (GET must return `map` and the raw cell strings; POST deleted or made a proxy).
  **This is the change that turns a preview into an editor.**
- Guard it: `/api/maps/cell-edit` needs the file's sha256 from the read. Copy the
  pattern from `HallEditor.tsx:341`.

### 2. Geometry in plan mode still draws the template. One line.

`src/app/api/museum-plan-view/route.ts:49-51`:

```ts
const tile: string[][] = row.tile ?? pat?.tile ?? [];
const w = tile[0]?.length ?? pat?.w ?? 0;
const h = tile.length || (pat?.h ?? 0);
```

Fixes 171 of 172 halls and moves 264 bodies back inside their room. Also fixes
`/museum-plan-editor`'s width, same line shape, `api/museum-plan-editor/route.ts`
(`w: pat?.w ?? 0`). **Do this first — it is five minutes and it is load-bearing for
the other four items.** 140 of 172 halls have no engine row, so plan mode is the
common path, not the fallback.

### 3. Wall works are visible but not movable. Medium.

`page.tsx:312-330` builds card plates and hangs the record on
`plate.userData.card`, but no raycast branch selects them and `save()` never emits
a `kind: "showing"` row. The override schema already supports it — 27 `showing`
rows exist in `em_overrides.json`, written by the TAB editor, keyed by `index`
with an `offset`, and `showing` rulings **do** survive the authored-hall guard.

- `page.tsx`: add cards to the pick list, add an `Ov` variant carrying
  `{kind:"showing", index, offset, text?}`.
- `api/museum-editor/route.ts` POST: it currently filters
  `!(o.chapter === body.chapter && !o.kind)` and never writes a `kind`, so showing
  rows are preserved-but-unwritable. Widen the replace key to
  `(chapter, kind, index)`.
- ~120 lines across the two files. **This is the one item where the override file
  is the right target**, because showings are dressing, not plan bodies.

### 4. The passage rows are missing from the drawing. Small, but it is the long-museum fault.

`geo` in engine mode now carries `vest`, `porch`, `court` — but there is no
`passage`, and `em_layout_walk.json` records it (`point one`: `passage: 9`,
`passage_kind: "chicane"`). In plan mode there is no way to know it at all.
`tools/em_map_halls.py` computes it; the web should call that rather than become a
third implementation. Files: `api/museum-plan-view/route.ts` (shell out to
`em_map_halls.derive_row`, or return the map's raw structure and let the page walk
it), `museum-editor/page.tsx` (`geo`, and the ground/ceiling extents).

### 5. Engine mode is unreachable for 140 of 172 halls. Make the badge actionable.

The red badge is right. Add the command beside it — `godot --path . res://commons/scenes/endless_museum.tscn -- --em-plan`
and the pearl to walk — so the badge says how to clear itself. And say it on
`/museum-pipeline` as a count: *"32 of 172 halls have an engine row."*
`museum-editor/page.tsx` toolbar + `api/museum-pipeline/route.ts`, ~30 lines.

### 6. The strip is two days stale. Automate or date it.

`commons/data/long_museum.json` is from 2026-09-17 16:24; `point one` was rebuilt
2026-09-19 14:42. `/long-museum` currently shows the older shape with no visible
date. Either run `python tools/long_museum.py` on each museum walk, or print the
file's mtime in the header. `src/app/api/long-museum/route.ts` already knows the
rebuild command (`const REBUILD`); it should return the mtime with it.

---

## 5. Delete, merge, and what breaks

### Delete outright — nothing reads them, nothing writes them

| route | why | what breaks |
|---|---|---|
| `/museum-aaa-pass` (866 lines) | static report of 2026-08-10 | nothing. Linked from no nav. Untracked in git — deleting it is `rm`, not a commit |
| `/museum-contract-pilot` (304) | same | nothing; untracked |
| `/museum-stage-12` (568) | same | nothing; tracked, so it is a commit |
| `/museum-staging` (316) | same | **`/museum-editors` stage 2 links to it.** Edit that entry first (`src/app/museum-editors/page.tsx`, the `"2 · Contract"` row) |
| `/museum-phi` (331) | same | nothing; tracked |

That is 2,385 lines of page plus ~340 KB of `public/` JSON. If the *content* is
worth keeping, it belongs in `/spatial-iterations` as a dated contact sheet — which
is what that page is for — not as five live routes that look current.

### Merge

- **`/museum-plan-view` into `/museum-editor`.** The page (229 lines) is a
  read-only 2D twin of the 3D one; the API stays, because `/museum-editor` calls
  it. Deleting the page breaks two links from `/museum-editors` (stage 3 `href` and
  `live`) and one from `/museum-pipeline`'s token trace.
- **`/hall-editor` into the survivor.** Its unique power is the wall/passage cell
  toggle and the gate slider. On an authored hall the interior toggle is refused by
  the engine anyway (§0), so what it uniquely does is *the gate and the vestibule* —
  which is exactly what the survivor lacks. Port those two controls, keep
  `/api/museum-halls` (it is the one route that calls `em_ship.py` after a cell
  ruling, so the Quest export follows). Breaks: `/museum-editors` has no entry for
  it, so nothing links to it — check `git grep hall-editor` before deleting.
- **`/museum-plan-editor`'s inspector into the survivor.** Its per-artifact DNA
  config dropdowns (read from the registry's `dna.axes`) and its bake status +
  re-bake button are the best inspector in the family and exist nowhere else. The
  *writer* should be retired — it writes plan rows that `_derive_map_row`
  overwrites. Breaks: `/speak` links to it (`src/app/speak/page.tsx`), and
  `/museum-editors` stage "3 · Plan — edited as the plan" describes it at length.

### Keep as-is

`/halls` (edits the books — a different authority, no overlap),
`/museum-pipeline` (the freshness dashboard),
`/museum-editors` (the index; it is how anyone finds their way, and it is the
cheapest thing to keep honest — one array of objects),
`/museum-50`, `/museum-belt`, `/museum-match`, `/museum-wizard`, `/museum-wall-kit`,
`/museum-readiness`, `/hall-verdicts` — these are research and gallery surfaces, not
editors, and none claims to be one.

### Fix the index the same day

`src/app/museum-editors/page.tsx` currently tells a reader that `/museum-editor`
*"is a RULING in the same file the Godot dealer reads at the next build. Proven: a
web-ruled move was applied by the museum (`moved by hand [11,11] -> [12,11]`)."*
That was true before the 2026-09-08 *map is the placement authority* ruling. It is
now false for all 172 halls, and it is the most load-bearing wrong sentence in the
project, because it is the page people read to decide where to go.

---

## Where I am unsure, and what would settle it

1. **Whether the `authored: "map"` guard is intentional-forever or a stopgap.**
   The comment at `:7965` reads as doctrine (*"ONE TRUTH … Edits encode into
   map_data.json; rulings (props, frames, the gate, the enter room, the web's)
   still layer on"*) — note it names "the web's" among the rulings that survive,
   which suggests someone believed web artifact rulings still applied. Settled by:
   asking Palle, or by a forum thread. Either way the measurement stands — right
   now they do not.

2. **Whether 32 is the true engine-row count or an artifact of this machine.**
   `em_layout_walk.json` is gitignored, so I can only see this checkout's copy, and
   `vr_link_viewer.gd:13` claims 198. Settled by: `python -c` on the file after a
   full `--em-plan` walk, or by checking whether anything truncates it.

3. **Why `primitives|point one`'s engine row has `bodies` of length 2, both
   furniture with empty `tile_cell`, and `cards: []`** — while
   `em_showing_cards.json` holds 38 cards for that same hall from the same
   14:42 build. Either `_layout_built` is called before the bodies are stamped, or
   that walk was a partial one. Settled by: one walk of that hall with the
   `[em-edit]` prints captured, comparing `em_layout_walk.bodies` against
   `em_built.json.segments[].bodies`.

4. **Whether `/museum-editor` and `/api/museum-editor` are finished.** They were
   being rewritten as I read them. Re-check both hashes before acting on §2c.
