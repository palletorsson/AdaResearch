# Experiments

Experimental interactive scenes for exploring geometric concepts through direct manipulation.

## How It Works

The TriangleConnectionManager coordinates multiple draggable triangles in a shared coordinate space. It reparents all vertex spheres to a unified manager node, then continuously checks for proximity-based snapping. When two vertices from different triangles come close enough, they merge into a single shared vertex, allowing players to build connected geometric structures by hand.

## Files

- `TriangleConnectionManager.gd` -- Manages triangle vertex snapping and merging in a unified coordinate space
- `ConnectedTriangles.tscn` -- Scene with multiple interactive triangles and the connection manager
