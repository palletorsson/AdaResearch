<<<ADA_BUNDLE>>>
sequence: fractals
file: tutorial.md
maps: 11
skipped_passing: 0
created: 2026-04-24T05:20:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Fractal_Recursion>>>
# Fractal Recursion

A function that calls itself. Depth bounded, structure unbounded.

Recursive factorial.

```gdscript
func factorial(n: int) -> int:
    if n <= 1: return 1
    return n * factorial(n - 1)
```

Base case at 1; recursive call with smaller argument. The call stack captures the recursion depth.

Recursive tree structure.

```gdscript
func recursive_tree(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0: return
    var end := start + direction * length
    draw_segment(start, end)
    var axis: Vector3 = direction.cross(Vector3.UP).normalized()
    var left: Vector3 = direction.rotated(axis, deg_to_rad(20))
    var right: Vector3 = direction.rotated(axis, deg_to_rad(-20))
    recursive_tree(end, left, length * 0.7, depth - 1)
    recursive_tree(end, right, length * 0.7, depth - 1)
```

Binary branching. Each call spawns two shorter children.

Memoisation.

```gdscript
var memo: Dictionary = {}

func fib(n: int) -> int:
    if n in memo: return memo[n]
    if n <= 1: return n
    var result: int = fib(n - 1) + fib(n - 2)
    memo[n] = result
    return result
```

Cache results. Fibonacci without memoisation is exponential; with it, linear.

Tail-recursive form.

```gdscript
func sum_tail(n: int, acc: int = 0) -> int:
    if n == 0: return acc
    return sum_tail(n - 1, acc + n)
```

Accumulator carries state forward. Compilers can optimise this into a loop.

Iterative equivalent.

```gdscript
func sum_iterative(n: int) -> int:
    var total: int = 0
    while n > 0:
        total += n
        n -= 1
    return total
```

Same computation; no call stack. Faster and safer for large n.

Detect stack depth.

```gdscript
func measure_depth(n: int, depth: int = 0) -> int:
    if n <= 0: return depth
    return measure_depth(n - 1, depth + 1)
```

Returns the number of recursive calls made. Useful for testing stack-overflow limits.

Self-similar structure.

```gdscript
func render_fractal_at(position: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        spawn_cube_at(position, size * 0.3)
        return
    var offset: float = size * 0.5
    for dx in [-1, 1]:
        for dy in [-1, 1]:
            for dz in [-1, 1]:
                render_fractal_at(position + Vector3(dx, dy, dz) * offset, size * 0.5, depth - 1)
```

Each cube spawns 8 smaller cubes. Cantor dust in 3D.

You can now write recursive functions, memoise their results, recognise tail recursion, convert to iteration, measure call depth, and build self-similar 3D structures. Fractal_RecursiveTrees extends into tree morphologies.

<<<MAP: Fractal_RecursiveTrees>>>
# Fractal Recursive Trees

Branching trees. Parametric binary subdivision.

Define tree parameters.

```gdscript
@export var branch_angle: float = 25.0
@export var length_ratio: float = 0.75
@export var max_depth: int = 6
```

Angle, shrink ratio, depth. Three numbers define the tree's shape.

Build the tree.

```gdscript
func build_tree(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0:
        spawn_leaf(start)
        return
    var end := start + direction * length
    spawn_branch(start, end, depth)
    var axis: Vector3 = direction.cross(Vector3.UP).normalized()
    var left: Vector3 = direction.rotated(axis, deg_to_rad(branch_angle))
    var right: Vector3 = direction.rotated(axis, deg_to_rad(-branch_angle))
    build_tree(end, left, length * length_ratio, depth - 1)
    build_tree(end, right, length * length_ratio, depth - 1)
```

Binary branching with fixed angle and shrink. Exponentially many leaves.

Trunk with taper.

```gdscript
func spawn_branch(start: Vector3, end: Vector3, depth: int) -> void:
    var branch := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.02 * depth
    cylinder.bottom_radius = 0.02 * (depth + 1)
    cylinder.height = start.distance_to(end)
    branch.mesh = cylinder
    branch.position = (start + end) / 2
    branch.look_at(end, Vector3.UP)
    branch.rotate_object_local(Vector3.RIGHT, PI / 2)
    add_child(branch)
```

Thicker at the trunk, thinner at the tips. The taper scales with depth.

Add randomness.

```gdscript
func build_random_tree(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0:
        spawn_leaf(start)
        return
    var end := start + direction * length
    spawn_branch(start, end, depth)
    var axis := Vector3(randfn(0, 0.2), 0, randfn(0, 0.2)).cross(direction).normalized()
    var left := direction.rotated(axis, deg_to_rad(randf_range(15, 35)))
    var right := direction.rotated(axis, deg_to_rad(-randf_range(15, 35)))
    build_random_tree(end, left, length * randf_range(0.6, 0.85), depth - 1)
    build_random_tree(end, right, length * randf_range(0.6, 0.85), depth - 1)
```

Each call uses slightly different parameters. Trees no longer look identical.

Three-way branching.

```gdscript
func build_ternary(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0:
        spawn_leaf(start)
        return
    var end := start + direction * length
    spawn_branch(start, end, depth)
    for angle_deg in [30, 0, -30]:
        var axis: Vector3 = direction.cross(Vector3.UP).normalized()
        var rotated := direction.rotated(axis, deg_to_rad(angle_deg))
        build_ternary(end, rotated, length * 0.75, depth - 1)
```

Three children per branch. Denser tree than binary; matches how plants often actually grow.

Approximate biology.

```gdscript
func phyllotactic_angle(i: int) -> float:
    return i * 137.5  # golden angle
```

The golden angle produces Fibonacci-like spiral patterns that appear in plant phyllotaxis. 137.5° between successive branches.

Build a tree and animate its growth.

```gdscript
var growth_progress: float = 0.0

func _process(delta: float) -> void:
    growth_progress = min(1.0, growth_progress + delta * 0.2)
    update_branch_lengths_to(growth_progress)
```

Branches grow from 0 to full length. The learner watches the tree form.

You can now build parametric trees with binary/ternary branching, random variation, phyllotactic spirals, and animated growth. Fractal_CantorSet extends into 1D deletion fractals.

<<<MAP: Fractal_CantorSet>>>
# Cantor Set

Remove the middle third. Recurse. Fractal dimension 0.631.

Generate Cantor intervals.

```gdscript
func cantor_intervals(start: float, end: float, depth: int) -> Array:
    if depth == 0:
        return [[start, end]]
    var third_length: float = (end - start) / 3.0
    var left_intervals: Array = cantor_intervals(start, start + third_length, depth - 1)
    var right_intervals: Array = cantor_intervals(end - third_length, end, depth - 1)
    return left_intervals + right_intervals
```

Recursive: split into thirds, keep outer thirds. 2^n intervals at depth n.

Render intervals as cylinders.

```gdscript
func render_cantor(intervals: Array, y: float, length: float) -> void:
    for interval in intervals:
        var segment := MeshInstance3D.new()
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.02
        cylinder.bottom_radius = 0.02
        cylinder.height = interval[1] - interval[0]
        segment.mesh = cylinder
        segment.position = Vector3((interval[0] + interval[1]) / 2, y, 0)
        segment.rotate_object_local(Vector3.RIGHT, PI / 2)
        add_child(segment)
```

Each interval is a short cylinder. The pattern is a horizontal line of shrinking bars.

Stack generations vertically.

```gdscript
func render_generations(max_depth: int) -> void:
    for depth in max_depth + 1:
        var intervals: Array = cantor_intervals(0.0, 10.0, depth)
        render_cantor(intervals, -depth * 0.3, 0.0)
```

Each row shows one generation. The pattern tree develops downward.

Compute the set's measure.

```gdscript
func measure(depth: int, total_length: float) -> float:
    var remaining: float = pow(2.0 / 3.0, depth) * total_length
    return remaining
```

Each generation multiplies the total length by 2/3. Converges to zero as depth grows.

Compute fractal dimension.

```gdscript
func cantor_dimension() -> float:
    return log(2) / log(3)
```

Two pieces at 1/3 scale. D = log(2)/log(3) ≈ 0.631. Between 0 and 1 — fractal rather than linear.

Cantor dust (2D variant).

```gdscript
func cantor_dust(depth: int, size: float) -> Array:
    if depth == 0:
        return [Vector2.ZERO]
    var points: Array = []
    var sub_points: Array = cantor_dust(depth - 1, size / 3)
    for dx in [0, 2]:
        for dy in [0, 2]:
            for sub in sub_points:
                points.append(sub + Vector2(dx * size / 3, dy * size / 3))
    return points
```

Four corners at each scale. 4^n points at depth n.

Visualise dimension.

```gdscript
func animate_dimension_comparison() -> void:
    var cantor_d: float = cantor_dimension()
    var sierpinski_d: float = log(3) / log(2)
    var menger_d: float = log(20) / log(3)
    display_dimension_graph([cantor_d, sierpinski_d, menger_d], ["Cantor", "Sierpinski", "Menger"])
```

Three fractals, three dimensions. The comparison shows fractal dimension lives between integers.

You can now generate Cantor intervals, render them as cylinders, compute the fractal dimension, and extend to Cantor dust in 2D. Fractal_KochSierpinski extends into additive and multiplicative 2D fractals.

<<<MAP: Fractal_KochSierpinski>>>
# Koch & Sierpinski

Additive Koch. Subtractive Sierpinski.

Koch curve recursion.

```gdscript
func koch_segment(a: Vector2, b: Vector2, depth: int) -> Array:
    if depth == 0:
        return [[a, b]]
    var third: Vector2 = (b - a) / 3.0
    var p1: Vector2 = a + third
    var p2: Vector2 = a + third * 2
    var peak: Vector2 = p1 + third.rotated(-PI / 3)
    return (
        koch_segment(a, p1, depth - 1) +
        koch_segment(p1, peak, depth - 1) +
        koch_segment(peak, p2, depth - 1) +
        koch_segment(p2, b, depth - 1)
    )
```

Each segment splits into four. The middle third is replaced by a peak forming an equilateral triangle.

Build the Koch snowflake.

```gdscript
func koch_snowflake(centre: Vector2, radius: float, depth: int) -> Array:
    var angles := [PI / 2, PI / 2 + TAU / 3, PI / 2 + 2 * TAU / 3]
    var points: Array = []
    for a in angles:
        points.append(centre + Vector2(cos(a), sin(a)) * radius)
    return (
        koch_segment(points[0], points[1], depth) +
        koch_segment(points[1], points[2], depth) +
        koch_segment(points[2], points[0], depth)
    )
```

Three Koch segments forming a triangle. The result is the Koch snowflake.

Sierpinski triangle.

```gdscript
func sierpinski_triangle(a: Vector2, b: Vector2, c: Vector2, depth: int) -> Array:
    if depth == 0:
        return [[a, b, c]]
    var ab: Vector2 = (a + b) / 2
    var bc: Vector2 = (b + c) / 2
    var ca: Vector2 = (c + a) / 2
    return (
        sierpinski_triangle(a, ab, ca, depth - 1) +
        sierpinski_triangle(ab, b, bc, depth - 1) +
        sierpinski_triangle(ca, bc, c, depth - 1)
    )
```

Three sub-triangles at corners; central triangle removed. Classic substructure.

Render Sierpinski.

```gdscript
func render_sierpinski(triangles: Array) -> void:
    for tri in triangles:
        var polygon := MeshInstance3D.new()
        polygon.mesh = build_triangle_mesh(tri[0], tri[1], tri[2])
        add_child(polygon)
```

Each returned triangle becomes a filled polygon. Visible holes form the pattern.

Sierpinski carpet.

```gdscript
func sierpinski_carpet(corner: Vector2, size: float, depth: int) -> Array:
    if depth == 0:
        return [Rect2(corner, Vector2(size, size))]
    var third: float = size / 3.0
    var squares: Array = []
    for dx in 3:
        for dy in 3:
            if dx == 1 and dy == 1: continue  # remove centre
            squares += sierpinski_carpet(corner + Vector2(dx * third, dy * third), third, depth - 1)
    return squares
```

Nine sub-squares minus the centre. Eight survive.

Compute scaling ratios.

```gdscript
func dimension(pieces: int, ratio: float) -> float:
    return log(pieces) / log(1.0 / ratio)
```

Number of self-similar pieces divided by log of scale factor. Koch: D = log(4)/log(3) ≈ 1.26. Sierpinski: D = log(3)/log(2) ≈ 1.58.

You can now render Koch curves, Koch snowflakes, Sierpinski triangles, Sierpinski carpets, and compute their fractal dimensions. Fractal_MengerSponge extends into the 3D version.

<<<MAP: Fractal_MengerSponge>>>
# Menger Sponge

27 sub-cubes. Remove 7. Recurse on the remaining 20.

Generate sub-cube positions.

```gdscript
func menger_recursion(origin: Vector3, size: float, depth: int) -> Array:
    if depth == 0:
        return [[origin, size]]
    var result: Array = []
    var third: float = size / 3.0
    for x in 3:
        for y in 3:
            for z in 3:
                # Remove centre of each face and the very centre
                var face_count: int = 0
                if x == 1: face_count += 1
                if y == 1: face_count += 1
                if z == 1: face_count += 1
                if face_count >= 2: continue
                var sub_origin: Vector3 = origin + Vector3(x, y, z) * third
                result += menger_recursion(sub_origin, third, depth - 1)
    return result
```

Seven cubes are face-centres or the very centre. Twenty survive. Recurse on survivors.

Render the cubes.

```gdscript
func render_menger(cubes: Array) -> void:
    for cube in cubes:
        var mesh := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(cube[1], cube[1], cube[1])
        mesh.mesh = box
        mesh.position = cube[0] + Vector3(cube[1], cube[1], cube[1]) / 2
        add_child(mesh)
```

Each surviving cube becomes a MeshInstance3D. The sponge emerges.

Use MultiMesh for performance.

```gdscript
func render_menger_multimesh(cubes: Array) -> void:
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = BoxMesh.new()
    multimesh.instance_count = cubes.size()
    for i in cubes.size():
        var t := Transform3D.IDENTITY
        t.origin = cubes[i][0] + Vector3.ONE * cubes[i][1] / 2
        t = t.scaled(Vector3.ONE * cubes[i][1])
        multimesh.set_instance_transform(i, t)
    var instance := MultiMeshInstance3D.new()
    instance.multimesh = multimesh
    add_child(instance)
```

One draw call for all cubes. Essential for deep recursion.

Count surviving cubes per depth.

```gdscript
func count_at_depth(depth: int) -> int:
    return int(pow(20, depth))
```

20^n cubes at depth n. Depth 4: 160,000 cubes.

Fractal dimension.

```gdscript
func menger_dimension() -> float:
    return log(20) / log(3)
```

D = log(20)/log(3) ≈ 2.727. A 3D sponge with dimension between 2 and 3.

Handle deep recursion.

```gdscript
@export var depth_limit: int = 4

func safe_render(depth: int) -> void:
    if depth > depth_limit:
        print("Depth cap reached; limiting to ", depth_limit)
        depth = depth_limit
    var cubes: Array = menger_recursion(Vector3.ZERO, 3.0, depth)
    render_menger_multimesh(cubes)
```

Performance guard. Beyond depth 4, even MultiMesh struggles.

Interactive depth slider.

```gdscript
func _on_depth_changed(new_depth: int) -> void:
    for child in get_children():
        if child is MultiMeshInstance3D: child.queue_free()
    safe_render(new_depth)
```

User-adjustable depth. Scene rebuilds on change.

You can now generate the Menger sponge recursively, render it efficiently with MultiMesh, cap recursion depth, compute its fractal dimension, and support interactive depth changes. Fractal_GoldenSpiral extends into organic spirals.

<<<MAP: Fractal_GoldenSpiral>>>
# Golden Spiral

Fibonacci rectangles. A spiral through their quarter-arcs.

Compute Fibonacci numbers.

```gdscript
func fib(n: int) -> int:
    if n <= 1: return n
    var a: int = 0
    var b: int = 1
    for _i in range(n - 1):
        var c: int = a + b
        a = b
        b = c
    return b
```

Iterative. Linear time.

Golden ratio.

```gdscript
const PHI: float = 1.61803398875  # (1 + sqrt(5)) / 2
```

Limit of consecutive Fibonacci ratios. Ubiquitous in art and nature.

Build Fibonacci rectangles.

```gdscript
func fibonacci_rectangles(count: int) -> Array:
    var rectangles: Array = []
    var position := Vector2.ZERO
    var direction := Vector2.RIGHT
    for i in count:
        var side: float = float(fib(i + 1))
        var rect := Rect2(position, Vector2(side, side))
        rectangles.append(rect)
        position = rect.end if direction.x > 0 else Vector2(rect.position.x, rect.end.y)
        direction = direction.rotated(PI / 2)
    return rectangles
```

Each rectangle is a square with side equal to the next Fibonacci number. They tile around a shared corner.

Draw a quarter-arc in each rectangle.

```gdscript
func quarter_arc(centre: Vector2, radius: float, start_angle: float) -> Array:
    var points: Array = []
    for i in 32:
        var t: float = float(i) / 31
        var angle: float = start_angle + t * PI / 2
        points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
    return points
```

32 points along a quarter circle. Smooth enough for a visible curve.

Render the spiral.

```gdscript
func render_golden_spiral(rectangles: Array) -> void:
    var rotation: float = PI
    for rect in rectangles:
        var centre: Vector2 = rect.position
        var radius: float = rect.size.x
        var arc_points: Array = quarter_arc(centre, radius, rotation)
        for i in range(1, arc_points.size()):
            spawn_line_segment(arc_points[i - 1], arc_points[i])
        rotation += PI / 2
```

Sequential quarter-arcs form the spiral. Each arc starts where the previous ended.

Spawn in 3D.

```gdscript
func spawn_line_segment(a: Vector2, b: Vector2) -> void:
    var line := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.03
    cylinder.bottom_radius = 0.03
    var a3 := Vector3(a.x, 0, a.y)
    var b3 := Vector3(b.x, 0, b.y)
    cylinder.height = a3.distance_to(b3)
    line.mesh = cylinder
    line.position = (a3 + b3) / 2
    line.look_at(b3, Vector3.UP)
    line.rotate_object_local(Vector3.RIGHT, PI / 2)
    add_child(line)
```

2D to 3D: XY becomes XZ, Y stays Y. Places the spiral on the ground plane.

You can now compute Fibonacci numbers, tile rectangles, render quarter-arcs, and form the golden spiral. Fractal_MandelbrotSet extends into complex-dynamics fractals.

<<<MAP: Fractal_MandelbrotSet>>>
# Mandelbrot Set

z_{n+1} = z_n² + c. Points c that don't escape form the set.

Test a single point.

```gdscript
func mandelbrot_iterations(c: Vector2, max_iter: int = 100) -> int:
    var z := Vector2.ZERO
    for i in max_iter:
        z = Vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c
        if z.length_squared() > 4:
            return i
    return max_iter
```

Iterate z = z² + c. Return iteration count if it escapes, max_iter if it stays bounded.

Render the set as a texture.

```gdscript
func render_mandelbrot(bounds: Rect2, resolution: Vector2i, max_iter: int = 100) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for py in resolution.y:
        for px in resolution.x:
            var c := Vector2(
                bounds.position.x + (px / float(resolution.x)) * bounds.size.x,
                bounds.position.y + (py / float(resolution.y)) * bounds.size.y
            )
            var iter: int = mandelbrot_iterations(c, max_iter)
            var color: Color = iter_to_color(iter, max_iter)
            image.set_pixel(px, py, color)
    return ImageTexture.create_from_image(image)
```

Iterate every pixel; colour by iteration count. The characteristic Mandelbrot silhouette emerges.

Colour mapping.

```gdscript
func iter_to_color(iter: int, max_iter: int) -> Color:
    if iter == max_iter: return Color.BLACK
    var t: float = float(iter) / max_iter
    return Color.from_hsv(t * 0.7, 0.9, 0.9)
```

Points in the set (max iterations reached) are black; escape times colour the boundary.

Smooth colouring.

```gdscript
func smooth_iter(c: Vector2, max_iter: int = 100) -> float:
    var z := Vector2.ZERO
    for i in max_iter:
        z = Vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c
        if z.length_squared() > 4:
            return i + 1 - log(log(z.length()) / log(2))
    return max_iter
```

Fractional iteration count. Eliminates banding in the colour gradient.

Zoom control.

```gdscript
var view_centre: Vector2 = Vector2(-0.75, 0.0)
var view_width: float = 3.0

func zoom(factor: float, at: Vector2) -> void:
    view_centre = at
    view_width *= factor
    rerender()
```

Zoom in on a point. At factor 0.5, the view doubles in detail.

Detect interior.

```gdscript
func is_in_set(c: Vector2, max_iter: int = 1000) -> bool:
    return mandelbrot_iterations(c, max_iter) == max_iter
```

Definitive membership requires infinite iterations. A finite cap gives approximate membership.

Animate zoom.

```gdscript
var zoom_target: Vector2 = Vector2(-0.745, 0.186)

func animate_zoom(duration: float) -> void:
    var tween := create_tween()
    tween.tween_method(func(t):
        var z: float = pow(0.1, t)
        view_width = 3.0 * z
        rerender()
    , 0.0, 1.0, duration)
```

Exponential zoom. The observer falls toward an interior point; detail unfolds forever.

You can now render the Mandelbrot set, colour it smoothly, zoom interactively, and animate descent into the boundary. Fractal_JuliaSet extends into the related Julia family.

<<<MAP: Fractal_JuliaSet>>>
# Julia Set

z_{n+1} = z_n² + c, but c is fixed and z_0 varies.

Test a Julia point.

```gdscript
func julia_iterations(z0: Vector2, c: Vector2, max_iter: int = 100) -> int:
    var z := z0
    for i in max_iter:
        z = Vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + c
        if z.length_squared() > 4:
            return i
    return max_iter
```

Same iteration as Mandelbrot, but the role of z_0 and c swaps. Each c gives a different Julia set.

Render for a given c.

```gdscript
func render_julia(c: Vector2, bounds: Rect2, resolution: Vector2i, max_iter: int = 100) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for py in resolution.y:
        for px in resolution.x:
            var z0 := Vector2(
                bounds.position.x + (px / float(resolution.x)) * bounds.size.x,
                bounds.position.y + (py / float(resolution.y)) * bounds.size.y
            )
            var iter: int = julia_iterations(z0, c, max_iter)
            image.set_pixel(px, py, iter_to_color(iter, max_iter))
    return ImageTexture.create_from_image(image)
```

Same texture pipeline; the parameter c distinguishes Julia sets from each other.

Animate c.

```gdscript
var c_value: Vector2 = Vector2(-0.7, 0.27)
var c_progress: float = 0.0

func _process(delta: float) -> void:
    c_progress += delta * 0.3
    var angle: float = c_progress
    c_value = Vector2(cos(angle) * 0.7, sin(angle) * 0.27)
    rerender_julia(c_value)
```

Move c along a loop. The Julia set morphs continuously.

Mandelbrot-Julia relationship.

```gdscript
func is_connected_julia(c: Vector2) -> bool:
    return is_in_set(c, 1000)
```

The Julia set is connected iff c is in the Mandelbrot set. Disconnected Julia sets look like dust; connected ones look like coherent shapes.

Pick up Julia samples.

```gdscript
func spawn_julia_sample(c: Vector2) -> MeshInstance3D:
    var sample := MeshInstance3D.new()
    sample.mesh = QuadMesh.new()
    sample.mesh.size = Vector2(1, 1)
    var texture := render_julia(c, Rect2(-2, -2, 4, 4), Vector2i(256, 256))
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    sample.material_override = mat
    return sample
```

Render a Julia set to a quad. Grab and inspect.

Gallery of c values.

```gdscript
const GALLERY_C := [
    Vector2(-0.7, 0.27),    # "dragon"
    Vector2(0.285, 0.01),   # "dendrite"
    Vector2(-0.8, 0.156),   # "rabbit"
    Vector2(0.37, 0.1),     # "branches"
]
```

Canonical Julia sets. Each c produces a distinct visual identity.

You can now iterate Julia points, render Julia sets for arbitrary c, animate c, test set connectivity via the Mandelbrot relationship, and build a gallery of classic Julia forms. Fractal_Synthesis extends into composed fractals.

<<<MAP: Fractal_Synthesis>>>
# Fractal Synthesis

Combine fractals. Overlay, intersect, mask.

Define a fractal generator.

```gdscript
class_name FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return 0.0  # override in subclasses
```

Abstract base. Subclasses provide concrete evaluation.

Koch generator.

```gdscript
class_name KochGenerator extends FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return 1.0 if is_near_koch_curve(p) else 0.0
```

Returns 1 near the Koch curve, 0 elsewhere. Binary membership.

Sierpinski generator.

```gdscript
class_name SierpinskiGenerator extends FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return 1.0 if is_inside_sierpinski(p) else 0.0
```

Returns 1 inside a Sierpinski triangle, 0 outside.

Overlay operator.

```gdscript
class_name OverlayOp extends FractalGenerator

var a: FractalGenerator
var b: FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return max(a.evaluate_at(p), b.evaluate_at(p))
```

Union. Output positive wherever either input is positive.

Intersect operator.

```gdscript
class_name IntersectOp extends FractalGenerator

var a: FractalGenerator
var b: FractalGenerator

func evaluate_at(p: Vector2) -> float:
    return min(a.evaluate_at(p), b.evaluate_at(p))
```

Intersection. Positive only where both inputs are positive.

Scale-offset operator.

```gdscript
class_name ScaleOffsetOp extends FractalGenerator

var inner: FractalGenerator
var scale: Vector2
var offset: Vector2

func evaluate_at(p: Vector2) -> float:
    return inner.evaluate_at((p - offset) / scale)
```

Composed transformation. The fractal is scaled and shifted before evaluation.

Render a composed fractal.

```gdscript
func render_composition(generator: FractalGenerator, bounds: Rect2, resolution: Vector2i) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for py in resolution.y:
        for px in resolution.x:
            var p := Vector2(
                bounds.position.x + (px / float(resolution.x)) * bounds.size.x,
                bounds.position.y + (py / float(resolution.y)) * bounds.size.y
            )
            var value: float = generator.evaluate_at(p)
            image.set_pixel(px, py, Color.WHITE if value > 0.5 else Color.BLACK)
    return ImageTexture.create_from_image(image)
```

Sample the composed generator at every pixel. Any generator tree can be rendered this way.

Build a composition tree.

```gdscript
func example_composition() -> FractalGenerator:
    var koch := KochGenerator.new()
    var sierpinski := SierpinskiGenerator.new()
    var overlay := OverlayOp.new()
    overlay.a = koch
    overlay.b = sierpinski
    return overlay
```

Generators and operators compose like a DAG. Trees of arbitrary depth are possible.

You can now build fractal generators as subclasses, compose them with overlay / intersect / scale-offset operators, and render the composition to a texture. Fractal_CrossSequence extends into comparisons across other sequences.

<<<MAP: Fractal_CrossSequence>>>
# Fractal CrossSequence

Compare fractal methods with noise, CA, L-systems.

Compare fractal dimension vs noise output.

```gdscript
func measure_box_dimension(image: Image, threshold: float) -> float:
    var sizes: Array = [2, 4, 8, 16, 32]
    var counts: Array = []
    for s in sizes:
        counts.append(count_boxes(image, s, threshold))
    return estimate_slope(sizes, counts)
```

Box-counting fractal dimension. Fit a line in log-log space; the slope is the dimension.

Count non-empty boxes.

```gdscript
func count_boxes(image: Image, box_size: int, threshold: float) -> int:
    var count: int = 0
    for y in range(0, image.get_height(), box_size):
        for x in range(0, image.get_width(), box_size):
            var has_content: bool = false
            for dy in box_size:
                for dx in box_size:
                    if image.get_pixel(x + dx, y + dy).v > threshold:
                        has_content = true
                        break
                if has_content: break
            if has_content: count += 1
    return count
```

Grid overlay. Any box with above-threshold pixels counts.

Fit a log-log slope.

```gdscript
func estimate_slope(sizes: Array, counts: Array) -> float:
    var log_sizes: Array = []
    var log_counts: Array = []
    for i in sizes.size():
        log_sizes.append(log(sizes[i]))
        log_counts.append(log(counts[i]))
    return linear_regression_slope(log_sizes, log_counts)
```

Linear fit of log(count) vs log(1/size). Slope is the fractal dimension.

Match matched pairs.

```gdscript
const MATCHED_PAIRS := [
    ["Koch_snowflake", "Noise_octaves_4"],
    ["Sierpinski", "CA_rule_30"],
    ["LSystem_tree", "Noise_turbulence"],
]
```

Hand-curated pairs of fractal-ish patterns from different sequences. The learner can see the visual affinity.

Render side by side.

```gdscript
func render_matched_gallery() -> void:
    for i in MATCHED_PAIRS.size():
        var left_tex := load_texture(MATCHED_PAIRS[i][0])
        var right_tex := load_texture(MATCHED_PAIRS[i][1])
        spawn_comparison_panel(left_tex, right_tex, Vector3(i * 3, 0, 0))
```

Each pair on its own panel. Walking the gallery walks the correspondences.

Compute structural similarity.

```gdscript
func structural_correlation(img_a: Image, img_b: Image) -> float:
    var a_mean: float = image_mean(img_a)
    var b_mean: float = image_mean(img_b)
    var covariance: float = 0.0
    var count: int = 0
    for y in img_a.get_height():
        for x in img_a.get_width():
            covariance += (img_a.get_pixel(x, y).v - a_mean) * (img_b.get_pixel(x, y).v - b_mean)
            count += 1
    return covariance / count
```

Simple covariance. Higher is more similar. Useful for automated comparison.

You can now measure box-counting dimension, fit log-log slopes, render matched-pair galleries, and compute image similarity. The sequence concludes with Chamber_Fractals.

<<<MAP: Chamber_Fractals>>>
# Chamber Fractals

Catalyst projectiles branch. Hydra regrows.

Build the fractal catalyst.

```gdscript
class_name FractalCatalyst extends Node3D

@export var branch_depth: int = 2
@export var branches_per_hit: int = 4

func fire(aim: Vector3) -> void:
    var projectile := FRACTAL_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = aim * 10.0
    projectile.branch_depth = branch_depth
    projectile.branches_per_hit = branches_per_hit
    get_tree().root.add_child(projectile)
```

Each projectile carries its own depth. On impact, it branches.

Projectile on impact.

```gdscript
class_name FractalProjectile extends RigidBody3D

@export var branch_depth: int = 2
@export var branches_per_hit: int = 4

func _on_body_entered(body: Node) -> void:
    if branch_depth > 0:
        spawn_branches()
    queue_free()

func spawn_branches() -> void:
    for i in branches_per_hit:
        var angle: float = i * TAU / branches_per_hit
        var direction := Vector3(cos(angle), randf_range(-0.3, 0.3), sin(angle))
        var child := FRACTAL_PROJECTILE_SCENE.instantiate()
        child.global_position = global_position
        child.linear_velocity = direction * 6.0
        child.branch_depth = branch_depth - 1
        child.branches_per_hit = branches_per_hit
        get_tree().root.add_child(child)
```

Branches spawn with decremented depth. At depth 0, the branch simply dies.

Build the hydra.

```gdscript
class_name FractalHydra extends CharacterBody3D

@export var initial_heads: int = 3

var heads: Array = []

func _ready() -> void:
    for _i in initial_heads:
        spawn_head()

func spawn_head() -> Node3D:
    var head := HYDRA_HEAD_SCENE.instantiate()
    head.global_position = global_position + Vector3(randfn(0, 0.5), randf_range(0.3, 1.5), randfn(0, 0.5))
    add_child(head)
    heads.append(head)
    return head
```

Initial heads scatter around the hydra. Each head is an independent target.

Regrow on head loss.

```gdscript
@export var regrowth_factor: int = 2

func _on_head_destroyed(head: Node3D) -> void:
    heads.erase(head)
    for _i in regrowth_factor:
        spawn_head()
```

Each destroyed head spawns regrowth_factor new ones. The hydra's head count grows.

Limit total heads.

```gdscript
@export var max_heads: int = 30

func spawn_head() -> Node3D:
    if heads.size() >= max_heads:
        return null
    # ... normal spawn
```

Performance guard. Without the cap, the hydra could grow unboundedly and tank the scene.

Track recursion depth via science screen.

```gdscript
class_name FractalScienceScreen extends Node3D

var projectile_depths_seen: Dictionary = {}
var head_counts_over_time: Array = []

func log_projectile(depth: int) -> void:
    projectile_depths_seen[depth] = projectile_depths_seen.get(depth, 0) + 1

func _process(_delta: float) -> void:
    head_counts_over_time.append(hydra.heads.size())
    if head_counts_over_time.size() > 300:
        head_counts_over_time.pop_front()
```

Track everything. The screen shows depth and head count over time.

You can now build the fractal catalyst with branching projectiles, the fractal hydra with regrowth, cap total heads, and log the encounter's data to the science screen. The Fractals sequence closes with infinite regress as combat.
