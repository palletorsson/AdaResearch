# Transform Matrix Cube

An interactive 3x3 matrix transformation visualizer that shows how a matrix maps a unit cube to a new shape. A ghost cube shows the original, while the transformed version displays deformed vertices, edges, and faces along with colored basis vector arrows indicating where the i, j, and k unit vectors land after transformation.

## How It Works

Each of the eight unit cube vertices is multiplied by the current 3x3 matrix (Basis) to produce transformed positions. Edges are drawn as oriented cylinders connecting transformed vertex pairs via MultiMesh for efficient rendering. Semi-transparent faces are rebuilt each frame as ImmediateMesh triangles. Three colored arrows (red, green, blue) show the transformed basis vectors, and a determinant label indicates whether the transformation preserves orientation, flips it, or collapses a dimension.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float | 0.4 |
| `matrix` | Basis | Basis.IDENTITY |
| `color_original` | Color | (0.3, 0.3, 0.4, 0.3) |
| `color_transformed` | Color | (0.3, 1.0, 0.5, 0.7) |
| `color_i` | Color | (1.0, 0.3, 0.3) |
| `color_j` | Color | (0.3, 1.0, 0.3) |
| `color_k` | Color | (0.3, 0.5, 1.0) |

## Features

- 6 preset transformations: Identity, Scale 2X, Shear, Rotate 45 degrees, Reflect, Squish
- Live 3x3 matrix display and determinant calculation with orientation interpretation
- Color-coded basis vector arrows (i', j', k') showing where unit vectors map
- MultiMesh-based vertex and edge rendering for performance
- Tween-based smooth animation between matrix states
- Keyboard shortcuts (1-6) for desktop testing

## Files

- `transform_matrix_cube.gd` -- Main script
- `transform_matrix_cube.tscn` -- Scene file
