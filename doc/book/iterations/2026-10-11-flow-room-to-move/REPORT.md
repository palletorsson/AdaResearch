# Room to move

Endless Museum · Flow Fields · 11 October 2026

The hand-written field now has room around it. An oversized ant simulation is contained on a live table, the ecosystem has a low stand, and an open route joins the displays to the full-size crowd court.

## Walk the room

Enter through the north opening. The familiar point and drawing table remain on the west side. Draw a direction and watch the original bodies follow it. Across the room, the ant table gives a different account of a field: its travellers leave the trails that subsequent movement can read. Its pause/play button is at the front-right.

Continue through the east opening to the existing crowd court. Here the field is large enough to walk through. The original crowd, destination point and controls remain. The small ecosystem is an optional comparison on a stand near the south exit. Leave through that exit to Boids; the next hall asks who is near rather than supplying one common direction.

These are different relations between a body and its surroundings. Similar movement is a reason to compare their rules, not evidence that they use the same rule.

## Changes in the actual museum

- **Ant Colony V2:** replaced its oversized room placement with a 1.8 m live table at cell (9, 2). The original 100 ants still run on their 50 m terrain in a private physics world. Rendering their camera view at table size preserves that scale and their existing behaviour.
- **Ecosystem:** moved the unchanged scene to cell (2, 7) on an explicit 80 cm stand. The first attempt used a structural cell that became a full-height post; the native test caught it, and the final stand has clear access.
- **Circulation:** cleared four interior posts, kept the existing ramp, and limited automatic sculptures in the comparison room. The north entry and south exit now align with the existing wall openings. Dimensions and the east crowd court stay the same.
- **Continuity:** the carried point, direction-table code, crowd code, all fourteen canonical tutorial/reflection texts and the sequence order are unchanged. Only the Flow Fields row of the museum plan changed.

## Evidence

**63/63 checks passed:** 29 room/ant checks, 13 portal checks and 21 repeated point-interaction checks. The room probe sampled 245 positions across five routes for floor support and standing-capsule clearance. A real CharacterBody walked from entry to the table and exit with gravity enabled.

The portal coordinator completed Flow Fields → Boids → Flow Fields, with supported arrivals and one resident hall. These were supplied crossing requests. The point test used a supplied desktop pickup and stroke, then checked movement after release and retention of the written directions. The ant table advanced through actual physics ticks; pause/resume retained its state.

All 71 recorded source/text hashes match. The publisher checks the exact map and plan changes, including preservation of every other hall. No script or shader errors appear in the final runs. Existing UID, Jolt, renderer, loading-time and shutdown warnings remain in the evidence logs. Headset interaction and Quest performance have not been tested.

The before/after photographs use the same cameras in the native Godot museum. Simulation states differ because the systems are running. Reload **Swarm Intelligence → Flow Fields** to try the arrangement.
