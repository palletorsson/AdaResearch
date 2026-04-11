# 10 PRINT Ant Maze

A 3D interpretation of the classic Commodore 64 one-liner `10 PRINT CHR$(205.5+RND(1)); : GOTO 10`. The program fills a grid with randomly chosen diagonal strokes (`/` or `\`), producing a maze-like pattern. An ant pathfinder then navigates through the maze from one side to the other, demonstrating how simple random rules can create complex navigable structures.

This artifact teaches that a single coin-flip per cell -- the most minimal random decision possible -- is enough to generate an entire maze. Randomness does not need to be complex to produce complex results.

## How It Works

1. **Maze Generation**: A `grid_width x grid_depth` grid is filled. Each cell gets a random value of 0 or 1 (`randi() % 2`), corresponding to a `/` or `\` diagonal. Start and exit positions are placed on opposite sides of the grid.

2. **Navigation Grid**: A finer-resolution grid (`nav_grid_scale = 2`) is built from the maze. The diagonal strokes are rasterized onto this grid as wall cells. The ant navigates the open (non-wall) cells.

3. **3D Rendering**: Each diagonal is rendered as an `ImmediateMesh` line in the ZY plane. The strokes are rotated +/- 45 degrees around the X axis to form the classic `/` and `\` patterns as standing 3D walls.

4. **Ant Pathfinding**: A sphere ("ant") starts at the left edge and seeks the right edge. It uses a greedy heuristic -- preferring moves that reduce distance to the exit -- with a small random factor to avoid straight-line paths. When stuck, it backtracks along its path. The visited set prevents revisiting cells.

5. **Wall Mutation**: A timer periodically picks a random wall and rotates it by 90 degrees, flipping its diagonal direction. This makes the maze evolve over time while the ant navigates.

6. **Path Visualization**: The ant's path is drawn as a glowing `ImmediateMesh` line strip in the ZY plane, updated every frame.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cell_size` | float | 1.0 | Size of each maze cell |
| `wall_height` | float | 2.0 | Height of wall geometry |
| `grid_width` | int | 10 | Number of columns in the maze |
| `grid_depth` | int | 10 | Number of rows in the maze |
| `wall_thickness` | float | 0.1 | Thickness of wall strokes |
| `show_marker_disks` | bool | false | Show start/exit markers |
| `ant_speed` | float | 5.0 | Movement speed of the ant |
| `ant_size` | float | 0.3 | Radius of the ant sphere |
| `ant_color` | Color | Red | Color of the ant |
| `path_color` | Color | (1.0, 0.5, 0.0) | Color of the path trail |
| `wall_color` | Color | (0.9, 0.95, 1.0) | Color of maze strokes |
| `wall_change_interval` | float | 0.2 | Seconds between random wall rotations |

## Features

- Classic 10 PRINT algorithm rendered as 3D standing walls
- Ant pathfinder with greedy heuristic and backtracking
- Real-time path visualization as a glowing line strip
- Dynamic maze mutation -- walls randomly flip their diagonal at a configurable interval
- Configurable grid size, ant speed, and visual colors
- Emissive unshaded materials for the maze strokes and path

## Files

| File | Description |
|------|-------------|
| `ten_print_maze.gd` | Main script -- maze generation, navigation grid, ant AI, wall mutation |
| `ten_print_maze_3d.tscn` | Scene file |
