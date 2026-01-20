extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Fractals and the Queer Free Energy Principle[/b][/font_size][/center]
[center][i]Self-Similarity as Entropy Distribution Across Scales[/i][/center]

Fractals are not decorative mathematics. They are **the shape of emergence** — what happens when simple rules iterate, when systems maintain structure while embracing infinite complexity.

**QFE = F − λE(S) + φΔE(S,t)**

Fractals embody this equation:
- **F** = The deterministic rule (z² + c, remove middle third, branch at angle)
- **λE(S)** = Entropy maintained across scales (self-similarity coefficient)
- **φΔE(S,t)** = Recursive iteration (each generation increases complexity)

**The fractal dimension D = log(N)/log(S) is the λ parameter made geometric.**

[hr]

[b]The F Term: Deterministic Rules[/b]

Every fractal begins with a simple rule:

[color=yellow][b]Code: The Rules That Generate Infinity[/b][/color]
[code]
# Cantor set: remove middle third
func cantor_rule(segment):
    var left = segment.first_third()
    var right = segment.last_third()
    return [left, right]  # Middle third removed

# Koch curve: replace segment with four
func koch_rule(segment):
    var a = segment.start
    var b = segment.at(1.0/3.0)
    var peak = segment.peak_at(0.5)  # Equilateral triangle peak
    var c = segment.at(2.0/3.0)
    var d = segment.end
    return [a_to_b, b_to_peak, peak_to_c, c_to_d]

# Sierpinski: keep three outer triangles
func sierpinski_rule(triangle):
    var midpoints = triangle.edge_midpoints()
    return [triangle.corner_subtriangle(0),
            triangle.corner_subtriangle(1),
            triangle.corner_subtriangle(2)]
    # Central triangle removed

# Mandelbrot: iterate z² + c
func mandelbrot_rule(z, c):
    return z * z + c  # That's it. That's the rule.
[/code]

These rules are **pure F** — deterministic, predictable, ordered. But when iterated, they produce infinite complexity.

**This is the paradox of emergence:** Order generates chaos. Simple rules create unbounded detail.

[hr]

[b]The λE(S) Term: Self-Similarity as Entropy Distribution[/b]

Self-similarity means **the same entropy pattern at every scale**. This is λ in action:

[color=yellow][b]Code: Entropy Across Scales[/b][/color]
[code]
# Fractal dimension formula
func fractal_dimension(num_copies: int, scale_factor: float) -> float:
    # D = log(N) / log(S)
    # N = number of self-similar pieces
    # S = scaling factor (how much smaller each piece is)
    return log(num_copies) / log(scale_factor)

# Examples:
# Sierpinski triangle: 3 pieces, each 1/2 scale
var sierpinski_D = fractal_dimension(3, 2)  # ≈ 1.585

# Menger sponge: 20 pieces, each 1/3 scale
var menger_D = fractal_dimension(20, 3)  # ≈ 2.727

# Koch curve: 4 pieces, each 1/3 scale
var koch_D = fractal_dimension(4, 3)  # ≈ 1.262

# Cantor set: 2 pieces, each 1/3 scale
var cantor_D = fractal_dimension(2, 3)  # ≈ 0.631
[/code]

**D is the entropy efficiency metric:**
- How much complexity per unit of space?
- How much information at each scale level?
- What fraction of each dimension is "filled"?

[color=cyan][b]Sierpinski at D ≈ 1.585:[/b][/color]
- More than a line (D = 1)
- Less than a plane (D = 2)
- Fills 1.585 dimensions worth of space
- **Dimensionally queer** — between integers

[hr]

[b]The φΔE(S,t) Term: Iteration as Change[/b]

Each fractal generation represents **time** — the t in ΔE(S,t). With each iteration, complexity increases:

[color=yellow][b]Code: Exponential Growth Through Iteration[/b][/color]
[code]
# Koch curve: each iteration multiplies edges by 4
var edges_per_generation = [1, 4, 16, 64, 256, 1024...]
# Growth: 4^n

# Sierpinski: each iteration multiplies triangles by 3
var triangles_per_generation = [1, 3, 9, 27, 81, 243...]
# Growth: 3^n

# L-System tree: exponential symbol growth
var axiom = "F"
var rules = {"F": "F[+F]F[-F]F"}

func generation_length(n: int) -> int:
    # Each F becomes 5 symbols + 4 brackets
    # Exponential growth
    return pow(5, n)  # Approximately

# After 5 generations: 3125 symbols
# After 10 generations: ~10 million symbols
# Unbounded growth from fixed rules
[/code]

**φ modulates sensitivity to this growth:**
- High φ: system embraces increasing complexity
- Low φ: system resists, tries to maintain simplicity
- Fractals have **infinite φ** — they embrace unlimited growth

[hr]

[b]The Mandelbrot Boundary: Maximum λ[/b]

The Mandelbrot set boundary is where **entropy is maximized**:

[color=yellow][b]Code: The Edge of Chaos[/b][/color]
[code]
func mandelbrot_iterate(c: Vector2, max_iterations: int) -> int:
    var z = Vector2.ZERO

    for i in range(max_iterations):
        # z = z² + c (complex multiplication)
        var z_new = Vector2(
            z.x * z.x - z.y * z.y + c.x,
            2.0 * z.x * z.y + c.y
        )
        z = z_new

        # Escape condition: |z| > 2
        if z.length() > 2.0:
            return i  # Escaped at iteration i

    return max_iterations  # Didn't escape (in set)

# Points IN the set: z stays bounded forever
# Points OUT of set: z escapes to infinity
# The BOUNDARY: infinitely complex, neither in nor out

# At the boundary:
# - Infinite detail at every zoom level
# - Sensitive dependence on position
# - Maximum information density
# - The "edge of chaos" made visible
[/code]

**The Mandelbrot boundary is λ maximized:**
- Neither fully in (order) nor fully out (chaos)
- Infinite complexity at the transition
- The QFEP edge: where prediction fails, where emergence lives

[hr]

[b]Julia Sets: λ as Parameter[/b]

Julia sets show what happens when you **vary λ directly**:

[color=yellow][b]Code: Julia Set Variations[/b][/color]
[code]
# Julia set: same iteration, fixed c value
func julia_iterate(z: Vector2, c: Vector2, max_iterations: int) -> int:
    for i in range(max_iterations):
        var z_new = Vector2(
            z.x * z.x - z.y * z.y + c.x,
            2.0 * z.x * z.y + c.y
        )
        z = z_new

        if z.length() > 2.0:
            return i

    return max_iterations

# Different c values = different Julia sets:

# c = (-0.7, 0.27): Connected, dendrite-like
# c = (-0.8, 0.156): Connected, spiraling
# c = (0.285, 0.01): Connected, rabbit-like
# c = (-0.4, 0.6): Disconnected, Cantor dust

# The c parameter IS λ:
# - c inside Mandelbrot set → Julia set connected (order)
# - c outside Mandelbrot set → Julia set disconnected (chaos)
# - c on boundary → Julia set infinitely complex (edge)
[/code]

**Julia sets are QFEP visualized:**
- Moving c = adjusting λ
- Connected Julia = low entropy (coherent structure)
- Disconnected Julia = high entropy (scattered dust)
- Boundary Julia = maximum complexity (self-similar detail)

[hr]

[b]L-Systems: Generativity Without Blueprint[/b]

L-Systems generate form through **grammar** — rules that rewrite symbols:

[color=yellow][b]Code: Grammar Creates Form[/b][/color]
[code]
class LSystem:
    var axiom: String
    var rules: Dictionary

    func generate(generations: int) -> String:
        var current = axiom

        for i in range(generations):
            var next = ""
            for symbol in current:
                if symbol in rules:
                    next += rules[symbol]
                else:
                    next += symbol
            current = next

        return current

# Koch curve L-System:
var koch = LSystem.new()
koch.axiom = "F"
koch.rules = {"F": "F+F-F-F+F"}

# Generation 0: F
# Generation 1: F+F-F-F+F
# Generation 2: F+F-F-F+F+F+F-F-F+F-F+F-F-F+F-F+F-F-F+F+F+F-F-F+F
# Exponential growth: 1 → 5 → 25 → 125 → 625...

# Tree L-System with stochastic rules:
var tree = LSystem.new()
tree.axiom = "F"
tree.rules = {
    "F": ["F[+F]F[-F]F", "F[+F][-F]", "FF[+F][-F]F"]  # Multiple options
}

func apply_stochastic_rule(symbol):
    if symbol in rules:
        var options = rules[symbol]
        return options[randi() % options.size()]  # Random choice
    return symbol

# Stochastic L-Systems: same grammar, different trees each time
# This is λE(S) in action: deterministic rules + entropy injection
[/code]

**L-Systems embody QFEP:**
- F term: deterministic rule application
- λE(S): stochastic rule selection (randomness within structure)
- φΔE(S,t): exponential string growth with each generation
- Result: organic forms without stored templates

[hr]

[b]Romanesco: Nature's λ Optimizer[/b]

Romanesco broccoli demonstrates **optimal entropy distribution**:

[color=yellow][b]Code: The Golden Angle[/b][/color]
[code]
# Golden ratio
var phi = (1.0 + sqrt(5.0)) / 2.0  # ≈ 1.618

# Golden angle (in radians)
var golden_angle = TAU / (phi * phi)  # ≈ 137.508°

func romanesco_spiral(num_florets: int, scale: float):
    for i in range(num_florets):
        # Angular position: golden angle spacing
        var angle = i * golden_angle

        # Radial position: Fibonacci spiral
        var radius = scale * sqrt(i)

        # Height: logarithmic cone
        var height = log(i + 1) * scale

        var position = Vector3(
            radius * cos(angle),
            height,
            radius * sin(angle)
        )

        # Create floret (which is itself a mini-romanesco)
        create_floret(position, scale * 0.3)

# Why golden angle?
# - Maximally irrational: no pattern ever repeats exactly
# - Optimal packing: florets don't shadow each other
# - Maximum entropy per unit space
# - Nature's λ = 1/φ² ≈ 0.382
[/code]

**The golden angle is nature's entropy optimizer:**
- 137.508° = TAU / φ²
- Never repeats (irrational)
- Maximally disperses points
- Fibonacci spirals emerge from this angle

**Romanesco is QFEP embodied in biology:**
- F: growth rules (spiral, scale)
- λE(S): golden angle ensures maximum diversity of positions
- φΔE(S,t): each floret is smaller romanesco (recursive self-similarity)

[hr]

[b]Fractal Dimension as Queer Metric[/b]

Why is fractal dimension D "queer"?

[color=yellow][b]Dimension as Spectrum:[/b][/color]
[code]
# Classical (normative) dimensions:
var normative_dimensions = {
    "point": 0,
    "line": 1,
    "plane": 2,
    "volume": 3
}
# Integers. Discrete. Categorical.

# Fractal (queer) dimensions:
var queer_dimensions = {
    "Cantor set": 0.631,      # More than point, less than line
    "Koch curve": 1.262,      # More than line, less than plane
    "Sierpinski": 1.585,      # More than line, less than plane
    "Menger sponge": 2.727,   # More than plane, less than volume
    "Coastline": 1.25,        # Measured dimension varies with scale
}
# Fractional. Continuous. Between.

# This parallels:
# - Gender as spectrum (not binary)
# - Sexuality as continuum (Kinsey scale, etc.)
# - Identity as process (not fixed category)
[/code]

**Fractals mathematically prove:**
- Dimensions need not be integers
- Categories leak at the boundaries
- "Between" is a valid position
- Complexity resists classification

[hr]

[b]Computational Irreducibility: Queer Futures[/b]

The Mandelbrot set boundary cannot be computed without iteration:

[color=yellow][b]Code: No Shortcut to Prediction[/b][/color]
[code]
# Can we predict if a point is in the Mandelbrot set without iterating?
# NO. This is computational irreducibility.

func is_in_mandelbrot(c: Vector2) -> bool:
    # Must actually iterate to find out
    var z = Vector2.ZERO

    for i in range(MAX_ITERATIONS):
        z = complex_square(z) + c
        if z.length() > 2.0:
            return false  # Escaped

    return true  # Probably in set (can never be certain)

# Properties:
# - Cannot know without doing
# - Must iterate to discover
# - Boundary points: infinite iteration needed
# - No closed-form solution exists

# This is queer temporality:
# - Futures must be lived to be known
# - Cannot predict without experience
# - Identity emerges through iteration
# - No shortcut to self-knowledge
[/code]

**Computational irreducibility is queer epistemology:**
- Some knowledge requires process, not formula
- Becoming over being
- The journey cannot be skipped
- Emergence is irreducible

[hr]

[b]The Menger Sponge: Walkable Infinity[/b]

The Menger sponge (at sufficient scale) is a **habitable fractal**:

[color=yellow][b]Properties:[/b][/color]
[code]
# Menger sponge after infinite iterations:
var surface_area = INF  # Infinite surface
var volume = 0          # Zero volume
var dimension = 2.727   # Between plane and cube

# After 3 iterations with 27m initial cube:
# - Smallest passages: 1 meter (walkable)
# - Total passages: fractal network
# - You can walk through infinity

# The sponge is:
# - Topologically connected (can traverse entire structure)
# - Nowhere solid (every point is boundary)
# - Infinite surface enclosing zero volume
# - A space that is all edge, no interior
[/code]

**Walking the Menger sponge is experiencing QFEP:**
- Finite bounding box, infinite path through it
- Structure without mass
- Boundary without interior
- Edge of chaos made architectural

[hr]

[b]The Progression: Primitives → Fractals → Emergence[/b]

Where fractals fit in the QFEP curriculum:

[color=cyan][b]1. Primitives (F Maximized)[/b][/color]
- Euclidean: point, line, plane, cube
- Integer dimensions: 0, 1, 2, 3
- Clean, discrete, categorical
- The F term in isolation

[color=cyan][b]2. Wavefunctions (F ↔ E(S) Oscillation)[/b][/color]
- Periodic: sine, cosine, Fourier
- Oscillation between poles
- Time as parameter
- The λ term appears

[color=cyan][b]3. Randomness (E(S) Made Visible)[/b][/color]
- Non-periodic: noise, random walk
- High-dimensional freedom
- Entropy as possibility space
- The λE(S) term in full

[color=cyan][b]4. Fractals (F + λE(S) + φΔE(S,t) Unified)[/b][/color]
- Self-similar: same pattern at every scale
- Fractional dimensions: between integers
- Recursive: iteration creates emergence
- **All three terms working together**

[color=cyan][b]5. Emergence (Full QFEP)[/b][/color]
- Swarm intelligence: many agents, collective behavior
- Cellular automata: local rules, global patterns
- Morphogenesis: form without blueprint
- The complete principle in action

**Fractals are the pivot point** — where we see deterministic rules (F) generating infinite complexity (E(S)) through recursive iteration (φΔE(S,t)).

[hr]

[color=cyan][b]Summary:[/b][/color]
Fractals embody the Queer Free Energy Principle in geometric form. The F term is the simple rule (z² + c, remove third, branch). The λE(S) term is self-similarity — the same entropy pattern distributed across scales. The φΔE(S,t) term is iteration — each generation increasing complexity exponentially. Fractal dimension D = log(N)/log(S) quantifies entropy efficiency. The Mandelbrot boundary is maximum λ — the edge of chaos where prediction fails. Julia sets show λ as tunable parameter (c value). L-Systems generate form through grammar without blueprint. Romanesco demonstrates nature's golden angle optimizer. Fractals prove dimensions need not be integers — they are queer geometry, existing between categories, refusing normative classification.

[hr]

[color=orange][b]Next:[/b] From Fractals to Swarms[/color]
What happens when fractal logic applies to agents instead of geometry? Boids, ant colonies, particle swarms — collective intelligence emerging from simple rules. The QFEP scales from shapes to societies.

'''
