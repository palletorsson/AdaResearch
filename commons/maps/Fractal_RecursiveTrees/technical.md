# A garden of forking branches — recursive trees that share one grammar yet never grow the same shape twice

Fractals_1 subdivided cubes into cubes. Uniform, geometric, exact. Every depth-3 subdivision produced the same 512 sub-cubes in the same positions with the same sizes. The rule was deterministic and the output was frozen — a crystal lattice of self-similarity. Now the rule bends — branches replace cubes, angles vary, and randomness enters the recursion. The topology shifts from volume to line, from grid to graph, from mineral to vegetable. The recursive tree is the first organic fractal in the sequence.

## The Recursive Tree: A Branch That Branches

A tree is a function that draws a line segment and then calls itself twice — once angled left, once angled right. Each sub-call draws a shorter segment and calls itself again. The base case is depth zero, where the recursion stops and the branch tip becomes a leaf.

```gdscript
func draw_tree(position: Vector3, direction: Vector3, length: float,
               angle: float, depth: int) -> void:
    if depth <= 0:
        return

    var end_pos := position + direction * length

    # Draw this branch segment
    _add_branch(position, end_pos, depth)

    # Left sub-branch — rotate direction by +angle around Z
    var left_dir := direction.rotated(Vector3.FORWARD, angle)
    draw_tree(end_pos, left_dir, length * 0.7, angle, depth - 1)

    # Right sub-branch — rotate direction by -angle around Z
    var right_dir := direction.rotated(Vector3.FORWARD, -angle)
    draw_tree(end_pos, right_dir, length * 0.7, angle, depth - 1)
```

Three parameters govern the shape. `length` determines segment size — multiplied by 0.7 at each level, so branches shrink as they subdivide. `angle` determines the spread between left and right sub-branches — wider angles produce broader canopies, narrower angles produce columnar forms. `depth` controls how many generations of branching occur before the recursion bottoms out. At depth 1, the tree is a Y. At depth 5, it is a dense canopy of 32 tips. At depth 10 — 1,024 tips, and the GPU starts to notice.

The branching factor here is 2 — each branch produces exactly two children. Compare this to the cube subdivision from Fractals_1, where each cube produced 8 children. The growth rate is 2^n instead of 8^n. Slower, but the visual complexity is higher because branches carry directional information — they point, they angle, they curve through space. Cubes just sit.

## The L-System Connection: Grammar as Geometry

The recursive tree function above is equivalent to an L-system with the production rule `F -> F[+F][-F]`. The symbols:

- `F` — draw forward by one segment length
- `+` — rotate left by the branch angle
- `-` — rotate right by the branch angle
- `[` — push the current position and direction onto a stack
- `]` — pop the saved state, returning to the branch point

```gdscript
func generate_lsystem(axiom: String, rules: Dictionary, iterations: int) -> String:
    var current := axiom

    for i in range(iterations):
        var next := ""
        for symbol in current:
            if symbol in rules:
                next += rules[symbol]
            else:
                next += symbol
        current = next

    return current

# The simplest branching tree
var tree_string := generate_lsystem("F", {"F": "F[+F][-F]"}, 5)
```

After one iteration: `F[+F][-F]`. After two: `F[+F][-F][+F[+F][-F]][-F[+F][-F]]`. The string grows exponentially, and each `F` in the result will itself be replaced on the next pass. The grammar is the genotype. The interpreted string — rendered as branches in space — is the phenotype. Same distinction biology makes between the instructions and the body they build.

The stack operations `[` and `]` are what make trees possible. Without them, every branch would continue from the tip of the previous one — a zigzag, not a tree. The `[` saves position and direction at a branch point. The `]` restores that state after the sub-branch completes, so the second child starts from the same fork as the first. Branching requires memory. The stack is that memory. An interpreter walks the string character by character — `F` draws and advances, `+` and `-` rotate, `[` pushes, `]` pops — and the tree emerges from a flat sequence of symbols.

## Deterministic Trees: Same Seed, Same Shape

With fixed parameters, the recursive tree is entirely deterministic. Angle 25 degrees, length ratio 0.7, depth 6 — the same tree every time. Every branch point produces the same two children at the same angles. The tree is as frozen as the cube subdivision, just shaped differently.

```gdscript
@export var branch_angle: float = deg_to_rad(25.0)
@export var length_ratio: float = 0.7
@export var max_depth: int = 6
@export var trunk_length: float = 2.0

func _ready() -> void:
    draw_tree(Vector3.ZERO, Vector3.UP, trunk_length,
              branch_angle, max_depth)
```

Change `branch_angle` from 25 to 45 degrees and the tree flattens into a wide parasol. Drop `length_ratio` from 0.7 to 0.5 and the branches shrink faster — a compact bush. Raise `max_depth` from 6 to 9 and the canopy fills with fine detail. Three numbers define a species. The deterministic tree is a point in parameter space — one specific combination of angle, ratio, and depth. Every point in that space produces a different but fixed tree. A catalog of species, each perfectly reproducible.

The `small_subdivision_cube` artifact in this map maintains the geometric thread from Fractals_1 — a cube recursion sitting alongside the tree recursion, reminding the learner that branching and subdivision are two faces of the same operation. One splits volumes. The other splits directions.

## Stochastic Variation: Noise Enters the Recursion

Nature does not produce deterministic trees. Wind, soil, light, water — environmental forces perturb every branch. Two oaks grown from the same acorn species develop different canopies. The grammar is shared. The noise is individual.

Stochastic variation adds random perturbation to the branch parameters at each recursive call:

```gdscript
@export var angle_variance: float = 0.3    # +/- 30% of base angle
@export var length_variance: float = 0.2   # +/- 20% of base length

func draw_stochastic_tree(position: Vector3, direction: Vector3,
                          length: float, angle: float, depth: int) -> void:
    if depth <= 0:
        return

    # Perturb length — each branch gets its own random factor
    var perturbed_length := length * (1.0 + randf_range(
        -length_variance, length_variance))
    var end_pos := position + direction * perturbed_length

    _add_branch(position, end_pos, depth)

    # Perturb angles independently for left and right
    var left_angle := angle * (1.0 + randf_range(
        -angle_variance, angle_variance))
    var right_angle := angle * (1.0 + randf_range(
        -angle_variance, angle_variance))

    var left_dir := direction.rotated(Vector3.FORWARD, left_angle)
    var right_dir := direction.rotated(Vector3.FORWARD, -right_angle)

    draw_stochastic_tree(end_pos, left_dir,
        perturbed_length * length_ratio, angle, depth - 1)
    draw_stochastic_tree(end_pos, right_dir,
        perturbed_length * length_ratio, angle, depth - 1)
```

Four `randf_range` calls per branch point — one for length, one for left angle, one for right angle, one implicit in the perturbed length propagating to children. Each call is an independent random draw. At depth 6, there are 63 branch points (2^6 - 1), each making independent random choices. That is 252 random numbers shaping the tree. Same grammar, different rolls, different body.

The variance parameters control how much noise the recursion tolerates. At `angle_variance = 0.0` and `length_variance = 0.0`, the tree is deterministic — identical to the fixed version. At `angle_variance = 1.0`, branches can swing from zero degrees to double the base angle — the tree becomes wild, tangled, barely recognizable. The interesting zone sits between 0.1 and 0.4 — enough variation to look natural, enough structure to read as "tree."

This is the lambda parameter from the QFEP framework made spatial. Lambda modulates the balance between deterministic structure and entropic exploration. At lambda near zero, the system collapses to a single fixed point — the deterministic tree. As lambda increases, the system explores more of its possibility space — each tree wanders further from the deterministic archetype. At lambda too high, the structure dissolves into noise. The stochastic tree finds the edge — the lambda_edge — where form and variation coexist.

## Seed Control: Reproducible Randomness

Randomness in code is pseudorandom — generated by a deterministic algorithm from a starting seed. Same seed produces the same sequence of "random" numbers. This matters for stochastic trees because it means any specific tree can be reproduced exactly.

```gdscript
@export var tree_seed: int = 42

func _ready() -> void:
    seed(tree_seed)
    draw_stochastic_tree(Vector3.ZERO, Vector3.UP, trunk_length,
                         branch_angle, max_depth)
```

Seed 42 always produces the same stochastic tree. Seed 43 produces a different one. The seed is the tree's identity — its unique combination of all the random draws that shaped it. Two trees with the same grammar, same parameters, but different seeds are siblings — same species, different individuals. Change the seed and the tree changes. Change the grammar and the species changes. The distinction between individual variation and structural variation maps directly onto the distinction between seed and rule.

The `inverted_tree_cloud` artifact exploits this. It generates a stochastic tree, then mirrors it — branches pointing downward, a root system reflected as cloud. The same grammar produces both crown and root, one reaching up, one reaching down. The inversion foreshadows the reflection motifs that surface later in the fractal sequence. A tree and its shadow. A structure and its dual.

## The Inverted Tree Cloud: Reflection as Recursion

Two `inverted_tree_cloud` instances appear in this map — one on the walled courtyard's inner edge, one at the outer perimeter. Each generates a branching structure using the stochastic tree algorithm, then duplicates it inverted along the vertical axis.

```gdscript
func build_inverted_tree_cloud(base_pos: Vector3, tree_seed_value: int) -> void:
    seed(tree_seed_value)

    # Upward tree — trunk grows toward sky
    draw_stochastic_tree(base_pos, Vector3.UP, trunk_length,
                         branch_angle, max_depth)

    # Inverted tree — same seed, same shape, flipped
    seed(tree_seed_value)
    draw_stochastic_tree(base_pos, Vector3.DOWN, trunk_length,
                         branch_angle, max_depth)
```

Resetting the seed before the second call guarantees the inverted copy mirrors the original exactly — same random draws, same branch decisions, opposite direction. The result is a symmetric structure that looks organic above the horizon and root-like below it. Cloud and earth. Canopy and mycelium. The symmetry is not imposed by a mirror operation on the geometry. It emerges from replaying the same pseudorandom sequence in a different direction. Recursion plus seed replay equals reflection.

## The Mobius World: Topological Self-Reference

The `mobius_world` sits at the far edge of the map — a surface that loops back on itself with a half-twist. A Mobius strip has one side and one edge. Walk along its surface and after one full circuit the walker arrives back at the starting point but on the "opposite" face — except there is no opposite face. The surface is its own mirror.

```gdscript
func build_mobius_strip(radius: float, width: float, segments: int) -> MeshInstance3D:
    var mesh := ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

    for i in range(segments + 1):
        var t := float(i) / float(segments)
        var theta := t * TAU

        var center := Vector3(cos(theta), 0, sin(theta)) * radius

        # Half-twist: cross-section rotates by pi over one full loop
        var twist_angle := theta * 0.5
        var up := Vector3(0, 1, 0).rotated(
            Vector3(cos(theta), 0, sin(theta)).normalized(), twist_angle)
        var offset := up * width * 0.5

        mesh.surface_add_vertex(center + offset)
        mesh.surface_add_vertex(center - offset)

    mesh.surface_end()
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    return instance
```

The key line is `twist_angle := theta * 0.5`. Over a full revolution, the cross-section rotates by exactly half a turn — pi radians. This half-twist makes the strip non-orientable. The two "sides" are the same side. The recursion here is topological rather than geometric — the strip refers back to itself after one traversal, arriving at the same point from the other direction. Self-reference without self-similarity. The `mobius_world` does not branch or subdivide. It loops — a different flavor of recursion where the structure's boundary is also its interior, where traversal is return.

## The Cube Desk: Functional Recursion

The `cube_desk` carries forward the geometric recursion thread from Fractals_1 but applies it to functional form — like the recursive chair from the previous map. A desk surface subdivided into smaller desks. The recursion serves a design purpose rather than a purely mathematical one. Each sub-desk retains the proportions of its parent. The recursion is structural, not decorative.

This artifact bridges the two recursion modes present in the map. The stochastic trees are organic — branching, directional, noisy. The cube desk is geometric — rectilinear, grid-aligned, exact. Both use the same mechanism — a function that calls itself with smaller parameters — but the topology differs. Trees produce graphs. Desks produce grids. The recursion engine is substrate-agnostic. What changes is the geometry it generates.

## Natural Branching Patterns

Stochastic trees converge on recognizable natural forms not because they simulate biology but because they share the statistical signatures of biological branching:

- **Leonardo's rule** — the combined cross-sectional area of branches after a fork equals the area before the fork. A length ratio of 0.7 with two children approximates this conservation.
- **Angle distribution** — real trees branch at 15 to 45 degrees from the parent. The base angle parameter sits in this range. The variance parameter spreads the distribution, producing the asymmetric forks visible in actual canopies.
- **Apical dominance** — the trunk continues straighter and longer than lateral branches. An `is_trunk` flag in the recursive call can break the symmetry — trunk continuation uses a small angle deviation and a ratio of 0.85, while the lateral branch uses the full angle and a ratio of 0.6.

```gdscript
func draw_tree_with_dominance(position: Vector3, direction: Vector3,
                               length: float, angle: float,
                               depth: int, is_trunk: bool) -> void:
    if depth <= 0:
        return

    var perturbed_length := length
    if is_trunk:
        perturbed_length *= (1.0 + randf_range(-0.05, 0.1))
    else:
        perturbed_length *= (1.0 + randf_range(-0.2, 0.05))

    var end_pos := position + direction * perturbed_length
    _add_branch(position, end_pos, depth)

    # Trunk continues with small deviation; lateral gets full angle
    var trunk_dir := direction.rotated(Vector3.FORWARD,
        randf_range(-angle * 0.2, angle * 0.2))
    draw_tree_with_dominance(end_pos, trunk_dir,
        perturbed_length * 0.85, angle, depth - 1, true)

    var lateral_dir := direction.rotated(Vector3.FORWARD,
        angle * (1.0 + randf_range(-0.3, 0.3)))
    draw_tree_with_dominance(end_pos, lateral_dir,
        perturbed_length * 0.6, angle, depth - 1, false)
```

The result is a dominant central axis with subordinate side branches — visually closer to a pine or poplar than the symmetric Y-trees produced by equal branching.

## The Dark Sphere: Anchor in the Garden

The `dark_sphere` sits at the center of the courtyard — the same pulsing, rotating sphere from previous maps. Among the stochastic trees, it serves as a fixed reference point. The trees vary. The sphere does not. Its rotation is deterministic, its pulse is periodic, its position is constant. In a map about randomness, the dark sphere is the zero-variance control. It demonstrates what recursion looks like when lambda equals zero — pure repetition, no exploration, no surprise.

## Performance: Bounding the Stochastic

Stochastic variation does not change the asymptotic complexity — a binary tree at depth n still produces O(2^n) branches whether the angles are fixed or random. But variance can produce unbalanced trees. A random draw that dramatically shortens one branch while lengthening another creates visual asymmetry, and if length perturbation is high enough, some branches extend far beyond the expected canopy radius.

```gdscript
@export var max_segments: int = 5000
var _segment_count: int = 0

func draw_stochastic_tree_limited(position: Vector3, direction: Vector3,
                                   length: float, angle: float,
                                   depth: int) -> void:
    if depth <= 0 or _segment_count >= max_segments:
        return
    if length < 0.01:
        return  # cull invisibly small branches

    _segment_count += 1
    # ... perturb, draw, recurse
```

Two safety mechanisms. The `max_segments` cap prevents runaway geometry counts. The minimum length check culls branches too small to see — a practical base case that supplements the depth-based one. Together they bound the worst-case output without constraining the stochastic character.

## From Determinism to Forest

The stochastic tree is not one artifact. It is a family of artifacts — every seed instantiates a different member. Place ten stochastic trees with different seeds in a row and the result is a forest. Same grammar, ten individuals. The learner walks among them and recognizes each as "tree" while seeing that no two are alike. Recognition without identity. Category without uniformity.

This is the lambda_edge principle rendered as landscape. The deterministic tree is a single point in output space — one shape, reproducible, dead. The fully random tree is noise — no shape, no pattern, meaningless. Between these extremes lies a region where the grammar is visible but not rigid, where structure and variation coexist, where each instantiation is both familiar and novel. The stochastic trees in this map occupy that region. They are the forest at the edge.

The `cube_desk` and `small_subdivision_cube` remind the learner that this territory extends beyond the organic. Geometric forms also live on the spectrum between rigid determinism and formless noise — the cube subdivision from Fractals_1 sits at the deterministic end, and adding stochastic perturbation to cube offsets or sizes would produce the same transition from crystal to rubble that the tree exhibits from skeleton to thicket.

The next map — Fractals_3 — moves from branching to circular recursion. Spirals, nested rings, recursive arcs. The topology shifts again. But the engine remains: a finite rule, self-applied, bounded by depth, shaped by parameters, and — now — perturbed by noise.

## Possible Artifacts

**parameter_space_explorer** — An interactive panel with three sliders: branch angle variance, length ratio variance, and recursion depth. A live stochastic tree regenerates on each slider change, with a seed-lock toggle that holds the random seed constant across parameter sweeps. The learner maps the transition from deterministic tree (all variances at zero) to stochastic forest (variances high) and discovers the lambda_edge — the narrow band where trees look most natural. A fourth slider controls seed directly, cycling through individuals within a fixed parameter set. This is the gap artifact — the map needs it to make parameter sensitivity tangible rather than verbal.

**branching_comparator** — Three trees side by side: a deterministic tree (zero variance), a mildly stochastic tree (variance 0.15), and a heavily stochastic tree (variance 0.5), all grown from the same seed with the same base angle and depth. The comparison makes the effect of variance visible in a single frame — crystal, plant, chaos. Labels show the variance values. The learner sees that "natural" occupies a specific region of parameter space, not the whole range.

**lsystem_string_visualizer** — An artifact that displays the L-system production string alongside the rendered tree, with each symbol highlighted as the interpreter steps through it. Stack pushes and pops flash the saved state. The learner sees the one-to-one correspondence between grammar symbols and spatial operations — F draws, + turns, [ saves, ] restores. Connects the string abstraction to the geometric result and makes the stack mechanism visible rather than implicit.
