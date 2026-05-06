extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Random Distributions[/b][/font_size][/center]
[center][i]Shapes of Randomness[/i][/center]

**Not all randomness is equal.** Different distributions create different patterns, behaviors, probabilities.

**Uniform is flat. Gaussian is bell. Exponential is decay.** Each shape tells a story about how values cluster.

[hr]

[b]Uniform Distribution: Democracy of Values[/b]

**All values equally likely** - no favorites, no bias.

[color=yellow][b]Code: Uniform Random[/b][/color]
[code]
# Godot's randf() returns uniform [0, 1]
func uniform_random(min_val: float, max_val: float) -> float:
    return randf() * (max_val - min_val) + min_val

# Example: Random position in rectangle
var x = uniform_random(0, 100)
var y = uniform_random(0, 100)

# Result: Every point in rectangle equally likely
# No clustering, flat probability
[/code]

**Properties:**
- **Mean:** (min + max) / 2
- **Flat probability density** - every value in range has same chance
- **No memory** - previous values don't affect next

**Use cases:** Dice rolls, coin flips, random colors, shuffling.

[hr]

[b]Exponential Distribution: Time Until Event[/b]

**Models waiting time** - time until next radioactive decay, customer arrival, component failure.

[color=yellow][b]Code: Exponential Random[/b][/color]
[code]
# λ (lambda) = rate parameter (events per unit time)
func exponential_random(lambda: float) -> float:
    var u = randf()  # Uniform [0, 1]
    return -log(1.0 - u) / lambda

# Example: Time until next enemy spawn
var spawn_rate = 0.5  # 0.5 enemies per second
var time_until_spawn = exponential_random(spawn_rate)

await get_tree().create_timer(time_until_spawn).timeout
spawn_enemy()

# Result: Memoryless spawning - past doesn't affect future
# Most spawns happen soon, rare long waits
[/code]

**Properties:**
- **Memoryless** - P(wait another t | already waited s) = P(wait t)
- **Mean:** 1/λ
- **Long tail** - rare extreme values
- **Skewed right** - most values near zero, few large values

**Use cases:** Time between events, particle lifetimes, network packet arrivals.

[hr]

[b]Poisson Distribution: Event Counting[/b]

**How many events in fixed time?** Complement to exponential (time until event).

[color=yellow][b]Code: Poisson Random[/b][/color]
[code]
# λ (lambda) = expected number of events
func poisson_random(lambda: float) -> int:
    var L = exp(-lambda)
    var k = 0
    var p = 1.0

    while p > L:
        k += 1
        p *= randf()

    return k - 1

# Example: Number of meteors hitting planet per minute
var expected_meteors = 3.0
var actual_meteors = poisson_random(expected_meteors)

for i in range(actual_meteors):
    spawn_meteor()

# Result: Usually ~3 meteors, sometimes 0, sometimes 7
# Discrete values (can't have 2.5 meteors)
[/code]

**Properties:**
- **Discrete** - whole numbers only
- **Mean = variance = λ**
- **Rare events** - when λ small, mostly 0 or 1
- **Approaches Gaussian** when λ large (λ > 20)

**Use cases:** Spawn counts, particle emissions, procedural encounter tables.

[hr]

[b]Binomial Distribution: Success Counting[/b]

**n trials, each success probability p** - how many successes total?

[color=yellow][b]Code: Binomial Random[/b][/color]
[code]
# n trials, p probability of success each trial
func binomial_random(n: int, p: float) -> int:
    var successes = 0
    for i in range(n):
        if randf() < p:
            successes += 1
    return successes

# Example: 10 arrows shot, each 70% hit chance
var arrows = 10
var hit_chance = 0.7
var hits = binomial_random(arrows, hit_chance)

print(hits, " out of ", arrows, " arrows hit")

# Result: Usually 6-8 hits, rarely 0 or 10
# Symmetric when p = 0.5, skewed otherwise
[/code]

**Properties:**
- **Discrete** (0 to n)
- **Mean:** n * p
- **Variance:** n * p * (1 - p)
- **Symmetric when p = 0.5**, skewed otherwise

**Use cases:** Hit chances, loot drops, critical hit counting.

[hr]

[b]Gaussian (Normal) Distribution: The Bell Curve[/b]

**Already covered in bell_curve_axioms.gd**, but quick recap:

[color=yellow][b]Code: Box-Muller Transform[/b][/color]
[code]
func gaussian_random(mean: float = 0.0, std_dev: float = 1.0) -> float:
    var u1 = randf()
    var u2 = randf()
    var z = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
    return mean + z * std_dev

# Example: Random height with mean 170cm, std_dev 10cm
var height = gaussian_random(170, 10)
# Result: Most values 160-180, rare extremes
[/code]

**Central Limit Theorem:** Sum of many independent random variables → Gaussian (regardless of original distribution).

[hr]

[b]Cauchy Distribution: No Mean, Heavy Tails[/b]

**Extreme outliers dominate** - mean doesn't exist mathematically.

[color=yellow][b]Code: Cauchy Random[/b][/color]
[code]
func cauchy_random(x0: float = 0.0, gamma: float = 1.0) -> float:
    var u = randf()
    return x0 + gamma * tan(PI * (u - 0.5))

# Example: Glitch displacement
var glitch_offset = cauchy_random(0, 0.5)
sprite.position.x += glitch_offset

# Result: Usually small offset, occasionally HUGE jump
# Unpredictable, chaotic feel
[/code]

**Properties:**
- **No defined mean or variance** (infinite)
- **Very heavy tails** - extreme outliers common
- **Ratio of two Gaussians** = Cauchy

**Use cases:** Glitch effects, chaos, aggressive outliers.

[hr]

[b]Beta Distribution: Values in [0, 1][/b]

**Constrained randomness** - always between 0 and 1, shape controlled by α and β.

[color=yellow][b]Code: Beta Distribution (Approximation)[/b][/color]
[code]
# Simple beta using gamma functions (approximation)
func beta_random(alpha: float, beta_param: float) -> float:
    var x = pow(randf(), 1.0 / alpha)
    var y = pow(randf(), 1.0 / beta_param)
    return x / (x + y)

# Example: Random skill level (0 = novice, 1 = master)
var skill = beta_random(2, 5)  # Skewed toward lower values (novice)
var damage = base_damage * skill

# Result: Most enemies weak, few strong
[/code]

**Shape control:**
- **α = β = 1:** Uniform
- **α > β:** Skewed right (toward 1)
- **α < β:** Skewed left (toward 0)
- **α, β > 1:** Bell-shaped in [0, 1]

**Use cases:** Random percentages, skill levels, color mixing.

[hr]

[b]Log-Normal Distribution: Multiplicative Growth[/b]

**If log(X) is Gaussian, X is log-normal.** Models multiplicative processes.

[color=yellow][b]Code: Log-Normal Random[/b][/color]
[code]
func log_normal_random(mean_log: float, std_dev_log: float) -> float:
    var z = gaussian_random(mean_log, std_dev_log)
    return exp(z)

# Example: Resource deposit size
var deposit_size = log_normal_random(3, 1)

# Result: Many small deposits, few HUGE ones
# Like: wealth distribution, city sizes, file sizes
[/code]

**Properties:**
- **Always positive** (can't be negative)
- **Right-skewed** - long tail toward large values
- **Models multiplicative growth** (compound interest, population growth)

**Use cases:** Loot amounts, resource deposits, city sizes.

[hr]

[b]Triangular Distribution: Simple Skew[/b]

**Easy to implement, intuitive parameters:** min, max, mode.

[color=yellow][b]Code: Triangular Random[/b][/color]
[code]
func triangular_random(a: float, b: float, c: float) -> float:
    # a = min, b = max, c = mode (peak)
    var u = randf()
    var F_c = (c - a) / (b - a)

    if u < F_c:
        return a + sqrt(u * (b - a) * (c - a))
    else:
        return b - sqrt((1.0 - u) * (b - a) * (b - c))

# Example: Enemy count in encounter
var min_enemies = 1
var max_enemies = 10
var most_likely = 3  # Usually small groups

var enemy_count = triangular_random(min_enemies, max_enemies, most_likely)

# Result: Peak at 3, rare extremes (1 or 10)
[/code]

**When to use:** Need rough skew without complexity of beta/gamma.

[hr]

[b]Pareto Distribution: Power Law (80/20 Rule)[/b]

**Few have much, many have little.** The rich get richer.

[color=yellow][b]Code: Pareto Random[/b][/color]
[code]
func pareto_random(x_min: float, alpha: float) -> float:
    var u = randf()
    return x_min / pow(u, 1.0 / alpha)

# Example: NPC wealth distribution
var min_wealth = 10
var alpha = 1.5  # Lower α = more inequality

var npc_wealth = pareto_random(min_wealth, alpha)

# Result: Most NPCs poor (~10-50), few rich (1000+)
# 80% of wealth held by 20% of NPCs
[/code]

**Power law:** P(X > x) ∝ x^(-α)

**Examples in nature:**
- Wealth distribution
- City sizes
- Word frequency (Zipf's law)
- Network connectivity (scale-free networks)

[hr]

[b]Weibull Distribution: Failure Modeling[/b]

**Time until component failure** - like exponential, but with "aging" (failure rate changes over time).

[color=yellow][b]Code: Weibull Random[/b][/color]
[code]
func weibull_random(lambda: float, k: float) -> float:
    var u = randf()
    return lambda * pow(-log(1.0 - u), 1.0 / k)

# Example: Weapon durability degradation
var scale = 100.0  # λ (scale parameter)
var shape = 2.0    # k (shape parameter)

var time_until_break = weibull_random(scale, shape)

# k < 1: Infant mortality (early failures common)
# k = 1: Constant failure rate (exponential)
# k > 1: Wear-out (failure rate increases with age)
[/code]

**Use cases:** Durability systems, breakable objects, aging effects.

[hr]

[b]Choosing the Right Distribution[/b]

[color=yellow][b]Decision Guide:[/b][/color]
[code]
# Q: All values equally likely?
# → Uniform distribution

# Q: Time until next event?
# → Exponential distribution

# Q: How many events in fixed time?
# → Poisson distribution

# Q: Success count out of n tries?
# → Binomial distribution

# Q: Natural variation, central tendency?
# → Gaussian (normal) distribution

# Q: Rare extreme outliers?
# → Cauchy or Pareto distribution

# Q: Always positive, right-skewed?
# → Log-normal or exponential

# Q: Constrained to [0, 1]?
# → Beta or uniform

# Q: Simple triangular peak?
# → Triangular distribution
[/code]

[hr]

[b]Mixing Distributions[/b]

**Combine distributions for complex behavior:**

[color=yellow][b]Code: Mixture Models[/b][/color]
[code]
# 70% weak enemies, 30% strong enemies (bimodal)
func enemy_strength() -> float:
    if randf() < 0.7:
        return gaussian_random(10, 2)  # Weak group
    else:
        return gaussian_random(50, 5)  # Strong group

# Result: Two distinct clusters of enemy strength

# Weighted average of distributions
func mixed_distribution() -> float:
    var choice = randf()
    if choice < 0.5:
        return exponential_random(1.0)
    elif choice < 0.8:
        return gaussian_random(5, 1)
    else:
        return uniform_random(0, 10)

# Result: Complex multi-modal distribution
[/code]

[hr]

[b]What Distributions Reveal[/b]

Distributions show us:

1. **Shape matters** - Uniform ≠ Gaussian ≠ Exponential
2. **Parameters control behavior** - Mean, variance, skew
3. **Match distribution to phenomenon** - Don't use Gaussian for everything
4. **Heavy tails = rare extremes** - Cauchy, Pareto for chaos
5. **Central Limit Theorem** - Many randoms sum to Gaussian
6. **Mixtures create complexity** - Combine simple for complex
7. **Discrete vs continuous** - Poisson/binomial vs Gaussian/exponential

**Uniform is anarchy** - all equal, no structure.
**Gaussian is conformity** - cluster around mean, punish outliers.
**Exponential is mortality** - most die young, few survive long.
**Pareto is capitalism** - few have much, many have little.

**Choice of distribution is political** - it encodes assumptions about how the world works.

[hr]

[color=cyan][b]Summary:[/b][/color]
Random distributions shape probability. Uniform (flat, all equal), Gaussian (bell curve, central tendency), exponential (time until event, memoryless), Poisson (event count, discrete), binomial (success count), Cauchy (heavy tails, no mean), log-normal (multiplicative growth, right-skewed), Pareto (power law, 80/20), Weibull (failure with aging). Choose distribution based on phenomenon. Mixture models combine distributions. Shape encodes assumptions about reality.

[hr]

[color=orange][b]Next:[/b] Ten-Print Maze - One-Line Randomness[/color]
If distributions shape probability, ten-print shows randomness as pattern - one line of code generating infinite maze-like structure. Historical, poetic, minimal.

'''
