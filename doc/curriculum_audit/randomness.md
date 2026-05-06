# Randomness — Curriculum Audit

**Sequence ID:** `randomness`
**Spine order:** ~7 (post-color, pre-wavefunctions)
**Maps:** 14 (13 content + 1 chamber)
**QFEP term:** E(S) — entropy as the irreducible residue of the F-model
**Evolutions written:** 0

## 1. Core Concept

Randomness in Ada is not error but freedom — the vital space where prediction fails and patterns emerge without blueprint. The sequence teaches four distinct registers that are currently tangled together: **definition** (what entropy/randomness *is*, axiomatically), **perception** (the felt difference between deterministic PRNG and physical TRNG), **distribution** (the shapes chance takes — uniform, Gaussian, power-law), and **emergence** (randomness-as-seed for walks, stigmergy, morphogenesis). The QFEP framing — E(S) as freedom, not decay — is the spine. Every map should be positioned on one of these four rungs; currently several maps straddle two or sit in a fifth register (gallery / game) that is about application rather than understanding.

## 2. The Red Thread

1. **Entropy as possibility** (Random_Definition)
   - Randomness is high-dimensional free space, not broken order
   - Captures: the axiom, the jar, the dark sphere as symbol
   - Leaks: *where does entropy come from?* (→ TRNG/PRNG distinction)

2. **Source: PRNG vs TRNG** (Random_Definition, Random_Mushrooms)
   - Deterministic sequences with a seed vs physical noise from hardware
   - Captures: `x_{n+1} = (a·x_n + c) mod m`, the RAND 1955 book, hardware decay
   - Leaks: *what does the output look like?* (→ distribution)

3. **Discrete uniform** (Random_Cubes)
   - `P(X=k) = 1/n` for coins, dice, independent events
   - Captures: coin_toss, dice_throw, slot_machine (joint probability)
   - Leaks: what happens when we sum many uniforms? (→ Gaussian)

4. **Continuous distribution** (Random_Gaussian)
   - Central Limit Theorem: `Binomial(n, 0.5) → N(n/2, n/4)`
   - Captures: galton_board, distribution_sampler, random_bell_curve
   - Leaks: distributions are *shapes* — what shapes besides Gaussian? (→ noise, power-law, blue noise)

5. **Random subtraction / removal** (Random_Remove)
   - Randomness as authorship-by-erasure — sculpture, ruins
   - Captures: remove_random as inverse of placement
   - Leaks: why is removal not just addition of holes? (conceptual — could fold into Cubes)

6. **Random transform** (Random_Rotate_Random_XYZ)
   - Jittered rotation, scale, position on existing geometry
   - Captures: RandomRotateRandomXYZ, random_decay_multimesh, hardware_entropy_decay
   - Leaks: transform over time → random walk

7. **One-line emergence: 10 PRINT** (Randomness_10_PRINT_Algorithm)
   - `10 PRINT CHR$(205.5+RND(1)); : GOTO 10` — pattern from a single bit
   - Captures: ten_print_maze_3d — the smallest generative algorithm
   - Leaks: how does randomness become motion? (→ random walk)

8. **Random walk** (Random_Walk)
   - Brownian motion, drunkard's walk, non-teleological navigation
   - Captures: random_walk_128, random_walk_terrarium, leash variants, pixel_cloud
   - Leaks: walks with memory → pheromone/stigmergy

9. **Biological randomness** (Random_Mushrooms)
   - Spores, fungal dispersal, historical random tables (RAND 1955)
   - Captures: mushrooms, bubbles_random, random_number_book
   - Leaks: *this is a thematic map, not a new concept* — fits under TRNG/sampling

10. **Stigmergy / memory walk** (Random_Pheromone)
    - `trail[x,y] += deposit; next = argmax(pheromone[neighbors])`
    - Captures: pheromone_terrain — randomness that leaves traces
    - Leaks: what else emerges from noisy fields? (→ reaction-diffusion, morphogenesis)

11. **Random as spatial substrate** (Random_Space, Random_Space_Geometry)
    - Environment-scale procedural generation, sculpt_one, env_one
    - Captures: world built from random seeds
    - Leaks: coherent noise (Perlin/Simplex) is deferred to its own sequence — correctly

12. **Gallery of applications** (Randomness_Examples_of_Randomness)
    - Pollock, Monte Carlo π estimation, pipe_dream, extreme_randomness
    - Captures: randomness as artistic + computational tool
    - Leaks: Monte Carlo belongs near distribution; Pollock belongs near random walk

13. **Survive the algorithm** (Random_Game)
    - Randomized projectile gauntlet with folding creature enemies
    - Captures: randomness as antagonist, tests embodied understanding
    - Leaks: *game mechanic rather than concept*

14. **Chamber** (Chamber_Random)
    - Catalyst chamber: chaos shots against octapod, randomness levels the field
    - Captures: synthesis, QFEP E(S) embodied as combat mechanic
    - Leaks: → wavefunctions (coherent noise as the next register)

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | Random_Definition | Entropy axiom + PRNG/TRNG | prng_crank_machine, entropy_jar, entropy_axiom, trng_vs_prng | Rich intro, no evolution |
| 2 | Random_Remove | Subtraction | remove_random | Thin map, one anchor |
| 3 | Randomness_10_PRINT_Algorithm | Minimal emergent pattern | ten_print_maze_3d | Good anchor, no evolution |
| 4 | Random_Cubes | Discrete uniform / probability primitives | dice_throw, coin_toss, slot_machine | Good anchor |
| 5 | Random_Rotate_Random_XYZ | Jitter transform | RandomRotateRandomXYZ | Anchor is the map's namesake |
| 6 | Random_Walk | Brownian motion | random_walk_128, random_walk_terrarium, random_walk_leash | Dense — 4 walk variants |
| 7 | Random_Gaussian | CLT / normal distribution | galton_board | Strong anchor |
| 8 | Random_Mushrooms | Biological + historical randomness | mushrooms, random_number_book_page_1955 | Thematic, not conceptual |
| 9 | Random_Space_Geometry | Geometric randomness at scale | random_transformations_geometric, env_one, sculpt_one | Environment scale |
| 10 | Randomness_Examples_of_Randomness | Gallery | pollock_painting_in_3d, monte_carlo_dartboard, pipe_dream | Feels like overflow bin |
| 11 | Random_Pheromone | Stigmergy | pheromone_terrain | Single-anchor, rich concept |
| 12 | Random_Space | Spatial synthesis | random_space | World-scale, concept unclear |
| 13 | Random_Game | Game / test | folding creatures + cube_projectile_spawner | Culmination as gameplay |
| 14 | Chamber_Random | Catalyst chamber | becoming_catalyst (implied) | QFEP synthesis |

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Entropy axiom | entropy_axiom | algorithms/randomness/entropy_axiom/entropy_axiom_multimesh.gd | ✓ |
| Entropy felt | entropy_jar | algorithms/randomness/entropy_jar/entropy_jar.gd | ✓ `dS/dt >= 0` |
| PRNG | prng_crank_machine | algorithms/randomness/prng_crank_machine/prng_crank_machine.gd | ✓ LCG visible |
| TRNG compare | trng_vs_prng | algorithms/randomness/trng_vs_prng/ | ✓ |
| Hardware noise | hardware_entropy_decay | algorithms/randomness/hardware_entropy_decay/ | ✓ |
| Seed reproducibility | seed_replay | algorithms/randomness/seed_replay/seed_replay_demo.gd | ✓ exists but unmapped |
| Digital glitch | digital_materiality_glitch | algorithms/randomness/digital_materiality_glitch/ | ✓ |
| Discrete uniform (coin) | coin_toss | algorithms/randomness/coin_toss/coin_toss.gd | ✓ |
| Discrete uniform (die) | dice_throw | algorithms/randomness/dice_throw/dice_throw.gd | ✓ P(X=k)=1/6 |
| Joint probability | slot_machine | algorithms/randomness/slot_machine/slot_machine.gd | ✓ 6³=216 space |
| Random spawn | random_object_spawner | algorithms/randomness/random_object_spawner.gd | ✓ |
| Random geometry | random_edge_profile | algorithms/randomness/proceduralrandomness/geometrybased/ | ✓ |
| Subtraction | remove_random | algorithms/randomness/RemoveRandom.gd | ✓ |
| Jittered transform | RandomRotateRandomXYZ | algorithms/randomness/RandomRotateRandomXYZ/ | ✓ |
| Decay multimesh | random_decay_multimesh | algorithms/randomness/randomdecay/scripts/ | ✓ |
| 10 PRINT | ten_print_maze_3d | algorithms/randomness/generative/tenprintantmaze/ | ✓ |
| Walk (base) | random_walk | algorithms/randomness/randomwalk/scripts/random_walk.gd | ✓ |
| Walk (128) | random_walk_128 | algorithms/randomness/random_walk_128.tscn | ✓ |
| Walk (leashed) | random_walk_leash | algorithms/randomness/random_walk_leash/ | ✓ |
| Walk (terrarium) | random_walk_terrarium | found via registry | ✓ |
| Walk (collection) | random_walk_collection | found via registry | ✓ |
| Pixel cloud walk | pixel_cloud | algorithms/randomness/pixelcloud/pixel_cloud.gd | ✓ |
| Galton / CLT | galton_board | algorithms/randomness/galton_board/galton_board.gd | ✓ |
| Gaussian field | gaussian_random | algorithms/randomness/gaussian_random.tscn | ✓ |
| Distribution sampler | distribution_sampler | referenced in map | ✓ |
| Distribution compare | distribution_comparator | algorithms/randomness/distribution_comparator/ | ✓ exists but unmapped |
| Bell curve | random_bell_curve | algorithms/randomness/randombellcurve/ | ✓ |
| Stigmergy | pheromone_terrain | algorithms/randomness/pheromone_terrain/pheromone_terrain.gd | ✓ |
| Monte Carlo | monte_carlo_dartboard | algorithms/randomness/monte_carlo_dartboard/ | ✓ π ≈ 4·(inside/total) |
| Action painting | pollock_painting_in_3d | algorithms/randomness/proceduralrandomness/movementbased/ | ✓ |
| Generative pipes | pipe_dream | algorithms/randomness/pipedream/ | ✓ |
| Env synthesis | env_one, sculpt_one | algorithms/randomness/envOne.gd, sculpt_one.tscn | ✓ |
| Spatial synthesis | random_space | referenced | ✓ |
| Mushrooms | mushrooms, bubbles_random | algorithms/randomness/random_bubbles/ | ✓ |
| RAND 1955 book | random_number_book_page_1955 | found in map | ✓ |
| Reaction-diffusion stub | reaction_diffusion_intro | algorithms/randomness/reaction_diffusion_intro/ | ✓ exists — teaser for next seq |
| Perlin bridge | perlin_noise_bridge | algorithms/randomness/perlin_noise_bridge/ | ✓ exists — teaser for noise seq |
| Folding enemies (game) | miura_crawler, kresling_spire, scissor_stalker, kaleidocycle_enemy, origami_droideka, armadillo_eggling | commons/hazards/, algorithms/wavefunctions/foldables/ | ✓ all exist |

**Coverage verdict:** Artifact layer is the strongest part of this sequence — ~40+ working artifacts. The problem is not missing pieces; it is that the pieces are not clustered by concept.

## 5. Gap Analysis

### Is 14 maps bloated? — Yes.

The sequence has strong artifact coverage but weak conceptual compression. Three categories of bloat:

1. **Concept duplication (3 maps for "random transform on geometry")**
   - Random_Remove (removal)
   - Random_Rotate_Random_XYZ (rotation)
   - Random_Space_Geometry (geometric transforms at scale)
   - These could collapse into **one "Random Transformation" map** with sub-stations. The `RANDOMNESS_CURRICULUM.md` already groups them as "Map 4: The Builder."

2. **Gallery/application bloat (3 maps)**
   - Random_Mushrooms (thematic — biological + RAND book)
   - Randomness_Examples_of_Randomness (gallery — Pollock, Monte Carlo, pipes)
   - Random_Space (spatial synthesis — unclear concept)
   - These teach *uses* of randomness rather than *kinds* of randomness. They could either be one consolidated "Randomness in the Wild" gallery or be redistributed (Monte Carlo → Random_Gaussian; Pollock → Random_Walk; mushrooms/spores → Random_Pheromone as "biological stigmergy").

3. **Misclassified anchor maps**
   - Random_Mushrooms is *about* the RAND 1955 book and biological dispersal — this is really TRNG history + Poisson-spread, and belongs inside Random_Definition's orbit, not standing alone.
   - Random_Space has only `random_space` and `dark_sphere` — single-artifact map, world-scale, but no clear concept the others don't cover.

### Missing conceptual bridges

- **From discrete to continuous**: Random_Cubes → Random_Gaussian jumps over "summing uniforms makes a bell curve." The Galton board does this but the *transition* is not named.
- **From uncorrelated to coherent**: nothing in this sequence points to *why Perlin noise exists* — the map `perlin_noise_bridge` artifact exists but has no dedicated map. This is a major forward leak that should be an explicit teaser (a clipboard or info_board).
- **From walk to stigmergy**: Random_Walk → Random_Pheromone is correct but they are separated by five maps (Gaussian, Mushrooms, Space_Geometry, Examples). The thread breaks.

### Missing / weak artifacts

- **Blue noise vs white noise comparison** — `blue_noise` and `whitenoise` folders exist but no map uses them. Anti-clumping is a fundamental concept.
- **Power-law / Pareto distribution** — only Gaussian is taught. Real-world randomness is rarely Gaussian.
- **Seed-reproducibility demo** — `seed_replay` exists but is not placed. This is the payoff of PRNG.
- **distribution_comparator** — exists but unmapped. Would strengthen Random_Gaussian.

### Redundancies

- `random_walk_128`, `random_walk_terrarium`, `random_walk_collection`, `random_walk_leash` — four walk variants in one map is rich but risks being a tech demo. Pick two anchors, promote the others to a second walk map or retire.
- 11 artifacts in Random_Definition is the highest density of any map in the sequence — likely overloaded.

## 6. Forward Leaks

Concepts this sequence raises but cannot answer:

- **Coherent noise (Perlin, Simplex, value)** → Wavefunctions or a dedicated Noise sequence. The `perlin_noise_bridge` and `noise*` artifact families are staged here but belong after this sequence.
- **Reaction-diffusion / morphogenesis** → The `reaction_diffusion_intro` artifact is a teaser; full Turing patterns belong in a later emergence/ML sequence.
- **Stochastic gradient descent / training noise** → ML sequence. Randomness-as-learning is never named here.
- **Quantum randomness** → Foundations crisis. TRNG gestures at physical randomness but does not touch Bell inequalities or measurement.
- **Halting / Kolmogorov complexity** → Foundations crisis. "Is this string random?" is a decidability question.
- **Chaos vs randomness** → Wavefunctions or dynamical systems. Lorenz, logistic map — deterministic sequences that *look* random.
- **Probability as epistemology** (Bayes, frequentist vs Bayesian) → never mentioned; belongs in an inference sequence or foundations.
- **Entropy as information** (Shannon) → QFEP lab has `shannon_entropy_meter` but this sequence treats entropy only as thermodynamic disorder.

## 7. Proposed Ordering

Consolidate 14 maps → **9 maps** along the four registers (definition → distribution → walk → emergence), plus chamber.

```
1. Random_Definition         — entropy, PRNG vs TRNG, the RAND 1955 book
   (absorb: random_number_book from Mushrooms; promote seed_replay)

2. Random_Cubes              — discrete uniform, coin/dice/slot, joint probability
   (keep; add: distribution_comparator as bridge to next)

3. Random_Gaussian           — CLT, Galton, continuous distributions, Monte Carlo π
   (absorb: monte_carlo_dartboard from Examples; add power-law artifact)

4. Random_Transform          — NEW consolidated map
   (absorb: Random_Remove + Random_Rotate_Random_XYZ + Random_Space_Geometry
    Concept: randomness as operator on existing structure — jitter, remove, sculpt)

5. Randomness_10_PRINT       — one-line emergence, smallest generative algorithm
   (keep; strong anchor)

6. Random_Walk               — Brownian motion, drunkard's walk
   (keep; absorb pollock_painting_in_3d from Examples as "random walk as art"
    trim to 2 walk anchors + Pollock)

7. Random_Pheromone          — stigmergy, walks with memory
   (keep; absorb mushrooms/bubbles_random as "biological stigmergy"
    add teaser clipboard for reaction-diffusion and Perlin → next sequences)

8. Random_Game               — survive the algorithm (test)
   (keep; the gameplay culmination)

9. Chamber_Random            — catalyst chamber, QFEP E(S) synthesis
   (keep)

Retire:
- Random_Mushrooms     → absorbed into Definition (book) + Pheromone (biology)
- Random_Space_Geometry → absorbed into new Random_Transform
- Random_Space         → absorbed into Random_Transform (env_one, sculpt_one)
- Randomness_Examples  → redistributed (Monte Carlo → Gaussian, Pollock → Walk, pipe_dream → retire or move to generative art sequence)
```

### Alternative: keep at 11 maps

If the 14→9 compression feels too aggressive, the minimum viable cleanup is:

1. Merge Random_Remove + Random_Rotate_Random_XYZ → **Random_Transform** (jitter + remove)
2. Merge Random_Space + Random_Space_Geometry → **Random_Space** (env-scale synthesis)
3. Redistribute Randomness_Examples artifacts (Monte Carlo → Gaussian, Pollock → Walk, pipe_dream → retire)
4. Absorb Random_Mushrooms into Random_Definition (book) and Random_Pheromone (biology)

Net: 14 → 11 maps, conceptual thread clarified, no artifacts lost.

## Summary

Randomness has the richest artifact library of any sequence audited so far (~40 working artifacts across 10 subfolders) but the weakest conceptual compression. The sequence currently reads as a *gallery of random things* rather than a *curriculum about randomness*. Four registers (definition, distribution, walk, emergence) are present but interleaved with thematic maps (Mushrooms, Examples) and spatial-scale maps (Space, Space_Geometry) that dilute the thread. The existing `RANDOMNESS_CURRICULUM.md` already proposes a 5-map structure (Dice / Drunkard / Cloud / Builder / System) — this audit proposes 9 maps as a middle ground that keeps the spine QFEP chamber. The Perlin/noise family staged in this folder clearly belongs in a later sequence and should be moved or gated behind a teaser.
