# What lets the cube stay up?

Primary: `force_play_support`.

Bring back the cube from Primitives. This small first reconstruction uses one box resting on one support. The mesh and collider share dimensions. REMOVE SUPPORT moves the supporting body sideways and wakes the load. Let the physics engine supply the result before building the full table.

Carry: A contact can maintain rest or change motion during an impact. The bowling point returns for the second case.

Check: Move the support only 0.1 m instead of 1.5 m and restart. Enough overlap should remain to hold the centred cube. Then use the larger displacement and compare. Keep body dimensions and gravity fixed.
