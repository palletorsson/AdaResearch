# Artifact Auto-Research

> The substrate's auto-research methodology, applied at the artifact scale.
> Every artifact in the project — ~750 of them — has parameters, has a visual
> output, has a place in a sequence's pedagogy. Iteratively refining each
> artifact toward its perfect image is the natural sibling to iteratively
> refining a map's substrate toward its plate.
>
> The substrate work proved the loop: write → capture → compare to seed →
> iterate. Same loop, smaller scale, more instances.

## The shift in scale

| | Substrate (map level) | Artifact (object level) |
|---|---|---|
| Unit | one map's GridMultiMesh | one Node3D artifact |
| Parameters | channel mutators + expressions + recipes | per-artifact `@export` fields + script logic |
| Capture | `capture_map_substrate_cycle.gd` (whole map) | `capture_multi_angle.gd --mode=artifact` (one object) |
| Visual seed | per-edge cousin image | per-artifact reference image / functional spec |
| Iteration speed | ~7 sec capture per pattern | ~3 sec capture per artifact |
| Scale | ~12 sequences × few maps | ~750 artifacts |

Most things stay the same: capture pipeline, visual-diff methodology,
human-in-the-loop critique, vision model for similarity scoring (when
that step is built). The differences are unit, parameter shape, and count.

## What auto-research means at the artifact scale

Five stages, mirroring the substrate's auto-research loop:

```
   ┌──────────┐    ┌──────────────┐    ┌─────────────────┐
   │ artifact │ →  │ parameter    │ →  │ variant builder │
   │ identity │    │ space        │    │ (sweep / random) │
   │ (.md)    │    │ (@exports)   │    │                  │
   └──────────┘    └──────────────┘    └─────────────────┘
                                                 │
   ┌──────────┐    ┌──────────────┐               │
   │ critique │ ←  │ capture set  │ ←─────────────┘
   │ (vision  │    │ (multi-angle │
   │  + human)│    │  pngs)       │
   └──────────┘    └──────────────┘
```

### Stage 1 — Artifact identity

Each artifact already has a slot for this in `doc/plans/artifacts/<name>.md`
(generated). The `@identity` block at the top of every artifact's GDScript
also fills it: `essence`, `desire`, `critical_parameter`, `triggers`,
`emerges`, `needs`, `relationships`, `truth`. The `critical_parameter`
field literally names what to vary in stage 2.

### Stage 2 — Parameter space

Most artifacts already expose `@export` fields. The parameter space is
the cross-product of those fields' valid ranges. For an artifact like
`pompeii_mosaic_floor`, that might be: `tile_size`, `palette_index`,
`grout_color`, `weathering_amount`, `motif_density` — five fields, each
with 3–8 sensible values, ~3000 variants.

For artifacts whose parameter space is too large to sweep exhaustively,
the variant builder samples (random or low-discrepancy / Latin hypercube).
For artifacts whose parameter space is too small, just enumerate.

### Stage 3 — Variant builder

A new tool `tools/sweep_artifact.py` that:
- Reads the artifact's `@export` declarations from its `.gd`
- Reads a sweep config (which fields, which value sets, sampling strategy)
- For each variant, instantiates the artifact, sets the fields, captures
  via `capture_multi_angle.gd --mode=artifact`
- Names the output `<artifact>__<variant_hash>.png`
- Records the parameter values in a sidecar `<variant_hash>.json`

For a 5-field artifact with 3 values each = 243 variants. ~12 minutes per
artifact at 3 seconds per capture. Acceptable for nightly batches; too
slow for inline iteration.

### Stage 4 — Capture set

Already exists: `commons/testing/capture_multi_angle.gd --mode=artifact`
produces 4–12 angles per artifact. Each variant of stage 3 emits one
capture set.

### Stage 5 — Critique

The art / curatorial step. Three options:

- **Visual seed comparison** — like the edge-cousins moodboard, each artifact
  has a reference image (a Haeckel plate, a Codex page, a hand sketch, a
  prior-iteration of the artifact). Vision model returns a similarity score
  and a paragraph. Same shape as proposed for substrate.
- **Functional spec comparison** — for artifacts whose value is functional
  (showing an algorithm), critique asks: *did the algorithm read?* "I see
  rule 30 evolving as a triangular pattern" → pass. "I see noise" → fail.
- **Aesthetic vote** — rare; for artifacts where no spec exists, only
  an aesthetic answer.

Score + paragraph feed back into stage 2's parameter space. The next
iteration narrows the sweep around the high-scoring variants.

## What's already partly done

The project already has *most* of an artifact-iteration pipeline; what's
missing is the loop closure:

| Stage | Existing | Gap |
|---|---|---|
| Identity | `@identity` blocks in most GDScripts; `doc/plans/artifacts/*.md` | many incomplete |
| Parameter space | `@export` fields throughout | no machine-readable sweep spec |
| Variant builder | one-off scripts in `commons/testing/` | no general-purpose `sweep_artifact.py` |
| Capture | `capture_multi_angle.gd`, `capture_artifact_shot.gd` | working |
| Critique | manual eyeball | no vision-model loop yet |

The two missing pieces — `sweep_artifact.py` and the vision-critique runner
— are the same scripts the substrate auto-research needs. **Build them
once, use them at both scales.**

## A small first cycle

Pick one artifact. Iterate it end-to-end with the loop. If it works,
generalise.

Suggested first artifact: **`pompeii_mosaic_floor`** (in
`algorithms/color/pompeii_mosaic_floor/`). Reasons:

- It's tile-based, so the parameter space is finite-ish (palette × tile-size
  × motif-density × weathering = ~50 variants).
- It has a clear visual seed: actual photographs of Pompeii floors
  (the user's `arttoeat/qfep/` folder for reference if needed).
- It's already shipped, so we know it renders.
- It's pedagogically rich — a good demonstration of "how the auto-research
  loop refines an artifact."

The first cycle:

1. Write a sweep config: which fields, which values.
2. Sweep produces ~50 variants, each a 4-angle capture set.
3. Pull up reference Pompeii photographs alongside.
4. Score each variant manually (1–5) — bootstrap the dataset before any
   vision model.
5. The top-scoring variants get tagged as "canonical defaults."
6. Update the artifact's defaults to the highest-scoring values.
7. Capture once more with new defaults; that's the new baseline.

Half-day's work to ship the first artifact-cycle proof. After that,
the loop repeats per-artifact at the rate the curriculum needs.

## Where this dovetails with substrate work

Substrate runners (like `FoldTheatreRunner`) ARE artifacts in this sense.
They have parameters (`floor_plan_layers`, `glyph_max_subdivided_cells`,
`color_by_role_palette`, etc.). They produce visual output. They have
visual seeds (Haeckel Tafel 9, Codex carousel).

The same auto-research loop applies. **A substrate runner is just an
artifact whose internal logic is mutator-driven.** The loop doesn't care
whether the parameters drive a procedural mesh or a substrate mutator
configuration.

## Open path

The substrate work pauses at the baseline locked above. The artifact-
auto-research work begins by:

1. Writing `tools/sweep_artifact.py` (general-purpose variant capture).
2. Writing `tools/critique_captures.py` (vision-model comparison).
3. Running both on `pompeii_mosaic_floor` end-to-end.
4. If proven, repeat across the 750 artifacts at whatever rate is
   sustainable, prioritising spine artifacts first.

After that's solid, return to the substrate work with the artifact loop
as a tool that also iterates substrate runners.

*Started 2026-04-27, after the substrate baseline lock.*
*Sibling to `doc/SUBSTRATE_STATE_BASELINE.md`.*
