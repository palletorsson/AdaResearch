# Fibonacci Pagoda

Architectural fractal using Fibonacci-scaled tiers — mathematical patterns expressed as pagoda architecture.

## QFEP Connection

The Fibonacci sequence appears throughout nature because it **optimizes packing and growth**. Pagodas taper according to structural necessity (F); using Fibonacci ratios connects that structure to deeper mathematical patterns (λ). The golden ratio (φ = 1.618...) emerges from F/E balance in biological systems.

## How It Works

```
        ╱╲
       ╱  ╲     ← Tier 8 (smallest)
      ╱────╲
     ╱      ╲   ← Tier 7
    ╱────────╲
   ╱          ╲ ← Tier 6
  ╱────────────╲
         ...
╱════════════════╲ ← Tier 1 (largest)

Scale follows inverse Fibonacci:
Tier N scale = base_scale / fib(N)
```

## Fibonacci Sequence

```
1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89...

Each number = sum of previous two
Ratio converges to φ (golden ratio) ≈ 1.618
```

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `num_tiers` | 8 | Number of levels |
| `base_scale` | 3.0 | Bottom tier size |
| `tier_height` | 1.2 | Vertical spacing |
| `roof_overhang` | 1.3 | Roof extension |
| `use_golden_ratio` | true | φ vs pure Fibonacci |

## Files

| File | Purpose |
|------|---------|
| `fibonacci_pagoda.gd` | Main generator |
| `pillarpart.tscn` | Individual tier component |

## Usage

```gdscript
var pagoda = preload("res://algorithms/fractals/pillar/fibonacci_pagoda.tscn").instantiate()
pagoda.num_tiers = 12
pagoda.use_golden_ratio = false  # Pure Fibonacci scaling
add_child(pagoda)
```

## VR Experience

Walk around the pagoda. Notice how each tier's scale relates to the others — not arbitrary, but mathematically determined. The tapering feels natural because Fibonacci ratios appear throughout nature (pinecones, sunflowers, shells).

## Mathematical Notes

- **Golden ratio**: φ = (1 + √5) / 2 ≈ 1.618
- **Fibonacci convergence**: fib(n+1)/fib(n) → φ as n → ∞
- **Golden spiral**: Rectangle subdivision creates spiral

## Cultural Context

East Asian pagodas traditionally taper for structural stability. Using Fibonacci ratios connects this architectural form to mathematical patterns found in:
- Plant phyllotaxis (leaf arrangement)
- Shell spirals
- Galaxy arms
- Hurricane formation

## See Also

- `fractals/` — Other fractal structures
- `lsystems/` — Growth patterns
- `arrays/` — Mathematical constructions
