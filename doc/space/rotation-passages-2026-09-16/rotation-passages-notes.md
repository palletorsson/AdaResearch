# Rotation passages · 2026-09-16

The user reported falling off X and asked whether X/Z rotation could provide a useful passage. A bare blade crosses vertical during a half-turn; a fixed-pose crossing test did not establish a standing ride. Its collider also had no explicit rider support during motion.

Added one upright side-mounted endpoint deck per X/Z blade, retaining the centred8.4m blade and the original grid banks. X netdisplacement=(0,3,7)m; Z=(7,3,0)m. Position follows a half-circle with radial verticaloffset−1.5m and traveloffset−3.5m. The platform basis remains upright; a fixed bracket offset compensates the blade's thickness-adjusted axle. Both use the upper arc and reverse for the return. Twelve-second docking pauses and15deg/s rotation give twelve-second travel. Side mounting separates the standing rider from the blade sweep. Rails guard the two non-boarding sides.

Wall motion now runs on physics ticks at priority−110. The new rotation_rider_deck.gd detects feet over its top surface, applies only per-tick displacement, moves XR collision body and tracking origin together, and rebases its own ground contact to prevent double carry. Step-off/jump releases. Invalid freed riders are removed by index before typed calls, covering scene streaming cleanup.

Files: commons/artifacts/rotation_studies/wall_crossings.gd; rotation_rider_deck.gd; commons/maps/Trans_Rotation/final.md, tutorial.md, critical.md; commons/testing/probe_rotation_rides.gd; probe_rotation_turn_direction.gd. Map geometry and artifact count are unchanged.

53 actual-museum XR tests pass; 1,638 capsule poses along the two arcs are clear (1.8mheight,0.25mradius,centre+eightoffsets,91poses per arc). Max body error1.54mm, max cameraerror3.97mm; camera localpose/heading/up preserved. Test pace60deg/s and0.7secondholds. Static hall regression42/42; direction/centre regression9/9. No script errors in the final runtime checks.

Sources synchronized: core final hash, book captions, sequence/beats and runtime narration. Actual Godot museum screenshots accompany the review. Screenshots show held motion phases; the runtime tests exercise continuous motion.

Limits: physical headset comfort, tracking quality and human timing are unverified. The discrete capsule clearances supplement the complete moving-rig trials; they are not a proof for every possible body size or position. No gravity inversion or forced head rotation was added.
