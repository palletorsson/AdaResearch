# One impact, then the world

Primary: `force_play_bowling`.

Use the same point twice for the smallest collision. One is the striker; one receives it. Apply an impulse once, then let the physics engine handle their contact. This first reconstruction is a gravity-free horizontal collision, before the lane adds floor friction, rolling and pin shapes.

Carry: Force was sustained; impulse happened once. In the last hall, holding a trigger sustains an acceleration request to the player body.

Check: Double the striker’s mass while keeping the impulse. Its initial speed should halve. Predict that speed separately from what the collision will do. Then compare the actual collision rather than assuming ten pins must always fall.
