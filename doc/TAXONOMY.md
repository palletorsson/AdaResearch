# Generative Paradigms Taxonomy

> How do we encode form? What primitives and operations are needed?

---

## From Point to Forest: The Foundational Stack

Everything builds from nothing. The progression:

### Level 0: The Point
```
Point = Vector3(x, y, z)
```
Position without extension. Pure existence. The origin of everything.

**Maps:** `Point_Zero`, `Point_One`

---

### Level 1: Primitives (0D → 3D)

| Dimension | Primitive | Definition | Example |
|-----------|-----------|------------|---------|
| 0D | Point | Position | `Vector3(0,0,0)` |
| 1D | Line | Two points connected | `Point_Line` |
| 2D | Triangle | Three points, one face | `Point_Triangle` |
| 2D | Plane | Infinite flat surface | `grab_plane` |
| 3D | Tetrahedron | 4 faces, simplest solid | `grab_tetrahedron` |
| 3D | Cube | 6 faces, the workhorse | `grab_cube` |
| 3D | Sphere | All points equidistant | `grab_sphere` |

**Platonic Solids (regular polyhedra):**
- Tetrahedron (4 faces)
- Cube/Hexahedron (6 faces)
- Octahedron (8 faces)
- Dodecahedron (12 faces)
- Icosahedron (20 faces)

**Sequences:** `primitives`

---

### Level 2: Properties

What can a primitive have?

| Property | Type | Example |
|----------|------|---------|
| Position | Vector3 | `(x, y, z)` |
| Color | RGB/HSV | `Color(1, 0, 0)` |
| Scale | Vector3 | `(1, 1, 1)` |
| Rotation | Basis/Quat | `Basis.IDENTITY` |
| Material | Surface | albedo, roughness, metallic |

**Sequences:** `color`, `vectors`

---

### Level 3: Transformations

How do primitives move?

| Transform | Formula | Effect |
|-----------|---------|--------|
| Translate | `p + offset` | Move position |
| Rotate | `p × rotation_matrix` | Spin around axis |
| Scale | `p × scale_factor` | Grow/shrink |
| Shear | `p × shear_matrix` | Skew |

**Sequences:** `transformation`, `vectors`

---

### Level 4: Collections

How do we have many?

| Collection | Structure | Example |
|------------|-----------|---------|
| Array | Indexed sequence | `elements[i]` |
| Grid | 2D array | `elements[i][j]` |
| Lattice | 3D array | `elements[i][j][k]` |
| Graph | Nodes + edges | `node.connections` |
| Tree | Hierarchical | `node.children` |

**Sequences:** `arrays`, `datastructures`

---

### Level 5: Patterns

Collections + rules = patterns.

| Pattern | Rule | Example |
|---------|------|---------|
| Repetition | Same transform each | Grid |
| Progression | Cumulative transform | Staircase |
| Alternation | Modulo selection | Checkerboard |
| Symmetry | Mirror/rotate | Mandala |
| Gradient | Interpolated property | Color fade |

---

### Level 6: Dynamics

Patterns over time.

| Dynamic | Mechanism | Example |
|---------|-----------|---------|
| Animation | Transform(t) | Spinning cube |
| Physics | Forces → acceleration | Bouncing ball |
| Oscillation | sin(t), cos(t) | Wave |
| Growth | Recursive expansion | L-system tree |
| Emergence | Agent interaction | Flocking |

**Sequences:** `forces`, `wavefunctions`, `particles`

---

### Level 7: Complexity

Dynamics → emergent structure.

| Complexity | Source | Example |
|------------|--------|---------|
| Fractal | Self-similarity | Mandelbrot |
| Cellular | Local rules | Game of Life |
| Swarm | Collective behavior | Boids |
| Evolutionary | Selection pressure | Genetic algorithm |

**Sequences:** `fractals`, `cellularautomata`, `swarmintelligence`

---

### Level 8: The Forest

All levels combined. A forest is:
- Points (leaf positions)
- Primitives (trunk cylinders, leaf planes)
- Properties (bark color, leaf green)
- Transforms (branch angles)
- Arrays (many trees)
- Patterns (spacing rules)
- Dynamics (wind, growth)
- Complexity (ecosystem interaction)

**From point to forest: each level requires the previous.**

---

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
**Algorithm folders:** `arrays`, `primitives`, `patterngeneration`  
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
**Algorithm folders:** `lsystems` (interpretation)  
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
**Algorithm folders:** `fractals` (42 scenes)  
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
**Algorithm folders:** `lsystems`, `stringalgorithms`, `proceduralgeneration/grammar_systems`  
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
**Algorithm folders:** `swarmintelligence`, `cellularautomata` (41), `emergentsystems`, `steering`, `particles`  
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
**Algorithm folders:** `randomness` (114!), `wavefunctions` (105), `spacetopology`, `proceduralgeneration/isosurfaces`  
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
**Algorithm folders:** `primitives/booleans`, `transformation/booleanTunnel`  
**Sequences:** (cave example)  
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
**Algorithm folders:** `physicssimulation` (39), `forces`, `softbodies`, `joint` (11), `proceduralgeneration/constraint_solvers`  
**Sequences:** `forces`, `softbodies`, `constraint_solvers`

---

## Full Algorithm → Paradigm Mapping

### F_order (Structure, Prediction)
| Folder | Scenes | Paradigm(s) |
|--------|--------|-------------|
| `primitives` | 28 | Array, Boolean |
| `arrays` | 15 | Array |
| `vectors` | 57 | Transform |
| `transformation` | 10 | Transform |
| `color` | 38 | Field |
| `computationalgeometry` | 8 | Constraint |
| `datastructures` | 16 | Array, Graph |

### Oscillation (F↔E Balance)
| Folder | Scenes | Paradigm(s) |
|--------|--------|-------------|
| `wavefunctions` | 105 | Field |
| `oscillation` | 18 | Field |
| `forces` | 10 | Constraint |
| `joint` | 11 | Constraint |
| `proceduralaudio` | 10 | Field |

### E_entropy (Disorder, Randomness)
| Folder | Scenes | Paradigm(s) |
|--------|--------|-------------|
| `randomness` | 114 | Field |
| `cellularautomata` | 41 | Agent |
| `chaos` | 4 | Field, Agent |
| `patterngeneration` | 11 | Field, Grammar |

### Lambda_edge (Edge of Chaos)
| Folder | Scenes | Paradigm(s) |
|--------|--------|-------------|
| `fractals` | 42 | Fractal |
| `lsystems` | 7 | Grammar, Turtle |
| `spacetopology` | 25 | Field, Boolean |
| `emergentsystems` | 12 | Agent |
| `wfc` | 5 | Constraint, Field |

### Integration (Emergence)
| Folder | Scenes | Paradigm(s) |
|--------|--------|-------------|
| `swarmintelligence` | 9 | Agent |
| `steering` | 15 | Agent |
| `physicssimulation` | 39 | Constraint |
| `softbodies` | 13 | Constraint |
| `computationalbiology` | 11 | Agent, Grammar |

### Synthesis (Full QFEP)
| Folder | Scenes | Paradigm(s) |
|--------|--------|-------------|
| `machinelearning` | 65 | Constraint, Agent |
| `proceduralgeneration` | 101 | All paradigms |
| `graphtheory` | 21 | Constraint, Array |
| `alternativegeometries` | 8 | Field, Transform |

### Critical/Theory
| Folder | Scenes | Paradigm(s) |
|--------|--------|-------------|
| `criticalalgorithms` | 2 | — |
| `criticaltheory` | 8 | — |
| `neuroscience` | 3 | Agent, Field |

---

## Scene Count by Paradigm

| Paradigm | Estimated Scenes | Primary Folders |
|----------|------------------|-----------------|
| **Field** | ~350 | randomness, wavefunctions, noise |
| **Agent** | ~80 | cellularautomata, swarm, steering |
| **Constraint** | ~75 | physics, forces, softbodies |
| **Fractal** | ~45 | fractals |
| **Array** | ~60 | arrays, primitives, vectors |
| **Grammar** | ~20 | lsystems, stringalgorithms |
| **Boolean** | ~10 | booleans, tunnels |
| **Turtle** | ~10 | (implicit in lsystems) |

**Total: ~1000+ algorithm scenes**

---

## Paradigm Combinations

Real systems often combine paradigms:

| Combination | Result | Example Folders |
|-------------|--------|-----------------|
| Array + Transform | Staircase | `transformation` |
| Array + Field | 2.5D, terrain | `randomness/noise` |
| Grammar + Turtle | L-systems | `lsystems` |
| Agent + Field | Flow fields | `steering`, `swarmintelligence` |
| Fractal + Grammar | Recursive L-systems | `lsystems/Growth` |
| Constraint + Agent | Physics swarms | `physicssimulation` |
| Field + Boolean | Marching cubes | `spacetopology/marchingcubes` |

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

---

## References

- Prusinkiewicz & Lindenmayer, *The Algorithmic Beauty of Plants*
- Shiffman, *The Nature of Code*
- Stiny, *Shape Grammars*
- Reynolds, *Flocks, Herds and Schools* (Boids)
- Wolfram, *A New Kind of Science* (CA)
- Perlin, *Noise* (continuous fields)

---

*This taxonomy maps to AdaResearch sequences. Each paradigm is a way of thinking about generation — a different answer to "how do we make form?"*

*See also: `curriculum_spine.json`, `WorldMapDataProvider.gd`*
