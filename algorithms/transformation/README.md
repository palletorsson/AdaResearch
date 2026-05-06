# Transformation

Translate, rotate, scale. The fundamental operations of geometry.

## QFEP Connection

Transformations are **F** — they preserve structure while changing form. A rotation doesn't add entropy; it maps the object to itself through different coordinates. Transformations reveal **invariants**: what stays the same when everything changes?

## Contents

| Folder | Description |
|--------|-------------|
| `spin/` | Rotation demonstrations |
| `scaleme/` | Scale transformations |
| `rotatescalecubes/` | Combined rotation and scaling |
| `carousel_cake/` | Rotating carousel of objects |
| `toruscylinder/` | Torus and cylinder transformations |
| `vector_field/` | Vector field transformations |
| `quantum_field/` | Quantum field-inspired transforms |
| `surreal_machines/` | Surrealist machine animations |
| `booleanTunnel/` | Boolean operations creating tunnels |

## Key Concepts

1. **Translation** — Move without changing orientation: T(x) = x + d
2. **Rotation** — Turn around axis: R(θ) preserves distances
3. **Scale** — Grow/shrink: S(k) multiplies all distances by k
4. **Composition** — Combine transforms: first rotate, then translate
5. **Matrices** — 4×4 matrices encode all 3D transformations
6. **Invariants** — What doesn't change? (angles in rotation, ratios in uniform scale)

## Transform Order Matters!

```
Rotate then Translate ≠ Translate then Rotate

    ┌──┐ rotate    ┌──┐ translate  ┌──┐
    │  │  ──→      │╲ │   ──→      │╲ │ 
    └──┘           └──┘            └──┘
                                    ↑ different position!
    
    ┌──┐ translate ┌──┐  rotate    ┌──┐
    │  │  ──→      │  │   ──→      │ ╲│
    └──┘           └──┘            └──┘
                                    ↑ rotates around origin, not object
```

## VR Experience

- Manipulate objects with 6DOF controllers
- See transform matrices update in real-time
- Build compositions of transforms
- Discover invariants through interaction

## Files

- 10 GDScript files
- 10 scene files
- 2 documentation files
