# Proposal — `change` sequence (order 4.5)

_Drafted 2026-05-13. Follows from the [math-density sieve](/doc/sieve_passes/2026-05-13T09-15-00_math-density.md)._

## What this is

A proposal for a **new spine sequence** at order 4.5 — between `color` (order 4) and `forces` (order 5) — whose job is to introduce the calculus substrate (change / accumulation / flow) before the four sequences that use it implicitly.

The math-density sieve identified the gap: forces, wavefunctions, randomness, and noise all rest on a calculus shadow that is never named. The fix is small (one sequence) and conservative (the spine's framing is preserved). This document specifies what the sequence should be so it can be implemented and built against.

## Truth statement

> **Things change. Change accumulates. Accumulation flows.**

Three sentences, one for each sub-unit of the sequence. They name the three calculus atoms the player needs in their pocket before the analytic sequences begin.

## QFEP role + phase

- **Phase**: `F_order` — still foundational. Change is what makes ordered foundations *do anything*; it's the bridge between static structure (primitives, transformation, arrays, color) and dynamic structure (oscillation, entropy, lambda_edge).
- **QFEP role**: *"Foundation — the calculus substrate. Derivative as instantaneous rate of change, integral as accumulated quantity, vector field as flow. The conceptual vocabulary that forces, wavefunctions, randomness, and noise will all use."*

## Position in spine

```
order  sequence              phase
1      primitives            F_order
2      transformation        F_order
3      array_tutorial        F_order
4      color                 F_order
4.5    change                F_order        ← NEW
5      forces                oscillation
6      wavefunctions         oscillation
7      randomness            E_entropy
...
```

The 4.5 ordering matches the existing convention used at 12.5 (isosurfaces) and 12.7 (boolean_surfaces) — explicit half-step inserts that don't shift the overall numbering.

## Prerequisites + unlocks

- **Prerequisites**: `color` (functions named at seq 4 — *"every gradient is a function from t∈[0,1] to a color"*) — change is what happens *to* a function.
- **Unlocks**: `forces`, `wavefunctions` — the player can now hear forces talk about derivatives and wavefunctions talk about Fourier integrals without being lost.

## Learning objectives

1. **Change as instantaneous rate** — the derivative; slope of a curve at a point; velocity as rate of position.
2. **Slope across a curve** — how slope itself becomes a function (derivative-as-function).
3. **Accumulation as continuous addition** — the integral; area under a curve; total from rate.
4. **Riemann sum** — discrete accumulation approaching continuous; how rectangles become integrals in the limit.
5. **Vector fields** — change-and-flow at every point in space; the first encounter with a function of space (not just time).
6. **The fundamental theorem of calculus** — change and accumulation are inverse operations; one undoes the other.
7. **Carry-forward to forces and waves** — `F = ma` is calculus made physical; `sine` is the function whose second derivative is itself negated.

## Maps (proposed)

Eight maps. Naming convention follows existing sequences (`Trans_*`, `Color_*`, etc. → `Change_*`):

| order | map | content |
|---|---|---|
| 1 | **Change_Intro** | a curve in space, a tangent line that slides along it; tangent's slope reads out as a number |
| 2 | **Change_Velocity** | a particle moves; its position over time draws a curve; its velocity arrow is the derivative made visible |
| 3 | **Change_Slope_Surface** | a 2D function `z = f(x,y)`; partial derivatives shown as slope arrows in x and y |
| 4 | **Accumulation_Area** | a curve and a shaded area beneath it; slider moves the right boundary; area readout tracks |
| 5 | **Accumulation_Riemann** | discrete rectangles approaching a continuous integral as count increases; player adjusts partition |
| 6 | **Flow_Field** | a 2D vector field — arrows everywhere; visually wavy / circulating / divergent depending on the field |
| 7 | **Flow_Particle_Pulse** | release particles into a field, watch them flow along it |
| 8 | **Change_Reconciliation** | the FTC bridge — animation showing derivative + integral are inverse; transition into a chamber |
| 9 | **Chamber_Change** | catalyst chamber: introduce the *sustain* catalyst affordance (see below); first catalyst foe whose state shifts under sustained contact |

## Artifacts needed

Most of these don't exist yet. Listed here as the design target — the sequence file ships scaffolded; artifacts get built into the placeholders over time.

| artifact lookup | what it is | priority |
|---|---|---|
| `slope_tangent_demo` | curve + tangent line that slides; slope value renders out | core |
| `derivative_pair` | function on left, its derivative on right; both animate together | core |
| `velocity_arrow` | particle with rate-of-change arrow visualized | core |
| `partial_derivative_terrain` | terrain surface, slope arrows at sampled points in x and y | secondary |
| `riemann_pump` | adjustable Riemann sum: slider for partition count, rectangles update | core |
| `integral_area` | curve + shaded area, slider for upper bound | core |
| `vector_field_grid` | 2D grid of arrows for `f(x,y) = (vx, vy)`; presets for rotational / divergent | core |
| `particle_flow_swarm` | particles released into a vector field, follow streamlines | secondary |
| `ftc_bridge` | animation: derivative → integral → original function (round trip) | core |
| `catalyst_sustain_demo` | demo for the **sustain** catalyst affordance — orb-on-contact builds accumulating effect | core, new affordance |
| `science_screen` | (reuse) text panel with calculus formula display | reuse |
| `code_display` | (reuse) the equation rendered with sliders for parameters | reuse |

Most of these have natural prior art in the project — `riemann_pi` exists (Pi via Riemann sum at the QFEP lab), `vector_field_grid` patterns exist in some forces artifacts, particle systems exist for noise. The build cost is moderate.

## Catalyst affordance — *sustain*

This sequence introduces a new catalyst affordance, in line with the [catalyst-arsenal mapping sieve](/doc/sieve_passes/2026-05-13T09-45-00_catalyst-arsenal-mapping.md):

> **sustain** — catalyst contact accumulates over time. Hold the orb on a target and the effect builds (rate × time = total). Release to dissipate. This is the *integral* in catalyst form.

Pedagogically clean: the calculus the player just learned becomes a bracelet affordance.

Pairs well with the **gather** verb at forces (seq 5) — sustain at seq 4.5 is "accumulate over time"; gather at seq 5 is "accumulate from a field." Both are integral-shaped; one is time-indexed, the other space-indexed.

## `soft_stages.json` entry

```jsonc
"change": {
  "order": 4.5,
  "ecosystem": {
    "allow_flags": ["function_visualization", "rate_arrows", "field_arrows"],
    "nature_kingdoms": ["flower"],   // carries from color
    "vegetation_density": 0.08,       // slight, slightly less than forces=0.15
    "terrain_mode": "flat",
    "ambient_preset": "calc_lab"
  },
  "hazards": {
    "unlock_types": [],
    "spawner_behavior": "dormant",
    "personality_shift": {},
    "max_concurrent": 1
  },
  "capability": {
    "capacity_level": 4,
    "hand_verbs": ["observe", "grab", "snap", "trace", "sustain"],
    "catalyst_mode": "change",
    "catalyst_affordances": ["accumulate", "trace-rate", "flow-along"],
    "movement_abilities": ["teleport"]
  },
  "enemies": {
    "kind": "goo",
    "comment": "Foe variant for the calculus sequence — same goo, tickled by sustained contact instead of one-shot impact. The new affordance teaches the new way to engage."
  }
}
```

The new field `catalyst_affordances` is introduced here per the arsenal sieve. The existing F_order sequences should be retroactively populated:

| sequence | catalyst_affordances |
|---|---|
| primitives | `["orb", "wand", "spell", "agent"]` |
| transformation | `["shift", "rotate", "shrink"]` |
| array_tutorial | `["grid-stamp", "pattern"]` |
| color | `["paint", "rainbow-arc", "context-tint"]` |
| change *(new)* | `["accumulate", "trace-rate", "flow-along"]` |

After F_order the player has **15 affordances** in 5 categories.

## Difficulty + estimated time

- **Difficulty**: `intermediate` — first sequence that moves from operational to analytic. The earlier sequences teach things-and-operations; this one teaches *how to think about a thing changing*.
- **Estimated time**: `20-30 minutes`

## Why this is the right size

A common temptation would be to make calculus a longer sequence with separate slots for *derivatives*, *integrals*, *partial derivatives*, *vector calculus*, *differential equations*, etc. That would be a math course.

This sequence's job is different. It exists to **establish the vocabulary** so the four sequences that follow (forces, wavefunctions, randomness, noise) can name what they're doing. The player doesn't need to *solve* calculus problems; they need to *recognize* derivative-shaped and integral-shaped patterns when they appear later.

That argues for *light, dense, visual*. Eight maps. One affordance. Three named atoms. Then move on.

## What gets unblocked

Once `change` exists in the spine:

- **Forces** can name what it's doing — derivatives in F = ma, acceleration as second derivative.
- **Wavefunctions** can be honest about Fourier — *"integration in the limit; same accumulation move as Riemann sums, generalized."*
- **Randomness** can write Shannon's formula — `H = -Σ p log p` reads as *expectation, weighted by log of probability*; the integral arises naturally as the continuous form.
- **Noise** can talk about its octaves as *layered scales* — frequency in Fourier terms.

Each downstream sequence saves one bullet of *implicit-and-undischarged*. The whole F_order → oscillation → E_entropy → λ_edge transition becomes legibly continuous.

## What this proposal does not include

- Specific shader / mesh implementations for any artifact. Those land in the artifacts' `.gd` and `.tscn` files when built.
- Map layouts (cell-by-cell). The spine_walker's editor + the existing `/editor` are the right tools for those when the time comes.
- The actual learning text (`learning_objectives` per sequence — those are listed above but final phrasing happens at edit time).
- The capture pipeline for the new artifacts — that just uses the existing `batch_capture_via_api.ps1` once the artifacts exist.

This proposal is the **structural placement** — what the sequence is, where it sits, what it teaches, what catalyst affordance it brings. Implementation lands in the JSON files; build happens artifact-by-artifact afterwards.

## Implementation steps (this session)

1. Add 6 one-bullet additions to existing sequences' `learning_objectives` (per math-density sieve, recommendation 6a).
2. Create `commons/maps/sequences/change.json` from the spec above.
3. Add `change` to `commons/maps/curriculum_spine.json` at order 4.5.
4. Add `change` stage to `commons/maps/soft_stages.json`, plus retroactive `catalyst_affordances` on the F_order stages.

Each step is a focused JSON edit. None requires Godot. All are checkable by walking the spine_walker after.

---

*Next: implement.*
