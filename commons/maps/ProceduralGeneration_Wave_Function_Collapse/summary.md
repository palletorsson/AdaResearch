# Wave Function Collapse — Summary

## What You'll Learn

Wave Function Collapse (WFC) is a constraint-based procedural generation algorithm inspired by quantum mechanics. It generates coherent structures by:

1. **Starting in superposition** — Each cell can be any tile
2. **Selecting by entropy** — Choose the cell with fewest possibilities
3. **Collapsing** — Pick one state randomly
4. **Propagating** — Update neighbors based on adjacency rules
5. **Repeating** — Until all cells are determined (or contradiction)

## Key Concepts

### Entropy
In WFC, entropy = number of remaining possibilities. Low entropy cells are "almost decided" — we collapse these first to minimize contradictions.

### Constraint Propagation
When a cell collapses, its neighbors lose incompatible options. This propagates outward like a wave, sometimes triggering chain reactions.

### Adjacency Rules
The heart of WFC: which tiles can be next to which. These simple local rules produce globally coherent structures.

### Backtracking
Sometimes constraints lead to contradictions (a cell with zero possibilities). Good implementations backtrack and try again.

## Applications

- Procedural dungeons and levels
- Texture synthesis
- City generation
- Puzzle design
- Any domain with local compatibility rules

## QFEP Connection

WFC is **F (constraints) + E(S) (random selection) → emergence**. The rules are pure order; the collapse is entropy injection; the result is coherent complexity at the edge of chaos.
