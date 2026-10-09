# Arena: selection, state and collision

## arena_relation_lab

A full-scale station wraps the existing head_crab.gd controller using lesson_crab.gd. That subclass replaces only candidate selection and fallback target acquisition. It nominates this station's food and either a beacon or one actual museum-player node. The nearest visible candidate strictly within 6 m is eligible, excluding the inherited temporary ignore list. A strict less-than comparison means an exact distance tie retains the food candidate encountered first. No sight memory is used; stale targets are cleared on selection. This is explicitly different from the base crab's global candidate groups and brief sight memory.

Candidate distance uses 3D node positions; _sees uses the existing horizontal ray at floor + 0.20 m with collision mask 1. The screen is real query-blocking geometry. It can also block the visitor's route when present; passages remain at both ends. The displayed candidate line lies at a fixed display height and is not the ray itself.

Crab scale is 0.3, chase speed 0.8 m/s, patrol speed zero, path grid disabled. Existing whisker/shape-query avoidance and plant/swing gait remain. Movement writes position; this is not a RigidBody3D and does not model momentum transfer. The scoped crab cannot bite. Existing crabs and turret deeper in the hall retain their own behavior.

| Control | Action |
| --- | --- |
| RUN | Pause/resume this crab's controller, including the feeding timer. |
| RESET | Replace crab with an unfed instance, remove this station's food, pause; retain beacon, screen, visitor and reveal choices. |
| BEACON | Cycle centre, right, left target positions without resetting the animal. |
| VISITOR | Switch nominated target between beacon and actual museum player. |
| FOOD | Offer one native mushroom on the pink pad; no stacking, none after the stopping threshold. |
| SCREEN | Show/hide a 2.4 × 1.4 m collision screen and its sight obstruction. |
| PARTS | Reveal candidate, candidate line, distance, feeding timer and completed meals. |
| RULE | Expose selection scope, distance/sight geometry, lack of sight memory and the five-meal threshold. |

Food reuses SporeMushroom via lesson_food.gd. _plant removes global spider_bait membership; only this station's selector considers it. Walking pickup is disabled. begin_absorb, consume, eating animation and the meal count use the existing code. A meal begins within feed_reach=0.26 m measured horizontally and takes feed_time=2 seconds of controller updates. Once begun, feeding completes before selection resumes. The fifth completed meal calls _root, disables bite and both speeds. No branches are created and no policy is learned.

At absolute local X or Z greater than 5 m, the station pauses its crab. This is an observation bound, not a wall. RUN cannot resume a boundary exit until RESET. Food's short planting/consumption tweens are separate from pausing the crab.

## collision_carts

The existing scene and passage are retained. MASS RATIO maps 0..1 to striker mass 0.4..2.6; target mass is 1, incoming striker speed 1, target initially still. Analytic elastic 1D outcomes are vA=(mA-mB)/(mA+mB)*u and vB=2*mA/(mA+mB)*u. Upper/lower lanes show before/after. Both momentum and kinetic energy balance under those stated conditions. Arrows have a visibility threshold and a fixed length offset, so their drawn length is not a precision speed scale.

## Verification scope

The desktop probe runs in the actual museum and checks live pointer controls, selection/occlusion, autonomous arrival and feeding, timed consumption, five-meal state, reset, actual player nomination, observation boundary, approaches and the retained collision-carts model. It also tests conservation at three ratios independently of the displayed arrows. These do not certify every retained Arena artifact. Headset reach, legibility, comfort and sustained performance remain open.
