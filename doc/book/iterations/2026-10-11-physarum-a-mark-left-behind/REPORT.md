# A mark left behind

Endless Museum · 11 October 2026

The yellow Physarum colony now has a six-metre wall view and a hand surface. The original 2.8 m table is still present. All three show one running colony: 300 original agents, one field, one history.

## Try it

Reload **Swarm Intelligence → Physarum Colony** and enter the new east opening. Take the black point beside the smaller surface. Hold the trigger and move it above the surface to draw. A cyan ring shows where your mark will land. Release the trigger and watch the colony continue working on what you left.

The nearby buttons pause/play the colony or restart it. You can draw while paused. Desktop uses the existing right-click carry/drop and left-click action. The point returns to its dock three seconds after you drop it.

## What we kept, what we added

This reuses the existing `physarum_museum` exhibit and its original colony, agent, grid and shader. Its private 50 m simulation is viewed through the original camera, so enlarging the picture does not enlarge its physics. The original anchors still change every 20 simulation seconds. There is no hidden warmup and no automatic reset.

The new operation is a **hand deposit into the same field the agents sense**. Carrying alone does not write. Holding action above the surface deposits a bounded brush, with continuous segments between accepted positions. Moving outside the surface ends the segment; returning does not draw a bridge across the gap. A screen border corresponding to space outside the original simulation is excluded.

The agents' sensing, movement and deposition rules are unchanged. Their environment changes because your hand has added a trace. What happens afterward depends on the existing state and those rules; a visible mark need not persist or become a route. This is a Physarum-inspired model, a related trace mechanism rather than another ant simulation.

## Place in the sequence

Point → hand movement → trace → a field other bodies read. The carried point returns with another ability: it leaves something that keeps acting after the hand stops. The distinction is visible in the room without requiring a new primary tutorial. The seven canonical `tutorial.md` and `final.md` pairs are unchanged.

The hall expands from 13 × 11 to 28 × 11 cells. The old table moves into this new host, leaving only one Physarum colony running. A three-cell east opening gives standing access to the table and controls. All other saved artifact and utility cells remain as before; other museum-plan rows are unchanged.

## What the images show

These are actual Godot museum captures. The colony developed for 32.16 elapsed seconds before being paused for the first photographs. A scripted desktop pickup and action then moved the actual PointBody in a loop above the pad. That gesture made 466 brush deposits, including interpolation. After release, the colony ran for eight more seconds. Pauses keep the before/drawing comparisons legible; normal play does not insert them automatically.

The gestures are test inputs, not a recording of a person's hand. The images establish what rendered in this run, not a guaranteed final pattern.

## Checks and limits

**46/46 checks passed:** 27 production-scene checks and 19 museum checks. They cover shared state, the original resources, camera/input agreement in all quadrants, a translated and rotated host, held-action gating, brush size and cap, continuous strokes, leaving/re-entering, pause and restart, release and return, original simulation advancement, floor support and standing access.

All 29 recorded source/text hashes match their before-state. No script or shader errors occurred in the final runs. Existing UID/Jolt and museum warnings remain in the retained logs. The south sequence exit still reports a fallback warning also present in the earlier artifact-inventory run; this work does not establish portal traversal. Physical headset use and Quest performance remain untested.

The first native views exposed an oversized status label in front of the controls. It was reduced and moved behind them, then the complete checks and museum run were repeated.
