# From artifact order to an AAA game environment

> Plan written 2026-08-11 from a seven-agent capability audit. Every number below
> was measured against the working tree. Companion: `doc/SPATIAL_CONTRACT_AUDIT.md`.

## The finding that reorders everything

The pipeline is not mostly missing. It is **mostly built and mostly unconnected**, and
the two layers that would tell us whether it works — measurement and validation — are
the two that are broken.

| Layer | State | Evidence |
|---|---|---|
| Artifact contract | **9 artifacts complete** of 2698 | resolver runs, sources are thin |
| Order / lineage | **Strong.** 12610 typed edges, 951 DNA axes | `artifact_relations.json`; gate 938/951 verified, 0 broken |
| Floorplan | **Strong.** 30 museums, 475 slots, byte-identical round-trip | `extract_museum_bays.py --dry-run` 30/30 |
| Wall kit | **Certified and unused.** 23 variants, 11 gates pass | **0 of 2417 maps place it** |
| Assembler | **Owns placement it shouldn't.** 6338 layout lines | builds its own boxes, never calls the kit |
| Validation | **Structurally incapable of failing** | pathfinder exit counts ERRORs; only ERROR rule is auto-fixed |
| Book / monitors | Text exists, routing does not | 787 blurbs; 0 exhibit captions in the museum |

So the work is **connection and truth**, not invention. Two things must be fixed before
anything downstream can be believed.

---

## Phase 0 — Make the ground true — **DONE 2026-08-11**

> Outcome. Both measurement scripts repaired, corpus re-measured (1752 → **2647**
> artifacts, **878 changed — 50% of everything comparable**), and the
> correspondence gate built and proven by self-test. The loop closed end to end:
> the gate found `bias_visualizer` recorded at 0.55 m against a real 1.98 m, the
> repaired measurer independently produced 1.98 m from the scene, the plan
> recomputed, and the gate now passes.
>
> The repair caught its own regression. Letting artifacts BUILD during the settle
> window also let them RUN: 14 simulation-class artifacts (the cellular automata,
> the marching-cubes landscapes, `evolving_bloops`) walked away to heights of
> 1003 m, 10018 m and 9.4e19. A second reading 0.15 s later now detects a body
> still growing, the merge refuses to write anything the harness distrusts, and
> those 14 are marked `withheld` in the registry rather than carrying either a
> huge wrong number or April's small wrong one.
>
> Corpus after: 19 `[8,8,8]` particle boxes gone · 140 zeros recovered (including
> `scale_lines`, genuinely 100 m, standing in 22 live maps) · 144 fallbacks now
> declare themselves · 1345 artifacts have signage measured apart from body ·
> 55 top-level nodes no longer drag the box to the world origin.
>
> Still open from 0.3: `merge_curated_walls.py` merges nothing, Gate B fails on
> `grey_point`, and 10 tokens are claimed by two registry files with different
> scenes (`doc/reports/duplicate_tokens.json` — needs an authoring decision).

Nothing built on top of today's measurements or gates can be trusted. This phase buys
the right to believe later phases.

### 0.1 Repair measurement

- `ada_run/artifact_measurements.json` is dated **2026-04-29**; the registry has grown
  1759 → 2698 since. **947 tokens were never measured; 226 more measure zero.** Only
  **1525 of 2698 can supply a body size.**
- `doc/plans/capture_measure_faults.md` (2026-08-10, **never applied**) documents six
  faults and estimates ~25 of 72 sampled measurements are wrong, projecting ~900 bad
  numbers. Apply it first, then re-measure — measuring again through the same faults
  just manufactures more confident wrong numbers.
- **20 lookup_names are duplicated across registry files** and `measure_artifacts.gd`
  de-dupes last-file-wins, so 20 artifacts are measured under someone else's scene.
  Fix the duplicates before the run.
- Add `sweep` to the measurement itself: capture the AABB over N frames of simulation
  rather than at frame 2. Today **2614 of 2698 tokens have no way to declare a moving
  volume** — `staged_measurements.json` knows 20 and nothing reads it.

**Gate:** ≥95% of `map_ready` tokens carry a fresh non-zero AABB, and a re-measure of
the same artifact twice produces the same number.

### 0.2 Build a gate that can fail

- `map_pathfinder.py check` **cannot fail**: `total_issues` counts ERRORs only, R1 is
  the sole ERROR rule, and R1 is auto-fixable. 1373/2417 maps are actually clean; the
  tool reports 657/657 OK. Make WARN counts visible to the exit code behind a flag.
- The pathfinder knows only *the cell a token sits in* — no footprint, no AABB, no
  height, no overlap, no rotation. It cannot see a 10-cell artifact.
- **No 2D→3D correspondence check exists anywhere.** Write it. This is the keystone
  deliverable of Phase 0: a Godot probe that loads a compiled map, reads each
  artifact's real world AABB, and diffs it against the plan the negotiator approved —
  cell, height, rotation, overlap, clipping. Building blocks already exist
  (`detect_footprints.gd`, `probe_cell_world.gd`, `check_aabb_below_ground.gd`).
- Wire `check_dna_declarations.py` into the release gates. CLAUDE.md calls it "the
  gate"; nothing runs it.
- Fix Gate B (currently **FAIL**: `grey_point` missing scene path).

**Gate:** the correspondence probe passes on the 3-artifact slice and *fails* when a
placement is deliberately corrupted. A gate that has never failed has never been tested.

### 0.3 Two live hazards, fix now

- **`tools/artifact_relations.py` writes `commons/data/artifact_relations.json` with an
  older, incompatible schema.** Running it silently destroys the 12610-edge typed graph
  that five `em_*.gd` modules read at runtime. Rename or delete it.
- **`tools/merge_curated_walls.py` merges nothing** — it globs `curated_walls/*.json`
  while all 87 curated files live in `curated_walls/clusters/`.
- Latent VR crash: `endless_museum.gd:2192` `_track_acoustic` uses `_cam`, which is
  null in VR.

---

## Phase 1 — One contract, twelve artifacts

Extend the existing resolver (`tools/spatial_contract.py`); do not start over.

- Add the fields the audit found missing: **`view.preferred_distance_m` as a range**
  (the resolver drops it entirely today), oriented occupancy mask, `sweep_m` populated
  from 0.1, host/support requirement, projection depth.
- **Featured artifacts must FAIL, not default.** Today `resolve()` always returns a
  contract; for the featured set a defaulted field is a failed gate.
- Pick **12** covering the real spatial cases: small · large · wall-facing · 360° ·
  animated/sweeping · diagram · solid · host-mounted · room-scale · safety prop ·
  interactive · walkthrough. The AAA pass already authored 34 such contracts —
  start from those, not from a new list.
- Note: `doc/book/heroes.json` **cannot** serve as the featured list. It is hero/anti
  *prose per map* ("the point — the first mark placed"), not artifact tokens.

**Gate:** 12 complete contracts, zero defaulted fields, provenance on every value.

---

## Phase 2 — Order → exhibition brief

Almost free. The hard part is already done and sitting in GDScript.

- `artifact_relations.json` has **12610 typed edges** in 5 kinds (co_placed 6813,
  axis_kin 2101, family 1929, named 1609, sibling 158), each with `why`, and
  `em_sets.gd` **already maps each kind to a spatial rule** (named→sightline,
  sibling→row, axis_kin→adjacent-at-different-values, family→padding).
- DNA series are machine-derivable: **698 tokens, 951 axes, 4056 values**, extracted
  from code by `check_dna_declarations.py`.
- **570 of 799** spine anchors can already emit "anchor → 2 typed relations → 1 DNA run".

**Build:** a Python CLI that emits the brief — the logic exists only inside GDScript
today, so a Python negotiator cannot call it. **Add the missing pedagogical edge types**
(prerequisite / descendant / contrast / application); current kinds express co-presence
and shared axes, never "this teaches that". Retire the orphan
`spine_artifact_order_kin.json` (no writer, no reader).

**Gate:** brief for one sequence, no coordinates in the output, every relation typed.

---

## Phase 3 — Floorplan from the real corpus

**Delete `spatial_floorplan.build_enfilade()`.** It is a parallel system; the audit
confirmed it loads nothing.

- Load `commons/data/template_patterns.json` (30 museums) and `museum_bays.json`
  (144 bays, round-trip verified byte-identical).
- **Regenerate `museum_bays.json` first — it is stale**: 28 museums on disk, 30 in
  patterns.
- Slot roles are already derived (hero 28, wall_hang 102, vitrine 80, station 58,
  underfoot 52) with a `size_class` from a 5×5 clearance count.
- **Add declared slot capacity** — the one genuine gap: `max_body_m`, allowed placement
  modes, approach sides, expandable axes. Today a slot advertises nothing.
- Note museum patterns carry **no** `slots`/`hero` key (bay-only fields); read slots
  from the tile or from `museum_bays.json`.
- `walk_rule` / `pacing_rule` on the 30 museums are **prose nothing reads**. Either
  make them machine-readable or stop implying they are rules.

**Gate:** the negotiator runs against a real Uffizi/Castelvecchio bay and
`validate_museum_templates.py` stays green.

---

## Phase 4 — Negotiator on real bays

The negotiator exists and works (27 tests). What changes is what it negotiates against.

- Feed it real bay slots + declared capacity instead of the invented enfilade.
- Room expansion must respect the **certified kit**: pieces exist at 1–4 m widths and
  **one 4 m height**. `kit_buildable()` already warns; make it a hard gate, or
  commission a taller certified piece. A room the kit cannot build is not a solution.
- Adopt the declared priority verbatim (`museum_contract_pilot.negotiation.priority`):
  safety → reachability → route continuity → lineage order → view quality → compactness.

**Gate:** 12 artifacts placed into one real museum, every decision explained, zero
artifact-specific code paths.

---

## Phase 5 — Walls as the second 2D domain

The most fragmented layer, and where AAA actually lives.

- **Reconcile three incompatible band schemes** before writing any more wall code:
  eye-band top is 2.3 (prop rules), 2.1 (`build_wall_faces`) or 2.7 (contract pilot);
  wall top is 4.0 or 3.4. Pick one, write it once, delete the others.
- **Give props a real mount contract.** Only 5 props have one. The 87-prop
  classification lives in a **GDScript const in `em_props.gd`, unreachable from
  Python**, and carries no projection depth or service clearance. Move it to data.
- Bridge the two wall models: `layers.walls` (integer edge codes, **global** height —
  and none of the 200 maps using it declares the kit's 4.0) versus the kit's (u,v)
  surface with feature field and rails. Nothing converts between them today.
- Generalise `build_uffizi_prop_placement_pilot.py` off its hardcoded map.
- Negotiate wall rect **and** the floor in front in one pass — currently
  `wall_props.py` knows floor cells but no height, and the pilot knows height but never
  touches floor occupancy.

**Gate:** a wall elevation and a floor plan for the same bay that agree with each other,
and with the 3D capture.

---

## Phase 6 — The assembler gets dumber

- **The seam is `_deal_segment` (314 lines).** Replace it with a plan reader; keep
  `_stamp` as the executor and `_build_segment` as the single call site.
- Six things must be preserved (audited): slot-dict *identity* (em_sets reads `top` off
  them), the `+VESTIBULE_H`/`zbase` cell translation, `_seal_cells`/`_reaches_all`
  corridor protection, `_apply_axis` running **before** `add_child`, chapter alignment,
  and plinth lift + measured-floor seat correction.
- **`_stamp` has no rotation, no mount, no y_offset** — position only. It must be
  extended; `_dress_props` already proves the pattern with `rot_y`.
- **Use the certified kit.** The assembler builds walls, floors and ceilings from its
  own `_box`/`_add_col` while 23 certified, gate-passing wall variants sit unused in
  every map. This is the single largest ready-made AAA asset in the repo.
- **Commission the missing modules**: there is no corner, ceiling, floor, trim or
  lighting module — runs cannot turn, and a bay's roof and lights are hardcoded to 8×8.
- VR: never create a camera or move the walker; the build path must stay
  camera-independent.

**Gate:** the same spatial data that passed the 2D negotiator produces a museum that
passes the Phase 0 correspondence probe, at 90 fps in VR.

---

## Phase 7 — The book on the wall

- `em_detail.gd` already hangs **52–60 monitor-shaped "showings" per segment** at
  1.58 m eye height — deterministic, correctly placed, and **blank**, because they are
  MultiMesh transforms with no per-picture node and no role tag.
- **Promote N showings to real nodes, tag each wall face with a role** during the BFS
  route walk that already derives exit-sign arrows, then route by role: entry→blurb,
  artifact→technical/tutorial, counter→critical, exit→summary.
- `tutorial_wall` already self-loads a named map's text — the pattern is proven and has
  **zero placements**. Use it.
- **Resolve the text schema split**: `build_book.py` reads summary/intent/tutorial/
  critical; `map_text_writer.py` tracks blurb/technical/critical/summary. The 787-file
  blurb corpus — the largest — is invisible to the book, and "entry monitor = blurb"
  currently targets a file the book never reads.
- Today a visitor sees one segment banner, EXIT signs and the word "GALLERY". **No
  exhibit has a nameplate.**

**Gate:** every monitor attached to a visible exhibit or spatial decision; no floating
text.

---

## Phase 8 — AAA finish and the human gate

- `museum_wall_aaa_quality.json` already declares the standard: per-width mesh budgets,
  14 materials, min visual score 8.5 across 9 categories, VR 90 fps, LOD contract,
  collision matching visible solids. Extend it from the wall kit to the whole segment.
- **The VR feedback loop is dormant** — 21 entries, all February; of 215 `walked.md`
  files, **198 are AI ghost-drafted**, so roughly 17 maps carry a genuine headset walk.
  No amount of automation replaces this. Restart it early, not at the end.
- `walk_evaluator.py` scores encounter order and detour on 2D placements and is wired
  to nothing. Wire it onto compiled galleries.

---

## Sequencing and honest cost

```
0 ground truth ─┬─> 1 contract ──> 2 brief ──┐
                │                             ├─> 4 negotiate ──> 6 assemble ──> 8 AAA
                └─> 3 floorplan ──────────────┘        │
                                              5 walls ─┘
                                              7 book ──┘
```

Phase 0 blocks everything and is the least glamorous. Phases 2 and 3 are cheap because
the data already exists. Phase 6 is the highest-risk change (13.6k lines of working
runtime). Phase 5 is the widest.

Rough effort for one focused developer, given the automation that exists: Phase 0 about
a week (dominated by re-measurement and the correspondence probe), Phases 1–4 two to
three weeks to a 12-artifact museum, Phases 5–6 three to four weeks, Phase 7 a week,
Phase 8 continuous. Corpus-wide migration is a separate, later, mostly-automated job —
and should not start until the 12 pass.

**The largest uncertainty is not the compiler. It is that we currently have no way to
tell whether a generated room is good — only that it is non-overlapping.** Phase 0's
correspondence probe and Phase 8's VR walk are the only two things that answer it.
