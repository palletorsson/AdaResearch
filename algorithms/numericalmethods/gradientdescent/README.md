# Gradient Descent

Watch optimization happen — a ball rolling downhill on a mathematical landscape, seeking the lowest point.

## QFEP Connection

Gradient descent is **F-minimization made literal**. The free energy principle says systems minimize surprise/prediction error — gradient descent is the algorithm that does exactly this. Each step reduces the objective function (F), following the steepest path toward equilibrium. But beware local minima: sometimes order traps you.

## How It Works

```
┌──────────────────────────────────────────┐
│                                          │
│     Start (high F)                       │
│        ↓                                 │
│         ↘                                │
│           ↘                              │
│             ↘                            │
│               ↘                          │
│                 ↓                        │
│               Minimum (low F)            │
│                                          │
└──────────────────────────────────────────┘
```

The algorithm:
1. Evaluate function at current position
2. Compute gradient (direction of steepest increase)
3. Step in opposite direction (downhill)
4. Repeat until gradient ≈ 0

```
x_new = x_old - learning_rate × ∇f(x_old)
```

## Function Presets

| Preset | Description | Minima |
|--------|-------------|--------|
| **Quadratic Bowl** | x² + y² | Single global minimum at (0,0) |
| **Rosenbrock Valley** | Banana-shaped valley | Hard to optimize, tests algorithms |
| **Himmelblau Function** | Multiple local minima | Tests global vs local optimization |

## Parameters

### Optimization
| Export | Default | Description |
|--------|---------|-------------|
| `objective_function` | "x^2 + y^2" | Function to minimize |
| `initial_position` | (3.0, 2.0) | Starting point |
| `learning_rate` | 0.1 | Step size (α) |
| `tolerance` | 0.001 | Convergence threshold |
| `max_iterations` | 50 | Maximum steps |
| `iteration_speed` | 1.0 | Seconds between steps |

### Visualization
| Export | Default | Description |
|--------|---------|-------------|
| `surface_resolution` | 100 | Mesh detail |
| `x_range` / `y_range` | (-5, 5) | Domain bounds |
| `z_scale` | 2.0 | Vertical exaggeration |
| `show_gradient_vectors` | true | Display gradient arrows |
| `show_path_trail` | true | Show descent history |
| `animate_descent` | true | Step-by-step animation |

## Files

| File | Purpose |
|------|---------|
| `gradient_descent_visualization.tscn` | Scene |
| `gradient_descent_visualization.gd` | Optimization logic and visualization |

## Usage

```gdscript
var gd = preload("res://algorithms/numericalmethods/gradientdescent/gradient_descent_visualization.tscn").instantiate()
gd.learning_rate = 0.05  # Smaller steps
gd.function_preset = "Rosenbrock Valley"
add_child(gd)
```

## Learning Rate

The learning rate (α) is crucial:
- **Too small**: Takes forever to converge
- **Too large**: Overshoots, oscillates, or diverges
- **Just right**: Smooth descent to minimum

This is a core challenge in machine learning — finding good hyperparameters.

## VR Experience

Stand above the optimization landscape and watch the marker descend. The surface is the function's graph, the gradient arrows show the local slope, and the trail shows the path taken. Try different starting positions to see how initial conditions affect the result.

## Educational Value

Gradient descent underlies:
- **Machine learning**: Training neural networks
- **Physics**: Energy minimization
- **Economics**: Utility maximization
- **Biology**: Fitness landscapes

Understanding this algorithm unlocks intuition for optimization across domains.

## See Also

- `machinelearning/` — Gradient descent for neural nets
- `optimization/` — Other optimization methods
- `chaos/` — When optimization landscapes have fractal basins
