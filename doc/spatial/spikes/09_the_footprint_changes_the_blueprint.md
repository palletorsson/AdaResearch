# Spike 09 — the footprint changes the blueprint

*Design record, 2026-08-14. Palle: "the footprint of the artifact should
change the blueprint. Can we fix that?"*

## QUESTION

Today the negotiator FITS bodies to fixed buildings: the tile decides the
room, the body is measured against it, and a body that fits nowhere is
refused (`escalation`) or exiled to a courtyard/balcony joint. The
building never learns from the body. Should it — and how, without a
second author of the plan?

## PROBE (measured against `ada_run/em_plan.json`, regenerated 08-14 09:27)

```
placed 900 · in courts/balconies 127 · rejected 256
  114  escalation: precinct: no exterior venue is large enough either
   60  physical_overlap (launch_arc collides with 60 neighbours — one bad seal)
   26  physical_overlap (other)
    7  faces_out_of_wall · 4 circulation · 4 wall_is_available
```

The 114 escalations are 101 tokens (some appear in two chapters). Bodies,
from `artifact_sizes.json` (98 measured):

```
footprint max-side:  min 0.0   median 18.0   max 60.3
  <= 12 m : 30   (would fit a WIDER room)
  12-40 m : 58   (would fit a courtyard/balcony joint — refused because
                  the JOINT QUEUE per chapter is capped, not the joint)
  > 40 m  : 10   (env_one 60x60, AntColonyV2 50x50, cnn_vr 51x53 — worlds,
                  not exhibits: they need to be WALKED INTO, not viewed)
  = 0.0   :  4   (marchingcave, mc_cave… — unmeasured GPU artifacts read as
                  zero and are refused for a size they do not have)
```

## BASELINE — where the building's shape comes from today

`_build_segment` picks a template (`spec.tile`, a fixed W×H char grid) via
`_plan_owner`; the negotiator picks slots INSIDE that grid. Three
adjustments already exist and are the precedent for this spike:

1. `_widen_doors` (08-14): edits the TILE before anything derives — 1-cell
   doors → 2 m. **This is the pattern**: change the tile, and walls,
   colliders, seals, walk cells and the door list all agree for free.
2. courtyard/balcony joints (spike 08): the building GROWS a joint between
   segments for a body it cannot host. The blueprint changes — but only at
   the seam, and only for `preferred_venue` bodies.
3. `_court_queue` cap (40 m/joint): the reason 58 mid-size bodies are
   refused — not "no venue is large enough" but "the queue is full".

## FAILURES the probe names (EXPECTED / ACTUAL / CAUSE)

- **F1** — a 6.9 m `xyz_slider_plate` in `array_tutorial` (Altes rotunda,
  w 15): EXPECTED a 7-cell slot; ACTUAL escalation; CAUSE the tile's rooms
  are ≤ 5 cells across and the negotiator never asks the tile to open a
  bay. `spatial_negotiation.py` treats `tile` as immutable input.
- **F2** — 58 bodies 12–40 m: EXPECTED a joint; ACTUAL "no exterior venue
  large enough"; CAUSE the refusal message lies — `spine_run.write_plan`
  counts joint depth per chapter against 40 m and stamps escalation when
  the budget is spent. A cap reported as an impossibility.
- **F3 — RETRACTED IN THE SAME SESSION.** The probe read
  `artifact_sizes.json` (aabb 0.0 for marchingcave, mc_cave, noiselayers)
  and diagnosed "unmeasured bodies negotiating as size zero." Then the
  contract was actually resolved: `spatial_contract.resolve` takes body
  from a BETTER source and reports 91.7×79.5 m, 300×300 m, 220×125 m. Not
  unmeasured — WORLDS, F4's category. The zero in sizes.json is that
  file's stale entry, not the negotiator's input. Lesson (the fourth time
  this week): measure the input the code READS, not the file that looks
  like it. A guard against a genuinely zero body still ships — it costs
  nothing and names the case honestly if it ever occurs — but it fires on
  none of these four.
- **F4** — 10 worlds > 40 m: EXPECTED a walk-in venue; ACTUAL none exists;
  CAUSE the vocabulary has room, courtyard, balcony — no *precinct that
  the walker enters*. This is the ">34 m tail" CURRENT_STATE already lists.

## PROPOSED FIX — three rungs, one authorship rule

**Authorship rule (non-negotiable):** the plan stays the ONE author. Any
tile change is DERIVED from the plan at build (like `_widen_doors`) or is
a NEGOTIATOR OUTPUT written into the plan (like `court`). Never a build-time
decision the plan does not know about — that is the second-author fault
this week paid for four times.

1. **The bay** (F1, ≤ 12 m, 30 tokens). Negotiator gains `bay_cells:
   (w, d)` on a placement: "host this here, but the tile must open a bay of
   w×d floor around the slot." Written into the plan row. `_build_segment`
   applies bays to the tile BEFORE derivation exactly as `_widen_doors`
   does: interior wall cells inside the bay rectangle become floor, subject
   to the same rules (no T-junction severance, exterior skin untouched,
   walk route must survive — the seal's severance test already exists).
   Additive and gated: a plan without `bay_cells` builds byte-identical.

2. **Honest joint refusals + queue that drains** (F2, 12–40 m, 58 tokens).
   Refusal text becomes `joint_budget_spent: 40 m/joint, N m queued` — a
   fact, not a fiction. Then the joint budget becomes PER SEGMENT LENGTH
   rather than a flat 40 m: a 90 m Uffizi segment earns a deeper joint than
   a 53 m Grande Galerie. That alone admits most of the 58.

3. **The walk-in precinct** (F4, > 40 m, 10 tokens). A new venue kind:
   `precinct` — the artifact IS the segment. No tile; the walker enters the
   world through a threshold and leaves through the next. This is the
   ">34 m tail" ruling CURRENT_STATE has been waiting for, and it needs
   Palle: which of env_one / AntColonyV2 / cnn_vr are worlds to enter, and
   which are simply too big for any museum and should be exiled to their
   own map.

**F3 was a misread** (see above); the > 40 m tail is 14 tokens, not 10,
and all of it is rung 3's question for Palle.

## THE PROBE WAS WRONG TOO — corrected before rung 1's measurement

The size histogram above was read from `artifact_sizes.json`. Building
rung 1 and tracing `facade_grammar_demo` (listed there as small) through the
ladder printed *"body 16.0 x 14.0 m exceeds the tile"* — the contract reads
bodies from a better source, and that source is BIGGER. Re-measured against
`spatial_contract.resolve(token).body_m`, the input the negotiator READS:

```
101 escalation tokens:  max-side min 10.2   median 25.8   max 300.0
  fits a 15-wide tile with a bay (<= 13 m):   6   (not 30)
  13-40 m (a joint would hold it):           63   (not 58)
  > 40 m (worlds):                           32   (not 14)
```

Bay candidates: extreme_randomness 10.2, mushrooms 10.4, box_counting_dimension
11.0, julia_set 12.0, facade_builder 12.0, MeltingBerniniScene 12.9.

So rung 1 is a small rung and rung 2 is where the yield lives. This is the
FIFTH "measure the input the code reads" of the week, in the same document
as the fourth. The rule generalises: `artifact_sizes.json` is a stale mirror
for the whole corpus, not just for four GPU artifacts, and no spatial
finding may cite it again — resolve the contract.

## RUNG 1 BUILT — and what the standalone traces said before the corpus run

`_try_bay` (spatial_negotiation.py), `bay_cells` on Placement + as_dict,
`bay` on the exporter row (tile coords, apron subtracted there), `_open_bays`
in the assembler applied to the tile before derivation. `test_em_bays.gd`
proves the assembler half both ways (no bay = identity; a bay opens exactly
its interior cells; the skin refuses with a voice).

Tracing the six candidates through real museums standalone (before the
regen) found the roof, not the walls: **five of six are too TALL** —
extreme_randomness 10.6 m, box_counting_dimension 6.0, julia_set 6.3,
facade_builder 14.0, MeltingBerniniScene 8.1 — every bay attempt (970 for
box_counting in the Grande Galerie) died on `body_fits_under_ceiling`, and
a bay opens walls, not the roof. Only `mushrooms` (1.2 m tall, 10.4 m
square) is a genuine bay case, and it fails on `circulation_on_floor` /
skin contact / >24 cells: a 10 m square wants a 12 m clear floor, which no
15-wide template's interior offers even with 24 cells opened. **The bay's
honest yield on this corpus is ~0.** The right instrument for these bodies
is the unroofed joint — rung 2 — which is why 127 already live there.

Also fixed on the way: `spatial_floorplan.FloorPlan.wall_height_m` defaulted
to 4.0 — a THIRD copy of the wall height, never 3.0 nor 4.5. `from_museum`
now reads em_detail.WALL_H (4.5). And the first regen was cut by a 590 s
timeout (isosurfaces alone takes 257 s) — its "byte-identical" result was
the OLD plan compared to itself. Fifth-and-a-half lesson: check the mtime.

## RUNG 1 MEASURED (regen 2026-08-15 06:57, full run, plan mtime checked)

```
            placed  interior  courts  bays  rejected  escalation
before         900       442     127     0       256         114
after          900       442     127     0       256         114
```

**Byte-identical, for real this time.** The bay admitted 0 of 6; the wall
height 4.0→4.5 moved nothing (no body sat between the two numbers on an
otherwise-fitting slot). The prediction's failure clause said "0 of 6 means
`_try_bay` is too strict" — the traces say otherwise: five of six need the
ROOF opened (too tall), the sixth needs 12 m of clear floor no template
interior has. The bay is correct, gated, tested, and inert on this corpus.
It ships (a body under 4.5 m and under ~8 m wide that meets an interior
wall will use it), and rung 2 is where the 63 mid-size bodies actually go.

## RUNG 2 BUILT AND MEASURED (regen 2026-08-15 08:46)

Two halves. NEGOTIATOR: the crossability rule read `body_m[0]` alone at
rotation 0 and refused an 18 x 6 m body for its 18 when it is 6 across
turned — the court is a rectangle a body can be TURNED in. Now the narrow
side must cross; if only the turned orientation does, the court is granted
turned (rotation +90, court dims swapped, assembler stamps the row's
rotation so plan and building agree); a body whose NARROW side still
severs the corridor is refused with the honest text: "a WORLD, not an
exhibit — Palle's ruling". ASSEMBLER: the joint budget scales with the
building it follows — clamp(0.6 x segment length, 40, 80) m — and doubles
once when the queue is backed up (> 6 waiting), so the corridor pays its
debt at the next seam instead of carrying balconies chapters behind their
rooms.

```
           placed  interior  courts  rejected  escalation
before        900       442     127       256         114
after         943       448     164       213          95
```

+43 placed, +37 in courts, -19 escalations, -43 rejected. Prediction said
"-> ~40 escalations"; measured 95. The gap is the 32 worlds plus square
bodies over 12 m that no turn helps — rung 3's population, now named by
the refusal text itself.

## PREDICTION (revised, still before rung 1's measurement)

Rung 1: escalations 114 → ~106 (the 6 candidates, some in two chapters).
If it admits 0 of 6, the bay's severance/skin rules are too strict for the
templates' interiors and the fault is in `_try_bay`, not the idea.
Rung 2 (joint budget per segment length): → ~40.

## PREDICTION (original, superseded — kept as the record of the misread)

Rung 1 alone: escalations 114 → ~84 (the 30 under 12 m), interior
placement 38.1% → ~40%. Rung 2: → ~30 escalations. If rung 1 admits fewer
than 20 of the 30, the bay rule is fighting the templates' interior walls
and the fault is in the severance test, not the idea.

## NEGATIVE TEST

A plan with no `bay_cells` on any row builds byte-identical geometry (mesh
count and collider count equal, `probe_em_render_load` before/after). A
plan with ONE bay opens exactly the cells the row names and no others.

## NOT DOING

Letting the negotiator resize the whole tile (W×H). The templates are
architecture — Sainsbury's false perspective, the Uffizi's spine — and a
building that reshapes itself to every body is no longer a museum, it is
a bounding box. Bays and joints are how real museums absorb odd objects;
they are enough.
