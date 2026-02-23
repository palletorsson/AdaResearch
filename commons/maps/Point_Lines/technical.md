# Point Lines - Technical Tutorial

Point_Lines expands the line primitive into system behavior.

## From Single Relation to Rule Set

A single line relation is local. Multiple lines require constraints:

- parallelism (shared direction)
- perpendicularity (orthogonal relation)
- proportional scaling
- projection/perspective convergence

## Constraint Example: Parallel Lines

```gdscript
var a0: Vector3
var a1: Vector3
var b0: Vector3
var b1: Vector3

var dir_a: Vector3 = (a1 - a0).normalized()
var dir_b: Vector3 = (b1 - b0).normalized()
var parallel_score: float = abs(dir_a.dot(dir_b))
# close to 1.0 => near parallel
```

Puzzle artifacts operationalize this by letting players drag endpoints until constraints are satisfied.

## Measurement Lane Pattern

Rows 12-14 pair visual line segments with measurement devices:

- line object for geometric relation
- laser measure for numeric distance readout
- stepped cube scale references

This dual channel (visual + numerical) helps anchor metric intuition.

## Perspective and Scale

Late-map artifacts (`perspective_lines`, `scale_lines`, `dgrid`) shift from local line editing to representational systems where lines organize how space is read.

## Implementation Notes

- Keep interactable rows dimension-consistent across all layers.
- Prefer explicit artifact staging zones over dense clustering.
- Validate map grammar after any placement edits.

## Key Takeaway

Point_Lines is where lines stop being isolated edges and become a framework for indexing, measuring, and projecting space.
