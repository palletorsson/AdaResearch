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

## The cause, now DIAGNOSED — and both first guesses were wrong

**It is not the geometry.** `commons/testing/probe_pbr_box.gd` builds ten boxes at the exact
sizes and bevels this batch used and runs an edge census: in a closed mesh every edge is shared
by exactly two triangles. **0 of 10 failed** — including a 4 mm panel, an oversized bevel, and
a bevel exactly at half the minimum dimension. `PbrKit.box` is watertight, and the fourteen
artifacts already shipping on it are safe.

**It is not transparency.** Only 8 colours in the palette carry alpha below 1: six are the
`glass` slot and two are contact-shadow quads. Every body colour is opaque.

**The bodies are simply THREE TIMES TOO DARK.** Measured on `white_cube`, the shipped default,
over the plinth body:

| | mean luminance | near-black px |
|---|---|---|
| before | **209.5** | 0.0% |
| after | **66.6** | 1.8% |

Its palette entry is `body: Color(0.85, 0.83, 0.78), r 0.6` with **no metallic key**, so it is a
bright dielectric by declaration. It renders at a third of its albedo. A white cube that is not
white has lost the thing it is named for.

"Hollow" was the eye's reading of a near-black body beside a lit cap and a dark floor. The
corpus-wide metric said the same thing in numbers and I read it too slowly: **crushed 0.20% ->
1.35%, a 6.7x rise.** That is lesson 5 from the brief — three subtle darkenings agree on black —
recurring at scale despite being written into the brief as a rule.

## Where to look next

The stacking is the suspect, not any single call: `weather()`'s grime multiply (floor 0.60-0.95),
`crevice_ao`, `rams_body`'s wear darkening, and the roughness retarget the agent added all
multiply into the same surface. A 0.32x survival factor needs more than one of them. The fix is
almost certainly a budget — at most one darkening per surface, asserted rather than intended —
not a per-artifact re-tune.

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
