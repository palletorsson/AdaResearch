extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Randomness and the Queer Free Energy Principle[/b][/font_size][/center]
[center][i]Entropy as the E(S) Term Made Visible[/i][/center]

Randomness is not chaos in the pejorative sense. It is the **E(S) term** of the Queer Free Energy Principle—the entropy that systems need to survive, adapt, and create.

**QFE = F − λE(S) + φΔE(S,t)**

Where randomness appears:
- **E(S)** = system entropy (randomness is literally this)
- **λ** = how much the system values entropy (the entropy drive)
- **ΔE(S,t)** = rate of entropy change (continuous injection of novelty)

Without randomness, there is no adaptation. Without entropy, there is only crystallization.

[hr]

[b]The Three Terms and Randomness[/b]

The QFEP balances three forces. Randomness is central to two of them:

[color=yellow][b]F — Free Energy (Order)[/b][/color]
[code]
# F measures prediction error
# Lower F = better predictions = more order
# This term wants to MINIMIZE randomness

var prediction = model.predict(input)
var actual = observe(world)
var F = distance(prediction, actual)

# Pure F-minimization:
# - Seeks patterns, regularities
# - Imposes structure
# - Reduces surprise
# - Tends toward rigidity
[/code]

[color=yellow][b]E(S) — Entropy (Disorder)[/b][/color]
[code]
# E(S) measures system entropy
# Higher E(S) = more possible states = more randomness
# This term IS randomness

func calculate_entropy(distribution):
    var entropy = 0.0
    for probability in distribution:
        if probability > 0:
            entropy -= probability * log(probability)
    return entropy

# Pure E(S) maximization:
# - Seeks disorder, variety
# - Dissolves structure
# - Embraces surprise
# - Tends toward dispersal
[/code]

[color=yellow][b]λE(S) — The Entropy Drive[/b][/color]
[code]
# λ modulates how much entropy matters
# λ = 0: ignore entropy, pure order-seeking
# λ = 1: maximum entropy drive
# λ ≈ 0.3-0.5: edge of chaos (adaptive zone)

var lambda = 0.4  # Entropy drive coefficient

func compute_qfe():
    var F = compute_free_energy()
    var E_S = compute_entropy()

    # The balance:
    return F - lambda * E_S

    # Minimizing QFE means:
    # - Reduce prediction error (order)
    # - BUT maintain entropy (disorder)
    # - The λ term prevents crystallization
[/code]

**Randomness is what keeps systems alive.** Without E(S), the system would minimize F to zero—perfect prediction, total rigidity, death by crystallization.

[hr]

[b]The λ Parameter: Tuning Between Order and Chaos[/b]

Lambda (λ) is the dial between order-seeking and chaos-seeking:

[color=yellow][b]Code: Lambda Spectrum[/b][/color]
[code]
# λ = 0.0: Pure prediction (rigid order)
var system_rigid = {
    "lambda": 0.0,
    "behavior": "Seeks perfect patterns",
    "failure_mode": "Cannot adapt to change",
    "metaphor": "Crystal, bureaucracy, fundamentalism"
}

# λ = 0.3: Slight entropy drive (stable with flexibility)
var system_stable = {
    "lambda": 0.3,
    "behavior": "Mostly predictable, some variation",
    "failure_mode": "Can miss opportunities",
    "metaphor": "Institution, tradition, habit"
}

# λ = 0.5: Balanced (edge of chaos)
var system_adaptive = {
    "lambda": 0.5,
    "behavior": "Oscillates between explore and exploit",
    "failure_mode": "May seem inconsistent",
    "metaphor": "Jazz improvisation, evolution, queer existence"
}

# λ = 0.7: High entropy drive (creative chaos)
var system_creative = {
    "lambda": 0.7,
    "behavior": "Seeks novelty, resists routine",
    "failure_mode": "Difficulty maintaining structure",
    "metaphor": "Art, revolution, transformation"
}

# λ = 1.0: Pure entropy (dissolution)
var system_chaotic = {
    "lambda": 1.0,
    "behavior": "Maximum randomness",
    "failure_mode": "No coherent structure",
    "metaphor": "White noise, heat death, dispersal"
}
[/code]

**Life exists at λ ≈ 0.3-0.5** — enough order to maintain identity, enough chaos to adapt and create.

[hr]

[b]PRNG: Deterministic Chaos (F Pretending to be E)[/b]

Pseudorandom number generators (PRNGs) are philosophically fascinating: **deterministic algorithms producing apparently random output**.

[color=yellow][b]Code: The Illusion of Randomness[/b][/color]
[code]
# PRNG: Completely deterministic
class PRNG:
    var state: int

    func _init(seed: int):
        state = seed

    func next() -> float:
        # Linear congruential generator
        state = (state * 1103515245 + 12345) % (1 << 31)
        return float(state) / float(1 << 31)

    # Same seed → same sequence (always)
    # Different seed → different sequence
    # Deterministic but unpredictable without knowing state

# What PRNG reveals:
# - "Randomness" can emerge from pure order (F-like)
# - Unpredictability ≠ non-determinism
# - The appearance of E(S) from F
[/code]

**PRNG is the F term in disguise as E(S)** — perfect order producing apparent disorder. This is why computational randomness is always pseudo: true E(S) requires physical processes.

[color=yellow][b]Code: True Randomness (TRNG)[/b][/color]
[code]
# TRNG: Physical entropy sources
# - Thermal noise in resistors
# - Radioactive decay timing
# - Quantum fluctuations

# These are genuine E(S):
# - Not predictable even with perfect knowledge
# - Not reproducible
# - Not compressible
# - True high-dimensional freedom

# The distinction matters:
# PRNG: F dressed as E(S) — controllable, reproducible
# TRNG: Actual E(S) — uncontrollable, irreproducible
[/code]

[hr]

[b]Distributions: The Shape of Entropy[/b]

Not all randomness is the same. Distributions give entropy structure without eliminating it.

[color=yellow][b]Uniform Distribution[/b][/color]
[code]
# Every value equally likely
# Maximum entropy for bounded range

func uniform_random(min_val, max_val):
    return randf() * (max_val - min_val) + min_val

# Properties:
# - No preferred values
# - Flat histogram
# - Maximum surprise per sample
# - Pure democracy of outcomes
[/code]

[color=yellow][b]Gaussian Distribution[/b][/color]
[code]
# Bell curve: values cluster around mean
# Structure within chaos

func gaussian_random(mean, std_dev):
    # Box-Muller transform
    var u1 = randf()
    var u2 = randf()
    var z = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
    return mean + z * std_dev

# Properties:
# - Central tendency (mean is most likely)
# - Tails decay exponentially
# - Sum of many random variables → Gaussian (CLT)
# - Nature's favorite distribution
[/code]

**Gaussian is E(S) with memory** — randomness that remembers a center, disorder with a home base. This is the edge of chaos in distribution form: not uniform (too chaotic) but not deterministic (too ordered).

[hr]

[b]Random Walk: Non-Teleological Movement[/b]

The random walk embodies **queer navigation** — movement without predetermined destination.

[color=yellow][b]Code: Wandering Without Goal[/b][/color]
[code]
var position = Vector2.ZERO
var history = []

func step():
    # Choose random direction
    var angle = randf() * TAU
    var direction = Vector2(cos(angle), sin(angle))

    # Move
    position += direction * step_size
    history.append(position)

    # No destination
    # No plan
    # Just wander

# Properties:
# - Displacement grows as √N (not N)
# - Returns to origin infinitely often (2D)
# - Eventually fills space
# - Non-teleological: process without goal
[/code]

**The random walk is the queer path:**
- No "straight" trajectory (literal and metaphorical)
- Progress is non-linear (√N, not N)
- Returns are possible (revisiting places differently)
- Fills space through wandering, not planning

[color=yellow][b]Code: Queer Random Walk[/b][/color]
[code]
# Heteronormative path: A → B (direct, efficient, goal-oriented)
func straight_path(start, end):
    return end - start  # Direct vector

# Queer path: wandering, returning, exploring
func queer_path(start, steps):
    var position = start
    var path = [position]

    for i in range(steps):
        var direction = random_direction()
        position += direction
        path.append(position)

    return path  # No predetermined endpoint

    # The journey IS the destination
    # Coverage through wandering
    # Non-reproductive movement
[/code]

[hr]

[b]Emergence: When E(S) Creates F[/b]

The deepest insight: **randomness can create order**. This is Turing morphogenesis, the mystery of emergence.

[color=yellow][b]Code: Pattern from Noise[/b][/color]
[code]
# Start with pure entropy
var grid = []
for x in range(100):
    var row = []
    for y in range(100):
        row.append(randf())  # Random initial state
    grid.append(row)

# Apply simple local rules (reaction-diffusion)
func update():
    for x in range(100):
        for y in range(100):
            var neighbors = get_neighbors(x, y)
            var activation = compute_activation(grid[x][y], neighbors)
            var inhibition = compute_inhibition(grid[x][y], neighbors)

            # Local positive feedback + long-range negative feedback
            grid[x][y] += activation - inhibition

# Result after many iterations:
# → Stripes, spots, spirals emerge
# → Order from disorder
# → F crystallizes from E(S)
[/code]

**This is the miracle of the E(S) term:** It doesn't just oppose order—it can **generate** order through self-organization.

[color=yellow][b]The Turing Insight[/b][/color]
[code]
# You don't need:
# - Blueprint
# - Designer
# - Plan
# - Goal

# You need:
# - Random initial conditions (E(S))
# - Simple local rules (constraints)
# - Time (iteration)
# - Energy (computation)

# Result: Complex pattern
# Zebra stripes, leopard spots, shell spirals
# Order without orderer
# Form without former
[/code]

[hr]

[b]The φΔE(S,t) Term: Embracing Change[/b]

The third term captures **rate of entropy change** — not just how much entropy, but how fast it's changing.

[color=yellow][b]Code: Sensitivity to Change[/b][/color]
[code]
var phi = 0.5  # Rate sensitivity coefficient
var E_previous = 0.5
var E_current = 0.5

func update(delta):
    E_current = measure_entropy()
    var dE_dt = (E_current - E_previous) / delta
    E_previous = E_current

    # The rate term
    var rate_contribution = phi * dE_dt

    # Positive phi: system values increasing entropy
    # Negative phi: system resists entropy change

    # Queer systems have POSITIVE phi:
    # - Embrace transition, becoming
    # - Value change itself
    # - Don't cling to current state

# The full QFEP:
func compute_qfe():
    var F = compute_free_energy()
    var E_S = E_current
    var dE_dt = (E_current - E_previous) / delta

    return F - lambda * E_S + phi * dE_dt
[/code]

**Positive φ is the queer signature:**
- Valuing transition over stability
- Embracing becoming over being
- Finding meaning in change itself

[hr]

[b]Randomness and Queer Existence[/b]

Why "queer" free energy? Because queer existence embodies the E(S) term:

[color=yellow][b]Queer as High λ, Positive φ[/b][/color]
[code]
# Normative system:
var normative = {
    "lambda": 0.2,  # Low entropy drive (prefer order)
    "phi": -0.3,    # Negative (resist change)
    "behavior": "Maintain categories, resist deviation"
}

# Queer system:
var queer = {
    "lambda": 0.5,  # Higher entropy drive (value diversity)
    "phi": 0.4,     # Positive (embrace becoming)
    "behavior": "Blur categories, explore possibility"
}
[/code]

**Parallels:**
- **Entropy resists normalization** → Queerness resists heteronormativity
- **High dimensions = freedom** → Identity beyond binary
- **Random walk = non-teleological** → Queer time, non-reproductive futures
- **Emergence without blueprint** → Becoming without predetermined destination
- **Edge of chaos = adaptation** → Queer survival through flexibility

[hr]

[b]Computational Wilderness[/b]

Entropy is **computational wilderness** — space that resists:

- **Indexing** (random points don't fit grids)
- **Compression** (true randomness is incompressible)
- **Prediction** (high entropy = high surprise)
- **Control** (too many states to enumerate)

[color=yellow][b]Code: Unmarked Territory[/b][/color]
[code]
# The grid: every position has an address
var grid = {}
for x in range(100):
    for y in range(100):
        grid[Vector2(x, y)] = "indexed"  # Cadastral, controlled

# Random points: no addresses
var wilderness = []
for i in range(100):
    var point = Vector2(randf() * 100, randf() * 100)
    wilderness.append(point)  # No grid position
    # Cannot be addressed as grid[x][y]
    # Exists in continuous space
    # Free-floating, unmarked

# Wilderness is:
# - Non-cadastral (not divided into owned parcels)
# - High-dimensional (continuous, not discrete)
# - Vital free space (room to move, explore, become)
[/code]

**Without wilderness, no adaptation.** Without E(S), no evolution. Without randomness, no creativity.

[hr]

[b]The Progression: Primitives → Waves → Randomness → Emergence[/b]

The curriculum builds toward understanding QFEP:

[color=cyan][b]Primitives (F Maximized)[/b][/color]
- Pure order: cubes, spheres, lines
- Deterministic, predictable, indexed
- The F term in isolation
- Necessary foundation but insufficient for life

[color=cyan][b]Wavefunctions (F ↔ E(S) Oscillation)[/b][/color]
- Periodic order: oscillation between poles
- Predictable but dynamic
- The λ term begins to appear
- Transition from static to dynamic

[color=cyan][b]Randomness (E(S) Made Visible)[/b][/color]
- Entropy as freedom, not destruction
- High-dimensional possibility space
- The λE(S) term in full
- Computational wilderness

[color=cyan][b]Emergence (E(S) → F)[/b][/color]
- Patterns from noise (Turing morphogenesis)
- Self-organization without blueprint
- The full QFEP in action
- Swarm intelligence, cellular automata

**Randomness is the pivot point** — where we see that disorder is not the enemy of order but its source.

[hr]

[color=cyan][b]Summary:[/b][/color]
Randomness is the E(S) term of the Queer Free Energy Principle made visible. The λE(S) term prevents crystallization by maintaining entropy drive. PRNG is deterministic chaos (F dressed as E), while TRNG is genuine entropy. Distributions give entropy structure (Gaussian = edge of chaos in probability). Random walk embodies non-teleological queer navigation. Emergence shows E(S) creating F through self-organization. The φΔE(S,t) term captures embrace of change—positive φ is the queer signature. Randomness is computational wilderness: unmarked, uncontrolled, vital free space.

[hr]

[color=orange][b]Next:[/b] Noise and Coherent Randomness[/color]
If randomness is freedom, noise is **freedom with memory**. Perlin noise, simplex noise, cellular noise: randomness that varies smoothly, disorder with continuity. The bridge between E(S) and F, chaos that doesn't forget its neighbors.

'''
