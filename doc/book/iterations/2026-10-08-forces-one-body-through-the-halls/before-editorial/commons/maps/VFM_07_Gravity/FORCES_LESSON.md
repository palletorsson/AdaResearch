# Let both points answer

Primary: `force_play_mutual`.

Return to two instances of the same physical point. Give them opposite initial velocities, then calculate one force from the displacement between them. Apply it to one body and its negative to the other. Contacts and uniform gravity are off for this isolated pair.

Carry: Two bodies can interact while passing through one another. Support adds a different relation: a surface that prevents penetration.

Check: Double only a.mass while keeping the initial velocities. The shared force doubles. The acceleration of a stays the same, while b’s acceleration doubles. Predict both responses before running. Set both positions equal to check that softening returns a finite zero vector.
