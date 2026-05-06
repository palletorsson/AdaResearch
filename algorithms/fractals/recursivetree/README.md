# Recursive Tree (Animated)

Branching growth. Watch a tree emerge from nothing.

## QFEP Connection

Trees are **F through branching**: simple rules (split, angle, taper) create infinite complexity. Each branch is a smaller tree — self-similarity across scales. The randomness parameter controls λ: deterministic (λ=0) vs organic chaos (λ=1).

## Features

- **Animated growth** — watch the tree grow branch by branch
- **Natural variation** — random angles within ranges
- **Tapering** — branches thin toward tips
- **Color gradient** — trunk to leaves coloring

## Parameters

```gdscript
@export var growth_interval: float = 0.3       # Seconds between growth steps
@export var max_depth: int = 10                # Recursion depth
@export var initial_branch_length: float = 2.0 # Trunk length
@export var initial_branch_thickness: float = 0.2
@export var length_reduction: float = 0.7      # Each level shorter
@export var thickness_reduction: float = 0.65  # Each level thinner
@export var branch_count: int = 3              # Branches per node
@export var branch_angle_min: float = 20.0     # Angle range
@export var branch_angle_max: float = 35.0
@export var add_randomness: bool = true        # Natural variation
@export var randomness_amount: float = 0.15    # Variation strength
```

## The Branching Rule

At each node:
1. Create `branch_count` new branches
2. Each branch: length × `length_reduction`, thickness × `thickness_reduction`
3. Angle: random between `branch_angle_min` and `branch_angle_max`
4. Rotation around trunk: distributed + variation

## Files

- `recursive_tree.gd` — Animated branching algorithm
- `recursive_tree.tscn` — Scene setup
