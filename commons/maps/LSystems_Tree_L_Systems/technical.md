# Tree L-Systems

The Grammar Lab introduced the full L-system pipeline — axiom, rules, string, turtle, tree — as a single mechanism. Growth added time, showing each generation as a distinct phase. This map isolates the tree itself. Three artifacts occupy the space: an L-system tree rendered from the classic plant rule, a tree generator that cycles through generations automatically, and an interactive editor where the learner manipulates presets, angles, and iteration depth in real time. The question shifts from "how does the grammar work?" to "what makes a tree look like a tree?"

## The Alphabet

An L-system operates on a string. The string is built from a finite alphabet, and each character encodes an instruction for the turtle:

- `F` — move forward, drawing a line segment
- `G` — move forward, drawing a line segment (alias for `F` in some grammars)
- `f` — move forward without drawing
- `+` — turn left by the branching angle
- `-` — turn right by the branching angle
- `[` — push the current position and direction onto a stack
- `]` — pop the stack, restoring position and direction

The bracket pair `[ ]` is what separates trees from curves. The Koch curve, the Sierpinski triangle, the dragon curve — they use `F`, `+`, and `-` only. The turtle walks a single path. Brackets introduce branching. The turtle saves its state, ventures down a branch, then snaps back to the fork and continues the main stem. Without brackets, a string describes a trail. With brackets, it describes a tree.

## The Classic Plant Rule

The `lsystem_tree` artifact implements one rule:

```gdscript
var _axiom: String = "F"
var _rules: Dictionary = {"F": "F[+F]F[-F]F"}
```

One axiom. One production rule. The rule replaces every `F` with `F[+F]F[-F]F` — draw forward, save state, turn left, draw, restore, draw forward, save state, turn right, draw, restore, draw forward. Five forward segments per replacement, two bracketed branches.

The rewriting loop applies this rule iteratively:

```gdscript
func _generate() -> void:
    _current_string = _axiom

    for _i in range(iterations):
        var next := ""
        for c in _current_string:
            if _rules.has(c):
                next += _rules[c]
            else:
                next += c
        _current_string = next
        if _current_string.length() > 80000:
            break

    _draw_tree()
```

Each iteration walks the current string character by character. Characters with rules are replaced. Characters without rules pass through unchanged — `+`, `-`, `[`, and `]` are constants. They survive every generation, accumulating as the string grows. After 4 iterations, the string `F` has become thousands of characters encoding hundreds of branches.

The length guard — `80000` characters — prevents the string from consuming all available memory. At 5 iterations with this rule, the string exceeds 15,000 characters. At 6, it exceeds 75,000. Exponential growth is not a metaphor here. It is a memory allocation problem.

## Turtle Graphics: Reading the String

The string is data. The turtle is the interpreter. It walks the string left to right, executing each instruction:

```gdscript
var pos := Vector3.ZERO
var dir := Vector3.UP
var right := Vector3.RIGHT
var stack: Array = []
var angle_rad: float = deg_to_rad(base_angle)

for c in _current_string:
    match c:
        "F":
            var new_pos := pos + dir * current_length
            segments.append([pos, new_pos, depth])
            pos = new_pos
        "+":
            var axis := dir.cross(right)
            axis = axis.normalized()
            dir = dir.rotated(axis, angle_rad).normalized()
            right = right.rotated(axis, angle_rad).normalized()
        "-":
            var axis := dir.cross(right)
            axis = axis.normalized()
            dir = dir.rotated(axis, -angle_rad).normalized()
            right = right.rotated(axis, -angle_rad).normalized()
        "[":
            stack.append({
                "pos": pos, "dir": dir, "right": right,
                "depth": depth, "length": current_length,
            })
            depth += 1
            current_length *= 0.72
        "]":
            if stack.size() > 0:
                var state: Dictionary = stack.pop_back()
                pos = state["pos"]
                dir = state["dir"]
                right = state["right"]
                depth = state["depth"]
                current_length = state["length"]
```

The turtle carries position, direction, and a right vector (for computing rotation axes in 3D). When it encounters `[`, it pushes everything onto the stack and increases the depth counter. When it encounters `]`, it pops, snapping back to the fork point. The depth counter is not just bookkeeping — it drives two visual effects. First, `current_length *= 0.72` shortens branches at deeper levels. Outer branches are shorter than the trunk. Second, depth determines color — the trunk is brown, the tips are green.

The rotation mechanism deserves attention. In 2D, turning is simple — rotate the direction vector by the angle. In 3D, the rotation axis matters. `dir.cross(right)` computes the axis perpendicular to both the current direction and the right vector. Rotating around this axis tilts the turtle in the plane defined by its current heading. This keeps the tree growing in a consistent plane unless additional 3D rotations are introduced.

## The Branching Angle

The default angle is 25.7 degrees. This is not arbitrary. In 1968, Aristid Lindenmayer published the first L-systems for modeling plant growth. The branching angles of real plants cluster around specific values — 25.7° produces structures resembling the weed *Mycelis muralis*. Change the angle and the tree changes character:

The `lsystem_editor` artifact makes this manipulable. Seven presets span the range:

```gdscript
const PRESETS = {
    0: ["F", {"F": "F+F-F-F+F"}, 90.0, 4, "Koch Curve"],
    1: ["F-G-G", {"F": "F-G+F+G-F", "G": "GG"}, 120.0, 5, "Sierpinski"],
    2: ["FX", {"X": "X+YF+", "Y": "-FX-Y"}, 90.0, 10, "Dragon Curve"],
    3: ["X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, 25.0, 5, "Plant"],
    4: ["F", {"F": "FF+[+F-F-F]-[-F+F+F]"}, 22.5, 4, "Bush"],
    5: ["X", {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"}, 25.0, 5, "Fern"],
    6: ["F", {"F": "G[+F]-F", "G": "GG"}, 45.0, 6, "Binary Tree"],
}
```

Presets 0–2 use no brackets — they produce curves, not trees. Presets 3–6 use brackets — they produce branching structures. The Koch Curve at 90° and the Sierpinski triangle at 120° are geometric. The Plant at 25° and the Fern at 25° are organic. The Bush at 22.5° produces denser lateral branching. The Binary Tree at 45° produces a symmetric fork at every node.

The angle slider in VR lets the learner sweep from 5° to 90° on any preset. At 5°, branches barely diverge — the tree is a narrow spike. At 45°, branches spread wide and the canopy flattens. At 90°, branches point sideways and the structure reads as a grid, not a tree. The sweet spot — the range where the output looks botanical — is roughly 20° to 30°. Below that, too columnar. Above that, too geometric. The tree's organic quality is a narrow band in angle space.

## Auxiliary Symbols: X and G

Some presets use symbols that are not turtle commands. In the Plant preset:

```
Axiom: X
Rules: X → F+[[X]-X]-F[-FX]+X
       F → FF
```

`X` has no turtle interpretation — the turtle ignores it when drawing. But `X` participates in rewriting. It is a placeholder that structures the grammar. In the first generation, the axiom `X` becomes `F+[[X]-X]-F[-FX]+X`. The `X` symbols are scattered through brackets, waiting to be rewritten in the next generation. Meanwhile, `F → FF` doubles every forward segment.

This two-rule system produces qualitatively different trees than the single-rule `F → F[+F]F[-F]F`. The auxiliary symbol `X` creates a separation between growth (controlled by `F → FF`) and branching (controlled by `X → ...`). The trunk elongates independently of the branching pattern. In the single-rule version, trunk and branches are the same — every `F` produces both. With `X`, the grammar has internal structure. The genotype is more complex, and the phenotype shows it.

`G` in the Binary Tree and Sierpinski presets serves a similar purpose. `G → GG` doubles a forward segment without introducing branches. The binary tree rule `F → G[+F]-F` replaces each branch tip with a longer trunk segment (`G`) followed by a fork. The result is a tree where the internodes — the segments between forks — grow longer at each generation while the branching pattern stays fixed.

## Rendering: ImmediateMesh

Both the `lsystem_tree` and `lsystem_editor` artifacts render with `ImmediateMesh` — Godot's tool for drawing geometry from code at the vertex level.

```gdscript
_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

for seg in segments:
    var p1: Vector3 = (seg[0] - center) * scale_factor
    var p2: Vector3 = (seg[1] - center) * scale_factor
    var d: int = seg[2]

    var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
    var col: Color = trunk_color.lerp(tip_color, t)

    _immediate_mesh.surface_set_color(col)
    _immediate_mesh.surface_add_vertex(p1)
    _immediate_mesh.surface_set_color(col)
    _immediate_mesh.surface_add_vertex(p2)

_immediate_mesh.surface_end()
```

`PRIMITIVE_LINES` draws each pair of vertices as a line segment. No quads, no triangles — just edges. This is sufficient for a diagrammatic tree but not for a realistic one. Real branches have thickness that tapers. Real leaves have surface area. The line-based rendering is a deliberate choice: it shows the grammar's output with minimum visual noise. The structure is legible precisely because it is skeletal.

The depth-based color gradient — brown trunk (`trunk_color`) to green tips (`tip_color`) via `lerp` — encodes the stack depth visually. The learner can trace the branching hierarchy by color alone. Deep branches are green. Shallow trunk segments are brown. The interpolation parameter `t` is `depth / max_depth`, so every tree, regardless of iteration count, maps its full depth range onto the full color range.

The bounds computation centers and scales the tree to fit within `display_size`:

```gdscript
var bounds_size := max_bounds - min_bounds
var max_dim: float = maxf(maxf(bounds_size.x, bounds_size.y), bounds_size.z)
var scale_factor: float = display_size * 0.75 / max_dim
var center := (min_bounds + max_bounds) / 2.0
center.y = min_bounds.y  # Anchor at bottom
```

Setting `center.y = min_bounds.y` ensures the tree base sits at `y = 0` regardless of how tall the canopy grows. Without this, the tree would float upward as iterations increase.

## From String to Forest

The `tree_generation` artifact takes the L-system one step further — it animates the growth process. A timer fires every 2 seconds. Each tick applies `apply_lsystem_rules()`, rewrites the string, and redraws the tree. The learner watches generation 0 (a single segment) become generation 1 (a small fork) become generation 3 (a recognizable tree) become generation 5 (a dense canopy). At generation 6, the cycle resets.

```gdscript
func _process(delta):
    generation_timer += delta

    if generation_timer >= generation_interval:
        generation_timer = 0.0
        if generation < max_generations:
            generation += 1
            apply_lsystem_rules()
            draw_tree()
        else:
            generate_initial_tree()
```

This artifact adds leaves. At generation 3 and beyond, every terminal `F` sprouts a small sphere:

```gdscript
if generation >= 3:
    create_leaf(position)
```

The leaves appear only once the tree has enough structure to support them. Generations 0–2 are bare — trunk and branches only. Generation 3 introduces the first leaf buds. By generation 5, the canopy is dense with green spheres. This mirrors real development: leaves emerge after the branching scaffold is established.

The tree_generation artifact uses CSG nodes (`CSGCylinder3D` for branches, `CSGSphere3D` for leaves) rather than `ImmediateMesh`. This is heavier — each branch is a separate node — but allows per-branch animation. During growth, branches scale from 0 to 1 along their y-axis, creating the visual impression of extension. Leaves fade in with a delayed timing offset. The tree does not appear. It develops.

## Grammar as Genotype

The L-system string is a genotype. The rendered tree is a phenotype. The rewriting rules are the developmental program. The angle, the length decay, the iteration count — these are the environmental parameters. Change the genotype (the rules) and the body plan changes. Change the environment (the angle, the constraints) and the same genotype produces a different phenotype.

This is the lambda edge in compressed form. The rules are pure F — order, prediction, determinism. Every generation follows the same substitution. But the output is not orderly. At 4 iterations, the plant rule produces a structure that looks organic, irregular, alive. The complexity does not come from complex rules. It comes from the recursive application of simple rules — each generation's output becoming the next generation's input, errors compounding, structure accumulating. The string rewriting is deterministic. The visual result is not legible as deterministic. The gap between the two is where L-systems live.

The next map — Animated Tree — takes this further. Instead of rendering the final tree as a static structure, it animates the turtle's traversal of the string. The tree draws itself in real time, branch by branch, and the relationship between string order and spatial structure becomes visible.

## Possible Artifacts

**angle_sweep_display** — A row of 7 trees rendered simultaneously, each from the same grammar but with branching angles from 15° to 45° in 5° increments. The learner walks along the row and sees how angle alone transforms the character of the tree — from columnar to spreading to geometric. A floating label on each shows the angle value. Makes the narrow "botanical band" visible at a glance.

**string_to_tree_animator** — An artifact that displays the L-system string as scrolling text on one panel while the turtle draws the corresponding tree on an adjacent panel. A cursor highlights the current character as the turtle executes it. `[` and `]` flash when the stack pushes and pops. The learner sees the direct mapping between syntax and geometry — grammar made spatial in real time.

**rule_comparator** — Side-by-side display of the single-rule tree (`F → F[+F]F[-F]F`) and the two-rule plant (`X → F+[[X]-X]-F[-FX]+X`, `F → FF`) at the same iteration depth. Labels show string length, branch count, and max depth for each. The structural difference between one-rule and two-rule grammars becomes measurable, not just visual.
