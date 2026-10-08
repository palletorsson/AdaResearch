# Ask the field where you are

Primary: `force_play_vortex`.

Keep the moving point. Replace the fixed push with `sample()`, a function that reads its position and returns an acceleration. Combine an inward pull with a sideways turn.

Carry: This force reads position. The next one reads how fast, and in which direction, the point is moving.

Check: Change the point’s mass to 4 kg. With the same start and no contact, predict the same path: the requested force grows with mass. Restart, then set the sideways coefficient from 2.8 to zero. Watch what remains of the motion.
