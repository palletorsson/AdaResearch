# Fractals_14 - Technical Tutorial

## The QFEP in Code

### The Formula Revisited
**QFE = F − λE(S) + φΔE(S,t)**

Translated to stochastic trees:

```gdscript
# F = Free energy (deterministic structure)
# The branching rule itself
func F_component(branch: Branch) -> Array[Branch]:
    return [
        Branch.new(branch.end, branch.direction.rotated(angle), branch.length * ratio),
        Branch.new(branch.end, branch.direction.rotated(-angle), branch.length * ratio)
    ]

# λE(S) = Entropy modulated by λ
# Random variation in angles and lengths
func lambda_ES_component(branch: Branch, lambda_param: float) -> Branch:
    var entropy = randf_range(-1.0, 1.0)
    branch.angle += entropy * lambda_param * max_angle_variation
    branch.length *= 1.0 + entropy * lambda_param * max_length_variation
    return branch

# φΔE(S,t) = Change in entropy over time
# How much variation increases/decreases with depth
func phi_delta_ES(depth: int, phi_param: float) -> float:
    # Positive phi: more variation at higher depths
    # Negative phi: less variation at higher depths
    return phi_param * log(depth + 1)
```

### Complete QFEP Tree

```gdscript
class QFEPTree:
    var lambda_param: float = 0.3  # Entropy modulator
    var phi_param: float = 0.1     # Entropy change rate
    var base_angle: float = 30.0   # Deterministic angle (F)
    var base_ratio: float = 0.7    # Deterministic ratio (F)

    func generate_branch(
        start: Vector3,
        direction: Vector3,
        length: float,
        depth: int,
        max_depth: int
    ):
        if depth >= max_depth:
            return

        var end = start + direction * length
        draw_branch(start, end)

        # Calculate effective lambda at this depth
        var effective_lambda = lambda_param + phi_delta_ES(depth, phi_param)
        effective_lambda = clamp(effective_lambda, 0.0, 1.0)

        # F component: deterministic branching
        var child_length = length * base_ratio
        var left_angle = deg_to_rad(base_angle)
        var right_angle = deg_to_rad(-base_angle)

        # λE(S) component: entropy injection
        left_angle += randf_range(-1, 1) * effective_lambda * deg_to_rad(15)
        right_angle += randf_range(-1, 1) * effective_lambda * deg_to_rad(15)
        child_length *= 1.0 + randf_range(-1, 1) * effective_lambda * 0.2

        # Generate children
        var left_dir = direction.rotated(Vector3.FORWARD, left_angle)
        var right_dir = direction.rotated(Vector3.FORWARD, right_angle)

        generate_branch(end, left_dir, child_length, depth + 1, max_depth)
        generate_branch(end, right_dir, child_length, depth + 1, max_depth)
```

### Parameter Exploration

```gdscript
# Explore the λ parameter space
func demonstrate_lambda_spectrum():
    var lambda_values = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

    for i in range(lambda_values.size()):
        var tree = QFEPTree.new()
        tree.lambda_param = lambda_values[i]
        tree.position = Vector3(i * 5.0, 0, 0)
        tree.generate()

# λ = 0: Pure F, deterministic, identical trees
# λ = 0.3: Natural variation, organic appearance
# λ = 1.0: Maximum entropy, chaotic structure
```

### The Edge of Chaos

```gdscript
# Find the λ value that produces maximum complexity
func measure_tree_complexity(tree: QFEPTree) -> float:
    # Complexity metrics:
    # - Branching diversity
    # - Angular distribution entropy
    # - Self-similarity preservation

    var angles = collect_branch_angles(tree)
    var angle_entropy = calculate_entropy(angles)

    var lengths = collect_branch_lengths(tree)
    var length_entropy = calculate_entropy(lengths)

    var self_similarity = measure_self_similarity(tree)

    # Complexity is high when:
    # - Moderate entropy (not too uniform, not too random)
    # - High self-similarity preservation
    return angle_entropy * self_similarity

# The "edge of chaos" is where complexity peaks
# This typically occurs around λ ≈ 0.3-0.4
```

### Time Evolution (φ component)

```gdscript
# Animate tree growth showing temporal evolution
var growth_time: float = 0.0

func _process(delta):
    growth_time += delta

    # Current depth based on time
    var current_depth = int(growth_time * 2.0)

    # φ modulates how entropy changes over time
    var current_phi_effect = phi_param * growth_time

    regenerate_tree_to_depth(current_depth, current_phi_effect)
```

### Comparison: Pure F vs. Full QFEP

```gdscript
func demonstrate_comparison():
    # Pure F (λ = 0, φ = 0): Deterministic tree
    var deterministic_tree = QFEPTree.new()
    deterministic_tree.lambda_param = 0.0
    deterministic_tree.phi_param = 0.0
    deterministic_tree.position = Vector3(-5, 0, 0)
    deterministic_tree.generate()

    # Full QFEP: Natural tree
    var natural_tree = QFEPTree.new()
    natural_tree.lambda_param = 0.35
    natural_tree.phi_param = 0.1
    natural_tree.position = Vector3(5, 0, 0)
    natural_tree.generate()

    # The difference is visible:
    # Deterministic: symmetric, predictable, artificial
    # QFEP: asymmetric, varied, natural
```

### Synthesis with Other Fractals

```gdscript
# The QFEP framework applies to all fractals:

# Mandelbrot Set
# F: The formula z² + c
# λE(S): The c parameter (each c produces different complexity)
# φΔE(S,t): The iteration count (time evolution of each point)

# Sierpinski Triangle
# F: The deletion rule (remove center triangle)
# λE(S): Stochastic vertex selection in chaos game
# φΔE(S,t): Iteration depth

# Koch Curve
# F: Edge replacement rule
# λE(S): Could add stochastic angle/length variation
# φΔE(S,t): Generation count
```

## Implementation Notes

### Seeded Randomness for Reproducibility

```gdscript
var tree_seed: int = 12345

func generate_reproducible():
    seed(tree_seed)
    generate_tree()

# Same seed → same tree
# Different seeds → different trees from same rules
```

### Interactive λ Control

```gdscript
@export_range(0.0, 1.0) var lambda_param: float = 0.3:
    set(value):
        lambda_param = value
        regenerate_tree()
```

## Key Takeaway
The stochastic tree embodies the **Queer Free Energy Principle** in botanical form. The deterministic branching rule is F. The random variation is λE(S). The temporal unfolding through iterations is φΔE(S,t). Understanding this equation is understanding why natural forms look the way they do: **order and entropy in dynamic equilibrium**.
