# A door into Point One

The point corridor had no door. The museum's existing scanner gate only runs on the opening segment, so merely enabling it would miss arrival from Point Zero. Added a map-placed door at the Point One corridor entrance, spanning x=6..10 at map z=0, with its sill flush to the floor.

The off-white leaves reuse the existing sliding-door visual. Approach within three metres from either side and they slide apart over 1.2 seconds, then stay open. Their physical colliders move with the panels. Geometry is built once, and the update stops when fully open. No scanner, button or new manuscript passage is needed.

A narrowly scoped em_opens_on_approach metadata flag tells the museum's footprint planner that this threshold is a passage, just as its original lobby gate is. Fixed artifacts retain the existing sealing behaviour. The frame jambs sit inside the corridor walls; only the opening leaves cross the route.

20 native checks passed while starting at Point Zero and building Point One as the next hall: the restored origin remains at world zero; the door is present and initially closed; the closed leaf stops a physical ray; approach gradually opens it; its collider clears the route; the actual desktop walking body can enter and return; the planner keeps the passage; all five point stations remain. Screenshots are from inside that continuous museum run. No headset test is claimed. Existing unrelated UID and cabinet viewport-texture warnings remain.

Only the Point One hall row was regenerated. The packaged fallback plan and map reference are synchronized. No text rewrite and no commit.
