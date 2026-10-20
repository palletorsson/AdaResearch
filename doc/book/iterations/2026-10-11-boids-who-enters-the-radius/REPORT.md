# Who enters the radius?

Endless Museum · Boids · 11 October 2026

The familiar point now changes who counts as a neighbour. The original thirty-body FlockingControls exhibit has moved into a clear bay, with a visible radius, links to the selected neighbours and four arrows showing the requests for one body.

## Try it in the museum

Enter **Swarm Intelligence → Boids**. The table is near the north entrance, on the right. Pick up the black point from its left stand. Press its trigger to pause, then move your hand left or right. The bodies stay where they are while the gold radius contracts or expands. Watch the neighbour count and the requests change. Press again to let the same bodies continue.

The nearby right button also pauses and plays. The original separation, alignment, cohesion, speed and radius sliders remain accessible at the front. Dropping the point returns it to its stand after 1.5 seconds; your chosen radius stays. Reset makes a new random scatter.

## What this comparison makes visible

In the captured comparison, a radius of 0.05 m includes **0 neighbours** and 0.5 m includes **10**. Positions and velocities are identical in both photographs. The changing count comes entirely from the inclusion radius. This particular count is a recorded example, not a fixed result for every run.

Red shows separation, blue alignment, green cohesion, and white their sum. These are the next weighted steering requests for the gold body, before the original speed limits. Arrow lengths are compressed to fit the table; the labels give full magnitudes. Setting the original separation slider to zero removes that request without moving the paused bodies.

Flow Fields supplied a direction at each location. Here the other bodies help determine the next request, but only if they enter the chosen radius. In the next hall, Agent-Based Modelling, we ask what the individual point carries as its own state. The point remains our means of intervening in the example; it is not added to the flock as another neighbour.

## Space and continuity

- Moved FlockingControls from cell (10, 9) to (9, 3), with a solid table and two nearby hand controls. Its original scene remains inside the new adapter.
- Cleared two interior posts and aligned entry/exit with the north/south openings. Kept the 28 × 13 hall dimensions, west observation balcony and east drone court.
- Kept the open hundred-body flock, seventy-two-fish school, aquarium, film, 2D panel, science display and drone comparison. The route to the balcony passes around the existing 2D panel.
- Preserved all fourteen canonical swarm tutorial/reflection texts, the sequence order, the PointBody class and the original simulation sources. Only this hall's row of the museum plan changed.

The printed tutorial remains the small snapshot/fixed-step study already written. This optional exhibit runs the original sequential, frame-driven FlockingControls model. Their implementation differences remain explicit.

## Checks and limits

**76/76 automated checks passed:** 30 production-code checks, 34 installed-museum checks and 12 portal checks.

The adapter and an unwrapped original produced exactly matching positions and velocities over 300 varying time steps. Additional checks compare the preview with the original body's next calculation, verify rendered link endpoints, and exercise pause/resume, old sliders, drop/return and supplied desktop/XR near-grab inputs.

The museum probe sampled 322 positions along five routes for floor support and standing-capsule clearance. A native paused comparison verified that radius changes preserve every position and velocity, while the visible rings, links and arrows match the calculation. The portal coordinator completed Boids → Agent-Based Modelling → Boids using supplied crossing requests, with supported arrivals and one resident hall.

All 47 recorded source/text hashes match. The publisher also checks the exact intended map and plan changes. Final runs contain no script or shader errors. The logs retain UID, renderer and Jolt warnings/errors; the portal run also reports viewport-texture errors during loading. These remain outside this exhibit's checks. Physical headset interaction and Quest performance have not been tested.

The first attempts revealed an inherited panel hidden by the new table and a balcony test route running through the old 2D panel. Raising the control panel and routing around the existing exhibit resolved those checks. The report uses the final native captures.

## Photographs

Room and overhead before/after views use the same cameras in the real Godot museum. Control close-ups use the same view relative to the exhibit, which has moved. Running simulation states differ; the narrow/wide pair specifically keeps the same paused state. These are engine captures, not illustrated proposals.
