# A gallery of recursive objects — cubes that subdivide into smaller cubes, chairs made of smaller chairs, a pagoda whose tiers follow the Fibonacci sequence

Cellular automata showed how simple local rules produce complex global patterns. A cell checks its neighbors, applies a rule, and the grid evolves. The complexity came from interaction — many cells influencing each other simultaneously. Fractals ask a different question. Not "what happens when many agents follow rules?" but "what happens when a rule applies to its own output?"

The answer: infinite structure from finite instructions. A cube subdivides into eight smaller cubes. Each smaller cube subdivides into eight smaller cubes. The rule never changes. The depth never has to stop. Three lines of logic produce geometry that, mathematically, has no bottom — detail at every magnification, structure all the way down.

## Recursion: The Function That Calls Itself

A recursive function has two parts. The base case — the condition under which it stops. And the recursive case — where it calls itself with a smaller problem. Without the base case, the function never terminates. Without the recursive case, nothing interesting happens.

```gdscript
func build_staircase(position: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        return

    # Place a cube at the current position
    var cube := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(size, size, size)
    cube.mesh = box
    cube.position = position
    add_child(cube)

    # Build a smaller step on top and to the right
    build_staircase(
        position + Vector3(size, size, 0),
        size * 0.5,
        depth - 1
    )
```

This is the `cube_staircase` — the simplest recursive structure in the map. Each call places one cube, then delegates to a smaller version of itself offset upward and to the right. Depth 1 produces one cube. Depth 2 produces two — the original and a half-sized step. Depth 6 produces six cubes cascading upward, each half the size of the previous. The growth is linear here — one cube per level. That changes fast.

The `depth` parameter is the leash. It controls how many times the function is allowed to call itself. Remove it and the call stack overflows — Godot crashes. Every recursive function in every fractal artifact uses this pattern: do work, reduce depth, recurse. The depth parameter is what makes infinite mathematical objects finite in code.

## Subdivision: The Exponential Engine

The staircase adds one cube per level. Subdivision multiplies.

```gdscript
func subdivide_cube(position: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        var cube := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(size, size, size)
        cube.mesh = box
        cube.position = position
        add_child(cube)
        return

    var half := size / 2.0
    var quarter := size / 4.0

    for x in [-1, 1]:
        for y in [-1, 1]:
            for z in [-1, 1]:
                subdivide_cube(
                    position + Vector3(x, y, z) * quarter,
                    half,
                    depth - 1
                )
```

Eight sub-cubes per cube. Three nested loops — x, y, z — each iterating over `[-1, 1]`. The product is 2 * 2 * 2 = 8 positions. Each sub-cube is half the size of its parent, offset by a quarter of the parent's size in each axis. The parent vanishes — only leaves of the recursion tree become visible geometry.

The numbers escalate. Depth 1 produces 8 cubes. Depth 2: each of those 8 produces 8 more — 64 cubes. Depth 3: 512. Depth 4: 4,096.

Depth 5: 32,768. The pattern is 8^n, where n is the depth. This is exponential growth — the defining characteristic of recursive subdivision. The rule is trivially simple. The output is not.

The `cube_subdivision` artifact in the map implements exactly this function. At depth 1, the result looks like a Rubik's cube — eight blocks with visible gaps. At depth 3, the structure is a solid-looking mass of 512 tiny cubes. At depth 5, the geometry starts to strain the GPU. The same three nested loops, the same halving of size — the only variable is depth, and depth changes everything.

## The Recursive Chair: Subdivision with Pruning

Pure subdivision is democratic — every sub-cube gets the same treatment. The `recursive_chair` introduces discrimination. Not all sub-cubes survive. Only the ones that correspond to functional parts of a chair — legs, seat, back — are kept. The rest are pruned.

```gdscript
func build_recursive_chair(position: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        _place_cube(position, size)
        return

    var third := size / 3.0

    for x in range(3):
        for y in range(3):
            for z in range(3):
                var keep := false

                # Bottom layer: only corners survive (legs)
                if y == 0:
                    keep = (x == 0 or x == 2) and (z == 0 or z == 2)
                # Middle layer: full platform (seat)
                elif y == 1:
                    keep = true
                # Top layer: only back row (backrest)
                elif y == 2:
                    keep = z == 2

                if keep:
                    var offset := Vector3(x, y, z) * third
                    var sub_pos := position + offset - Vector3(1, 0, 1) * third
                    build_recursive_chair(sub_pos, third, depth - 1)
```

A 3x3x3 grid — 27 possible sub-cubes. The bottom layer keeps four corners: legs. The middle layer keeps all nine: the seat. The top layer keeps three from the back row: the backrest. That's 16 out of 27 surviving the first pass.

The recursive part is the trick. Each surviving sub-cube is itself subdivided into a 3x3x3 grid, and the same pruning rules apply. The legs of the chair are made of smaller chairs. The seat is made of smaller chairs. The backrest is made of smaller chairs. At depth 1, it looks like a blocky chair. At depth 3, it looks like a chair made of chairs made of chairs — self-similarity at every scale.

This is the bridge between pure fractals and design. The Menger sponge prunes uniformly — remove the center and face centers from every sub-cube, always. The recursive chair prunes with intent — keep the parts that serve a structural purpose. Both are recursive. Both are self-similar. But the chair has a function. It demonstrates that recursion is not just a mathematical curiosity. It is a construction technique.

## CSG: Boolean Operations on Recursive Geometry

The `recursive_boolean_cube` artifact takes subdivision one step further. Instead of pruning sub-cubes from a grid, it applies Constructive Solid Geometry — union, intersection, difference — to recursive shapes.

```gdscript
func recursive_boolean(position: Vector3, size: float, depth: int) -> CSGCombiner3D:
    var combiner := CSGCombiner3D.new()

    # Primary shape: a subdivided cube
    var primary := CSGBox3D.new()
    primary.size = Vector3(size, size, size)
    combiner.add_child(primary)

    # Subtract a sphere from the center
    var sphere := CSGSphere3D.new()
    sphere.radius = size * 0.65
    sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
    combiner.add_child(sphere)

    if depth > 0:
        var half := size / 2.0
        for x in [-1, 1]:
            for y in [-1, 1]:
                for z in [-1, 1]:
                    var child := recursive_boolean(
                        Vector3(x, y, z) * half * 0.5,
                        half * 0.5,
                        depth - 1
                    )
                    child.position = Vector3(x, y, z) * half * 0.5
                    combiner.add_child(child)

    combiner.position = position
    return combiner
```

At each level, a cube has a sphere subtracted from its center — a boolean difference that carves a round hole through the solid. Then the same operation applies to eight sub-cubes at the corners. The result at depth 2 is a cube riddled with spherical voids at two scales. At depth 3, the voids appear at three scales — large, medium, small — nested inside each other.

CSG treats solid geometry as an algebra. Union adds volumes. Intersection keeps only overlaps. Subtraction removes one shape from another. Apply these operations recursively and the algebra becomes generative — each level of recursion introduces new boolean relationships. The `recursive_boolean_cube` is not just a shape. It is a tree of operations, where each node is a boolean combination of its children.

## The Fibonacci Pagoda: A Different Kind of Recursion

Not all recursion is geometric subdivision. The `fibonacci_pagoda` introduces numeric recursion — the Fibonacci sequence — as an architectural principle.

```gdscript
func fibonacci(n: int) -> int:
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

func build_pagoda(tiers: int) -> void:
    var y_offset := 0.0

    for i in range(tiers):
        var fib_value := fibonacci(i + 2)
        var tier_width := fib_value * 0.3
        var tier_height := 0.5 + i * 0.1

        var tier := CSGBox3D.new()
        tier.size = Vector3(tier_width, tier_height, tier_width)
        tier.position = Vector3(0, y_offset + tier_height / 2.0, 0)
        add_child(tier)

        # Roof overhang
        var roof := CSGBox3D.new()
        roof.size = Vector3(tier_width * 1.3, 0.08, tier_width * 1.3)
        roof.position = Vector3(0, y_offset + tier_height, 0)
        add_child(roof)

        y_offset += tier_height + 0.1
```

F(0) = 0. F(1) = 1. F(n) = F(n-1) + F(n-2). The sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21. Each tier of the pagoda uses a Fibonacci number to set its width. The bottom tier is narrow. Each successive tier widens — not linearly, not exponentially, but at the Fibonacci rate, where each value is the sum of the two before it.

This is recursion without subdivision. The cube fractals divide a whole into parts and recurse on each part. The Fibonacci sequence accumulates — each value depends on previous values, not on smaller copies of the same structure. The recursion tree for `fibonacci(6)` is not eight branches splitting uniformly. It is two branches at each node, one computing `n-1` and the other `n-2`, overlapping heavily.

The pagoda makes the sequence physical. The ratio between consecutive Fibonacci numbers converges to the golden ratio — approximately 1.618. At higher tiers, each level is 1.618 times wider than the previous. The building develops a characteristic flare that appears in nature — sunflower spirals, nautilus shells, pine cones. The Fibonacci thread surfaces again in Fractals_7.

## Fractal Dimension: When Integers Are Not Enough

A line is one-dimensional. A plane is two-dimensional. A cube is three-dimensional. These are integers, clean and familiar. Fractals break that convention.

The fractal dimension D is computed from the self-similarity ratio:

```
D = log(N) / log(S)
```

N is the number of self-similar pieces. S is the scaling factor — how many times larger the whole is compared to each piece. A line split into 3 equal segments: N = 3, S = 3, D = log(3)/log(3) = 1. A square split into 9 equal sub-squares: N = 9, S = 3, D = log(9)/log(3) = 2. Integers. No surprise.

The Sierpinski triangle: divide a triangle into 4 sub-triangles and remove the center one. N = 3 (three surviving pieces), S = 2 (each piece is half the original's linear size). D = log(3)/log(2) = 1.585. Not 1. Not 2. The Sierpinski triangle is more than a line but less than a plane — it occupies a fractional dimension.

```gdscript
func fractal_dimension(num_copies: int, scale_factor: float) -> float:
    return log(num_copies) / log(scale_factor)

# Standard geometries
var line_d := fractal_dimension(2, 2)          # 1.0
var square_d := fractal_dimension(4, 2)        # 2.0
var cube_d := fractal_dimension(8, 2)          # 3.0

# Fractals
var sierpinski_d := fractal_dimension(3, 2)    # 1.585
var menger_d := fractal_dimension(20, 3)       # 2.727
var cantor_d := fractal_dimension(2, 3)        # 0.631
```

The Menger sponge — a cube subdivided 3x3x3 with the center column and face centers removed — has dimension log(20)/log(3) = 2.727. More than a plane, less than a solid. It has infinite surface area but zero volume. The Cantor set — a line segment with the middle third removed at every step — has dimension 0.631. More than a point, less than a line.

Fractal dimension quantifies how a structure fills space. Integer-dimensional objects fill their space completely. Fractals fill it partially — at every scale, they contain holes, gaps, absences that prevent them from reaching the next integer dimension. The `example_8_3_recursion_circles_vr` artifact in the map demonstrates this with nested circles — each circle contains smaller circles, and the packing never completely fills the plane.

## Self-Similarity: The Whole in the Part

Zoom into a fractal and you see the fractal again. This is self-similarity — the defining property. The cube subdivision at depth 5 looks the same whether you view the whole structure or zoom into one corner. The recursive chair at any magnification reveals smaller chairs. The Sierpinski triangle is three half-sized Sierpinski triangles arranged in a triangle.

Self-similarity is not ornament. It is mechanism. The reason fractals look the same at every scale is that they are built by the same rule at every scale. The code does not describe the shape. The code describes the process. The shape is a consequence.

```gdscript
# This function does not describe a fractal.
# It describes a process that produces a fractal.
func subdivide_cube(position: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        _place_cube(position, size)
        return
    for x in [-1, 1]:
        for y in [-1, 1]:
            for z in [-1, 1]:
                subdivide_cube(
                    position + Vector3(x, y, z) * size / 4.0,
                    size / 2.0,
                    depth - 1
                )
```

Twelve lines. No explicit geometry description. No list of vertices. No mesh data. Just a rule and a depth. The geometry emerges from the recursion. This is the lambda_edge thesis made spatial — finite rules produce infinite complexity because the output of a rule becomes its own input.

## Performance: The Exponential Wall

Exponential growth is beautiful mathematically and brutal computationally. The cube subdivision produces 8^n objects. At depth 7, that is 2,097,152 cubes. Each needs a mesh, a transform, a draw call. The GPU will not comply.

```gdscript
@export var max_depth: int = 4

func _process(delta: float) -> void:
    var cam_distance := global_position.distance_to(
        get_viewport().get_camera_3d().global_position
    )

    # Level of Detail: reduce depth for distant fractals
    var lod_depth := clampi(
        max_depth - int(cam_distance / 5.0),
        1,
        max_depth
    )

    if lod_depth != _current_depth:
        _regenerate(lod_depth)
        _current_depth = lod_depth
```

Level of Detail — LOD — adjusts recursion depth based on camera distance. A fractal close to the viewer gets full depth. One across the room gets depth 1 or 2. The eye cannot resolve the difference at distance, but the GPU absolutely feels it. The `cam_distance / 5.0` divisor determines how aggressively depth drops off. Smaller divisor means faster falloff — fewer cubes at moderate distances. Larger divisor preserves detail longer at the cost of framerate.

The `_regenerate` function tears down the existing children and rebuilds from scratch at the new depth. This is wasteful — a smarter approach caches intermediate levels and adds or removes the deepest layer. But for a teaching artifact, clarity outweighs optimization. The learner sees the direct relationship between depth and visual complexity. Slide the depth down and cubes vanish in blocks. Slide it up and detail erupts at every surface.

MultiMesh offers another path. Instead of thousands of individual `MeshInstance3D` nodes, a `MultiMeshInstance3D` draws all cubes in a single draw call with per-instance transforms:

```gdscript
func _build_multimesh(positions: Array[Vector3], sizes: Array[float]) -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = _shared_box_mesh
    mm.instance_count = positions.size()

    for i in range(positions.size()):
        var xform := Transform3D()
        xform = xform.scaled(Vector3.ONE * sizes[i])
        xform.origin = positions[i]
        mm.set_instance_transform(i, xform)

    _multi_mesh_instance.multimesh = mm
```

One mesh, one material, thousands of instances. The GPU handles instanced drawing far more efficiently than individual nodes. This is the standard technique for any fractal visualization that exceeds a few hundred elements. The `dark_sphere` artifact in the map uses a simpler version of this principle — a single sphere mesh with shader-driven effects rather than geometric complexity.

## From Finite to Infinite

The artifacts in this map — `cube_staircase`, `cube_subdivision`, `recursive_chair`, `recursive_table`, `fibonacci_pagoda`, `recursive_boolean_cube`, `fractal_recursion_2`, `example_8_3_recursion_circles_vr` — all demonstrate the same principle from different angles. A finite rule, self-applied, generates unbounded structure. The staircase shows it linearly. The subdivision shows it exponentially. The chair shows it with pruning. The pagoda shows it with accumulation. The boolean cube shows it with algebra.

This is the lambda_edge made concrete. In the QFEP framework, lambda governs the balance between order and entropy. At lambda = 0, pure order — a single cube, no recursion, no complexity. As lambda increases, the system explores. Subdivision is exploration — each recursive call branches the possibility space. Pruning is exploitation — the recursive chair keeps only what serves a purpose. The tension between subdivide-everything and keep-only-what-matters is the tension between entropy and structure that runs through every sequence in this curriculum.

The next map — Fractals_2 — takes recursion organic. Instead of cubes subdividing into cubes, branches subdivide into branches. The recursive tree replaces the recursive cube. The topology changes — from grids to graphs, from volume to line. But the engine stays the same: a function that calls itself, a depth that limits the descent, and a base case that finally produces visible geometry.

## Possible Artifacts

**depth_comparator** — A side-by-side display showing the same subdivision rule at depths 1 through 5 simultaneously. Five instances of the cube subdivision, arranged in a row, each at a different depth. The learner sees the exponential progression spatially — the jump from depth 2 to depth 3 is not twice as complex but eight times as complex. Numeric labels show cube counts: 8, 64, 512, 4096, 32768. This is the gap artifact — the map needs it to make exponential growth visceral rather than theoretical.

**recursion_unwinder** — An animated artifact that plays back the recursion tree in execution order. A cube appears, splits into eight, then one of the eight splits into eight, depth-first. The call stack is visualized as a vertical bar beside the geometry — growing as calls nest, shrinking as they return. Pausing at any frame shows exactly which cube is being processed and where in the tree the function stands. Connects the code abstraction to the spatial result.

**dimension_calculator** — An interactive artifact where the learner adjusts N (number of copies) and S (scale factor) with sliders and watches the fractal dimension update in real time. Preset buttons for Sierpinski triangle, Menger sponge, Cantor set, Koch curve. A number line from 0 to 3 shows where each fractal falls relative to integer dimensions — points, lines, planes, volumes. Makes fractional dimension tangible rather than formulaic.
