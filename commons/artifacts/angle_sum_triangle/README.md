# Angle Sum Triangle

Demonstrates the Euclidean geometry theorem that the interior angles of any triangle sum to exactly 180 degrees. This fundamental property fails in non-Euclidean geometries, making it a gateway to understanding how axioms shape mathematical truth.

## How It Works

An equilateral triangle is drawn as a wireframe line strip with labeled 60-degree angles at each vertex. A summary label below shows the equation 60 + 60 + 60 = 180, reinforcing the angle sum property visually. The artifact uses ImmediateMesh for the triangle outline and Label3D nodes for angle annotations.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `size` | float | `0.4` |

## Features

- Wireframe triangle rendered via ImmediateMesh
- Labeled angles at each vertex with warm yellow color
- Sum equation displayed below the triangle
- Grid configuration support via `apply_grid_config()`

## Files

- `angle_sum_triangle.gd` -- Main script
- `angle_sum_triangle.tscn` -- Scene file
