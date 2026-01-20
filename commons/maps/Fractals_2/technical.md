# Fractals_2 - Technical Tutorial

## Stochastic L-Systems

### Basic L-System Review
An L-System uses grammar rules to generate strings:

```gdscript
class_name LSystem

var axiom: String = "F"
var rules: Dictionary = {"F": "F[+F]F[-F]F"}

func generate(iterations: int) -> String:
    var current = axiom

    for i in range(iterations):
        var next = ""
        for symbol in current:
            if symbol in rules:
                next += rules[symbol]
            else:
                next += symbol
        current = next

    return current
```

### Adding Stochasticity
Stochastic rules offer multiple options for each symbol:

```gdscript
class_name StochasticLSystem

var axiom: String = "F"
var rules: Dictionary = {
    "F": [
        "F[+F]F[-F]F",      # Standard branching
        "F[+F][-F]",         # Simplified branching
        "FF[+F][-F]F",       # Extended trunk
        "F[++F][--F]F"       # Wide angle variation
    ]
}

func generate(iterations: int) -> String:
    var current = axiom

    for i in range(iterations):
        var next = ""
        for symbol in current:
            if symbol in rules:
                var options = rules[symbol]
                # Random choice from available rules
                next += options[randi() % options.size()]
            else:
                next += symbol
        current = next

    return current
```

### Weighted Stochastic Rules
For more control, use weighted probabilities:

```gdscript
var weighted_rules: Dictionary = {
    "F": [
        {"rule": "F[+F]F[-F]F", "weight": 0.5},   # 50% chance
        {"rule": "F[+F][-F]", "weight": 0.3},     # 30% chance
        {"rule": "FF[+F][-F]F", "weight": 0.2}    # 20% chance
    ]
}

func apply_weighted_rule(symbol: String) -> String:
    if symbol not in weighted_rules:
        return symbol

    var options = weighted_rules[symbol]
    var total_weight = 0.0
    for opt in options:
        total_weight += opt.weight

    var roll = randf() * total_weight
    var cumulative = 0.0

    for opt in options:
        cumulative += opt.weight
        if roll <= cumulative:
            return opt.rule

    return options[-1].rule  # Fallback
```

### Tree Rendering from L-System String
Interpret the string as drawing commands:

```gdscript
func render_tree(l_string: String, start_pos: Vector3):
    var pos = start_pos
    var direction = Vector3.UP
    var stack = []

    var segment_length = 0.5
    var angle_delta = deg_to_rad(25.0)

    for symbol in l_string:
        match symbol:
            "F":
                # Draw segment and move forward
                draw_branch(pos, pos + direction * segment_length)
                pos += direction * segment_length
            "+":
                # Rotate right around Z axis
                direction = direction.rotated(Vector3.FORWARD, angle_delta)
            "-":
                # Rotate left around Z axis
                direction = direction.rotated(Vector3.FORWARD, -angle_delta)
            "[":
                # Push state onto stack
                stack.push_back({"pos": pos, "dir": direction})
            "]":
                # Pop state from stack
                var state = stack.pop_back()
                pos = state.pos
                direction = state.dir
```

### Adding Natural Variation
Beyond rule selection, add continuous variation:

```gdscript
func render_tree_natural(l_string: String, start_pos: Vector3):
    var pos = start_pos
    var direction = Vector3.UP
    var stack = []

    var base_length = 0.5
    var base_angle = deg_to_rad(25.0)
    var length_variation = 0.2   # ±20%
    var angle_variation = 0.3    # ±30%

    for symbol in l_string:
        match symbol:
            "F":
                # Vary segment length
                var length = base_length * (1.0 + randf_range(-length_variation, length_variation))
                draw_branch(pos, pos + direction * length)
                pos += direction * length
            "+":
                # Vary rotation angle
                var angle = base_angle * (1.0 + randf_range(-angle_variation, angle_variation))
                direction = direction.rotated(Vector3.FORWARD, angle)
            "-":
                var angle = base_angle * (1.0 + randf_range(-angle_variation, angle_variation))
                direction = direction.rotated(Vector3.FORWARD, -angle)
            # ... stack operations unchanged
```

### The Cantor Pagoda
The Cantor set applied to 3D architecture:

```gdscript
func cantor_pagoda(base: AABB, depth: int):
    if depth <= 0:
        create_solid(base)
        return

    # Divide into thirds
    var third = base.size / 3.0

    # Create left and right sections (skip middle)
    var left = AABB(base.position, Vector3(third.x, base.size.y, third.z))
    var right = AABB(
        base.position + Vector3(2 * third.x, 0, 2 * third.z),
        Vector3(third.x, base.size.y, third.z)
    )

    # Recurse on each section
    cantor_pagoda(left, depth - 1)
    cantor_pagoda(right, depth - 1)
```

## Implementation Notes

### Seed Control
For reproducible stochastic trees:

```gdscript
@export var tree_seed: int = 12345

func _ready():
    seed(tree_seed)
    var l_string = generate(5)
    render_tree(l_string, Vector3.ZERO)
```

Same seed = same tree. Different seeds = different trees from same rules.

### Performance with Stochastic Trees
Stochastic variation doesn't change complexity class, but can create unbalanced trees:

```gdscript
# Some random outcomes produce much more geometry
# Use maximum depth limits and LOD
@export var max_segments: int = 10000
var segment_count: int = 0

func render_with_limit(l_string: String, start_pos: Vector3):
    for symbol in l_string:
        if segment_count >= max_segments:
            return  # Stop rendering
        # ... render logic
        if symbol == "F":
            segment_count += 1
```

## Key Takeaway
Stochastic L-Systems demonstrate the QFEP balance: the F term (deterministic grammar) provides structure, while the λE(S) term (random rule selection) provides variation. The result is **natural form**: recognizable structure with unique expression.
