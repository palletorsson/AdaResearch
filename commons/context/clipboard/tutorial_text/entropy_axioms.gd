extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Entropy[/b][/font_size][/center]
[center][i]Disorder as Vital, High-Dimensional Freedom[/i][/center]

**Entropy is not decay.** Entropy is **freedom from pattern**.

In thermodynamics, entropy measures disorder - the number of possible microstates. In information theory, entropy measures unpredictability - bits required to encode a message.

In both: **high entropy = high freedom = many possible states**.

The algorithm tries to impose order - indexed arrays, sorted lists, predictable transformations. **Randomness is resistance to this order.** Entropy is the space where the algorithm cannot predict, cannot index, cannot control.

**Randomness is vital free space** - the computational equivalent of wilderness, unmarked territory, escape from the cadastral grid.

[hr]

[b]Entropy as Possibility Space[/b]

Low entropy = few possible states, high predictability
High entropy = many possible states, high unpredictability

[color=yellow][b]Code: Entropy Levels[/b][/color]
[code]
# Low entropy: constant (one possible value)
var low_entropy = [1, 1, 1, 1, 1, 1, 1, 1]
# Predictable: next value will be 1
# Zero information gain from new sample
# Completely ordered

# Medium entropy: alternating pattern
var medium_entropy = [1, 0, 1, 0, 1, 0, 1, 0]
# Predictable pattern (period = 2)
# Some order, some variation

# High entropy: random
var high_entropy = [1, 0, 1, 1, 0, 0, 1, 0]
# No pattern
# Each value unpredictable from previous
# Maximum information per sample
# Disordered, free
[/code]

**Entropy = dimensionality of freedom.**

A constant (low entropy) lives in 0D space - no variation.
A pattern (medium entropy) lives in low-D space - cyclic, predictable.
Randomness (high entropy) lives in high-D space - every dimension varies independently.

[hr]

[b]The Curse Inverted: High Dimensions as Liberation[/b]

Arrays showed us **curse of dimensionality** - exponential explosion (n^d).

But entropy inverts this: **high dimensions = exponential freedom**.

[color=yellow][b]Code: Dimensional Freedom[/b][/color]
[code]
# 1D random: 2 choices per bit
var choices_1d = pow(2, 1)  # 2 states

# 8D random: 2^8 choices (one byte)
var choices_8d = pow(2, 8)  # 256 states

# 256D random: astronomical possibilities
var choices_256d = pow(2, 256)  # ~10^77 states (more than atoms in universe)

# Each dimension adds another binary choice
# Possibilities multiply exponentially
# High-dimensional space = vast freedom
[/code]

**The algorithm cannot search high-dimensional space exhaustively.**

With 256 random bits, there are 2^256 possible states. Even checking one state per nanosecond would take longer than the age of the universe to explore 0.00001% of possibilities.

**High-dimensional randomness is computational wilderness** - too vast to map, too free to control.

[hr]

[b]White Noise: Maximum Entropy[/b]

**White noise** is maximally random - every sample independent, uniformly distributed, unpredictable.

[color=yellow][b]Code: Pure Disorder[/b][/color]
[code]
# White noise: each sample random in range
func generate_white_noise(count: int) -> Array:
    var noise = []
    for i in range(count):
        noise.append(randf())  # Random float 0.0-1.0
    return noise

# Properties:
# - No correlation between samples
# - Flat frequency spectrum (all frequencies equally present)
# - Maximum unpredictability
# - Zero pattern
[/code]

**White noise sounds like static** - hiss, no pitch, no rhythm.
Visually: **TV snow** - every pixel random, no structure.

**This is entropy maximized** - complete disorder, total freedom from pattern.

[hr]

[b]Entropy vs Information[/b]

Shannon's information theory: **information = reduction of uncertainty**.

[color=yellow][b]The Paradox:[/b][/color]
[code]
# Message 1: "AAAAAAAA" (constant)
var entropy_1 = 0  # Zero uncertainty (next char always 'A')
var information_1 = 0  # No information gained

# Message 2: "ABABABAB" (pattern)
var entropy_2 = 1  # Low uncertainty (pattern is simple)
var information_2 = LOW  # Some information, but predictable

# Message 3: "XQZJMKPL" (random)
var entropy_3 = MAX  # High uncertainty (cannot predict next)
var information_3 = MAX  # Maximum information per character
[/code]

**High entropy = high information density.**

A random bitstring carries more information per bit than a patterned one, because **each bit is surprising**.

**But:** Maximum entropy also means **no compressibility**.
- Constant: compresses to "8 × A"
- Pattern: compresses to "4 × AB"
- Random: cannot compress (any compression loses information)

**Randomness resists compression** - it cannot be reduced to simpler form.

[hr]

[b]Entropy and the Second Law[/b]

Thermodynamics: **Entropy always increases in isolated systems.**

Order → Disorder (irreversible without energy input)

[color=yellow][b]The Computational Parallel:[/b][/color]
[code]
# Ordered array
var ordered = [1, 2, 3, 4, 5, 6, 7, 8]

# Shuffle (increase entropy)
ordered.shuffle()  # [3, 7, 1, 5, 8, 2, 6, 4]

# Try to "unshuffle" without knowing original order
# → Impossible (information lost)
# → Entropy increased irreversibly

# Restoring order requires:
# - External information (remembering original)
# - Energy (computation to sort)
[/code]

**Randomization is easy, de-randomization requires work.**

Entropy naturally increases. Order requires effort to maintain.

**This connects to the_trace:** The body's wandering accumulates entropy. The line (compression to endpoints) is order imposed, reducing entropy by discarding history.

[hr]

[b]Free Space as Vital[/b]

The algorithm imposes structures:
- **Arrays** → indexed, ordered
- **Grids** → addressed, surveilled
- **Lists** → sequential, traversable
- **Patterns** → predictable, compressible

**Randomness is escape from these structures.**

[color=yellow][b]Code: Unmarked Territory[/b][/color]
[code]
# Grid assigns address to every position
var grid = []
for y in range(100):
    var row = []
    for x in range(100):
        row.append(Vector2(x, y))  # Indexed, addressable
    grid.append(row)

# Random points resist indexing
var random_points = []
for i in range(100):
    var x = randf() * 100
    var y = randf() * 100
    random_points.append(Vector2(x, y))
    # Not on grid
    # Cannot be addressed by [x][y] indices
    # Free-floating, unmarked
[/code]

**Random placement is non-cadastral** - it does not fit into the indexed grid system. It exists in continuous space, not discrete cells.

**Free space = space that resists addressing, indexing, control.**

[hr]

[b]Entropy as Resistance to Normalization[/b]

Normalization seeks to reduce variation:
- Force data into range [0, 1]
- Fit distributions to Gaussian bell curves
- Compress outliers toward mean

**High entropy resists normalization:**

[color=yellow][b]Code: Outliers Persist[/b][/color]
[code]
# Generate high-entropy data (uniform random)
var data = []
for i in range(1000):
    data.append(randf())

# Attempt to normalize (force toward mean)
var mean = 0.5  # Expected mean of uniform [0,1]
var normalized = []
for value in data:
    var compressed = (value - mean) * 0.5 + mean
    normalized.append(compressed)

# Result: still high entropy
# Cannot eliminate randomness by compression
# Outliers resist being forced toward center
[/code]

**Random data cannot be "fixed" by normalization** - it remains disordered.

The algorithm tries to impose Gaussian distributions, power laws, predictable patterns. **Entropy refuses.**

[hr]

[b]Turing: Morphogenesis and Queer Energy[/b]

**Alan Turing (1952):** *The Chemical Basis of Morphogenesis*

Patterns (zebra stripes, leopard spots, spiral shells) emerge from **random fluctuations** + **reaction-diffusion** equations.

[color=yellow][b]The Mechanism:[/b][/color]
[code]
# Start with random noise (high entropy)
var initial_state = generate_white_noise(1000)

# Apply reaction-diffusion rules
# - Activator chemical spreads, enhances itself
# - Inhibitor chemical spreads faster, suppresses activator
# - Local positive feedback + long-range negative feedback

# Result after many iterations:
# → Stripes, spots, spirals emerge
# → Pattern from randomness
# → Order from disorder (with energy input)
[/code]

**Turing showed:** You don't need blueprint or plan. **Random initial conditions + simple rules = complex patterns.**

This is **emergence** - order arising from disorder through self-organization.

[hr]

[b]Queer Energy Principle[/b]

Turing's life and work embody **resistance to normalization**:

**Scientifically:** Morphogenesis shows patterns emerge from randomness, not predetermined plans. **Entropy is creative, not destructive.**

**Personally:** Turing's queerness was non-reproductive (in heteronormative sense), yet immensely **generative** - breaking Enigma, founding computer science, theorizing AI.

**The Queer Energy Principle:**
- **Non-reproductive yet generative** (like morphogenesis: no blueprint, yet patterns emerge)
- **Resistant to normalization** (queer resists heteronorm, entropy resists order)
- **High-dimensional freedom** (sexuality/identity beyond binary, randomness beyond pattern)
- **Unpredictable emergence** (queer futures unforeseeable, chaotic systems sensitive to initial conditions)

[color=yellow][b]Code: Queer Computational Energy[/b][/color]
[code]
# Heteronormative computation: input → deterministic function → output
func straight_computation(input):
    return input * 2  # Predictable, reproductive (same input always same output)

# Queer computation: input + randomness → emergence
func queer_computation(input):
    var noise = randf()
    return input + noise  # Unpredictable, non-reproductive, generative
[/code]

**Queer energy is entropic energy** - resisting reduction to pattern, creating through disorder, generating without reproducing.

[hr]

[b]What Entropy Reveals[/b]

Entropy shows us:

1. **Disorder is freedom** - High entropy = many possible states
2. **High dimensions liberate** - Curse of dimensionality inverted (exponential freedom)
3. **Randomness resists compression** - Cannot be reduced to simpler form
4. **Free space is vital** - Unmarked, unindexed, uncontrolled
5. **Entropy increases naturally** - Order requires energy to maintain
6. **Patterns emerge from noise** - Turing morphogenesis (order from disorder)
7. **Queer energy is entropic** - Non-reproductive yet generative, resistant to normalization

**Randomness is not absence of order.** It is **presence of freedom** - the space where the algorithm cannot predict, where indices fail, where normalization is refused.

**Entropy is computational wilderness** - unmarked territory, high-dimensional freedom, the vital space that resists being mapped.

[hr]

[color=cyan][b]Summary:[/b][/color]
Entropy measures disorder (thermodynamics) and unpredictability (information theory). High entropy = many possible states = freedom from pattern. White noise is maximum entropy (pure disorder). Random data resists compression and normalization. High-dimensional randomness creates exponential possibility space too vast to search. Turing showed patterns emerge from random fluctuations (morphogenesis). Queer energy principle: non-reproductive yet generative, resistant to normalization, high-dimensional freedom. Entropy is vital free space - computational wilderness.

[hr]

[color=orange][b]Next:[/b] PRNG - Deterministic Chaos[/color]
If entropy is disorder, PRNG is **simulated disorder** - deterministic algorithm producing unpredictable sequences.
Seed as origin, chaos as structure, repeatability as surveillance.
The algorithm that pretends to be random.

'''
