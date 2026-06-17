# Ada Research vs. The Nature of Code — coverage map

How Ada's curriculum lines up with the chapter topics of *The Nature of Code* (see
[CREDITS.md](CREDITS.md) for attribution and the license caveat). This maps **topics and
structure** only — Ada's material is original throughout; nothing from NoC is reproduced.

Status: **✓ covered** · **~ partial** (mechanics exist, dedicated tutorial thin) · **+ Ada-only** (no NoC equivalent).

## NoC chapter topics → Ada sequences

| NoC topic | Ada sequence(s) | spine # / QFEP phase | status |
|---|---|---|---|
| Introduction — randomness, random walks | `randomness`, `noise` | 7–8 · E_entropy | ✓ |
| Vectors | `forces` (vector half), `primitives` | 5 · oscillation / 1 · F_order | ✓ — see the new `/vector-force-map` + `/vector-force-tutorial` |
| Forces | `forces` | 5 · oscillation | ✓ — built out deeply (24-concept spine, 5 acts, walk-in twins) |
| Oscillation | `wavefunctions`, + spring/pendulum in `forces` | 6 · oscillation | ✓ |
| Particle Systems | particle/emitter artifacts in `physics_simulation`; `softbodies` | (no standalone subject) | ~ |
| Autonomous Agents (steering, flocking) | `swarmintelligence` | 13 · lambda_edge | ✓ |
| Physics Libraries (Box2D / Matter.js) | `physics_simulation` (joints, ragdolls, constraints), `softbodies` | 14 · integration | ✓ — Ada rolls its own physics rather than wrapping a library |
| Cellular Automata | `cellularautomata` | 9 · lambda_edge | ✓ |
| Fractals | `fractals`, `lsystems` | 10–11 · lambda_edge | ✓ |
| Evolutionary Computing | nature-system evolution (CritterDNA, EvolutionSystem), `machinelearning` | 15 · integration | ~ — evolution mechanics exist; a dedicated "genetic algorithms" tutorial is thin |
| Neural Networks / Neuroevolution | `machinelearning` | 15 · integration | ✓ |

## Where Ada goes beyond The Nature of Code

NoC assumes a coder already comfortable with geometry and starts at vectors. Ada teaches the
**foundations underneath** first, and closes with a **critical-theory synthesis** NoC never enters.

**Foundations layer (before NoC's chapter 1):**
`primitives` (points/lines/planes) · `transformation` (rotation, dot/cross as invariants) ·
`array_tutorial` (the grid, indexing) · `color` (→ composition) · `change` (calculus — derivative,
integral, vector field) · `isosurfaces` (marching cubes) · `boolean_surfaces` (CSG).

**Edge & synthesis arc (after NoC's chapters):**
`proceduralgeneration` (WFC, Markov) · `graphtheory` (the substrate under everything) ·
`foundationscrisis` (Gödel, Russell — the limits of formal systems) · `qfeplaboratory` (the QFEP
formula embodied) · `postfoundationscrisis` (bias, rhizomes, molecular design as post-crisis practice).

And the whole thing is framed by **QFEP** and a queer-theory reading of computation — a lens NoC
does not carry. Where NoC asks *how do we simulate nature?*, Ada also asks *what does this encoding
foreclose, and what lives in its dark spot?*

## Gaps — where to write Ada's own next chapters

The map surfaces two honest gaps, both natural next writes (in Ada's own words, our own artifacts):

1. **Particle Systems** — Ada has emitters and particle artifacts scattered through
   `physics_simulation`, but no dedicated sequence that teaches *the particle system as a pattern*
   (emitter → particle → lifespan → forces on many → systems of systems). NoC's chapter 4 is the
   clearest argument that this deserves its own arc; Ada's `forces` work (applying one force to many
   bodies) is the on-ramp.
2. **Evolutionary Computing** — the runtime exists (`CritterDNA`, `EvolutionSystem`,
   `TransmutationManager`), but there's no tutorial that walks *genotype → phenotype → fitness →
   selection → generations* as a teachable concept the way `forces` now does for vectors.

Both are where an "extended Ada version" earns the name — covering NoC's ground in Ada's voice, at
body scale in VR, and then pushing past it into the synthesis arc.
