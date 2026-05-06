# Constraint Solvers

Procedural generation via constraint satisfaction — WFC, SAT, and rule-based systems.

## QFEP Connection

Constraint solving is **negotiated order**. Rules define what's allowed (F); the solver finds configurations that satisfy all rules (E within F). Backtracking explores possibilities; propagation eliminates contradictions. λ as the search through possibility space.

## Methods

- **WFC (Wave Function Collapse)**: Tile adjacency constraints
- **Boolean patterns**: Logical constraint satisfaction
- **Rule-based systems**: Grammar-like generation

## See Also

- `wfc/` — Dedicated WFC implementation
- `grammar_systems/` — Grammar-based generation
