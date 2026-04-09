# Artifact Types — Improvement Strategies by Kind

Discovered from randomness sequence (114 artifacts), applicable to all 1700.

Every artifact is one of 7 types. Each type has a different improvement strategy. Classify first, then apply the right strategy.

---

## Type 1: Interaction Objects
**What:** Grabbable, throwable things on pedestals. Coin toss, dice, entropy jar.
**Player does:** Grab, throw, shake, pull. Physics respond.
**Scale:** Pedestal (0.5-1m tall)

**Improvement strategy:**
- Is the grab zone obvious? (highlight with glow on approach)
- Does the object feel right to hold? (mass, damping, bounce)
- Is the feedback immediate? (what changes when you throw it?)
- Is the result readable? (ratio display, outcome label)
- Sound: satisfying click/thud on landing

**Quality check:** Can a player who has never seen this pick it up and understand what happened within 3 seconds?

---

## Type 2: Button-Triggered Simulations
**What:** Systems that evolve step-by-step when player presses a button or pulls a lever. PRNG crank, Monte Carlo darts, slot machine.
**Player does:** Press, pull, crank. Each press advances the simulation one step.
**Scale:** Station (0.5-1.5m)

**Improvement strategy:**
- Is the button/lever visible and reachable? (VR ergonomics)
- Does each step produce visible change? (not too subtle, not too large)
- Is accumulated state clear? (counter, histogram, trail)
- Can the player control pace? (fast vs slow iteration)
- Information: show iteration count, current value, running statistic

**Quality check:** After 10 presses, does the player see a pattern emerging?

---

## Type 3: Auto-Generative Installations
**What:** Structures that self-build in real-time. Mazes, pipes, coral, trees. The algorithm is the performance.
**Player does:** Watch, walk around or through.
**Scale:** Room (5-40m)

**Improvement strategy:**
- Is the growth front visible? (highlight the active edge with glow/pulse)
- Can you see the history? (trail, gradient from old to new)
- Is the pace right? (too fast = incomprehensible, too slow = boring)
- Does it fill space interestingly? (not just a blob growing uniformly)
- Sound: subtle generative audio tied to growth events

**Quality check:** Can you point at the screen and say "that part grew from there"?

---

## Type 4: Navigable Landscapes
**What:** Terrains the player walks through or on. Noise terrain, pheromone trails, bell alley.
**Player does:** Walk, explore, feel the space with their body.
**Scale:** Landscape (10-100m)

**Improvement strategy:**
- Does the terrain communicate through height? (valleys = low values, peaks = high)
- Is the color meaningful? (height-mapped, parameter-mapped, or just pretty?)
- Can the player feel the algorithm through movement? (uphill = high probability)
- Are boundaries clear? (where does the terrain end?)
- Atmosphere: fog, ambient light, environmental audio

**Quality check:** Does walking through it feel like walking through the math?

---

## Type 5: Floating Data Objects
**What:** Abstract mathematical visualizations hovering in 3D space. Distributions, probability surfaces, wave grids.
**Player does:** Look at it from different angles. Maybe orbit around it.
**Scale:** Floating (1-5m, no ground plane)

**Improvement strategy:**
- Is the shape readable? (clear axes, labeled if needed)
- Does animation reveal the math? (parameter sweep, morphing between states)
- Is color encoding consistent? (same palette rules as rest of sequence)
- Are labels legible? (Label3D at readable size, billboard mode)
- Glow: emission on the surface itself, no ground plane needed

**Quality check:** Can you screenshot it and use the image in a textbook?

---

## Type 6: Particle & Swarm Aesthetics
**What:** Living, moving elements filling space. Butterflies, bubbles, paint drips, fireflies.
**Player does:** Stand inside it. Feel surrounded.
**Scale:** Ambient (fills available space)

**Improvement strategy:**
- Do individual particles have character? (size variation, color variation, motion variety)
- Does the swarm have emergence? (flocking, clustering, avoidance)
- Is accumulation visible? (trails, deposits, layers building up)
- Sound: particle events → audio events (pop, whoosh, chirp)
- Performance: particle count vs frame rate at 90fps VR

**Quality check:** Does it feel alive? Would you want to stay and watch?

---

## Type 7: Minimal Concept Demonstrators
**What:** Single transforms repeated. Spinning cubes, jittering vertices, random colors.
**Player does:** Glance at it. Get the concept in 2 seconds. Move on.
**Scale:** Compact (0.5-2m)

**Improvement strategy:**
- Is it instantly readable? (concept visible in first frame)
- Is there unnecessary complexity? (strip to essence)
- Does it need to exist? (if it teaches the same thing as another artifact, merge)
- Label: one-line text explaining the principle
- These are warm-up artifacts — they should be fast, clear, forgettable

**Quality check:** Can you explain the concept from a screenshot in one sentence?

---

## How to Use This

1. **Classify** every artifact in a sequence into one of the 7 types
2. **Apply** the type-specific improvement strategy
3. **Batch** by type: improve all Type 1s together, all Type 2s together
4. **Cross-sequence**: the same types appear everywhere. Type 3 (auto-generative) appears in randomness, fractals, L-systems, cellular automata, procedural generation.

## Type Distribution (estimated from randomness)

| Type | Count | % |
|---|---|---|
| Minimal Concept Demonstrators | ~30 | 26% |
| Particle & Swarm Aesthetics | ~20 | 18% |
| Auto-Generative Installations | ~18 | 16% |
| Floating Data Objects | ~15 | 13% |
| Button-Triggered Simulations | ~12 | 11% |
| Interaction Objects | ~10 | 9% |
| Navigable Landscapes | ~9 | 8% |

The Minimal Concept Demonstrators are the largest group and the easiest wins — many are fine as-is, they just need metadata.
