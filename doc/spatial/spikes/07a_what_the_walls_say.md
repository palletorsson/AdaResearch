# SPIKE 07a — what the walls already say about themselves

*Research only. No repo file edited, nothing staged, no Godot run.*

**PROVENANCE — and I got this wrong first, which is F0.** My opening check
covered only some of the paths I went on to cite, came back empty, and I wrote
"working tree == HEAD for all targets". It is not. Verified per-file against
HEAD (`e9202f138`):

| file | state | descriptions below are of |
|---|---|---|
| `tools/wall_bands.py` | clean | HEAD |
| `commons/data/template_patterns.json` | clean | HEAD |
| `commons/data/museum_contract_pilot.json` | clean | HEAD |
| `commons/data/wall_faces.json` | clean | HEAD |
| `commons/scenes/em/em_detail.gd` | clean | HEAD |
| `commons/scenes/em/em_lighting.gd` | clean | HEAD |
| `commons/scenes/em/em_props.gd` | clean | HEAD |
| `commons/testing/probe_housed_artifact.gd` | clean | HEAD |
| `tools/build_wall_faces.py` | **MODIFIED** | both — diffed, see F0/F1 |
| `tools/spatial_negotiation.py` | **MODIFIED** | HEAD (checked `git show`) |
| `tools/em_white_cube_measure.py` | **UNTRACKED — not in HEAD** | working tree only |
| `commons/data/museum_prop_placement_rules.json` | **UNTRACKED — not in HEAD** | working tree only |
| `commons/data/museum_module_kit.json` | **UNTRACKED — not in HEAD** | working tree only |

The three untracked files are not incidental — they are the prop declaration,
the tool behind HANDOVER §5's wall numbers, and the kit the gate probes. F0
records what that changes.

---

## QUESTION

Could the modular system hold PROP DEFAULTS at declared places along its walls,
applied when the endless museum is assembled — **without a second copy of the
geometry**? Specifically: what do the walls already say about themselves, is
`tools/wall_bands.py` already the single owner such a scheme would need, and
where should the ONE owner of each field live?

The constraint that decides it is HANDOVER §8: *"Two places holding one number
is this codebase's endemic bug."*

## PROBE

- `commons/data/template_patterns.json` — the tile vocabulary (a)
- `tools/wall_bands.py`, all 181 lines, plus every importer (b)
- `commons/scenes/em/em_detail.gd`, `em_lighting.gd`, and — unavoidably —
  `em_props.gd`, which turned out to be where the question actually lives (c)
- Re-derivation of the wall corpus from source, in-process, no writes (d)
- `museum_prop_placement_rules.json`, `museum_contract_pilot.json`,
  `museum_module_kit.json`, `wall_faces.json`, `em_white_cube_measure.py`

## BASELINE

The brief's own framing: `wall_bands.py` is "one reader for the museum and
hangar band schemes", and a prop-default scheme risks storing a position twice.

## PREDICTION WRITTEN FIRST

Committed before probing, from the brief's framing:

| # | prediction | outcome |
|---|---|---|
| P1 | `wall_bands.py` is close to the single owner; wiring a prop scheme to it is mostly plumbing | **WRONG.** It owns one of five vocabularies and the shipping museum reads none of it (F1) |
| P2 | The duplication risk is in the FUTURE scheme | **WRONG.** The duplication already shipped, in `em_props.gd` (F3) and `em_white_cube_measure.py` (F8) |
| P3 | A tile cell can't address a position along a wall | **RIGHT** (F5) — but the useful half is that it doesn't need to (see PROPOSED SCHEME) |
| P4 | The (d) numbers will mostly hold; maybe one is off | **RIGHT, one is off**: mean run is 2.41 m pooled, not 2.7 (F7) |
| P5 | "182 templates / 30 museums" is stale | **WRONG — it is exactly right** (F10) |
| P6 | The binding constraint is that 59% of walls are 1 m | **WRONG.** Length binds nothing; addressing does (F9) |
| P7 | (implicit, and the worst) the working tree is HEAD for everything I cite | **WRONG, and I published it before checking** (F0) |

Five of seven wrong, including the one I did not know I was making. Per §8 that
is where the value is.

---

## FINDINGS

### F0 — I diagnosed the working tree, and three of the files that carry this question are not in the repo at all.

**EXPECTED:** targets clean, so working tree == HEAD (my own opening check said so).

**ACTUAL:** `git status --porcelain` per file, plus `git cat-file -e HEAD:<f>`:

- `commons/data/museum_prop_placement_rules.json` — **untracked.** The "Museum
  principal-wall prop contract" that F4 is about **is not in the repository.**
- `commons/data/museum_module_kit.json` — **untracked.** HANDOVER §6 calls it
  "complete and certified"; it is not committed. `wall_bands.py:36` (which *is*
  in HEAD) points at it, so **on a fresh clone `_load(KIT)` returns `{}` and the
  4.0 m fallback is the only code path that ever runs.** F2 is not a latent bug
  in HEAD — it is the guaranteed behaviour.
- `tools/em_white_cube_measure.py` — **untracked.** Every wall number in
  HANDOVER §5 (5071 m, 2104 walls, 91.4%, 2.7 m, 59%) is produced by a tool a
  fresh clone does not have. The numbers reproduce here; they are not
  reproducible from HEAD.
- `tools/build_wall_faces.py` — **modified.** See F1: the fix I credited it with
  is uncommitted.
- `tools/spatial_negotiation.py` — modified, but its `wall_bands` import is
  genuinely in HEAD at `:850-855` (my working-tree line number 867 was wrong).

**CAUSE:** my opening `git status --short -- <paths>` listed only six of the
thirteen files I ended up citing, returned empty, and I generalised from it.
Identical in shape to spike 01's open question 4 ("`SPATIAL_PIPELINE.md` does not
exist" — concluded from a local `ls`), and to the `doc/spatial/CURRENT_STATE.md`
opening note. **Check the file you are about to cite, not the file you set out
to read.** This also matches the standing memory *"Uncommitted measurements break
worktrees"*: any worktree or clone of this branch resolves these three files to
nothing, silently.

**This strengthens rather than weakens the design conclusion:** the prop
declaration and the certified kit are not merely unread (F4) — they are not part
of the project's committed state, while the code that contradicts them
(`em_props.gd`, `em_detail.gd`) is.

### F1 — `wall_bands.py` is not the single owner. It is one of FIVE wall-height vocabularies, and the museum that ships reads none of it.

**EXPECTED:** one reader, two schemes, as the module docstring says
(`tools/wall_bands.py:2-25`).

**ACTUAL:** five live vocabularies for "how high a thing sits on a wall":

| # | scheme | numbers | owner | who reads it |
|---|---|---|---|---|
| 1 | museum low/eye/upper | 0–1.1 / 1.1–2.3 / 2.3–**4.0** | `museum_contract_pilot.json` `wall_system` | `wall_bands.py:65`; `probe_housed_artifact.gd:46` (a **test bench**) |
| 2 | hangar dado/hang/frieze | 0–0.9 / 0.9–2.1 / 2.1–3.2 | `wall_bands.py:45` HANGAR_BANDS | **in HEAD: nobody — the numbers are a second hardcoded copy at `build_wall_faces.py:50`.** The `from wall_bands import HANGAR_BANDS` at working-tree :55 is UNCOMMITTED |
| 3 | the museum's actual hang | **one line, `HANG_Y := 1.58`** | `em_detail.gd:213` | the shipping museum |
| 4 | the museum's readable band | skirt `0.13` → cornice `2.72` | `em_detail.gd:140,144` | `em_props.gd:124-125` (copied), `em_white_cube_measure.py:48-50` (copied) |
| 5 | per-prop mount heights | `H_EXTINGUISHER 1.10`, `H_ESTOP 1.05`, `H_PANEL 1.50`, `H_SCANNER 1.35`, `H_CLOCK 2.25`, `H_SCREEN 1.55`, `H_BOARD 1.30`, `H_WINDOW 1.70`, `H_HOSE_BOX 1.00`, `Y_EXIT_PORTAL 2.72`, `Y_EXIT_WALL 2.30` | `em_props.gd:152-169` | the shipping museum |

**Nothing in `commons/scenes/em/` imports, reads or references `wall_bands.py`
or either JSON it reads.** Grepped across HEAD (`git grep wall_bands HEAD`), not
just the working tree: **in HEAD `wall_bands.py` has exactly ONE importer** —
`spatial_negotiation.py:854`, `feature_field` only. `build_wall_faces.py` in HEAD
carries its own hardcoded `BANDS` tuple (`:50`); the de-duplicating import is an
uncommitted working-tree change (F0). So scheme 2 is **two copies in HEAD, one in
the working tree**, and the repair has not landed.

The only reader of `museum_prop_placement_rules.json` in *any* language is
`wall_bands.py:35` (bands block only) and the one-off, also-untracked
`build_uffizi_prop_placement_pilot.py:28`.

**CAUSE:** `wall_bands.py` was written as a *reconciliation report* between two
Python/data schemes, at a time when the question was "do the declarations
agree?". The museum builder was never in its scope. Scheme 3 is not even a band
scheme — it is a single centre line.

**This is the direct answer to (b): no, it is not the single owner a prop
scheme would need, and it is not close.**

### F2 — `wall_bands.check()` validates every scheme against a wall height that is a silent fallback, and the wall the museum actually builds is 3.0 m.

**EXPECTED:** `check()` reads the certified wall height from
`museum_module_kit.json` (`wall_bands.py:126-134`).

**ACTUAL:** two independent reasons the probe can never succeed. First, the kit
**is not in HEAD at all** (F0) — a clean checkout has no such file, `_load()`
swallows the exception at `wall_bands.py:57-61`, and `kit_h` is 4.0 by
definition. Second, even the untracked working-tree copy has no height at either
probed path: `museum_module_kit.json` → `wall_kit` keys are
`[schema, socket, piece_scene, composer_scene, width_cells, kinds, compositions]`.
Both `kit.get("wall_kit",{}).get("height_m")` and `kit.get("height_m")` return
`None`, so `kit_h` **always** falls back to `CERTIFIED_WALL_M = 4.0`
(`wall_bands.py:40`). The loop cannot fail; nothing prints.

Meanwhile the museum builds a **3.0 m** wall:
`em_detail.gd:137 const WALL_H := 3.0`, corroborated independently at
`em_lighting.gd:110 const WALL_H := 3.0` and
`em_props.gd:117 const WALL_H := 3.0  # endless_museum.gd wall boxes`.

Consequences the gate cannot see:

- museum `upper` band is **2.3 – 4.0 m**: **1.0 m of it is above the wall head**,
  and of the 0.42 m that is real (2.30 → 2.72) the top is the cornice springing.
- `check()` reports exactly ONE fault today, and it is the *least* important one:
  the hangar frieze stopping at 3.2 m on the phantom 4 m wall. Verified:
  `python tools/wall_bands.py --check` → 1 line, exit 1.
- Also stale: `check()`'s comment 1 (`wall_bands.py:113-122`) describes a feature
  field of 1.1–**2.7** m spilling into the eye band. The data now says 1.1–**2.3**
  (`museum_contract_pilot.json` `wall_system.feature_field.vertical_m`), so that
  branch is dead. The **2.7 survives only as `wall_bands.py:86`'s hardcoded
  fallback** — i.e. the one place still holding the retired number is the reader
  that exists to prevent exactly that. `probe_housed_artifact.gd:43-45` documents
  the 2.7 → 2.3 move and names the anti-pattern verbatim: *"A constant here would
  be a fourth opinion about eye height."*

**CAUSE:** two-places-holding-one-number, in the reader written to police it.
The kit is the ORPHANED module kit (HANDOVER §6, "the module kit stays
orphaned") — the gate asks the wall nobody builds and ignores the wall everybody
walks.

### F3 — `em_props.gd` already IS a prop-default table, hand-transcribed from `em_detail.gd`, with the source file named in a comment on every line.

**EXPECTED:** per (c), an implicit band scheme in code that `wall_bands.py` does
not own.

**ACTUAL:** worse and more useful — a fully explicit one.
`em_props.gd:115-132` is a block of eighteen constants each carrying a comment
naming the file it was copied from:

```gdscript
const WALL_H := 3.0           # endless_museum.gd wall boxes: y 1.5, size 3.0 -> 0..3
const DOOR_HEAD := 2.10       # em_detail.gd DOOR_HEAD
const CORNICE_BOTTOM := 2.72  # em_detail.gd — nothing may be hung above this
const SKIRT_H := 0.13         # em_detail.gd — nothing hangs below this
const BAY := 3.0              # em_detail.gd BAY — ceiling coffer and floor seam module
const SKY_Y := 2.92           # em_lighting.gd SKY_Y — nothing hangs below the ribs
```

and then `em_props.gd:152-169`, the actual prop defaults, nine `H_*` heights plus
two `Y_EXIT_*`. `em_props.gd:159` even cross-references the copy it is offset
from: `const H_CLOCK := 2.25  # above the picture band (em_detail hangs at 1.58)`.

**CAUSE:** GDScript has no cross-file constant import for these, so a comment was
used as the link. **The answer to Palle's design question is therefore not "could
the system hold prop defaults" — it already does. The question is which file owns
them, and today it is the renderer.**

### F4 — The declared prop contract reaches no GDScript, and where it can be compared it CONTRADICTS the code by up to 1.10 m.

**EXPECTED:** `museum_prop_placement_rules.json` ("Museum principal-wall prop
contract", schema `adaresearch.museum_prop_placement_rules.v1`) is consumed when
the museum is assembled.

**ACTUAL:** no `.gd` file anywhere in the repo mentions it — **and the file is
untracked, so it is not in HEAD** (F0). The comparison below is therefore
*working-tree JSON vs HEAD GDScript*, which is the honest framing: an uncommitted
declaration against committed code. Its five `prop_types` against `em_props.gd`:

| prop | JSON declares | `em_props.gd` does | verdict |
|---|---|---|---|
| `emergency_button` | `preferred_center_v_m: 1.05` | `H_ESTOP := 1.05` (:156) | agree — **by coincidence, not by reading** |
| `fire_extinguisher` | `mounting: floor_against_wall`, `preferred_base_v_m: 0` | `H_EXTINGUISHER := 1.10  # base of the cylinder. EN 3 hangs a portable unit` (:152) | **contradict by 1.10 m and by mounting kind** |
| `exit_sign` | `preferred_center_v_m: 3.15` | `Y_EXIT_WALL := 2.30` (:169), `Y_EXIT_PORTAL := 2.72` (:165) | **contradict; and 3.15 is 0.15 m ABOVE the 3.0 m wall head** |
| `station_panel` | `preferred_center_v_m: 1.9`, `size_m: [3.9, 0.8]` | `H_PANEL := 1.50` (:157) | contradict by 0.40 m |
| `station_crates` | `preferred_base_v_m: 0` | floor path, `_emit_floor_against_wall` (:1266) | agree |

The `exit_sign` case is the sharpest: a declared default that is **geometrically
impossible** in the building it declares against, sitting undisturbed because
nothing reads it. This is HANDOVER §7's *"0 of 182 declare white_cube, so the
paint works and reaches nobody"* recurring in the prop layer.

**CAUSE:** the contract was authored for the pilot compiler
(`build_uffizi_prop_placement_pilot.py`), which writes `prop_rule_source` into
its own metadata (:482), and the endless museum grew its own table in parallel.

### F5 — A tile cannot address a position along a wall. It cannot address a wall FACE either. Seven closed codes, no suffix syntax.

**EXPECTED, per (a):** find out whether a tile can address a position along a
wall or only a cell.

**ACTUAL:** only a cell, and not even that with any annotation.
`template_patterns.json:2` `_readme` defines the whole vocabulary:
`'' void, '1' floor, '1s' floor slot, '2' platform, '2s' podium slot,
'3s' high podium slot, '4' wall`. Census over all 182 patterns — exactly those
seven strings, **zero cells carry a colon, a suffix or any extra character**:

```
all 182 :  '1' 16808   '4' 6375   '2' 1008   '' 965   '2s' 858   '1s' 416   '3s' 58
30 museums: '1'  7601   '4' 4228   '2'  610   '' 618   '1s' 233   '2s' 212   '3s' 30
```

Note the interactables layer of `map_data.json` *does* have a suffix grammar
(`artifact:rotation:y_offset`, and `artifact#axis:value`) — but template tiles do
not share it. A `"4"` is one cell with up to four faces and no way to say which.

**A wall is therefore a DERIVED thing, twice over.** `em_detail.gd:498-520`
`_dressed_faces()` derives one face per (wall cell × direction that has a floor
neighbour); `_add_wall_showings` (:566-640) then groups faces into runs
(:578) and cuts runs into contiguous stretches. `em_props.gd:606` has its own
`_dressed_faces`, and `build_wall_faces.py:229` `faces_of()` a third, in Python.

**CAUSE:** the tile is a paint format for `/template-pattern-editor`, seeded
2026-07-15 for a different purpose. It was never a placement address.

### F6 — the run identity a prop default would have to name is a formatted float key, and it is derived fresh on every stamp.

`em_detail.gd:578`:

```gdscript
var key: String = "%s|%.2f|%.0f|%.0f" % [
    "x" if along_x else "z", fixed, float(fd["nx"]), float(fd["nz"])]
```

A run has no name. Its identity is its axis, its fixed coordinate to 2 dp, and
its outward normal. **Good news, and it is load-bearing for the scheme:** the
coordinates are SEGMENT-LOCAL — `em_detail.gd:458-471 _map_tile()` writes
`z = y + VESTIBULE_H` from tile indices, so the frame is the tile's own, not the
world's. A default keyed to tile cells therefore **cannot** catch spike 03's 4 m
offset. A default keyed to anything world-shaped would catch it immediately.

Within a stretch, positions are dealt: one showing per `HANG_PITCH_FACES` (2 m,
`em_detail.gd:221`), centred in its group, cap dealt round-robin across runs
(:587-640). Deterministic, no `randf` (:561-565) — but **ordinal, not nameable**.

### F7 — (d) re-derived: every number holds EXCEPT the mean, which is a mean-of-means.

Re-derived in-process from `template_patterns.json` (**HEAD-clean**) through
`em_white_cube_measure.py`'s own `dressed_faces` + `stretches_of` (no writes).
Caveat from F0: that tool is **untracked**, so these figures are reproducible
here and *not* from a clean checkout of HEAD — which is itself worth knowing,
since HANDOVER §5 presents them as settled corpus facts.

| brief's claim | measured | verdict |
|---|---|---|
| 5071 m of wall run | **5071** | ✅ exact |
| across 2104 walls | **2104** | ✅ exact |
| 91.4% of band area bare | **91.4%** (pooled) | ✅ exact |
| 59% of walls exactly 1 m | **1241 / 2104 = 59.0%** | ✅ exact |
| runs ≥4 m are 55.1% of cells | **440 walls, 2794 m = 55.1%** | ✅ exact |
| all 30 museums can host a 4 m panel | **min longest run = 4** | ✅ **but by one museum and one metre** |
| **mean unbroken run 2.7 m** | **2.41 m pooled** (5071 / 2104) | ❌ **2.7 is the mean of 30 per-building means** |

**CAUSE of the 2.7:** `em_white_cube_measure.py`'s table prints a `MEAN of 30`
row that averages the per-template `mean` column — an unweighted mean of means.
HANDOVER §5 quotes it in a row whose other three figures (5071, 2104, 91.4%) are
*pooled*. Two aggregations in one sentence. Not wrong, but not the same
statistic, and the pooled figure is 12% lower.

Also: "all 30 can host a 4 m panel" is true on the thinnest possible margin —
**`pompidou-plateau-libre` is the only museum whose longest run is exactly 4**,
and `museum_prop_placement_rules.json` declares `station_panel` at
`size_m: [3.9, 0.8]`. A 3.9 m panel on a 4.0 m run leaves 50 mm each side. Cross-
reference `build_wall_faces.py:195-209 mount_window()`, whose whole docstring is
the record of a 4.9 m bar hung off the end of its wall in Castelvecchio.

### F8 — the two rival definitions of "wall run" HANDOVER §8 warns about are both live, in one file, and one of them drives the budget.

`tools/em_white_cube_measure.py` exports **both** `perimeter_of()` and
`dressed_faces()`/`stretches_of()`. `for_segment()` computes
`wall_run = perimeter_of(tile)` and spends the feature licence against it
(`wf_max = gd_round(wall_run * 0.1 * wf)`), while every wall statistic in the
same file's table comes from `stretches_of(dressed_faces(...))`.
`em_props.gd:803` has a third, `_perimeter_m()`.

Corpus scale of the gap: the 30 museums hold **4228 tile `"4"` cells** but
**5071 dressed-face metres** — a wall cell can present up to four faces, and the
vestibule adds walls no tile contains. The two numbers differ by 20% and both
are called "wall run".

### F9 — the binding constraint on a default scheme is not wall length. It is that nothing is addressable.

The brief asks which of (d) binds. Measured, the length distribution binds
almost nothing:

- 91.4% of readable band area is **already bare**. There is no competition for
  space; a default scheme is not fighting for room.
- The 1 m walls are 59% of *walls* but only **24.5% of the run** (1241 of
  5071 m). "A 1 m wall cannot carry a 2 m bench" is true and costs little,
  because the 1 m walls are a quarter of the surface.
- The ≥4 m runs are 21% of walls but **55.1% of the surface**, and all 30
  buildings have at least one.

So the corpus can physically host defaults. What it cannot do is **name where
one goes** (F5, F6). The constraint that binds is addressing, and the constraint
that *decides the design* is F1/F3/F4: the numbers a default would need already
exist in three-to-five places, so any new field is a sixth copy unless it
displaces one.

The one length fact that does bind a specific declaration: **`station_panel` at
3.9 m fits only 440 of 2104 walls (20.9%)**, and in one museum with 50 mm spare.

### F10 — "182 templates of which 30 are real museums" is EXACTLY right.

Re-derived: `len(patterns) == 182`. Filtering on truthy `museum` → **30**. The
`museum` key is present on exactly those 30 and absent on the other 152, so the
`.get("museum")` filter used at `build_wall_faces.py:119-122` and
`compile_museum_map.py:51-54` cannot drift. Prefixes: `bay:` 91, `lattice:` 51,
plain 34, `beat:` 6 — matching HANDOVER §5's account of bays as partitions and
lattice/beat as wallpaper courses. **P5 was wrong; this number is sound.**

### F11 — `commons/data/wall_faces.json` is a generated file 10 museums behind its source.

`museums()` returns **30**; `wall_faces.json` contains **20**. Missing:
`capuchin-crypt-corridor`, `caracalla-thermal-axis`, `castelvecchio-pinch-v2`,
`kanazawa-vista-v2`, `katsura-miegakure-circuit`, `labrouste-stack-hall`,
`mengoni-glazed-thoroughfare`, `mesdag-panorama-drum`, `sando-threshold-run`,
`thoronet-circumambulation-void`.

Its own `_readme` says *"regenerate after tile changes"* and it was not. It also
embeds a `bands` block (`dado/hang/frieze` + `y_offset` 0.45/1.5/2.6) — a
**fourth serialised copy** of scheme 2, now frozen in a stale artefact. This
matters for the design: it is the one file in the repo whose shape *is* what a
prop-default scheme wants (per-museum, per-run, with facing/front/standoff) —
and it is the proof that a generated sidecar goes stale silently. **A prop
default must not live in a derived file.**

---

## EVIDENCE

Commands run, all read-only, all against HEAD:

```bash
# per-file, the check I should have run first (F0)
git status --porcelain -- <f>; git cat-file -e HEAD:<f>
git show HEAD:tools/build_wall_faces.py | sed -n '50,60p'   # hardcoded BANDS
git grep -n "wall_bands" HEAD -- '*.py' '*.gd'              # 1 real importer
git diff -- tools/build_wall_faces.py                       # the uncommitted import

python tools/wall_bands.py                        # 5 museum + 3 hangar bands
python tools/wall_bands.py --check                # 1 fault, exit 1 (F2)
python tools/em_white_cube_measure.py             # the 30-row table, no --json
```

In-process re-derivations (no writes, no Godot):

```
templates 182 / museums 30                        (F10)
tile code census, 182 and 30                      (F5)
stretches 2104, run 5071 m, mean 2.41 m           (F7)
1 m walls 1241 = 59.0% of walls, 24.5% of run     (F7, F9)
>=3 m 630 walls 3364 m 66.3% | >=4 m 440 walls 2794 m 55.1%
>=5 m 290 walls 2194 m 43.3% | >=6 m 131 walls 1399 m 27.6%
min longest run across 30 = 4 (pompidou-plateau-libre, sole)
museums() 30 vs wall_faces.json 20                (F11)
museum_module_kit.json wall_kit.height_m -> None  (F2)
```

Key file:line references: `wall_bands.py:40,45,51,86,113,126`;
`build_wall_faces.py:55,119,195,229`; `spatial_negotiation.py:867`;
`em_detail.gd:137,140,144,213,221,458,498,566,578`;
`em_lighting.gd:110,114,118`;
`em_props.gd:115-132,152-169,606,803,1242,1266`;
`probe_housed_artifact.gd:39-48`; `em_white_cube_measure.py:44-58`;
`template_patterns.json:2`.

---

## PROPOSED SCHEME (not applied)

**The finding that shapes it:** the defaults already exist (F3), already have a
declaration file (F4), and the declaration already reaches nobody. So the change
is not "add a prop-default system". It is **make the existing declaration the
owner and delete the copies**. Per HANDOVER §8: *prefer turning a knob to adding
a system.*

### What a prop-default declaration would have to name — and who owns each field

| field | who owns it | why that owner, and what must NOT hold it |
|---|---|---|
| **which prop** | `museum_prop_placement_rules.json` → `prop_types.<token>` | already the declaration; already keyed by registry token. **Step 0 of any of this is committing that file** — it is untracked today (F0), and an owner that is not in the repo is not an owner |
| **preferred height (v)** | **`museum_prop_placement_rules.json`** — `preferred_center_v_m` / `preferred_base_v_m` | it already declares these. `em_props.gd:152-169`'s `H_*` and `Y_EXIT_*` must become *nothing* — deleted, not defaulted-to, or they are the second copy that survives (F4) |
| **band name** | `museum_contract_pilot.json` → `wall_system` | already the declaration; already has a Python reader (`wall_bands.py:65`) and a proven GDScript reader pattern (`probe_housed_artifact.gd:46`) |
| **band → metres** | `wall_bands.py` for Python; **one new GDScript reader promoted out of `probe_housed_artifact.gd`** | the probe already does it correctly and says why. Promoting it is a move, not a copy. `wall_bands.py:86`'s stale 2.7 fallback must go with it |
| **wall head height** | **`em_detail.gd:137 WALL_H`** — the thing that builds the wall | must be *published* so `wall_bands.check()` reads it instead of `CERTIFIED_WALL_M` (F2). The orphaned kit must stop being consulted |
| **horizontal position along the run** | **the tile cell in `template_patterns.json`** | it is the only segment-local, author-editable, already-stamped address (F6). A world coordinate reproduces spike 03's 4 m offset by construction |
| **which FACE of that cell** | **derived — `em_detail.gd:498 _dressed_faces()`** | a `"4"` cell has up to 4 faces and exactly one faces a floor in each direction. Storing it duplicates the tile |
| **rotation** | **derived — the face normal**, `em_props.gd:1258 atan2(nx, nz)` | already derived correctly. Storing a rotation next to a face IS the endemic bug; this is the field spike 03 got wrong |
| **standoff / what fits** | **derived — `build_wall_faces.py:212 max_area()`** from `museum_principles.json` | a viewing-distance rule, not a stored number |
| **prop size** | **the measured AABB** (`registry measurements.aabb_size`) | `museum_prop_placement_rules.json`'s `size_m` is *already* a third copy of a measurable fact. HANDOVER §6: "the measurement wins on body size; the room wins on intent." Height is intent; size is geometry |

### The shape

A default is a **(prop token, band name)** pair in
`museum_prop_placement_rules.json` — declaring *intent* only. Everything spatial
is derived at assembly:

```
prop token ──> prop_placement_rules: band name + preferred v + mounting kind
band name  ──> contract_pilot wall_system: v range in metres
tile cell  ──> em_detail._dressed_faces(): the face, the normal
face normal──> the rotation
standoff   ──> max_area(): whether this prop may stand here at all
```

**No coordinate is stored anywhere.** The only new *data* is the band name on a
prop type, in the file that already declares prop types. Nothing gets a second
copy; three things lose theirs (`em_props.gd`'s H_* table, `wall_bands.py`'s
2.7 fallback, `check()`'s phantom 4 m wall).

### Additive and gated, per §8

A building with no band declared on its props must be byte-identical. Since
`em_props.gd` currently sources every height from its own constants, the gate is:
read the JSON, fall back to the constant **only while the migration runs**, and
delete the constant in the same commit that proves the JSON is read. Leaving
both is the failure mode this whole spike is about.

### What I would NOT do

- Do **not** put defaults in `wall_faces.json` or any generated sidecar (F11 —
  it is already 10 museums stale and nothing noticed).
- Do **not** extend the tile cell code with a suffix (F5). It would put a
  height in the geometry file and make `template_patterns.json` a second owner
  of the band scheme.
- Do **not** merge the museum and hangar schemes. `wall_bands.py:16-21` argues
  correctly that they are different contexts. The problem is not that there are
  two schemes; it is that there are five and the museum reads none.

---

## NEGATIVE TEST

**Must FAIL today, PASS after.** Three assertions; the first is the real one.

**N1 — the declaration must bite.**
Change `museum_prop_placement_rules.json` → `prop_types.exit_sign
.preferred_center_v_m` from `3.15` to `1.20`, re-derive the museum's prop plan
for `uffizi-spine-enfilade`, and assert **the exit sign's world y moved**.
*Today it cannot move:* no `.gd` reads that file, and the height comes from
`em_props.gd:169 Y_EXIT_WALL := 2.30`. The test fails today by measuring
**0.00 m of movement**, which is the signature of an unwired declaration — the
same one that made 22 museums certify a door the sightline never touches
(HANDOVER §7.4).

**N2 — the phantom wall must be caught.**
`python tools/wall_bands.py --check` must report that the museum `upper` band
tops at 4.0 m on a **3.0 m** wall, and that `exit_sign`'s declared 3.15 m centre
is above the wall head. *Today it reports neither*, because `kit_h` silently
falls back to `CERTIFIED_WALL_M = 4.0` (F2). Assert the fault COUNT rises from
1 to at least 3, and assert the printed height is `3` — not merely that the
count changed, or the silent fallback can satisfy it again.

**N3 — assert the TYPE and the UNIT, not the value.**
`preferred_center_v_m` is metres; `HANG_PITCH_FACES` is a count of 1 m faces;
`front`/`cells` are cell indices. On a 1 m grid all three compare equal by
value (HANDOVER §8, spike 01 F4/F5). The reader must return a tagged metre value
and the test must `assertIs(type(...), ...)`. Without N3, N1 and N2 can both
pass while a cell count is being read as a height.

**Noise floor:** N1–N3 are all exact-arithmetic assertions on the plan, not
pixel deltas, so the 1.020% biome reseed floor does not apply. No capture is
needed and none should be run — this is a fact about the STAMP, not the render
(`em_white_cube_measure.py:13-16`).

---

## OPEN, for Palle

0. **Three files that this design depends on are untracked** (F0):
   `museum_prop_placement_rules.json`, `museum_module_kit.json`,
   `em_white_cube_measure.py`. Commit or delete them before anything else — while
   they float, HANDOVER §5's wall numbers and §6's "certified kit" ruling cannot
   be reproduced from the repository, and any worktree silently disagrees with
   this one. Check for a concurrent writer first (§4 trap: never `git add -A`).
1. **`fire_extinguisher` is the one that needs a human ruling** (F4): the JSON
   says floor-standing at v=0, `em_props.gd:152` says wall-hung at 1.10 m citing
   EN 3. Both are defensible real-world practice. Whichever wins, the loser must
   be deleted, not defaulted-to.
2. `exit_sign` at 3.15 m cannot be honoured on a 3.0 m wall. Lower the
   declaration, or raise `WALL_H` — the second is a core-geometry change and
   would need the grid-guard discipline from CLAUDE.md.
3. Should the museum `upper` band be re-declared **2.3 – 2.72** (the real
   readable top, `CORNICE_BOTTOM`)? It currently promises 1.0 m of wall that has
   never existed, and `wall_bands.check()` structurally cannot say so.
