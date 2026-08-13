# Ceiling convergence — the grid's ceiling and the museum's ceiling

**Question (verbatim):** *"there is a ceiling grid system. Can we use that in the AAA endless modular museum?"*

**Answer: no — and the divergence is justified. Neither system should adopt the other.**
The two are not two implementations of one idea. They are a *drop ceiling* and a *roof*,
and the museum's lighting rig is built on the roof being perforated.

This document exists so the next agent does not re-ask. Ownership is stated in
[§ Ownership](#ownership) at the foot.

---

## 0. Predictions, written before any capture

Committed before the probe script existed and before a single PNG was rendered.
Marked ✅ / ❌ in [§ 4](#4-verdict-on-the-predictions).

| # | Prediction | Basis |
|---|---|---|
| **P1** | Ceiling height: grid **4.0 m** (default/`institutional`); museum soffit **3.14 m**, lowest overhead element **2.943 m** (the rib chamfer). Grid sits **0.86 m above** the museum soffit and **1.00 m above** the museum's 3.00 m wall head. | read off constants — not a real bet, stated for the record |
| **P2** | Overhead render primitives for **one segment**: museum ceiling **20–60** MultiMesh instances; grid ceiling **> 2000** individual `MeshInstance3D` nodes. Ratio **> 40×**. | `_generate_ceiling_tiles` is one node per 0.5 m cell |
| **P3** | Upper-band (top 25% of frame rows) **mean luminance rises** in the AFTER image, to **≥ 0.40**, ratio AFTER/BEFORE **≥ 1.4** — because the grid soffit at 4.0 m sits *above* em_lighting's daylight plane (`SKY_Y` 3.62), dropping the entire daylight family inside the room, plus emissive light panels at `emission_energy 2.0`. | a real bet; the opposite (the black cap dominating) is equally arguable |
| **P4** | The grid ceiling's `_create_ceiling_cap` — a near-black **unshaded** 0.3 m slab whose stated purpose is *"block exterior light/sky"* — is architecturally incompatible with a building whose light comes **through** its ceiling. Adoption seals the museum. | `GridCeilingComponent.gd:356-378` vs `em_lighting.gd:29,121-124` |

<a name="1"></a>
## 1. The two systems, measured side by side

Sources: `commons/grid/GridCeilingComponent.gd` (1155 lines), `commons/grid/CEILING_SYSTEM.md`,
`commons/scenes/em/em_detail.gd` (`_add_ceiling`, lines 1088–1135, constants 148–159).

| fact | `GridCeilingComponent` | `em_detail._add_ceiling` | disagree? |
|---|---|---|---|
| **type** | suspended drop ceiling (T-grid + acoustic tile) | structural coffered roof with daylight slots | — |
| **module** | **0.5 m** tile. Hard-forced: `initialize()` line 122 sets `tile_size = 0.5` and *discards* the `cube_size + gutter` it just computed | **3.0 m** `BAY`, shared with `SEAM_M` floor joints so the module reads in floor and ceiling | **YES — 6× apart** |
| **height (soffit)** | `ceiling_height` **4.0** default; presets 3.5 (office) / 4.0 (institutional, liminal, growing) / 4.5 (laboratory) / 6.0 (warehouse) | `CEIL_SOFFIT` **3.14**, fixed. Panels 3.14→3.40 (`CEIL_TOP`) | **YES — 0.86 m** |
| **lowest overhead element** | tiles at 4.005 (`ceiling_height + 0.005`) | rib soffit 2.96 (`CEIL_SOFFIT - RIB_DROP`), rib chamfer **2.943** | **YES — 1.06 m** |
| **relation to the wall head** | none. Walls are not consulted; the ceiling is a rectangle over the whole grid AABB | **`SHADOW_GAP` 0.14** — an explicit constant: 3.00 wall head → 3.14 soffit, a dark slot around every room's perimeter | **YES — one system has the concept, the other does not** |
| **perforation** | **sealed, deliberately.** `_create_ceiling_cap()` adds a 0.3 m box, albedo (0.02,0.02,0.02), `SHADING_MODE_UNSHADED`, comment: *"block sky/exterior"* | **18.3% open.** `SLOT_W` 0.55 of every 3.0 m bay is a real hole; panel length is `BAY - SLOT_W` = 2.45 | **YES — opposite intent** |
| **light source** | owns light. `OmniLight3D` on every 4th panel (`panel_count % 4 == 0`), `light_energy = intensity * 2.0`, `omni_range = 2.5`, shadows off; every panel emissive at `emission_energy_multiplier 2.0` | owns **no** light. Emits geometry only; `em_lighting` hangs 3 daylight spots at `SKY_Y = CEIL_TOP + 0.22 = 3.62`, *outside* the roof, reaching the floor only through the slots | **YES — one is a luminaire, one is an aperture** |
| **light layout** | 7 patterns (`sparse` default = `x%3==1 and z%3==1`, `checkerboard`, `random`, `sine`, `growing`, `perimeter`, `grid`) | n/a | — |
| **ribs / grain** | 0.02 m T-grid beams, one `MeshInstance3D` per lattice line, both axes | `RIB_W` 0.20 × `RIB_DROP` 0.18, both axes on the 3.0 m bay, plus `RIB_CH` 0.024 chamfers on the two lower arrises | — |
| **render primitive** | one `MeshInstance3D` **per tile**, per light panel, per beam | one `MultiMeshInstance3D` for the whole family (`_emit`, unit BoxMesh, size in the per-instance basis) = **1 draw call** | **YES — see P2** |
| **materials** | hardcoded `StandardMaterial3D`: tile (0.92,0.92,0.90) rough 0.85; T-grid (0.7,0.7,0.7) metallic 0.8; emissive (0.95,0.95,1.0) | resolved from the museum's library, `lib["ceiling"]` via `_role(mats, …, ["ceiling","get_ceiling",…])`, so the ceiling takes the building's plaster | **YES — closed vs injected** |
| **determinism** | **not deterministic.** `randf_range(0.998,1.002)` per tile scale (line 481); `randf()` in the `growing` pattern (453); `_add_subtle_flicker` uses `randf_range` | fully deterministic from `(w, h)` — same seed, same building | **YES** |
| **extras** | 5 fixture families (vents, sprinklers, smoke sensors, speakers, accent panels), seeded, 5 named presets; 12 "array learning" disco lessons driving the panels as a 2-D array display | none | — |
| **config surface** | `settings.ceiling` in `map_data.json`; 10 curated blocks in `commons/maps/ceiling_dna_library.json` | compile-time constants only |  |
| **live usage** | **2 map families**: `Lab` (+ 11 `map_data_post_*` variants) and `Tutorial_Disco`. That is it, out of 2049 maps | every segment of every museum, 30 templates | |

### The four disagreements that matter

1. **Module: 0.5 m vs 3.0 m, a factor of 6.** Not a tunable — `initialize()` *forces* 0.5
   regardless of the grid's own cell size, and the museum's 3.0 m is load-bearing twice over
   (floor seams are on the same module by design, so "the structural grid reads in both planes").
2. **Height: 4.00 vs 3.14, and 4.005 vs 2.943 at the lowest element.** The grid ceiling would
   float a metre above a 3.0 m wall head with nothing between them.
3. **The shadow gap exists in one system and is not a concept in the other.** `SHADOW_GAP` is
   a *relationship* between the wall head and the soffit. `GridCeilingComponent` never reads a
   wall; it cannot express the detail, and the detail is the museum's whole point ("costs zero
   geometry because it is made of the space between two things").
4. **Sealed vs perforated, and this is the one that decides the question.** The grid ceiling
   contains an explicit light-blocker. The museum's ceiling is an aperture and its light rig
   lives on the far side of it. These are not reconcilable by configuration; there is no
   `settings.ceiling` key that turns a cap into a slot.

---

<a name="2"></a>
## 2. The counterfactual — the museum WITH the grid ceiling, built and photographed

Talking about it settles nothing, so it was built. `commons/testing/em_ceiling_probe.gd`
instantiates `endless_museum.tscn` **unmodified**, lets its `_ready()` build the corridor and
compose its own proof shot (armed 90 frames out), and inside that window either leaves the
museum alone (`--probe=none`) or hides `em_detail`'s `Ceiling` / `ArrisCeiling` MultiMeshes and
installs `GridCeilingComponent` per segment over exactly the same footprint (`--probe=grid`).

Same seed (46), same building (`sainsbury-false-perspective-enfilade`, 17 × 30 cells), same
segment count (2), same rig, same standpoint. **The only difference between the two frames is
which ceiling is in the room.** No shipped file was edited to produce any of it.

### Geometry census — `doc/reports/ceiling_before.json` / `ceiling_after.json`

| | em_detail (BEFORE) | GridCeilingComponent (AFTER) |
|---|---|---|
| soffit / lowest overhead | measured off the transforms: **low 2.948 m**, top **3.400 m** | **4.000 m** (tiles at 4.005), cap 4.05–4.35 |
| render nodes, 2 segments | **4** `MultiMeshInstance3D` | **5110** `MeshInstance3D` |
| box instances | 204 (per segment: 42 ceiling + 60 rib chamfers) | 4344 tiles + 552 light panels + 214 T-grid beams |
| unique materials | 1 (`lib["ceiling"]` — the building's own plaster) | **552+** — `_create_light_panel` calls `light_material.duplicate()` per panel, so batching is defeated by construction |
| `OmniLight3D` added | 0 (em_lighting owns light, capped 24/segment, 6 shadow casters) | **~138** (1 per 4 panels), against that same budget |
| RNG calls | 0 — deterministic from `(w, h)` | **4344** unseeded `randf_range` (per-tile scale jitter), so the corridor stops being reproducible from its seed |

**1252× the node count and 313× the draw-call count for one ceiling over two segments.**
A 40-segment walk would be roughly 102,000 `MeshInstance3D`.

<a name="3"></a>
## 3. Images, with mtimes and the measured ceiling number

All under `C:\Users\palle\Documents\GitHub\AdaResearch_46\doc\reports\`. 1800 × 1200.
Luminance is Rec.709 on 0–1.

### Pair A — the museum's own composed proof frame (its shipped camera)

| | path | mtime | upper-25% mean | upper-25% std |
|---|---|---|---|---|
| BEFORE | `ceiling_before.png` | 2026-08-13 10:45:48.130 | **0.4049** | 0.0694 |
| AFTER | `ceiling_after.png` | 2026-08-13 10:46:20.372 | **0.4517** | 0.1021 |

ratio 1.116; whole-frame mean abs diff 0.0158, 3.57% of pixels changed by more than 0.125.

### Pair B — a standpoint that actually looks at the ceiling (mid-gallery 8.5, 18.0; pitch +0.38 rad)

| | path | mtime | upper-25% mean | upper-25% std | whole frame |
|---|---|---|---|---|---|
| BEFORE | `ceiling_room_before.png` | 2026-08-13 10:54:12.712 | **0.4185** | 0.0419 | 0.4217 |
| AFTER | `ceiling_room_after.png` | 2026-08-13 10:54:39.938 | **0.7402** | 0.1213 | 0.6388 |

ratio **1.769**; whole-frame mean abs diff 0.2205, **64.4%** of pixels changed by more than
0.125 (96.1% within the upper quarter). This is the pair to look at: BEFORE is a coffered
soffit with ribs on a 3 m grid and dark daylight slots between them; AFTER is an office
suspended ceiling — 0.5 m acoustic tiles, exposed T-grid, fluorescent troffers — inside a
Sainsbury Centre gallery.

### Supporting frames

| path | mtime | what it settles |
|---|---|---|
| `ceiling_plain.png` | 2026-08-13 10:55:38.146 | plain museum run, no probe script at all |
| `ceiling_plain2.png` | 2026-08-13 10:56:10.729 | second plain run — the run-to-run noise floor |
| `ceiling_up_before.png` / `ceiling_up_after.png` | 10:48:54.057 / 10:49:17.659 | first ceiling-aimed attempt (bad standpoint, see § 3.1) |
| `ceiling_up_hide.png` | 2026-08-13 10:51:44.404 | hide-only control that exposed the bad standpoint |
| `ceiling_overhead.json` | 2026-08-13 10:52:55.651 | overhead census with the ceiling hidden |

### 3.1 The standpoint trap, caught in flight

Pair A and Pair B are the same swap on the same building and they disagree by a factor of six
(3.57% of frame vs 64.4%). The museum's composed camera is deliberately built to hold a
foreground wall plane, which leaves the ceiling a corner of the picture. **Judged from that
camera alone, replacing a coffered daylight roof with an office drop ceiling looks like a 3%
edit.** This is the corpus's standing lesson — a dead verdict is only ever a fact about where
the camera was standing — arriving again in a new domain, and it is why this pass shot from two
standpoints instead of one.

A first ceiling-aimed attempt (`ceiling_up_*`) stood the camera under an occluder and reported
**0.00%** change across the top quarter of the frame. Rather than believe it, a **hide-only
control** was run: em_detail's roof removed and *nothing* put back. It also reported 0.00%
change in that region, which proves the region was never showing a ceiling at all. The
`--overhead` census then confirmed that with the ceiling hidden nothing in the building reaches
above 3.021 m. The measurement was moved to a standpoint where the subject is actually in
frame; in the far-ceiling band of those same aimed frames (rows 696–1008) the swap does show,
0.4220 → 0.5013, ratio 1.188.

<a name="4"></a>
## 4. Verdict on the predictions

| # | predicted | measured | |
|---|---|---|---|
| **P1** | grid 4.0 m; museum soffit 3.14, lowest 2.943 | grid **4.000** (tiles 4.005); museum measured off transforms **low 2.948 / top 3.400** | ✅ (2.943 vs 2.948 — the 5 mm is the 45°-rotated chamfer bar's true half-height, which the constant does not state) |
| **P2** | museum 20–60 instances/segment; grid > 2000 nodes/segment; ratio > 40× | museum **42** ceiling boxes/segment (102 with chamfers); grid **2555** `MeshInstance3D`/segment | ✅ ratio **1252×** on nodes — an order of magnitude past the prediction |
| **P3** | upper-band mean **rises**, AFTER ≥ 0.40, ratio ≥ 1.4 | direction ✅ (rises in every pair); AFTER ≥ 0.40 ✅ (0.452 / 0.740). **Ratio ≥ 1.4: ❌ on the museum's own camera (1.116)**, ✅ on the ceiling standpoint (1.769). BEFORE was predicted at 0.18–0.32 and measured **0.405–0.419** — ❌, the museum's soffit is far better lit than assumed | **❌ / partial** |
| **P4** | the sealed cap is architecturally incompatible | ✅, and worse than predicted — three modules depend on the roof being open, not one (§ 5.1) | ✅ |

**P3 is the one worth keeping.** It was wrong in exactly the way that mattered: it assumed
"the ceiling's brightness" was one number, and the answer turned out to depend on where the
camera stands — which is what forced Pair B into existence. A prediction that had agreed with
the first measurement would have shipped the 1.116 figure and understated the change by six
times.

<a name="5"></a>
## 5. Decision, and why

**The divergence is justified. The museum keeps `em_detail._add_ceiling`, the grid keeps
`GridCeilingComponent`, neither adopts the other, and no shared abstraction is worth building.**

### 5.1 Why the museum must not adopt the grid ceiling

1. **It is a light-blocker, and the museum's light comes through the ceiling.**
   `_create_ceiling_cap()` builds a near-black unshaded 0.3 m slab whose stated job is to
   "block sky/exterior". `em_lighting` hangs its entire daylight family at
   `SKY_Y = CEILING_TOP + 0.22 = 3.62`, *outside* the roof, so that it "reach[es] the room only
   through em_detail's 550 mm slots". Adoption seals them. There is no `settings.ceiling` key
   that turns a cap into an aperture: this is not a configuration gap, it is opposite intent.
2. **Three modules already consume the ceiling's geometry contract.** `em_props` duplicates six
   of em_detail's constants by name (`CEIL_SOFFIT`, `CEIL_THICK`, `BAY`, `SLOT_W`, `RIB_W`,
   `RIB_UNDERSIDE`) and its R4 rule pins every ceiling vent to *the middle of a solid panel*,
   explicitly because "a vent floating in an open slot is a vent in a hole". `em_lighting`
   documents the same section. `em_detail`'s own floor seams sit on the same 3.0 m module so
   the structural grid reads in both planes. Swap the ceiling and the vents hang at 3.14 m
   under a soffit at 4.0 m, in mid-air, and the floor loses the module it was answering.
3. **It costs 1252× the nodes and 313× the draw calls**, on a corridor that streams segments
   continuously, with 552 duplicated materials defeating batching by construction.
4. **It would break seed reproducibility** — 4344 unseeded `randf_range` calls per two
   segments, in a system whose contract is that `--em-seed=46` builds the same building twice.
5. **The picture is the argument.** `ceiling_room_after.png` is a 1970s office ceiling in a
   Chipperfield-grade gallery. 64% of the frame changed and all of it for the worse: the
   coffer's directional grain, the daylight slots, the 140 mm shadow gap and the rib chamfers
   all collapse into one flat luminous plane. (Std rises 0.042 → 0.121, but that is tile-grid
   noise, not modelling — more variance, less form.)

### 5.2 Why the grid must not adopt the museum's ceiling

`GridCeilingComponent` is not a worse ceiling; it is a **different working artefact with its own
live consumers**. `Tutorial_Disco` drives its light panels as a 2-D array display through twelve
named lessons (`CORNER_BLINK`, `INDEX_STRIDE`, `SUBARRAY_REGION`, …) — the ceiling *is* the
teaching surface for array indexing, and a 3.0 m coffered bay with 550 mm holes cannot be a lit
array. `Lab` and its eleven `map_data_post_*` states depend on the institutional look.
`commons/maps/ceiling_dna_library.json` curates ten configurations of it and
`commons/testing/capture_ceiling_dna_gallery.gd` renders them. Replacing it would break all of
that to serve a system that does not call it.

### 5.3 Why there is no shared abstraction here

Every fact in § 1 disagrees: module (0.5 vs 3.0), height (4.0 vs 3.14), wall relationship (none
vs a named 140 mm constant), perforation (sealed vs 18.3% open), light ownership (luminaire vs
aperture), render primitive (node-per-tile vs MultiMesh), material source (hardcoded vs
injected), determinism (RNG vs pure). A base class over two things that share no fact is an
empty interface with two implementations: more indirection, no reuse, and a fresh place for the
next agent to get confused about which one is authoritative.

**They are not two ceilings. One is a suspended service plenum; the other is a roof.**

<a name="ownership"></a>
## 6. Ownership — the line the next agent should not re-litigate

| world | ceiling owner | source | configured by |
|---|---|---|---|
| **grid maps** (`GridSystem`, `map_data.json`) | `GridCeilingComponent` | `commons/grid/GridCeilingComponent.gd`, `commons/grid/CEILING_SYSTEM.md` | `settings.ceiling` in the map; presets + `commons/maps/ceiling_dna_library.json` |
| **the endless museum** (`endless_museum.tscn`) | `EmDetail._add_ceiling` | `commons/scenes/em/em_detail.gd` (constants 148–159, builder 1088–1135) | compile-time constants; consumed by `em_props` R4 and `em_lighting` `SKY_Y` |

The museum does not build through `GridSystem` at all and never has — it says so in its own
header, line 12: *"Standalone and additive: no GridSystem, no shipped map touched."* The ceiling
is not an oversight in that separation; it is one of the places the separation is load-bearing.

**If you are here because the question came up again:** the answer is no. It has been built and
photographed. The images are `ceiling_room_before.png` and `ceiling_room_after.png`, and the
reason is that the museum's ceiling is an aperture with three downstream consumers while the
grid's is a sealed luminaire with two of its own.

### 6.1 The one thing that IS worth transferring — and it is not the ceiling

`GridCeilingComponent`'s **fixture family** (sprinkler heads, smoke detectors, ceiling speakers)
is real gallery equipment at body scale that the museum lacks: `em_props` R4 builds ceiling
vents and cable trays but no sprinklers, detectors or speakers. That is a prop gap in
`em_props`, to be answered in `em_props`' own idiom (MultiMesh, pinned to the bay module, kept
off the ribs). It is **not** a reason to adopt the ceiling plane, and it is left as a note
rather than done here.

<a name="7"></a>
## 7. The negative test — the probe is inert unless asked

The counterfactual is reachable only through `--probe=grid`. Proof that the gate bites, in both
directions, measured rather than asserted:

| comparison | mean abs luminance diff | pixels > 0.125 | |
|---|---|---|---|
| plain vs plain (**noise floor** — the renderer is not bit-deterministic) | 0.000275 | 0.007% | — |
| plain vs `--probe=none` (**gate OFF**) | 0.000348 | 0.010% | **1.3× the noise floor — indistinguishable from a plain run** |
| plain vs `--probe=grid` (**gate ON**) | 0.015821 | 3.571% | **58× the noise floor** |

On the ceiling standpoint the gate-ON separation is 0.2205, **802× the noise floor**. The
gate-OFF state sits inside the noise the engine produces between two identical runs, so the
probe demonstrably changes nothing until it is asked to.

Note the honest finding embedded in that table: **two identical museum runs are not
pixel-identical** (max per-pixel difference 0.366). Any future museum test that asserts image
equality must compare against this floor rather than against zero.

### 7.1 A concurrent writer, disclosed

`commons/scenes/endless_museum.gd` was modified by another session at **10:51:13**, in the
middle of this pass — not by this work, which edited no shipped file. The captures therefore
straddle two versions of the museum source, and a reader checking mtimes would notice, so:

- **Pair A** (10:45:48 / 10:46:20) — both pre-edit, internally consistent.
- **Pair B** (10:54:12 / 10:54:39) — both post-edit, internally consistent.
- **Noise floor** (`ceiling_plain` 10:55:38 / `ceiling_plain2` 10:56:10) — both post-edit.

The only cross-era comparison is *plain* (post-edit) vs `--probe=none` (pre-edit), and it came
back at 0.000348 — within 1.3× of the same-era floor. That is itself the evidence that the
concurrent edit changed nothing this pass measured. No conclusion here rests on a pair that
spans the edit.

## 8. What was added, and what was not

**Added — one file, on no shipped code path:**
`commons/testing/em_ceiling_probe.gd`, the counterfactual harness. Modes `none` (control),
`grid` (swap), `hide` (remove-and-replace-nothing control); options `--pitch`, `--stand`,
`--overhead`, `--report`. Compile-checked green.

**Not touched:** `endless_museum.gd`, `em_detail.gd`, `em_sets.gd`, `GridCeilingComponent.gd`,
`CEILING_SYSTEM.md`, `tools/museum_wizard.py`, `tools/pipeline_images.py`, anything under
`ada_encyclopedia/`, and every map. The decision was *not to change the code*, so the code did
not change.

**Reproduce:**

    python tools/godot_watchdog.py --expect=<png> --grace=240 --stall=60 -- \
      "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off --no-window \
      --script res://commons/testing/em_ceiling_probe.gd -- \
      --probe=grid --stand=8.5,18.0 --pitch=0.38 --em-seed=46 --em-segments=2 \
      --em-shot=<abs png> --report=<abs json>

Both `--em-shot` and `--em-segments` are required together; `--em-segments` is inert without
`--em-shot`. Never run two Godot instances at once.
