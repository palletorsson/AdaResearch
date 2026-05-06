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

### Interactive λ Control

```gdscript
@export_range(0.0, 1.0) var lambda_param: float = 0.3:
    set(value):
        lambda_param = value
        regenerate_tree()
```

## Key Takeaway
The stochastic tree embodies the **Queer Free Energy Principle** in botanical form. The deterministic branching rule is F. The random variation is λE(S). The temporal unfolding through iterations is φΔE(S,t). Understanding this equation is understanding why natural forms look the way they do: **order and entropy in dynamic equilibrium**.

## Implementation Notes and Complexity

CrossSequence pulls together the fractal arc's connections to earlier sequences in the curriculum. Noise, cellular automata, L-systems, and recursive geometry all share a common substrate: rules applied repeatedly to produce self-similar or scale-invariant outputs. The map stages this commonality as a gallery where equivalent structures from different sequences are displayed side by side.

The rendering cost is dominated by the sheer number of comparison artifacts the map displays. Each comparison pair requires two independent generators running at matched parameter values, and the gallery holds a dozen such pairs. The per-pair cost is O(1) at spawn and O(render size) at display; the aggregate is manageable because each individual artifact is modest.

The matching problem — which noise parameter corresponds to which L-system parameter when the outputs look similar — is not a solved problem in the abstract. The map's approach is pragmatic: matched pairs are hand-tuned by the authoring system, and the learner compares the pairs visually rather than algorithmically. A different approach would use statistical signatures such as power spectra or correlation functions to match outputs automatically, but the hand-tuned matching preserves the authoring intent the sequence's pedagogy depends on.

The cross-sequence connections the map demonstrates are structural rather than merely visual. Both fractals and noise produce structures with fractal dimension between integers; both L-systems and cellular automata produce structures through repeated local rewriting; both noise and cellular automata operate on grids. The map's side panels name the structural connections explicitly, so the visual comparisons are grounded in shared mathematics rather than in surface resemblance.

Within the sequence, CrossSequence is the bridge. It situates the fractals arc within the broader curriculum and prepares the learner to recognise the fractal logic in later sequences. The map's argument is that self-similarity is a widely shared property, and the recognition is part of the curriculum's synthesis work.
