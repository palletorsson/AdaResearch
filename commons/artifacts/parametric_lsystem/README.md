# Parametric L-System

Generates branching plant structures using L-system string rewriting with continuously decaying parameters. Unlike discrete rule-based L-systems, the branch angle and segment length decay smoothly at each depth level, producing naturalistic trees and organic forms.

## How It Works

Starting from an axiom string, production rules are applied iteratively to generate a long instruction string. A 3D turtle interpreter then walks the string: "F" draws a line segment forward, "+" and "-" rotate by the branch angle (with random variation), and "["/"]" push/pop the turtle state to create branches. The key parametric feature is that on each branch entry, both segment length and branch angle decay multiplicatively, so deeper branches become shorter and more tightly angled. Four built-in presets (Bushy Tree, Willow, Fern Spray, Coral Branch) demonstrate different growth patterns achievable by varying the rules, angles, and decay rates.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 1.2 |
| `trunk_color` | Color | (0.55, 0.35, 0.15) |
| `tip_color` | Color | (0.3, 0.8, 0.2) |
| `axiom` | String | "F" |
| `iterations` | int | 4 |
| `base_length` | float | 0.12 |
| `base_angle` | float | 25.7 |
| `length_decay` | float | 0.72 |
| `angle_variation` | float | 8.0 |
| `preset` | int | 0 |

## Features

- Four growth presets: Bushy Tree, Willow, Fern Spray, Coral Branch
- Parametric decay of length and angle per branch depth for organic shapes
- Random angle variation for natural-looking asymmetry
- Depth-based coloring from brown trunk to green tips
- Multi-pass line rendering for thicker branch appearance
- Automatic scaling and centering to fit display bounds
- Grid config support for preset, iterations, angle, decay, and variation

## Files

- `parametric_lsystem.gd` — Main script
- `parametric_lsystem.tscn` — Scene file
