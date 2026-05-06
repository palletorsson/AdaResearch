# Romanesco

Nature's fractal. Fibonacci spirals made edible.

## QFEP Connection

Romanesco broccoli is **QFEP embodied in biology**: the golden angle (137.5°) optimizes light capture (F-minimization), while recursive self-similarity creates infinite detail (λ edge). It's a vegetable that solved computational geometry through evolution.

## The Algorithm

1. Start with a central cone
2. Add buds in Fibonacci spirals (13 spirals by default)
3. Position each bud using the golden angle: 137.508°
4. Each bud is a smaller copy of the whole
5. Recurse to desired depth

## The Golden Angle

```
360° × (1 - 1/φ) = 360° × (1 - 0.618...) = 137.508°
```

This angle ensures no bud overlaps another — optimal packing discovered by evolution, rediscovered by Fibonacci in 1202.

## Properties

| Property | Value |
|----------|-------|
| Spiral count | Fibonacci numbers (8, 13, 21...) |
| Scaling factor | 1/φ ≈ 0.382 (golden ratio) |
| Golden angle | 137.508° |
| Self-similarity | Each bud is a miniature whole |

## Parameters

```gdscript
@export var growth_interval: float = 0.5     # Seconds between iterations
@export var max_depth: int = 4               # Recursion depth
@export var fibonacci_spiral_count: int = 13 # Spirals (Fibonacci number)
@export var base_cone_size: float = 1.0      # Initial size
@export var scale_factor: float = 0.382      # Golden ratio reduction
```

## Usage

```gdscript
$Romanesco.perform_growth_iteration()  # Single step
$Romanesco.reset()
```

## VR Experience

Watch the romanesco grow from a single bud into fractal complexity. The spirals emerge naturally — count them and you'll find Fibonacci numbers. This is mathematics you can (almost) eat.

## Files

- `romanesco.gd` — Fibonacci spiral cone generator
- `romanesco.tscn` — Scene setup
