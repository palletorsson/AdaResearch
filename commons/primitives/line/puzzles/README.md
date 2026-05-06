# Line Puzzles

Half-Life: Alyx-style holographic line puzzles with snap mechanics.

## Files

- `line_snap_puzzle_base.gd`: base class with validation, tag system, and state machine
- `cross_puzzle.gd`, `parallel_puzzle.gd`, `plus_puzzle.gd`, `quad_puzzle.gd`, `triangle_puzzle.gd`: puzzle shape variants
- Matching `.tscn` files for each

## Behavior

- Alyx-cyan color scheme.
- PuzzleState enum for validation flow.
- Tag system triggers obstacle/reward actions on completion.
- `lock_on_complete` freezes solved puzzles.
- Form constraints enforce valid line configurations.
