# L-System Tree

A deterministic L-system tree using the classic plant production rule F -> F[+F]F[-F]F. This teaches how simple recursive string rewriting can generate natural-looking branching structures, a foundational concept in procedural generation and computational botany.

## How It Works

Starting from the axiom "F", the rule F -> F[+F]F[-F]F is applied iteratively. The resulting string is interpreted by a turtle: "F" draws a line segment forward, "+" and "-" rotate by the branching angle (25.7 degrees), and brackets "[" / "]" push and pop the turtle state to create branches. Branch length decreases by 28% at each depth level, producing a natural tapering effect. Segments are colored on a brown-to-green gradient based on depth, simulating trunk-to-leaf transitions.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 0.6 |
| `trunk_color` | Color | (0.45, 0.28, 0.12) |
| `tip_color` | Color | (0.2, 0.65, 0.15) |
| `iterations` | int | 4 |
| `base_angle` | float | 25.7 |
| `base_length` | float | 0.1 |

## Features

- Classic L-system plant rule with deterministic branching
- Depth-based color gradient from brown trunk to green tips
- Branch length reduction (72% per depth level) for natural tapering
- Auto-scaling and bottom-center anchoring so the tree grows upward
- Info label showing rule, iteration count, angle, and segment count
- Rendered with ImmediateMesh line primitives for efficient drawing

## Files

- `lsystem_tree.gd` -- Main script
- `lsystem_tree.tscn` -- Scene file
