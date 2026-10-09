# Late Color: preserve the encounters, repair the walking order

Local audit, 19 September 2026. Scope: Color_Paint, Color_Walls and Chamber_Color. The frozen 18 September review and source packages were not edited. This pass follows `doc/book/REVIEW_PRINCIPLES.md`.

## Decisions

| Hall | Maturity and decision | What was verified or repaired |
|---|---|---|
| Color_Paint | Preserve the two primary encounters and the complete chapter. A beginner-facing clock experiment remains a focused development opportunity. | The wet shader exists locally. Fresh rendered museum checks exercise held-ball rays, receiver retargeting, rectangular UV mapping, simultaneous automation, release and retained GPU pigment. |
| Color_Walls | Targeted spatial correction; preserve the chapter and all six placed artifacts. | Move the two colour-coordinate/interpolation benches beyond the office so the room can support the book's order: partition, coordinate, path. Correct stale map documentation and misleading source comments. |
| Chamber_Color | Preserve the chapter and supporting receiver. | The dynamically loaded projectile and secondary target exist. Fresh physical shots verify tint, nearby visual deformation, unchanged floor collision, cooldown, disappearance and return. |

## Color_Paint: an absent source in the ZIP was not an absent capability

**Passage and purpose.** “Both routes reach the same drawing operation.” Manual action enters an image that already has a machine at work; a gesture can leave a trace without remaining recoverable as a separate object. “Even their clocks differ” returns to Trace and Disco with a changed receiver: the image persists and fades.

**Current ecology.** `ball_painting_demo` and `albers_wall_gallery` are already primary; `dark_sphere` is decoration. The Albers return lets a stable surround compare with a neighbour that keeps arriving. There is no reason to reduce the hall to one artifact. No scene or final.md change was made here.

**SOURCE.** The review's missing source is `algorithms/color/drawing/wet_paint_simulation.gdshader`, reached through `commons/context/drawingboard/wet_paint_canvas.tscn` and `paper_draw_surface.gd`. Its five samples, vertical shift and constant per-frame dissipation agree with the manuscript's bounded implementation claim. The automatic brush accumulates delta in `ball_painting_automation.gd`. This is not a physical pigment model.

**RUNTIME TEST.** `verified/probe_paint_encounter.json`: 27 checks, zero failures, actual museum under Vulkan/mobile. A supplied grabber moves a real pickable ball, real rays hit the drawing area, a deliberately wrong cached receiver is replaced, automatic strokes continue, release stops manual writing and returns the ball to the tray. The actual GPU image retains red pigment after release. A capsule can approach the tray and the viewing ray is unobstructed. `verified/paint_encounter_museum.png` is current-state evidence, not a fabricated before/after repair.

**Open.** This test does not measure fading at two controlled rendering rates, and the live artifact has no beginner-facing comparison that separates those clocks. Preserve the claim and record a future encounter-development task: a reversible comparison that holds brush elapsed time while exposing a different number of surface updates. Do not label that proposed control as implemented or dilute the whole argument because it is not yet there.

## Color_Walls: the strong paragraph needed a different placement

**Passage and purpose.** “You have been walking through an arrangement of coloured space. These models arrange colour values in space.” That pivot needs the cubicles before the small models. “The agreement about where to begin and end did not decide how to travel” then returns Transformation through interpolation.

**Before.** All three intended primaries were present and functional. `commons/data/artifact_roles.json` orders office, navigator, interpolator. The book and tutorial have the same order. The map instead placed navigator and interpolator at `(18,10)` and `(28,10)`, ahead of the office centred at `(23,20)`. Its entrance console and open aisle face the low-z approach. The actual straight museum segment spans z=-4 to z=42; baseline captures show the models in front of the office. This was a placement mismatch, not a reason to rewrite the chapter.

**Repair.** Move the two existing tokens to `(18,31)` and `(28,31)`, preserving yaw, size, height and all configuration. Keep the office where it stands. Extend its sculpture-clear rectangle from z29 to z34 so generated ornament does not occupy the new comparison approaches. Leave the rainbow hallway, subpixel display and dark sphere present in their current secondary/decorative roles. Correct the stale map documentation that still described a 12-by-30 Gradient Hall and an old rainbow terminus.

**SOURCE cleanup.** The navigator header incorrectly advertised body-scale navigation, every achievable colour and an HSL model. It now describes the actual finite tabletop RGB/HSV models. HSL identifiers remain for scene/config compatibility; comments explain what the implementation does. The office header now describes the cubicle configuration and distinguishes its glass/opaque comparison from the legacy angled installation. No executable line in either artifact script changed; see `source-verification.json`.

**RUNTIME TEST.** Baseline 52/52 checks; after 59/59. The unchanged checks cover all eight entrances in both visibility modes, pane blocking, exact collider identity, actual button signals, standing control height, 500+500 samples and RGB coordinate agreement. Seven new checks establish both models are beyond the full office footprint and sweep a 0.64 m-wide capsule along six routes: leave the office, reach either comparison, continue between them, turn and leave through the far museum exit. All six cast fractions are [1,1]. The hall still permits exploration; this is a viable ordered route, not a claim that every visitor is forced to follow it.

**CAPTURE.** `before/Color_Walls-overview.png` and `after/Color_Walls-overview.png` use the same actual Godot museum camera. Companion `Color_Walls-entrance.png` views use a standing approach. Dynamic background sculptures differ between runs; their change is not attributed to this repair. Glass/opaque comparison captures remain under both phases. These are desktop renders; headset readability and comfort remain open.

## Chamber_Color: verify the receiver, keep the argument

**Passage and purpose.** “Now it arrives as a message, and the receiver decides what to do with it.” Colour no longer simply changes a material: one impact invokes separate tint and geometry calculations. The unchanged collision deliberately returns the earlier difference between an invitation to look and an invitation to enter, now underfoot.

**Current ecology.** `becoming_catalyst` is primary. `catalyst_target` is a secondary but essential receiver of that same encounter. `science_screen` and `proximity_spawner` remain supporting works. Promoting the target merely to satisfy a bundle filter is unnecessary; include its implementation in future reviews. No scene or final.md change was made here.

**SOURCE.** The mounted lesson uses `commons/hazards/becoming_catalyst/chromatic_study.gd`, `modes/mode_chromatic.gd`, `modes/chromatic_projectile.gd`, the projectile base and `catalyst_target.gd`. These files establish the native shot, target callback, neighbourhood calculation and reset. The original review correctly treated omitted receiver files as uncertainty, not proof of broken behavior.

**RUNTIME TEST.** `verified/probe_chamber_colour.json`: 32 checks, zero failures, actual museum. A real mounted button pointer event launches a physical projectile; cooldown rejects an immediate repeat; one contact counts once. In this seeded run two nearby grid instances change colour and render transform while static collision transforms remain fixed. Three distinct shots remove the target; the instrument waits while absent; the target returns with collision and a fresh count. Button/hand-pose areas survive the museum disarm pass and a capsule can reach the changed floor. `verified/chamber_colour_before.png` / `chamber_colour_after.png` compare before and after a shot in the same existing encounter, not before and after a code repair.

## Verification scope and remaining limits

- Current unique post-decision checks: **118 passed** = Walls59 + Paint27 + Chamber32. The additional Walls52 baseline checks are not counted again as new coverage.
- All three `final.md` files are byte-identical to this pass's snapshots.
- Before source snapshots, scoped unified diffs, commands, owned process IDs, timings, engine logs and JSON results are retained under this directory.
- All four launched Godot processes exited zero. No GDScript errors occurred. Logs retain known UID/certificate errors, registry warnings and unsupported mobile-renderer feature warnings. There are also renderer `_save_to_cache` file-open errors; rendering still produced inspected images and the paint GPU checks passed. This is therefore not a claim that the complete engine log is clean.
- Rendered mobile desktop evidence is not Quest performance, tracked-hand reach, a novice's comprehension or a continuous unassisted walk. Those remain separate checks.
- The future Paint clock comparison is an explicit development task. No unimplemented control is being promised as present.
