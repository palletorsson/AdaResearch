# Random_Definition - Technical Tutorial

## Randomness in Code

### The RandomNumberGenerator Class
Godot provides a dedicated class for random number generation:

```gdscript
var rng = RandomNumberGenerator.new()
rng.randomize()  # Seeds with current time

# Core methods
var random_float = rng.randf()           # 0.0 to 1.0
var random_int = rng.randi_range(1, 10)  # 1 to 10 inclusive
var random_vec = Vector3(rng.randf(), rng.randf(), rng.randf())
```

This is **pseudo-random**: the sequence is deterministic given a seed. Same seed = same sequence.

### PRNG vs TRNG

**Pseudo-Random Number Generator (PRNG)**:
```gdscript
# Deterministic chaos - appears random but repeatable
var rng = RandomNumberGenerator.new()
rng.seed = 12345  # Fixed seed
print(rng.randf())  # Always prints same value: 0.695584
print(rng.randf())  # Always prints same value: 0.459239
```

**True Random Number Generator (TRNG)**:
- Uses physical entropy sources (thermal noise, radioactive decay)
- Not available in standard game engines
- Used for cryptography, not typically for games
- The RAND Corporation's 1955 book contained 1 million random digits from electronic noise

### Entropy Levels in Practice

```gdscript
# Low entropy: constant (one possible value)
var low_entropy = [1, 1, 1, 1, 1, 1, 1, 1]
# Predictable: next value will be 1
# Zero information gain from new sample

# Medium entropy: alternating pattern
var medium_entropy = [1, 0, 1, 0, 1, 0, 1, 0]
# Predictable pattern (period = 2)
# Some order, some variation

# High entropy: random
var high_entropy = []
for i in range(8):
    high_entropy.append(rng.randi_range(0, 1))
# No pattern, each value unpredictable
# Maximum information per sample
```

### The Dimensional Freedom Explosion

```gdscript
# Why high-dimensional randomness escapes algorithmic control
var bits = 8
var possible_states = pow(2, bits)  # 256 states for 1 byte

bits = 256
possible_states = pow(2, bits)  # ~10^77 states
# More states than atoms in the observable universe
# Even checking 1 state per nanosecond:
# - Age of universe: ~10^17 seconds
# - States checked: ~10^26
# - Fraction explored: 10^26 / 10^77 = 10^-51 (essentially zero)
```

This is why **cryptographic randomness** works: the search space is too vast to explore.

## Implementation Notes

### The entropy_axiom Interactable
Located at position (2,2) with height offset 1.5m and scale 0.9. This is a visualization object that demonstrates entropy concepts—likely showing the difference between ordered and disordered states.

### The trng_vs_prng Comparison
At position (4,12), this interactive element allows players to see the difference between:
- PRNG: Fast, repeatable, deterministic
- TRNG: Slow, unique, truly unpredictable

### The Random Number Book (1955)
The RAND Corporation's "A Million Random Digits with 100,000 Normal Deviates" was a landmark publication—random numbers generated from electronic noise and published in book form for scientific use before computers were ubiquitous.

```gdscript
# Historical context: before PRNGs, randomness was manual labor
# Scientists would look up random numbers in physical books
# The infrastructure of randomness was material, embodied, slow
```

### Grid Configuration
- `cube_size: 1.0` - Standard unit
- `gutter: 0.0` - No spacing
- `initial_tile_visibility: "hidden_except_corners"` - Progressive reveal
- `auto_reveal_on_entry: false` - Manual exploration

## Key Takeaway
Randomness in computing is almost always **pseudo-random**: deterministic algorithms that produce sequences statistically indistinguishable from true randomness. The "random" is a simulation, a performance of disorder within an ordered system. This mirrors the QFEP insight: systems oscillate between order and chaos, never fully one or the other.

## Axiom References
- `commons/context/clipboard/tutorial_text/entropy_axioms.md`
- `commons/context/clipboard/tutorial_text/info_randomness.md`
