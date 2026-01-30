# Central Limit Theorem

Interactive visualization showing how sample means converge to a normal distribution — regardless of the original population's shape.

## QFEP Connection

The CLT is **order emerging from any chaos**. Start with uniform, exponential, bimodal — any distribution (E). Take enough samples, average them, and the result is always Gaussian (F). This is statistical alchemy: diversity becoming bell curves through aggregation.

## How It Works

```
Population (any shape)          Sample Means (always normal)
┌──────────────────────┐        ┌──────────────────────┐
│ ████████████████████ │        │                      │
│ ████████████████████ │   →    │         ▄▄▄         │
│ ████████████████████ │ sample │       ▄████▄       │
│ ████████████████████ │ + avg  │     ▄████████▄     │
│ ████████████████████ │        │   ▄████████████▄   │
└──────────────────────┘        └──────────────────────┘
      UNIFORM                         NORMAL
```

1. Generate population from any distribution
2. Take random samples of size n
3. Compute mean of each sample
4. Plot distribution of sample means
5. Watch it become Gaussian!

## Population Types

| Type | Shape | Description |
|------|-------|-------------|
| **Uniform** | Flat rectangle | Equal probability everywhere |
| **Exponential** | Right-skewed decay | Common in wait times |
| **Bimodal** | Two peaks | Two distinct subgroups |
| **Skewed** | Asymmetric | Long tail on one side |
| **Discrete** | Bars | Integer values only |

## Parameters

### Population
| Export | Default | Description |
|--------|---------|-------------|
| `population_type` | UNIFORM | Starting distribution |
| `population_size` | 10000 | Population count |
| `population_min/max` | 0-10 | Value range |

### Sampling
| Export | Default | Description |
|--------|---------|-------------|
| `sample_size` | 30 | n per sample (≥30 recommended) |
| `num_samples` | 100 | Total samples to take |
| `auto_sample` | false | Continuous sampling |

### Visualization
| Export | Default | Description |
|--------|---------|-------------|
| `show_population` | true | Display original distribution |
| `show_sample_means` | true | Display means distribution |
| `animation_speed` | 1.0 | Sampling animation rate |

## Files

| File | Purpose |
|------|---------|
| `CentralLimitTheoremVR.gd` | Main visualization |

## Usage

```gdscript
var clt = preload("res://algorithms/statistics/04_central_limit_theorem/CentralLimitTheoremVR.tscn").instantiate()
clt.population_type = CentralLimitTheoremVR.PopulationType.EXPONENTIAL
clt.sample_size = 50
add_child(clt)
```

## The Theorem

For samples of size n from any distribution with mean μ and variance σ²:

```
Sample Mean ~ Normal(μ, σ²/n)
```

As n increases:
- Distribution becomes more normal
- Variance decreases (more precise estimates)
- Shape converges faster for symmetric populations

## VR Experience

Watch samples being drawn from the population, their means computed, and the sampling distribution grow. Start with a bizarre population shape — uniform, bimodal, whatever — and observe as the sample means form a bell curve. It's mathematical magic made visible.

## Educational Value

CLT is foundational because:
- **Confidence intervals** assume normality of sample means
- **Hypothesis testing** relies on this convergence
- **Real-world data** is often averaged (sums of many factors)
- Explains why normal distributions appear everywhere

## See Also

- `randomness/distributions/` — Probability distributions
- `statistics/` — Other statistical concepts
- `randomness/random_bell_curve/` — Gaussian terrain
