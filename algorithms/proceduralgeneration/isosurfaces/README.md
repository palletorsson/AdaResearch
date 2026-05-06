# Isosurfaces

Metaball and implicit surface visualization via ray marching — organic blob shapes from mathematical fields.

## QFEP Connection

Isosurfaces define form through **threshold**. A scalar field fills space (E, continuous); the isosurface extracts where field equals threshold (F, boundary). Metaballs blend smoothly — multiple sources create organic merging. λ as the threshold value.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `metaball_count` | 9 | Number of blobs |
| `min/max_strength` | 0.8/1.2 | Field intensity range |
| `blend_factor` | 0.4 | Merge smoothness |
| `metaball_color` | Blue | Surface color |
| `animate_strength` | false | Pulsing animation |

## How It Works

Ray marching through signed distance field:
1. Cast ray from camera
2. Sample field at each step
3. When field ≈ threshold, found surface
4. Calculate normal for shading

## Files

| File | Purpose |
|------|---------|
| `metaballs.gd` | Field generation |
| `*.tscn` | Scene |

## See Also

- `spacetopology/marchingcubes/` — Mesh-based isosurfaces
- `swarmintelligence/physarum/` — Organic field growth
