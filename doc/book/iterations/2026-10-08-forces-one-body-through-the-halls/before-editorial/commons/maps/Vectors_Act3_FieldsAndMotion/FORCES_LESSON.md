# Ask the field where you are

Primary: `force_play_vortex`.

Keep the moving point and its velocity. Replace the fixed force with a function of position. The function returns acceleration: an inward part and a sideways part. Multiply by mass before handing it to the rigid body.

Carry: The next force will read velocity rather than position. Carry the distinction between sampling a value and deciding how a body receives it.

Check: Set the point’s mass to 4 kg. With the same start and no contact, the path should stay the same because the requested force grows with mass. Then set the tangential coefficient to zero; predict the loss of the sideways contribution.
