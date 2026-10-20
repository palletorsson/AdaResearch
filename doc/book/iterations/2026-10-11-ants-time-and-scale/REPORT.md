# One pattern, three sizes

Endless Museum · 11 October 2026

Fourteen existing simulations ran for **about 90 seconds each**, with photographs requested at 5, 30 and 90 seconds. The clearest contrasting effects were the coloured turmite surface and the concentrating pheromone trail. Both appear in a comparison court beside the existing colony lesson. **Ant Colony V2 is now the third selectable model**, with a fresh 90-second museum run and clearer trail colours.

## Try it in the museum

Reload **Swarm Intelligence → Ant Colony Optimization**. From the original sphere-and-trail field, enter the new east opening. Three sizes show one live state:

- **45 cm:** take the tile by its black point. Trigger pauses or continues the pattern. It returns to its dock five seconds after release.
- **1.8 m:** lean over the table and follow an individual ant.
- **8 m:** walk across the same pattern at room scale.

The nearby buttons select **Trails**, **Turmites** or **Ant Colony V2**, pause/play, and restart the selected model. Each model keeps its history when you switch away. There is no automatic reset. Desktop uses the existing right-click carry/drop and left-click action.

## What changed

The two original simulation scripts still provide their own movement and cell-update rules. A new host gives them visible ant bodies, a clearer field palette, shared displays and the existing grabbable PointBody. The turmite view keeps the original 900-step warm start; a fixed seed makes its reset repeatable. The pheromone view begins empty and develops while you watch.

V2 runs its original scene once in a private physics world: 100 original SimpleAnt bodies, a 256 × 256 pheromone grid and the original food/home detectors. The 50 m simulation supplies all three smaller displays without rescaling its physics. Cyan shows home trails, rose shows food trails. Gold ants forage; pink ants are returning. This comparison uses a flat, dark, unlit field in place of the original terrain shading, avoiding the glare seen in the isolated capture. This is a new presentation of the original state, with no change to its movement or deposit rules. No fast-forward or hidden warmup is applied.

The main tutorial remains **Two trails underfoot**, with its carried spheres and separate home/food channels. This optional comparison court does not replace it or turn every display into a new lesson. Existing tutorial.md and final.md files remain unchanged.

The hall grows from 17 × 17 to 33 × 17 cells. Its north/south sequence passages and existing lesson position remain. A three-cell east opening leads into the new court. Automatic sculpture placement is excluded from the field and approach, after an overhead inspection exposed obstructions there.

## What the longer runs showed

More time does not always mean a richer image. In the pheromone-grid run, several branches condensed into one dominant route. The turmite surface kept a varied coloured pattern. The carried Langton toy visibly filled more of its surface. The yellow Physarum example made strong branches and loops; it stays in its own hall as a related mechanism.

These are selection observations from one run per scene, not a performance ranking. Original scene defaults and warm starts differ; some isolated scenes supply their own cameras or lighting. The old isolated V2 capture remains overexposed; the new museum views correct the display contrast. The optimization preview is too distant for detailed assessment. The original gallery remains linked for additional views. Individual ant components were not treated as independent simulations.

## Evidence

**70/70 checks passed:** 34 code/display checks and 36 museum checks. The original trail engine and adapter match after 180 steps; the turmite state matches after its warmup and another 100 steps. Checks also cover shared state at all sizes, rendering without data mutation, preserving histories across selections, pause/resume, explicit reset, pickup/action/drop and return to the dock.

Native museum checks cover floor support, standing clearance along the approach and across the field, access to controls, hand height, live simulation advancement and thirteen real captures. V2 checks also cover isolation from museum collisions, its original food/home Area3D transitions, shared 100-agent views, pause and history preservation. In the 90-second museum run, ants reached food through their own movement. The receipt records wall time and actual physics ticks separately; this is not a 90 Hz headset performance test. The ant bodies are visual instances with static legs, not physical insects. Walking through them does not steer them.

The 90-second comparisons use real elapsed time at normal engine speed. They are not equal-step experiments or recorded continuous video. Select any of the three stills, labelled with their requested times; each card also lists actual elapsed times. Two malformed JSON envelopes were repaired around surviving measurements and checked against their logs; originals are retained in evidence/receipt-repairs.json. No script/shader errors occurred in the passing runs; pre-existing engine warnings remain in the logs. Physical headset use and Quest performance remain untested.
