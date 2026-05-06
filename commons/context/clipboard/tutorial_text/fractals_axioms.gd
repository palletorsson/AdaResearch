extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Fractals[/b][/font_size][/center]
[center][i]Self-Similarity, Infinite Detail, Queer Dimensionality[/i][/center]

**A fractal is a pattern that repeats at different scales.**

Look close: you see the same structure. Zoom in: still the same structure. Zoom forever: **always more detail, never smooth**.

Fractals are **geometric self-reference** - the whole contains copies of itself, infinitely nested.

They are **infinite detail in finite space** - bounded area, unbounded complexity.

And they reveal something mathematically queer: **dimensions between integers**. Not 1D, not 2D, but **1.585D**. Not line, not plane, but **between**.

**Fractals refuse categorical placement.**

[hr]

[b]Self-Similarity: The Whole Contains Itself[/b]

**Self-similar** means a pattern looks similar to itself at different scales.

[color=yellow][b]Examples in Nature:[/b][/color]
- **Ferns** - each frond is a miniature fern
- **Coastlines** - jagged at every zoom level (km, m, cm)
- **Romanesco broccoli** - spirals made of spirals
- **River networks** - branching at all scales
- **Lungs** - bronchi branch recursively

**Self-similarity is not identity** - the smaller copies are **similar**, not **identical**.

**Variation in repetition** - each iteration slightly different, but structurally the same.

This is **queer kinship** - resemblance without sameness, family without cloning.

[hr]

[b]Cantor Set: Infinitely Many Points, Zero Length[/b]

The **Cantor set** (Georg Cantor, 1883) is the simplest fractal - and the most paradoxical.

**Construction:**
1. Start with line segment [0, 1]
2. Remove middle third [1/3, 2/3], leaving [0, 1/3] and [2/3, 1]
3. Repeat: remove middle third of each remaining segment
4. Continue infinitely

[color=yellow][b]Code: Cantor Set Recursion[/b][/color]
[code]
func draw_cantor(start: Vector3, width: float, depth: int):
    if depth > max_depth or width < 0.01:
        return  # Base case

    # Draw this segment
    create_line(start, width)

    # Recurse: divide into thirds, keep first and last
    var new_width = width / 3.0
    var next_y = start.y - vertical_spacing

    # Left third
    draw_cantor(Vector3(start.x, next_y, 0), new_width, depth + 1)

    # Right third (skip middle third)
    var right_start = start.x + 2.0 * new_width
    draw_cantor(Vector3(right_start, next_y, 0), new_width, depth + 1)

# After infinite iterations:
# - Infinitely many points remain (uncountably infinite!)
# - Total length = 0 (all removed)
# - Nowhere dense (no intervals, just dust)
[/code]

**Mathematical queerness of Cantor set:**
- **Uncountably infinite points** (same cardinality as real numbers)
- **Yet total measure is zero** (nothing left, yet infinitely many points)
- **Self-similar** - zoom in on any piece, looks like the whole

**The Cantor set is pure paradox** - infinitely many things that take up no space.

It is **existence without extension** - points that are, yet measure nothing.

[hr]

[b]Koch Snowflake: Infinite Perimeter, Finite Area[/b]

The **Koch snowflake** (Helge von Koch, 1904) starts with equilateral triangle, recursively adds smaller triangles to each edge.

**Construction:**
1. Start with equilateral triangle
2. Divide each edge into thirds
3. Replace middle third with two sides of smaller equilateral triangle (pointing outward)
4. Repeat on all edges

[color=yellow][b]Code: Koch Curve[/b][/color]
[code]
func koch_curve(start: Vector3, end: Vector3, depth: int):
    if depth == 0:
        create_line(start, end)  # Base case: draw straight line
        return

    # Divide edge into thirds
    var delta = end - start
    var a = start
    var b = start + delta / 3.0
    var c = start + delta * 2.0 / 3.0
    var d = end

    # Calculate peak of triangle (point above midpoint)
    var mid = (b + c) / 2.0
    var perp = Vector3(-delta.z, delta.y, delta.x).normalized()
    var height = delta.length() / 3.0 * sqrt(3.0) / 2.0
    var peak = mid + perp * height

    # Recurse on four segments
    koch_curve(a, b, depth - 1)
    koch_curve(b, peak, depth - 1)
    koch_curve(peak, c, depth - 1)
    koch_curve(c, d, depth - 1)

# After infinite iterations:
# - Perimeter → infinity (each iteration increases by 4/3)
# - Area → finite (bounded, approximately 1.6× original triangle)
[/code]

**Mathematical queerness:**
- **Infinite boundary** enclosing **finite area**
- **Nowhere differentiable** - no smooth tangent line anywhere
- Every point is a **corner** - jagged at every scale

**The Koch snowflake is ungraspable** - you can never find a smooth section, never compute the exact perimeter.

It is **infinite complexity in bounded space** - the perimeter is infinitely long, yet the shape fits on a page.

[hr]

[b]Sierpinski Triangle: Fractal Dimension 1.585[/b]

The **Sierpinski triangle** (Wacław Sierpiński, 1915) recursively removes triangles.

**Construction:**
1. Start with filled triangle
2. Remove central triangle (connecting midpoints of edges)
3. Repeat on each remaining sub-triangle

[color=yellow][b]Code: Sierpinski Recursion[/b][/color]
[code]
func sierpinski(a: Vector3, b: Vector3, c: Vector3, depth: int):
    if depth == 0:
        create_triangle(a, b, c)  # Base case: draw filled triangle
        return

    # Calculate midpoints
    var ab = (a + b) / 2.0
    var bc = (b + c) / 2.0
    var ca = (c + a) / 2.0

    # Recurse on three outer triangles (skip central triangle)
    sierpinski(a, ab, ca, depth - 1)
    sierpinski(ab, b, bc, depth - 1)
    sierpinski(ca, bc, c, depth - 1)

# After infinite iterations:
# - Area → 0 (removed half each time: 1/2, 1/4, 1/8...)
# - Shape remains (self-similar pattern)
# - Fractal dimension = log(3) / log(2) ≈ 1.585
[/code]

**Fractal dimension** (Hausdorff dimension):

**D = log(N) / log(S)**
- N = number of self-similar pieces
- S = scaling factor

For Sierpinski triangle:
- N = 3 (three sub-triangles)
- S = 2 (each half the size)
- D = log(3) / log(2) ≈ **1.585**

**Not 1D (line), not 2D (plane), but 1.585D.**

**This is queer dimensionality** - refusing integer categories, existing **between**.

A Sierpinski triangle is **more than a line, less than a plane** - dimensionally non-normative.

[hr]

[b]Fractal Dimension: Refusal of Integer Categories[/b]

**Classical dimensions:**
- **0D** = point (no extent)
- **1D** = line (length only)
- **2D** = plane (length × width)
- **3D** = volume (length × width × height)

**Fractals break this** - they have **non-integer dimensions**.

[color=yellow][b]Examples:[/b][/color]
- **Cantor set**: D = log(2) / log(3) ≈ **0.631** (more than points, less than line)
- **Sierpinski triangle**: D ≈ **1.585** (more than line, less than plane)
- **Sierpinski pyramid**: D = log(4) / log(2) = **2.0** (actually integer!)
- **Menger sponge**: D = log(20) / log(3) ≈ **2.727** (more than plane, less than volume)
- **Koch curve**: D = log(4) / log(3) ≈ **1.262**
- **Coastline of Britain**: D ≈ **1.25** (more complex than smooth curve)

**Fractals occupy fractional dimensions** - they refuse to fit into Euclidean categories.

**This is mathematical queerness:**
- Not 1, not 2, but **between**
- Not line, not plane, but **something else**
- Dimensionality as spectrum, not discrete levels

**Fractals prove:** **Reality does not conform to integer dimensions. Nature is fractionally dimensional.**

[hr]

[b]Mandelbrot Set: Infinite Boundary Complexity[/b]

The **Mandelbrot set** (Benoît Mandelbrot, 1980) is defined by iterating a simple equation:

**z_{n+1} = z_n² + c**
- Start with z_0 = 0
- Iterate equation with complex number c
- If |z| stays bounded (doesn't escape to infinity), **c is in the set**

[color=yellow][b]Code: Mandelbrot Test[/b][/color]
[code]
func is_in_mandelbrot(c: Vector2, max_iterations: int) -> bool:
    var z = Vector2.ZERO

    for i in range(max_iterations):
        # Complex multiplication: (a + bi)² = (a² - b²) + (2ab)i
        var z_real = z.x * z.x - z.y * z.y + c.x
        var z_imag = 2.0 * z.x * z.y + c.y
        z = Vector2(z_real, z_imag)

        # Check if escaped (magnitude > 2)
        if z.length_squared() > 4.0:
            return false  # Not in set

    return true  # In set (probably - might escape later)

# Points in set: black
# Points outside: colored by how fast they escape
[/code]

**Mathematical properties:**
- **Connected** - single piece, not scattered
- **Boundary is infinitely complex** - fractal dimension ≈ 2 (fills space)
- **Self-similar** - zoom in on boundary, see miniature Mandelbrot sets
- **Computationally irreducible** - cannot predict membership without iteration

**The Mandelbrot boundary is unknowable** - you can zoom forever, always finding new detail.

It is **infinite complexity at the edge** - the question "is this point in the set?" can require infinite computation.

**Mandelbrot is computational queerness:**
- **Membership is undecidable** (for points on boundary)
- **Simplest rule, most complex shape** (z² + c → infinite detail)
- **Self-reference generates infinity** (iteration creates unbounded complexity)

[hr]

[b]L-Systems: Generative Grammars[/b]

**L-systems** (Lindenmayer systems, Aristid Lindenmayer, 1968) generate fractals via **string rewriting**.

**Rules:**
- Start with **axiom** (initial string)
- Apply **production rules** (replace symbols)
- Repeat for n **generations**

[color=yellow][b]Code: Koch Curve L-System[/b][/color]
[code]
var axiom = "F"
var rules = {
    "F": "F+F-F-F+F"
}

func generate_lsystem(generations: int) -> String:
    var current = axiom

    for gen in range(generations):
        current = apply_rules(current)

    return current

func apply_rules(input: String) -> String:
    var result = ""
    for char in input:
        if char in rules:
            result += rules[char]
        else:
            result += char
    return result

# Generation 0: F
# Generation 1: F+F-F-F+F
# Generation 2: F+F-F-F+F + F+F-F-F+F - F+F-F-F+F - F+F-F-F+F + F+F-F-F+F
# Length grows exponentially: 1, 5, 25, 125, 625...

# Interpretation:
# F = draw forward
# + = turn left 90°
# - = turn right 90°
[/code]

**L-systems separate structure from geometry:**
- **String** = abstract structure (what to do)
- **Turtle graphics** = geometric interpretation (how to draw)

[color=yellow][b]Tree L-System:[/b][/color]
[code]
var axiom = "X"
var rules = {
    "X": "F+[[X]-X]-F[-FX]+X",
    "F": "FF"
}

# F = draw forward
# + = turn left 25°
# - = turn right 25°
# [ = push position/angle to stack
# ] = pop position/angle from stack

# Generates realistic branching tree
# Stack enables branching (save state, explore branch, restore)
[/code]

**L-systems are generative without blueprint** - no explicit tree structure stored, just rewriting rules.

**Grammar creates form** - syntax generates geometry.

This is **algorithmic morphogenesis** - patterns emerge from rules, not from template.

[hr]

[b]Romanesco: Nature's Fractal[/b]

**Romanesco broccoli** is a natural fractal - spirals made of spirals made of spirals.

[color=yellow][b]Fibonacci + Golden Angle:[/b][/color]
[code]
# Romanesco uses:
# - Fibonacci spiral (logarithmic growth)
# - Golden angle (137.5° between florets)

var golden_angle = 137.5  # degrees

func generate_romanesco(center: Vector3, iterations: int):
    for i in range(iterations):
        var angle = deg_to_rad(i * golden_angle)
        var radius = sqrt(i) * 0.5  # Logarithmic spacing

        var position = Vector3(
            center.x + cos(angle) * radius,
            center.y,
            center.z + sin(angle) * radius
        )

        # Create floret at this position
        create_floret(position, i)

        # Recurse: each floret is miniature romanesco
        if i % 5 == 0:  # Don't recurse on every floret (too many)
            generate_romanesco(position, iterations / 2)

# Self-similar spirals at multiple scales
# Nature uses fractal packing for optimal sunlight capture
[/code]

**Fractals in nature optimize** - maximize surface area (for gas exchange, light capture) while minimizing volume.

**Biology is fractal** - lungs, trees, rivers, veins, neurons all use recursive branching.

**Nature discovered fractals before mathematics** - evolution found self-similarity as efficient structure.

[hr]

[b]Menger Sponge: 3D Fractal, Zero Volume[/b]

The **Menger sponge** (Karl Menger, 1926) is 3D Sierpinski - recursively remove cubes.

**Construction:**
1. Start with cube
2. Divide into 27 sub-cubes (3×3×3)
3. Remove central cube and 6 face-centered cubes (leaving 20)
4. Repeat on each remaining sub-cube

[color=yellow][b]Fractal Properties:[/b][/color]
[code]
# After n iterations:
# - Number of cubes: 20^n
# - Volume: (20/27)^n → 0 (approaches zero)
# - Surface area: increases each iteration (→ infinity)

# Fractal dimension: D = log(20) / log(3) ≈ 2.727

# After infinite iterations:
# - Volume = 0 (all removed)
# - Surface area = ∞ (infinitely complex surface)
# - Fractal dimension ≈ 2.727 (between surface and volume)
[/code]

**The Menger sponge is architectural impossibility** - infinite surface area, zero volume.

You could paint it forever (infinite surface), yet it contains nothing (zero volume).

**Queer materiality** - a form that is all surface, no interior. All boundary, no substance.

[hr]

[b]The Queer Politics of Fractals[/b]

Fractals reveal queer potentials:

**1. Self-Similarity Without Identity**
- Each smaller copy is **similar**, not **identical**
- **Variation in repetition** - resemblance without cloning
- Queer kinship (chosen family, not biological clone)

**2. Fractional Dimensionality**
- Not 1D or 2D, but **1.585D**
- **Refusing categorical placement**
- Dimensionality as spectrum (like gender, like sexuality)

**3. Infinite Detail in Finite Space**
- Zoom forever, always more complexity
- **Bounded yet unbounded** - contained but inexhaustible
- Queer bodies (finite flesh, infinite possibilities)

**4. Nowhere Smooth**
- Every point is corner (Koch), gap (Cantor), or fracture (Mandelbrot)
- **No normality** - no standard, typical, or smooth section
- Resistance to reduction (cannot simplify without loss)

**5. Generativity Without Blueprint**
- L-systems generate without template
- **Grammar creates form** - rules, not plan
- Queer reproduction (non-biological, algorithmic kinship)

**6. Computational Irreducibility**
- Mandelbrot boundary unknowable (must iterate)
- **No shortcut** - cannot predict without simulation
- Queer futures (unknowable, emergent, must be lived to be known)

[hr]

[b]What Fractals Reveal[/b]

Fractals show us:

1. **Self-similarity** - whole contains itself at smaller scales
2. **Infinite detail** - zoom forever, always more structure
3. **Cantor set** - infinitely many points, zero length (paradox)
4. **Koch snowflake** - infinite perimeter, finite area
5. **Sierpinski triangle** - fractal dimension 1.585 (queer dimensionality)
6. **Fractal dimension** - non-integer dimensions (refusal of categories)
7. **Mandelbrot set** - infinite boundary complexity, computationally irreducible
8. **L-systems** - generative grammars, form from rules
9. **Romanesco** - nature's fractal, Fibonacci spirals
10. **Menger sponge** - infinite surface, zero volume

**Fractals are recursion made geometric** - self-reference visualized.

**They are also queer ontology:**
- **Self-similarity without identity** (variation in repetition)
- **Fractional dimensionality** (between integers, refusing categories)
- **Infinite within finite** (bounded yet unbounded)
- **Nowhere smooth** (no normal, every point exceptional)
- **Generativity without blueprint** (L-systems, emergence)
- **Computational irreducibility** (unknowable boundaries)

**Fractals prove:** **Complexity is not smooth. Boundaries are infinite. Dimensions are fractional. Nature refuses integer categories.**

**The world is fractal. The queer is fractal. Both resist normative reduction.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Fractals are self-similar patterns repeating at different scales (infinite detail in finite space). Cantor set (infinitely many points, zero length), Koch snowflake (infinite perimeter, finite area), Sierpinski triangle (dimension 1.585). Fractal dimension D = log(N)/log(S) - non-integer dimensions (queer dimensionality, refusing categories). Mandelbrot set (z² + c, infinite boundary complexity, computationally irreducible). L-systems (generative grammars, axiom + rules → form). Romanesco (nature's fractal, Fibonacci + golden angle). Menger sponge (infinite surface, zero volume). Queer fractals: self-similarity without identity, fractional dimensions, infinite within finite, nowhere smooth, generativity without blueprint, computational irreducibility. Recursion made geometric, dimensions as spectrum, resistance to normative reduction.

[hr]

[color=orange][b]Conclusion:[/b] Recursion + Fractals = Self-Reference Embodied[/color]

**Recursion** = self-reference in code (functions calling themselves)
**Fractals** = self-reference in geometry (patterns containing themselves)

Both reveal:
- **No foundation** (turtles all the way down, zoom forever)
- **Infinite from finite** (stack from one function, unbounded detail from bounded space)
- **Non-linear structure** (temporal loops, dimensional fractions)
- **Arbitrary stopping points** (base cases, iteration limits)

**Together, recursion and fractals demonstrate:**

**You can build infinity from self-reference alone.**

No external source. No blueprint. No foundation.

Just a rule that references itself, iterated.

**This is queer generativity** - creating without reproduction, complexity without template, infinity without ground.

**The algorithm contains multitudes.**

'''
