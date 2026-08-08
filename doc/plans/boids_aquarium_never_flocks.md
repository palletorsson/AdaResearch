# boids_aquarium never flocks

**Status:** FOUND, not fixed — the fix is a design and performance decision, not a bug repair.
**Found:** 2026-08-08, by `tools/temporal_lint.py`.

## The measurement

Two frames, nothing asked to change:

| gap | frame moved |
|---|---|
| 0.15 s | 0.15% |
| **3.0 s** | **0.14%** |

Three seconds produces the same number as a seventh of a second. A school that flocks drifts
steadily; this one is a fixed image. The residual 0.14% is the info plate, not the boids.

## Why

`commons/artifacts/boids_aquarium/boids_aquarium.gd` is the only script in the scene and it
has **no `_process` and no `_physics_process`**. Nothing integrates velocity. The slider
callbacks set `separation_weight` / `alignment_weight` / `cohesion_weight` and call
`_update_boid_params()`, which only refreshes the caption — the weights are stored and never
applied to anything that moves.

## Why this is a gap and not a preference

The file's own identity block promises motion, in its own words:

- *"Flocking simulation in a glass tank"*
- *"emerges: rotating toroids, figure-eight loops, and sudden directional consensus events —
  the tank finds shapes the designer never chose"*
- *"triggers: dragging SEP slider to max produces cold dispersal; dragging COH to max produces
  a pulsing sphere"*

None of that can happen. In VR a visitor can drag all three sliders and the school will not
move, because there is no loop to move it.

## What is genuinely deliberate

The DNA work on `accord` is explicit that the *still* needs a standing configuration:

> "The capturer waits ~1.1 s and shoots, so the axis has to be legible in the STANDING
> configuration, not after a long run. Every value is deposited arithmetically — no pre-roll,
> no convergence loop."

That reasoning is sound for the photograph. It says nothing about the artifact at play, and
the deposit appears to have become the whole implementation.

## The decision, which is Palle's

1. **Add the integrator.** Restores what the identity promises. Costs a per-frame update over
   ~30 boids with a spatial hash — cheap on desktop, and this ships to a Quest, so it needs a
   budget check. The DNA sweep must keep photographing the standing deposit, so the loop would
   have to be suppressed under `dna.fixture` — the same mechanism that hid the
   `line_builder_3d` flicker, so it would need to be applied honestly this time: pinned for
   the bench, live in the world, and never the reverse.
2. **Correct the identity.** If a standing tableau of four flock shapes is what this artifact
   is for, the header should say so and stop promising toroids and consensus events.

Doing neither leaves an artifact whose documentation and behaviour disagree, which is the
condition that made every other finding in this session expensive to track down.
