# Let both points answer

Primary: `force_play_mutual`.

Return to two physical points. Give them opposite starting velocities. Calculate the attraction between them once, apply it to one body, and apply its negative to the other.

Carry: These points attract while passing through each other. Bring back collision to ask what lets one body support another.

Check: Double only `a.mass` and keep the starting velocities. Predict both responses: the shared force doubles; a’s acceleration stays the same because its mass also doubled; b’s acceleration doubles. Restart to compare.
