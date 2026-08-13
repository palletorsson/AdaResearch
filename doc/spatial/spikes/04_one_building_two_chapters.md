# SPIKE 04 — seven chapters with a plan no building can receive

*Research pass, 2026-08-13. No repo file was edited; no Godot was run (LAW 2).
Every source cited was compared against HEAD before it was read — see VERIFIED
AGAINST HEAD below.*

## QUESTION

`em_plan.json` is keyed by BUILDING. The crown/rotation policy gives 24 chapters
17 distinct buildings. What actually happens to the other seven — is the loss
announced, and what is the right shape of key?

## VERIFIED AGAINST HEAD

`git diff --quiet HEAD -- <path>` is clean for every file this spike diagnoses:

```
CLEAN  tools/export_museum_plan.py          CLEAN  commons/data/museum_crowns.json
CLEAN  tools/spine_run.py                   CLEAN  commons/data/template_patterns.json
CLEAN  commons/scenes/endless_museum.gd     CLEAN  commons/data/spine_artifact_order.json
CLEAN  ada_run/em_plan.json                 CLEAN  doc/reports/spine_run.md
```

**One caveat that matters.** `ada_run/spine_run.json` — the per-chapter
measurement this spike quotes for the size of the loss — is **UNTRACKED**
(`git ls-files` errors on it). It is working-tree-only evidence produced by the
run that wrote the committed `em_plan.json` at `603265862`. Its aggregate agrees
with the committed `doc/reports/spine_run.md` table row for row, and its
per-chapter interior counts sum to the report's 383, so I treat it as
corroborated rather than trusted. `ada_run/spine_run/**` (the capture and sort
logs) is likewise untracked.

## PROBE

- `tools/export_museum_plan.py::main` / `::plan_museum` — the generic exporter
- `tools/spine_run.py::assign_museums` / `::write_plan` — the 24-chapter writer
- `commons/scenes/endless_museum.gd::_build_segment` / `::_deal_from_plan` — the reader
- `commons/data/museum_crowns.json`, `commons/data/template_patterns.json`
- `ada_run/em_plan.json` (committed), `ada_run/spine_run.json` (untracked)
- `ada_run/spine_run/capture/*.log`, `ada_run/spine_run/sorts/both.log` (untracked)

## PIPELINE TRACE

```
spine_artifact_order.json ─┐
museum_crowns.json ────────┼─► assign_museums()   24 chapters → a building each
template_patterns.json ────┘        │
                                    ▼
                          write_plan()  ── keyed by BUILDING ──► ada_run/em_plan.json
                                    │                                   │
                            7 collisions dropped                        │
                            (recorded in _spine_run.displaced)          │
                                                                        ▼
                                                          endless_museum.gd --em-plan
                                                          _build_segment  :1051
                                                            next_seq  :1056-1058   ← chapter, computed
                                                            crown/rotation :1059-1068 → spec.key
                                                          _deal_segment   :1425
                                                            _deal_from_plan :1367   ← keyed on spec.key ONLY
                                                              next_seq never consulted
                                                              _pick_pool never called
```

The chapter is in scope at the call site (`next_seq`, line 1056) and is not
passed to the reader. That single omission is the whole spike.

## BASELINE

`doc/reports/spine_run.md` §2, committed, states the position this spike is
testing:

> "The exporter gives the key to the first chapter in curriculum order and
> records the other seven under `_spine_run.displaced` rather than silently
> overwriting. **In the live corridor there is no collision, because a building
> is re-entered segment after segment in time; the collision is a property of
> the plan FILE.**"

The first sentence is true and I verified it. The emphasised sentence is the
one I set out to falsify, and it is false in both of its clauses.

## PREDICTION WRITTEN FIRST

Written before running the derivation, in this order:

| # | prediction | outcome |
|---|---|---|
| P1 | at least one of 24 / 17 / 7 is stale | **WRONG — all three re-derive exactly.** 24 chapters, 17 distinct buildings, 7 displaced, reproduced byte-for-byte against the committed `_spine_run.owner` map |
| P2 | the 7 collisions are crown-vs-crown: grande×4 + sainsbury×2 = 6 chapters over 2 buildings = 4 losses, so 20 buildings and 4 displaced | **WRONG, and this is the finding.** 6 of the 7 are crown-vs-ROTATION. The rotation does not skip a building a crown has reserved |
| P3 | `write_plan` is silent last-wins | **WRONG.** It is first-wins and it announces, in-file and on stdout. The doctrine is satisfied *there* |
| P4 | the scene checks the plan entry's chapter before stamping it | **WRONG.** No chapter check exists |
| P5 | the templates line, "182 keys of which 30 are museums" | **RIGHT.** 182 keys: 91 `bay:`, 51 `lattice:`, 6 `beat:`, 34 plain, of which 30 carry a truthy `museum` |

P1 agreeing is worth little. P2 and P3 disagreeing are worth the pass.

## FAILURES

### F1 — the rotation never skips a crowned building, so the crowns are what get thrown away

EXPECTED (P2): collisions happen between chapters that share a crown, so the
crowned chapters keep their ruled buildings and the *overflow* crowned chapters
lose.

ACTUAL: **all seven displaced chapters are crowned chapters, and six of the seven
are displaced by an UNCROWNED chapter that the `em_order` rotation happened to
hand the same building.** Of the eight crowns ruled by the museum match
tournament, exactly one survives into the plan.

```
change                → grande-galerie-axial   held by symmetry        (crowned displaced by rotation)
forces                → sainsbury-...-enfilade held by primitives      (crowned displaced by crowned)
lsystems              → grande-galerie-axial   held by symmetry        (crowned displaced by rotation)
isosurfaces           → castelvecchio-pinch-v2 held by formfinding     (crowned displaced by rotation)
graphtheory           → grande-galerie-axial   held by symmetry        (crowned displaced by rotation)
foundationscrisis     → grande-galerie-axial   held by symmetry        (crowned displaced by rotation)
postfoundationscrisis → uffizi-spine-enfilade  held by transformation  (crowned displaced by rotation)

crowned chapters displaced: 7 of 8.   surviving crown: primitives (sainsbury).
```

CAUSE: `tools/spine_run.py:110-116` (and the code it reproduces,
`commons/scenes/endless_museum.gd:1055-1068`) advances the rotation cursor `i`
only for uncrowned chapters, but never *excludes* a crowned building from the
rotation. The rotation's first five entries are
`uffizi-spine-enfilade, grande-galerie-axial, altes-rotunda-hub,
castelvecchio-endstopped-enfilade, castelvecchio-pinch-v2` — three of those five
are crowned to a later chapter. Uncrowned chapters 2, 3 and 8 (`transformation`,
`symmetry`, `formfinding`) therefore reach those buildings *earlier in
curriculum order* than the chapters that were ruled into them, and first-wins
hands them the key.

CONSEQUENCE: the crown file is a ruling backed by a scored tournament
(`museum_crowns.json`: grande-galerie-axial won `change` by 7.73 vs 6.83, the
largest margin in the match). The plan file discards seven of those eight
rulings, and the mechanism that discards them is an alphabetical-ish rotation
constant, `em_order`, that has no opinion about the curriculum at all.

file:line — `tools/spine_run.py:97-117`, `commons/scenes/endless_museum.gd:1055-1068`

---

### F2 — the in-file note beside the loss is wrong about the loss

EXPECTED: the note written next to `_spine_run.displaced` describes the
displacement it just recorded.

ACTUAL: `ada_run/em_plan.json` carries

> `"note": "one chapter per museum; em_plan.json is keyed by building, and six chapters share three crowned buildings"`

Three errors in one clause: it is **seven** chapters, over **four** buildings,
and only **one** of the seven collisions is a shared crown. `write_plan`'s
docstring states the same wrong model:

```python
# tools/spine_run.py:261-266
"""Four chapters are crowned to `grande-galerie-axial` and two to
`sainsbury-...`, and `em_plan.json` is keyed by MUSEUM, so a museum serving
several chapters can only carry one."""
```

That model predicts 4 losses (3 grande + 1 sainsbury). The code, running
correctly, produced 7 and wrote the number `7` into the file two lines above the
sentence that says `six`. Nothing compares them.

CAUSE: the note is a hand-typed literal at `tools/spine_run.py:295-297`, not
derived from `displaced`. Same class as the DNA lesson in CLAUDE.md — a
hand-typed declaration beside a derived measurement, and the green run is about
the literal.

file:line — `tools/spine_run.py:295-297`; `ada_run/em_plan.json` `_spine_run.note`

---

### F3 — the live corridor DOES collide, and there the loss is silent

EXPECTED (`doc/reports/spine_run.md` §2): "In the live corridor there is no
collision… the collision is a property of the plan FILE."

ACTUAL: `_deal_from_plan` looks the plan up by building and never consults the
chapter, so when the corridor builds `change` — crowned to
`grande-galerie-axial` — it finds `symmetry`'s plan under that key and stamps
**symmetry's thirteen bodies into change's room.** This is not a shortfall; it is
a substitution, and it is worse than the loss the file announces.

```gdscript
# commons/scenes/endless_museum.gd:1367-1374
func _deal_from_plan(seg: Node3D, zbase: int, key: String, tile: Array,
		w: int, h: int) -> Dictionary:
	if not _plan_db.has(key):
		return {}
	var entry: Dictionary = _plan_db[key]
	var rows: Array = entry.get("artifacts", [])
```

`entry["sequence"]` — which `write_plan` sets on every museum
(`tools/spine_run.py:285`) and which is present on all 17 entries in the
committed file — is never read.

And nothing announces it. Three would-be announcers all print a dash:

1. `_deal_from_plan` returns `"sequence": ""` hardcoded
   (`endless_museum.gd:1418`), so `seg_seq` (`:1175`) is empty.
2. The threshold banner (`:1214`) therefore shows the museum's label only, with
   no chapter line — the one thing a walker could read.
3. The segment log (`:1300`) prints `chapter=-`.

MEASURED, from the committed run's own capture logs (untracked evidence,
`ada_run/spine_run/capture/*.log`), all four planned buildings:

```
[endless_museum] seg 0 = grande-galerie-axial (Louvre — Grande Galerie, Paris) chapter=- placed 7/13 …
[endless_museum] seg 0 = sainsbury-false-perspective-enfilade (…) chapter=- placed 20/80 …
[endless_museum] seg 0 = louisiana-pavilion-chain (…) chapter=- placed 21/72 …
[endless_museum] seg 0 = teshima-droplet (…) chapter=- placed 17/36 …
```

Against the same scene *without* `--em-plan` (`ada_run/spine_run/sorts/both.log`),
which prints the chapter every time:

```
[endless_museum] seg 0 = sainsbury-false-perspective-enfilade chapter=primitives placed 14/14 …
```

So the doctrine holds in the exporter and fails in the assembler: the announced
loss is in the file, the silent one is in the room.

file:line — `commons/scenes/endless_museum.gd:1367-1374`, `:1418`, `:1175`, `:1214`, `:1300`

---

### F4 — the plan path freezes the pool cursor, so the corridor cannot reach chapter 2 at all

EXPECTED: with `--em-plan`, the corridor walks the curriculum and each chapter is
stamped from its plan; seven chapters get the wrong plan (F3) and the rest are
correct.

ACTUAL (read from source; **not run** — LAW 2): under `--em-plan` the corridor
never leaves the first chapter, so it is not seven chapters that no building
receives but **twenty-three**.

The chain:

- `_pool_i` is advanced in exactly one place, `_pick_pool` at
  `endless_museum.gd:780`.
- `_pick_pool` is called from exactly one place, `endless_museum.gd:1479`, inside
  the dealer body of `_deal_segment`.
- `_deal_segment:1430-1433` returns `_deal_from_plan`'s result *before* reaching
  the dealer whenever the current building has a plan.
- `_deal_from_plan` reads `_pool` only to build a `token → scene` map
  (`:1378-1380`) and calls `_stamp` directly. It never advances the cursor.
- `_build_segment:1056-1058` derives the next chapter as
  `_pool[_pool_i % _pool.size()].sequence`.

So with a plan loaded, `next_seq` is pinned to `_pool[0]`'s sequence for the
whole run. The capture logs confirm `_pool[0]` is `primitives`
(`pool: SPINE ORDER, 756 of 799 curriculum artifacts alive`, and the unplanned
run prints `chapter=primitives` at seg 0). `primitives` is crowned to
`sainsbury-false-perspective-enfilade`, which **is** one of the 17 planned
buildings — so every segment after the first picks Sainsbury, finds the plan,
stamps the identical 20 objects, and leaves the cursor where it was.

Two consequences that separate this from the already-known "a crowned chapter
repeats its building" (`order_to_walk.md` §3):

- Without the plan, the dealer *does* advance: `both.log`'s six Sainsbury
  segments place 14/12/13/10/14/12 different bodies and would leave `primitives`
  after roughly seven segments (82 curriculum rows at 12–14 per segment). With
  the plan, every segment is the same 20 objects in the same cells.
- `--em-first=X` only moves segment 0 (`:1061` suppresses the crown at
  `_seg_index == 0` when `_first_key` is set). Segments 1..N are Sainsbury
  regardless.

WHY NOBODY SAW IT: every `--em-plan` run on record used `--em-segments=1`
(`tools/spine_run.py:457`), and every multi-segment run (`sorts_mode`,
`--em-segments=6`) omitted `--em-plan`. The two flags have never been used
together.

file:line — `commons/scenes/endless_museum.gd:780`, `:1479`, `:1430-1433`,
`:1367-1380`, `:1056-1058`, `:1061`

---

### F5 — `export_museum_plan.py` is the silent overwrite the exporter was praised for avoiding

`spine_run.write_plan` is careful. The tool it calls into is not.

`tools/export_museum_plan.py:222-234` writes the whole of `ada_run/em_plan.json`
from scratch on every invocation, with no read of the existing file, no merge and
no warning. `--sequence=change` plans *one* chapter's cast into *all 30*
museum-truthy keys and replaces a 17-chapter spine plan with it. The resulting
file has:

- no `_spine_run` block at all;
- no `sequence` field on any museum entry — `plan_museum` (`:107-149`) does not
  set one; only `write_plan` does, afterwards (`spine_run.py:285`);
- the chapter recorded only at top level, in `cast.sequence` (`:229-232`), a key
  `_deal_from_plan` never reads.

So `_deal_from_plan` cannot distinguish a 24-chapter spine plan from a
single-chapter export, and the documented gate — "a museum key absent from the
plan deals exactly as before" — silently becomes "every museum stamps `change`'s
cast" the moment somebody runs the exporter's own documented example.

Secondary, same file: `--all` selects on `v.get("museum")` and plans all 30,
including the four `challenger: true` templates
(`castelvecchio-endstop-pinch`, `kanazawa-matrix-vista`, `uffizi-spine-ordered`,
`kanazawa-vista-v2`), which `endless_museum.gd:594` explicitly excludes from the
corridor. Four of every thirty planned buildings can never be built. The same
divergence sits in `spine_run.museum_rotation()` (`:83-87`), which also omits the
challenger filter — it does not bite today only because those four are the only
museums with no `em_order` and sort to positions 27-30, past the 16 the
uncrowned chapters consume. That is luck, not design: give any challenger an
`em_order` below 16, or add a 17th uncrowned chapter, and `spine_run`'s
"reproduce the museum's own choice" stops reproducing it.

file:line — `tools/export_museum_plan.py:170-190`, `:222-234`, `:107-149`;
`tools/spine_run.py:83-87`; `commons/scenes/endless_museum.gd:594`

## EVIDENCE

**a) The keying.** `em_plan.json` is
`{"schema","_readme","_spine_run","offered","museums"}`; `museums` is a flat dict
whose **key is the template key** (`grande-galerie-axial`) and whose value is
`{artifacts[], rejected[], room{w,h}, apron, interior_count}` — plus `sequence`,
but only when written by `spine_run.write_plan`. Collision handling depends
entirely on which writer ran:

| writer | on collision | announced? |
|---|---|---|
| `spine_run.write_plan` (`:277-286`) | **first in curriculum order wins**, the rest skipped | **yes** — `_spine_run.displaced` in-file, plus `plan -> … (17 museums, 7 chapters displaced)` on stdout |
| `export_museum_plan.main` (`:209-234`) | n/a — one cast into every museum | — but it **overwrites the whole file**, silently (F5) |
| `endless_museum._deal_from_plan` (`:1367`) | **no collision detection** — stamps whatever the building's key holds | **no** (F3) |

**b) 24 → 17, re-derived.** Reproduced from the same two files the scene reads,
independent of the committed plan, then compared: the owner map matches
`_spine_run.owner` **byte-for-byte**.

```
182 pattern keys · 30 truthy museum · rotation length 30 (26 after the scene's challenger filter)
8 crowns → 4 distinct buildings (grande ×4, sainsbury ×2, castelvecchio-pinch-v2 ×1, uffizi ×1)
24 chapters · 8 crowned · 16 uncrowned consuming rotation[0..15]
→ 17 distinct buildings · 17 owners · 7 displaced
```

**c) The size of the loss.** From `ada_run/spine_run.json`, cross-checked against
the committed `spine_run.md` table:

| | rows | offered | placed | interior |
|---|---|---|---|---|
| the 17 chapters that own a building | 538 | 792 | 507 | 281 |
| **the 7 displaced chapters** | **261** | **364** | **171** | **102** |
| whole spine | 799 | 1156 | 678 | 383 |

**102 of 383 interior placements — 26.6% of everything the negotiator managed to
house across the whole curriculum — are computed and then dropped by the writer.**
32.7% of the curriculum's rows are in a chapter with no plan entry.

**d) The file contradicts itself about its own roster.** `offered` is built as the
union of all 24 casts (`spine_run.py:298`) = **944 tokens**. Only **667** of those
appear anywhere in `museums` (placed or rejected). **277 tokens — 29.3% — are
advertised as offered and mentioned nowhere**, and 276 of the 277 are tokens that
occur only in a displaced chapter (`ContextFreeGrammars`, `KonigsbergBridge`,
`GyroidDemo`, …). The `displaced` list names chapters; nothing names the bodies.

**e) Answer to (c), the doctrine question — the loss is announced in one place of
three, and the place it is silent is the one that reaches a walker.**

- exporter → file: **announced** (`_spine_run.displaced`, stdout).
- exporter → file, generic path: **silent whole-file overwrite** (F5).
- file → room: **silent, and a substitution rather than a loss** (F3), with the
  chapter name present in the file and discarded by the reader (`:1418`), so the
  banner and the log both print a dash.
- corridor: **silent freeze** (F4) — 23 chapters never get a segment.

## PROPOSED FIX (not applied)

**(i) — a compound key, (building, chapter).** Argued below against the other two.

Shape, additive and gated in the CLAUDE.md sense:

```
museums: { "<building>": { … } }                    # v1, still read
plans:   [ {"museum": "<key>", "sequence": "<seq>", …} ]   # v2, chapter-keyed
```

`_deal_from_plan` gains the chapter it already has in scope
(`next_seq`, `:1056`) and looks up `(key, next_seq)` in `plans` first, `museums`
second, and `{}` last. A v1 file keeps working unchanged; a v2 file that has no
row for this chapter falls through to the dealer instead of stamping a stranger's
chapter, which is the correct meaning of "absent from the plan". It also returns
`entry["sequence"]` instead of `""`, so the banner and the log name the chapter —
the fallback announces itself.

**(i) alone is not sufficient.** F4 is independent: a compound key whose second
component never changes is still one chapter forever. The fix must also advance
the pool cursor past what the plan stamped — the cheapest honest version is for
`_deal_from_plan` to advance `_pool_i` by the number of pool entries whose
`sequence` matches the chapter it just stamped, so a planned segment consumes the
curriculum at the same rate a dealt one does.

Why (i) and not the others:

| option | forecloses |
|---|---|
| **(i) compound key** | A plan can no longer be written for a building *independent of the curriculum* — `export_museum_plan --all --limit=8`, which plans one generic cast into every museum, has no chapter to key by and needs a sentinel (`sequence: ""` = any), which reintroduces the ambiguity in a smaller and more visible place. Also: "what stands in the Grande Galerie" stops being one lookup. Both are cheap, and the second is arguably wrong to want. |
| **(ii) one building per chapter, enforced upstream** | Forecloses the crown ruling itself. Four chapters were ruled into `grande-galerie-axial` by a scored tournament (`change` by 7.73 vs 6.83, the largest margin in the match); three of them would have to be moved into buildings they measurably lost in, and the ruling file would become advisory. It also caps the curriculum at the number of buildings — 26 usable today against 24 chapters, so a 27th chapter breaks the invariant — and it fixes neither F3 nor F4. Worst of all it contradicts the corridor: `forces` has 151 rows and occupies roughly a dozen segments of one building anyway, so buildings are shared over TIME by construction and the file would be asserting an exclusivity the scene does not have. |
| **(iii) buildings are shared, make the plan additive** | Forecloses "a museum houses ONE sequence", which the dealer enforces at `:1484-1490` by handing the chapter opener back so the next museum opens with it. Merging four chapters' casts into one `grande-galerie-axial` entry gives no rule for their order, no way to say which chapter a given body belongs to, and nothing for the banner to print. It also makes `interior_count` — the housing test — meaningless per chapter, which is the only number `spine_run.md` reports. |

The compound key is right because **it is the only one that adds the information
the pipeline already has instead of removing a decision somebody made.** The
chapter is computed at `:1056`, carried in the file at `spine_run.py:285`, and
thrown away in between. Everything else on this list deletes either a ruling
(ii) or a rule (iii) in order to make a flat dict adequate.

Secondary fixes, each a line or two, each with its own gate:

- `spine_run.py:295-297` — derive the note from `displaced` instead of typing it
  (F2).
- `export_museum_plan.py:222-234` — refuse to overwrite a file whose
  `_spine_run` block covers more chapters than this run does, unless `--force`
  (F5).
- `spine_run.museum_rotation:83-87` and `export_museum_plan.main:184` — add the
  `challenger` filter the scene has at `:594` (F5, secondary).

## NEGATIVE TEST

Three, in order of cost. Each must FAIL today.

**NT1 — pure Python, no Godot. The one that gates the schema.**

```python
# tools/test_em_plan_chapters.py
from spine_run import assign_museums, sequences
plan = json.loads((REPO / "ada_run/em_plan.json").read_text())
for seq, a in assign_museums([s for s, _ in sequences()]).items():
    entry = lookup(plan, a["museum"], seq)          # v2: (building, chapter)
    assert entry is not None, f"{seq} -> {a['museum']}: no plan"
    assert entry["sequence"] == seq, \
        f"{seq} -> {a['museum']}: plan holds {entry['sequence']!r}"
```

TODAY: **7 failures**, and the message is the misattribution itself —
`change -> grande-galerie-axial: plan holds 'symmetry'`. AFTER: 24/24.
This test cannot even be *written* against the v1 schema without the fix, which
is the point: the assertion names a key the file does not have.

**NT2 — the roster must not lie.**

```python
mentioned = {a["token"] for m in plan["museums"].values()
             for a in m["artifacts"] + m["rejected"]}
assert set(plan["offered"]) <= mentioned
```

TODAY: fails, 277 of 944 orphaned. AFTER: 0.

**NT3 — the corridor, and the only one needing Godot. Run by whoever applies the fix.**

```
godot_watchdog.py --expect=<png> -- <godot> --path . --xr-mode off --no-window \
  commons/scenes/endless_museum.tscn -- --em-plan --em-segments=8 --em-shot=<png>
```

then, over the log:

```python
chapters = re.findall(r"chapter=(\S+)", log)
assert len(set(chapters)) >= 2, chapters      # the corridor must leave chapter 1
assert "-" not in chapters                    # a planned segment must name its chapter
stamps = re.findall(r"\[em-plan\] (\S+): stamped (\d+)", log)
assert len({s[0] for s in stamps}) >= 2       # and must not be one building repeated
```

PREDICTED TODAY (source-read, not run): all eight segments print `chapter=-`,
seven of the eight print `[em-plan] sainsbury-false-perspective-enfilade: stamped
20 interior`, and `set(chapters) == {"-"}` — three assertions, three failures.
**If this run instead shows the chapter advancing, F4 is wrong and the whole of
this spike's §F4 should be struck.** That is the cheapest way to find out, and it
is one boot.

## OPEN

1. The crowns and the rotation are two policies that do not know about each
   other. Even after the compound key, `symmetry` will still be standing in
   `change`'s ruled building — correctly, now, and in its own plan entry — but
   whether the rotation *should* skip a reserved building is a ruling, not a fix.
   Skipping would give 24 chapters 24 distinct buildings out of 26 available,
   which is a different museum.
2. `--em-first` suppresses the crown at segment 0 only (`:1061`). Every proof
   shot in `/spatial-iterations` taken with `--em-first` therefore shows a
   building the corridor would not have chosen. Known and commented; worth
   restating because F4 means those frames are also the only segment that was
   ever chapter-correct.
3. `ada_run/spine_run.json` and `ada_run/spine_run/**` are untracked. Everything
   in §c and every log quoted here rests on them. They should be committed or
   regenerated before any of these numbers is cited again.
