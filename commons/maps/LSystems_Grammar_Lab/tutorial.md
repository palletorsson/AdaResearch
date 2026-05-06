# Grammar Lab

Axiom, rules, generations. An L-system rewrites a string.

Define an L-system.

```gdscript
class_name LSystem extends Resource

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "F+F-F-F+F"}
@export var angle_deg: float = 90.0
```

The axiom is the starting string. The rules map symbols to their replacements.

Expand by one generation.

```gdscript
func expand_once(current: String) -> String:
    var result: String = ""
    for c in current:
        result += rules.get(c, c)
    return result
```

Every character is looked up in the rules. Characters not in the rules pass through unchanged.

Expand several generations.

```gdscript
func expand(generations: int) -> String:
    var current: String = axiom
    for _i in generations:
        current = expand_once(current)
    return current
```

Each generation is a string. Length grows exponentially when rules expand to longer strings.

Apply the Koch rule.

```gdscript
var koch_system := LSystem.new()
koch_system.axiom = "F"
koch_system.rules = {"F": "F+F-F-F+F"}
koch_system.angle_deg = 90.0

var string := koch_system.expand(4)
# Result: 256 characters after 4 generations
```

Classic Koch curve rule. Each F becomes a kink.

Interpret the string with a turtle.

```gdscript
class_name Turtle2D

var position: Vector2 = Vector2.ZERO
var heading: float = 0.0  # radians
var segments: Array = []

func interpret(lstring: String, step: float, angle_rad: float) -> void:
    for c in lstring:
        match c:
            "F":
                var end := position + Vector2(cos(heading), sin(heading)) * step
                segments.append([position, end])
                position = end
            "+":
                heading += angle_rad
            "-":
                heading -= angle_rad
```

F draws a line forward; + rotates left; - rotates right. Classic turtle-graphics commands.

Render the segments.

```gdscript
func render_segments(turtle: Turtle2D) -> void:
    for seg in turtle.segments:
        draw_line(seg[0], seg[1])
```

Each segment becomes a line in the scene. The shape emerges from the string interpretation.

Tree rule with branches.

```gdscript
var tree_system := LSystem.new()
tree_system.axiom = "F"
tree_system.rules = {"F": "F[+F]F[-F]F"}
tree_system.angle_deg = 25.0
```

[ pushes the turtle state; ] pops it. The turtle splits off to draw a branch, then returns.

Implement stack commands.

```gdscript
var stack: Array = []

func push_state() -> void:
    stack.append({"position": position, "heading": heading})

func pop_state() -> void:
    var s = stack.pop_back()
    position = s.position
    heading = s.heading
```

Push before branching; pop after. The turtle returns to its original state to continue the trunk.

You can now define an L-system, expand it, interpret the result with a turtle, and render the segments. LSystems_Growth extends the L-system into animated time-lapse growth.

Test an empty string.

```gdscript
func is_terminal(lstring: String, rules: Dictionary) -> bool:
    for c in lstring:
        if c in rules: return false
    return true
```

Fully expanded when no symbol matches a rule. Useful for detecting when further generations won't change anything.
