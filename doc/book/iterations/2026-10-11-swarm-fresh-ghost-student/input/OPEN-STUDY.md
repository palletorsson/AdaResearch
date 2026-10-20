# Open study — a good score, a scattered group

This optional investigation follows the seven Swarm lessons. Work inside the prepared Endless Museum with the complete Particle Swarm tutorial and its carried PointBody. No new agent or exhibit is required. The brief does not prescribe an outcome. A [ghost-student rehearsal](prior-investigation/REPORT.md) records one completed comparison; make your prediction before reading its results.

**Question:** on RIDGE, does weaker shared attraction preserve a more dispersed group? What happens to its scores? A diagonal can permit many equally good positions without the moving population occupying them all.

Before running, write your hypothesis and choose one additional `social_pull` value to compare with the printed default, `1.5`. Change that variable in your lesson's `swarm.gd`; keep the personal pull, inertia, population, boundaries and seed unchanged. Do not edit the museum's production artifact. This extends the lesson's tested single-step variation into an investigation of later behaviour.

For each version, start the host paused, select RIDGE, then RESTART. Restart retains the objective and coefficients, restores seed `101006`, and rebuilds positions, velocities and memories. Compare the same step counts: 0, 20 and 100. Use ONE STEP for exact counts. Keep your hands off the points during these runs: holding would pause the model and alter a position or velocity.

At each count, save a view from the same position. Record the shared best score and inspect the same three points, using the already printed `score()` and `positions` records. For a numerical measure of spread, record the largest pairwise distance between current positions; your earlier distance calculation and nested loop are enough. State that choice before looking at the result. Distance measures spread, not fairness or the number of distinct solutions. A single good shared score also says little about the other points' current scores.

Repeat each run from RESTART to check reproducibility. Then, if useful, change the seed in `reset()` and run both versions with that same second seed. Repeating one seed is a check of the setup; a second seed asks whether the observation depends on that starting population. Neither establishes a general guarantee.

Keep a short record: **hypothesis → what changed → what stayed fixed → step counts and evidence → observation → revised question**. Include results that contradict the prediction. If the pictures look different but the measured spread does not, investigate the discrepancy rather than selecting the picture you prefer.

Combining Boids with a depositing field is another possible study. It requires a new model, explicit update order and new reconstruction checks. It remains a proposal, not part of the tested seven lessons.
