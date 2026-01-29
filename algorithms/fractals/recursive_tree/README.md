# Recursive Tree (Static/Styled)

Sculptural trees with color and form control.

## QFEP Connection

This variant emphasizes **aesthetic control** over the branching process. The tree is generated all at once (not animated), allowing precise color palettes and form. Same recursive mathematics, different artistic intent.

## Features

- **Instant generation** — full tree created at once
- **Color control** — primary, secondary, and trunk colors
- **Seed-based** — reproducible results with `random_seed`
- **Inverted variant** — tree growing downward (cloud/root form)

## Parameters

```gdscript
# Structure
@export var num_main_branches := 5
@export var max_sub_branches := 4
@export var branch_length_min := 1.5
@export var branch_length_max := 4.0
@export var trunk_height := 5.0
@export var trunk_width := 1.5
@export var random_seed := 42

# Appearance
@export var primary_color := Color(0.95, 0.3, 0.3)   # Main branch color
@export var secondary_color := Color(0.85, 0.2, 0.2) # Variation
@export var trunk_color := Color(0.8, 0.3, 0.3)
```

## Variants

| File | Description |
|------|-------------|
| `recursive_tree.gd` | Standard upward tree |
| `inverted_tree_cloud.gd` | Inverted (downward/root) form |
| `RecursiveTreeUI.gd` | UI controls for parameters |

## Files

- `recursive_tree.gd` — Main generation algorithm
- `inverted_tree_cloud.gd` — Inverted variant
- `RecursiveTreeUI.gd` — Parameter UI
