**Decay**
Time-Based Procedural Randomness

**Decay is entropy over time.** Order → disorder, structure → noise, signal → static.

**But decay is also generative** - it creates textures, atmospheres, organic patterns through progressive randomization.

---

## Exponential Decay

**Exponential decay:** Quantity decreases by constant *proportion* per time step (not constant *amount*).

**Code: Basic Decay**

```
# Exponential decay formula: N(t) = N₀ * e^(-λt)
# λ = decay constant (rate)
# N₀ = initial quantity
# t = time

var initial_value = 100.0
var decay_rate = 0.1  # 10% per second

func get_decayed_value(time: float) -> float:
    return initial_value * exp(-decay_rate * time)

# At t=0: 100
# At t=5: 100 * e^(-0.5) ≈ 60.7
# At t=10: 100 * e^(-1.0) ≈ 36.8
# At t=20: 100 * e^(-2.0) ≈ 13.5
```

**Half-life:** Time for quantity to reduce to 50%.
- t_half = ln(2) / λ ≈ 0.693 / λ
- For λ=0.1: t_half ≈ 6.93 seconds

**Properties:**
- Never reaches zero (asymptotic)
- Same proportional decrease per time step
- Memoryless (future decay doesn