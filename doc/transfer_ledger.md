# The Transfer Ledger

> Palle (2026-07-20): "one important aspect is what improvements can be
> translated to other artifacts." This ledger is that aspect made operational.
> An improvement found on ONE artifact is only finished when it carries a
> **class-condition** — the test that names every other artifact it applies
> to — and has been propagated (or consciously scoped down). One entry per
> transferable improvement; status = OPEN / PROPAGATED / CLOSED.

| improvement | class-condition | reach | status |
|---|---|---|---|
| **Measured footprint → dressing room** | room `footprint` is a template default (1×1 or 6×6) AND registry has `measurements.grid_cells` | **695 rooms corrected** (cap 9, sync_footprints discipline) | PROPAGATED 2026-07-20 |
| **Measured footprint → registry** (`sync_footprints.py`) | `measurements.grid_cells` disagrees with `spatial_needs.footprint_cells` | registry-wide; 1 residual (weather_vector_field) applied | PROPAGATED (standing tool) |
| **One-scene-many-names wrapper** | any family of thin variants of one behavior (shape/mode/label differ, logic shared) — the grid stamps `artifact_lookup_name` meta before `_ready` | specimen (9) + affordance (6) families live; candidates: the 4 `*_array_demo`s, constraint fail/pass pairs | OPEN (pattern proven) |
| **PAD-plate labels (TextScreen mode 2)** | any artifact using a floating `Label3D` for its caption (the 2D-in-3D ruling) | LabelFramer class; specimen plinth uses it natively | OPEN (ruling standing) |
| **Leading-space token fix** | interactable cell where `cell != cell.lstrip()` with content | corpus swept CLEAN (10 cells, 3 maps) | CLOSED 2026-07-19 |
| **Type-taxonomy normalization** | `artifact_type`/`category` in a string-drift group | 128 entries, 13 groups → majority forms | CLOSED 2026-07-19 |
| **Family-voice conceit** | a mute artifact family sharing one substrate/idea (voice = shared conceit + per-member turn) | living_paper 28 + Gallery_ML 29 done; next: mesh (21), grab (14), step (14), profile (13), GlassRack (7), noc (7), Primitives design objects (~90) | OPEN (in progress) |
| **Placement re-optimization** (`place.py --in-place --only-improve` + pathfinder gate) | any map whose placement predates the engines | spine complete: 269 maps, 138 improved, 0 rollbacks | PROPAGATED (re-runnable) |
| **Dressing room from template** | registered artifact with no `dressing_rooms/<lookup>.json` (viewer can't jump to it) | 15 bricolage rooms made; residual class ≈ registry minus 2,585 roomed | OPEN (generate on demand) |

## The discipline

1. When auto research (or an editor session) improves one artifact, write the
   class-condition down HERE before moving on — the improvement isn't done
   until its reach is named.
2. Propagation is measured, gated, and reversible: measured values only
   (never template→template), caps honored (footprint cap 9), pathfinder/
   capture gates where behavior could change, git as the undo.
3. The map-DNA genomes (`/map-dna`) are the class-query surface: every
   condition above is computable from manifest `config` fields, so future
   transfers start as one query over `public/map-dna/*/manifest.json`.
