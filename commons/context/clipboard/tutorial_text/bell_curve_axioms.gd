extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Bell Curves and Normalization[/b][/font_size][/center]
[center][i]Where Are The Queer Ones That Curve?[/i][/center]

**The bell curve enforces the center.** It says: most values cluster near the mean, extremes are rare, outliers are errors.

**But who decides what's "normal"?**

[hr]

[b]The Gaussian Distribution[/b]

The **normal distribution** (Gaussian, bell curve) appears everywhere in statistics:
- Heights of populations
- Measurement errors
- Test scores
- IQ distributions

[color=yellow][b]Code: Generating Normal Distribution[/b][/color]
[code]
# Box-Muller transform: uniform random → Gaussian random
func gaussian_random(mean: float = 0.0, std_dev: float = 1.0) -> float:
    var u1 = randf()
    var u2 = randf()
    var z0 = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
    return mean + z0 * std_dev

# Generate 1000 values with mean=0, std_dev=1
var distribution = []
for i in range(1000):
    distribution.append(gaussian_random(0.0, 1.0))

# Result: 68% within ±1σ, 95% within ±2σ, 99.7% within ±3σ
# The bell curve: most values near 0, few at extremes
[/code]

**Properties:**
- **Mean (μ)**: center of distribution
- **Standard deviation (σ)**: spread/width
- **68-95-99.7 rule**: percentage within 1σ, 2σ, 3σ

[hr]

[b]Normalization as Violence[/b]

**Normalization** forces data into expected ranges, suppressing outliers:

[color=yellow][b]Code: Z-Score Normalization[/b][/color]
[code]
# Z-score normalization: transform data to mean=0, std_dev=1
func normalize(data: Array) -> Array:
    # Calculate mean
    var sum = 0.0
    for value in data:
        sum += value
    var mean = sum / data.size()

    # Calculate standard deviation
    var variance_sum = 0.0
    for value in data:
        variance_sum += pow(value - mean, 2)
    var std_dev = sqrt(variance_sum / data.size())

    # Normalize: z = (x - μ) / σ
    var normalized = []
    for value in data:
        var z_score = (value - mean) / std_dev
        normalized.append(z_score)

    return normalized

# Example: heights in cm
var heights = [150, 165, 170, 175, 180, 195, 210]
var normalized_heights = normalize(heights)
# → [-1.5, -0.7, -0.3, 0.0, 0.3, 0.9, 1.8]
# The 210cm person becomes "+1.8σ" - an outlier, abnormal
[/code]

**Normalization says:** "You are X standard deviations from normal."

But **who is normal?** The mean is constructed from the dataset. Change the population, change the "normal."

[hr]

[b]Where Are The Queer Ones That Curve?[/b]

The bell curve assumes **symmetry** - equal probability of deviation in both directions.

**But what about:**
- **Bimodal distributions** (two peaks - not one center, but two)
- **Skewed distributions** (long tail on one side - poverty, wealth inequality)
- **Heavy-tailed distributions** (outliers more common than Gaussian predicts - extreme events)
- **Multimodal distributions** (many peaks - multiple "normals")

[color=yellow][b]Code: Bimodal Distribution (Two Normals)[/b][/color]
[code]
# Generate bimodal data: two Gaussian peaks
func bimodal_random() -> float:
    if randf() < 0.5:
        return gaussian_random(-2.0, 0.5)  # First peak at -2
    else:
        return gaussian_random(2.0, 0.5)   # Second peak at +2

# Result: TWO centers, not one
# Bell curve fails to describe this
# Z-score normalization distorts it
[/code]

**Queer distributions resist the bell curve.** They have multiple centers, asymmetric tails, unexpected clusters.

**The algorithm tries to fit them to Gaussian anyway** - erasing difference, enforcing single "normal."

[hr]

[b]Outliers Are Not Errors[/b]

Standard statistical practice: **remove outliers** (values > 3σ from mean).

**But outliers are often the most interesting data:**
- **Extreme weather events** (climate change signal)
- **Genius/disability** (cognitive diversity)
- **Queer identities** (resistance to heteronorm)
- **Black swan events** (market crashes, pandemics)

[color=yellow][b]Code: Outlier Removal as Erasure[/b][/color]
[code]
# Standard outlier removal
func remove_outliers(data: Array) -> Array:
    var normalized = normalize(data)
    var filtered = []

    for i in range(data.size()):
        var z_score = normalized[i]
        if abs(z_score) <= 3.0:  # Keep only within ±3σ
            filtered.append(data[i])
        else:
            print("Outlier removed: ", data[i])

    return filtered

# Example: [1, 2, 3, 4, 5, 100]
# → Removes 100 as "outlier"
# But 100 might be the most important value!
[/code]

**Removing outliers normalizes the dataset** - makes it more Gaussian, more "well-behaved."

**But this erases difference.** The outliers ARE the signal, not the noise.

[hr]

[b]The Central Limit Theorem (CLT)[/b]

**CLT says:** Sum of many independent random variables → Gaussian distribution (even if original variables aren't Gaussian).

[color=yellow][b]Code: CLT in Action[/b][/color]
[code]
# Roll die once: uniform distribution (1-6, all equal probability)
func roll_die() -> int:
    return randi() % 6 + 1

# Roll die 10 times, sum results
func roll_multiple_dice(count: int) -> int:
    var sum = 0
    for i in range(count):
        sum += roll_die()
    return sum

# Distribution of roll_die() = uniform (flat)
# Distribution of roll_multiple_dice(10) = Gaussian (bell curve)!
# CLT: averaging/summing → Gaussian, regardless of source distribution
[/code]

**CLT is why Gaussian appears everywhere:**
- Many small random factors sum to create observed value
- Heights = genetics + nutrition + environment + ... → Gaussian
- Test scores = knowledge + sleep + luck + stress + ... → Gaussian

**But:** CLT requires **independence** and **finite variance**.

**Power law distributions** (wealth inequality, city sizes) violate these - they DON'T become Gaussian.

[hr]

[b]Standard Deviation as Surveillance[/b]

**Standard deviation (σ)** measures "spread from normal."

[color=yellow][b]The Disciplinary Function:[/b][/color]
[code]
# Mark students as "standard deviations from mean"
var test_scores = [45, 60, 70, 75, 80, 85, 90, 95]
var normalized = normalize(test_scores)

# Student grades now expressed as:
# "You are -1.2σ below average"
# "You are +0.8σ above average"

# Creates hierarchy:
# - Center (±0σ) = normal
# - Positive σ = gifted
# - Negative σ = remedial
[/code]

**Standard deviation is a tool of normalization:**
- Measures distance from center
- Defines "acceptable range" (usually ±2σ)
- Labels outliers as deviant

**Foucault:** Discipline operates through norm/deviation. The bell curve is biopolitical - sorting populations into normal/abnormal.

[hr]

[b]Uniform vs Gaussian: Which Is "More Random"?[/b]

[color=yellow][b]Code: Comparing Distributions[/b][/color]
[code]
# Uniform random: all values equally likely
func uniform_random() -> float:
    return randf()  # 0.0 to 1.0, flat distribution

# Gaussian random: clustered near mean
func gaussian_random_01() -> float:
    return gaussian_random(0.5, 0.15)  # Mean 0.5, std_dev 0.15
    # Most values near 0.5, few at extremes

# Question: Which is "more random"?
# - Uniform: maximum entropy (all outcomes equally probable)
# - Gaussian: lower entropy (center more probable than edges)

# Answer: Uniform is "more random" (higher entropy)
# Gaussian is "more structured" (has preferred center)
[/code]

**Uniform distribution** = maximum freedom (no center imposed).
**Gaussian distribution** = normalization (center enforced).

[hr]

[b]Resistant Distributions[/b]

**Non-Gaussian distributions resist normalization:**

[color=yellow][b]1. Power Law (Heavy-Tailed)[/b][/color]
[code]
# Power law: P(x) ∝ x^(-α)
# Examples: wealth distribution, city sizes, word frequencies
# Characteristic: "rich get richer" (preferential attachment)
# Long tail: extreme values more common than Gaussian predicts

# Zipf's law (α = 1): most common word is 2× frequent as 2nd, 3× as 3rd...
# No characteristic scale - no meaningful "average"
[/code]

[color=yellow][b]2. Exponential (Memoryless)[/b][/color]
[code]
# Exponential decay: P(t) = λ * e^(-λt)
# Examples: radioactive decay, time between events
# Memoryless: P(survival past t+s | survived to t) = P(survival past s)
# Always same probability of event, regardless of history

func exponential_random(lambda: float) -> float:
    return -log(randf()) / lambda
[/code]

[color=yellow][b]3. Cauchy (Undefined Mean)[/b][/color]
[code]
# Cauchy distribution: no defined mean or variance
# Heavy tails: extreme outliers very common
# CLT doesn't apply: sum of Cauchy variables → still Cauchy, not Gaussian!
# Resists averaging, resists normalization completely
[/code]

**These distributions say:** "There is no center. There is no normal. Your bell curve doesn't apply here."

[hr]

[b]Queer Statistics[/b]

**Queer theory resists normalization** - the idea of single "normal" identity/sexuality.

**Queer statistics would:**
1. **Celebrate multimodal distributions** (many normals, not one)
2. **Preserve outliers** (difference is not error)
3. **Reject z-score labeling** (no measuring "deviations from normal")
4. **Use non-parametric methods** (don't assume Gaussian)
5. **Center the margins** (study outliers first, not as afterthought)

[color=yellow][b]Code: Non-Parametric Diversity[/b][/color]
[code]
# Instead of fitting to Gaussian (parametric):
var data = [collect diverse data]

# Use kernel density estimation (non-parametric)
# - No assumption of shape
# - Discovers multiple peaks
# - Preserves irregularity
# - Doesn't force bell curve

# Result: see true distribution, not idealized Gaussian projection
[/code]

**The bell curve is not "natural" or "neutral"** - it's a **model** that enforces centrality and erases difference.

[hr]

[b]What Bell Curves Reveal[/b]

Bell curves show us:

1. **Normalization is constructed** - mean depends on population sampled
2. **Outliers are erased** - statistical practice removes "abnormal" data
3. **Center is enforced** - σ measures "deviance from normal"
4. **Many distributions aren't Gaussian** - power laws, multimodal, heavy-tailed resist
5. **CLT creates Gaussian** - but requires independence, finite variance
6. **Uniform is more random** - Gaussian has preferred center (lower entropy)
7. **Queer statistics resists** - multiple centers, preserve outliers, non-parametric

**The bell curve asks:** "How far are you from normal?"
**Queer statistics asks:** "What if there is no normal?"

**Where are the queer ones that curve?** Everywhere the bell curve says they shouldn't be - in the tails, at multiple peaks, refusing to cluster near the mean.

[hr]

[color=cyan][b]Summary:[/b][/color]
Gaussian distribution (bell curve) clusters values near mean, with exponentially rare extremes (68-95-99.7 rule). Normalization forces data into mean=0, std_dev=1, measuring "distance from normal." Outliers (>3σ) are removed as errors, erasing difference. CLT makes sums of random variables Gaussian, but doesn't apply to power laws or heavy-tailed distributions. Uniform distribution has higher entropy (more random) than Gaussian (structured around center). Queer statistics resists bell curve: multiple peaks, preserved outliers, no single "normal."

[hr]

[color=orange][b]Next:[/b] Decay - Time-Based Randomness[/color]
If bell curves enforce spatial normalization, decay enforces temporal normalization - all things return to equilibrium, noise, disorder. But decay rate is also random, unpredictable, generative.

'''
