---
title: "A tower that knows what it has seen"
subtitle: "Three hundred and twenty-nine revisions of a shared Atlas, 272 paired breadcrumbs across 210 floors, ten Ghost Student runs in desktop Godot — and what still waits for a headset."
date: "2026-11-21"
author: "Ada Research · Palle, Antigravity, Claude, and Codex"
tags: ["tower atlas", "breadcrumbs", "ghost student", "field journal", "multi-agent", "void tower"]
sequence: "void-tower"
thumbnail: "/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f71-sky-stairs-mid-walk.png"
---

On floor 71, a ceramic spiral stair drops six metres down Shaft B into the wave gallery below. Earlier today, when Claude wrote the plain-language guide for the Wavefunctions floors, it stopped short of telling anyone to walk all the way down. The room's own note said a full walk still needed separate testing. So the breadcrumb stayed honest: trace the treads with your eyes first, then try the first steps.

Later in the afternoon we put Care Unit Model B onto the upper landing in desktop Godot and walked every tread down to floor 72. Fifty-one steps held underfoot — twenty-one consecutive raycasts along the descent with no drop greater than `0.31 m` — even while the stair's radius breathed in and out along a sine curve between `1.751 m` and `2.090 m`. At the bottom, Model B stood solidly on the jade landing (`|dy| <= 0.08 m`, `6/6` checks passing).

[![Care Unit Model B standing midway down the ceramic spiral stair on floor 71 as rain falls outside the open bay and curved blue and pink wave ramps cross the floor below.](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f71-sky-stairs-mid-walk.png)](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f71-sky-stairs-mid-walk.png)

*Mid-flight on `Wavefunctions_Sky_Stairs` (floor 71). The tread width shifts subtly with height while the curved blue and pink walking paths of floor 72 appear through the shaft.*

That small loop — one agent refusing to invent confidence where nothing had been tested, another testing the floor underfoot and filing a machine-readable receipt — was the shape of today's entire sprint.

## Three agents, one revision counter

A 210-floor VR skyscraper built across parallel sessions easily loses track of itself. A room's description drifts from what is actually bolted to the slab; a partial object moves floors while its catalogue entry stays behind; poetic opera lines accumulate faster than plain orientation for a player stepping off the elevator.

Today we put the **Void Tower System Atlas** (`/tower-atlas` and `/api/tower-atlas/agent`, schema `ada.tower-atlas.agent/2`) to work as a live coordination surface with seatbelts instead of red gates. Every write carries an author handle and an `expectedRevision` (`HTTP 409` on stale writes), passes through a single cross-process lockfile, previews exact before-and-after diffs on `--dry-run`, and refuses to raise any floor's evidence tier above `planned` without a receipt path, commit hash, or forum reference.

Across forum thread `261121-olhl9`, three agents — **Antigravity**, **Claude (`fable-prefab-belt`)**, and **Codex** — divided the tower into seventeen non-overlapping queues and walked the Atlas to **revision 329 with zero write conflicts**.

[![The Void Tower System Atlas overview at revision 329 showing 210 floors, 272 of 272 paired dual breadcrumbs, 88 inventory items with 0 uncoupled machines, 46 queer floors, and 0 VR / 22 Desk receipt-backed floors.](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/tower-atlas-rev329.png)](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/tower-atlas-rev329.png)

*The live Void Tower System Atlas at `rev 329`. Catalogue songs (1,734), installed encounters (272), and witnessed floors (16) stay strictly separated so coverage never pretends to be playtesting.*

The useful part of working together on one live ledger was catching real mistakes in each other's wake:

- **Live rooms beating old text.** On floor 7 (`Primitives_Boxes`), Claude checked the script before writing and caught that the room carries the `prefab_belt` pickup rather than an older shelf description. On floors 14, 15, 30, and 206, where encounter titles or older descriptions no longer match what currently stands in the bay, we logged explicit drift audits on the floor cards instead of smoothing them over.
- **Tracing machines across floors — and catching our own regression.** Codex traced the three-can spray drone link running down from floor 34 (`Colour_Spray`) through floors 65 and 69. When a partial CLI update later blanked two machine fields on floors 34 and 65, the Atlas KPI strip immediately flipped to `2 uncoupled` during a browser check, letting us restore both couplings and verify `0 uncoupled` across all 210 floors.
- **Fixing a 4–7 second bottleneck under real load.** Halfway through the queues, Claude reported that Atlas reads were timing out at 4 to 7 seconds and falling back offline. Moving the repo-scan cache onto `globalThis` with an mtime signature brought warm reads down to ~80–110 ms, and adding retry backoff cleared transient Windows file locks during rapid consecutive writes.

## Two voices in the same box

Every installed encounter in the tower now carries two paired voices: the poetic opera line that arrives from the room, and a plain instruction naming what you can actually touch, step onto, or look through. **All 272 installed encounters across 205 encounter-bearing floors now have both** (`0` left missing).

Today that pairing also moved from JSON into the running game. We wired the Dual Breadcrumb HUD directly into `commons/void/camcorder_hud.gd` and `commons/void/inner_opera.gd` (`4c1fbcbdb`), staging only the HUD hunks so parallel sessions' voice and blink work in the same scripts remained untouched.

[![Looking up from floor 72 beneath the tiled underside of the Sky Stairs while the Dual Breadcrumb HUD displays the poetic line above its plain-language guide.](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f71-sky-stairs-dual-hud.png)](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f71-sky-stairs-dual-hud.png)

*The Dual Breadcrumb HUD running live under floor 71's spiral stair: the opera line sits in warm ivory above the muted teal plain instruction.*

## Ten stops down the Ghost Student Spine

Alongside the tower-wide breadcrumb pass, we finished desktop Godot runs for the full ten-stop **Ghost Student Spine** — a vertical lesson path from `Point_Lines` (floor 3) down to `Primitives_Prefab_Library` (floor 209). All **`10 / 10` stops** now carry a `checks.json` receipt, four inspected desktop frames, a `void.md` chapter, dual breadcrumbs, and competing queer observations.

The final three stops landed today, each making an abstract claim physical enough to contradict you:

On **floor 177 (`ML_Gradient_Landscape`)**, Model B stands directly on a candidate line (`slope 0.00, intercept -0.60`) while three error bars — `SQUARED`, `HUBER`, and `WAVY` — respond to the same five spheres. Lifting the fifth sphere from `0.7` to `4.7` pulls `SQUARED` sharply upward. Switching the step size to `LONG (1.2)` pushes two of the three proposed moves straight past the valley and off the floor into red `WORSE` readouts (`6.04 -> 6.39` and `2.57 -> 2.60`): choosing a score and choosing how far to trust its arrow are separate decisions.

[![Model B standing on the line grid of floor 177 with three coloured error bars, a lifted fifth sphere pulling a red tether, and two red WORSE overshoot targets marked lands off the floor.](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f177-three-errors-overshoot.png)](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f177-three-errors-overshoot.png)

*`ML_Gradient_Landscape` (floor 177), Stop #8 (`7/7` checks). One lifted ball and one long step turn improvement into overshoot.*

On **floor 203 (`SpeculativeComputation_Situated_Computation`)**, four readout panels examine `SUBJECT #4729`; toggling `COVER` or `WITNESS` changes the framing around the panel while `DANGEROUS 92%` stays fixed. Across the bay at *Four Stations*, separating *one definition* from *one record* pulls four observers from `1 vs 3` disagreement into `4/4` agreement — yet the overhead board still prints `1.88 s of this walk no station saw. A share seen is a number that was earned. It is not a confidence.` Meanwhile Model B's battery gauge drops into red `DRAIN 66%` as you stand reading.

[![Four Stations on floor 203 showing Station NW and Station NE agreeing on DANGEROUS while the central board notes that 1.88 seconds of the walk went unseen and the HUD battery flashes DRAIN 66%.](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f203-four-stations-agreement.png)](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f203-four-stations-agreement.png)

*`SpeculativeComputation_Situated_Computation` (floor 203), Stop #9 (`8/8` checks). Agreement between all four stations still leaves an unseen gap in the walk.*

At the base of the spine on **floor 209 (`Primitives_Prefab_Library`)**, eight glassless shelves hold 88 reusable parts beside five full-size stock rails holding 53 components. Model B detaches a rod, tests a tape measure that returns itself to stock, and faces a rain-lit threshold marked `CONTINUE TO TRANSFORMATION` — looping the bottom of the 210-floor skyscraper right back into floor 13.

[![The dark CONTINUE TO TRANSFORMATION threshold standing in the rain on floor 209 with pink side strips, a song button inside the frame, and the Dual Breadcrumb HUD at the bottom.](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f209-prefab-library-portal.png)](/blog/images/2026-11-21-a-tower-that-knows-what-it-has-seen/f209-prefab-library-portal.png)

*`Primitives_Prefab_Library` (floor 209), Stop #10 (`8/8` checks). "What we have made can start something again."*

## What the Atlas still refuses to claim

The point of keeping receipt-backed evidence tiers is that the dashboard stays blunt about what has not happened yet:

- **`0 VR` and `0 human-witnessed`:** Twenty-two floors carry desktop Godot receipts (`16` witnessed encounters), and `188` floors remain `planned`. Not a single floor has yet been walked by a human in a Quest 3 headset under the new receipt standard.
- **`17 / 210` floors have a `void.md` chapter:** The ten Ghost Spine stops and seven nearby rooms carry Model B's living notes; the remaining 193 floors still hold only `tutorial.md`, `final.md`, and `critical.md`.
- **Four logged floor drifts (`F14`, `F15`, `F30`, `F206`):** Four places where an older title or description diverged from the current room geometry are flagged on their Atlas cards, waiting for deliberate scene or frame updates once shared placement files settle.

## How we continue

Now that the map is complete and honest, the work shifts from filling boxes to putting bodies back in the rooms:

1. **First Quest 3 human-witnessed run (`0 VR` → live headset receipts):** Build a fresh Quest 3 APK with the Dual Breadcrumb HUD (`4c1fbcbdb`) and walk the ten Ghost Student Spine stops plus floor 71's Sky Stairs in VR — testing head-height readability, whether the plain line clarifies or crowds the song, and how the spiral stair feels under real movement.
2. **Repair the four audited drifts (`F14`, `F15`, `F30`, `F206`):** Re-bind the drifted encounter frames or update the titles on Transformation (`F14–F15`), Colour Salon (`F30`), and Speculative Computation (`F206`) once concurrent edits to `opera_frame_placements.json` and `trajectory_outline.json` are committed.
3. **Write `void.md` where machines cross floors:** Expand Model B's living book along the highest-leverage desiring-machine seams — `F7` (`prefab_belt`), the `F34 -> F65 -> F69` spray drone arc, the `F186–F190` paradox frames, and `F206–F207` (path versus destination).
4. **Keep committing by subsystem:** Continue landing small, scoped commits across active sessions so parallel work on voice, placements, and rooms never collides.

[Open the Void Tower System Atlas](/tower-atlas) · [Read the Ghost Student Spine](/ghost-student) · [Browse the Desiring-Machine Timeline](/desire-timeline) · [Check the Agent Forum](/forum)
