# Curriculum Flow Analysis

## Current System

### What Controls Flow

| Component | File | Role |
|-----------|------|------|
| **Layer Organization** | `fractal_index.json` | Groups sequences by QFEP term |
| **Prerequisites** | `cross_references` in fractal_index | "requires" / "enables" |
| **Lab States** | `Lab/map_data_post_*.json` | Visual evolution after completion |
| **Progression Mapping** | `lab_map_progression.json` | Sequence → post-lab mapping |
| **Visualization** | `WorldMapDataProvider.gd` | Subway map view |

### Current Flow is **Implicit**

The player can choose any **unlocked** sequence. Unlocking is controlled by prerequisites:

```
primitives (no prereqs - always available)
    ↓ enables
├── vectors
├── transformations  
├── meshes
├── color
└── randomness
        ↓ enables
    ├── noise
    ├── morphogenesis
    └── machinelearning...
```

**Problem**: No recommended path. Player might do `primitives → randomness → ML` and miss foundational concepts.

## Proposed: Explicit Spine + Optional Branches

### The QFEP Spine (Recommended Progression)

A linear **recommended path** that teaches QFEP progressively:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        THE QFEP SPINE                                   │
│                                                                         │
│  F (Order)                                                              │
│  ─────────                                                              │
│  1. primitives        → "The Euclidean world"                          │
│  2. vectors           → "Direction and magnitude"                       │
│  3. transformations   → "What stays the same"                          │
│                                                                         │
│  F ↔ E Oscillation                                                      │
│  ────────────────                                                       │
│  4. wavefunctions     → "Sine creates curves"                          │
│  5. forces            → "Newton's laws"                                │
│                                                                         │
│  E(S) (Entropy)                                                         │
│  ─────────────                                                          │
│  6. randomness        → "Disorder as creative force"                   │
│  7. noise             → "Structured randomness"                        │
│  8. cellularautomata  → "Simple rules, complex behavior"               │
│                                                                         │
│  λ (Edge of Chaos)                                                      │
│  ─────────────────                                                      │
│  9. fractals          → "Self-similarity, infinite detail"             │
│  10. lsystems         → "Generative grammars"                          │
│  11. proceduralgen    → "WFC, Markov, isosurfaces"                     │
│                                                                         │
│  φΔE(S,t) (Integration)                                                 │
│  ─────────────────────                                                  │
│  12. morphogenesis    → "Turing patterns"                              │
│  13. swarmintelligence → "Collective behavior"                         │
│  14. softbodies       → "Deformable matter"                            │
│  15. machinelearning  → "Learning systems"                             │
│                                                                         │
│  Synthesis                                                              │
│  ─────────                                                              │
│  16. foundationscrisis → "Gödel, Russell, limits"                      │
│  17. qfeplaboratory   → "The complete formula"                         │
│  18. speculativecomputation → "Queer futures"                          │
│  19. criticalalgorithms → "Ethics of computation"                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Optional Branches (Unlock from Spine)

At certain spine points, branches become available:

```
After primitives:
  └── meshes (3D modeling)
  └── datastructures (arrays, trees)
  └── color (perception)

After vectors:
  └── computationalgeometry
  └── graphtheory

After forces:
  └── physicssimulation (rigid bodies)
  └── particles
  └── joints

After proceduralgen:
  └── spatial_partitioning (Voronoi, BSP)
  └── isosurfaces (marching cubes)
  └── higher_dimensions (tesseract)

After machinelearning:
  └── recursiveemergence
  └── artmathematics (Escher, Magritte)

After criticalalgorithms:
  └── advancedlaboratory
```

## Implementation Options

### Option 1: Keep Prerequisites-Only (Current)
- **Pros**: Maximum freedom, non-linear exploration
- **Cons**: No guidance, can miss foundations, Lab states unordered

### Option 2: Explicit Spine Config
Add to `fractal_index.json`:
```json
"spine": {
  "order": [
    "primitives", "vectors", "transformations",
    "wavefunctions", "forces",
    "randomness", "noise", "cellularautomata",
    "fractals", "lsystems", "proceduralgeneration",
    "morphogenesis", "swarmintelligence", "softbodies", "machinelearning",
    "foundationscrisis", "qfeplaboratory", "speculativecomputation", "criticalalgorithms"
  ],
  "branch_points": {
    "primitives": ["meshes", "datastructures", "color"],
    "vectors": ["computationalgeometry", "graphtheory"],
    "forces": ["physicssimulation", "particles"],
    "proceduralgeneration": ["spatial_partitioning", "isosurfaces", "higher_dimensions"],
    "machinelearning": ["recursiveemergence", "artmathematics"]
  }
}
```
- **Pros**: Clear recommended path, branches for exploration
- **Cons**: More rigid, might feel constrained

### Option 3: Hybrid with Soft Guidance
- Prerequisites still control unlock
- Add "recommended_next" field to each sequence
- Lab visually emphasizes spine sequences (larger portals, glowing)
- **Pros**: Guided but free, Lab design drives flow
- **Cons**: Requires careful Lab state design

## Lab Evolution Pattern

The Lab should evolve to:
1. **Celebrate completion** (trace data, artifacts appear)
2. **Unlock next spine sequence** (prominent portal)
3. **Reveal branches** (smaller portals, "optional" labels)
4. **Build the world** (structures grow as you progress)

### Lab State Progression

```
Lab (initial)
  └── Portal: primitives (only option)

Lab_post_primitives
  ├── Your trace visible
  ├── Ramp up to: vectors (SPINE - prominent)
  └── Side doors: meshes, color, datastructures (optional)

Lab_post_vectors
  ├── Vectors visualized on walls
  ├── Elevator to: transformations (SPINE)
  └── Side: computationalgeometry, graphtheory

Lab_post_transformations
  ├── Rotating structures appear
  ├── Bridge to: wavefunctions (SPINE)
  └── Side: (none yet)

Lab_post_wavefunctions
  ├── Oscillating structures, sound
  ├── Stairs to: forces (SPINE)
  └── Side: proceduralaudio

... and so on
```

## Recommendation

**Option 3 (Hybrid)** is most aligned with QFEP:
- **Order** (spine provides structure)
- **Chaos** (branches allow exploration)
- **Edge** (Lab visually guides without forcing)

The flow becomes:
1. Complete spine sequence
2. Return to Lab (evolved state)
3. See prominent portal to NEXT spine sequence
4. See smaller portals to OPTIONAL branches
5. Choose: follow spine or explore branch
6. Either way, return to Lab, continue spine

This is **QFEP as curriculum design**: F (spine) - λE(S) (branches) + φΔE(S,t) (Lab evolves based on choices).
