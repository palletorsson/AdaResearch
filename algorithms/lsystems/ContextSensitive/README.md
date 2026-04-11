# Context-Sensitive Tree -- Obstacle-Aware L-System

An L-System tree generator that uses **physics raycasting** to detect obstacles and prune branches that would collide, creating context-sensitive growth behavior. Branches that hit obstacles are drawn as short red stubs rather than continuing to grow.

## Concept Taught

**Context-sensitive L-Systems and environment-aware growth.** Traditional L-Systems are purely formal -- they rewrite strings without knowledge of the spatial result. Context-sensitive L-Systems extend this by letting the environment influence which production rules are applied. This artifact demonstrates the concept by performing physics raycasts along each branch segment: if a branch would penetrate an obstacle, it is pruned (marked as "dead") and rendered as a red stub. All sub-branches of a dead branch are also pruned, modeling how real trees redirect growth away from physical barriers.

## How It Works

1. An L-System is initialized with the `fractal_plant` preset rules via `LSystem.create_fractal_plant()`.
2. Obstacle bodies (semi-transparent violet boxes) are placed in the tree's growth space as `StaticBody3D` nodes with collision shapes.
3. The L-System string is generated for the configured number of iterations.
4. During interpretation, each `F` (forward) command performs a **physics raycast** from the current cursor position to the projected endpoint using `PhysicsDirectSpaceState3D.intersect_ray()`.
5. If the ray hits an obstacle:
   - The branch is marked as `is_dead = true`.
   - A short red stub (20% length) is drawn to indicate pruning.
   - The cursor advances to the endpoint but no full branch is drawn.
   - All subsequent branches in the same bracket scope remain dead.
6. When a `]` (pop state) command is reached, the dead state is restored from the context stack, allowing sibling branches to grow normally.
7. Leaves (`L` command) are only created on living branches.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `iterations` | int | 5 | Number of L-System generation iterations |
| `step_length` | float | 0.12 | Length of each forward segment |
| `angle` | float | 25.0 | Branching angle in degrees |

Grid config support via `apply_grid_config()`:
- `iterations` -- override iteration count
- `angle` -- override branching angle

## Features

- Physics-based obstacle detection using raycasting per branch segment
- Dead branch propagation through bracket scoping -- pruning cascades to sub-branches
- Red stub visualization for pruned branches (20% of normal length)
- Context stack tracks dead/alive state across branch push/pop operations
- Semi-transparent violet obstacle blocks for clear visibility
- Full turtle graphics interpretation: forward, turn, pitch, roll, push/pop, leaf
- Info label and pedestal decorations
- Grid config integration for map-based parameter overrides

## Files

- `ContextSensitiveTree.gd` -- Context-sensitive L-System interpreter with physics raycasting
- `ContextSensitiveTree.tscn` -- Scene file
