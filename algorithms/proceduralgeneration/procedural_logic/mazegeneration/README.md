# Maze Generation

A procedural maze generator using the recursive backtracking algorithm, with both a standard 3D version and a VR-optimized version featuring human-scale corridors, physical collision, and animated step-by-step generation. Includes a UI controller for live parameter tweaking and a debug script for collision testing.

## Concept Taught

**Recursive backtracking and graph traversal.** This artifact teaches one of the foundational algorithms in computer science: depth-first search with backtracking. The maze is a grid where every cell starts as a wall. The algorithm picks a starting cell, marks it as visited, and repeatedly moves to a random unvisited neighbor -- carving a passage by removing the wall between them. When it reaches a dead end (no unvisited neighbors), it backtracks along the stack to find unexplored branches. The animated generation makes the algorithm visible: students watch the red "current cell" probe forward, turn green when visited, and retreat when stuck. The result is a perfect maze -- exactly one path between any two points, with no loops and no unreachable areas.

## How It Works

1. The grid is initialized with all cells as walls. Path cells are placed at every odd coordinate (1,1), (1,3), (3,1), etc.
2. Generation starts at cell (1,1). The cell is marked visited and pushed onto a stack.
3. Each step, the algorithm checks for unvisited neighbors two cells away (to skip the wall between cells):
   - If neighbors exist, one is chosen at random. The wall between the current cell and the chosen neighbor is removed. The current cell is pushed onto the stack, and the algorithm moves to the neighbor.
   - If no neighbors exist, the algorithm pops the stack and backtracks.
4. Generation ends when the stack is empty -- every reachable cell has been visited.
5. An entrance is opened at the top and an exit at the bottom, marked with special colors.
6. The VR version adds human-scale corridors (2m wide, 2.8m tall walls), proper floor and ceiling geometry, collision bodies for all walls, glowing entrance/exit markers, and lighting.

## Parameters

### Standard Version (maze_generator.gd)

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `maze_width` | int | 9 | Grid width (should be odd) |
| `maze_height` | int | 9 | Grid height (should be odd) |
| `cell_size` | float | 1.0 | World-space size of each cell |
| `wall_height` | float | 1.0 | Height of wall blocks |
| `generation_speed` | float | 0.2 | Seconds between generation steps |
| `wall_color` | Color | (0.4, 0.4, 0.6) | Wall block color |
| `path_color` | Color | (0.8, 0.8, 0.9) | Floor/path color |
| `current_color` | Color | (0.9, 0.3, 0.3) | Current cell highlight (red) |
| `visited_color` | Color | (0.3, 0.9, 0.3) | Visited cell color (green) |
| `show_generation` | bool | true | Animate the generation process |

### VR Version (maze_generator_vr.gd)

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `maze_width` | int | 15 | Grid width |
| `maze_height` | int | 15 | Grid height |
| `cell_size` | float | 2.0 | Corridor width in meters |
| `wall_height` | float | 2.8 | Wall height (above head) |
| `wall_thickness` | float | 0.3 | Visual wall inset |
| `generation_speed` | float | 0.05 | Fast generation speed |
| `entrance_color` | Color | (0.3, 0.8, 0.3) | Green entrance marker |
| `exit_color` | Color | (0.8, 0.3, 0.3) | Red exit marker |
| `add_ambient_light` | bool | true | Add directional lighting |

## Features

- Recursive backtracking produces perfect mazes (exactly one solution path)
- Animated step-by-step generation visualizes the DFS algorithm in action
- Full collision system: StaticBody3D with BoxShape3D for every wall and floor cell
- Walls are removed dynamically during generation, updating both visuals and collision
- VR-optimized version with human-scale corridors, floor, lighting, and entrance/exit markers
- Instant generation mode skips animation for immediate use
- Regeneration support with keyboard shortcuts (R = regenerate, G = animated, I = instant)
- UI controller allows live adjustment of width, height, and speed
- Debug script provides per-position collision queries and maze info
- Utility functions: `is_wall_at_position()`, `is_floor_at_position()`, `get_maze_string()`
- Helper methods for VR: `get_entrance_position()`, `get_exit_position()`, `get_maze_center()`

## Files

| File | Purpose |
|------|---------|
| `maze_generator.gd` | Standard 3D maze with animated generation, wall/floor collision, and debug utilities |
| `maze_generator_vr.gd` | VR-optimized maze with human-scale corridors, lighting, markers, and instant generation |
| `MazeUI.gd` | Control panel for adjusting maze width, height, and speed at runtime |
| `maze_debug_collision.gd` | Debug CharacterBody3D for testing collision detection at any position in the maze |
