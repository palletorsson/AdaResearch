# What lets the cube stay up?

Primary: `force_play_support`.

Bring back the cube from Primitives. Start with one box resting on one support. Move the support sideways and let the physics engine determine what happens to the load.

Carry: Contact can hold a body still. Next, let contact pass motion from one body to another.

Check: Change the support’s movement from 1.5 m to 0.1 m and restart. Predict that enough overlap will remain to support the centred cube. Then restore the larger movement. Keep the dimensions and gravity the same.
