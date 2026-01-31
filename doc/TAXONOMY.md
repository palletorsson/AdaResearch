# Generative Paradigms Taxonomy

> How do we encode form? What primitives and operations are needed?

## The Encoding Stack

To describe any complex structure (a facade, a forest, a form), we need:

| Layer | Role | Example |
|-------|------|---------|
| **Elements** | The vocabulary (nouns) | window, branch, cube |
| **Transform** | Positioning (verbs) | translate, rotate, scale |
| **Array** | Repetition structure | grid, sequence, lattice |
| **Map/Rules** | Selection logic (grammar) | if corner: use X, else Y |

**General formula:**
```
structure = positions.map((i,j) => {
    element: select(i, j, rules),
    transform: compute(i, j)
})
```

---

## Eight Generative Paradigms

### 1. Array/Grid
**Structure:** `element[i,j] = f(i,j)`

Explicit positions. Regular repetition. Architectural thinking.

```gdscript
for i in rows:
    for j in cols:
        place(element, Vector3(i * spacing, 0, j * spacing))
```

**Good for:** Facades, grids, lattices, tilings  
**Sequences:** `array_tutorial`, `primitives`

---

### 2. Turtle/Path
**Structure:** Forward, turn, forward...

Position emerges from accumulated movements. The trace of motion.

```gdscript
forward(length)
turn(angle)
forward(length)
```

**Good for:** Branching, paths, organic growth, drawing  
**Sequences:** `lsystems` (implicit)

---

### 3. Fractal/Recursive
**Structure:** `base + subdivide(self)`

Self-similarity across scales. Infinite detail through recursion.

```gdscript
func fractal(depth):
    if depth == 0: return base
    return combine(fractal(depth-1), fractal(depth-1))
```

**Good for:** Trees, coastlines, mountains, Sierpinski  
**Sequences:** `fractals`

---

### 4. Grammar/Rewrite
**Structure:** `symbol → expansion`

Start with axiom, apply production rules, expand.

```
Axiom: A
Rules: A → AB, B → A
Generations: A → AB → ABA → ABAAB → ...
```

**Good for:** Linguistic structure, growth patterns, L-systems  
**Sequences:** `lsystems`, `grammar_systems`

---

### 5. Agent/Particle
**Structure:** Many entities + local rules → emergence

No global plan. Behavior emerges from interaction.

```gdscript
for agent in agents:
    agent.velocity += separation + alignment + cohesion
    agent.position += agent.velocity
```

**Good for:** Flocking, swarms, CA, unpredictable patterns  
**Sequences:** `swarmintelligence`, `cellularautomata`, `particles`

---

### 6. Field/Sample
**Structure:** Evaluate `f(x,y,z)` at points

Continuous function, discretely sampled. The continuous underlying the discrete.

```gdscript
for point in sample_points:
    value = noise(point.x, point.y, point.z)
    if value > threshold: place(element, point)
```

**Good for:** Noise, terrain, implicit surfaces, organic shapes  
**Sequences:** `noise`, `randomness`, `isosurfaces`

---

### 7. Boolean/CSG
**Structure:** `A ∪ B`, `A - B`, `A ∩ B`

Constructive Solid Geometry. Build complex forms from simple primitives using set operations.

```gdscript
# Union: combine two shapes
result = A.union(B)

# Subtract: carve B from A
result = A.subtract(B)

# Intersect: only where both exist
result = A.intersect(B)
```

**Good for:** Carved forms, caves, architectural voids, mechanical parts  
**Sequences:** `booleans` (cave example)  
**Godot:** `CSGBox3D`, `CSGCombiner3D`, `CSGSphere3D`

---

### 8. Constraint/Solve
**Structure:** Specify relationships → solver finds positions

Declarative: say what you want, not how to get it.

```gdscript
# Constraints:
distance(A, B) == 1.0
angle(A, B, C) == 90°
# Solver finds A, B, C positions
```

**Good for:** Physics, inverse kinematics, optimization, equilibrium  
**Sequences:** `forces`, `softbodies`, `constraint_solvers`

---

## Paradigm Combinations

Real systems often combine paradigms:

| Combination | Result |
|-------------|--------|
| Array + Transform | Staircase (cumulative offset) |
| Array + Field | 2.5D glass planes (discrete sampling continuous) |
| Grammar + Turtle | L-systems (rewrite rules + turtle interpretation) |
| Agent + Field | Particles in flow field |
| Fractal + Grammar | Recursive L-systems |
| Constraint + Agent | Physics-based swarms |

---

## Curriculum Sequence

Building capacity progressively:

1. **Primitives** — elements exist
2. **Transform** — elements can be moved/rotated/scaled
3. **Arrays** — elements can be repeated
4. **Arrays + Transform** — patterns emerge (staircase)
5. **Fields** — continuous functions (noise)
6. **Arrays + Fields** — discrete sampling continuous (2.5D)
7. **Recursion** — self-reference (fractals)
8. **Grammar** — rule-based growth (L-systems)
9. **Agents** — emergence from interaction (CA, boids)
10. **Constraints** — physics, equilibrium (forces, soft bodies)

Each paradigm requires capacities from previous ones.

---

## Dimensional Progression

| Dimension | Structure | Cost |
|-----------|-----------|------|
| 0D | Point | Trivial |
| 1D | Line, curve, path | O(n) |
| 2D | Surface, grid | O(n²) |
| 2.5D | Layered planes | O(n) planes |
| 3D | Volume, mesh | O(n³) or O(faces) |
| 4D | Animation, time | O(n³ × frames) |

2.5D is the performance sweet spot: 3D appearance at 2D cost.

---

## References

- Prusinkiewicz & Lindenmayer, *The Algorithmic Beauty of Plants*
- Shiffman, *The Nature of Code*
- Stiny, *Shape Grammars*
- Reynolds, *Flocks, Herds and Schools* (Boids)
- Wolfram, *A New Kind of Science* (CA)
- Perlin, *Noise* (continuous fields)

---

## Mapping to QFEP Phases & Curriculum Spine

The taxonomy integrates with `curriculum_spine.json`:

| QFEP Phase | λ Range | Paradigms | Sequences |
|------------|---------|-----------|-----------|
| **F_order** | λ→0 | Array, Transform | `primitives`, `vectors`, `transformation` |
| **oscillation** | F↔E | Field (periodic) | `wavefunctions`, `forces` |
| **E_entropy** | λ→1 | Field (noise), Agent | `randomness`, `noise`, `cellularautomata` |
| **lambda_edge** | λ≈0.3-0.5 | Fractal, Grammar | `fractals`, `lsystems` |
| **integration** | φ>0 | Agent, Constraint | `swarmintelligence`, `softbodies` |
| **synthesis** | Full QFEP | All combined | `qfeplaboratory` |

### World Map Structure

```
WORLD_MAP = {
    lines: QFEP_PHASES (6 colored metro lines),
    stations: SEQUENCES (stops along each line),
    interchanges: PARADIGM_COMBINATIONS (where lines cross),
    terrain: PARADIGMS (underlying generative modes)
}
```

The paradigms are the **territory**.  
The QFEP phases are the **paths through territory**.  
The sequences are **stations on paths**.  
The maps are **rooms in stations**.

### Generating from Taxonomy

```gdscript
# WorldMapDataProvider can read:
# - curriculum_spine.json → ordered sequences with QFEP phases
# - TAXONOMY.md → paradigm classifications
# - map_sequences.json → sequence definitions
# 
# To produce: navigable world map where
# - Position encodes paradigm
# - Color encodes QFEP phase
# - Connections encode prerequisites
```

---

*This taxonomy maps to AdaResearch sequences. Each paradigm is a way of thinking about generation — a different answer to "how do we make form?"*

*See also: `curriculum_spine.json`, `WorldMapDataProvider.gd`*
