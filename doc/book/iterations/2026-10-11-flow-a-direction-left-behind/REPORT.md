# Leave a direction

Endless Museum · Flow Fields · 11 October 2026

The point gains another use. In Physarum it left a deposit that the colony could change. Here your hand writes **directions**. The existing bodies read them, and the arrows remain after you release the point.

## Try it in the museum

Reload **Swarm Intelligence → Flow Fields**. Take the black point at the front-right of the table. Hold the trigger and move it above the smaller surface. A gold cursor locates your hand in both views. Move to write; holding still does not invent a direction. Release the trigger and watch the bodies respond.

The buttons to the left pause/play, reset the directions, and switch between Draw and the original Tour. Drawing still works while paused. Reset keeps the bodies and their current positions. Returning from Tour to Draw clears the edits. Dropping the point returns it after three seconds, keeping your field. Desktop uses the existing carry/drop and action controls.

## What returns, what changes

The original FlowFieldMain scene, FlowGrid and 200 FlowAgent bodies run inside the existing table host. A new host adds the familiar PointBody, a smaller view, nearby controls and cylinder arrows. Both surfaces share one running simulation. The agent code, steering, collisions and boundary response are unchanged. The existing walk-in crowd is still present in the adjoining court.

Draw begins with one rightward field. A stroke replaces the directions in a bounded strip of cells. The hand is now an additional author of the field. Agents read these instructions; they do not deposit, diffuse or erase them. The original Tour still visits its six scenarios and ends in animated noise.

This gives a concrete comparison across the halls: **a deposit sensed by agents → a direction supplied to agents → neighbours sensed by agents**. These can produce similar-looking collective movement while using different information. This optional encounter strengthens that distinction. The agreed tutorial objects, all fourteen canonical texts and the sequence order remain unchanged.

## The room

The table stays at cell (4, 2) and turns to face the room. The point dock moves to the front-right; controls sit on the left, clear of the existing ramp. A local exclusion rectangle limits automatic sculptures near the table. Room dimensions, utility cells, other artifact placements and all other museum-plan rows are preserved.

The overhead image also reveals an existing room problem: an oversized AntColonyV2 footprint and other exhibits extend beyond their intended space. The current run reports entry/exit fallback warnings also present in the earlier crowd run. The tested table approaches have floor support and capsule clearance; this does not certify the complete hall route. That spatial cleanup remains open.

## What was tested

**48/48 checks passed**: 27 production-scene checks and 21 checks in the actual museum. They cover original resource reuse, shared views, private simulation visuals and physics, camera/input agreement, transformed hosts, held-action gating, stationary input, brush bounds, interrupted strokes, direction and colour, agent response, pause, reset, release, return and standing access.

The native run injected a desktop pickup and stroke into the actual PointBody. It edited 212 cells. All 200 bodies moved after resume, while the edited vectors stayed intact. A separate controlled check verifies the original agent turns along an edited vector. The seven images are native Godot captures, with pauses for comparison; they are not a recorded headset session.

All 33 recorded original source/text hashes match. Final runs contain no script or shader errors. Existing UID, Jolt and renderer-feature warnings remain in the logs. Physical headset interaction and Quest performance have not been tested.

## Repairs during the pass

The first access check found the ramp beside the buttons. The controls were moved and the checks repeated. An initially reused filename also collided with the older Change-sequence flow_field_painter. Its two files were restored byte-for-byte from the archived source, verified against HEAD with newline normalization. This encounter now has the distinct flow_direction_table name and registry entry.
