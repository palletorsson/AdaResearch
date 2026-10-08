# When the push ends

Primary: `force_play_mass`.

Use three instances of the familiar point. Give each the same force for the same time and vary only mass. The supplied `free_point.gd` lets them move freely, with gravity and damping set to zero.

**Build:** create several instances of the inherited point, store them in an array and apply a timed force to each.

**Investigate:** predict how mass and push duration change velocity, then distinguish equal final speed from equal travelled distance.

Carried knowledge: The point class comes from [Lines](../Point_Lines/tutorial.md), pickup and local/world positions from [Coordinates](../Point_Coordinates/tutorial.md), and arrays, indices and loops from [Trace](../Point_Trace/tutorial.md). [Transformation](../Trans_Pre/tutorial.md) used elapsed time to place a body; [Launch](../VFM_05_Launch/tutorial.md) used initial velocity and a clock. Keep those constructions. Here the new operation is a force applied during physics updates.

Check: Replace the mass expression with `[1.0, 2.0, 8.0][i]`, and change the caption’s heading from `1 / 2 / 4 kg` to `1 / 2 / 8 kg`. Predict a speed change of 0.125 m/s for the third point. Restart to compare from rest, and keep your hands off while measuring. The body’s mass and the words describing it need to agree.

Construction: Keep the complete example above as your working reference. In a separate script extending `study.gd`, make two points: 1 kg and 2 kg. One button begins both pushes. Apply the same 1 N force to the first for one second and the second for two seconds. Keep an independent remaining-time value for each point. A two-entry array and the loop pattern above are enough. Reading `remaining[i]` gets that point’s clock; assigning `remaining[i] = ...` replaces the entry. Update each clock separately, keeping its index paired with the same point.

Before running, predict their speeds after one second and after both pushes have finished. Also predict whether equal final speed puts them at the same distance from their starting places. Show both speeds and distances from the starting positions in the caption. Keep each starting position before the run; the length of `point.position - start_position` measures distance from it in these straight, forward paths. This reuses the displacement from Lines. Keep one snapshot of both distances when both push clocks first reach zero; the spheres will keep moving while you read it. A boolean flag can record that the snapshot has been taken, and the next button press can clear that flag. Allow for a small difference from the ideal values at the physics-step boundary. Use a clear bay, no gravity or damping, and separate the points so they cannot collide during this comparison.

Check your result by waiting after both clocks reach zero: both points should retain their final velocities until another influence intervenes. Explain which instructions end the push and which settings permit the coasting. Then choose another mass and work out a duration that would give the same final speed. Your code and your prediction are both part of the exercise.

Carry: A push can end while its consequence continues. Next, choose the push from where the point is now.
