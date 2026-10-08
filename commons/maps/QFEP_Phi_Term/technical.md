# A signed control before its interpretation

The Lambda hall separated a recommendation from its surroundings. Here the PHI rail separates sign, magnitude and the language used to interpret them. The museum uses the existing phi_slider with sign_study:on and starts at zero. Its original XR handle remains full size on a plinth, 1.1 metres above the floor.

The hall-specific feedback uses equal speeds at equal magnitudes, opposite vertical directions and no particle gravity. Zero stops new emission; already emitted particles may survive for their two-second lifetime. The original legacy feedback favoured upward motion and continued emitting at zero. Other placements retain that legacy behaviour.

```gdscript
phi = (position / rail_length) * 2.0 - 1.0
particle_mat.direction = Vector3.UP * signf(phi)
particle_mat.initial_velocity_min = absf(phi) * 0.20
particle_mat.initial_velocity_max = absf(phi) * 0.20
_particles.emitting = not is_zero_approx(phi)
```

NEGATIVE / ZERO / POSITIVE remain on an evenly marked rail. EARLIER LABELS / HIDE reveals or hides the old RESIST / EMBRACE interpretation on a backed sign. That button changes text only: it does not move PHI, alter the wave pattern, or choose a moral classification. Blue and pink, upward and downward remain authored choices, available to question.

The sign study does not join the global qfep_phi_controllers group. The transforming_pattern runs independently from its prescribed wave field; its 6 by 6 cells are enlarged to 0.15 metres for comparison. The preserved pattern, rigid sculpture, fluid form, lambda promenade and two existing secondary teleporter tokens remain placed. The map uses its authored placements, with four display plinths and level circulation.

The QFEP expression in the project documents is QFE = F - lambda E + phi Delta E. A signed weight is not a measurement of change. For Delta E=+0.5, phi=+1 adds +0.5 to the score, while phi=-1 adds -0.5. If the score is minimized, the first increases cost with F and E held fixed. Reversing Delta E reverses those contributions. Zero phi makes this contribution zero, not the world's change zero. This rail does not measure entropy or run an optimizer.

Delta E names a difference between specified observations. It becomes a rate only after division by the elapsed interval. An entropy claim also needs defined states, probabilities, units and normalization. The wave field supplies none of those through its animation alone.

The earlier technical and critical drafts are archived in design-proposals.md. They describe intended connections, not shipped behaviours. Headset operation and what readers learn remain distinct from the recorded desktop signal and route checks.
