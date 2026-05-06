# Koch Curve Zigzag

Iterated Function Systems compressed shapes into sets of affine maps — the whole living inside its pieces. The Koch curve asks a simpler question. One rule, one segment, applied everywhere simultaneously. No matrix algebra. No probabilistic selection. Just: divide a line into thirds and replace the middle third with two sides of an equilateral triangle. Repeat.

The result is a curve that is continuous everywhere and differentiable nowhere. Finite area, infinite perimeter. Helge von Koch published it in 1904 as a geometric construction that broke the assumption that continuous curves must have tangent lines. A century later, it remains the cleanest demonstration of how a single substitution rule generates unbounded complexity.

## The Rule: Five Points from Two

Every Koch iteration operates on line segments. A segment has a start and an end. The rule produces five points from these two.

```gdscript
func generate_koch_segment(start: Vector2, end: Vector2) -> Array:
    var direction = end - start
    var length = direction.length()
    var unit_dir = direction.normalized()

    var p1 = start
    var p2 = start + unit_dir * (length / 3.0)
    var p4 = start + unit_dir * (2.0 * length / 3.0)
    var p5 = end

    # Peak of the equilateral triangle
    var perpendicular = Vector2(-unit_dir.y, unit_dir.x)
    var triangle_height = (length / 3.0) * sqrt(3) / 2.0
    var p3 = p2 + perpendicular * triangle_height

    return [p1, p2, p3, p4, p5]
```

p1 and p5 are the original endpoints. p2 sits one-third along the segment. p4 sits two-thirds along. p3 is the apex — offset perpendicular to the segment by the height of an equilateral triangle whose base is one-third the segment length. The perpendicular is computed by rotating the direction vector 90 degrees: swap x and y, negate one component.

One segment becomes four. The middle third vanishes, replaced by two sides of a triangle that juts outward. The total length increases by a factor of 4/3 with each application. After n iterations, the length is (4/3)^n times the original. As n approaches infinity, the length approaches infinity. The curve never stops growing.

## Iteration: The Transformation Loop

The Koch snowflake starts as an equilateral triangle — three segments closing a loop.

```gdscript
func initialize_koch_curve():
    points.clear()
    var triangle_size = 40.0
    var height = triangle_size * sqrt(3) / 2.0

    points.append(Vector2(-triangle_size/2, -height/3))
    points.append(Vector2(triangle_size/2, -height/3))
    points.append(Vector2(0, 2*height/3))
    points.append(Vector2(-triangle_size/2, -height/3))  # Close the triangle

    current_iteration = 0
    update_vr_optimized_visual()
```

Four points — three vertices plus the closing point that returns to the start. The triangle has side length 40 units. The height of an equilateral triangle is `side * sqrt(3) / 2`. The vertices are centered at the origin with the base sitting below center.

Each iteration walks through every consecutive pair of points and applies the Koch rule:

```gdscript
func apply_koch_transformation():
    var new_points = []

    for i in range(points.size() - 1):
        var start = points[i]
        var end = points[i + 1]

        var koch_points = generate_koch_segment(start, end)

        # Add all points except the last (avoid duplication)
        for j in range(koch_points.size() - 1):
            new_points.append(koch_points[j])

    # Close the curve
    new_points.append(points[-1])
    points = new_points
```

The inner loop adds four of the five points from each segment transformation — p1 through p4. The fifth point (p5) is the same as p1 of the next segment, so it is skipped to avoid duplication. The final closing point is appended after the loop.

Iteration 0: 3 segments (triangle). Iteration 1: 12 segments. Iteration 2: 48. Iteration 3: 192. Iteration 4: 768. The pattern is 3 × 4^n. Each iteration quadruples the number of segments. The artifact cycles through iterations on a timer, resetting to the base triangle after reaching the maximum:

```gdscript
func generate_next_iteration():
    current_iteration = (current_iteration + 1) % (max_iterations + 1)

    if current_iteration == 0:
        initialize_koch_curve()
    else:
        apply_koch_transformation()
        update_vr_optimized_visual()
```

The modular arithmetic wraps the iteration counter back to zero. The learner watches the curve grow — triangle to star to snowflake to intricate boundary — then snap back and start again. The visual loop makes the exponential growth visceral. At iteration 1, the shape is recognizably a Star of David. At iteration 4, the boundary is so dense it reads as a continuous edge at normal viewing distance. Zoom in and the angles reappear.

## Fractal Dimension: log 4 / log 3

The Koch curve has dimension D = log(4) / log(3) ≈ 1.2619. Four self-similar pieces, each scaled down by a factor of 3. More than a line (D = 1), less than a plane (D = 2).

```gdscript
# Fractal dimension from self-similarity
var num_copies := 4    # Each segment becomes 4 segments
var scale_factor := 3  # Each new segment is 1/3 the length
var dimension := log(num_copies) / log(scale_factor)  # 1.2619...
```

Compare with the structures from earlier in the Recursive Emergence sequence. The Sierpinski triangle has dimension log(3)/log(2) ≈ 1.585 — it fills more of the plane because three copies at half scale cover more area than four copies at one-third scale. The Cantor set has dimension log(2)/log(3) ≈ 0.631 — less than a line, because it keeps removing material. The Koch curve adds material — every iteration increases the boundary length — yet the area it encloses converges to a finite value. Infinite perimeter, finite area. The dimension 1.26 captures exactly this: a curve that sprawls more than a line but never fills a region.

## The Coastline Paradox

Benoit Mandelbrot asked: how long is the coast of Britain? The answer depends on the ruler. A 200km ruler gives one number. A 50km ruler, tracing smaller inlets and peninsulas, gives a larger number. A 1km ruler, following every beach and cove, gives a much larger number. The smaller the ruler, the longer the coast.

The Koch curve is this paradox made exact. At iteration n, the total length is:

```gdscript
func get_fractal_info() -> Dictionary:
    return {
        "iteration": current_iteration,
        "segments": total_segments,
        "theoretical_length": pow(4.0/3.0, float(current_iteration)) * 12.0,
    }
```

The base triangle has perimeter 3 × 40 = 120 units. After one iteration: 120 × (4/3) = 160. After two: 120 × (4/3)^2 ≈ 213. After four: 120 × (4/3)^4 ≈ 379. The length grows without bound. Measure the Koch snowflake with any finite ruler and you get a finite answer — but that answer increases as the ruler shrinks. In the limit, the length is infinite.

This is not a mathematical curiosity. Real coastlines behave the same way. Mandelbrot measured the dimension of the west coast of Britain at approximately 1.25 — strikingly close to the Koch curve's 1.26. The Koch curve is a deterministic model of a phenomenon that appears everywhere in nature: boundaries that resist measurement because they contain structure at every scale.

## VR Rendering: ArrayMesh Instead of Nodes

The artifact in this map renders the Koch curve as a single `ArrayMesh` — a ribbon of quads following the point sequence. This is the critical VR optimization. At iteration 4, the curve has 768 segments. Creating 768 individual `MeshInstance3D` nodes would mean 768 draw calls. The `ArrayMesh` packs all geometry into a single surface.

```gdscript
func update_vr_optimized_visual():
    total_segments = points.size() - 1
    var array_mesh = ArrayMesh.new()
    var vertices = PackedVector3Array()
    var indices = PackedInt32Array()
    var colors = PackedColorArray()

    var ribbon_width = 0.4
    var vertex_index = 0

    for i in range(points.size() - 1):
        var start = Vector3(points[i].x, points[i].y, 0)
        var end = Vector3(points[i + 1].x, points[i + 1].y, 0)

        var direction = (end - start).normalized()
        var perpendicular = Vector3(-direction.y, direction.x, 0) * ribbon_width

        # Quad: two triangles
        vertices.append(start + perpendicular)
        vertices.append(start - perpendicular)
        vertices.append(end - perpendicular)
        vertices.append(end + perpendicular)

        indices.append(vertex_index)
        indices.append(vertex_index + 1)
        indices.append(vertex_index + 2)
        indices.append(vertex_index)
        indices.append(vertex_index + 2)
        indices.append(vertex_index + 3)

        vertex_index += 4

    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_INDEX] = indices
    arrays[Mesh.ARRAY_COLOR] = colors
    array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    koch_mesh_instance.mesh = array_mesh
```

Each segment becomes a quad — four vertices, two triangles, six indices. The perpendicular offset creates a ribbon of constant width. The 2D Koch points are promoted to 3D by setting z = 0. The color of each segment encodes both its position along the curve (color_intensity) and the current iteration depth (iteration_intensity), producing a gradient that shifts as the curve evolves.

This is the same principle as the `MultiMesh` approach from the Fractals sequence — batch geometry into minimal draw calls. The difference is that `ArrayMesh` gives vertex-level control. Each quad can have its own color, its own UV coordinates, its own normal. `MultiMesh` gives per-instance transforms but shares a single mesh shape. For a curve made of identical quads with varying colors, `ArrayMesh` is the natural choice.

## Iterative vs Recursive Implementation

The Koch curve is defined recursively — apply the rule, then apply it to the result. But the artifact implements it iteratively. Each call to `apply_koch_transformation()` walks the current point list once, producing a new list. No function calls itself. No stack grows.

This is a deliberate choice. The recursive definition of the Koch curve would look like:

```gdscript
# Recursive approach (NOT used — would overflow at depth 4+)
func koch_recursive(start: Vector2, end: Vector2, depth: int) -> Array:
    if depth <= 0:
        return [start, end]

    var seg = generate_koch_segment(start, end)
    var result = []
    result.append_array(koch_recursive(seg[0], seg[1], depth - 1))
    result.append_array(koch_recursive(seg[1], seg[2], depth - 1))
    result.append_array(koch_recursive(seg[2], seg[3], depth - 1))
    result.append_array(koch_recursive(seg[3], seg[4], depth - 1))
    return result
```

Four recursive calls per segment. At depth 4: 4^4 = 256 calls, each creating arrays. At depth 6: 4,096 calls. The call stack grows linearly with depth, but the array allocations grow exponentially. The iterative approach avoids this entirely — one flat loop per iteration, one array allocation, no stack growth.

The IFS maps in the previous step used random iteration — pick a transformation at random, apply it, plot the point. That works for attractors where the order of operations does not matter. The Koch curve is deterministic. Every segment must be replaced simultaneously. The iterative approach preserves this simultaneity — the old point list is read, the new one is written, and then the swap happens.

## From Deterministic to Stochastic

The Koch curve is perfectly regular. Every segment gets the same rule. Every iteration produces the same angular pattern. Nature is not this orderly. Real coastlines, mountain ridges, and cloud boundaries share the Koch curve's self-similarity but not its symmetry.

Randomizing the Koch rule introduces variation:

```gdscript
func generate_random_koch_segment(start: Vector2, end: Vector2) -> Array:
    var direction = end - start
    var length = direction.length()
    var unit_dir = direction.normalized()

    # Randomize the split points
    var t1 = randf_range(0.25, 0.4)
    var t2 = randf_range(0.6, 0.75)

    var p1 = start
    var p2 = start + unit_dir * (length * t1)
    var p4 = start + unit_dir * (length * t2)
    var p5 = end

    # Randomize the height and direction of the peak
    var perpendicular = Vector2(-unit_dir.y, unit_dir.x)
    var peak_height = (length * (t2 - t1)) * randf_range(0.3, 0.9)
    var side = 1 if randf() > 0.5 else -1
    var p3 = lerp(p2, p4, 0.5) + perpendicular * peak_height * side

    return [p1, p2, p3, p4, p5]
```

The split points jitter. The triangle height varies. The peak can face either direction. The result is a curve that shares the Koch curve's fractal dimension but not its crystalline regularity. Apply this to a closed polygon and the boundary develops the irregular, organic quality of a real coastline.

This is the lambda threshold in action. The deterministic Koch curve sits at low lambda — pure order, perfect prediction, every scale a mirror of every other. Randomizing the parameters pushes lambda upward. The self-similarity softens. The boundary becomes less predictable but more natural. At the edge of chaos, the curve is neither perfectly regular nor completely random — it has structure that cannot be compressed to a single rule but also cannot be dismissed as noise.

## Toward the Infinite: Mandelbrot

The Koch curve constructs its fractal from the outside — start with a shape, apply a rule, watch complexity accumulate. The Mandelbrot set, which the next map explores, works from the inside — iterate a function on complex numbers and classify each point by whether the iteration escapes to infinity. The Koch curve is constructive. The Mandelbrot set is classificatory. Both produce infinite structure from finite rules, but the nature of that structure is fundamentally different.

Koch builds a boundary. Mandelbrot reveals a boundary that was always there — the border between convergence and divergence in the complex plane. The Koch curve's dimension is known exactly: log(4)/log(3). The Mandelbrot set's boundary has dimension 2 — it is as complex as a filled region, despite being a curve. Where Koch is clean and computable, Mandelbrot is wild and empirical. The corridor narrows toward that wildness.

## Possible Artifacts

**koch_depth_slider** — An interactive artifact where the learner controls iteration depth with a slider (0–6). Each position regenerates the curve in real time. A counter displays the number of segments and total length at each depth. The exponential relationship between depth and complexity becomes manipulable rather than observed.

**koch_dimension_ruler** — A measurement tool that overlays rulers of different lengths on the Koch curve and counts how many ruler-lengths fit. At ruler length L, the count follows L^(-D) where D ≈ 1.26. The learner slides the ruler length and watches the count climb — making the coastline paradox interactive and the fractal dimension tangible.

**stochastic_koch_comparator** — Side-by-side display showing the deterministic Koch curve next to a randomized variant at the same iteration depth. Both start from the same triangle. The deterministic version is crystalline. The stochastic version is organic. A lambda slider controls how much randomness enters the split points and peak height — from λ=0 (pure Koch) to λ=0.5 (coastline-like) to λ=1.0 (chaotic boundary).
