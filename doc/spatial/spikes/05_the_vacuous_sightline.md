# SPIKE 05 — the threshold sightline fault

*Research only. No repo file was edited, staged or committed. Godot was not run.*

## VERSION NOTE (LAW 1)

`tools/spatial_negotiation.py` and `tools/spatial_contract.py` are both
uncommitted-modified by another session. **The `threshold()` section is
byte-identical between `HEAD` and the working tree** — 6309 characters, diffed
directly. The uncommitted hunks touch only `_affinity`, `try_place`'s support
match and `_slot_suits` (the `pedestal`/`table`/`podium` collapse and the
overloaded-zero fix from spike 02). They move `threshold()` down by 29 lines and
change nothing inside it.

Every finding below therefore holds for **both** versions. Line numbers are
given as `HEAD / working tree`.

| symbol | HEAD | working tree |
|---|---|---|
| `def threshold` | 1074 | 1103 |
| `inside = (x - dx, z - dz)` | 1099 | 1128 |
| `for _, cell, side in candidates[:40]` | 1111 | 1140 |
| `stand = (cell[0] - dx * 3, ...)` | 1114 | 1143 |
| `blocked = [c for c in line ...]` | 1120 | 1149 |
| `if blocked: continue` | 1122 | 1151 |

---

## QUESTION

HANDOVER §7.4 says the one-line assertion that fixes `threshold()`'s
vacuous-truth hole "would turn 22 accepts into rejects, so the standing point
needs deciding first."

Is that true? And is the standing point the thing that is wrong?

## PROBE

`lab_room` (the corpus's canonical precinct: 8.04 × 7.98 × 4.30 m,
`containment=precinct`) negotiated into each of the 30 real museums in
`commons/data/slot_capacity.json`, then handed to `threshold()`. Four read-only
Python probes, no repo writes:

1. reproduce the audit and classify each accept REAL / VACUOUS
2. classify the standing point as inside / outside the building footprint, by
   the tile bounding box (`apron=14`, so footprint is `x,z ∈ [14, 14+tw/th)`)
3. replay the `threshold()` loop with each candidate fix bolted on
4. rank how deep in the candidate list the first legitimate door sits

## PIPELINE TRACE

Traversed: `staged_contract` → `from_museum` → `negotiate` → `Occupancy.commit`
→ `threshold` → `_line`. Not traversed: rendering. `threshold()`'s **only two
callers in the entire repo** are `pipeline_images.py:200` and
`:220`. It is not reached by `export_museum_plan.py`, not reached by
`negotiate()`, and **has zero test coverage** — no `tools/test_*.py` mentions
it. Blast radius of any fix: two diagram-drawing call sites.

## BASELINE

`threshold()` certifies a door, a sightline and a caption for every precinct
work. 30 museums → 28 ACCEPT, 2 REJECT. Of the 28, `pipeline_images._threshold_audit`
reports 22 whose certified door is not on the sightline it certifies.

## PREDICTION WRITTEN FIRST

Recorded honestly, including which were formed before which probe.

| # | prediction | when formed | outcome |
|---|---|---|---|
| P1 | 28 is the ACCEPT count, 30 the museum count; both numbers correct, no error | after reading `pipeline_images.md:71`, before probe 1 | **RIGHT** |
| P2 | the 22/6/2 split reproduces exactly | before probe 1 | **RIGHT** |
| P3 | the standing point is outside the building — the report's stated cause | before probe 2 | **WRONG**, and I got it wrong twice (see F5) |
| P4 | the assertion does **not** cost 22 accepts, because the loop `continue`s and can find a better door further down the same list | before probe 3 (stated in-session before running it) | **RIGHT — it costs 13, and 0 if the `[:40]` cap goes** |
| P5 | the 6 REAL are genuine | implicit, before probe 4 | **WRONG — 2 of the 6 are false** |

P4 is the pass. P3 and P5 are the two I would not have caught without measuring.

---

## FAILURES

### F1 — the vacuous-truth path

EXPECTED: "the line from a standing point inside to the work's centre must cross
the wall ONLY at the door" (docstring, HEAD:1079 / WT:1108).

ACTUAL: the implementation is

```python
blocked = [c for c in line
           if plan.in_bounds(*c) and plan.grid[c[1]][c[0]] == "4" and c != cell]
if blocked:
    continue
```

`blocked == []` is satisfied by *"crosses the wall at the door and nowhere
else"* **and** by *"crosses no wall anywhere"*. The second reading is never
excluded. `cell` is never tested for membership in `line`.

CAUSE: the rule was written as a negative (nothing else may block) with no
matching positive (the door must be on the path). One `in` test is missing.

FILE:LINE: `tools/spatial_negotiation.py` HEAD:1120-1123 / WT:1149-1152.

MEASURED: 22 of 28 accepts take the vacuous path. `nwall == 0` on the sightline
in exactly those 22 — the line meets **no** wall cell at all, not one in the
wrong place.

### F2 — `threshold()` has no concept of "inside the building"

EXPECTED: a door separates interior from exterior; `inside` and `outside` are
the two sides of that.

ACTUAL:

```python
inside  = (x - dx, z - dz)
outside = (x + dx, z + dz)
if not (plan.walkable(*inside) and plan.walkable(*outside)):
    continue
```

Both sides are tested with `plan.walkable()` **only**. `walkable()` is
`grid[z][x] not in (VOID, WALL)` (`spatial_floorplan.py:153-154`), and
`from_museum` paints the entire apron ring FLOOR — *"the grounds"*,
`spatial_floorplan.py:445-447`. So the grounds are as walkable as the galleries
and nothing in `threshold()` can tell them apart. `inside` is simply *whichever
of the four directions the loop named*, and all four are enumerated for every
wall cell.

CONSEQUENCE, measured: in **4 of 28** museums the certified "inside" standing
point is in the grounds — `kanazawa-matrix-vista`, `kanazawa-room-matrix`,
`kanazawa-vista-v2` (all `stand=[19,13]`, north of the footprint edge at z=14)
and `mezquita-hypostyle` (`stand=[20,11]`). `mezquita`'s whole sightline is
3 cells long and entirely outdoors: `[20,11] → [21,11] → [22,10]`. The door it
certifies is on the north facade, labelled `south`, i.e. with the interior
called "outside".

FILE:LINE: `tools/spatial_negotiation.py` HEAD:1099-1102 / WT:1128-1131;
`tools/spatial_floorplan.py:153-154` and `:445-447`.

### F3 — the real cause is the ENTRANCE, not the standing point

This is the finding that overturns HANDOVER §7.4's diagnosis.

`doc/reports/pipeline_images.md:96-99` states the cause as: *"the precinct
itself is placed in the porch — outside the walls — so on most plans the
'visitor standing inside' is already standing next to the work with nothing
between them."*

EXPECTED (from that): the standing point is outside the building in most of the
22.

ACTUAL: the standing point is **inside the footprint in 24 of 28**, including
18 of the 22 vacuous ones, at 5–14 cells from the work. The visitor is inside,
is not next to the work, and **genuinely can see it** — through the front
entrance, which is a floor cell, not a wall.

`from_museum` derives `spawn = (gap(off), off)` — the middle of the walkable run
in the tile's first row (`spatial_floorplan.py:456`) — and `_exterior_slots`
plants the porch at `cell=(sx, max(1, sz - 3))`, three cells directly outside
that entrance (`spatial_floorplan.py:549-556`). The precinct lands on the porch
in 27 of 28 museums. **So the work is placed directly outside the front
opening, and any look from inside toward it leaves the building through that
opening.**

Traced cell by cell, `uffizi-spine-enfilade`:

```
stand (24,17)'1' → (24,16)'2s' → (25,15)'1' → (25,14)'1' → (25,13)'1'
                 → (25,12)'1' → (26,11)'1' → target (26,10)'1'
```

The line leaves the footprint at `(25,14)`, which is `'1'` — floor. The
certified door is `(24,14)`: a wall cell in the **same facade row, one metre to
the west** of the gap the visitor is already looking through. That is the shape
of 18 of the 22, not "standing next to the work".

CAUSE: `threshold()` was written for a work behind a wall. The negotiator puts
precincts on the porch, which is by construction in front of the hole in the
wall. Nobody checked that the two agreed.

FILE:LINE: `tools/spatial_floorplan.py:456`, `:549-556`;
`tools/spatial_negotiation.py` HEAD:1120 / WT:1149.

### F4 — "22 accepts become rejects" is wrong. It is 13, and it can be 0.

EXPECTED (HANDOVER §7.4): adding `door_cell in line` turns 22 accepts into
rejects.

ACTUAL, replayed over all 30 museums:

| variant | ACCEPT | REJECT | doors on the sightline |
|---|---|---|---|
| today | 28 | 2 | 6 |
| **+ `cell in line`, cap kept at 40** | **15** | **15** | 15 |
| **+ `cell in line`, cap removed** | **28** | **2** | **28** |
| + `cell in line` + stand must be inside, cap removed | 24 | 6 | 24 |

The one-line assertion costs **13 accepts, not 22**. Nine of the 22 vacuous
museums find a legitimate door further down the *same 40-candidate list* and
were never at risk (`altes-rotunda-hub`, `caracalla-thermal-axis`,
`castelvecchio-endstop-pinch`, `castelvecchio-endstopped-enfilade`,
`castelvecchio-pinch-v2`, `dia-beacon-field`, `guggenheim-serpentine`,
`mesdag-panorama-drum`, `soane-cabinet-vista`).

And the 13 that *do* fail are lost to an arbitrary constant, not to the
assertion. `candidates[:40]` (HEAD:1111 / WT:1140) truncates a list that runs
38–470 entries long. The index of the first door that is genuinely on the
sightline has **median 36, max 170**, and is **≥ 40 in exactly 13 of 28
museums** — the same 13. Remove the cap and the assertion is free: the accept
set is *identical to today's 28*, the reject set is the *same 2*
(`chichu-buried-cells`, `katsura-miegakure-circuit`), and every one of the 28
now has its door on the line.

**The standing point does not need deciding first.** The claim in §7.4 conflated
the assertion's cost with a search-budget artefact.

CAUSE: the audit in `pipeline_images._threshold_audit` (`:177-205`) measures the
*verdict* `door_cell in _line(...)` on the door the loop already chose. It never
re-runs the loop under the assertion, so it cannot see that the loop would keep
searching. A post-hoc classifier was read as a counterfactual.

FILE:LINE: `tools/spatial_negotiation.py` HEAD:1111 / WT:1140;
`tools/pipeline_images.py:177-205`.

### F5 — 2 of the 6 certified-REAL are also false, and the published frame uses one

EXPECTED: the 6 named in `pipeline_images.md:72-74` "put the door in the way of
the look."

ACTUAL: only **4** do. The test that separates them is whether the certified
door *is the cell where the sightline leaves the building*:

| museum | door | on perimeter crossing? | verdict |
|---|---|---|---|
| `libeskind-void-axis` | [18,14] `'4'` | **yes** | genuine |
| `louisiana-pavilion-chain` | [22,14] `'4'` | **yes** | genuine |
| `teshima-droplet` | [19,14] `'4'` | **yes** | genuine |
| `thoronet-circumambulation-void` | [27,14] `'4'` | **yes** | genuine |
| `capuchin-crypt-corridor` | [18,20] | no — line exits at `(17,14)` `'1'` | **false** |
| `sando-threshold-run` | [19,16] | no — line exits at `(20,14)` `'1'` | **false** |

In both false cases the "door" is a hole punched in an **interior partition**
20–16 cells inside the building, after which the sightline still leaves through
the open facade with nothing to cross. The visitor could walk around the
partition.

The sting: `capuchin-crypt-corridor` is the museum the published AFTER frame
uses (`spatial-iterations/20260813-095925/2_after_door_sightline_caption.png`),
chosen — per `pipeline_images.md:100-102` — *"precisely because it is one of the
six where the claim is real."* It is one of the two where it is not. The frame's
own caption is accurate about the geometry (1 wall cell crossed at `[18,20]`)
and wrong about what that geometry means.

So the true score today is **4 of 28 = 14.3%**, not 6 of 28.

CAUSE: `door_cell in line` is necessary but not sufficient. It admits any
interior wall the line happens to graze.

FILE:LINE: `tools/spatial_negotiation.py` HEAD:1120 / WT:1149;
`doc/reports/pipeline_images.md:72-74`, `:100-102`.

---

## THE 22 — DO THEY SHARE A SHAPE?

Yes, two shapes, and neither is a museum family or a template series.

| shape | n | signature |
|---|---|---|
| **A — the look leaves through the front entrance** | 18 | stand inside the footprint (5–14 cells in), target on the porch directly outside the entrance gap, sightline crosses **0** wall cells, certified door is a facade wall cell 1–4 m to the side of the gap |
| **B — inside and outside inverted** | 4 | stand in the grounds; `kanazawa-{matrix-vista,room-matrix,vista-v2}` (three revisions of one template — that is the only family effect present) and `mezquita-hypostyle`; sightlines 3–4 cells, entirely outdoors |

Not shared: door orientation. The vacuous 22 split `north` 14 / `west` 4 /
`south` 4, while all 6 REAL are `north` — but 14 of the 22 are also `north`, so
orientation does not separate them. Not shared: template series — the three
`castelvecchio-*` and both `uffizi-*` revisions are vacuous, but so are
`dia-beacon-field`, `mezquita-hypostyle` and `pompidou-plateau-libre`, which
share no lineage. Venue is near-constant and therefore not discriminating:
27 porch, 1 courtyard (`mesdag-panorama-drum`) across all 28 accepts.

**All 28 targets are outside the building.** The variation is entirely in where
the door and the standing point land, not in where the work goes.

---

## EVIDENCE

- 30 museums enumerated from `commons/data/slot_capacity.json`; `lab_room`
  placed by `negotiate()` in all 30; `threshold()` ACCEPT in 28, REJECT in 2.
- `28` is the **ACCEPT** denominator; `30` is the museum count. HANDOVER §5 and
  §7.4 are both right and describe different things. No error to fix, but §7.4
  should say "22 of the 28 that accept" to stop the next reader re-deriving it.
- Split reproduced to the museum: 22 VACUOUS / 6 REAL / 2 REJECT, and the 6
  named in the report are the 6 measured.
- Sightline wall-crossings: `nwall == 0` in all 22 vacuous, `nwall == 1` in all
  6 real.
- Standing point inside the footprint: 24 of 28 (18 vacuous + all 6 real).
  Outside: 4 (shape B).
- Candidate list length 38–470; first-on-line index median 36, max 170
  (`uffizi-spine-{enfilade,ordered}`), ≥ 40 in 13 of 28.
- Fix matrix as tabulated in F4.
- Perimeter-crossing test on the 6 REAL as tabulated in F5.
- `threshold()` byte-identical HEAD vs working tree; zero test coverage;
  two callers, both in `pipeline_images.py`.

Probe scripts (scratchpad, not repo): `probe_threshold.py`, `probe_inside.py`,
`probe_fix.py`, `probe_rank.py`.

---

## PROPOSED FIX — not applied

### The three candidates, measured

**(i) assert the line crosses at least one wall / the door is on the line.**
Literal one-liner, cap kept: 28 → 15 accepts. Cap lifted: 28 → 28 accepts, all
28 doors on the line, same 2 rejects, **zero regressions**. Cost: the doors it
then picks can be absurd — `pompidou-plateau-libre` lands its door at `[18,49]`,
41 cells from the work, in the **back** wall, with the visitor standing in the
south grounds looking up the entire 36-cell enfilade and out the front. 4 of the
28 do this (`labrouste-stack-hall` 36, `uffizi-*` 34 each, `pompidou` 41,
against 5–11 for the honest ones).

**(ii) move the standing point.** Answers shape B (4 museums) and nothing else.
It cannot answer shape A, because in shape A the standing point is already
inside and the visitor really can see the work — the fault is that the door is
somewhere else. Moving the standing point without (i) leaves the vacuous path
open; the line would still cross no wall.

**(iii) both.** Assertion + "the standing point must be inside the footprint",
cap lifted: 24 accepts, 6 rejects. Loses `labrouste-stack-hall`,
`pompidou-plateau-libre`, `uffizi-spine-enfilade`, `uffizi-spine-ordered` —
precisely the four back-door absurdities. So (iii) suppresses the right cases,
but by an unrelated rule, and at the price of a footprint test `threshold()`
currently has no way to compute (it never receives the tile extents).

### Recommendation: **(i), strengthened — and not (ii)**

Assert **the door is the cell at which the sightline leaves the building**, not
merely that it is somewhere on the line. That is still one predicate, it
subsumes (i), it kills the back-door cases without a footprint parameter (a
41-cell line from the south grounds crosses the back wall *and* exits the front
opening — it is not a single crossing), and it is the only one of the three that
also catches **F5**, the two false REALs that (i) alone certifies.

Concretely, at HEAD:1120 / WT:1149, replacing the `blocked` test with:

```python
crossings = [c for c in line
             if plan.in_bounds(*c) and plan.grid[c[1]][c[0]] == "4"]
if crossings != [cell]:
    continue
```

— the look meets exactly one wall, and it is this door — plus removing the
`[:40]` truncation at HEAD:1111 / WT:1140, or raising it to `len(candidates)`.

Do **not** move the standing point. It is inside in 24 of 28, the 4 exceptions
are a symptom of F2 (no interiority anywhere in this function) rather than of
the standing rule, and `crossings != [cell]` rejects all four of them anyway —
an entirely outdoor 3-cell line crosses zero walls. Fixing F2 properly means
teaching `FloorPlan` to distinguish grounds from galleries, which is a change to
the shared plan type and belongs in its own pass; it is not needed to close
this.

### The design question this leaves open, which is the actual §7.4 decision

If the work sits on the porch, three metres outside a front entrance the visitor
is already looking through — **has the museum not already given it a
threshold?** Shape A is 18 of the 22, and in every one of them the sightline
claim is *true* and the door claim is *false*. The honest fix may not be a new
door at all but recognising the existing opening as the door and hanging the
caption beside it. That is a decision about what a threshold *is*, and it is the
user's, not a code fix. The assertion above is correct either way: it turns 18
silent lies into 18 visible facade doors, which is what makes the question
answerable.

---

## NEGATIVE TEST — must FAIL today, PASS after

`tools/test_threshold.py` (does not exist; `threshold()` has no tests at all).

```python
def test_certified_door_is_the_only_wall_the_look_crosses(self):
    """The door must be ON the sightline, and be the only wall on it.

    Fails today: uffizi certifies a door at [24,14] while the look leaves
    through the floor cell at [25,14], one metre east. `crossed` is empty.
    """
    for key in ("uffizi-spine-enfilade", "altes-rotunda-hub",
                "mezquita-hypostyle", "capuchin-crypt-corridor"):
        plan = from_museum(key)
        occ = Occupancy()
        c = staged_contract("lab_room")
        p = negotiate(c, plan, occ)
        self.assertEqual(p.result, "ACCEPT", key)
        occ.commit("lab_room", p.masks, p.anchor)
        th = threshold(plan, p, c)
        self.assertEqual(th.result, "ACCEPT", key)
        line = _line(th.stand_cell, p.anchor)
        crossed = [cc for cc in line if plan.in_bounds(*cc)
                   and plan.grid[cc[1]][cc[0]] == "4"]
        self.assertEqual(crossed, [th.door_cell], key)   # <-- the bite
```

Today: **4 failures.** `uffizi-spine-enfilade` `[] != [(24,14)]`;
`altes-rotunda-hub` `[] != [(19,14)]`; `mezquita-hypostyle` `[] != [(20,14)]`;
`capuchin-crypt-corridor` `[(18,20)] != [(18,20)]` **passes** — this one is the
control that proves the assertion is not merely rejecting everything, and it is
also why a second arm is needed for F5.

After the fix: all four pass, `capuchin`'s door having moved to the facade.

Two more arms, so the fix cannot be gamed:

```python
def test_the_fix_costs_no_museum(self):
    """The assertion must not shrink the accept set. Cap must go with it."""
    accepts = [k for k in MUSEUMS if _threshold_of(k).result == "ACCEPT"]
    self.assertEqual(len(accepts), 28)          # 28 today, 28 after
    self.assertEqual(sorted(set(MUSEUMS) - set(accepts)),
                     ["chichu-buried-cells", "katsura-miegakure-circuit"])

def test_the_door_is_not_an_interior_partition(self):
    """F5: capuchin and sando certify a hole in a wall you can walk around."""
    for key in ("capuchin-crypt-corridor", "sando-threshold-run"):
        ...  # the sightline must not continue past the door through open floor
        self.assertTrue(_door_is_perimeter_crossing(key), key)
```

`test_the_fix_costs_no_museum` is the one that would have caught §7.4's error:
it fails at 15 if the assertion lands without the cap being lifted, so it forces
the two changes to ship together.
