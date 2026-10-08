# Somewhere to start

A paired rail exhibit for Random_Walk. One seeded random number drives two rules: fresh absolute position, and a bounded increment from the previous position.

Scene: `random_position_rails.tscn`. Registry key: `random_position_rails`. Placement: Random_Walk (13,8), yaw 180 degrees.

- NEXT: native lever; one draw per pull, busy draws refused.
- White marker: native grab slider / desktop pointer. Prediction only; does not affect the random stream.
- RUN / HOLD: repeat every 2.8 seconds / finish current movement and stop future draws.
- REPLAY: restore seed 79, two centres, empty twelve-pair record, marker centre.

Targets are exposed for 0.65 seconds before a matched 1-second cubic animation. Both have equal interpolation weights, not equal speed. Pink folds a proposed endpoint at the rail ends. Carriages are visual, not rideable physics bodies. The frame and supports have fixed collision.

Review, preserved text, actual museum photographs and reproducible tests:
`doc/book/iterations/2026-09-24-random-walk-rails/index.html`

Pending: headset grip/reach/comfort, reader and learner observations.
