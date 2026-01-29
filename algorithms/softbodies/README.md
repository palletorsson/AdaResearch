# Soft Bodies

Deformable physics. Cloth, jelly, squishy things.

## QFEP Connection

Soft bodies exist in constant **oscillation between form (F) and deformation (E)**. They maintain structure while yielding to force — order through flexibility rather than rigidity. This is a queer physics: identity preserved through transformation.

## Contents

| Folder | Description |
|--------|-------------|
| `cloth_straps/` | Cloth simulation with attachment points |
| `mushrooms/` | Soft, springy mushroom physics |
| `slap_test/` | Impact/collision testing for soft bodies |
| `joyride/` | Playful soft body interactions |
| `advanced_concepts/` | Complex soft body techniques |

## Key Concepts

1. **Mass-spring systems** — Particles connected by springs
2. **Verlet integration** — Position-based physics (stable for cloth)
3. **Constraint solving** — Keep particles at fixed distances
4. **Self-collision** — Prevent cloth from passing through itself
5. **Pressure** — Internal force for balloon/jelly effects

## Technical Implementation

Soft bodies typically use:
- Point masses at vertices
- Springs along edges (structural)
- Springs across diagonals (shear)
- Springs across faces (bend resistance)

```
Structural: ─────
Shear:      ╲   ╱
Bend:       ─ ─ ─
```

## VR Experience

- Poke and prod soft objects
- Watch cloth drape and flow
- Feel (visually) the squish
- Throw things at soft targets

## Files

- 9 GDScript files
- 13 scene files
