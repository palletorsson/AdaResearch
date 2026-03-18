# Snap Point Puzzles

Tag-based snap point puzzles with state machine validation.

## Files

- `snap_point_puzzle_base.gd`: base class with PuzzleState enum (BUILDING → VALIDATING → LOCKED → COMPLETED)
- `octahedron_puzzle.gd`, `pyramid_puzzle.gd`, `tetrahedron_puzzle.gd`, `triangle_puzzle.gd`: shape variants
- Matching `.tscn` files
- `PUZZLE_TAG_SYSTEM.md`: tag system documentation

## Behavior

- Tag system triggers obstacle/reward actions on completion.
- Auto-hide tagged objects when puzzle completes.
- Locked material applied to completed puzzles.
- Configurable success message and reset timer.
