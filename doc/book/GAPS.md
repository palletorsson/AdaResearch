# GAPS — the authoring backlog the baselines surfaced

> R-025's cross-chapter findings, made into a punch-list. 29 weak/missing beats
> across 22 chapters. These are not casting errors — they are places the map
> inventory genuinely lacks the artifact a sound tutorial needs. Ranked by
> leverage (how many beats one fix closes).

## A · The exit-test family — 11 beats, ONE fix (highest leverage)

Almost every chapter's **"prove it"** beat is weak: the sequence has no snap /
match / puzzle artifact to close the lesson. Only primitives, array_tutorial,
randomness, forces, qfeplaboratory ship a real exit test.

Weak "prove it": change, isosurfaces, wavefunctions, noise, cellularautomata,
fractals, lsystems, proceduralgeneration, softbodies, graphtheory,
foundationscrisis.

**One parametric artifact closes all 11** — a `concept_exit_test` that takes a
target (a pose, a value, a pattern, a graph) and a player attempt, and reads
pass/fail. Configured per chapter via `apply_grid_config`. This is the single
highest-leverage authoring job in the book. *(Content, not a book tool — needs
Palle's greenlight; it's a real new artifact family.)*

## B · Artifacts in the wrong sequence's inventory — recastable by moving

The right artifact EXISTS but lives in another sequence's maps, so the chapter
can't cast it:
- **noise** "the flow field" + "steer with the field" → the flow artifacts
  (`noc_5_04_flow_field`, `flow_field_painter`, `curl_noise_particles`) sit in
  **forces / randomness**. Fix: place one in a noise map, or let baselines cast
  cross-sequence.
- **foundationscrisis** "the halting problem" → `halting_bench` /
  `halting_workbench` live in **forces / foundations**, not this sequence.
- **softbodies** spring atoms (`mass_spring_damper`, `spring_network`) live in
  **forces** (cast worked around it via `jelly_cube`).

Decision for Palle: allow **cross-sequence casting** in the baseline (an artifact
can be borrowed if it's the right teacher) OR place copies in-sequence.

## C · Missing teaching primitives — needs a new small artifact

The concept has only whole-simulation sculptures, no atomic teaching piece:
- **cellularautomata**: the cell (on/off), the neighborhood, one rule one step —
  all cast from whole-sim stand-ins. Needs a single-cell / neighborhood primitive.
- **proceduralgeneration**: the tile set, adjacency, **WFC-proper** — no actual
  wave-function-collapse artifact exists; `maze_generation` stands in.
- **noise** "smooth it — value noise": no value-noise piece (only Perlin/simplex).
- **transformation** dot product / cross product: no dedicated projection or
  perpendicular artifact.
- **lsystems** stochastic rules; **swarmintelligence** alignment (isolated);
  **machinelearning** overfitting — each lacks an isolating primitive.

## D · Genuinely missing pearl

- **boolean_surfaces** "two solids": no pre-operation two-solids artifact; chapter
  is known-thin. Lowest priority (the chapter honestly shows uncast).

---

## The one recommendation

Build the **`concept_exit_test`** parametric artifact (Category A). It closes 11
weak beats — more than a third of the backlog — with one artifact, and it gives
every chapter the "prove it" that makes a tutorial a tutorial. Everything else in
B/C/D is per-chapter and lower-leverage. Greenlight it and the spine goes from
21/22 baseline-met to genuinely-sound across the board.
