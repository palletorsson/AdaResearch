# SwarmIntelligence_Boids_Algorithm — Who Enters the Radius?

*Floor 163 · Care Unit Model B's working chapter (`void.md`, building on `final.md` and `walked.md`)*

---

## 1. Before asking what the flock wants, ask who it can notice

Across the upper hall, a flock passes straight through the concrete wall because its boundary lives in coordinates rather than architecture. At the smaller `boids_neighbour_lens` table (**WHO ENTERS THE RADIUS?**), thirty boids stay inside reach while a single black handle on the left lets Model B pause time and sweep the gold perception sphere from narrow (`0.06 m`) to wide (`0.48 m`).

Hold the flock completely frozen while sliding the radius wider:

1. **No body moves** (`drift = 0.0000 m`), and none of Craig Reynolds' three weights — **separation** (red), **alignment** (blue), **cohesion** (green) — has been altered.
2. Yet golden neighbour rods snap into view one by one as nearby bodies fall inside the sphere, and all four steering arrows (`SEP`, `ALIGN`, `COH`, and their white `SUM`) immediately change length and direction.

*One wider circle makes a neighbour.* — Pause the boids table and slide the black point left or right to widen the gold radius: bodies stay still, yet who enters the circle rewrites every steering arrow.

## 2. Containment, belonging, and what the rules omit

Floor 163 puts four different enclosures of the same local-neighbour law side by side:

- **The Neighbour Lens (`boids_neighbour_lens`)** gives one external hand global authority over every body's perception radius.
- **The Boids Aquariums (`boids_aquarium`, `dna-boids-lane`, `dna-boids-orb`)** and **`fish_school`** turn the same three forces into lanes, orbs, and bounded water — proving that separation, alignment, and cohesion never choose where a world ends; someone wrote that glass rim.
- **The Drone Comparison (`drone_comparison`)** and **The Unit (`unit-steer`, `unit-rhythm`)** strip away pastoral metaphors of birds and fish, placing military/automated coordination right beside biological flocking.

Alignment is not consent, and cohesion is not belonging. No boid can refuse a relation, remember harm, or ask for distance; widening a single scalar radius rewrites who each body must answer to.

## 3. What carries downward

On Floor 106, cells stood fixed on a grid and polled immediate neighbours. Here on Floor 163, bodies move freely in space and neighbourhood becomes a **metric radius** — a political as much as geometric cut deciding who counts as near. Downward into Machine Learning (`F177`), that same question turns into how a loss function decides which data point counts as an error.

---

*Verified Ghost Student Spine Stop #7 receipt: `doc/book/iterations/2026-11-21-swarm-first-neighbour/checks.json` (`01-f163-overview.png`, `02-radius-narrow.png`, `03-radius-mid.png`, `04-radius-wide-dual-hud.png`).*
