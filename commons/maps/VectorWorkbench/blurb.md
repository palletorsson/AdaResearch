Universal sandbox for exploring vector operations.

## What It Shows

Two draggable vectors (A and B) with ALL operations computed live:
- **A + B** (yellow) — Vector addition
- **A - B** (purple) — Vector subtraction
- **A · B** — Dot product with angle
- **A × B** (green) — Cross product
- **proj_B(A)** (pink) — Projection of A onto B

## Visual Elements

- **Angle arc** between vectors (for dot product)
- **Parallelogram** showing cross product area
- **Info panel** with all computed values

## Controls

| Key | Action |
|-----|--------|
| 1 | Show all operations |
| 2 | Addition mode only |
| 3 | Dot product mode only |
| 4 | Cross product mode only |
| 5 | Projection mode only |
| R | Reset vectors |

## Why It Matters

Instead of separate scenes for each operation, the Workbench shows how they relate:
- Perpendicular vectors → dot product = 0
- Parallel vectors → cross product = 0
- Same vector → A - A = 0, A + A = 2A

Everything updates in real-time as you drag.
