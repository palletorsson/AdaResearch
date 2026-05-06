# Fine-Tuning

Interactive VR visualization of transfer learning and layer freezing — walk through a neural network tower and control which layers are trainable.

## QFEP Connection

Fine-tuning is **selective plasticity**. Frozen layers preserve learned features (F, stable knowledge); unfrozen layers adapt to new data (E, learning). The `num_frozen_layers` parameter controls this boundary. Transfer learning asks: what should stay fixed, and what should change? λ as the freeze/thaw boundary.

## How It Works

```
Layer 10 ═══ [UNFROZEN] ← Adapts to new task
Layer  9 ═══ [UNFROZEN] ← Adapts to new task
Layer  8 ═══ [UNFROZEN] ← Adapts to new task
Layer  7 ═══ [UNFROZEN] ← Adapts to new task
─────────────── FREEZE LINE ───────────────
Layer  6 ══● [FROZEN]   ← Preserves features
Layer  5 ══● [FROZEN]   ← Preserves features
Layer  4 ══● [FROZEN]   ← Preserves features
Layer  3 ══● [FROZEN]   ← Preserves features
Layer  2 ══● [FROZEN]   ← Preserves features
Layer  1 ══● [FROZEN]   ← Preserves features
```

Gradients flow backward only through unfrozen layers.

## Parameters

### VR Scale
| Export | Default | Description |
|--------|---------|-------------|
| `layer_height` | 1.2 | Vertical spacing |
| `layer_radius` | 1.5 | Layer disc radius |
| `num_layers` | 10 | Total network depth |
| `lock_size` | 0.25 | Lock control size |

### Training
| Export | Default | Description |
|--------|---------|-------------|
| `auto_train` | true | Continuous training |
| `training_speed` | 0.15 | Loss decrease rate |
| `num_frozen_layers` | 6 | Initially frozen count |
| `show_gradient_flow` | true | Visualize backprop |

### Interaction
| Export | Default | Description |
|--------|---------|-------------|
| `enable_layer_locking` | true | Grabbable locks |
| `enable_data_throwing` | true | Throw data samples |
| `show_activation_flow` | true | Forward pass particles |
| `learning_rate_control` | true | Per-layer LR sliders |

## Components

- **Layer discs**: Cylindrical platforms representing network layers
- **Lock objects**: Grabbable controls to freeze/unfreeze
- **Activation particles**: Forward pass visualization
- **Gradient particles**: Backward pass visualization
- **Info panels**: Loss curves, layer states

## Files

| File | Purpose |
|------|---------|
| `fine_tuning.gd` | Main controller |
| `fine_tuning.tscn` | VR scene |

## Usage

```gdscript
var ft = preload("res://algorithms/machinelearning/fine_tuning/fine_tuning.tscn").instantiate()
ft.num_layers = 12
ft.num_frozen_layers = 8  # More frozen
add_child(ft)
```

## VR Experience

Stand inside a vertical tower of neural network layers. Grab locks to freeze/unfreeze layers — watch how gradient flow stops at frozen boundaries. Throw training data in and watch activations propagate up; see gradients flow back down (but only through unfrozen layers). The loss curve shows training progress.

## Transfer Learning Concept

1. **Pre-train** on large dataset (ImageNet, etc.)
2. **Freeze** early layers (generic features)
3. **Unfreeze** later layers (task-specific features)
4. **Fine-tune** on small target dataset

Early layers learn edges, textures (reusable); late layers learn class-specific features (need adaptation).

## See Also

- `neuralnetworks/` — Network architecture visualization
- `numericalmethods/gradientdescent/` — Optimization visualization
- `neuroevolution/` — Alternative learning method
