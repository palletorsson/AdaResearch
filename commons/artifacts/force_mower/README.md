# Force mower — flower garden

The museum placement in VFM_03_Motion uses `lesson:flower_garden#lawn_width:20#lawn_length:28`, yaw 270°. The original diagram is retained for other placements.

Grip the pink handle, push it forward, and move the hand left/right to steer. Walk with the mower. Releasing the grip removes the drive; drag gradually slows the mower. The button next to the grip resets the mower and whole lawn after release. Desktop: RMB carry/drop the pink handle, walk and move the mouse to guide it; wheel changes reach.

The tracked handle is a target for a model force, not a measurement of muscular effort. A 14 kg Jolt rigid body stays in a horizontal plane, with a 100 N/m virtual push spring capped at 65 N, longitudinal drag 13 N/(m/s), additional lateral resistance, and damped yaw torque. The mower collides with the visible lawn boundary. Work sums the applied model push dotted with the resulting displacement. Drag is a separate force; the work display is not net kinetic-energy change.

The 20 × 28 m stationary lawn has 3,922 cells and 11,766 instanced blades. Cutting shortens blades; every third cut cell grows a flower. Repeated passes do not create duplicates. Three MultiMesh batches hold grass, stems and heads; counts remain bounded. Flowers last until reset or hall unload. The main point-sphere comparison remains the hall's tutorial anchor.

Verification: `tools/probes/flower_mower.gd` tests actual rigid motion, XRTools pickup, desktop hand events, right/left steering, release drag, bounded flowers, reset and cleanup. `tools/probes/flower_mower_museum.gd` tests the real museum placement and route, then supplies hand poses to drive the actual mower for captures. Headset ergonomics and Quest frame time remain untested.
