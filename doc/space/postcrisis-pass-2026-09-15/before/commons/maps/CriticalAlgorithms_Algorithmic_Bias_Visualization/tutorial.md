# Algorithmic Bias Visualization

A room divided. The left half spacious, the right half cramped. Build allocation as architecture before you write a single line of model code.

Declare the two halves.

```gdscript
@export var left_columns: int = 5
@export var right_columns: int = 2
@export var row_count: int = 8
@export var population_per_side: int = 40
```

Both halves hold the same population. Only the columns differ. The ratio of people to space is the bias.

Place the population into the left half.

```gdscript
func populate_left() -> void:
    for i in population_per_side:
        var col := i % left_columns
        var row := i / left_columns
        spawn_person(Vector3(col, 0.0, row))
```

Row-major placement fills the grid from the left. The crowd has room to breathe; bodies do not overlap.

Place the same count on the right.

```gdscript
func populate_right() -> void:
    for i in population_per_side:
        var col := i % right_columns
        var row := i / right_columns
        spawn_person(Vector3(10.0 + col, 0.0, row))
```

Same loop, smaller denominator. The crowd stacks upward. Rows extend past the room boundary.

Measure the density per side.

```gdscript
func density(side_columns: int) -> float:
    var area := float(side_columns * row_count)
    return float(population_per_side) / area
```

Density is bodies per cell. Left returns 1.0; right returns 2.5. The number on the sign is the felt experience of walking through.

Draw the allocation ratio on a screen.

```gdscript
func update_readout(label: Label3D) -> void:
    var l := density(left_columns)
    var r := density(right_columns)
    label.text = "Left: %.2f\nRight: %.2f\nRatio: %.1fx" % [l, r, r / l]
```

The ratio floats between the two halves. Not an abstraction. A multiplier hovering over heads.

Tint each side by crowding pressure.

```gdscript
func tint_by_density(mesh: MeshInstance3D, d: float) -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(d * 0.4, 0.2, 0.2, 1.0)
    mesh.material_override = material
```

More bodies, redder floor. Crowding becomes pigment. The bias visualizer is not asking the learner to infer inequality from data; it is making inequality inhabitable.

Reveal the allocation rule that caused the divide.

```gdscript
func show_source_rule(panel: Label3D) -> void:
    panel.text = "RULE: allocate columns ∝ historical_representation"
```

The rule is visible on a plaque. Nothing hidden in weights. The architecture is the classifier.

Toggle the rule at runtime.

```gdscript
func _on_rule_toggle_pressed(new_rule: String) -> void:
    current_rule = new_rule
    clear_population()
    apply_rule(new_rule)
```

The button rewrites the allocation live. The same population redistributes. The learner sees which rule produced which felt crowding.

You have built a room where classification precedes mathematics. Walk through the next map, Applied Ethics, to see what practice looks like once this room is the starting condition.
