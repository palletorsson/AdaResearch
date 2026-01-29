# Arrays

The fundamental data structure. 1D rows, 2D grids, 3D volumes.

## QFEP Connection

Arrays are **pure structure (F)** — ordered, indexed, predictable. They're the foundation on which entropy operates: randomize an array and you get noise, sort it and you restore order. The tension between array structure and array contents is QFEP in miniature.

## Contents

### Core Array Operations

| File | Description |
|------|-------------|
| `single_cube.gd` | Single element — the atom of arrays |
| `row_3_x.gd` | 1D array — elements along X axis |
| `column_3_z.gd` | 1D array — elements along Z axis |
| `grid_2d_4x4.gd` | 2D array — 4×4 grid |
| `grid_3d_4x4x4.gd` | 3D array — 4×4×4 volume |
| `grid_snapper.gd` | Snap positions to grid coordinates |

### Visualizations

| Folder | Description |
|--------|-------------|
| `index_visualizer/` | Visualize array indices and access patterns |
| `binary_table/` | Binary numbers as array patterns |
| `mondrian_grid/` | Mondrian-style rectangular subdivisions |
| `grid_editor/` | Interactive grid editing tool |
| `pulsar/` | Pulsing array animations |

## Key Concepts

1. **Indexing** — Access by position: arr[i], grid[x][y], volume[x][y][z]
2. **Iteration** — Walking through elements (for loops)
3. **Mapping** — Transform each element: map(f, arr)
4. **Dimensionality** — 1D (list), 2D (grid/matrix), 3D (volume), nD (tensor)
5. **Memory layout** — Row-major vs column-major ordering

## Array Dimensions in VR

```
1D: ─────────────  (row of cubes)

2D: ┌───────────┐  (flat grid)
    │ □ □ □ □ □ │
    │ □ □ □ □ □ │
    │ □ □ □ □ □ │
    └───────────┘

3D: Stacked grids (volume of cubes you can walk through)
```

## VR Experience

- Walk through 3D arrays
- See index labels on each element
- Visualize access patterns
- Edit grids with hand tracking

## Files

- 17 GDScript files
- 15 scene files
