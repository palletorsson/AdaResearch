# The twelve-artifact fan-out — HELD, not shipped

**Status:** REVERTED 2026-08-10. Work preserved in `doc/plans/aaa_fanout_batch.patch` (5,841 lines).
**Reason:** it made the pictures measurably worse, and broke R1 on the most-placed artifact in
the corpus.

## What was attempted

Twelve agents, one per artifact, migrating the most-placed artifacts in the project onto
`commons/render/pbr_kit.gd` and `commons/render/mesh_kit.gd`. Combined reach: **6,527
placements**, led by `exhibit_furniture` at 2,463 — more than double the next artifact.

Eight agents returned; four hit a session limit and had already written finished work to disk,
so eleven of twelve landed. All eleven compiled.

## Why it was reverted

Same rig both sides, so this is a like-for-like comparison of the code change alone:

| metric | before | after | |
|---|---|---|---|
| midtone_sd | 0.155 | 0.146 | flatter |
| unique colours | 169 | 158 | fewer |
| clipped | 1.26% | 1.44% | worse |
| **crushed** | **0.20%** | **1.35%** | **6.7x worse** |
| faulty frames | 7/33 | 9/33 | worse |

Every metric moved the wrong way. But the numbers were not the reason to stop — the picture
was. `exhibit_furniture`'s plinths went from SOLID BOXES to HOLLOW SHELLS you can see through,
with the interior of the far wall visible through the front face. That includes `white_cube`,
which is the shipped default, so this is an R1 break across 2,463 placements.

## What it looks like

`ada_encyclopedia/public/aaa-summary/fanout_furniture.png` — top row before, bottom row after,
three house values. The failure is unmistakable at a glance and invisible in the agent reports,
every one of which is careful, well-argued, and confident.

## The likely cause, unconfirmed

The symptom is front faces missing rather than genuine transparency: you see the inside of the
back wall. That points at `PbrKit.box`'s chamfer producing wrong winding or degenerate geometry
for some size-and-bevel combination, rather than at a material alpha. It is NOT the glass
routing — that is correctly gated on `slot == "glass"`.

If it is the kit, it matters beyond this batch: `PbrKit.box` is used by the fourteen artifacts
already shipped. Those render correctly today, so any fault must be conditional on proportions
this batch introduced — thin-walled boxes are the obvious suspect.

## What to do next

1. Build a minimal repro: one `PbrKit.box` at the plinth's dimensions and bevel, rendered
   alone. Confirm or clear the kit before touching eleven artifacts.
2. If the kit is at fault, fix it there and re-apply the patch unchanged — the agents' work is
   otherwise substantial and well reasoned, particularly `exhibit_furniture`, which derives
   per-instance grain scale from the framed diagonal and correctly identifies that a family
   spanning 0.4 m to 4.85 m cannot use one tiling number.
3. If the kit is fine, the fault is in the batch and each artifact needs its own look.

## The lesson worth keeping

Eleven agents produced detailed, internally consistent reports about material response, grain
scale in pixels, triangle budgets and R1 preservation. `exhibit_furniture`'s report states the
default lineage was "traced end to end" and that body albedo moves 0.6%. The plinth is hollow.

No report is evidence. The render is evidence.
