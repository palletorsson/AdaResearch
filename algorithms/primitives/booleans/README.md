# Boolean Primitives

Grid of CSG boolean operations — union, subtraction, and intersection demonstrated across primitive shapes.

## QFEP Connection

Boolean operations define **set membership in 3D space**. Union (OR) combines regions (E, expansion); intersection (AND) restricts to overlap (F, constraint); subtraction carves one from another (boundary creation). These fundamental operations construct all complex geometry from simple primitives.

## How It Works

```
Union (A ∪ B):        Subtraction (A - B):    Intersection (A ∩ B):
┌─────┬─────┐         ┌─────┬     ┐         ┌     ┬─────┐
│█████│█████│         │█████│     │         │     │█████│
│█████│█████│    →    │█████│     │    →    │     │█████│
│█████│█████│         │█████│     │         │     │█████│
└─────┴─────┘         └─────┴     ┘         └     ┴─────┘
  Combined              A with B hole         Only overlap
```

## Parameters

### Grid Settings
| Export | Default | Description |
|--------|---------|-------------|
| `grid_size` | (3, 5, 5) | Grid dimensions |
| `spacing` | 0.4 | Distance between cells |
| `scale_factor` | 0.1 | Object size |
| `auto_generate` | true | Generate on load |

### Randomization
| Export | Default | Description |
|--------|---------|-------------|
| `use_random_seed` | true | Random variations |
| `fixed_seed` | 12345 | Deterministic seed |
| `material_variations` | true | Different colors |

## Primitive Types

- **Box**: Rectangular solid
- **Sphere**: Ball shape
- **Cylinder**: Tube/column
- **Torus**: Donut shape
- **Prism**: Triangular solid

## Operation Types

| Operation | CSG Constant | Result |
|-----------|--------------|--------|
| Union | `OPERATION_UNION` | A + B combined |
| Subtraction | `OPERATION_SUBTRACTION` | A - B carved |
| Intersection | `OPERATION_INTERSECTION` | A ∩ B overlap only |

## Files

| File | Purpose |
|------|---------|
| `booleans.gd` | Grid generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var bools = preload("res://algorithms/primitives/booleans/booleans.tscn").instantiate()
bools.grid_size = Vector3i(5, 5, 5)
bools.use_random_seed = false  # Reproducible
add_child(bools)
```

## VR Experience

Walk through a grid of boolean combinations. Each cell shows different primitives combined via different operations. The rainbow of materials makes it easy to distinguish shapes. See how subtraction creates holes, intersection creates lenses, union creates blobs.

## Applications

- **3D modeling**: Building complex shapes from simple ones
- **Level design**: Carving rooms from solid blocks
- **Physics**: Collision shape construction
- **Art**: Sculptural forms

## See Also

- `transformation/booleanTunnel/` — Boolean tunnels
- `postprocessing/clipping/` — Plane-based cutting
- `proceduralgeneration/` — Complex shape generation
