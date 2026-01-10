**Fractals**
Self-Similarity, Infinite Detail, Queer Dimensionality

**A fractal is a pattern that repeats at different scales.**

Look close: you see the same structure. Zoom in: still the same structure. Zoom forever: **always more detail, never smooth**.

Fractals are **geometric self-reference** - the whole contains copies of itself, infinitely nested.

They are **infinite detail in finite space** - bounded area, unbounded complexity.

And they reveal something mathematically queer: **dimensions between integers**. Not 1D, not 2D, but **1.585D**. Not line, not plane, but **between**.

**Fractals refuse categorical placement.**

---

## Self-Similarity: The Whole Contains Itself

**Self-similar** means a pattern looks similar to itself at different scales.

**Examples in Nature:**
- **Ferns** - each frond is a miniature fern
- **Coastlines** - jagged at every zoom level (km, m, cm)
- **Romanesco broccoli** - spirals made of spirals
- **River networks** - branching at all scales
- **Lungs** - bronchi branch recursively

**Self-similarity is not identity** - the smaller copies are **similar**, not **identical**.

**Variation in repetition** - each iteration slightly different, but structurally the same.

This is **queer kinship** - resemblance without sameness, family without cloning.

---

## Cantor Set: Infinitely Many Points, Zero Length

The **Cantor set** (Georg Cantor, 1883) is the simplest fractal - and the most paradoxical.

**Construction:**
1. Start with line segment [0, 1]
2. Remove middle third [1/3, 2/3], leaving [0, 1/3] and [2/3, 1]
3. Repeat: remove middle third of each remaining segment
4. Continue infinitely

**Code: Cantor Set Recursion**

```
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
```

**Mathematical queerness of Cantor set:**
- **Uncountably infinite points** (same cardinality as real numbers)
- **Yet total measure is zero** (nothing left, yet infinitely many points)
- **Self-similar** - zoom in on any piece, looks like the whole

**The Cantor set is pure paradox** - infinitely many things that take up no space.

It is **existence without extension** - points that are, yet measure nothing.

---

## Koch Snowflake: Infinite Perimeter, Finite Area

The **Koch snowflake** (Helge von Koch, 1904) starts with equilateral triangle, recursively adds smaller triangles to each edge.

**Construction:**
1. Start with equilateral triangle
2. Divide each edge into thirds
3. Replace middle third with two sides of smaller equilateral triangle (pointing outward)
4. Repeat on all edges

**Code: Koch Curve**

```
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
```

**Mathematical queerness:**
- **Infinite boundary** enclosing **finite area**
- **Nowhere differentiable** - no smooth tangent line anywhere
- Every point is a **corner** - jagged at every scale

**The Koch snowflake is ungraspable** - you can never find a smooth section, never compute the exact perimeter.

It is **infinite complexity in bounded space** - the perimeter is infinitely long, yet the shape fits on a page.

---

## Sierpinski Triangle: Fractal Dimension 1.585

The **Sierpinski triangle** (Wacław Sierpiński, 1915) recursively removes triangles.

**Construction:**
1. Start with filled triangle
2. Remove central triangle (connecting midpoints of edges)
3. Repeat on each remaining sub-triangle

**Code: Sierpinski Recursion**

```
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
```

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

---

## Fractal Dimension: Refusal of Integer Categories

**Classical dimensions:**
- **0D** = point (no extent)
- **1D** = line (length only)
- **2D** = plane (length × width)
- **3D** = volume (length × width × height)

**Fractals break this** - they have **non-integer dimensions**.

**Examples:**
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

---

## Mandelbrot Set: Infinite Boundary Complexity

The **Mandelbrot set** (Benoît Mandelbrot, 1980) is defined by iterating a simple equation:

**z_{n+1} = z_n² + c**
- Start with z_0 = 0
- Iterate equation with complex number c
- If |z| stays bounded (doesn