# CA Elementary Rules

One dimension. Two states. 256 possible rules.

Encode a rule as an 8-bit number.

```gdscript
func rule_bit(rule: int, pattern: int) -> int:
    return (rule >> pattern) & 1
```

The rule's 8 bits specify the outcome for each of the 8 possible three-cell patterns. Rule 30 is binary 00011110.

Apply a rule to one row.

```gdscript
func step_row(row: Array, rule: int) -> Array:
    var new_row: Array = []
    var n: int = row.size()
    for i in n:
        var left: int = row[(i - 1 + n) % n]
        var centre: int = row[i]
        var right: int = row[(i + 1) % n]
        var pattern: int = left * 4 + centre * 2 + right
        new_row.append(rule_bit(rule, pattern))
    return new_row
```

Left, centre, right form a three-bit index. The rule's bit at that index is the new cell's state.

Generate a full 2D pattern.

```gdscript
func generate_rule_pattern(rule: int, width: int, generations: int) -> Array:
    var first: Array = []
    for _i in width: first.append(0)
    first[width / 2] = 1  # single seed in the middle
    var pattern: Array = [first]
    for g in range(1, generations):
        pattern.append(step_row(pattern[g - 1], rule))
    return pattern
```

Start with a single live cell. Each generation adds a row below the previous.

Render as an image.

```gdscript
func pattern_to_texture(pattern: Array) -> ImageTexture:
    var width: int = pattern[0].size()
    var height: int = pattern.size()
    var image := Image.create(width, height, false, Image.FORMAT_L8)
    for y in height:
        for x in width:
            image.set_pixel(x, y, Color.WHITE if pattern[y][x] else Color.BLACK)
    return ImageTexture.create_from_image(image)
```

One row per generation, stacked top-to-bottom. Time runs downward.

Classify a rule.

```gdscript
func classify_rule(rule: int, width: int = 101, generations: int = 200) -> String:
    var pattern := generate_rule_pattern(rule, width, generations)
    var final_density: float = 0.0
    for cell in pattern[generations - 1]:
        final_density += cell
    final_density /= width
    if final_density < 0.01: return "Class I (dies)"
    if is_periodic(pattern): return "Class II (periodic)"
    if appears_random(pattern): return "Class III (chaotic)"
    return "Class IV (complex)"
```

Wolfram's four classes. Classification is heuristic; the boundaries aren't sharp.

Render Rule 30 and Rule 110.

```gdscript
func display_famous_rules() -> void:
    render_at_position(generate_rule_pattern(30, 101, 200), Vector3(-2, 0, 0))
    render_at_position(generate_rule_pattern(110, 101, 200), Vector3(2, 0, 0))
```

Rule 30 produces chaos from order. Rule 110 supports moving localised structures — Turing complete.

Build the 256-rule gallery.

```gdscript
func build_gallery() -> void:
    for rule in 256:
        var pattern := generate_rule_pattern(rule, 33, 60)
        var texture := pattern_to_texture(pattern)
        var position := Vector3((rule % 16) * 0.4, 0, (rule / 16) * 0.4)
        spawn_rule_tile(rule, texture, position)
```

16×16 grid of small pattern tiles. Walk past and compare.

You can now encode a rule as 8 bits, apply it to a 1D array, generate a 2D pattern, render it, classify it, and display the gallery of 256 rules. CA_GameOfLife extends into Conway's 2D world.
